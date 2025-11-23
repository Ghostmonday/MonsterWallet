import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var wsm: WalletStateManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var filter: TxFilter = .all
    
    enum TxFilter: String, CaseIterable {
        case all = "All"
        case sent = "Sent"
        case received = "Received"
    }
    
    var filteredTransactions: [TransactionSummary] {
        guard let currentAddress = wsm.currentAddress else { return [] }
        let all = wsm.history.transactions
        
        switch filter {
        case .all:
            return all
        case .sent:
            return all.filter { $0.from.lowercased() == currentAddress.lowercased() }
        case .received:
            return all.filter { $0.to.lowercased() == currentAddress.lowercased() }
        }
    }
    
    var body: some View {
        ZStack {
            themeManager.currentTheme.backgroundMain.ignoresSafeArea()
            
            VStack(spacing: 0) {
                KryptoHeader(
                    title: "History",
                    onBack: { presentationMode.wrappedValue.dismiss() }
                )
                
                // Filter Tabs
                KryptoTab(
                    tabs: TxFilter.allCases.map { $0.rawValue },
                    selectedIndex: Binding(
                        get: {
                            TxFilter.allCases.firstIndex(of: filter) ?? 0
                        },
                        set: { index in
                            filter = TxFilter.allCases[index]
                            print("[History] Filter Changed: \(filter.rawValue)")
                        }
                    )
                )
                .padding(.vertical)
                
                if filteredTransactions.isEmpty {
                    Spacer()
                    Text("No transactions found")
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                    Spacer()
                } else {
                    List {
                        ForEach(filteredTransactions, id: \.hash) { tx in
                            TransactionRow(tx: tx, currentAddress: wsm.currentAddress ?? "")
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .padding(.vertical, 4)
                                .onTapGesture {
                                    openExplorer(hash: tx.hash)
                                }
                        }
                    }
                    .listStyle(.plain)
                    .refreshable {
                        print("[History] Refresh Triggered")
                        await wsm.refreshBalance()
                    }
                }
            }
        }
        .onAppear {
            print("[History] ViewDidAppear")
        }
    }
    
    func openExplorer(hash: String) {
        // Compliance: Must open in external Safari, not embedded WebView
        if let url = URL(string: "https://etherscan.io/tx/\(hash)") {
            print("[History] Explorer Link Tapped")
            UIApplication.shared.open(url)
        }
    }
}

struct TransactionRow: View {
    let tx: TransactionSummary
    let currentAddress: String
    @EnvironmentObject var wsm: WalletStateManager
    @EnvironmentObject var themeManager: ThemeManager
    
    var isSent: Bool {
        tx.from.lowercased() == currentAddress.lowercased()
    }
    
    var body: some View {
        KryptoListRow(
            title: isSent ? "Sent ETH" : "Received ETH",
            subtitle: formatDate(tx.timestamp),
            value: wsm.isPrivacyModeEnabled ? "**** ETH" : "\(tx.value) ETH",
            icon: isSent ? "arrow.up.right.circle.fill" : "arrow.down.left.circle.fill",
            isSystemIcon: true
        )
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

