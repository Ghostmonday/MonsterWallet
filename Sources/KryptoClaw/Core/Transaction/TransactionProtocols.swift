import Foundation

public struct Transaction: Codable, Equatable {
    public let from: String
    public let to: String
    public let value: String
    public let data: Data
    public let nonce: UInt64
    public let gasLimit: UInt64
    public let maxFeePerGas: String
    public let maxPriorityFeePerGas: String
    public let chainId: Int

    public init(from: String, to: String, value: String, data: Data, nonce: UInt64, gasLimit: UInt64, maxFeePerGas: String, maxPriorityFeePerGas: String, chainId: Int) {
        self.from = from
        self.to = to
        self.value = value
        self.data = data
        self.nonce = nonce
        self.gasLimit = gasLimit
        self.maxFeePerGas = maxFeePerGas
        self.maxPriorityFeePerGas = maxPriorityFeePerGas
        self.chainId = chainId
    }
}

public struct SimulationResult: Codable, Equatable {
    public let success: Bool
    public let estimatedGasUsed: UInt64
    public let balanceChanges: [String: String] // Address -> Delta
    public let error: String?

    public init(success: Bool, estimatedGasUsed: UInt64, balanceChanges: [String: String], error: String?) {
        self.success = success
        self.estimatedGasUsed = estimatedGasUsed
        self.balanceChanges = balanceChanges
        self.error = error
    }
}

public enum RiskLevel: String, Codable {
    case low
    case medium
    case high
    case critical
}

public struct RiskAlert: Codable, Equatable {
    public let level: RiskLevel
    public let description: String

    public init(level: RiskLevel, description: String) {
        self.level = level
        self.description = description
    }
}

public protocol TransactionSimulatorProtocol {
    func simulate(tx: Transaction) async throws -> SimulationResult
}

public struct GasEstimate: Codable, Equatable {
    public let gasLimit: UInt64
    public let maxFeePerGas: String
    public let maxPriorityFeePerGas: String

    public init(gasLimit: UInt64, maxFeePerGas: String, maxPriorityFeePerGas: String) {
        self.gasLimit = gasLimit
        self.maxFeePerGas = maxFeePerGas
        self.maxPriorityFeePerGas = maxPriorityFeePerGas
    }
}

public protocol RoutingProtocol {
    func estimateGas(to: String, value: String, data: Data, chain: Chain) async throws -> GasEstimate
    func getTransactionCount(address: String) async throws -> UInt64
}

public protocol SecurityPolicyProtocol {
    func analyze(result: SimulationResult, tx: Transaction) -> [RiskAlert]
    func onBreach(alert: RiskAlert)
}
