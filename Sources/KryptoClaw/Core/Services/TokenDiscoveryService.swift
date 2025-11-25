// MODULE: TokenDiscoveryService
// VERSION: 1.0.0
// PURPOSE: Token discovery and price feeds with CoinGecko API and disk caching

import Foundation

// MARK: - Token Discovery Error

public enum TokenDiscoveryError: Error, LocalizedError, Sendable {
    case networkError(underlying: Error)
    case rateLimited
    case invalidResponse
    case cacheMiss
    case searchFailed(query: String)
    
    public var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .rateLimited:
            return "API rate limit exceeded. Please try again later."
        case .invalidResponse:
            return "Received invalid data from price server."
        case .cacheMiss:
            return "Data not available offline."
        case .searchFailed(let query):
            return "Search failed for '\(query)'."
        }
    }
}

// MARK: - CoinGecko Response Models

/// CoinGecko simple price response
private struct CoinGeckoPriceResponse: Decodable {
    // Dynamic keys based on coin IDs
}

/// CoinGecko coin market data
public struct CoinGeckoMarketData: Codable, Sendable {
    public let id: String
    public let symbol: String
    public let name: String
    public let image: String?
    public let currentPrice: Decimal?
    public let marketCap: Decimal?
    public let marketCapRank: Int?
    public let priceChangePercentage24h: Decimal?
    public let totalVolume: Decimal?
    
    private enum CodingKeys: String, CodingKey {
        case id, symbol, name, image
        case currentPrice = "current_price"
        case marketCap = "market_cap"
        case marketCapRank = "market_cap_rank"
        case priceChangePercentage24h = "price_change_percentage_24h"
        case totalVolume = "total_volume"
    }
}

/// CoinGecko search result
public struct CoinGeckoSearchResult: Codable, Sendable {
    public let coins: [CoinGeckoSearchCoin]
}

public struct CoinGeckoSearchCoin: Codable, Sendable {
    public let id: String
    public let name: String
    public let symbol: String
    public let marketCapRank: Int?
    public let thumb: String?
    public let large: String?
    
    private enum CodingKeys: String, CodingKey {
        case id, name, symbol, thumb, large
        case marketCapRank = "market_cap_rank"
    }
}

// MARK: - Price Cache

/// Cached price data with expiration
struct PriceCache: Codable {
    let prices: [String: AssetPrice]
    let cachedAt: Date
    
    var isExpired: Bool {
        Date().timeIntervalSince(cachedAt) > 60 // 1 minute cache
    }
}

/// Cached token list
struct TokenListCache: Codable {
    let tokens: [CoinGeckoMarketData]
    let cachedAt: Date
    
    var isExpired: Bool {
        Date().timeIntervalSince(cachedAt) > 3600 // 1 hour cache
    }
}

// MARK: - Token Discovery Service

