// MODULE: ScreenshotViews
// VERSION: 1.0.0
// PURPOSE: Production-grade screenshot views for App Store presentation

import SwiftUI

// MARK: - Screenshot Container

/// Main container for navigating between screenshot views
public struct ScreenshotContainer: View {
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var screenshotManager = ScreenshotModeManager.shared
    
    public init() {}
    
    public var body: some View {
        let theme = themeManager.currentTheme
        
        ZStack {
            // Current screenshot view
            screenshotView(for: screenshotManager.currentScreenshot)
            
            // Debug navigation overlay (only in DEBUG)
            #if DEBUG
            VStack {
                Spacer()
                screenshotNavigator(theme: theme)
            }
            #endif
        }
        .environment(\.isScreenshotMode, true)
    }
    
    @ViewBuilder
    private func screenshotView(for type: ScreenshotModeManager.ScreenshotType) -> some View {
        switch type {
        case .homeDashboard:
            Screenshot_HomeDashboard()
        case .multiChainOverview:
            Screenshot_MultiChainOverview()
        case .transactionHistory:
            Screenshot_TransactionHistory()
        case .nftGallery:
            Screenshot_NFTGallery()
        case .earnOpportunities:
            Screenshot_EarnOpportunities()
        case .activePositions:
            Screenshot_ActivePositions()
        case .swapPreview:
            Screenshot_SwapPreview()
        case .transactionSimulation:
            Screenshot_TransactionSimulation()
        case .slideToConfirm:
            Screenshot_SlideToConfirm()
        case .hardwareSecurity:
            Screenshot_HardwareSecurity()
        case .settings:
            Screenshot_Settings()
        case .onboarding:
            Screenshot_Onboarding()
        }
    }
    
    #if DEBUG
    private func screenshotNavigator(theme: any ThemeProtocolV2) -> some View {
        HStack(spacing: 20) {
            Button(action: { screenshotManager.previousScreenshot() }) {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.title)
                    .foregroundColor(theme.accentColor)
            }
            
            Text("\(screenshotManager.currentScreenshot.rawValue)/12")
                .font(theme.captionFont)
                .foregroundColor(theme.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(theme.cardBackground)
                .cornerRadius(theme.cornerRadius)
            
            Button(action: { screenshotManager.nextScreenshot() }) {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.title)
                    .foregroundColor(theme.accentColor)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(theme.cornerRadius)
        .padding(.bottom, 20)
    }
    #endif
}

// MARK: - Screen 1: Home Dashboard

struct Screenshot_HomeDashboard: View {
    @EnvironmentObject var themeManager: ThemeManager
    private let data = FakeDataProvider.shared
    
    var body: some View {
        let theme = themeManager.currentTheme
        
        ZStack {
            Color.clear
                .themedContainer(theme: theme, showPattern: true, applyAnimation: false)
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: theme.spacingL) {
                    // Balance Card
                    VStack(spacing: theme.spacingS) {
                        Text("Total Balance")
                            .font(theme.captionFont)
                            .foregroundColor(theme.textSecondary)
                        
                        Text(data.formatCurrency(data.wallet.totalBalance))
                            .font(theme.balanceFont)
                            .foregroundColor(theme.textPrimary)
                        
                        HStack(spacing: theme.spacingXS) {
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                            Text(data.formatPercent(data.wallet.dailyChangePercent))
                            Text("today")
                                .foregroundColor(theme.textSecondary)
                        }
                        .font(theme.captionFont)
                        .foregroundColor(theme.successColor)
                    }
                    .padding(.top, theme.spacing2XL)
                    
                    // Quick Actions
                    HStack(spacing: theme.spacing2XL) {
                        quickActionButton(icon: theme.iconSend, label: "Send", theme: theme)
                        quickActionButton(icon: theme.iconReceive, label: "Receive", theme: theme)
                        quickActionButton(icon: theme.iconSwap, label: "Swap", theme: theme)
                        quickActionButton(icon: "chart.line.uptrend.xyaxis", label: "Earn", theme: theme)
                    }
                    .padding(.vertical, theme.spacingM)
                    
                    // Token List
                    VStack(spacing: theme.spacingS) {
                        HStack {
                            Text("Assets")
                                .font(theme.headlineFont)
                                .foregroundColor(theme.textPrimary)
                            Spacer()
                            Text("\(data.tokens.count) tokens")
                                .font(theme.captionFont)
                                .foregroundColor(theme.textSecondary)
                        }
                        .padding(.horizontal)
                        
                        ForEach(data.tokens) { token in
                            tokenRow(token: token, theme: theme)
                        }
                    }
                }
                .padding()
            }
        }
    }
    
    private func quickActionButton(icon: String, label: String, theme: any ThemeProtocolV2) -> some View {
        VStack(spacing: theme.spacingS) {
            ZStack {
                Circle()
                    .fill(theme.accentColor)
                    .frame(width: theme.actionButtonSize, height: theme.actionButtonSize)
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
            }
            Text(label)
                .font(theme.captionFont)
                .foregroundColor(theme.textPrimary)
        }
    }
    
    private func tokenRow(token: FakeDataProvider.FakeTokenBalance, theme: any ThemeProtocolV2) -> some View {
        KryptoCard {
            HStack {
                // Token icon
                ZStack {
                    Circle()
                        .fill(theme.accentColor.opacity(0.15))
                        .frame(width: theme.avatarSizeMedium, height: theme.avatarSizeMedium)
                    Text(token.symbol.prefix(1))
                        .font(theme.headlineFont)
                        .foregroundColor(theme.accentColor)
                }
                
                VStack(alignment: .leading, spacing: theme.spacingXS) {
                    Text(token.name)
                        .font(theme.headlineFont)
                        .foregroundColor(theme.textPrimary)
                    Text("\(token.balance) \(token.symbol)")
                        .font(theme.captionFont)
                        .foregroundColor(theme.textSecondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: theme.spacingXS) {
                    Text(data.formatCurrency(token.usdValue))
                        .font(theme.headlineFont)
                        .foregroundColor(theme.textPrimary)
                    Text(data.formatPercent(token.change24h))
                        .font(theme.captionFont)
                        .foregroundColor(token.change24h >= 0 ? theme.successColor : theme.errorColor)
                }
            }
        }
    }
}

