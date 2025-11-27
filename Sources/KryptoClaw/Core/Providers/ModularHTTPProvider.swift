import BigInt
import Foundation
import OSLog

public class ModularHTTPProvider: BlockchainProviderProtocol {
    private let session: URLSession
    private let logger = Logger(subsystem: "com.kryptoclaw.app", category: "ModularHTTPProvider")

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func fetchBalance(address: String, chain: Chain) async throws -> Balance {
        switch chain {
        case .ethereum:
            return try await fetchEthereumBalance(address: address)
        default:
            throw BlockchainError.unsupportedChain
        }
    }

    public func fetchHistory(address: String, chain: Chain) async throws -> TransactionHistory {
        // TODO: Implement actual history fetching using Etherscan API (or similar indexer)
        // Standard RPC nodes do not efficiently support "get history by address"

        try? await Task.sleep(nanoseconds: 300_000_000)

        let mockTxs = [
            TransactionSummary(
                hash: "0x7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b",
                from: address,
                to: "0xRecipientAddr...",
                value: "0.05",
                timestamp: Date().addingTimeInterval(-3600),
                chain: chain
            ),
            TransactionSummary(
                hash: "0x1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b",
                from: "0xWhaleWallet...",
                to: address,
                value: "2.50",
                timestamp: Date().addingTimeInterval(-86400),
                chain: chain
            ),
            TransactionSummary(
                hash: "0x9a8b7c6d5e4f3a2b1c0d9e8f7a6b5c4d3e2f1a0b",
                from: address,
                to: "0xUniswapRouter...",
                value: "0.10",
                timestamp: Date().addingTimeInterval(-172_800),
                chain: chain
            ),
        ]

        return TransactionHistory(transactions: mockTxs)
    }

