// MODULE: YieldModels
// VERSION: 1.0.0
// PURPOSE: Data models for yield opportunities, staking positions, and DeFi protocols

import Foundation

// MARK: - Yield Protocol

/// Supported yield-generating protocols
public enum YieldProtocol: String, Codable, CaseIterable, Sendable {
    case lido = "Lido"
    case aave = "Aave"
    case rocket = "Rocket Pool"
    case compound = "Compound"
    case eigenlayer = "EigenLayer"
    
    public var displayName: String {
        rawValue
    }
    
    public var chain: AssetChain {
        switch self {
        case .lido, .aave, .compound, .rocket, .eigenlayer:
            return .ethereum
        }
    }
    
    public var websiteURL: URL? {
        switch self {
        case .lido:
            return URL(string: "https://lido.fi")
        case .aave:
            return URL(string: "https://aave.com")
        case .rocket:
            return URL(string: "https://rocketpool.net")
        case .compound:
            return URL(string: "https://compound.finance")
        case .eigenlayer:
            return URL(string: "https://eigenlayer.xyz")
        }
    }
    
    public var iconName: String {
        switch self {
        case .lido: return "drop.fill"
        case .aave: return "waveform.path.ecg"
        case .rocket: return "flame.fill"
        case .compound: return "chart.bar.fill"
        case .eigenlayer: return "square.stack.3d.up.fill"
        }
    }
}

// MARK: - Yield Risk Level

/// Risk assessment for yield opportunities
public enum YieldRiskLevel: String, Codable, CaseIterable, Sendable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case veryHigh = "Very High"
    
    public var displayName: String {
        rawValue
    }
    
    public var score: Int {
        switch self {
        case .low: return 1
        case .medium: return 2
        case .high: return 3
        case .veryHigh: return 4
        }
    }
    
    public var description: String {
        switch self {
        case .low:
            return "Battle-tested protocol with long track record"
        case .medium:
            return "Established protocol with some complexity"
        case .high:
            return "Newer protocol or complex strategies"
        case .veryHigh:
            return "Experimental - high reward, high risk"
        }
    }
}

// MARK: - Lockup Period

/// Staking lockup configuration
public enum LockupPeriod: Codable, Sendable, Equatable {
    case none                       // No lockup, instant withdrawal
    case unbondingPeriod(days: Int) // Requires unbonding period
    case fixed(days: Int)           // Fixed term, no early exit
    case variable                   // Protocol-dependent
    
    public var displayText: String {
        switch self {
        case .none:
            return "No lockup"
        case .unbondingPeriod(let days):
            return "\(days) day unbonding"
        case .fixed(let days):
            return "\(days) day lock"
        case .variable:
            return "Variable"
        }
    }
    
    public var isLiquid: Bool {
        if case .none = self { return true }
        return false
    }
}

// MARK: - Yield Opportunity

/// Represents a yield-generating opportunity from a DeFi protocol
public struct YieldOpportunity: Identifiable, Codable, Sendable, Equatable {
    public let id: String
    
    /// Protocol providing the yield
    public let `protocol`: YieldProtocol
    
    /// Asset to stake/deposit
    public let inputAsset: Asset
    
    /// Asset received (staking derivative or same as input)
    public let outputAsset: Asset?
    
    /// Current APY as percentage (e.g., 4.5 = 4.5%)
    public let apy: Decimal
    
    /// APY range for variable yields
    public let apyRange: ClosedRange<Decimal>?
    
    /// TVL in USD
    public let tvlUSD: Decimal?
    
    /// Lockup requirements
    public let lockup: LockupPeriod
    
    /// Risk assessment
    public let riskLevel: YieldRiskLevel
    
    /// Minimum stake amount (in smallest unit)
    public let minimumStake: String?
    
    /// Maximum stake amount (in smallest unit)
    public let maximumStake: String?
    
    /// Whether the opportunity is currently active
    public let isActive: Bool
    
    /// Last updated timestamp
    public let lastUpdated: Date
    
    /// Description of the strategy
    public let strategyDescription: String?
    
    /// Rewards breakdown (e.g., base + boost)
    public let rewardsBreakdown: [RewardComponent]?
    
