import BigInt
import Foundation
import OSLog

public class ModularHTTPProvider: BlockchainProviderProtocol {
    private let session: URLSession
    private let logger = Logger(subsystem: "com.kryptoclaw.app", category: "ModularHTTPProvider")
    
    // Shared number formatter for ETH formatting (thread-safe for read-only use)
    private static let ethFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 6
        formatter.minimumFractionDigits = 2
        formatter.decimalSeparator = "."
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        return formatter
    }()

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
        guard chain == .ethereum else {
            // Only ETH history supported in V1
            return TransactionHistory(transactions: [])
        }
        
        // For local testnet, scan recent blocks for transactions
        if AppConfig.isTestEnvironment {
            return try await fetchLocalTestnetHistory(address: address, chain: chain)
        }
        
        // For mainnet, would use Etherscan API or similar indexer
        // TODO: Implement Etherscan API integration
        return TransactionHistory(transactions: [])
    }
    
    private func fetchLocalTestnetHistory(address: String, chain: Chain) async throws -> TransactionHistory {
        let url = AppConfig.rpcURL
        let normalizedAddress = address.lowercased()
        
        // Shared number formatter (thread-safe for read-only use)
        let formatter: NumberFormatter = {
            let f = NumberFormatter()
            f.maximumFractionDigits = 6
            f.minimumFractionDigits = 2
            f.decimalSeparator = "."
            f.usesGroupingSeparator = false
            return f
        }()
        
        // Get current block number
        let blockNumPayload: [String: Any] = [
            "jsonrpc": "2.0",
            "method": "eth_blockNumber",
            "params": [],
            "id": 1
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: blockNumPayload)
        request.timeoutInterval = 10.0
        
        let (blockNumData, _) = try await session.data(for: request)
        guard let blockNumJson = try? JSONSerialization.jsonObject(with: blockNumData) as? [String: Any],
              let blockNumHex = blockNumJson["result"] as? String,
              let currentBlock = UInt64(blockNumHex.dropFirst(2), radix: 16) else {
            logger.warning("Failed to get current block number")
            return TransactionHistory(transactions: [])
        }
        
        // Scan last 50 blocks (reasonable for local testnet)
        let blocksToScan = min(currentBlock, 50)
        let startBlock = max(0, currentBlock - blocksToScan)
        let blockRange = Array(stride(from: currentBlock, through: startBlock, by: -1))
        
        // Fetch blocks in parallel with concurrency limit
        var allTransactions: [TransactionSummary] = []
        let maxConcurrency = 5 // Limit concurrent requests
        
        await withTaskGroup(of: [TransactionSummary].self) { group in
            // Add all tasks
            for blockNum in blockRange {
                group.addTask { [weak self] in
                    guard let self = self else { return [] }
                    return await self.fetchTransactionsFromBlock(
                        blockNum: blockNum,
                        address: normalizedAddress,
                        chain: chain,
                        formatter: formatter,
                        url: url
                    )
                }
            }
            
            // Process results as they come in with early termination
            for await blockTransactions in group {
                allTransactions.append(contentsOf: blockTransactions)
                
                // Early termination if we have enough transactions
                if allTransactions.count >= 20 {
                    group.cancelAll()
                    break
                }
            }
        }
        
        // Sort by timestamp descending and limit to 20
        allTransactions.sort { $0.timestamp > $1.timestamp }
        return TransactionHistory(transactions: Array(allTransactions.prefix(20)))
    }
    
    /// Fetch transactions from a single block
    private func fetchTransactionsFromBlock(
        blockNum: UInt64,
        address: String,
        chain: Chain,
        formatter: NumberFormatter,
        url: URL
    ) async -> [TransactionSummary] {
        let blockPayload: [String: Any] = [
            "jsonrpc": "2.0",
            "method": "eth_getBlockByNumber",
            "params": ["0x" + String(blockNum, radix: 16), true],
            "id": Int(blockNum)
        ]
        
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: blockPayload)
            request.timeoutInterval = 5.0 // Shorter timeout for individual blocks
            
            let (blockData, _) = try await session.data(for: request)
            
            guard let blockJson = try? JSONSerialization.jsonObject(with: blockData) as? [String: Any],
                  let result = blockJson["result"] as? [String: Any],
                  let txArray = result["transactions"] as? [[String: Any]],
                  let timestampHex = result["timestamp"] as? String else {
                return []
            }
            
            let timestamp = UInt64(timestampHex.dropFirst(2), radix: 16) ?? 0
            let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
            
            var transactions: [TransactionSummary] = []
            
            for tx in txArray {
                guard let from = (tx["from"] as? String)?.lowercased(),
                      let to = (tx["to"] as? String)?.lowercased(),
                      let hash = tx["hash"] as? String,
                      let valueHex = tx["value"] as? String else {
                    continue
                }
                
                // Filter transactions involving our address
                if from == address || to == address {
                    // Convert value from wei to ETH
                    let weiValue = BigUInt(valueHex.dropFirst(2), radix: 16) ?? BigUInt(0)
                    let ethValue = Decimal(string: String(weiValue)) ?? 0
                    let eth = ethValue / pow(10, 18)
                    let valueString = formatter.string(from: eth as NSNumber) ?? "0.00"
                    
                    transactions.append(TransactionSummary(
                        hash: hash,
                        from: tx["from"] as? String ?? "",
                        to: tx["to"] as? String ?? "",
                        value: valueString,
                        timestamp: date,
                        chain: chain
                    ))
                }
            }
            
            return transactions
        } catch {
            logger.debug("Failed to fetch block \(blockNum): \(error.localizedDescription)")
            return []
        }
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

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, (200 ... 299).contains(httpResponse.statusCode) else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            logger.error("HTTP Error: \(statusCode)")
            throw BlockchainError.networkError(NSError(domain: "HTTP", code: statusCode, userInfo: nil))
        }
        
        logger.debug("HTTP Status: \(httpResponse.statusCode)")

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
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
        // Use shared formatter instance (thread-safe for read-only use)
        let amountString = Self.ethFormatter.string(from: ethValue as NSNumber) ?? "0.00"
        
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

        // Convert value to hex - handle both decimal and hex strings
        let valueHex: String
        if value.hasPrefix("0x") {
            // Already hex, remove prefix and use as-is
            valueHex = String(value.dropFirst(2))
        } else if let decimalValue = BigUInt(value) {
            // Decimal string, convert to hex
            valueHex = String(decimalValue, radix: 16)
        } else {
            throw BlockchainError.parsingError
        }
        
        let estimatePayload: [String: Any] = [
            "jsonrpc": "2.0",
            "method": "eth_estimateGas",
            "params": [[
                "to": to,
                "value": "0x" + valueHex,
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

        let (data, response) = try await session.data(for: request)
        
        // Check HTTP status
        if let httpResponse = response as? HTTPURLResponse,
           !(200...299).contains(httpResponse.statusCode) {
            throw BlockchainError.networkError(
                NSError(domain: "HTTP", code: httpResponse.statusCode, userInfo: nil)
            )
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw BlockchainError.parsingError
        }

        // Check for RPC error
        if let err = json["error"] as? [String: Any] {
            let message = err["message"] as? String ?? "RPC Error"
            let code = err["code"] as? Int ?? -1
            logger.error("RPC Error [\(code)]: \(message)")
            throw BlockchainError.rpcError(message)
        }
        
        guard let result = json["result"] as? String else {
            logger.error("Missing result in RPC response: \(json)")
            throw BlockchainError.parsingError
        }
        
        return result
    }
}
