// KRYPTOCLAW CHAIN DETAIL SCREEN
// Single asset deep dive.
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

import SwiftUI

public struct ChainDetailScreen: View {
    let chain: Chain
    
    @EnvironmentObject var walletState: WalletStateManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingSend = false
    @State private var showingReceive = false
    
    public init(chain: Chain) {
        self.chain = chain
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                KC.Color.bg.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: KC.Space.xxl) {
                        // Hero section
                        heroSection
                        
                        // Actions
                        actionsSection
                        
                        // Stats
                        statsSection
                        
                        // Recent activity
                        activitySection
                    }
                    .padding(.top, KC.Space.lg)
                    .padding(.bottom, KC.Space.xxxl)
                }
            }
            .kcNavigationInline()
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: KC.Space.sm) {
                        KCTokenIcon(chain.nativeCurrency, size: 28)
                        Text(chain.displayName)
                            .font(KC.Font.bodyLarge)
                            .foregroundColor(KC.Color.textPrimary)
                    }
                }
                ToolbarItem(placement: .kcTrailing) {
                    KCCloseButton { dismiss() }
                }
            }
            .sheet(isPresented: $showingSend) {
                SendScreen()
                    .environmentObject(walletState)
            }
            .sheet(isPresented: $showingReceive) {
                ReceiveScreen()
                    .environmentObject(walletState)
            }
        }
    }
    
    // MARK: - Hero Section
    
    private var heroSection: some View {
        VStack(spacing: KC.Space.lg) {
            // Token icon
            KCTokenIcon(chain.nativeCurrency, size: 72)
            
            // Balance
            if case let .loaded(balances) = walletState.state,
               let balance = balances[chain] {
                VStack(spacing: KC.Space.sm) {
                    Text(walletState.isPrivacyModeEnabled ? "••••" : balance.amount)
                        .font(KC.Font.display)
                        .foregroundColor(KC.Color.textPrimary)
                    
                    Text(chain.nativeCurrency)
                        .font(KC.Font.body)
                        .foregroundColor(KC.Color.textTertiary)
                    
                    if let usd = balance.usdValue {
                        Text(walletState.isPrivacyModeEnabled ? "••••" : usd.formatted(.currency(code: "USD")))
                            .font(KC.Font.title3)
                            .foregroundColor(KC.Color.textSecondary)
                    }
                }
            } else {
                VStack(spacing: KC.Space.sm) {
                    Text("0.00")
                        .font(KC.Font.display)
                        .foregroundColor(KC.Color.textPrimary)
                    
                    Text(chain.nativeCurrency)
                        .font(KC.Font.body)
                        .foregroundColor(KC.Color.textTertiary)
                }
            }
            
            // 24h change
            HStack(spacing: KC.Space.sm) {
                Circle()
                    .fill(KC.Color.positive)
                    .frame(width: 6, height: 6)
                
                Text("+3.2%")
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
        }
        .kcPadding()
    }
    
    // MARK: - Actions Section
    
    private var actionsSection: some View {
        HStack(spacing: KC.Space.md) {
            ActionButton(icon: "arrow.up.right", label: "Send") {
                showingSend = true
            }
            
            ActionButton(icon: "arrow.down.left", label: "Receive", isHighlighted: true) {
                showingReceive = true
            }
        }
        .kcPadding()
    }
    
    // MARK: - Stats Section
    
    private var statsSection: some View {
        VStack(spacing: 0) {
            StatRow(label: "Network", value: chain.displayName)
            Divider().background(KC.Color.divider)
            StatRow(label: "Symbol", value: chain.nativeCurrency)
            Divider().background(KC.Color.divider)
            StatRow(label: "Price", value: "$2,543.21")
            Divider().background(KC.Color.divider)
            StatRow(label: "Market Cap", value: "$305B")
        }
        .background(KC.Color.card)
        .clipShape(RoundedRectangle(cornerRadius: KC.Radius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: KC.Radius.lg)
                .stroke(KC.Color.border, lineWidth: 1)
        )
        .kcPadding()
    }
    
    // MARK: - Activity Section
    
    private var activitySection: some View {
        VStack(alignment: .leading, spacing: KC.Space.lg) {
            KCSectionHeader("Recent Activity")
                .kcPadding()
            
            let chainTransactions = walletState.history.transactions.filter { $0.chain == chain }
            
            if chainTransactions.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: KC.Space.md) {
                        Image(systemName: "clock")
                            .font(.system(size: 24))
                            .foregroundColor(KC.Color.textMuted)
                        Text("No transactions")
                            .font(KC.Font.body)
                            .foregroundColor(KC.Color.textTertiary)
                    }
                    .padding(.vertical, KC.Space.xl)
                    Spacer()
                }
                .background(KC.Color.card)
                .clipShape(RoundedRectangle(cornerRadius: KC.Radius.lg))
                .overlay(
                    RoundedRectangle(cornerRadius: KC.Radius.lg)
                        .stroke(KC.Color.border, lineWidth: 1)
                )
                .kcPadding()
            } else {
                VStack(spacing: 0) {
                    ForEach(chainTransactions.prefix(5), id: \.hash) { tx in
                        ChainActivityRow(transaction: tx, currentAddress: walletState.currentAddress)
                        if tx.hash != chainTransactions.prefix(5).last?.hash {
                            Divider().background(KC.Color.divider)
                        }
                    }
                }
                .background(KC.Color.card)
                .clipShape(RoundedRectangle(cornerRadius: KC.Radius.lg))
                .overlay(
                    RoundedRectangle(cornerRadius: KC.Radius.lg)
                        .stroke(KC.Color.border, lineWidth: 1)
                )
                .kcPadding()
            }
        }
    }
}

