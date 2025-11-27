// KRYPTOCLAW HISTORY SCREEN
// Transaction ledger. Complete record.
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

import SwiftUI

public struct HistoryScreen: View {
    @EnvironmentObject var walletState: WalletStateManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTransaction: TransactionSummary?
    @State private var filterChain: Chain?
    @State private var showFilters = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                KC.Color.bg.ignoresSafeArea()
                
                if walletState.history.transactions.isEmpty {
                    emptyState
                } else {
                    transactionList
                }
            }
            .navigationTitle("Activity")
            .kcNavigationLarge()
            .toolbar {
                ToolbarItem(placement: .kcLeading) {
                    Button(action: { showFilters = true }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(filterChain != nil ? KC.Color.gold : KC.Color.textSecondary)
                    }
                }
                ToolbarItem(placement: .kcTrailing) {
                    KCCloseButton { dismiss() }
                }
            }
            .sheet(item: $selectedTransaction) { tx in
                TransactionDetailSheet(transaction: tx)
                .environmentObject(walletState)
            }
            .sheet(isPresented: $showFilters) {
                FilterSheet(selectedChain: $filterChain)
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        KCEmptyState(
            icon: "clock.arrow.circlepath",
            title: "No Transactions Yet",
            message: "Your transaction history will appear here once you start sending or receiving crypto.",
            actionTitle: "Receive Crypto",
            action: { dismiss() }
        )
    }
    
    // MARK: - Transaction List
    
    private var transactionList: some View {
        ScrollView {
            LazyVStack(spacing: KC.Space.sm) {
                ForEach(groupedTransactions.keys.sorted(by: >), id: \.self) { date in
                    Section {
                        ForEach(groupedTransactions[date] ?? [], id: \.hash) { tx in
                            TransactionRow(transaction: tx, currentAddress: walletState.currentAddress)
                                .onTapGesture {
                                    HapticEngine.shared.play(.selection)
                                    selectedTransaction = tx
                                }
                        }
                    } header: {
                        HStack {
                            Text(formatSectionDate(date))
                                .font(KC.Font.label)
                                .tracking(1)
                                .foregroundColor(KC.Color.textMuted)
                            Spacer()
                        }
                        .padding(.top, KC.Space.lg)
                        .padding(.bottom, KC.Space.sm)
                    }
                }
            }
            .kcPadding()
            .padding(.bottom, KC.Space.xxxl)
        }
    }
    
    // MARK: - Helpers
    
    private var filteredTransactions: [TransactionSummary] {
        if let chain = filterChain {
            return walletState.history.transactions.filter { $0.chain == chain }
        }
        return walletState.history.transactions
    }
    
    private var groupedTransactions: [Date: [TransactionSummary]] {
        Dictionary(grouping: filteredTransactions) { tx in
            Calendar.current.startOfDay(for: tx.timestamp)
        }
    }
    
    private func formatSectionDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "TODAY"
        } else if calendar.isDateInYesterday(date) {
            return "YESTERDAY"
        } else {
            return DateFormatter.sectionHeader.string(from: date).uppercased()
        }
    }
}

// MARK: - Transaction Row

private struct TransactionRow: View {
    let transaction: TransactionSummary
    let currentAddress: String?
    
    var isReceive: Bool {
        transaction.to.lowercased() == (currentAddress ?? "").lowercased()
    }
    
