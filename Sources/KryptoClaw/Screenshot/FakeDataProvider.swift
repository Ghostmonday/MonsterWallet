// MODULE: FakeDataProvider
// VERSION: 1.0.0
// PURPOSE: Realistic fake data for App Store screenshots

import SwiftUI
import Foundation

// MARK: - Fake Data Provider

/// Provides realistic fake data for screenshot mode
/// All data is non-sensitive and designed for App Store presentation
public final class FakeDataProvider {
    
    // MARK: - Singleton
    
    public static let shared = FakeDataProvider()
    
    private init() {}
    
    // MARK: - Wallet Data
    
    public struct FakeWalletData {
        public let totalBalance: Double = 12_847.32
        public let dailyChangePercent: Double = 2.4
        public let dailyChangeAmount: Double = 301.58
        public let walletAddress: String = "0x742d35Cc6634C0532925a3b844Bc454e4438f44e"
        public let walletName: String = "Main Vault"
    }
    
    public let wallet = FakeWalletData()
    
    // MARK: - Token Balances
    
    public struct FakeTokenBalance: Identifiable {
        public let id = UUID()
        public let symbol: String
        public let name: String
        public let balance: String
        public let usdValue: Double
        public let price: Double
        public let change24h: Double
        public let chain: String
        public let iconName: String
    }
    
    public let tokens: [FakeTokenBalance] = [
        FakeTokenBalance(
            symbol: "ETH",
            name: "Ethereum",
            balance: "2.4521",
            usdValue: 5_892.45,
            price: 2_402.18,
            change24h: 3.2,
            chain: "Ethereum",
            iconName: "eth.circle.fill"
        ),
        FakeTokenBalance(
            symbol: "BTC",
            name: "Bitcoin",
            balance: "0.0847",
            usdValue: 4_235.67,
            price: 50_008.42,
            change24h: 1.8,
            chain: "Bitcoin",
            iconName: "bitcoinsign.circle.fill"
        ),
        FakeTokenBalance(
            symbol: "SOL",
            name: "Solana",
            balance: "24.8",
            usdValue: 1_984.00,
            price: 80.00,
            change24h: 5.4,
            chain: "Solana",
            iconName: "s.circle.fill"
        ),
        FakeTokenBalance(
            symbol: "USDC",
            name: "USD Coin",
            balance: "485.00",
            usdValue: 485.00,
            price: 1.00,
            change24h: 0.0,
            chain: "Ethereum",
            iconName: "dollarsign.circle.fill"
        ),
        FakeTokenBalance(
            symbol: "AVAX",
            name: "Avalanche",
            balance: "8.25",
            usdValue: 148.50,
            price: 18.00,
            change24h: -2.1,
            chain: "Avalanche",
            iconName: "a.circle.fill"
        ),
        FakeTokenBalance(
            symbol: "LINK",
            name: "Chainlink",
            balance: "6.5",
            usdValue: 78.00,
            price: 12.00,
            change24h: 4.2,
            chain: "Ethereum",
            iconName: "link.circle.fill"
        ),
        FakeTokenBalance(
            symbol: "ARB",
            name: "Arbitrum",
            balance: "15.0",
            usdValue: 15.00,
            price: 1.00,
            change24h: -0.5,
            chain: "Arbitrum",
            iconName: "arrowtriangle.right.circle.fill"
        ),
        FakeTokenBalance(
            symbol: "OP",
            name: "Optimism",
            balance: "4.35",
            usdValue: 8.70,
            price: 2.00,
            change24h: 1.2,
            chain: "Optimism",
            iconName: "o.circle.fill"
        )
    ]
    
    // MARK: - Transactions
    
    public enum FakeTransactionType: String {
        case send = "Sent"
        case receive = "Received"
        case swap = "Swapped"
        case stake = "Staked"
        case unstake = "Unstaked"
        case approve = "Approved"
    }
    
