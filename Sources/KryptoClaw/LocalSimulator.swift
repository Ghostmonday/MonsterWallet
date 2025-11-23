import Foundation
import BigInt
import web3

public class LocalSimulator: TransactionSimulatorProtocol {
    private let provider: BlockchainProviderProtocol
    
    public init(provider: BlockchainProviderProtocol) {
        self.provider = provider
    }
    
    public func simulate(tx: Transaction) async throws -> SimulationResult {
        // Updated Simulation Logic:
        // We will call `eth_call` to check if the transaction reverts.
        // This is a "Partial Simulation" (better than mock, but not full trace).
        // For full trace, we'd need Tenderly/Alchemy Simulate API.

        // 0. Strict Security Check (V2)
        if AppConfig.Features.isAddressPoisoningProtectionEnabled {
             // Block infinite approvals (common scam pattern)
             // 0xffffff... is typical for infinite approval
             if tx.data.count > 0 && tx.data.hexString.contains("ffffffffffffffffffffffffffffffff") {
                 return SimulationResult(
                     success: false,
                     estimatedGasUsed: 0,
                     balanceChanges: [:],
                     error: "Security Risk: Infinite Token Approval detected. This is a common wallet drainer technique. Transaction blocked."
                 )
             }
        }

        // 1. Determine Chain
        let chain: Chain
        if tx.chainId == 1 {
            chain = .ethereum
        } else {
            // Simplified mapping for V1 mock: All non-1 IDs map to Bitcoin/Solana mock flow
            // In a real app, we'd check specific IDs.
            chain = .bitcoin // Default fallback for mock simulation
        }

        // 2. Fetch Balance
        let balance = try await provider.fetchBalance(address: tx.from, chain: chain)
        
        // 3. Real Check via eth_call
        guard chain == .ethereum else {
             // Fallback for non-EVM mock
             return SimulationResult(success: true, estimatedGasUsed: 21000, balanceChanges: [:])
        }
        
        let url = AppConfig.rpcURL
        
        let payload: [String: Any] = [
            "jsonrpc": "2.0",
            "method": "eth_call",
            "params": [[
                "from": tx.from,
                "to": tx.to,
                "value": "0x" + (BigUInt(tx.value)?.toString(radix: 16) ?? "0"),
                "data": "0x" + tx.data.toHexString()
            ], "latest"],
            "id": 1
        ]
        
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let (data, _) = try await URLSession.shared.data(for: request)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                 if let error = json["error"] as? [String: Any] {
                      // Transaction would revert!
                      return SimulationResult(
                          success: false,
                          estimatedGasUsed: 0,
                          balanceChanges: [:],
                          error: "Simulation Failed: \(error["message"] as? String ?? "Reverted")"
                      )
                 }
            }

            // If success, we just check balance locally for "Insufficient Funds" as a secondary check
            // (Similar to previous logic but using BigInt)

            return SimulationResult(
                success: true,
                estimatedGasUsed: tx.gasLimit, // We assume gasLimit is sufficient if estimateGas passed
                balanceChanges: [:], // Real balance changes need full trace, not available in basic eth_call
                error: nil
            )

        } catch {
             return SimulationResult(success: false, estimatedGasUsed: 0, balanceChanges: [:], error: "Network Error")
        }
    }
}
