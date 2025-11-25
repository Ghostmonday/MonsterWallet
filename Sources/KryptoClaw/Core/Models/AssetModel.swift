// MODULE: AssetModel
// VERSION: 1.0.0
// PURPOSE: Comprehensive asset and portfolio data structures

import Foundation

// MARK: - Asset Definition

/// Represents a crypto asset (native coin or token)
public struct Asset: Identifiable, Codable, Hashable, Sendable {
    /// Unique identifier (chain:contractAddress or chain:native for native coins)
    public let id: String
    
    /// Ticker symbol (ETH, BTC, USDC, etc.)
    public let symbol: String
    
    /// Full name (Ethereum, Bitcoin, USD Coin)
    public let name: String
    
    /// Decimal places for the asset
    public let decimals: Int
    
    /// The blockchain this asset belongs to
    public let chain: AssetChain
    
    /// Contract address (nil for native coins)
    public let contractAddress: String?
    
    /// CoinGecko ID for price feeds
    public let coingeckoId: String?
    
    /// Icon URL
    public let iconURL: URL?
    
    /// Asset type
    public let type: AssetType
    
    /// Whether this is a verified/trusted asset
    public let isVerified: Bool
    
    public init(
        id: String,
        symbol: String,
        name: String,
        decimals: Int,
        chain: AssetChain,
        contractAddress: String? = nil,
        coingeckoId: String? = nil,
        iconURL: URL? = nil,
        type: AssetType = .token,
        isVerified: Bool = false
    ) {
        self.id = id
        self.symbol = symbol
        self.name = name
        self.decimals = decimals
        self.chain = chain
        self.contractAddress = contractAddress
        self.coingeckoId = coingeckoId
        self.iconURL = iconURL
        self.type = type
        self.isVerified = isVerified
    }
    
    /// Create a native coin asset
    public static func native(chain: AssetChain) -> Asset {
        switch chain {
        case .ethereum:
            return Asset(
                id: "ethereum:native",
                symbol: "ETH",
                name: "Ethereum",
                decimals: 18,
                chain: .ethereum,
                coingeckoId: "ethereum",
                iconURL: URL(string: "https://raw.githubusercontent.com/trustwallet/assets/master/blockchains/ethereum/info/logo.png"),
                type: .native,
                isVerified: true
            )
        case .bitcoin:
            return Asset(
                id: "bitcoin:native",
                symbol: "BTC",
                name: "Bitcoin",
                decimals: 8,
                chain: .bitcoin,
                coingeckoId: "bitcoin",
                iconURL: URL(string: "https://raw.githubusercontent.com/trustwallet/assets/master/blockchains/bitcoin/info/logo.png"),
                type: .native,
                isVerified: true
            )
        case .solana:
            return Asset(
                id: "solana:native",
                symbol: "SOL",
                name: "Solana",
                decimals: 9,
                chain: .solana,
                coingeckoId: "solana",
                iconURL: URL(string: "https://raw.githubusercontent.com/trustwallet/assets/master/blockchains/solana/info/logo.png"),
                type: .native,
                isVerified: true
            )
        }
    }
}

// MARK: - Asset Chain

/// Supported blockchain networks
public enum AssetChain: String, Codable, CaseIterable, Hashable, Sendable {
    case ethereum = "ethereum"
    case bitcoin = "bitcoin"
    case solana = "solana"
    
    public var displayName: String {
        switch self {
        case .ethereum: return "Ethereum"
        case .bitcoin: return "Bitcoin"
        case .solana: return "Solana"
        }
    }
    
    public var nativeSymbol: String {
        switch self {
        case .ethereum: return "ETH"
        case .bitcoin: return "BTC"
        case .solana: return "SOL"
        }
    }
    
    public var chainId: Int? {
        switch self {
        case .ethereum: return 1
        case .bitcoin: return nil
        case .solana: return nil
        }
    }
    
    /// Convert to legacy Chain enum
    public var legacyChain: Chain {
        switch self {
        case .ethereum: return .ethereum
        case .bitcoin: return .bitcoin
        case .solana: return .solana
        }
    }
    
    /// Convert from legacy Chain enum
    public static func from(legacy: Chain) -> AssetChain {
        switch legacy {
        case .ethereum: return .ethereum
        case .bitcoin: return .bitcoin
        case .solana: return .solana
        }
    }
}

// MARK: - Asset Type

/// Type of crypto asset
public enum AssetType: String, Codable, Hashable, Sendable {
    case native      // Native chain currency (ETH, BTC, SOL)
    case token       // ERC-20, SPL Token, etc.
    case nft         // Non-fungible token
    case wrapped     // Wrapped version (WETH, WBTC)
    case stablecoin  // USD-pegged (USDC, USDT)
}