    public enum FakeTransactionStatus: String {
        case confirmed = "Confirmed"
        case pending = "Pending"
        case failed = "Failed"
    }
    
    public struct FakeTransaction: Identifiable {
        public let id = UUID()
        public let type: FakeTransactionType
        public let status: FakeTransactionStatus
        public let amount: String
        public let symbol: String
        public let usdValue: String
        public let timestamp: Date
        public let hash: String
        public let toAddress: String?
        public let fromAddress: String?
        public let swapToSymbol: String?
        public let swapToAmount: String?
    }
    
    public var transactions: [FakeTransaction] {
        let now = Date()
        return [
            FakeTransaction(
                type: .receive,
                status: .confirmed,
                amount: "0.5",
                symbol: "ETH",
                usdValue: "$1,201.09",
                timestamp: now.addingTimeInterval(-3600),
                hash: "0x8f2e...4a9c",
                toAddress: wallet.walletAddress,
                fromAddress: "0x1234...5678",
                swapToSymbol: nil,
                swapToAmount: nil
            ),
            FakeTransaction(
                type: .swap,
                status: .confirmed,
                amount: "100",
                symbol: "USDC",
                usdValue: "$100.00",
                timestamp: now.addingTimeInterval(-7200),
                hash: "0x7d3a...8b2f",
                toAddress: nil,
                fromAddress: nil,
                swapToSymbol: "ETH",
                swapToAmount: "0.0416"
            ),
            FakeTransaction(
                type: .send,
                status: .confirmed,
                amount: "0.25",
                symbol: "ETH",
                usdValue: "$600.55",
                timestamp: now.addingTimeInterval(-14400),
                hash: "0x9e1c...3d7a",
                toAddress: "0xAlice...7890",
                fromAddress: wallet.walletAddress,
                swapToSymbol: nil,
                swapToAmount: nil
            ),
            FakeTransaction(
                type: .stake,
                status: .confirmed,
                amount: "1.0",
                symbol: "ETH",
                usdValue: "$2,402.18",
                timestamp: now.addingTimeInterval(-86400),
                hash: "0x4f8b...2c1e",
                toAddress: "Lido",
                fromAddress: wallet.walletAddress,
                swapToSymbol: "stETH",
                swapToAmount: "1.0"
            ),
            FakeTransaction(
                type: .receive,
                status: .confirmed,
                amount: "5.0",
                symbol: "SOL",
                usdValue: "$400.00",
                timestamp: now.addingTimeInterval(-172800),
                hash: "5Yjk...8mNp",
                toAddress: wallet.walletAddress,
                fromAddress: "Bob.sol",
                swapToSymbol: nil,
                swapToAmount: nil
            ),
            FakeTransaction(
                type: .swap,
                status: .confirmed,
                amount: "0.01",
                symbol: "BTC",
                usdValue: "$500.08",
                timestamp: now.addingTimeInterval(-259200),
                hash: "0xa2d4...6f9c",
                toAddress: nil,
                fromAddress: nil,
                swapToSymbol: "ETH",
                swapToAmount: "0.208"
            ),
            FakeTransaction(
                type: .approve,
                status: .confirmed,
                amount: "∞",
                symbol: "USDC",
                usdValue: "$0.00",
                timestamp: now.addingTimeInterval(-345600),
                hash: "0xb7e3...1a8d",
                toAddress: "Uniswap",
                fromAddress: wallet.walletAddress,
                swapToSymbol: nil,
                swapToAmount: nil
            ),
            FakeTransaction(
                type: .send,
                status: .confirmed,
                amount: "50",
                symbol: "USDC",
                usdValue: "$50.00",
                timestamp: now.addingTimeInterval(-432000),
                hash: "0xc1f9...5e2b",
                toAddress: "0xCharlie...2345",
                fromAddress: wallet.walletAddress,
                swapToSymbol: nil,
                swapToAmount: nil
            ),
            FakeTransaction(
                type: .receive,
                status: .confirmed,
                amount: "0.1",
                symbol: "ETH",
                usdValue: "$240.22",
                timestamp: now.addingTimeInterval(-518400),
                hash: "0xd5a2...9c7f",
                toAddress: wallet.walletAddress,
                fromAddress: "0xDave...6789",
                swapToSymbol: nil,
                swapToAmount: nil
            ),
            FakeTransaction(
                type: .unstake,
                status: .confirmed,
                amount: "0.5",
                symbol: "stETH",
                usdValue: "$1,201.09",
                timestamp: now.addingTimeInterval(-604800),
                hash: "0xe8b1...4d3a",
                toAddress: wallet.walletAddress,
                fromAddress: "Lido",
                swapToSymbol: "ETH",
                swapToAmount: "0.5"
            ),
            FakeTransaction(
                type: .swap,
                status: .confirmed,
                amount: "2.0",
                symbol: "SOL",
                usdValue: "$160.00",
                timestamp: now.addingTimeInterval(-691200),
                hash: "3Kpm...7xYz",
                toAddress: nil,
                fromAddress: nil,
                swapToSymbol: "USDC",
                swapToAmount: "159.80"
            ),
            FakeTransaction(
                type: .send,
                status: .pending,
                amount: "0.05",
                symbol: "ETH",
                usdValue: "$120.11",
                timestamp: now.addingTimeInterval(-300),
                hash: "0xf2c4...8a1e",
                toAddress: "0xEve...0123",
                fromAddress: wallet.walletAddress,
                swapToSymbol: nil,
                swapToAmount: nil
            )
        ]
    }
    
