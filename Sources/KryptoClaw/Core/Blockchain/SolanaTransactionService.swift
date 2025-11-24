import Foundation

/// Service for handling Solana transaction construction.
/// Pending implementation for binary message formatting and Ed25519 signing.
public class SolanaTransactionService {
    public init() {}

    public enum ServiceError: Error {
        case notImplemented
    }

    // TODO: Implement Solana transaction creation (sendSol)
    public func sendSol(to destination: String, amountLamports: UInt64) async throws -> String {
        // Safe fail instead of crash
        throw ServiceError.notImplemented
    }
}