    var body: some View {
        HStack(spacing: KC.Space.lg) {
            // Icon
            ZStack {
                Circle()
                    .fill(isReceive ? KC.Color.positive.opacity(0.15) : KC.Color.card)
                    .frame(width: 48, height: 48)
                
                Image(systemName: isReceive ? "arrow.down.left" : "arrow.up.right")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(isReceive ? KC.Color.positive : KC.Color.textSecondary)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(isReceive ? "Received" : "Sent")
                    .font(KC.Font.body)
                    .foregroundColor(KC.Color.textPrimary)
                
                HStack(spacing: KC.Space.sm) {
                    Text(transaction.chain.nativeCurrency)
                        .font(KC.Font.caption)
                        .foregroundColor(KC.Color.textTertiary)
                    
                    Circle()
                        .fill(KC.Color.textMuted)
                        .frame(width: 3, height: 3)
                    
                    Text(formatTime(transaction.timestamp))
                        .font(KC.Font.caption)
                        .foregroundColor(KC.Color.textTertiary)
                }
            }
            
            Spacer()
            
            // Amount
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(isReceive ? "+" : "-")\(transaction.value)")
                    .font(KC.Font.body)
                    .foregroundColor(isReceive ? KC.Color.positive : KC.Color.textPrimary)
                
                Text(transaction.chain.nativeCurrency)
                    .font(KC.Font.caption)
                    .foregroundColor(KC.Color.textTertiary)
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
    
    private func formatTime(_ date: Date) -> String {
        return DateFormatter.shortTime.string(from: date)
    }
}

// MARK: - Transaction Detail Sheet

struct TransactionDetailSheet: View {
    let transaction: TransactionSummary
    @EnvironmentObject var walletState: WalletStateManager
    @Environment(\.dismiss) private var dismiss
    
    var isReceive: Bool {
        transaction.to.lowercased() == (walletState.currentAddress ?? "").lowercased()
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                KC.Color.bg.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: KC.Space.xxl) {
                        // Header
                        VStack(spacing: KC.Space.lg) {
                            ZStack {
                                Circle()
                                    .fill(isReceive ? KC.Color.positive.opacity(0.15) : KC.Color.card)
                                    .frame(width: 72, height: 72)
                                
                                Image(systemName: isReceive ? "arrow.down.left" : "arrow.up.right")
                                    .font(.system(size: 28, weight: .semibold))
                                    .foregroundColor(isReceive ? KC.Color.positive : KC.Color.textSecondary)
                            }
                            
                            VStack(spacing: KC.Space.xs) {
                                Text(isReceive ? "Received" : "Sent")
                                    .font(KC.Font.bodyLarge)
                                    .foregroundColor(KC.Color.textTertiary)
                                
                                Text("\(isReceive ? "+" : "-")\(transaction.value) \(transaction.chain.nativeCurrency)")
                                    .font(KC.Font.title1)
                                    .foregroundColor(isReceive ? KC.Color.positive : KC.Color.textPrimary)
                            }
                        }
                        .padding(.top, KC.Space.xl)
                        
                        // Details
                        VStack(spacing: 0) {
                            DetailRow(label: "Status", value: "Confirmed", valueColor: KC.Color.positive)
                            Divider().background(KC.Color.divider)
                            DetailRow(label: "Date", value: formatDate(transaction.timestamp))
                            Divider().background(KC.Color.divider)
                            DetailRow(label: "Network", value: transaction.chain.displayName)
                            Divider().background(KC.Color.divider)
                            DetailRow(label: isReceive ? "From" : "To", value: truncateAddress(transaction.to), isMono: true)
                            Divider().background(KC.Color.divider)
                            DetailRow(label: "Transaction Hash", value: truncateAddress(transaction.hash), isMono: true)
                        }
                        .background(KC.Color.card)
                        .clipShape(RoundedRectangle(cornerRadius: KC.Radius.lg))
                        .overlay(
                            RoundedRectangle(cornerRadius: KC.Radius.lg)
                                .stroke(KC.Color.border, lineWidth: 1)
                        )
                        .kcPadding()
                        
                        // View on explorer
                        KCButton("View on Explorer", icon: "arrow.up.right.square", style: .secondary) {
                            // Open block explorer
                        }
                        .kcPadding()
                    }
                }
            }
            .navigationTitle("Transaction")
            .kcNavigationInline()
            .toolbar {
                ToolbarItem(placement: .kcTrailing) {
                    KCCloseButton { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
    }
    
    private func formatDate(_ date: Date) -> String {
        return DateFormatter.mediumDateTime.string(from: date)
    }
    
    private func truncateAddress(_ address: String) -> String {
        guard address.count > 16 else { return address }
        return "\(address.prefix(8))...\(address.suffix(6))"
    }
}

private struct DetailRow: View {
    let label: String
    let value: String
    var isMono: Bool = false
    var valueColor: Color = KC.Color.textPrimary
    
    var body: some View {
        HStack {
            Text(label)
                .font(KC.Font.body)
                .foregroundColor(KC.Color.textTertiary)
            
            Spacer()
            
            Text(value)
                .font(isMono ? KC.Font.mono : KC.Font.body)
                .foregroundColor(valueColor)
        }
        .padding(KC.Space.lg)
    }
}

// MARK: - Filter Sheet

struct FilterSheet: View {
    @Binding var selectedChain: Chain?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                KC.Color.bg.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: KC.Space.sm) {
                        // All chains
                        Button(action: {
                            selectedChain = nil
                            dismiss()
                        }) {
                            FilterRow(
                                icon: "globe",
                                label: "All Networks",
                                isSelected: selectedChain == nil
                            )
                        }
                        
                        ForEach(Chain.allCases, id: \.self) { chain in
                            Button(action: {
                                selectedChain = chain
                                dismiss()
                            }) {
                                FilterRow(
                                    tokenSymbol: chain.nativeCurrency,
                                    label: chain.displayName,
                                    isSelected: selectedChain == chain
                                )
                            }
                        }
                    }
                    .kcPadding()
                    .padding(.top, KC.Space.lg)
                }
            }
            .navigationTitle("Filter by Network")
            .kcNavigationInline()
            .toolbar {
                ToolbarItem(placement: .kcTrailing) {
                    KCCloseButton { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

private struct FilterRow: View {
    var icon: String?
    var tokenSymbol: String?
    let label: String
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: KC.Space.lg) {
            if let icon = icon {
                ZStack {
                    Circle()
                        .fill(KC.Color.gold.opacity(0.15))
                        .frame(width: KC.Size.avatarMD, height: KC.Size.avatarMD)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(KC.Color.gold)
                }
            } else if let symbol = tokenSymbol {
                KCTokenIcon(symbol)
            }
            
            Text(label)
                .font(KC.Font.body)
                .foregroundColor(KC.Color.textPrimary)
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(KC.Color.gold)
            }
        }
        .padding(KC.Space.lg)
        .background(isSelected ? KC.Color.goldGhost : KC.Color.card)
        .clipShape(RoundedRectangle(cornerRadius: KC.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: KC.Radius.md)
                .stroke(isSelected ? KC.Color.gold.opacity(0.3) : KC.Color.border, lineWidth: 1)
        )
    }
}

// MARK: - Extensions

extension TransactionSummary: Identifiable {
    public var id: String { hash }
}

#Preview {
    HistoryScreen()
}