    public init(
        id: String,
        protocol: YieldProtocol,
        inputAsset: Asset,
        outputAsset: Asset? = nil,
        apy: Decimal,
        apyRange: ClosedRange<Decimal>? = nil,
        tvlUSD: Decimal? = nil,
        lockup: LockupPeriod,
        riskLevel: YieldRiskLevel,
        minimumStake: String? = nil,
        maximumStake: String? = nil,
        isActive: Bool = true,
        lastUpdated: Date = Date(),
        strategyDescription: String? = nil,
        rewardsBreakdown: [RewardComponent]? = nil
    ) {
        self.id = id
        self.protocol = `protocol`
        self.inputAsset = inputAsset
        self.outputAsset = outputAsset
        self.apy = apy
        self.apyRange = apyRange
        self.tvlUSD = tvlUSD
        self.lockup = lockup
        self.riskLevel = riskLevel
        self.minimumStake = minimumStake
        self.maximumStake = maximumStake
        self.isActive = isActive
        self.lastUpdated = lastUpdated
        self.strategyDescription = strategyDescription
        self.rewardsBreakdown = rewardsBreakdown
    }
    
    /// Formatted APY for display
    public var formattedAPY: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return "\(formatter.string(from: apy as NSNumber) ?? "0.00")%"
    }
    
    /// Formatted TVL for display
    public var formattedTVL: String? {
        guard let tvl = tvlUSD else { return nil }
        return tvl.formatCompact()
    }
}

// MARK: - Reward Component

/// Breakdown of yield sources
public struct RewardComponent: Codable, Sendable, Equatable {
    public let name: String
    public let apy: Decimal
    public let isBoost: Bool
    
    public init(name: String, apy: Decimal, isBoost: Bool = false) {
        self.name = name
        self.apy = apy
        self.isBoost = isBoost
    }
}

// MARK: - Staking Position

/// Represents a user's staked position
public struct StakingPosition: Identifiable, Codable, Sendable, Equatable {
    public let id: String
    
    /// Opportunity this position is for
    public let opportunityId: String
    
    /// Protocol
    public let `protocol`: YieldProtocol
    
    /// Staked amount (in smallest unit)
    public let stakedAmount: String
    
    /// Current value including rewards (in smallest unit)
    public let currentValue: String
    
    /// Earned rewards (in smallest unit)
    public let earnedRewards: String
    
    /// Asset staked
    public let stakedAsset: Asset
    
    /// Derivative token received (e.g., stETH)
    public let derivativeAsset: Asset?
    
    /// Entry timestamp
    public let stakedAt: Date
    
    /// Unlock timestamp (if locked)
    public let unlocksAt: Date?
    
    /// Whether currently in unbonding
    public let isUnbonding: Bool
    
    /// Pending unbond amount
    public let pendingUnbond: String?
    
    public init(
        id: String,
        opportunityId: String,
        protocol: YieldProtocol,
        stakedAmount: String,
        currentValue: String,
        earnedRewards: String,
        stakedAsset: Asset,
        derivativeAsset: Asset? = nil,
        stakedAt: Date,
        unlocksAt: Date? = nil,
        isUnbonding: Bool = false,
        pendingUnbond: String? = nil
    ) {
        self.id = id
        self.opportunityId = opportunityId
        self.protocol = `protocol`
        self.stakedAmount = stakedAmount
        self.currentValue = currentValue
        self.earnedRewards = earnedRewards
        self.stakedAsset = stakedAsset
        self.derivativeAsset = derivativeAsset
        self.stakedAt = stakedAt
        self.unlocksAt = unlocksAt
        self.isUnbonding = isUnbonding
        self.pendingUnbond = pendingUnbond
    }
    
    /// Formatted staked amount
    public var formattedStakedAmount: String {
        formatAmount(stakedAmount, decimals: stakedAsset.decimals)
    }
    
    /// Formatted rewards
    public var formattedRewards: String {
        formatAmount(earnedRewards, decimals: stakedAsset.decimals)
    }
    
    /// Time staked
    public var timeStaked: TimeInterval {
        Date().timeIntervalSince(stakedAt)
    }
    
    /// Formatted time staked
    public var formattedTimeStaked: String {
        let days = Int(timeStaked / 86400)
        if days > 0 {
            return "\(days) day\(days == 1 ? "" : "s")"
        }
        let hours = Int(timeStaked / 3600)
        return "\(hours) hour\(hours == 1 ? "" : "s")"
    }
    
    private func formatAmount(_ raw: String, decimals: Int) -> String {
        guard let rawValue = Decimal(string: raw) else { return "0" }
        let divisor = pow(Decimal(10), decimals)
        let balance = rawValue / divisor
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = min(decimals, 6)
        
        return formatter.string(from: balance as NSNumber) ?? "0"
    }
}

// MARK: - Staking Transaction Type

/// Types of staking transactions
public enum StakingTransactionType: String, Codable, Sendable {
    case stake = "Stake"
    case unstake = "Unstake"
    case claimRewards = "Claim Rewards"
    case compound = "Compound"
}

// MARK: - Staking Request