// MARK: - Screen 2: Multi-Chain Overview

struct Screenshot_MultiChainOverview: View {
    @EnvironmentObject var themeManager: ThemeManager
    private let data = FakeDataProvider.shared
    
    var body: some View {
        let theme = themeManager.currentTheme
        
        ZStack {
            Color.clear
                .themedContainer(theme: theme, showPattern: true, applyAnimation: false)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Networks")
                        .font(theme.font(style: .title))
                        .foregroundColor(theme.textPrimary)
                    Spacer()
                }
                .padding()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: theme.spacingM) {
                        // Chain cards
                        chainCard(
                            name: "Ethereum",
                            symbol: "ETH",
                            balance: "2.4521 ETH",
                            value: "$5,892.45",
                            color: .blue,
                            theme: theme
                        )
                        
                        chainCard(
                            name: "Bitcoin",
                            symbol: "BTC",
                            balance: "0.0847 BTC",
                            value: "$4,235.67",
                            color: .orange,
                            theme: theme
                        )
                        
                        chainCard(
                            name: "Solana",
                            symbol: "SOL",
                            balance: "24.8 SOL",
                            value: "$1,984.00",
                            color: .purple,
                            theme: theme
                        )
                        
                        chainCard(
                            name: "Avalanche",
                            symbol: "AVAX",
                            balance: "8.25 AVAX",
                            value: "$148.50",
                            color: .red,
                            theme: theme
                        )
                        
                        chainCard(
                            name: "Arbitrum",
                            symbol: "ARB",
                            balance: "15.0 ARB",
                            value: "$15.00",
                            color: .cyan,
                            theme: theme
                        )
                        
                        chainCard(
                            name: "Optimism",
                            symbol: "OP",
                            balance: "4.35 OP",
                            value: "$8.70",
                            color: .red.opacity(0.8),
                            theme: theme
                        )
                    }
                    .padding()
                }
            }
        }
    }
    
    private func chainCard(name: String, symbol: String, balance: String, value: String, color: Color, theme: any ThemeProtocolV2) -> some View {
        KryptoCard {
            HStack {
                // Chain icon
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 50, height: 50)
                    Circle()
                        .stroke(color, lineWidth: 2)
                        .frame(width: 50, height: 50)
                    Text(symbol.prefix(1))
                        .font(theme.font(style: .title2))
                        .fontWeight(.bold)
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: theme.spacingXS) {
                    Text(name)
                        .font(theme.headlineFont)
                        .foregroundColor(theme.textPrimary)
                    
                    // Network badge
                    Text("Mainnet")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(color.opacity(0.15))
                        .cornerRadius(4)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: theme.spacingXS) {
                    Text(value)
                        .font(theme.headlineFont)
                        .foregroundColor(theme.textPrimary)
                    Text(balance)
                        .font(theme.captionFont)
                        .foregroundColor(theme.textSecondary)
                }
            }
        }
    }
}