// MARK: - Asset Balance

/// Represents an asset balance with price information
public struct AssetBalance: Identifiable, Codable, Sendable {
    public var id: String { asset.id }
    
    /// The asset
    public let asset: Asset
    
    /// Raw balance (in smallest unit, e.g., wei, satoshi)
    public let rawBalance: String
    
    /// Formatted balance with proper decimals
    public var formattedBalance: String {
        guard let rawValue = Decimal(string: rawBalance) else { return "0" }
        let divisor = pow(Decimal(10), asset.decimals)
        let balance = rawValue / divisor
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = min(asset.decimals, 8)
        formatter.roundingMode = .halfUp
        
        return formatter.string(from: balance as NSNumber) ?? "0"
    }
    
    /// Balance as Decimal
    public var decimalBalance: Decimal {
        guard let rawValue = Decimal(string: rawBalance) else { return 0 }
        let divisor = pow(Decimal(10), asset.decimals)
        return rawValue / divisor
    }
    
    /// Price per unit in USD
    public let priceUSD: Decimal?
    
    /// Total value in USD
    public var valueUSD: Decimal? {
        guard let price = priceUSD else { return nil }
        return decimalBalance * price
    }
    
    /// Formatted USD value
    public var formattedValueUSD: String {
        guard let value = valueUSD else { return "-" }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        
        return formatter.string(from: value as NSNumber) ?? "-"
    }
    
    /// 24h price change percentage
    public let priceChange24h: Decimal?
    
    /// Last updated timestamp
    public let lastUpdated: Date
    
    public init(
        asset: Asset,
        rawBalance: String,
        priceUSD: Decimal? = nil,
        priceChange24h: Decimal? = nil,
        lastUpdated: Date = Date()
    ) {
        self.asset = asset
        self.rawBalance = rawBalance
        self.priceUSD = priceUSD
        self.priceChange24h = priceChange24h
        self.lastUpdated = lastUpdated
    }
    
    /// Check if balance is non-zero
    public var hasBalance: Bool {
        decimalBalance > 0
    }
}

// MARK: - Portfolio

/// Complete wallet portfolio across all chains
public struct Portfolio: Codable, Sendable {
    /// All asset balances
    public let balances: [AssetBalance]
    
    /// Total portfolio value in USD
    public var totalValueUSD: Decimal {
        balances.compactMap(\.valueUSD).reduce(0, +)
    }
    
    /// Formatted total value
    public var formattedTotalValue: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: totalValueUSD as NSNumber) ?? "$0.00"
    }
    
    /// Last update timestamp
    public let lastUpdated: Date
    
    /// Balances grouped by chain
    public var byChain: [AssetChain: [AssetBalance]] {
        Dictionary(grouping: balances) { $0.asset.chain }
    }
    
    /// Only non-zero balances
    public var nonZeroBalances: [AssetBalance] {
        balances.filter { $0.hasBalance }
    }
    
    /// Native coin balances only
    public var nativeBalances: [AssetBalance] {
        balances.filter { $0.asset.type == .native }
    }
    
    public init(balances: [AssetBalance], lastUpdated: Date = Date()) {
        self.balances = balances
        self.lastUpdated = lastUpdated
    }
    
    public static let empty = Portfolio(balances: [])
}

// MARK: - Price Data

/// Price information for an asset
public struct AssetPrice: Codable, Sendable {
    public let assetId: String
    public let priceUSD: Decimal
    public let priceChange24h: Decimal?
    public let marketCap: Decimal?
    public let volume24h: Decimal?
    public let lastUpdated: Date
    
    public init(
        assetId: String,
        priceUSD: Decimal,
        priceChange24h: Decimal? = nil,
        marketCap: Decimal? = nil,
        volume24h: Decimal? = nil,
        lastUpdated: Date = Date()
    ) {
        self.assetId = assetId
        self.priceUSD = priceUSD
        self.priceChange24h = priceChange24h
        self.marketCap = marketCap
        self.volume24h = volume24h
        self.lastUpdated = lastUpdated
    }
}

// MARK: - Derived Address

/// Represents a derived wallet address for a specific chain
public struct DerivedAddress: Identifiable, Codable, Hashable, Sendable {
    public var id: String { "\(chain.rawValue):\(address)" }
    
    /// The blockchain
    public let chain: AssetChain
    
    /// The derived address
    public let address: String
    
    /// Derivation path used
    public let derivationPath: String
    
    /// Account index
    public let accountIndex: UInt32
    
    public init(chain: AssetChain, address: String, derivationPath: String, accountIndex: UInt32 = 0) {
        self.chain = chain
        self.address = address
        self.derivationPath = derivationPath
        self.accountIndex = accountIndex
    }
    
