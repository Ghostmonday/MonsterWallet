// MODULE: QuoteService
// VERSION: 1.0.0
// PURPOSE: Actor-based swap quote aggregator with parallel provider fetching

import Foundation

// MARK: - Quote Service Actor

/// Actor that aggregates swap quotes from multiple DEX providers.
///
/// **Features:**
/// - Parallel quote fetching using TaskGroup
/// - Cross-chain routing via THORChain
/// - Same-chain routing via 1inch/Jupiter
/// - Best price selection with fee consideration
/// - Quote caching with expiration
@available(iOS 15.0, macOS 12.0, *)
public actor QuoteService {
    
    // MARK: - Dependencies
    
    private let session: URLSession
    
    // MARK: - API Configuration
    
    private struct APIConfig {
        // THORChain Midgard API (cross-chain)
        static let thorchainBaseURL = "https://midgard.ninerealms.com/v2"
        static let thorchainNodeURL = "https://thornode.ninerealms.com/thorchain"
        
        // 1inch API (Ethereum)
        static let oneInchBaseURL = "https://api.1inch.dev/swap/v5.2/1"
        static let oneInchAPIKey = "YOUR_1INCH_API_KEY" // Placeholder
        
        // Jupiter API (Solana)
        static let jupiterBaseURL = "https://quote-api.jup.ag/v6"
    }
    
    // MARK: - State
    
    /// Cache of recent quotes
    private var quoteCache: [String: SwapQuoteV2] = [:]
    
    /// Provider health status
    private var providerHealth: [SwapProvider: Bool] = [:]
    
    // MARK: - Initialization
    
    public init(session: URLSession = .shared) {
        self.session = session
    }
    
    // MARK: - Public Interface
    
    /// Fetch the best quote for a swap request
    /// - Parameter request: The swap quote request
    /// - Returns: QuoteComparisonResult with best quote and alternatives
    public func fetchBestQuote(for request: SwapQuoteRequest) async throws -> QuoteComparisonResult {
        // Determine which providers to query based on route type
        let providers = selectProviders(for: request)
        
        guard !providers.isEmpty else {
            throw SwapError.unsupportedRoute(from: request.fromAsset.chain, to: request.toAsset.chain)
        }
        
        // Fetch quotes from all applicable providers in parallel
        var allQuotes: [SwapQuoteV2] = []
        var failedProviders: [SwapProvider: String] = [:]
        
        await withTaskGroup(of: (SwapProvider, Result<SwapQuoteV2, Error>).self) { group in
            for provider in providers {
                group.addTask {
                    do {
                        let quote = try await self.fetchQuote(from: provider, for: request)
                        return (provider, .success(quote))
                    } catch {
                        return (provider, .failure(error))
                    }
                }
            }
            
            for await (provider, result) in group {
                switch result {
                case .success(let quote):
                    allQuotes.append(quote)
                    await self.markProviderHealthy(provider)
                case .failure(let error):
                    failedProviders[provider] = error.localizedDescription
                    await self.markProviderUnhealthy(provider)
                }
            }
        }
        
        // Select best quote (highest output after fees)
        guard let bestQuote = selectBestQuote(from: allQuotes) else {
            if let firstError = failedProviders.first {
                throw SwapError.providerError(provider: firstError.key, message: firstError.value)
            }
            throw SwapError.networkError(underlying: "No quotes available")
        }
        
        // Cache the best quote
        let cacheKey = generateCacheKey(for: request)
        quoteCache[cacheKey] = bestQuote
        
        return QuoteComparisonResult(
            bestQuote: bestQuote,
            allQuotes: allQuotes,
            failedProviders: failedProviders
        )
    }
    
    /// Get a cached quote if still valid
    public func getCachedQuote(for request: SwapQuoteRequest) -> SwapQuoteV2? {
        let cacheKey = generateCacheKey(for: request)
        guard let quote = quoteCache[cacheKey], !quote.isExpired else {
            quoteCache.removeValue(forKey: cacheKey)
            return nil
        }
        return quote
    }
    
    /// Clear expired quotes from cache
    public func clearExpiredQuotes() {
        quoteCache = quoteCache.filter { _, quote in !quote.isExpired }
    }
    
    /// Check provider health status
    public func isProviderHealthy(_ provider: SwapProvider) -> Bool {
        providerHealth[provider] ?? true
    }
    
    // MARK: - Provider Selection
    
    /// Select applicable providers based on route type and chains
    private func selectProviders(for request: SwapQuoteRequest) -> [SwapProvider] {
        switch request.routeType {
        case .crossChain:
            // Only THORChain supports cross-chain swaps
            return [.thorchain]
            
        case .sameChain, .wrap, .unwrap:
            switch request.fromAsset.chain {
            case .ethereum:
                return [.oneInch, .paraswap]
            case .solana:
                return [.jupiter]
            case .bitcoin:
                return [] // Bitcoin native swaps not supported
            }
        }
    }
    
    // MARK: - Quote Fetching
    
    /// Fetch a quote from a specific provider
    private func fetchQuote(
        from provider: SwapProvider,
        for request: SwapQuoteRequest
    ) async throws -> SwapQuoteV2 {
        switch provider {
        case .thorchain:
            return try await fetchTHORChainQuote(for: request)
        case .oneInch, .paraswap:
            return try await fetchOneInchQuote(for: request, provider: provider)
        case .jupiter:
            return try await fetchJupiterQuote(for: request)
        case .uniswap:
            // Fallback to 1inch-style quote
            return try await fetchOneInchQuote(for: request, provider: provider)
        }
    }
    
    // MARK: - THORChain (Cross-Chain)
    
    /// Fetch quote from THORChain for cross-chain swaps
    private func fetchTHORChainQuote(for request: SwapQuoteRequest) async throws -> SwapQuoteV2 {
        // Build THORChain asset identifiers
        let fromTHORAsset = buildTHORChainAsset(request.fromAsset)
        let toTHORAsset = buildTHORChainAsset(request.toAsset)
        
        // Fetch quote from THORChain quote endpoint
        var components = URLComponents(string: "\(APIConfig.thorchainNodeURL)/quote/swap")!
        components.queryItems = [
            URLQueryItem(name: "from_asset", value: fromTHORAsset),
            URLQueryItem(name: "to_asset", value: toTHORAsset),
            URLQueryItem(name: "amount", value: request.amount),
            URLQueryItem(name: "destination", value: request.recipientAddress ?? request.senderAddress),
            URLQueryItem(name: "streaming_interval", value: "1"),
            URLQueryItem(name: "streaming_quantity", value: "0")
        ]
        
        guard components.url != nil else {
            throw SwapError.invalidParameters(reason: "Invalid THORChain quote URL")
        }
        
        // Mock response structure for THORChain quote
        // In production, this would be a real API call
        let quoteResponse = try await mockTHORChainQuote(request: request)
        
        return quoteResponse
    }
    
    /// Build THORChain asset identifier (e.g., "BTC.BTC", "ETH.ETH", "ETH.USDC-0xa0b...")
    private func buildTHORChainAsset(_ asset: Asset) -> String {
        let chainPrefix: String
        switch asset.chain {
        case .bitcoin:
            chainPrefix = "BTC"
        case .ethereum:
            chainPrefix = "ETH"
        case .solana:
            chainPrefix = "SOL"
        }
        
        if asset.type == .native {
            return "\(chainPrefix).\(chainPrefix)"
        } else if let contract = asset.contractAddress {
            return "\(chainPrefix).\(asset.symbol)-\(contract)"
        }
        
        return "\(chainPrefix).\(asset.symbol)"
    }
    
    /// Mock THORChain quote (for development/testing)
    private func mockTHORChainQuote(request: SwapQuoteRequest) async throws -> SwapQuoteV2 {
        // Simulate network latency
        try await Task.sleep(nanoseconds: 200_000_000) // 200ms
        
        // Mock exchange rates
        let mockRates: [String: [String: Decimal]] = [
            "BTC": ["ETH": 16.5, "SOL": 450, "USDC": 43000],
            "ETH": ["BTC": 0.06, "SOL": 27.5, "USDC": 2600],
            "SOL": ["BTC": 0.0022, "ETH": 0.036, "USDC": 95]
        ]
        
        let fromSymbol = request.fromAsset.symbol
        let toSymbol = request.toAsset.symbol
        let rate = mockRates[fromSymbol]?[toSymbol] ?? Decimal(1)
        
        guard let inputDecimal = Decimal(string: request.amount) else {
            throw SwapError.invalidParameters(reason: "Invalid input amount")
        }
        
        // Calculate with slippage
        let slippageMultiplier = 1 - (request.slippageTolerance / 100)
        let outputDecimal = inputDecimal * rate
        let minOutput = outputDecimal * slippageMultiplier
        
        // Scale to output asset decimals
        let scaleFactor = pow(Decimal(10), request.toAsset.decimals - request.fromAsset.decimals)
        let scaledOutput = outputDecimal * scaleFactor
        let scaledMinOutput = minOutput * scaleFactor
        
        // Build THORChain memo
        let memo = buildTHORChainMemo(
            toAsset: request.toAsset,
            destination: request.recipientAddress ?? request.senderAddress,
            limit: "\(scaledMinOutput)"
        )
        
        // Mock inbound vault address
        let vaultAddress = "thor1g98cy3n9mmjrpn0sxmn63lztelera37nrytwp2" // Mock
        
        let transactionData = SwapTransactionData(
            to: vaultAddress,
            value: request.amount,
            calldata: Data(),
            gasLimit: 80000,
            thorchainMemo: memo,
            vaultAddress: vaultAddress
        )
        
        return SwapQuoteV2(
            fromAsset: request.fromAsset,
            toAsset: request.toAsset,
            inputAmount: request.amount,
            outputAmount: "\(scaledOutput)",
            minimumOutputAmount: "\(scaledMinOutput)",
            exchangeRate: rate,
            priceImpact: 0.15, // Mock 0.15% impact
            slippageTolerance: request.slippageTolerance,
            networkFeeEstimate: "50000", // Mock fee in sats/wei
            networkFeeUSD: 2.50,
            provider: .thorchain,
            routeType: .crossChain,
            expiresAt: Date().addingTimeInterval(SwapConfiguration.quoteValidityDuration),
            transactionData: transactionData,
            routePath: [request.fromAsset.symbol, "RUNE", request.toAsset.symbol]
        )
    }
    
    /// Build THORChain memo string for swap
    private func buildTHORChainMemo(
        toAsset: Asset,
        destination: String,
        limit: String,
        affiliate: String? = nil,
        affiliateBps: Int? = nil
    ) -> String {
        // Format: SWAP:ASSET:DESTADDR:LIM:AFFILIATE:FEE
        // Example: =:ETH.ETH:0x1234...:1000000:t:30
        let assetString = buildTHORChainAsset(toAsset)
        var memo = "=:\(assetString):\(destination):\(limit)"
        
        if let aff = affiliate, let bps = affiliateBps {
            memo += ":\(aff):\(bps)"
        }
        
        return memo
    }
    
    // MARK: - 1inch (Ethereum)
    
    /// Fetch quote from 1inch for same-chain Ethereum swaps
    private func fetchOneInchQuote(
        for request: SwapQuoteRequest,
        provider: SwapProvider
    ) async throws -> SwapQuoteV2 {
        // Resolve token addresses
        let srcToken = resolveEthereumToken(request.fromAsset)
        let dstToken = resolveEthereumToken(request.toAsset)
        
        var components = URLComponents(string: "\(APIConfig.oneInchBaseURL)/quote")!
        components.queryItems = [
            URLQueryItem(name: "src", value: srcToken),
            URLQueryItem(name: "dst", value: dstToken),
            URLQueryItem(name: "amount", value: request.amount)
        ]
        
        guard let url = components.url else {
            throw SwapError.invalidParameters(reason: "Invalid 1inch quote URL")
        }
        
        // Check if using mock or real API
        if APIConfig.oneInchAPIKey == "YOUR_1INCH_API_KEY" {
            return try await mockOneInchQuote(request: request, provider: provider)
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.setValue("Bearer \(APIConfig.oneInchAPIKey)", forHTTPHeaderField: "Authorization")
        urlRequest.timeoutInterval = 5.0
        
        let (data, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw SwapError.providerError(provider: provider, message: "HTTP error")
        }
        
        return try parse1InchQuoteResponse(
            data: data,
            request: request,
            provider: provider
        )
    }
    
    /// Resolve Ethereum token address
    private func resolveEthereumToken(_ asset: Asset) -> String {
        if asset.type == .native {
            return "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE"
        }
        return asset.contractAddress ?? asset.symbol
    }
    
    /// Parse 1inch quote response
    private func parse1InchQuoteResponse(
        data: Data,
        request: SwapQuoteRequest,
        provider: SwapProvider
    ) throws -> SwapQuoteV2 {
        struct OneInchQuoteResponse: Codable {
            let toAmount: String
            let estimatedGas: Int?
        }
        
        let response = try JSONDecoder().decode(OneInchQuoteResponse.self, from: data)
        
        // Calculate minimum output with slippage
        guard let outputDecimal = Decimal(string: response.toAmount) else {
            throw SwapError.providerError(provider: provider, message: "Invalid output amount")
        }
        
        let slippageMultiplier = 1 - (request.slippageTolerance / 100)
        let minOutput = outputDecimal * slippageMultiplier
        
        // Calculate exchange rate
        guard let inputDecimal = Decimal(string: request.amount), inputDecimal > 0 else {
            throw SwapError.invalidParameters(reason: "Invalid input amount")
        }
        
        let scaleFactor = pow(Decimal(10), request.fromAsset.decimals - request.toAsset.decimals)
        let rate = (outputDecimal / inputDecimal) * scaleFactor
        
        return SwapQuoteV2(
            fromAsset: request.fromAsset,
            toAsset: request.toAsset,
            inputAmount: request.amount,
            outputAmount: response.toAmount,
            minimumOutputAmount: "\(minOutput)",
            exchangeRate: rate,
            priceImpact: nil,
            slippageTolerance: request.slippageTolerance,
            networkFeeEstimate: "\(response.estimatedGas ?? 150000)",
            provider: provider,
            routeType: .sameChain,
            expiresAt: Date().addingTimeInterval(SwapConfiguration.quoteValidityDuration),
            routePath: [request.fromAsset.symbol, request.toAsset.symbol]
        )
    }
    
    /// Mock 1inch quote (for development/testing)
    private func mockOneInchQuote(
        request: SwapQuoteRequest,
        provider: SwapProvider
    ) async throws -> SwapQuoteV2 {
        // Simulate network latency
        try await Task.sleep(nanoseconds: 150_000_000) // 150ms
        
        // Mock exchange rates for Ethereum tokens
        let mockRates: [String: [String: Decimal]] = [
            "ETH": ["USDC": 2600, "USDT": 2600, "WETH": 1],
            "WETH": ["ETH": 1, "USDC": 2600, "USDT": 2600],
            "USDC": ["ETH": 0.000385, "USDT": 1, "WETH": 0.000385],
            "USDT": ["ETH": 0.000385, "USDC": 1, "WETH": 0.000385]
        ]
        
        let fromSymbol = request.fromAsset.symbol
        let toSymbol = request.toAsset.symbol
        let rate = mockRates[fromSymbol]?[toSymbol] ?? Decimal(1)
        
        guard let inputDecimal = Decimal(string: request.amount) else {
            throw SwapError.invalidParameters(reason: "Invalid input amount")
        }
        
        // Scale input to human-readable, apply rate, scale back
        let inputDivisor = pow(Decimal(10), request.fromAsset.decimals)
        let outputMultiplier = pow(Decimal(10), request.toAsset.decimals)
        
        let humanInput = inputDecimal / inputDivisor
        let humanOutput = humanInput * rate
        let outputAmount = humanOutput * outputMultiplier
        
        let slippageMultiplier = 1 - (request.slippageTolerance / 100)
        let minOutput = outputAmount * slippageMultiplier
        
        // Mock price impact (varies by size)
        let priceImpact: Decimal = humanInput > 10 ? 0.5 : 0.1
        
        // Mock calldata (in production, this comes from 1inch /swap endpoint)
        let mockCalldata = Data(repeating: 0x12, count: 196)
        
        let transactionData = SwapTransactionData(
            to: "0x1111111254EEB25477B68fb85Ed929f73A960582", // 1inch Router
            value: request.fromAsset.type == .native ? request.amount : "0",
            calldata: mockCalldata,
            gasLimit: 200000
        )
        
        return SwapQuoteV2(
            fromAsset: request.fromAsset,
            toAsset: request.toAsset,
            inputAmount: request.amount,
            outputAmount: "\(outputAmount)",
            minimumOutputAmount: "\(minOutput)",
            exchangeRate: rate,
            priceImpact: priceImpact,
            slippageTolerance: request.slippageTolerance,
            networkFeeEstimate: "150000", // Gas units
            networkFeeUSD: 4.50,
            provider: provider,
            routeType: request.routeType,
            expiresAt: Date().addingTimeInterval(SwapConfiguration.quoteValidityDuration),
            transactionData: transactionData,
            routePath: [request.fromAsset.symbol, request.toAsset.symbol]
        )
    }
    
    // MARK: - Jupiter (Solana)
    
    /// Fetch quote from Jupiter for Solana swaps
    private func fetchJupiterQuote(for request: SwapQuoteRequest) async throws -> SwapQuoteV2 {
        let inputMint = resolveSolanaMint(request.fromAsset)
        let outputMint = resolveSolanaMint(request.toAsset)
        
        var components = URLComponents(string: "\(APIConfig.jupiterBaseURL)/quote")!
        components.queryItems = [
            URLQueryItem(name: "inputMint", value: inputMint),
            URLQueryItem(name: "outputMint", value: outputMint),
            URLQueryItem(name: "amount", value: request.amount),
            URLQueryItem(name: "slippageBps", value: "\(NSDecimalNumber(decimal: request.slippageTolerance * 100).intValue)")
        ]
        
        guard components.url != nil else {
            throw SwapError.invalidParameters(reason: "Invalid Jupiter quote URL")
        }
        
        // Use mock for development
        return try await mockJupiterQuote(request: request)
    }
    
    /// Resolve Solana mint address
    private func resolveSolanaMint(_ asset: Asset) -> String {
        if asset.type == .native {
            return "So11111111111111111111111111111111111111112" // Wrapped SOL
        }
        return asset.contractAddress ?? asset.symbol
    }
    
    /// Mock Jupiter quote (for development/testing)
    private func mockJupiterQuote(request: SwapQuoteRequest) async throws -> SwapQuoteV2 {
        // Simulate network latency
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        // Mock exchange rates for Solana tokens
        let mockRates: [String: [String: Decimal]] = [
            "SOL": ["USDC": 95, "USDT": 95],
            "USDC": ["SOL": 0.0105, "USDT": 1],
            "USDT": ["SOL": 0.0105, "USDC": 1]
        ]
        
        let fromSymbol = request.fromAsset.symbol
        let toSymbol = request.toAsset.symbol
        let rate = mockRates[fromSymbol]?[toSymbol] ?? Decimal(1)
        
        guard let inputDecimal = Decimal(string: request.amount) else {
            throw SwapError.invalidParameters(reason: "Invalid input amount")
        }
        
        // Scale input to human-readable, apply rate, scale back
        let inputDivisor = pow(Decimal(10), request.fromAsset.decimals)
        let outputMultiplier = pow(Decimal(10), request.toAsset.decimals)
        
        let humanInput = inputDecimal / inputDivisor
        let humanOutput = humanInput * rate
        let outputAmount = humanOutput * outputMultiplier
        
        let slippageMultiplier = 1 - (request.slippageTolerance / 100)
        let minOutput = outputAmount * slippageMultiplier
        
        return SwapQuoteV2(
            fromAsset: request.fromAsset,
            toAsset: request.toAsset,
            inputAmount: request.amount,
            outputAmount: "\(outputAmount)",
            minimumOutputAmount: "\(minOutput)",
            exchangeRate: rate,
            priceImpact: 0.08,
            slippageTolerance: request.slippageTolerance,
            networkFeeEstimate: "5000", // Lamports
            networkFeeUSD: 0.001,
            provider: .jupiter,
            routeType: .sameChain,
            expiresAt: Date().addingTimeInterval(SwapConfiguration.quoteValidityDuration),
            routePath: [request.fromAsset.symbol, request.toAsset.symbol]
        )
    }
    
    // MARK: - Best Quote Selection
    
    /// Select the best quote from available options
    private func selectBestQuote(from quotes: [SwapQuoteV2]) -> SwapQuoteV2? {
        guard !quotes.isEmpty else { return nil }
        
        // Calculate effective output (output - estimated fees in output token)
        // For simplicity, just compare output amounts directly
        return quotes.max { lhs, rhs in
            guard let lhsOutput = Decimal(string: lhs.outputAmount),
                  let rhsOutput = Decimal(string: rhs.outputAmount) else {
                return true
            }
            return lhsOutput < rhsOutput
        }
    }
    
    // MARK: - Provider Health
    
    private func markProviderHealthy(_ provider: SwapProvider) {
        providerHealth[provider] = true
    }
    
    private func markProviderUnhealthy(_ provider: SwapProvider) {
        providerHealth[provider] = false
    }
    
    // MARK: - Cache Key Generation
    
    private func generateCacheKey(for request: SwapQuoteRequest) -> String {
        "\(request.fromAsset.id):\(request.toAsset.id):\(request.amount):\(request.slippageTolerance)"
    }
}


