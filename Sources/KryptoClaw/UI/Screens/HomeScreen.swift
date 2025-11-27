// KRYPTOCLAW HOME SCREEN
// The command center. Balance as hero.
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

import SwiftUI

public struct HomeScreen: View {
    @EnvironmentObject var walletState: WalletStateManager
    @StateObject private var navigator = Navigator()
    
    @State private var contentAppeared = false
    
    public init() {}
    
    public var body: some View {
        ZStack {
            KC.Color.bg.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                header
                    .padding(.horizontal, KC.Space.xl)
                    .padding(.top, KC.Space.md)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: KC.Space.xxxl) {
                        // Balance Hero
                        balanceHero
                            .padding(.top, KC.Space.xxl)
                        
                        // Quick Actions
                        quickActions
                        
                        // Assets Section
                        assetsSection
                        
                        // Activity Preview
                        activitySection
                        
                        // NFT Preview
                        nftSection
                    }
                    .padding(.bottom, 120)
                }
            }
            .opacity(contentAppeared ? 1 : 0)
            .offset(y: contentAppeared ? 0 : 20)
        }
        .toast(item: $navigator.toastMessage)
        .sheet(isPresented: $navigator.showingSend) {
            SendScreen()
                .environmentObject(walletState)
        }
        .sheet(isPresented: $navigator.showingReceive) {
            ReceiveScreen()
                .environmentObject(walletState)
        }
        .sheet(isPresented: $navigator.showingSwap) {
            SwapScreen()
                .environmentObject(walletState)
        }
        .sheet(isPresented: $navigator.showingEarn) {
            EarnScreen()
                .environmentObject(walletState)
        }
        .sheet(isPresented: $navigator.showingBuy) {
            BuyScreen()
                .environmentObject(walletState)
        }
        .sheet(isPresented: $navigator.showingSettings) {
            SettingsScreen()
                .environmentObject(walletState)
        }
        .sheet(isPresented: $navigator.showingHistory) {
            HistoryScreen()
                .environmentObject(walletState)
        }
        .sheet(isPresented: $navigator.showingNFTGallery) {
            NFTGalleryScreen()
                .environmentObject(walletState)
        }
        .sheet(item: $navigator.selectedChain) { chain in
            ChainDetailScreen(chain: chain)
                .environmentObject(walletState)
        }
        .onAppear {
            Task { await walletState.refreshBalance() }
            withAnimation(KC.Anim.smooth.delay(0.1)) {
                contentAppeared = true
            }
        }
        .environmentObject(navigator)
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            // Logo
            HStack(spacing: KC.Space.sm) {
                KCLogoIcon(size: 32)
                
                Text("KryptoClaw")
                    .font(KC.Font.bodyLarge)
                    .foregroundColor(KC.Color.textPrimary)
            }
            
            Spacer()
            
            // Privacy toggle
            Button(action: {
                HapticEngine.shared.play(.selection)
                walletState.togglePrivacyMode()
            }) {
                Image(systemName: walletState.isPrivacyModeEnabled ? "eye.slash" : "eye")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(KC.Color.textTertiary)
                    .frame(width: 40, height: 40)
                    .background(KC.Color.card)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(KC.Color.border, lineWidth: 1))
            }
            
            // Settings
            Button(action: { navigator.showingSettings = true }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(KC.Color.textTertiary)
                    .frame(width: 40, height: 40)
                    .background(KC.Color.card)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(KC.Color.border, lineWidth: 1))
            }
        }
    }
    
    // MARK: - Balance Hero
    
    private var balanceHero: some View {
        VStack(spacing: KC.Space.lg) {
            // Label
            Text("TOTAL BALANCE")
                .font(KC.Font.label)
                .tracking(2)
                .foregroundColor(KC.Color.textMuted)
            
            // Balance
            Group {
                if case let .loaded(balances) = walletState.state {
                    let total = calculateTotal(balances)
                    Text(walletState.isPrivacyModeEnabled ? "••••••" : total)
                        .font(KC.Font.hero)
                        .foregroundColor(KC.Color.textPrimary)
                        .contentTransition(.numericText())
                } else if case .loading = walletState.state {
                    HStack(spacing: KC.Space.md) {
                        ProgressView()
                            .tint(KC.Color.gold)
                        Text("Loading...")
                            .font(KC.Font.title1)
                            .foregroundColor(KC.Color.textTertiary)
                    }
                } else {
                    Text("$0.00")
                        .font(KC.Font.hero)
                        .foregroundColor(KC.Color.textPrimary)
                }
            }
            
            // Change pill
            HStack(spacing: KC.Space.sm) {
                Circle()
                    .fill(KC.Color.positive)
                    .frame(width: 6, height: 6)
                
                Text("+2.4%")
                    .font(KC.Font.caption)
                    .foregroundColor(KC.Color.positive)
                
                Text("24h")
                    .font(KC.Font.caption)
                    .foregroundColor(KC.Color.textMuted)
            }
            .padding(.horizontal, KC.Space.md)
            .padding(.vertical, KC.Space.sm)
            .background(KC.Color.card)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(KC.Color.border, lineWidth: 1))
        }
    }
    
    // MARK: - Quick Actions
    
    private var quickActions: some View {
        HStack(spacing: KC.Space.md) {
            QuickActionButton(icon: "arrow.up.right", label: "Send") {
                navigator.showingSend = true
            }
            
            QuickActionButton(icon: "arrow.down.left", label: "Receive", isHighlighted: true) {
                navigator.showingReceive = true
            }
            
            QuickActionButton(icon: "arrow.left.arrow.right", label: "Swap") {
                navigator.showingSwap = true
            }
            
            QuickActionButton(icon: "chart.line.uptrend.xyaxis", label: "Earn") {
                navigator.showingEarn = true
            }
        }
        .padding(.horizontal, KC.Space.xl)
    }
    
    // MARK: - Assets Section
    
    private var assetsSection: some View {
        VStack(alignment: .leading, spacing: KC.Space.lg) {
            KCSectionHeader("Assets")
                .padding(.horizontal, KC.Space.xl)
            
            VStack(spacing: KC.Space.sm) {
                if case let .loaded(balances) = walletState.state {
                    ForEach(Array(balances.keys.sorted(by: { $0.rawValue < $1.rawValue })), id: \.self) { chain in
                        if let balance = balances[chain] {
                            AssetRow(
                                chain: chain,
                                balance: balance,
                                isPrivate: walletState.isPrivacyModeEnabled
                            )
                            .onTapGesture {
                                HapticEngine.shared.play(.selection)
                                navigator.selectedChain = chain
                            }
                        }
                    }
                } else {
                    ForEach(0..<3, id: \.self) { _ in
                        AssetRowSkeleton()
                    }
                }
            }
            .padding(.horizontal, KC.Space.xl)
        }
    }
    
    // MARK: - Activity Section
    
    private var activitySection: some View {
        VStack(alignment: .leading, spacing: KC.Space.lg) {
            KCSectionHeader("Recent Activity", action: { navigator.showingHistory = true }, actionLabel: "View All")
                .padding(.horizontal, KC.Space.xl)
            
            VStack(spacing: 0) {
                if walletState.history.transactions.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: KC.Space.md) {
                            Image(systemName: "clock")
                                .font(.system(size: 24))
                                .foregroundColor(KC.Color.textMuted)
                            Text("No transactions yet")
                                .font(KC.Font.body)
                                .foregroundColor(KC.Color.textTertiary)
                        }
                        .padding(.vertical, KC.Space.xxl)
                        Spacer()
                    }
                } else {
                    ForEach(walletState.history.transactions.prefix(3), id: \.hash) { tx in
                        ActivityRow(transaction: tx)
                            .environmentObject(walletState)
                        if tx.hash != walletState.history.transactions.prefix(3).last?.hash {
                            Divider()
                                .background(KC.Color.divider)
                        }
                    }
                }
            }
            .padding(KC.Space.lg)
            .background(KC.Color.card)
            .clipShape(RoundedRectangle(cornerRadius: KC.Radius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: KC.Radius.lg)
                    .stroke(KC.Color.border, lineWidth: 1)
            )
            .padding(.horizontal, KC.Space.xl)
            .onTapGesture { navigator.showingHistory = true }
        }
    }
    
    // MARK: - NFT Section
    
    private var nftSection: some View {
        VStack(alignment: .leading, spacing: KC.Space.lg) {
            KCSectionHeader("Collectibles", action: { navigator.showingNFTGallery = true }, actionLabel: "View All")
                .padding(.horizontal, KC.Space.xl)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: KC.Space.md) {
                    if walletState.nfts.isEmpty {
                        ForEach(0..<3, id: \.self) { i in
                            NFTPlaceholder(index: i)
                        }
                    } else {
                        ForEach(Array(walletState.nfts.prefix(5)), id: \.id) { nft in
                            NFTCard(nft: nft)
                        }
                    }
                }
                .padding(.horizontal, KC.Space.xl)
            }
        }
    }
    
    // MARK: - Helpers
    
    private func calculateTotal(_ balances: [Chain: Balance]) -> String {
        var total: Decimal = 0
        var hasUsdValue = false
        
        for (_, balance) in balances {
            if let usd = balance.usdValue {
                total += usd
                hasUsdValue = true
            }
        }
        
        // If we have USD values, show currency format
        if hasUsdValue {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = "USD"
            formatter.maximumFractionDigits = 2
            return formatter.string(from: total as NSNumber) ?? "$0.00"
        }
        
        // Otherwise show ETH balance directly (for local testnet)
        if let ethBalance = balances[.ethereum] {
            return "\(ethBalance.amount) ETH"
        }
        
        return "$0.00"
    }
}

