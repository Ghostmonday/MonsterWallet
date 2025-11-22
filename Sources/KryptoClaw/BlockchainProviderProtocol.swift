import Foundation

public enum Chain: String, CaseIterable {
    case ethereum
    case solana
    case bitcoin
}

public struct Balance: Codable, Equatable {
    public let amount: String // BigInt as String to avoid precision loss
    public let currency: String
    public let decimals: Int
    
    public init(amount: String, currency: String, decimals: Int) {
        self.amount = amount
        self.currency = currency
        self.decimals = decimals
    }
}

public struct TransactionSummary: Codable, Equatable {
    public let hash: String
    public let from: String
    public let to: String
    public let value: String
    public let timestamp: Date
    
    public init(hash: String, from: String, to: String, value: String, timestamp: Date) {
        self.hash = hash
        self.from = from
        self.to = to
        self.value = value
        self.timestamp = timestamp
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
}

public protocol BlockchainProviderProtocol {
    func fetchBalance(address: String, chain: Chain) async throws -> Balance
    func fetchHistory(address: String, chain: Chain) async throws -> TransactionHistory
    func broadcast(signedTx: Data) async throws -> String // TxHash
}