// MARK: - Action Button

private struct ActionButton: View {
    let icon: String
    let label: String
    var isHighlighted: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticEngine.shared.play(.selection)
            action()
        }) {
            HStack(spacing: KC.Space.sm) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                Text(label)
                    .font(KC.Font.bodyLarge)
            }
            .foregroundColor(isHighlighted ? KC.Color.bg : KC.Color.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: KC.Size.buttonHeight)
            .background(isHighlighted ? KC.Color.gold : KC.Color.card)
            .clipShape(RoundedRectangle(cornerRadius: KC.Radius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: KC.Radius.lg)
                    .stroke(isHighlighted ? .clear : KC.Color.border, lineWidth: 1)
            )
        }
    }
}

// MARK: - Stat Row

private struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(KC.Font.body)
                .foregroundColor(KC.Color.textTertiary)
            Spacer()
            Text(value)
                .font(KC.Font.body)
                .foregroundColor(KC.Color.textPrimary)
        }
        .padding(KC.Space.lg)
    }
}

// MARK: - Chain Activity Row

private struct ChainActivityRow: View {
    let transaction: TransactionSummary
    let currentAddress: String?
    
    var isReceive: Bool {
        transaction.to.lowercased() == (currentAddress ?? "").lowercased()
    }
    
    var body: some View {
        HStack(spacing: KC.Space.lg) {
            ZStack {
                Circle()
                    .fill(isReceive ? KC.Color.positive.opacity(0.15) : KC.Color.card)
                    .frame(width: 40, height: 40)
                
                Image(systemName: isReceive ? "arrow.down.left" : "arrow.up.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isReceive ? KC.Color.positive : KC.Color.textSecondary)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(isReceive ? "Received" : "Sent")
                    .font(KC.Font.body)
                    .foregroundColor(KC.Color.textPrimary)
                
                Text(timeAgo(transaction.timestamp))
                    .font(KC.Font.caption)
                    .foregroundColor(KC.Color.textTertiary)
            }
            
            Spacer()
            
            Text("\(isReceive ? "+" : "-")\(transaction.value)")
                .font(KC.Font.body)
                .foregroundColor(isReceive ? KC.Color.positive : KC.Color.textPrimary)
        }
        .padding(KC.Space.lg)
    }
    
    private func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    ChainDetailScreen(chain: .ethereum)
}