    public func broadcast(signedTx: Data, chain: Chain) async throws -> String {
        guard chain == .ethereum else { throw BlockchainError.unsupportedChain }

        // Note: `signedTx` must be RLP-encoded data from SimpleP2PSigner (via web3.swift)
        let txHex = signedTx.hexString

        let url = AppConfig.rpcURL

        let payload: [String: Any] = [
            "jsonrpc": "2.0",
            "method": "eth_sendRawTransaction",
            "params": ["0x" + txHex],
            "id": Int.random(in: 1 ... 1000),
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

        guard let result = json["result"] as? String else {
            throw BlockchainError.parsingError
        }

        return result
    }

    private func fetchEthereumBalance(address: String) async throws -> Balance {
        let url = AppConfig.rpcURL
        
        NSLog("🟢🟢🟢 fetchEthereumBalance CALLED 🟢🟢🟢")
        NSLog("🟢 Address: %@", address)
        NSLog("🟢 URL: %@", url.absoluteString)
        
        logger.debug("Fetching ETH balance for \(address) from \(url.absoluteString)")

        let payload: [String: Any] = [
            "jsonrpc": "2.0",
            "method": "eth_getBalance",
            "params": [address, "latest"],
            "id": 1,
        ]

        guard let httpBody = try? JSONSerialization.data(withJSONObject: payload) else {
            throw BlockchainError.parsingError
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = httpBody
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30.0

        NSLog("🟢 Making HTTP request...")
        let (data, response) = try await session.data(for: request)
        NSLog("🟢 Got response!")

        guard let httpResponse = response as? HTTPURLResponse, (200 ... 299).contains(httpResponse.statusCode) else {
            NSLog("🔴 HTTP Error: %d", (response as? HTTPURLResponse)?.statusCode ?? -1)
            logger.error("HTTP Error: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
            throw BlockchainError.networkError(NSError(domain: "HTTP", code: (response as? HTTPURLResponse)?.statusCode ?? 500, userInfo: nil))
        }
        
        NSLog("🟢 HTTP Status: %d", httpResponse.statusCode)
        if let responseStr = String(data: data, encoding: .utf8) {
            NSLog("🟢 Response body: %@", responseStr)
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            NSLog("🔴 JSON Parsing Failed")
            logger.error("JSON Parsing Failed")
            throw BlockchainError.parsingError
        }

        if let error = json["error"] as? [String: Any], let message = error["message"] as? String {
            logger.error("RPC Error: \(message)")
            throw BlockchainError.rpcError(message)
        }

        guard let hexResult = json["result"] as? String else {
            logger.error("No result in response: \(json)")
            throw BlockchainError.parsingError
        }
        
        // Convert hex string to decimal string (wei), then format as ETH
        let hexString = hexResult.hasPrefix("0x") ? String(hexResult.dropFirst(2)) : hexResult
        
        guard let weiValue = BigUInt(hexString, radix: 16) else {
            logger.error("Failed to parse hex balance: \(hexResult)")
            throw BlockchainError.parsingError
        }
        
        // Convert wei to ETH (divide by 10^18)
        // Use Decimal for better precision handling than Double
        let weiDecimal = Decimal(string: String(weiValue)) ?? 0
        let ethValue = weiDecimal / pow(10, 18)
        
        // Format to string, avoiding scientific notation
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 6
        formatter.minimumFractionDigits = 2
        formatter.decimalSeparator = "."
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false // Plain number string
        
        let amountString = formatter.string(from: ethValue as NSNumber) ?? "0.00"
        
        logger.info("Balance fetched: \(hexResult) -> \(amountString) ETH")

        return Balance(amount: amountString, currency: "ETH", decimals: 18)
    }

    public func fetchPrice(chain: Chain) async throws -> Decimal {
        let id = switch chain {
        case .ethereum: "ethereum"
        case .bitcoin: "bitcoin"
        case .solana: "solana"
        }

        let urlString = "https://api.coingecko.com/api/v3/simple/price?ids=\(id)&vs_currencies=usd"
        guard let url = URL(string: urlString) else {
            throw BlockchainError.parsingError
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 30.0
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, (200 ... 299).contains(httpResponse.statusCode) else {
            throw BlockchainError.networkError(NSError(domain: "HTTP", code: (response as? HTTPURLResponse)?.statusCode ?? 500, userInfo: nil))
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: [String: Double]],
              let priceData = json[id],
              let price = priceData["usd"]
        else {
            throw BlockchainError.parsingError
        }

        return Decimal(price)
    }

    public func estimateGas(to: String, value: String, data: Data, chain: Chain) async throws -> GasEstimate {
        guard chain == .ethereum else {
            // TODO: Implement BTC/SOL fee estimation (different fee models)
            return GasEstimate(gasLimit: 21000, maxFeePerGas: "20000000000", maxPriorityFeePerGas: "2000000000")
        }

        let url = AppConfig.rpcURL

        let estimatePayload: [String: Any] = [
            "jsonrpc": "2.0",
            "method": "eth_estimateGas",
            "params": [[
                "to": to,
                "value": "0x" + (BigUInt(value).map { String($0, radix: 16) } ?? "0"),
                "data": "0x" + data.hexString,
            ]],
            "id": 1,
        ]

        let limitHex = try await rpcCall(url: url, payload: estimatePayload)
        let gasLimit = UInt64(limitHex.dropFirst(2), radix: 16) ?? 21000

        let pricePayload: [String: Any] = [
            "jsonrpc": "2.0",
            "method": "eth_gasPrice",
            "params": [],
            "id": 2,
        ]
        let priceHex = try await rpcCall(url: url, payload: pricePayload)
        let baseFee = BigUInt(priceHex.dropFirst(2), radix: 16) ?? BigUInt(20_000_000_000)

        let priorityFee = BigUInt(2_000_000_000)
        let maxFee = baseFee + priorityFee

        return GasEstimate(
            gasLimit: gasLimit,
            maxFeePerGas: String(maxFee),
            maxPriorityFeePerGas: String(priorityFee)
        )
    }

    private func rpcCall(url: URL, payload: [String: Any]) async throws -> String {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30.0

        let (data, _) = try await session.data(for: request)
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { throw BlockchainError.parsingError }

        if let err = json["error"] as? [String: Any] { throw BlockchainError.rpcError(err["message"] as? String ?? "RPC Error") }
        return json["result"] as? String ?? "0x0"
    }
}
