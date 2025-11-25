// MODULE: SwapTypes
// VERSION: 1.0.0
// PURPOSE: Comprehensive models for swap quotes, routes, and configuration

import Foundation

// MARK: - Swap Route Type

/// Determines the routing mechanism for a swap
public enum SwapRouteType: String, Codable, Sendable {
    case sameChain          // DEX swap (1inch, Jupiter, etc.)
    case crossChain         // Bridge swap (THORChain, etc.)
    case wrap               // Wrap native to wrapped (ETH → WETH)
    case unwrap             // Unwrap to native (WETH → ETH)
}

// MARK: - Swap Provider

/// Available swap providers
public enum SwapProvider: String, Codable, Sendable, CaseIterable {
    case oneInch = "1inch"
    case jupiter = "Jupiter"
    case thorchain = "THORChain"
    case uniswap = "Uniswap"
    case paraswap = "ParaSwap"
    
    public var displayName: String {
        rawValue
    }
    
    public var supportsChains: [AssetChain] {
        switch self {
        case .oneInch, .uniswap, .paraswap:
            return [.ethereum]
        case .jupiter:
            return [.solana]
        case .thorchain:
            return [.ethereum, .bitcoin, .solana]
        }
    }
    
    public var supportsCrossChain: Bool {
        self == .thorchain
    }
}

// MARK: - Enhanced Swap Quote

/// Comprehensive swap quote with all routing details
public struct SwapQuoteV2: Identifiable, Sendable, Equatable {
    public let id: UUID
    
    /// Source asset
    public let fromAsset: Asset
    
    /// Destination asset
    public let toAsset: Asset
    
    /// Input amount (in smallest unit)
    public let inputAmount: String
    
    /// Expected output amount (in smallest unit)
    public let outputAmount: String
    
    /// Minimum output with slippage applied
    public let minimumOutputAmount: String
    
    /// Exchange rate (1 fromAsset = X toAsset)
    public let exchangeRate: Decimal
    
    /// Price impact percentage
    public let priceImpact: Decimal?
    
    /// Slippage tolerance (e.g., 0.5 for 0.5%)
    public let slippageTolerance: Decimal
    
    /// Network fee estimate (in native currency, smallest unit)
    public let networkFeeEstimate: String
    
    /// Network fee in USD
    public let networkFeeUSD: Decimal?
    
    /// Provider that sourced this quote
    public let provider: SwapProvider
    
    /// Route type
    public let routeType: SwapRouteType
    
    /// Timestamp when quote was fetched
    public let fetchedAt: Date
    
    /// Quote expiration time
    public let expiresAt: Date
    
    /// Raw transaction data for execution
    public let transactionData: SwapTransactionData?
    
    /// Route path (for display)
    public let routePath: [String]
    
    public init(
        id: UUID = UUID(),
        fromAsset: Asset,
        toAsset: Asset,
        inputAmount: String,
        outputAmount: String,
        minimumOutputAmount: String,
        exchangeRate: Decimal,
        priceImpact: Decimal?,
        slippageTolerance: Decimal,
        networkFeeEstimate: String,
        networkFeeUSD: Decimal? = nil,
        provider: SwapProvider,
        routeType: SwapRouteType,
        fetchedAt: Date = Date(),
        expiresAt: Date,
        transactionData: SwapTransactionData? = nil,
        routePath: [String] = []
    ) {
        self.id = id
        self.fromAsset = fromAsset
        self.toAsset = toAsset
        self.inputAmount = inputAmount
        self.outputAmount = outputAmount
        self.minimumOutputAmount = minimumOutputAmount
        self.exchangeRate = exchangeRate
        self.priceImpact = priceImpact
        self.slippageTolerance = slippageTolerance
        self.networkFeeEstimate = networkFeeEstimate
        self.networkFeeUSD = networkFeeUSD
        self.provider = provider
        self.routeType = routeType
        self.fetchedAt = fetchedAt
        self.expiresAt = expiresAt
        self.transactionData = transactionData
        self.routePath = routePath
    }
    
    /// Check if quote is still valid
    public var isExpired: Bool {
        Date() >= expiresAt
    }
    
    /// Time remaining until expiration
    public var timeRemaining: TimeInterval {
        expiresAt.timeIntervalSinceNow
    }
    