    // MARK: - NFTs
    
    public struct FakeNFT: Identifiable {
        public let id = UUID()
        public let name: String
        public let collection: String
        public let tokenId: String
        public let chain: String
        public let floorPrice: String?
        public let lastSale: String?
        public let imageGradient: [Color]
        public let traits: [(String, String)]
    }
    
    public let nfts: [FakeNFT] = [
        FakeNFT(
            name: "Quantum Voyager #4281",
            collection: "Quantum Collective",
            tokenId: "4281",
            chain: "Ethereum",
            floorPrice: "2.4 ETH",
            lastSale: "3.1 ETH",
            imageGradient: [.purple, .blue, .cyan],
            traits: [("Rarity", "Legendary"), ("Background", "Cosmic")]
        ),
        FakeNFT(
            name: "Neon Samurai #892",
            collection: "Cyber Warriors",
            tokenId: "892",
            chain: "Ethereum",
            floorPrice: "1.8 ETH",
            lastSale: "2.2 ETH",
            imageGradient: [.red, .orange, .pink],
            traits: [("Weapon", "Katana"), ("Armor", "Platinum")]
        ),
        FakeNFT(
            name: "Abstract Mind #156",
            collection: "Digital Dreams",
            tokenId: "156",
            chain: "Ethereum",
            floorPrice: "0.85 ETH",
            lastSale: "1.1 ETH",
            imageGradient: [.green, .teal, .blue],
            traits: [("Style", "Surreal"), ("Edition", "1/1")]
        ),
        FakeNFT(
            name: "Golden Horizon #33",
            collection: "Sunset Series",
            tokenId: "33",
            chain: "Solana",
            floorPrice: "45 SOL",
            lastSale: "52 SOL",
            imageGradient: [.yellow, .orange, .red],
            traits: [("Time", "Dusk"), ("Location", "Ocean")]
        ),
        FakeNFT(
            name: "Void Walker #2047",
            collection: "Dark Realms",
            tokenId: "2047",
            chain: "Ethereum",
            floorPrice: "1.2 ETH",
            lastSale: nil,
            imageGradient: [.black, .purple, .indigo],
            traits: [("Power", "Infinite"), ("Origin", "Unknown")]
        ),
        FakeNFT(
            name: "Crystal Genesis #7",
            collection: "Gem Origins",
            tokenId: "7",
            chain: "Ethereum",
            floorPrice: "5.5 ETH",
            lastSale: "6.8 ETH",
            imageGradient: [.cyan, .white, .mint],
            traits: [("Clarity", "Flawless"), ("Cut", "Brilliant")]
        )
    ]
    
