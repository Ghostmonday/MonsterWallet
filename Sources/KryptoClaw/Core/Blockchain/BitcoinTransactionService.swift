import Foundation

// TODO: GEMINI 3 INSTRUCTIONS
// =========================================================================================
// A) SKELETON INSTRUCTIONS:
//    This service handles Bitcoin-specific transaction construction, signing, and broadcasting.
//    - It should interact with a lower-level library (like BitcoinKit or similar via FFI) or
//      construct raw transactions manually if using `CryptoSwift` primitives.
//    - It needs to conform to a `TransactionSigner` protocol.
//
// B) IMPLEMENTATION INSTRUCTIONS:
//    1. Implement `prepareTransaction(to:amount:fee:)` returning a raw unsigned transaction.
//    2. Implement `sign(transaction:privateKey:)` returning signed hex.
//       - Must handle UTXO selection (Coin Selection Algorithm).
//       - Must handle fee calculation (Bytes * Sat/vByte).
//    3. Integrate with `MultiChainProvider` to fetch UTXOs (`fetchBitcoinBalance` logic needs expanding to return UTXO set).
//    4. Use the existing `openseaAPIKey` or add a new `BlockstreamAPIKey` if we switch providers.
// =========================================================================================

public class BitcoinTransactionService {
    public init() {}

    public func createTransaction(to address: String, amountSats: UInt64) async throws -> Data {
        fatalError("Not implemented")
    }
}
