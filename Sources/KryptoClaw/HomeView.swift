import SwiftUI

public struct HomeView: View {
    @EnvironmentObject var walletState: WalletStateManager
    @EnvironmentObject var themeManager: ThemeManager

    @State private var showingSend = false
    @State private var showingReceive = false
    @State private var showingSwap = false
    @State private var showingSettings = false

    @State private var selectedChain: Chain?

    public init() {}

    public var body: some View {
        let theme = themeManager.currentTheme

        ZStack {
            theme.backgroundMain.edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                HStack {
                    Image(systemName: theme.iconShield)
                        .foregroundColor(theme.accentColor)
                        .font(.title2)
                    Text("KryptoClaw")
                        .font(theme.font(style: .headline))
                        .foregroundColor(theme.textPrimary)
                    Spacer()
                    Button(action: {
                        walletState.togglePrivacyMode()
                    }) {
                        Image(systemName: walletState.isPrivacyModeEnabled ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(theme.textSecondary)
                    }

                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: theme.iconSettings)
                            .foregroundColor(theme.textSecondary)
                    }
                }
                .padding()

                if let address = walletState.currentAddress {
                    Button(action: {
                        walletState.copyCurrentAddress()
                    }) {
                        HStack {
                            Text(shorten(address))
                                .font(theme.addressFont)
                                .foregroundColor(theme.textSecondary)
                            Image(systemName: "doc.on.doc")
                                .font(.caption)
                                .foregroundColor(theme.accentColor)
                        }
                        .padding(8)
                        .background(theme.backgroundSecondary.opacity(0.5))
                        .cornerRadius(8)
                    }
                    .padding(.bottom, 10)
                }

                ScrollView {
                    VStack(spacing: 20) {
                        VStack(spacing: 10) {
                            Text("Total Portfolio Value")
                                .font(theme.font(style: .subheadline))
                                .foregroundColor(theme.textSecondary)

                            if case let .loaded(balances) = walletState.state {
                                let totalUSD = calculateTotalUSD(balances: balances)
                                Text(walletState.isPrivacyModeEnabled ? "****" : totalUSD)
                                    .font(theme.balanceFont)
                                    .foregroundColor(theme.textPrimary)
                            } else if case .loading = walletState.state {
                                ProgressView()
                            } else {
                                Text("$0.00")
                                    .font(theme.balanceFont)
                                    .foregroundColor(theme.textPrimary)
                            }
                        }
                        .padding(30)

                        HStack(spacing: 20) {
                            ActionButton(icon: theme.iconSend, label: "Send", theme: theme) {
                                showingSend = true
                            }
                            ActionButton(icon: theme.iconReceive, label: "Receive", theme: theme) {
                                showingReceive = true
                            }
                            if AppConfig.Features.isSwapEnabled {
                                ActionButton(icon: theme.iconSwap, label: "Swap", theme: theme) {
                                    showingSwap = true
                                }
                            }
                        }
                        .padding(.horizontal)

                        VStack(alignment: .leading, spacing: 15) {
                            Text("Assets")
                                .font(theme.font(style: .title3))
                                .fontWeight(.bold)
                                .foregroundColor(theme.textPrimary)
                                .padding(.horizontal)

                            if case let .loaded(balances) = walletState.state {
                                ForEach(Chain.allCases, id: \.self) { chain in
                                    if let balance = balances[chain] {
                                        AssetRow(chain: chain, balance: balance, theme: theme)
                                            .onTapGesture {
                                                selectedChain = chain
                                            }
                                    }
                                }
                            } else {
                                // TODO: Implement shimmer/skeleton loading animation
                                Text("Loading assets...")
                                    .foregroundColor(theme.textSecondary)
                                    .padding()
                            }
                        }
                    }
                    .padding(.bottom, 100)
                }
            }
        }
        .sheet(isPresented: $showingSend) {
            SendView()
        }
        .sheet(isPresented: $showingReceive) {
            ReceiveView()
        }
        .sheet(isPresented: $showingSwap) {
            SwapView()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(item: $selectedChain) { chain in
            ChainDetailView(chain: chain)
        }
        .onAppear {
            Task {
                await walletState.refreshBalance()
            }
        }
    }

    private func calculateTotalUSD(balances: [Chain: Balance]) -> String {
        var total: Decimal = 0.0
        for (_, balance) in balances {
            if let usd = balance.usdValue {
                total += usd
            }
        }

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        return formatter.string(from: total as NSNumber) ?? "$0.00"
    }

    private func shorten(_ addr: String) -> String {
        guard addr.count > 10 else { return addr }
        return "\(addr.prefix(6))...\(addr.suffix(4))"
    }
}

struct ActionButton: View {
    let icon: String
    let label: String
    let theme: ThemeProtocolV2
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack {
                ZStack {
                    Circle()
                        .fill(theme.accentColor.opacity(0.2))
                        .frame(width: 60, height: 60)

                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(theme.accentColor)
                }
                Text(label)
                    .font(theme.font(style: .caption))
                    .foregroundColor(theme.textPrimary)
            }
        }
    }
}

struct AssetRow: View {
    let chain: Chain
    let balance: Balance
    let theme: ThemeProtocolV2

    var body: some View {
        HStack {
            // TODO: Replace placeholder with actual chain logo image
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(chain.nativeCurrency.prefix(1))
                        .fontWeight(.bold)
                        .foregroundColor(theme.textPrimary)
                )

            VStack(alignment: .leading) {
                Text(chain.displayName)
                    .font(theme.font(style: .headline))
                    .foregroundColor(theme.textPrimary)
                Text(chain.nativeCurrency)
                    .font(theme.font(style: .caption))
                    .foregroundColor(theme.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing) {
                Text(balance.amount)
                    .font(theme.font(style: .body))
                    .foregroundColor(theme.textPrimary)

                if let usd = balance.usdValue {
                    Text("$\(usd)")
                        .font(theme.font(style: .caption))
                        .foregroundColor(theme.textSecondary)
                }
            }
        }
        .padding()
        .background(theme.cardBackground)
        .cornerRadius(theme.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .stroke(theme.borderColor, lineWidth: 1)
        )
        .padding(.horizontal)
    }
}

extension Chain: Identifiable {
    public var id: String { rawValue }
}
