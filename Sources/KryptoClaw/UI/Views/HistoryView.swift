import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var wsm: WalletStateManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.openURL) var openURL

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
        let theme = themeManager.currentTheme
        
        ZStack {
            Color.clear
                .themedContainer(theme: theme, showPattern: true, applyAnimation: true)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                KryptoHeader(
                    title: "History",
                    onBack: { presentationMode.wrappedValue.dismiss() }
                )

                // Filter Tabs
                KryptoTab(
                    tabs: TxFilter.allCases.map(\.rawValue),
                    selectedIndex: Binding(
                        get: {
                            TxFilter.allCases.firstIndex(of: filter) ?? 0
                        },
                        set: { index in
                            filter = TxFilter.allCases[index]
                            KryptoLogger.shared.log(level: .info, category: .stateTransition, message: "Filter Changed", metadata: ["filter": filter.rawValue, "view": "History"])
                        }
                    )
                )
                .padding(.vertical)

                if filteredTransactions.isEmpty {
                    KryptoEmptyState(
                        icon: "clock.arrow.circlepath",
                        title: "No Transactions",
                        message: "Your transaction history will appear here"
                    )
                } else {
                    List {
                        ForEach(filteredTransactions, id: \.hash) { tx in
                            TransactionRow(tx: tx, currentAddress: wsm.currentAddress ?? "")
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .padding(.vertical, theme.spacingXS)
                                .onTapGesture {
                                    openExplorer(hash: tx.hash)
                                }
                        }
                    }
                    .listStyle(.plain)
                    .refreshable {
                        KryptoLogger.shared.log(level: .info, category: .stateTransition, message: "Refresh Triggered", metadata: ["view": "History"])
                        await wsm.refreshBalance()
                    }
                }
            }
        }
        .onAppear {
            KryptoLogger.shared.log(level: .info, category: .lifecycle, message: "ViewDidAppear", metadata: ["view": "History"])
        }
    }

    func openExplorer(hash: String) {
        // Note: Must open in external Safari for App Store compliance
        if let url = URL(string: "https://etherscan.io/tx/\(hash)") {
            KryptoLogger.shared.log(level: .info, category: .boundary, message: "Explorer Link Tapped", metadata: ["hash": hash, "view": "History"])
            openURL(url)
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