    /// Shortened address for display
    public var shortAddress: String {
        guard address.count > 10 else { return address }
        return "\(address.prefix(6))...\(address.suffix(4))"
    }
}

// MARK: - Wallet Account

/// Represents a complete wallet account with addresses for all chains
public struct WalletAccount: Identifiable, Codable, Sendable {
    public let id: UUID
    
    /// Display name
    public let name: String
    
    /// Color theme identifier
    public let colorTheme: String
    
    /// Derived addresses for each chain
    public let addresses: [DerivedAddress]
    
    /// Creation timestamp
    public let createdAt: Date
    
    /// Is this the primary account
    public let isPrimary: Bool
    
    public init(
        id: UUID = UUID(),
        name: String,
        colorTheme: String = "blue",
        addresses: [DerivedAddress],
        createdAt: Date = Date(),
        isPrimary: Bool = false
    ) {
        self.id = id
        self.name = name
        self.colorTheme = colorTheme
        self.addresses = addresses
        self.createdAt = createdAt
        self.isPrimary = isPrimary
    }
    
    /// Get address for a specific chain
    public func address(for chain: AssetChain) -> DerivedAddress? {
        addresses.first { $0.chain == chain }
    }
}

// MARK: - Token List

/// Cached list of popular tokens
public struct TokenList: Codable, Sendable {
    public let tokens: [Asset]
    public let lastUpdated: Date
    public let source: String
    
    public init(tokens: [Asset], lastUpdated: Date = Date(), source: String = "coingecko") {
        self.tokens = tokens
        self.lastUpdated = lastUpdated
        self.source = source
    }
    
    /// Check if cache is stale (older than 1 hour)
    public var isStale: Bool {
        Date().timeIntervalSince(lastUpdated) > 3600
    }
}

// MARK: - Extensions

extension Asset {
    /// Common stablecoins on Ethereum
    public static let usdc = Asset(
        id: "ethereum:0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48",
        symbol: "USDC",
        name: "USD Coin",
        decimals: 6,
        chain: .ethereum,
        contractAddress: "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48",
        coingeckoId: "usd-coin",
        iconURL: URL(string: "https://raw.githubusercontent.com/trustwallet/assets/master/blockchains/ethereum/assets/0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48/logo.png"),
        type: .stablecoin,
        isVerified: true
    )
    
    public static let usdt = Asset(
        id: "ethereum:0xdac17f958d2ee523a2206206994597c13d831ec7",
        symbol: "USDT",
        name: "Tether USD",
        decimals: 6,
        chain: .ethereum,
        contractAddress: "0xdac17f958d2ee523a2206206994597c13d831ec7",
        coingeckoId: "tether",
        iconURL: URL(string: "https://raw.githubusercontent.com/trustwallet/assets/master/blockchains/ethereum/assets/0xdAC17F958D2ee523a2206206994597C13D831ec7/logo.png"),
        type: .stablecoin,
        isVerified: true
    )
    
    public static let weth = Asset(
        id: "ethereum:0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2",
        symbol: "WETH",
        name: "Wrapped Ether",
        decimals: 18,
        chain: .ethereum,
        contractAddress: "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2",
        coingeckoId: "weth",
        iconURL: URL(string: "https://raw.githubusercontent.com/trustwallet/assets/master/blockchains/ethereum/assets/0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2/logo.png"),
        type: .wrapped,
        isVerified: true
    )
}

// MARK: - Formatting Helpers

extension Decimal {
    /// Format as currency
    public func formatAsCurrency(symbol: String = "$", minimumFractionDigits: Int = 2, maximumFractionDigits: Int = 2) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = symbol
        formatter.minimumFractionDigits = minimumFractionDigits
        formatter.maximumFractionDigits = maximumFractionDigits
        return formatter.string(from: self as NSNumber) ?? "\(symbol)0.00"
    }
    
    /// Format with compact notation for large numbers
    public func formatCompact() -> String {
        let absValue = abs(self)
        let sign = self < 0 ? "-" : ""
        
        switch absValue {
        case 1_000_000_000_000...:
            let value = absValue / 1_000_000_000_000
            return "\(sign)\(value.formatAsCurrency())T"
        case 1_000_000_000...:
            let value = absValue / 1_000_000_000
            return "\(sign)\(value.formatAsCurrency())B"
        case 1_000_000...:
            let value = absValue / 1_000_000
            return "\(sign)\(value.formatAsCurrency())M"
        case 1_000...:
            let value = absValue / 1_000
            return "\(sign)\(value.formatAsCurrency())K"
        default:
            return formatAsCurrency()
        }
    }
}