// MARK: - Quick Action Button

private struct QuickActionButton: View {
    let icon: String
    let label: String
    var isHighlighted: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticEngine.shared.play(.selection)
            action()
        }) {
            VStack(spacing: KC.Space.sm) {
                ZStack {
                    Circle()
                        .fill(isHighlighted ? KC.Color.gold : KC.Color.card)
                        .frame(width: 56, height: 56)
                        .overlay(
                            Circle()
                                .stroke(isHighlighted ? .clear : KC.Color.border, lineWidth: 1)
                        )
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(isHighlighted ? KC.Color.bg : KC.Color.textPrimary)
                }
                
                Text(label)
                    .font(KC.Font.caption)
                    .foregroundColor(isHighlighted ? KC.Color.gold : KC.Color.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Asset Row

private struct AssetRow: View {
    let chain: Chain
    let balance: Balance
    let isPrivate: Bool
    
    var body: some View {
        HStack(spacing: KC.Space.lg) {
            // Token icon
            KCTokenIcon(chain.nativeCurrency)
            
            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(chain.displayName)
                    .font(KC.Font.body)
                    .foregroundColor(KC.Color.textPrimary)
                
                Text(chain.nativeCurrency)
                    .font(KC.Font.caption)
                    .foregroundColor(KC.Color.textTertiary)
            }
            
            Spacer()
            
            // Balance
            VStack(alignment: .trailing, spacing: 2) {
                Text(isPrivate ? "••••" : balance.amount)
                    .font(KC.Font.body)
                    .foregroundColor(KC.Color.textPrimary)
                
                if let usd = balance.usdValue {
                    Text(isPrivate ? "••••" : usd.formatted(.currency(code: "USD")))
                        .font(KC.Font.caption)
                        .foregroundColor(KC.Color.textTertiary)
                }
            }
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(KC.Color.textMuted)
        }
        .padding(KC.Space.lg)
        .background(KC.Color.card)
        .clipShape(RoundedRectangle(cornerRadius: KC.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: KC.Radius.md)
                .stroke(KC.Color.border, lineWidth: 1)
        )
    }
}

// MARK: - Asset Row Skeleton

private struct AssetRowSkeleton: View {
    var body: some View {
        HStack(spacing: KC.Space.lg) {
            Circle()
                .fill(KC.Color.cardElevated)
                .frame(width: KC.Size.avatarMD, height: KC.Size.avatarMD)
            
            VStack(alignment: .leading, spacing: 4) {
                KCShimmer(width: 80, height: 14)
                KCShimmer(width: 50, height: 12)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                KCShimmer(width: 60, height: 14)
                KCShimmer(width: 50, height: 12)
            }
        }
        .padding(KC.Space.lg)
        .background(KC.Color.card)
        .clipShape(RoundedRectangle(cornerRadius: KC.Radius.md))
    }
}

// MARK: - Activity Row

private struct ActivityRow: View {
    let transaction: TransactionSummary
    @EnvironmentObject var walletState: WalletStateManager
    
    var isReceive: Bool {
        // Determine direction based on whether we received or sent
        transaction.to.lowercased() == (walletState.currentAddress ?? "").lowercased()
    }
    
    var body: some View {
        HStack(spacing: KC.Space.lg) {
            // Icon
            ZStack {
                Circle()
                    .fill(isReceive ? KC.Color.positive.opacity(0.15) : KC.Color.card)
                    .frame(width: 44, height: 44)
                
                Image(systemName: isReceive ? "arrow.down.left" : "arrow.up.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isReceive ? KC.Color.positive : KC.Color.textSecondary)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(isReceive ? "Received" : "Sent")
                    .font(KC.Font.body)
                    .foregroundColor(KC.Color.textPrimary)
                
                Text(timeAgo(transaction.timestamp))
                    .font(KC.Font.caption)
                    .foregroundColor(KC.Color.textTertiary)
            }
            
            Spacer()
            
            // Amount
            Text("\(isReceive ? "+" : "-")\(transaction.value) \(transaction.chain.nativeCurrency)")
                .font(KC.Font.body)
                .foregroundColor(isReceive ? KC.Color.positive : KC.Color.textPrimary)
        }
        .padding(.vertical, KC.Space.md)
    }
    
    private func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - NFT Card

private struct NFTCard: View {
    let nft: NFTMetadata
    
    var body: some View {
        VStack(alignment: .leading, spacing: KC.Space.sm) {
            // Image
            AsyncImage(url: nft.imageURL) { image in
                image
                    .resizable()
                    .aspectRatio(1, contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(KC.Color.cardElevated)
            }
            .frame(width: 120, height: 120)
            .clipShape(RoundedRectangle(cornerRadius: KC.Radius.md))
            
            // Name
            Text(nft.name)
                .font(KC.Font.caption)
                .foregroundColor(KC.Color.textPrimary)
                .lineLimit(1)
        }
        .frame(width: 120)
    }
}

// MARK: - NFT Placeholder

private struct NFTPlaceholder: View {
    let index: Int
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: KC.Radius.md)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hue: Double(index) * 0.25, saturation: 0.3, brightness: 0.15),
                            Color(hue: Double(index) * 0.25 + 0.1, saturation: 0.2, brightness: 0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 120, height: 120)
            
            Text("#\(index + 1)")
                .font(KC.Font.title3)
                .foregroundColor(.white.opacity(0.15))
        }
    }
}

// MARK: - Chain Extension

extension Chain: Identifiable {
    public var id: String { rawValue }
}

#Preview {
    HomeScreen()
}