    // MARK: - Staking / Earn Data
    
    public struct FakeStakingOpportunity: Identifiable {
        public let id = UUID()
        public let protocolName: String
        public let asset: String
        public let apy: Double
        public let tvl: String
        public let riskLevel: String
        public let lockupPeriod: String
        public let iconName: String
    }
    
    public let stakingOpportunities: [FakeStakingOpportunity] = [
        FakeStakingOpportunity(
            protocolName: "Lido",
            asset: "ETH",
            apy: 4.2,
            tvl: "$12.4B",
            riskLevel: "Low",
            lockupPeriod: "None",
            iconName: "drop.fill"
        ),
        FakeStakingOpportunity(
            protocolName: "Rocket Pool",
            asset: "ETH",
            apy: 4.8,
            tvl: "$2.1B",
            riskLevel: "Low",
            lockupPeriod: "None",
            iconName: "flame.fill"
        ),
        FakeStakingOpportunity(
            protocolName: "Aave V3",
            asset: "USDC",
            apy: 8.5,
            tvl: "$8.7B",
            riskLevel: "Low",
            lockupPeriod: "None",
            iconName: "chart.line.uptrend.xyaxis"
        ),
        FakeStakingOpportunity(
            protocolName: "Convex",
            asset: "ETH-stETH LP",
            apy: 12.4,
            tvl: "$1.2B",
            riskLevel: "Medium",
            lockupPeriod: "None",
            iconName: "arrow.triangle.2.circlepath"
        ),
        FakeStakingOpportunity(
            protocolName: "Marinade",
            asset: "SOL",
            apy: 7.2,
            tvl: "$890M",
            riskLevel: "Low",
            lockupPeriod: "None",
            iconName: "sun.max.fill"
        ),
        FakeStakingOpportunity(
            protocolName: "Yearn V3",
            asset: "DAI",
            apy: 15.8,
            tvl: "$450M",
            riskLevel: "Medium",
            lockupPeriod: "None",
            iconName: "building.columns.fill"
        ),
        FakeStakingOpportunity(
            protocolName: "Pendle",
            asset: "stETH",
            apy: 18.2,
            tvl: "$280M",
            riskLevel: "High",
            lockupPeriod: "30 days",
            iconName: "hourglass"
        )
    ]
    
    public struct FakeStakingPosition: Identifiable {
        public let id = UUID()
        public let protocolName: String
        public let asset: String
        public let stakedAmount: String
        public let stakedValue: String
        public let rewards: String
        public let rewardsValue: String
        public let apy: Double
        public let startDate: Date
        public let iconName: String
    }
    
    public var stakingPositions: [FakeStakingPosition] {
        let now = Date()
        return [
            FakeStakingPosition(
                protocolName: "Lido",
                asset: "stETH",
                stakedAmount: "1.0",
                stakedValue: "$2,402.18",
                rewards: "0.0084",
                rewardsValue: "$20.18",
                apy: 4.2,
                startDate: now.addingTimeInterval(-2592000),
                iconName: "drop.fill"
            ),
            FakeStakingPosition(
                protocolName: "Aave V3",
                asset: "aUSDC",
                stakedAmount: "500",
                stakedValue: "$500.00",
                rewards: "3.54",
                rewardsValue: "$3.54",
                apy: 8.5,
                startDate: now.addingTimeInterval(-1296000),
                iconName: "chart.line.uptrend.xyaxis"
            ),
            FakeStakingPosition(
                protocolName: "Marinade",
                asset: "mSOL",
                stakedAmount: "10.0",
                stakedValue: "$800.00",
                rewards: "0.12",
                rewardsValue: "$9.60",
                apy: 7.2,
                startDate: now.addingTimeInterval(-5184000),
                iconName: "sun.max.fill"
            )
        ]
    }
    