// MARK: - Screen 3: Transaction History

struct Screenshot_TransactionHistory: View {
    @EnvironmentObject var themeManager: ThemeManager
    private let data = FakeDataProvider.shared
    
    var body: some View {
        let theme = themeManager.currentTheme
        
        ZStack {
            Color.clear
                .themedContainer(theme: theme, showPattern: true, applyAnimation: false)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Activity")
                        .font(theme.font(style: .title))
                        .foregroundColor(theme.textPrimary)
                    Spacer()
                }
                .padding()
                
                // Filter tabs
                HStack(spacing: theme.spacingS) {
                    filterTab("All", isSelected: true, theme: theme)
                    filterTab("Sent", isSelected: false, theme: theme)
                    filterTab("Received", isSelected: false, theme: theme)
                    filterTab("Swaps", isSelected: false, theme: theme)
                }
                .padding(.horizontal)
                .padding(.bottom, theme.spacingM)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: theme.spacingS) {
                        ForEach(data.transactions) { tx in
                            transactionRow(tx: tx, theme: theme)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    private func filterTab(_ title: String, isSelected: Bool, theme: any ThemeProtocolV2) -> some View {
        Text(title)
            .font(theme.captionFont)
            .fontWeight(isSelected ? .semibold : .regular)
            .foregroundColor(isSelected ? theme.accentColor : theme.textSecondary)
            .padding(.horizontal, theme.spacingM)
            .padding(.vertical, theme.spacingS)
            .background(isSelected ? theme.accentColor.opacity(0.15) : Color.clear)
            .cornerRadius(theme.cornerRadius)
    }
    
    private func transactionRow(tx: FakeDataProvider.FakeTransaction, theme: any ThemeProtocolV2) -> some View {
        KryptoCard {
            HStack {
                // Icon
                ZStack {
                    Circle()
                        .fill(txColor(tx.type, theme: theme).opacity(0.15))
                        .frame(width: theme.avatarSizeMedium, height: theme.avatarSizeMedium)
                    Image(systemName: txIcon(tx.type))
                        .foregroundColor(txColor(tx.type, theme: theme))
                }
                
                VStack(alignment: .leading, spacing: theme.spacingXS) {
                    HStack {
                        Text(tx.type.rawValue)
                            .font(theme.headlineFont)
                            .foregroundColor(theme.textPrimary)
                        
                        if tx.swapToSymbol != nil {
                            Text("→ \(tx.swapToSymbol!)")
                                .font(theme.captionFont)
                                .foregroundColor(theme.textSecondary)
                        }
                    }
                    
                    Text(data.formatTimeAgo(tx.timestamp))
                        .font(theme.captionFont)
                        .foregroundColor(theme.textSecondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: theme.spacingXS) {
                    Text("\(tx.type == .receive ? "+" : "-")\(tx.amount) \(tx.symbol)")
                        .font(theme.headlineFont)
                        .foregroundColor(tx.type == .receive ? theme.successColor : theme.textPrimary)
                    
                    // Status badge
                    statusBadge(tx.status, theme: theme)
                }
            }
        }
    }
    
    private func txIcon(_ type: FakeDataProvider.FakeTransactionType) -> String {
        switch type {
        case .send: return "arrow.up.right"
        case .receive: return "arrow.down.left"
        case .swap: return "arrow.triangle.2.circlepath"
        case .stake: return "lock.fill"
        case .unstake: return "lock.open.fill"
        case .approve: return "checkmark.shield.fill"
        }
    }
    
    private func txColor(_ type: FakeDataProvider.FakeTransactionType, theme: any ThemeProtocolV2) -> Color {
        switch type {
        case .send: return theme.errorColor
        case .receive: return theme.successColor
        case .swap: return theme.accentColor
        case .stake, .unstake: return .purple
        case .approve: return theme.securityWarningColor
        }
    }
    
    private func statusBadge(_ status: FakeDataProvider.FakeTransactionStatus, theme: any ThemeProtocolV2) -> some View {
        let color: Color = switch status {
        case .confirmed: theme.successColor
        case .pending: theme.securityWarningColor
        case .failed: theme.errorColor
        }
        
        return HStack(spacing: 4) {
            if status == .pending {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: color))
                    .scaleEffect(0.5)
            } else {
                Circle()
                    .fill(color)
                    .frame(width: 6, height: 6)
            }
            Text(status.rawValue)
                .font(.caption2)
                .foregroundColor(color)
        }
    }
}

// MARK: - Screen 4: NFT Gallery

struct Screenshot_NFTGallery: View {
    @EnvironmentObject var themeManager: ThemeManager
    private let data = FakeDataProvider.shared
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        let theme = themeManager.currentTheme
        
