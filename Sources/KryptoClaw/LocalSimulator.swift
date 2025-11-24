import BigInt
import Foundation
import web3

public class LocalSimulator: TransactionSimulatorProtocol {
    private let provider: BlockchainProviderProtocol
    private let session: URLSession

    public init(provider: BlockchainProviderProtocol, session: URLSession = .shared) {
        self.provider = provider
        self.session = session
    }

    public func simulate(tx: Transaction) async throws -> SimulationResult {
        // TODO: Implement full transaction trace simulation (Tenderly/Alchemy Simulate API)
        // Current implementation uses eth_call for partial simulation

        if AppConfig.Features.isAddressPoisoningProtectionEnabled {
            // Block infinite approvals (common scam pattern)
            if tx.data.count > 0, tx.data.hexString.contains("ffffffffffffffffffffffffffffffff") {
                return SimulationResult(
                    success: false,
                    estimatedGasUsed: 0,
                    balanceChanges: [:],
                    error: "Security Risk: Infinite Token Approval detected. This is a common wallet drainer technique. Transaction blocked."
                )
            }
        }

        let chain: Chain = if tx.chainId == 1 {
            .ethereum
        } else {
            // TODO: Implement proper chain ID mapping for Bitcoin/Solana
            .bitcoin
        }

        let balance = try await provider.fetchBalance(address: tx.from, chain: chain)

        guard chain == .ethereum else {
            return SimulationResult(success: true, estimatedGasUsed: 21000, balanceChanges: [:], error: nil)
        }

        // Note: balance.amount format varies by provider (decimal string or hex)
        let balanceBigInt = if balance.amount.hasPrefix("0x") {
            BigUInt(balance.amount.dropFirst(2), radix: 16) ?? BigUInt(0)
        } else {
            BigUInt(balance.amount) ?? BigUInt(0)
        }

        let txValue = BigUInt(tx.value) ?? BigUInt(0)

        if txValue > balanceBigInt {
            return SimulationResult(
                success: false,
                estimatedGasUsed: 0,
                balanceChanges: [:],
                error: "Insufficient Funds: Balance is lower than transaction value."
            )
        }

        let url = AppConfig.rpcURL

        let payload: [String: Any] = [
            "jsonrpc": "2.0",
            "method": "eth_call",
            "params": [[
                "from": tx.from,
                "to": tx.to,
                "value": "0x" + String(txValue, radix: 16),
                "data": "0x" + tx.data.hexString,
            ], "latest"],
            "id": 1,
        ]

        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 30.0

            let (data, _) = try await session.data(for: request)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let error = json["error"] as? [String: Any] {
                    return SimulationResult(
                        success: false,
                        estimatedGasUsed: 0,
                        balanceChanges: [:],
                        error: "Simulation Failed: \(error["message"] as? String ?? "Reverted")"
                    )
                }
            }

            return SimulationResult(
                success: true,
                estimatedGasUsed: tx.gasLimit,
                balanceChanges: [:], // TODO: Balance changes require full trace simulation (not available in basic eth_call)
                error: nil
            )

        } catch {
            KryptoLogger.shared.logError(module: "LocalSimulator", error: error)
            return SimulationResult(success: false, estimatedGasUsed: 0, balanceChanges: [:], error: "Network Error: \(ErrorTranslator.userFriendlyMessage(for: error))")
        }
    }
}