    // MARK: - Swap Preview Data
    
    public struct FakeSwapQuote {
        public let fromToken: String
        public let fromAmount: String
        public let fromValue: String
        public let toToken: String
        public let toAmount: String
        public let toValue: String
        public let exchangeRate: String
        public let priceImpact: String
        public let gasFee: String
        public let gasFeeUSD: String
        public let route: [String]
        public let mevProtected: Bool
        public let slippage: String
        public let minimumReceived: String
    }
    
    public let swapQuote = FakeSwapQuote(
        fromToken: "ETH",
        fromAmount: "0.5",
        fromValue: "$1,201.09",
        toToken: "USDC",
        toAmount: "1,198.45",
        toValue: "$1,198.45",
        exchangeRate: "1 ETH = 2,396.90 USDC",
        priceImpact: "0.02%",
        gasFee: "0.0024 ETH",
        gasFeeUSD: "$5.76",
        route: ["ETH", "WETH", "USDC"],
        mevProtected: true,
        slippage: "0.5%",
        minimumReceived: "1,192.46 USDC"
    )
    
    // MARK: - Security Alerts
    
    public struct FakeSecurityAlert: Identifiable {
        public let id = UUID()
        public let type: SecurityAlertType
        public let title: String
        public let description: String
        public let severity: AlertSeverity
        public let timestamp: Date
        
        public enum SecurityAlertType {
            case addressPoisoning
            case clipboardGuard
            case phishingDetected
            case unusualActivity
        }
        
        public enum AlertSeverity {
            case critical
            case warning
            case info
        }
    }
    
    public var securityAlerts: [FakeSecurityAlert] {
        let now = Date()
        return [
            FakeSecurityAlert(
                type: .addressPoisoning,
                title: "Address Poisoning Detected",
                description: "A similar-looking address (0x742d...44ef) was detected in your history. This may be an attempt to trick you into sending funds to a scammer.",
                severity: .critical,
                timestamp: now.addingTimeInterval(-1800)
            ),
            FakeSecurityAlert(
                type: .clipboardGuard,
                title: "Clipboard Protected",
                description: "Monster Wallet cleared a crypto address from your clipboard after 60 seconds to protect your privacy.",
                severity: .info,
                timestamp: now.addingTimeInterval(-3600)
            )
        ]
    }
    
    // MARK: - HSK Data
    
    public struct FakeHSKData {
        public let keyName: String = "YubiKey 5C NFC"
        public let keySerial: String = "••••••4827"
        public let boundWallet: String = "HSK Vault"
        public let boundAddress: String = "0x9a8B...3c2F"
        public let lastUsed: Date
        public let isVerified: Bool = true
        public let secureEnclaveEnabled: Bool = true
    }
    
    public var hskData: FakeHSKData {
        FakeHSKData(lastUsed: Date().addingTimeInterval(-7200))
    }
    
    // MARK: - Chart Data
    
    public struct FakeChartPoint: Identifiable {
        public let id = UUID()
        public let timestamp: Date
        public let value: Double
    }
    
    public var portfolioChartData: [FakeChartPoint] {
        let now = Date()
        let baseValue = 12_000.0
        var points: [FakeChartPoint] = []
        
        for i in 0..<30 {
            let timestamp = now.addingTimeInterval(Double(-i * 86400))
            let variation = sin(Double(i) * 0.3) * 500 + Double.random(in: -200...200)
            let value = baseValue + variation - Double(i) * 30
            points.append(FakeChartPoint(timestamp: timestamp, value: max(value, 10000)))
        }
        
        return points.reversed()
    }
    
    // MARK: - Formatting Helpers
    
    public func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
    
    public func formatPercent(_ value: Double) -> String {
        let sign = value >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", value))%"
    }
    
    public func formatTimeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

