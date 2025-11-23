import Foundation

// TODO: GEMINI 3 INSTRUCTIONS
// =========================================================================================
// A) SKELETON INSTRUCTIONS:
//    This service handles Solana transaction construction.
//    - Solana transactions differ significantly from EVM (Accounts, RecentBlockhash, Instructions).
//    - Needs to construct the binary message format for Solana.
//
// B) IMPLEMENTATION INSTRUCTIONS:
//    1. Define `SolanaInstruction`, `SolanaHeader`, `SolanaTransaction` structs.
//    2. Implement `serialize()` for the transaction message.
//    3. Implement `sign(message:keypair:)` using Ed25519 (via `CryptoSwift` or `tweetnacl`).
//    4. The `MultiChainProvider` already has a basic `fetchSolanaBalance`. Extend it to:
//       - `getRecentBlockhash` (Required for tx validity).
//       - `getMinimumBalanceForRentExemption`.
//    5. Add Token Program support (SPL Tokens) if V2 requires it.
// =========================================================================================

public class SolanaTransactionService {
    public init() {}

    public func sendSol(to destination: String, amountLamports: UInt64) async throws -> String {
        fatalError("Not implemented")
    }
}
