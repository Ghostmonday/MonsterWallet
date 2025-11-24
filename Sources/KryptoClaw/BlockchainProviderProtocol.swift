import Foundation

public enum Chain: String, CaseIterable, Codable, Hashable {
    case ethereum = "ETH"
    case bitcoin = "BTC"
    case solana = "SOL"

    public var displayName: String {
        switch self {
        case .ethereum: "Ethereum"
        case .bitcoin: "Bitcoin"
        case .solana: "Solana"
        }
    }

    public var nativeCurrency: String {
        rawValue
    }

    public var decimals: Int {
        switch self {
        case .ethereum: 18
        case .bitcoin: 8
        case .solana: 9
        }
    }
}

public struct Balance: Codable, Equatable {
    public let amount: String // BigInt as String
    public let currency: String
    public let decimals: Int
    public let usdValue: Decimal? // Added for V2 Portfolio

    public init(amount: String, currency: String, decimals: Int, usdValue: Decimal? = nil) {
        self.amount = amount
        self.currency = currency
        self.decimals = decimals
        self.usdValue = usdValue
    }
}

public struct TransactionSummary: Codable, Equatable {
    public let hash: String
    public let from: String
    public let to: String
    public let value: String
    public let timestamp: Date
    public let chain: Chain

    public init(hash: String, from: String, to: String, value: String, timestamp: Date, chain: Chain) {
        self.hash = hash
        self.from = from
        self.to = to
        self.value = value
        self.timestamp = timestamp
        self.chain = chain
    }
}

public struct TransactionHistory: Codable, Equatable {
    public let transactions: [TransactionSummary]

    public init(transactions: [TransactionSummary]) {
        self.transactions = transactions
    }
}

public enum BlockchainError: Error {
    case networkError(Error)
    case invalidAddress
    case rpcError(String)
    case parsingError
    case unsupportedChain
    case insufficientFunds
}

public protocol BlockchainProviderProtocol {
    func fetchBalance(address: String, chain: Chain) async throws -> Balance
    func fetchHistory(address: String, chain: Chain) async throws -> TransactionHistory
    func broadcast(signedTx: Data, chain: Chain) async throws -> String // TxHash
    func fetchPrice(chain: Chain) async throws -> Decimal
    func estimateGas(to: String, value: String, data: Data, chain: Chain) async throws -> GasEstimate
}
