import BigInt
import Foundation
import web3

public class LocalSimulator: TransactionSimulatorProtocol {
    private let provider: BlockchainProviderProtocol
    private let session: URLSession
    
    // Cache balance checks to avoid redundant network calls
    private var balanceCache: [String: (balance: Balance, timestamp: Date)] = [:]
    private let balanceCacheTTL: TimeInterval = 30.0 // 30 seconds cache

    public init(provider: BlockchainProviderProtocol, session: URLSession = .shared) {
        self.provider = provider
        self.session = session
    }

    public func simulate(tx: Transaction) async throws -> SimulationResult {
        // Task 12: Full Transaction Trace Simulation
        // Current implementation uses eth_call for partial simulation (revert check).
        // For full balance changes and internal traces, we need an external Simulator API (Tenderly/Alchemy).
        
        // 1. Check for common scams (Address Poisoning / Infinite Approvals)
        if AppConfig.Features.isAddressPoisoningProtectionEnabled {
            if tx.data.count > 0, tx.data.hexString.contains("ffffffffffffffffffffffffffffffff") {
                return SimulationResult(
                    success: false,
                    estimatedGasUsed: 0,
                    balanceChanges: [:],
                    error: "Security Risk: Infinite Token Approval detected. This is a common wallet drainer technique. Transaction blocked."
                )
            }
        }

        let chain: Chain = if tx.chainId == 1 || tx.chainId == AppConfig.TestEndpoints.ethereumChainId {
            .ethereum
        } else {
            // TODO: Implement proper chain ID mapping for Bitcoin/Solana
            .bitcoin
        }

        // 2. Fetch Balance for Pre-check (with caching)
        let balance = try await getCachedBalance(address: tx.from, chain: chain)

        guard chain == .ethereum else {
            // Only ETH simulation supported in V1
            return SimulationResult(success: true, estimatedGasUsed: 21000, balanceChanges: [:], error: nil)
        }

        // Convert balance from ETH string (e.g., "4897.999937") to wei BigUInt
        let balanceInWei: BigUInt
        if balance.amount.hasPrefix("0x") {
            balanceInWei = BigUInt(balance.amount.dropFirst(2), radix: 16) ?? BigUInt(0)
        } else if let ethDecimal = Decimal(string: balance.amount) {
            // Convert ETH to wei (multiply by 10^18)
            let weiDecimal = ethDecimal * pow(10, 18)
            balanceInWei = BigUInt(weiDecimal.description.split(separator: ".").first ?? "0") ?? BigUInt(0)
        } else {
            balanceInWei = BigUInt(0)
        }

        let txValue = BigUInt(tx.value) ?? BigUInt(0)

        if txValue > balanceInWei {
            return SimulationResult(
                success: false,
                estimatedGasUsed: 0,
                balanceChanges: [:],
                error: "Insufficient Funds: Balance is lower than transaction value."
            )
        }

        // 3. Perform Simulation
        // Attempt full trace via API if configured, otherwise fall back to eth_call
        if let simulationAPI = AppConfig.simulationAPIURL {
            return try await simulateViaExternalAPI(tx: tx, url: simulationAPI)
        } else {
            return try await simulateViaEthCall(tx: tx, value: txValue)
        }
    }
    
    private func simulateViaEthCall(tx: Transaction, value: BigUInt) async throws -> SimulationResult {
        let url = AppConfig.rpcURL
        let payload: [String: Any] = [
            "jsonrpc": "2.0",
            "method": "eth_call",
            "params": [[
                "from": tx.from,
                "to": tx.to,
                "value": "0x" + String(value, radix: 16),
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
                balanceChanges: [:], // eth_call doesn't provide balance changes
                error: nil
            )

        } catch {
            KryptoLogger.shared.logError(module: "LocalSimulator", error: error)
            return SimulationResult(success: false, estimatedGasUsed: 0, balanceChanges: [:], error: "Network Error: \(ErrorTranslator.userFriendlyMessage(for: error))")
        }
    }
    
    private func simulateViaExternalAPI(tx: Transaction, url: URL) async throws -> SimulationResult {
        // Stub for Tenderly/Alchemy Simulate API integration
        // Format: POST to /simulate with tx details
        // Response: Trace, state diffs, etc.
        
        // TODO: Implement specific API client (Tenderly/Alchemy)
        // This requires an API Key and proper request formatting per provider docs.
        // Example for Tenderly:
        // { "network_id": "1", "from": ..., "to": ..., "input": ..., "value": ..., "save": true }
        
        throw NSError(domain: "LocalSimulator", code: -1, userInfo: [NSLocalizedDescriptionKey: "External Simulation API not implemented"])
    }
    
    // MARK: - Balance Caching
    
    /// Get balance with caching to reduce redundant network calls
    private func getCachedBalance(address: String, chain: Chain) async throws -> Balance {
        let cacheKey = "\(address):\(chain.rawValue)"
        
        // Check cache
        if let cached = balanceCache[cacheKey],
           Date().timeIntervalSince(cached.timestamp) < balanceCacheTTL {
            return cached.balance
        }
        
        // Fetch fresh balance
        let balance = try await provider.fetchBalance(address: address, chain: chain)
        
        // Update cache
        balanceCache[cacheKey] = (balance: balance, timestamp: Date())
        
        // Clean old cache entries (keep cache size reasonable)
        if balanceCache.count > 100 {
            balanceCache = balanceCache.filter { _, value in
                Date().timeIntervalSince(value.timestamp) < balanceCacheTTL
            }
        }
        
        return balance
    }
}