/// Request to stake assets
public struct StakingRequest: Sendable {
    public let opportunity: YieldOpportunity
    public let amount: String
    public let senderAddress: String
    public let referralCode: String?
    
    public init(
        opportunity: YieldOpportunity,
        amount: String,
        senderAddress: String,
        referralCode: String? = nil
    ) {
        self.opportunity = opportunity
        self.amount = amount
        self.senderAddress = senderAddress
        self.referralCode = referralCode
    }
}

// MARK: - Unstaking Request

/// Request to unstake assets
public struct UnstakingRequest: Sendable {
    public let position: StakingPosition
    public let amount: String
    public let senderAddress: String
    public let immediately: Bool // For liquid staking
    
    public init(
        position: StakingPosition,
        amount: String,
        senderAddress: String,
        immediately: Bool = false
    ) {
        self.position = position
        self.amount = amount
        self.senderAddress = senderAddress
        self.immediately = immediately
    }
}

// MARK: - Prepared Staking Transaction

/// A prepared staking transaction ready for simulation
public struct PreparedStakingTransaction: Sendable {
    public let from: String
    public let to: String
    public let value: String
    public let calldata: Data
    public let chain: AssetChain
    public let gasLimit: UInt64
    public let transactionType: StakingTransactionType
    public let opportunity: YieldOpportunity?
    
    public init(
        from: String,
        to: String,
        value: String,
        calldata: Data,
        chain: AssetChain,
        gasLimit: UInt64,
        transactionType: StakingTransactionType,
        opportunity: YieldOpportunity? = nil
    ) {
        self.from = from
        self.to = to
        self.value = value
        self.calldata = calldata
        self.chain = chain
        self.gasLimit = gasLimit
        self.transactionType = transactionType
        self.opportunity = opportunity
    }
    
    /// Hex-encoded calldata
    public var calldataHex: String {
        "0x" + calldata.map { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Staking Error

/// Errors that can occur during staking operations
public enum StakingError: Error, LocalizedError, Sendable {
    case insufficientBalance
    case belowMinimumStake(minimum: String)
    case aboveMaximumStake(maximum: String)
    case protocolPaused
    case opportunityInactive
    case simulationFailed(reason: String)
    case transactionFailed(reason: String)
    case networkError(underlying: String)
    case positionNotFound
    case unstakingLocked(unlocksAt: Date)
    case invalidAmount
    
    public var errorDescription: String? {
        switch self {
        case .insufficientBalance:
            return "Insufficient balance to stake"
        case .belowMinimumStake(let min):
            return "Amount below minimum stake: \(min)"
        case .aboveMaximumStake(let max):
            return "Amount above maximum stake: \(max)"
        case .protocolPaused:
            return "Protocol is currently paused"
        case .opportunityInactive:
            return "This opportunity is no longer active"
        case .simulationFailed(let reason):
            return "Simulation failed: \(reason)"
        case .transactionFailed(let reason):
            return "Transaction failed: \(reason)"
        case .networkError(let underlying):
            return "Network error: \(underlying)"
        case .positionNotFound:
            return "Staking position not found"
        case .unstakingLocked(let date):
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return "Position locked until \(formatter.string(from: date))"
        case .invalidAmount:
            return "Invalid staking amount"
        }
    }
}

// MARK: - Earn Data Cache Model

/// Cached earn data for instant load
public struct EarnCacheData: Codable, Sendable {
    public let opportunities: [YieldOpportunity]
    public let positions: [StakingPosition]
    public let lastUpdated: Date
    
    public init(
        opportunities: [YieldOpportunity],
        positions: [StakingPosition],
        lastUpdated: Date = Date()
    ) {
        self.opportunities = opportunities
        self.positions = positions
        self.lastUpdated = lastUpdated
    }
    
    /// Check if cache is stale (older than 5 minutes)
    public var isStale: Bool {
        Date().timeIntervalSince(lastUpdated) > 300
    }
}

// MARK: - Protocol Contracts

/// Contract addresses for yield protocols
public enum ProtocolContracts {
    // Lido (Ethereum Mainnet)
    public static let lidoStETH = "0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84"
    public static let lidoWithdrawal = "0x889edC2eDab5f40e902b864aD4d7AdE8E412F9B1"
    
    // Aave V3 (Ethereum Mainnet)
    public static let aavePool = "0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2"
    public static let aaveDataProvider = "0x7B4EB56E7CD4b454BA8ff71E4518426369a138a3"
    
    // Rocket Pool
    public static let rocketDepositPool = "0xDD3f50F8A6CafbE9b31a427582963f465E745AF8"
    public static let rocketStorage = "0x1d8f8f00cfa6758d7bE78336684788Fb0ee0Fa46"
}