/// Actor service for token discovery and price feeds.
///
/// **Features:**
/// - Fetches top 100 tokens from CoinGecko
/// - Real-time price updates with caching
/// - Search functionality
/// - Offline support via disk persistence
/// - Rate limit handling
@available(iOS 15.0, macOS 12.0, *)
public actor TokenDiscoveryService {
    
    // MARK: - Constants
    
    private let baseURL = "https://api.coingecko.com/api/v3"
    private let proCacheFile = "token_list_cache.json"
    private let priceCacheFile = "price_cache.json"
    
    // MARK: - Dependencies
    
    private let session: URLSession
    private let persistence: PersistenceServiceProtocol
    private let apiKey: String?
    
    // MARK: - Cache
    
    private var priceCache: [String: AssetPrice] = [:]
    private var tokenListCache: [CoinGeckoMarketData] = []
    private var lastPriceFetch: Date?
    private var lastTokenListFetch: Date?
    
    // MARK: - Rate Limiting
    
    private var lastRequestTime: Date?
    private let minRequestInterval: TimeInterval = 1.0 // 1 second between requests
    
    // MARK: - Initialization
    
    public init(
        session: URLSession = .shared,
        persistence: PersistenceServiceProtocol = PersistenceService.shared,
        apiKey: String? = nil
    ) {
        self.session = session
        self.persistence = persistence
        self.apiKey = apiKey
        
        // Load cached data
        Task {
            await loadCachedData()
        }
    }
    
    // MARK: - Public API
    
    /// Fetch prices for a list of coin IDs
    /// - Parameter coinIds: Array of CoinGecko coin IDs (e.g., ["ethereum", "bitcoin"])
    /// - Returns: Dictionary of coin ID to AssetPrice
    public func fetchPrices(for coinIds: [String]) async throws -> [String: AssetPrice] {
        // Check cache first
        let cachedPrices = getCachedPrices(for: coinIds)
        let missingIds = coinIds.filter { cachedPrices[$0] == nil }
        
        guard !missingIds.isEmpty else {
            return cachedPrices
        }
        
        // Respect rate limiting
        try await throttleIfNeeded()
        
        // Build URL
        let idsParam = missingIds.joined(separator: ",")
        var urlString = "\(baseURL)/simple/price?ids=\(idsParam)&vs_currencies=usd&include_24hr_change=true&include_market_cap=true&include_24hr_vol=true"
        
        if let apiKey = apiKey {
            urlString += "&x_cg_pro_api_key=\(apiKey)"
        }
        
        guard let url = URL(string: urlString) else {
            throw TokenDiscoveryError.invalidResponse
        }
        
        // Fetch
        let (data, response) = try await session.data(from: url)
        
        // Check for rate limiting
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 429 {
            throw TokenDiscoveryError.rateLimited
        }
        
        // Parse response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: [String: Any]] else {
            throw TokenDiscoveryError.invalidResponse
        }
        
        // Convert to AssetPrice
        var prices = cachedPrices
        for (coinId, priceData) in json {
            if let usd = priceData["usd"] as? Double {
                let price = AssetPrice(
                    assetId: coinId,
                    priceUSD: Decimal(usd),
                    priceChange24h: (priceData["usd_24h_change"] as? Double).map { Decimal($0) },
                    marketCap: (priceData["usd_market_cap"] as? Double).map { Decimal($0) },
                    volume24h: (priceData["usd_24h_vol"] as? Double).map { Decimal($0) }
                )
                prices[coinId] = price
                priceCache[coinId] = price
            }
        }
        
        // Update cache timestamp
        lastPriceFetch = Date()
        
        // Persist to disk
        try? savePriceCache()
        
        return prices
    }
    
    /// Fetch top tokens by market cap
    /// - Parameter limit: Number of tokens to fetch (max 250)
    /// - Returns: Array of market data
    public func fetchTopTokens(limit: Int = 100) async throws -> [CoinGeckoMarketData] {
        // Check cache
        if !tokenListCache.isEmpty, let lastFetch = lastTokenListFetch,
           Date().timeIntervalSince(lastFetch) < 3600 {
            return Array(tokenListCache.prefix(limit))
        }
        
        try await throttleIfNeeded()
        
        var urlString = "\(baseURL)/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=\(min(limit, 250))&page=1&sparkline=false"
        
        if let apiKey = apiKey {
            urlString += "&x_cg_pro_api_key=\(apiKey)"
        }
        
        guard let url = URL(string: urlString) else {
            throw TokenDiscoveryError.invalidResponse
        }
        
        let (data, response) = try await session.data(from: url)
        
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 429 {
            throw TokenDiscoveryError.rateLimited
        }
        
        let decoder = JSONDecoder()
        let tokens = try decoder.decode([CoinGeckoMarketData].self, from: data)
        
        // Cache
        tokenListCache = tokens
        lastTokenListFetch = Date()
        
        // Persist
        try? saveTokenListCache()
        
        // Update price cache from market data
        for token in tokens {
            if let price = token.currentPrice {
                priceCache[token.id] = AssetPrice(
                    assetId: token.id,
                    priceUSD: price,
                    priceChange24h: token.priceChangePercentage24h,
                    marketCap: token.marketCap,
                    volume24h: token.totalVolume
                )
            }
        }
        
        return tokens
    }
    
    /// Search for tokens by name or symbol
    /// - Parameter query: Search query
    /// - Returns: Array of matching coins
    public func searchTokens(query: String) async throws -> [CoinGeckoSearchCoin] {
        guard !query.isEmpty else { return [] }
        
        try await throttleIfNeeded()
        
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        var urlString = "\(baseURL)/search?query=\(encodedQuery)"
        
        if let apiKey = apiKey {
            urlString += "&x_cg_pro_api_key=\(apiKey)"
        }
        
        guard let url = URL(string: urlString) else {
            throw TokenDiscoveryError.searchFailed(query: query)
        }
        
        let (data, response) = try await session.data(from: url)
        
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 429 {
            throw TokenDiscoveryError.rateLimited
        }
        
        let decoder = JSONDecoder()
        let result = try decoder.decode(CoinGeckoSearchResult.self, from: data)
        
        return result.coins
    }
    
    /// Convert market data to Asset model
    public func toAsset(from marketData: CoinGeckoMarketData, chain: AssetChain = .ethereum) -> Asset {
        Asset(
            id: "\(chain.rawValue):\(marketData.id)",
            symbol: marketData.symbol.uppercased(),
            name: marketData.name,
            decimals: 18, // Default for most ERC-20
            chain: chain,
            coingeckoId: marketData.id,
            iconURL: URL(string: marketData.image ?? ""),
            type: .token,
            isVerified: (marketData.marketCapRank ?? 1000) <= 100
        )
    }
    
    /// Get cached price for a coin
    public func getCachedPrice(for coinId: String) -> AssetPrice? {
        priceCache[coinId]
    }
    
    /// Get all cached tokens
    public func getCachedTokens() -> [CoinGeckoMarketData] {
        tokenListCache
    }
    
    // MARK: - Private Helpers
    
    /// Get cached prices for coin IDs
    private func getCachedPrices(for coinIds: [String]) -> [String: AssetPrice] {
        var result: [String: AssetPrice] = [:]
        
        // Only return cached prices if they're fresh (< 1 minute)
        guard let lastFetch = lastPriceFetch, Date().timeIntervalSince(lastFetch) < 60 else {
            return [:]
        }
        
        for id in coinIds {
            if let cached = priceCache[id] {
                result[id] = cached
            }
        }
        
        return result
    }
    
    /// Throttle requests to respect rate limits
    private func throttleIfNeeded() async throws {
        if let lastRequest = lastRequestTime {
            let elapsed = Date().timeIntervalSince(lastRequest)
            if elapsed < minRequestInterval {
                let delay = minRequestInterval - elapsed
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
        lastRequestTime = Date()
    }
    
    // MARK: - Persistence
    
    /// Load cached data from disk
    private func loadCachedData() {
        // Load price cache
        if let cached: PriceCache = try? persistence.load(PriceCache.self, from: priceCacheFile) {
            if !cached.isExpired {
                priceCache = cached.prices
                lastPriceFetch = cached.cachedAt
            }
        }
        
        // Load token list cache
        if let cached: TokenListCache = try? persistence.load(TokenListCache.self, from: proCacheFile) {
            if !cached.isExpired {
                tokenListCache = cached.tokens
                lastTokenListFetch = cached.cachedAt
            }
        }
    }
    
    /// Save price cache to disk
    private func savePriceCache() throws {
        let cache = PriceCache(prices: priceCache, cachedAt: Date())
        try persistence.save(cache, to: priceCacheFile)
    }
    
    /// Save token list cache to disk
    private func saveTokenListCache() throws {
        let cache = TokenListCache(tokens: tokenListCache, cachedAt: Date())
        try persistence.save(cache, to: proCacheFile)
    }
}

// MARK: - Offline Support Extension

@available(iOS 15.0, macOS 12.0, *)
extension TokenDiscoveryService {
    
    /// Check if offline data is available
    public var hasOfflineData: Bool {
        !tokenListCache.isEmpty || !priceCache.isEmpty
    }
    
    /// Get offline token list
    public func getOfflineTokenList() -> [CoinGeckoMarketData] {
        tokenListCache
    }
    
    /// Get offline prices
    public func getOfflinePrices() -> [String: AssetPrice] {
        priceCache
    }
    
    /// Force reload from disk
    public func reloadFromDisk() async {
        await loadCachedData()
    }
}

// MARK: - Popular Tokens

@available(iOS 15.0, macOS 12.0, *)
extension TokenDiscoveryService {
    
    /// Well-known coin IDs for quick lookup
    public static let popularCoinIds = [
        "bitcoin",
        "ethereum",
        "solana",
        "usd-coin",
        "tether",
        "binancecoin",
        "ripple",
        "cardano",
        "dogecoin",
        "polygon-pos"
    ]
    
    /// Fetch prices for popular coins
    public func fetchPopularPrices() async throws -> [String: AssetPrice] {
        try await fetchPrices(for: Self.popularCoinIds)
    }
}

