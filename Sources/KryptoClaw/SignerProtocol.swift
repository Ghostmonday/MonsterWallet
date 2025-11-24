import Foundation

public struct SignedData: Codable, Equatable {
    public let raw: Data
    public let signature: Data
    public let txHash: String

    public init(raw: Data, signature: Data, txHash: String) {
        self.raw = raw
        self.signature = signature
        self.txHash = txHash
    }
}

public protocol SignerProtocol {
    func signTransaction(tx: Transaction) async throws -> SignedData
    func signMessage(message: String) async throws -> Data
}
