import Foundation

public struct RecoveryShare: Codable, Equatable {
    public let id: Int
    public let data: String
    public let threshold: Int

    public init(id: Int, data: String, threshold: Int) {
        self.id = id
        self.data = data
        self.threshold = threshold
    }
}

public protocol RecoveryStrategyProtocol {
    func generateShares(seed: String, total: Int, threshold: Int) throws -> [RecoveryShare]
    func reconstruct(shares: [RecoveryShare]) throws -> String
}
