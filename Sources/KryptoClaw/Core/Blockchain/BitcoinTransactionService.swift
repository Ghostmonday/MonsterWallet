import Foundation

/// Service for handling Bitcoin transaction construction, signing, and broadcasting.
/// Pending implementation using BitcoinKit or similar library.
public class BitcoinTransactionService {
    public init() {}

    public enum ServiceError: Error {
        case notImplemented
    }

    // TODO: Implement Bitcoin transaction creation
    public func createTransaction(to address: String, amountSats: UInt64) async throws -> Data {
        // Safe fail instead of crash
        throw ServiceError.notImplemented
    }
}
