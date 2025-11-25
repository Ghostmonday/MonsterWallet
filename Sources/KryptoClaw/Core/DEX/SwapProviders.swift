import Foundation

public struct SwapQuote: Codable {
    public let fromToken: String
    public let toToken: String
    public let inAmount: String
    public let outAmount: String
    public let priceImpact: Double?
    public let provider: String
    public let data: Data? // Transaction data for the swap
}

public protocol SwapProviderProtocol {
    func getQuote(from: String, to: String, amount: String) async throws -> SwapQuote
}

// MARK: - Jupiter (Solana)
public class JupiterSwapProvider: SwapProviderProtocol {
    private let baseURL = "https://quote-api.jup.ag/v6"
    
    public init() {}
    
    public func getQuote(from: String, to: String, amount: String) async throws -> SwapQuote {
        // Jupiter requires Mint addresses.
        // For simplicity, we assume 'from' and 'to' are already Mint addresses.
        // If they are symbols (SOL, USDC), we need a mapping.
        // Mapping is complex, so we'll assume valid mints are passed or handle common ones.
        
        let inputMint = resolveMint(from)
        let outputMint = resolveMint(to)
        
        var components = URLComponents(string: "\(baseURL)/quote")!
        components.queryItems = [
            URLQueryItem(name: "inputMint", value: inputMint),
            URLQueryItem(name: "outputMint", value: outputMint),
            URLQueryItem(name: "amount", value: amount),
            URLQueryItem(name: "slippageBps", value: "50") // 0.5%
        ]
        
        guard let url = components.url else { throw BlockchainError.invalidAddress }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw BlockchainError.networkError(NSError(domain: "Jupiter", code: (response as? HTTPURLResponse)?.statusCode ?? 500))
        }
        
        struct JupiterResponse: Codable {
            let outAmount: String
            let priceImpactPct: String
        }
        
        let result = try JSONDecoder().decode(JupiterResponse.self, from: data)
        
        return SwapQuote(
            fromToken: from,
            toToken: to,
            inAmount: amount,
            outAmount: result.outAmount,
            priceImpact: Double(result.priceImpactPct),
            provider: "Jupiter",
            data: nil // Quote doesn't give tx data, /swap endpoint does.
        )
    }
    
    private func resolveMint(_ symbol: String) -> String {
        switch symbol.uppercased() {
        case "SOL": return "So11111111111111111111111111111111111111112"
        case "USDC": return "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"
        case "USDT": return "Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB"
        default: return symbol // Assume it's a mint address
        }
    }
}

// MARK: - 1inch (Ethereum)
public class OneInchSwapProvider: SwapProviderProtocol {
    private let baseURL = "https://api.1inch.dev/swap/v5.2/1"
    private let apiKey = "YOUR_1INCH_API_KEY" // Placeholder
    
    public init() {}
    
    public func getQuote(from: String, to: String, amount: String) async throws -> SwapQuote {
        // 1inch requires Token addresses.
        // ETH is "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE"
        
        let src = resolveToken(from)
        let dst = resolveToken(to)
        
        var components = URLComponents(string: "\(baseURL)/quote")!
        components.queryItems = [
            URLQueryItem(name: "src", value: src),
            URLQueryItem(name: "dst", value: dst),
            URLQueryItem(name: "amount", value: amount)
        ]
        
        guard let url = components.url else { throw BlockchainError.invalidAddress }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        // Mocking response if no API key
        if apiKey == "YOUR_1INCH_API_KEY" {
             // Return a mock quote for demo purposes
             let rate = 1800.0 // Mock ETH price
             let out = (Double(amount) ?? 0) * rate
             return SwapQuote(
                 fromToken: from,
                 toToken: to,
                 inAmount: amount,
                 outAmount: String(format: "%.0f", out),
                 priceImpact: 0.1,
                 provider: "1inch (Mock)",
                 data: nil
             )
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
             throw BlockchainError.networkError(NSError(domain: "1inch", code: (response as? HTTPURLResponse)?.statusCode ?? 500))
        }
        
        struct OneInchResponse: Codable {
            let toAmount: String
        }
        
        let result = try JSONDecoder().decode(OneInchResponse.self, from: data)
        
        return SwapQuote(
            fromToken: from,
            toToken: to,
            inAmount: amount,
            outAmount: result.toAmount,
            priceImpact: nil, // 1inch quote might not return impact in simple view
            provider: "1inch",
            data: nil
        )
    }
    
    private func resolveToken(_ symbol: String) -> String {
        switch symbol.uppercased() {
        case "ETH": return "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE"
        case "USDC": return "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"
        case "USDT": return "0xdAC17F958D2ee523a2206206994597C13D831ec7"
        default: return symbol
        }
    }
}
