import Foundation

/// A robust provider that routes requests to the correct chain-specific logic.
/// TODO: Replace mocked BTC/SOL backends with full implementations
public class MultiChainProvider: BlockchainProviderProtocol {
    private let ethProvider: ModularHTTPProvider // Existing provider
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
        ethProvider = ModularHTTPProvider(session: session)
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
        let urlString = "https://mempool.space/api/address/\(address)"
        guard let url = URL(string: urlString) else { throw BlockchainError.invalidAddress }

        var request = URLRequest(url: url)
        request.timeoutInterval = 30.0
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, (200 ... 299).contains(httpResponse.statusCode) else {
            throw BlockchainError.networkError(NSError(domain: "HTTP", code: (response as? HTTPURLResponse)?.statusCode ?? 500, userInfo: nil))
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let stats = json["chain_stats"] as? [String: Int],
              let funded = stats["funded_txo_sum"],
              let spent = stats["spent_txo_sum"]
        else {
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
            "params": [address],
        ]

        guard let httpBody = try? JSONSerialization.data(withJSONObject: payload) else {
            throw BlockchainError.parsingError
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = httpBody
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30.0

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, (200 ... 299).contains(httpResponse.statusCode) else {
            throw BlockchainError.networkError(NSError(domain: "HTTP", code: (response as? HTTPURLResponse)?.statusCode ?? 500, userInfo: nil))
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw BlockchainError.parsingError
        }

        if let error = json["error"] as? [String: Any], let message = error["message"] as? String {
            throw BlockchainError.rpcError(message)
        }

        guard let result = json["result"] as? [String: Any], let value = result["value"] as? Int else {
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
            // Etherscan or similar indexer integration should happen in ethProvider or here
            // For now, we will implement a basic Etherscan call in ethProvider or here directly
            return try await ethProvider.fetchHistory(address: address, chain: .ethereum)
        case .bitcoin:
            return try await fetchBitcoinHistory(address: address)
        case .solana:
            return try await fetchSolanaHistory(address: address)
        }
    }

    private func fetchBitcoinHistory(address: String) async throws -> TransactionHistory {
        let urlString = "https://mempool.space/api/address/\(address)/txs"
        guard let url = URL(string: urlString) else { throw BlockchainError.invalidAddress }

        var request = URLRequest(url: url)
        request.timeoutInterval = 30.0
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            // If 404, it might just mean no history, but mempool.space usually returns []
            if (response as? HTTPURLResponse)?.statusCode == 404 { return TransactionHistory(transactions: []) }
            throw BlockchainError.networkError(NSError(domain: "HTTP", code: (response as? HTTPURLResponse)?.statusCode ?? 500, userInfo: nil))
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            throw BlockchainError.parsingError
        }

        let txs: [TransactionSummary] = json.compactMap { txDict in
            guard let txid = txDict["txid"] as? String,
                  let status = txDict["status"] as? [String: Any],
                  let blockTime = status["block_time"] as? TimeInterval else { return nil }
            
            // Simplification: Parsing BTC inputs/outputs to determine value/from/to is complex.
            // For summary, we just list the TXID.
            // TODO: Parse 'vin' and 'vout' to determine direction and amount.
            
            return TransactionSummary(
                hash: txid,
                from: "BTC_Sender", // Needs parsing
                to: address,        // Needs parsing
                value: "0.0",       // Needs parsing
                timestamp: Date(timeIntervalSince1970: blockTime),
                chain: .bitcoin
            )
        }

        return TransactionHistory(transactions: txs)
    }

    private func fetchSolanaHistory(address: String) async throws -> TransactionHistory {
        let url = URL(string: "https://api.mainnet-beta.solana.com")!
        let payload: [String: Any] = [
            "jsonrpc": "2.0",
            "id": 1,
            "method": "getSignaturesForAddress",
            "params": [
                address,
                ["limit": 20]
            ]
        ]

        guard let httpBody = try? JSONSerialization.data(withJSONObject: payload) else { throw BlockchainError.parsingError }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = httpBody
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, _) = try await session.data(for: request)
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let result = json["result"] as? [[String: Any]] else {
            return TransactionHistory(transactions: [])
        }

        let txs: [TransactionSummary] = result.compactMap { sigDict in
            guard let signature = sigDict["signature"] as? String,
                  let blockTime = sigDict["blockTime"] as? TimeInterval else { return nil }
            
            return TransactionSummary(
                hash: signature,
                from: "Unknown", // Solana getSignaturesForAddress doesn't give details
                to: address,
                value: "0.0",
                timestamp: Date(timeIntervalSince1970: blockTime),
                chain: .solana
            )
        }
        
        return TransactionHistory(transactions: txs)
    }

    public func broadcast(signedTx: Data, chain: Chain) async throws -> String {
        switch chain {
        case .ethereum:
            return try await ethProvider.broadcast(signedTx: signedTx, chain: .ethereum)
        default:
            // TODO: Implement real BTC/SOL transaction broadcasting
            try await Task.sleep(nanoseconds: 1_000_000_000)
            return "0xBroadcastSuccess\(chain.rawValue)"
        }
    }

    public func fetchPrice(chain: Chain) async throws -> Decimal {
        try await ethProvider.fetchPrice(chain: chain)
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