    /// Formatted exchange rate for display
    public var formattedRate: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 8
        formatter.minimumFractionDigits = 2
        return "1 \(fromAsset.symbol) = \(formatter.string(from: exchangeRate as NSNumber) ?? "0") \(toAsset.symbol)"
    }
    
    /// Formatted output amount
    public var formattedOutputAmount: String {
        guard let rawValue = Decimal(string: outputAmount) else { return "0" }
        let divisor = pow(Decimal(10), toAsset.decimals)
        let balance = rawValue / divisor
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = min(toAsset.decimals, 8)
        
        return formatter.string(from: balance as NSNumber) ?? "0"
    }
    
    /// Formatted minimum output
    public var formattedMinimumOutput: String {
        guard let rawValue = Decimal(string: minimumOutputAmount) else { return "0" }
        let divisor = pow(Decimal(10), toAsset.decimals)
        let balance = rawValue / divisor
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = min(toAsset.decimals, 8)
        
        return formatter.string(from: balance as NSNumber) ?? "0"
    }
}

// MARK: - Swap Transaction Data

/// Raw transaction data for swap execution
public struct SwapTransactionData: Sendable, Equatable {
    /// Target contract address
    public let to: String
    
    /// Value to send (for native currency)
    public let value: String
    
    /// Calldata for the swap
    public let calldata: Data
    
    /// Gas limit recommendation
    public let gasLimit: UInt64?
    
    /// THORChain-specific memo (if applicable)
    public let thorchainMemo: String?
    
    /// Vault address for THORChain swaps
    public let vaultAddress: String?
    
    public init(
        to: String,
        value: String,
        calldata: Data,
        gasLimit: UInt64? = nil,
        thorchainMemo: String? = nil,
        vaultAddress: String? = nil
    ) {
        self.to = to
        self.value = value
        self.calldata = calldata
        self.gasLimit = gasLimit
        self.thorchainMemo = thorchainMemo
        self.vaultAddress = vaultAddress
    }
}

// MARK: - Quote Request

/// Parameters for requesting a swap quote
public struct SwapQuoteRequest: Sendable {
    public let fromAsset: Asset
    public let toAsset: Asset
    public let amount: String
    public let slippageTolerance: Decimal
    public let senderAddress: String
    public let recipientAddress: String?
    
    public init(
        fromAsset: Asset,
        toAsset: Asset,
        amount: String,
        slippageTolerance: Decimal = 0.5,
        senderAddress: String,
        recipientAddress: String? = nil
    ) {
        self.fromAsset = fromAsset
        self.toAsset = toAsset
        self.amount = amount
        self.slippageTolerance = slippageTolerance
        self.senderAddress = senderAddress
        self.recipientAddress = recipientAddress
    }
    
    /// Determine the route type based on assets
    public var routeType: SwapRouteType {
        if fromAsset.chain != toAsset.chain {
            return .crossChain
        }
        
        // Check for wrap/unwrap
        if fromAsset.type == .native && toAsset.type == .wrapped {
            return .wrap
        }
        if fromAsset.type == .wrapped && toAsset.type == .native {
            return .unwrap
        }
        
        return .sameChain
    }
}

// MARK: - Quote Comparison Result

/// Result of comparing quotes from multiple providers
public struct QuoteComparisonResult: Sendable {
    /// Best quote by output amount
    public let bestQuote: SwapQuoteV2
    
    /// All fetched quotes
    public let allQuotes: [SwapQuoteV2]
    
    /// Providers that failed to respond
    public let failedProviders: [SwapProvider: String]
    
    /// Savings compared to worst quote
    public var savingsVsWorst: Decimal? {
        guard allQuotes.count > 1,
              let best = Decimal(string: bestQuote.outputAmount),
              let worst = allQuotes.map({ Decimal(string: $0.outputAmount) ?? 0 }).min() else {
            return nil
        }
        guard worst > 0 else { return nil }
        return ((best - worst) / worst) * 100
    }
}

// MARK: - Swap Execution Result

/// Result of executing a swap
public struct SwapExecutionResult: Sendable {
    public let success: Bool
    public let transactionHash: String?
    public let inputAmount: String
    public let outputAmount: String?
    public let error: SwapError?
    public let simulationReceipt: SimulationReceipt?
    
    public init(
        success: Bool,
        transactionHash: String? = nil,
        inputAmount: String,
        outputAmount: String? = nil,
        error: SwapError? = nil,
        simulationReceipt: SimulationReceipt? = nil
    ) {
        self.success = success
        self.transactionHash = transactionHash
        self.inputAmount = inputAmount
        self.outputAmount = outputAmount
        self.error = error
        self.simulationReceipt = simulationReceipt
    }
}

