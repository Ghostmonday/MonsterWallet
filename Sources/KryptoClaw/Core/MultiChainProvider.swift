import Foundation

/// A robust provider that routes requests to the correct chain-specific logic.
/// For V1.0/V2 "Standard", we use mocked/simulated backends for BTC/SOL to ensure stability and compliance
/// without needing full SPV implementations (which are huge).
public class MultiChainProvider: BlockchainProviderProtocol {

    private let ethProvider: ModularHTTPProvider // Existing provider

    public init(session: URLSession = .shared) {
        self.ethProvider = ModularHTTPProvider(session: session)
    }

    public func fetchBalance(address: String, chain: Chain) async throws -> Balance {
        switch chain {
        case .ethereum:
            return try await ethProvider.fetchBalance(address: address, chain: .ethereum)

        case .bitcoin:
            return try await fetchBitcoinBalance(address: address)

        case .solana:
            return try await fetchSolanaBalance(address: address)
        }
    }
    
    private func fetchBitcoinBalance(address: String) async throws -> Balance {
        // Using mempool.space API
        let urlString = "https://mempool.space/api/address/\(address)"
        guard let url = URL(string: urlString) else { throw BlockchainError.invalidAddress }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
             throw BlockchainError.networkError(NSError(domain: "HTTP", code: (response as? HTTPURLResponse)?.statusCode ?? 500, userInfo: nil))
        }
        
        // Parse JSON
        // { "chain_stats": { "funded_txo_sum": 123, "spent_txo_sum": 100 } }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let stats = json["chain_stats"] as? [String: Int],
              let funded = stats["funded_txo_sum"],
              let spent = stats["spent_txo_sum"] else {
            throw BlockchainError.parsingError
        }
        
        let balanceSats = funded - spent
        let balanceBTC = Decimal(balanceSats) / pow(10, 8)
        
        return Balance(amount: "\(balanceBTC)", currency: "BTC", decimals: 8)
    }
    
    private func fetchSolanaBalance(address: String) async throws -> Balance {
        let url = URL(string: "https://api.mainnet-beta.solana.com")!
        
        let payload: [String: Any] = [
            "jsonrpc": "2.0",
            "id": 1,
            "method": "getBalance",
            "params": [address]
        ]
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: payload) else {
            throw BlockchainError.parsingError
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = httpBody
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
             throw BlockchainError.networkError(NSError(domain: "HTTP", code: (response as? HTTPURLResponse)?.statusCode ?? 500, userInfo: nil))
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw BlockchainError.parsingError
        }
        
        if let error = json["error"] as? [String: Any], let message = error["message"] as? String {
            throw BlockchainError.rpcError(message)
        }
        
        guard let result = json["result"] as? [String: Any], let value = result["value"] as? Int else {
            // Solana getBalance returns result: { context: {}, value: <lamports> }
            // Or sometimes just result: <lamports> depending on version? 
            // Actually standard is result: { context: ..., value: <int> }
            // Let's check if result is just Int
            if let val = json["result"] as? Int {
                let balanceSOL = Decimal(val) / pow(10, 9)
                return Balance(amount: "\(balanceSOL)", currency: "SOL", decimals: 9)
            }
            throw BlockchainError.parsingError
        }
        
        let balanceSOL = Decimal(value) / pow(10, 9)
        return Balance(amount: "\(balanceSOL)", currency: "SOL", decimals: 9)
    }

    public func fetchHistory(address: String, chain: Chain) async throws -> TransactionHistory {
        switch chain {
        case .ethereum:
            return try await ethProvider.fetchHistory(address: address, chain: .ethereum)
        default:
            // Mock history for BTC/SOL
            let tx = TransactionSummary(
                hash: "0xMockHash\(chain.rawValue)",
                from: "0xSender",
                to: address,
                value: "1.0",
                timestamp: Date().addingTimeInterval(-3600),
                chain: chain
            )
            return TransactionHistory(transactions: [tx])
        }
    }

    public func broadcast(signedTx: Data, chain: Chain) async throws -> String {
        switch chain {
        case .ethereum:
            return try await ethProvider.broadcast(signedTx: signedTx, chain: .ethereum)
        default:
            // Simulate broadcast
            try await Task.sleep(nanoseconds: 1_000_000_000)
            return "0xBroadcastSuccess\(chain.rawValue)"
        }
    }
    
    public func fetchPrice(chain: Chain) async throws -> Decimal {
        return try await ethProvider.fetchPrice(chain: chain)
    }
    
    public func estimateGas(to: String, value: String, data: Data, chain: Chain) async throws -> GasEstimate {
        switch chain {
        case .ethereum:
            return try await ethProvider.estimateGas(to: to, value: value, data: data, chain: .ethereum)
        default:
            // Mock estimation for BTC/SOL
            return GasEstimate(gasLimit: 21000, maxFeePerGas: "1000", maxPriorityFeePerGas: "100")
        }
    }
}