        ZStack {
            Color.clear
                .themedContainer(theme: theme, showPattern: true, applyAnimation: false)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("NFT Gallery")
                        .font(theme.font(style: .title))
                        .foregroundColor(theme.textPrimary)
                    Spacer()
                    Text("\(data.nfts.count) items")
                        .font(theme.captionFont)
                        .foregroundColor(theme.textSecondary)
                }
                .padding()
                
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(data.nfts) { nft in
                            nftCard(nft: nft, theme: theme)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    private func nftCard(nft: FakeDataProvider.FakeNFT, theme: any ThemeProtocolV2) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // NFT Image (gradient placeholder)
            ZStack {
                LinearGradient(
                    colors: nft.imageGradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Overlay pattern
                GeometryReader { geo in
                    Path { path in
                        let size = geo.size
                        for i in stride(from: 0, to: size.width, by: 20) {
                            path.move(to: CGPoint(x: i, y: 0))
                            path.addLine(to: CGPoint(x: i + size.height, y: size.height))
                        }
                    }
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                }
            }
            .aspectRatio(1, contentMode: .fill)
            .cornerRadius(theme.cornerRadius, corners: [.topLeft, .topRight])
            
            // Info section
            VStack(alignment: .leading, spacing: theme.spacingXS) {
                Text(nft.name)
                    .font(theme.font(style: .subheadline))
                    .fontWeight(.semibold)
                    .foregroundColor(theme.textPrimary)
                    .lineLimit(1)
                
                Text(nft.collection)
                    .font(theme.captionFont)
                    .foregroundColor(theme.textSecondary)
                    .lineLimit(1)
                
                if let floor = nft.floorPrice {
                    HStack {
                        Text("Floor:")
                            .font(.caption2)
                            .foregroundColor(theme.textSecondary)
                        Text(floor)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(theme.accentColor)
                    }
                }
            }
            .padding(theme.spacingS)
            .background(theme.cardBackground)
        }
        .background(theme.cardBackground)
        .cornerRadius(theme.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .stroke(theme.borderColor, lineWidth: 1)
        )
    }
}

// MARK: - Screen 5: Earn Opportunities

struct Screenshot_EarnOpportunities: View {
    @EnvironmentObject var themeManager: ThemeManager
    private let data = FakeDataProvider.shared
    