// MARK: - Swap Errors

/// Errors that can occur during swap operations
public enum SwapError: Error, LocalizedError, Sendable {
    case quoteExpired
    case simulationRequired
    case simulationFailed(reason: String)
    case insufficientBalance
    case insufficientAllowance
    case slippageExceeded(expected: String, actual: String)
    case providerError(provider: SwapProvider, message: String)
    case networkError(underlying: String)
    case invalidParameters(reason: String)
    case unsupportedRoute(from: AssetChain, to: AssetChain)
    case transactionFailed(reason: String)
    case userCancelled
    
    public var errorDescription: String? {
        switch self {
        case .quoteExpired:
            return "Quote has expired. Please refresh."
        case .simulationRequired:
            return "Transaction must be simulated before execution."
        case .simulationFailed(let reason):
            return "Simulation failed: \(reason)"
        case .insufficientBalance:
            return "Insufficient balance for this swap."
        case .insufficientAllowance:
            return "Token allowance not set. Please approve first."
        case .slippageExceeded(let expected, let actual):
            return "Slippage exceeded: expected \(expected), got \(actual)"
        case .providerError(let provider, let message):
            return "\(provider.displayName) error: \(message)"
        case .networkError(let underlying):
            return "Network error: \(underlying)"
        case .invalidParameters(let reason):
            return "Invalid parameters: \(reason)"
        case .unsupportedRoute(let from, let to):
            return "Swaps from \(from.displayName) to \(to.displayName) are not supported."
        case .transactionFailed(let reason):
            return "Transaction failed: \(reason)"
        case .userCancelled:
            return "Swap cancelled by user."
        }
    }
}

// MARK: - Swap Configuration

/// Global swap configuration
public struct SwapConfiguration: Sendable {
    /// Default slippage tolerance (0.5%)
    public static let defaultSlippage: Decimal = 0.5
    
    /// Maximum slippage tolerance (50%)
    public static let maxSlippage: Decimal = 50.0
    
    /// Quote validity duration in seconds
    public static let quoteValidityDuration: TimeInterval = 60.0
    
    /// Auto-refresh interval in seconds
    public static let autoRefreshInterval: TimeInterval = 15.0
    
    /// Minimum trade amount in USD
    public static let minimumTradeUSD: Decimal = 0.01
    
    /// High price impact threshold (%)
    public static let highPriceImpactThreshold: Decimal = 5.0
    
    /// Very high price impact threshold (%)
    public static let veryHighPriceImpactThreshold: Decimal = 15.0
}

// MARK: - Price Impact Level

/// Categorization of price impact severity
public enum PriceImpactLevel: Sendable {
    case low        // < 1%
    case medium     // 1% - 5%
    case high       // 5% - 15%
    case veryHigh   // > 15%
    
    public init(impact: Decimal?) {
        guard let impact = impact else {
            self = .low
            return
        }
        
        let absImpact = abs(impact)
        switch absImpact {
        case 0..<1:
            self = .low
        case 1..<5:
            self = .medium
        case 5..<15:
            self = .high
        default:
            self = .veryHigh
        }
    }
    
    public var warningMessage: String? {
        switch self {
        case .low, .medium:
            return nil
        case .high:
            return "High price impact. Consider splitting into smaller trades."
        case .veryHigh:
            return "Very high price impact! This trade may result in significant losses."
        }
    }
}

// MARK: - THORChain Types

/// THORChain-specific pool information
public struct THORChainPool: Codable, Sendable {
    public let asset: String
    public let assetDepth: String
    public let runeDepth: String
    public let status: String
    public let synth_supply: String?
    
    /// Calculate swap output using x*y=k formula
    public func calculateSwapOutput(
        inputAmount: Decimal,
        isAssetToRune: Bool
    ) -> Decimal {
        guard let assetDepth = Decimal(string: assetDepth),
              let runeDepth = Decimal(string: runeDepth) else {
            return 0
        }
        
        let x = isAssetToRune ? assetDepth : runeDepth
        let y = isAssetToRune ? runeDepth : assetDepth
        
        // Output = (inputAmount * y * x) / (inputAmount + x)^2
        let denominator = (inputAmount + x) * (inputAmount + x)
        guard denominator > 0 else { return 0 }
        
        return (inputAmount * y * x) / denominator
    }
}

/// THORChain inbound address info
public struct THORChainInboundAddress: Codable, Sendable {
    public let chain: String
    public let address: String
    public let router: String?
    public let halted: Bool
    public let gas_rate: String
}


