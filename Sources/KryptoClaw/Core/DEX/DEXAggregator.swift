import Foundation

/// Aggregates quotes from multiple DEX providers (1inch, Uniswap, Jupiter, etc.).
/// Abstracts API differences to provide the best swap rates.
public class DEXAggregator {
    private let jupiter = JupiterSwapProvider()
    private let oneInch = OneInchSwapProvider()
    
    public init() {}

    /// Fetches the best quote for a swap.
    /// - Parameters:
    ///   - from: Source token address or symbol
    ///   - to: Destination token address or symbol
    ///   - amount: Amount in base units
    ///   - chain: The blockchain to swap on
    /// - Returns: A SwapQuote object containing the best rate.
    public func getQuote(from: String, to: String, amount: String, chain: HDWalletService.Chain) async throws -> SwapQuote {
        switch chain {
        case .solana:
            return try await jupiter.getQuote(from: from, to: to, amount: amount)
        case .ethereum:
            return try await oneInch.getQuote(from: from, to: to, amount: amount)
        case .bitcoin:
            throw BlockchainError.rpcError("Swaps not supported for Bitcoin")
        }
    }
}