    var body: some View {
        let theme = themeManager.currentTheme
        
        ZStack {
            Color.clear
                .themedContainer(theme: theme, showPattern: true, applyAnimation: false)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: theme.spacingXS) {
                        Text("Earn")
                            .font(theme.font(style: .title))
                            .foregroundColor(theme.textPrimary)
                        Text("Put your crypto to work")
                            .font(theme.captionFont)
                            .foregroundColor(theme.textSecondary)
                    }
                    Spacer()
                }
                .padding()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: theme.spacingM) {
                        // Featured opportunity
                        featuredOpportunity(data.stakingOpportunities[0], theme: theme)
                        
                        // Other opportunities
                        ForEach(data.stakingOpportunities.dropFirst()) { opp in
                            opportunityCard(opp, theme: theme)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    private func featuredOpportunity(_ opp: FakeDataProvider.FakeStakingOpportunity, theme: any ThemeProtocolV2) -> some View {
        VStack(spacing: 0) {
            // Gradient header
            ZStack {
                LinearGradient(
                    colors: [theme.accentColor, theme.accentColor.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                VStack(spacing: theme.spacingS) {
                    Text("Featured")
                        .font(theme.captionFont)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("\(String(format: "%.1f", opp.apy))% APY")
                        .font(theme.balanceFont)
                        .foregroundColor(.white)
                    
                    Text("\(opp.protocolName) • \(opp.asset)")
                        .font(theme.bodyFont)
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(.vertical, theme.spacingXL)
            }
            .cornerRadius(theme.cornerRadius, corners: [.topLeft, .topRight])
            
            // Details
            VStack(spacing: theme.spacingM) {
                HStack {
                    detailItem("TVL", opp.tvl, theme: theme)
                    Spacer()
                    detailItem("Risk", opp.riskLevel, theme: theme)
                    Spacer()
                    detailItem("Lock", opp.lockupPeriod, theme: theme)
                }
                
                // CTA Button
                HStack {
                    Text("Stake Now")
                        .font(theme.headlineFont)
                        .foregroundColor(.white)
                    Image(systemName: "arrow.right")
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(theme.accentColor)
                .cornerRadius(theme.cornerRadius)
            }
            .padding()
            .background(theme.cardBackground)
        }
        .cornerRadius(theme.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .stroke(theme.accentColor.opacity(0.3), lineWidth: 1)
        )
    }
    
    private func detailItem(_ label: String, _ value: String, theme: any ThemeProtocolV2) -> some View {
        VStack(spacing: theme.spacingXS) {
            Text(label)
                .font(theme.captionFont)
                .foregroundColor(theme.textSecondary)
            Text(value)
                .font(theme.headlineFont)
                .foregroundColor(theme.textPrimary)
        }
    }
    
    private func opportunityCard(_ opp: FakeDataProvider.FakeStakingOpportunity, theme: any ThemeProtocolV2) -> some View {
        KryptoCard {
            HStack {
                // Icon
                ZStack {
                    Circle()
                        .fill(theme.accentColor.opacity(0.15))
                        .frame(width: theme.avatarSizeMedium, height: theme.avatarSizeMedium)
                    Image(systemName: opp.iconName)
                        .foregroundColor(theme.accentColor)
                }
                
                VStack(alignment: .leading, spacing: theme.spacingXS) {
                    Text(opp.protocolName)
                        .font(theme.headlineFont)
                        .foregroundColor(theme.textPrimary)
                    Text("Stake \(opp.asset)")
                        .font(theme.captionFont)
                        .foregroundColor(theme.textSecondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: theme.spacingXS) {
                    Text("\(String(format: "%.1f", opp.apy))%")
                        .font(theme.font(style: .title2))
                        .fontWeight(.bold)
                        .foregroundColor(theme.successColor)
                    Text("APY")
                        .font(theme.captionFont)
                        .foregroundColor(theme.textSecondary)
                }
            }
        }
    }
}

// MARK: - Screen 6: Active Positions

struct Screenshot_ActivePositions: View {
    @EnvironmentObject var themeManager: ThemeManager
    private let data = FakeDataProvider.shared
    
    var body: some View {
        let theme = themeManager.currentTheme
        
        ZStack {
            Color.clear
                .themedContainer(theme: theme, showPattern: true, applyAnimation: false)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: theme.spacingXS) {
                        Text("My Positions")
                            .font(theme.font(style: .title))
                            .foregroundColor(theme.textPrimary)
                        Text("3 active positions")
                            .font(theme.captionFont)
                            .foregroundColor(theme.textSecondary)
                    }
                    Spacer()
                }
                .padding()
                
                // Total staked summary
                KryptoCard {
                    HStack {
                        VStack(alignment: .leading, spacing: theme.spacingXS) {
                            Text("Total Staked")
                                .font(theme.captionFont)
                                .foregroundColor(theme.textSecondary)
                            Text("$3,702.18")
                                .font(theme.font(style: .title2))
                                .fontWeight(.bold)
                                .foregroundColor(theme.textPrimary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: theme.spacingXS) {
                            Text("Total Rewards")
                                .font(theme.captionFont)
                                .foregroundColor(theme.textSecondary)
                            Text("+$33.32")
                                .font(theme.font(style: .title2))
                                .fontWeight(.bold)
                                .foregroundColor(theme.successColor)
                        }
                    }
                }
                .padding(.horizontal)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: theme.spacingM) {
                        ForEach(data.stakingPositions) { position in
                            positionCard(position, theme: theme)
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    private func positionCard(_ position: FakeDataProvider.FakeStakingPosition, theme: any ThemeProtocolV2) -> some View {
        KryptoCard {
            VStack(spacing: theme.spacingM) {
                // Header
                HStack {
                    ZStack {
                        Circle()
                            .fill(theme.accentColor.opacity(0.15))
                            .frame(width: theme.avatarSizeMedium, height: theme.avatarSizeMedium)
                        Image(systemName: position.iconName)
                            .foregroundColor(theme.accentColor)
                    }
                    
                    VStack(alignment: .leading, spacing: theme.spacingXS) {
                        Text(position.protocolName)
                            .font(theme.headlineFont)
                            .foregroundColor(theme.textPrimary)
                        Text(position.asset)
                            .font(theme.captionFont)
                            .foregroundColor(theme.textSecondary)
                    }
                    
                    Spacer()
                    
                    // APY badge
                    Text("\(String(format: "%.1f", position.apy))% APY")
                        .font(theme.captionFont)
                        .fontWeight(.medium)
                        .foregroundColor(theme.successColor)
                        .padding(.horizontal, theme.spacingS)
                        .padding(.vertical, theme.spacingXS)
                        .background(theme.successColor.opacity(0.15))
                        .cornerRadius(theme.cornerRadius / 2)
                }
                
                Divider()
                    .background(theme.borderColor)
                
                // Stats
                HStack {
                    VStack(alignment: .leading, spacing: theme.spacingXS) {
                        Text("Staked")
                            .font(theme.captionFont)
                            .foregroundColor(theme.textSecondary)
                        Text("\(position.stakedAmount) \(position.asset)")
                            .font(theme.headlineFont)
                            .foregroundColor(theme.textPrimary)
                        Text(position.stakedValue)
                            .font(theme.captionFont)
                            .foregroundColor(theme.textSecondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: theme.spacingXS) {
                        Text("Rewards")
                            .font(theme.captionFont)
                            .foregroundColor(theme.textSecondary)
                        Text("+\(position.rewards) \(position.asset)")
                            .font(theme.headlineFont)
                            .foregroundColor(theme.successColor)
                        Text(position.rewardsValue)
                            .font(theme.captionFont)
                            .foregroundColor(theme.successColor)
                    }
                }
                
                // Time staked
                HStack {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                    Text("Staked \(data.formatTimeAgo(position.startDate))")
                        .font(theme.captionFont)
                        .foregroundColor(theme.textSecondary)
                    Spacer()
                }
            }
        }
    }
}

// MARK: - Corner Radius Extension

struct RectCorner: OptionSet {
    let rawValue: Int
    
    static let topLeft = RectCorner(rawValue: 1 << 0)
    static let topRight = RectCorner(rawValue: 1 << 1)
    static let bottomLeft = RectCorner(rawValue: 1 << 2)
    static let bottomRight = RectCorner(rawValue: 1 << 3)
    static let allCorners: RectCorner = [.topLeft, .topRight, .bottomLeft, .bottomRight]
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: RectCorner) -> some View {
        clipShape(RoundedCornerShape(radius: radius, corners: corners))
    }
}

struct RoundedCornerShape: Shape {
    var radius: CGFloat = .infinity
    var corners: RectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let topLeft = corners.contains(.topLeft) ? radius : 0
        let topRight = corners.contains(.topRight) ? radius : 0
        let bottomLeft = corners.contains(.bottomLeft) ? radius : 0
        let bottomRight = corners.contains(.bottomRight) ? radius : 0
        
        path.move(to: CGPoint(x: rect.minX + topLeft, y: rect.minY))
        
        // Top edge
        path.addLine(to: CGPoint(x: rect.maxX - topRight, y: rect.minY))
        
        // Top right corner
        if topRight > 0 {
            path.addArc(
                center: CGPoint(x: rect.maxX - topRight, y: rect.minY + topRight),
                radius: topRight,
                startAngle: Angle(degrees: -90),
                endAngle: Angle(degrees: 0),
                clockwise: false
            )
        }
        
        // Right edge
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - bottomRight))
        
        // Bottom right corner
        if bottomRight > 0 {
            path.addArc(
                center: CGPoint(x: rect.maxX - bottomRight, y: rect.maxY - bottomRight),
                radius: bottomRight,
                startAngle: Angle(degrees: 0),
                endAngle: Angle(degrees: 90),
                clockwise: false
            )
        }
        
        // Bottom edge
        path.addLine(to: CGPoint(x: rect.minX + bottomLeft, y: rect.maxY))
        
        // Bottom left corner
        if bottomLeft > 0 {
            path.addArc(
                center: CGPoint(x: rect.minX + bottomLeft, y: rect.maxY - bottomLeft),
                radius: bottomLeft,
                startAngle: Angle(degrees: 90),
                endAngle: Angle(degrees: 180),
                clockwise: false
            )
        }
        
        // Left edge
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + topLeft))
        
        // Top left corner
        if topLeft > 0 {
            path.addArc(
                center: CGPoint(x: rect.minX + topLeft, y: rect.minY + topLeft),
                radius: topLeft,
                startAngle: Angle(degrees: 180),
                endAngle: Angle(degrees: 270),
                clockwise: false
            )
        }
        
        path.closeSubpath()
        return path
    }
}

