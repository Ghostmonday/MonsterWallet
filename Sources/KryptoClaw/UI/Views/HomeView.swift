import SwiftUI

public struct HomeView: View {
    @EnvironmentObject var walletState: WalletStateManager
    @EnvironmentObject var themeManager: ThemeManager

    @State private var showingSend = false
    @State private var showingReceive = false
    @State private var showingSwap = false
    @State private var showingSettings = false

    @State private var selectedChain: Chain?
    @State private var showCopyFeedback = false
    @State private var showClipboardToast = false

    private static let toastDisplayDuration: TimeInterval = 3.0

    public init() {}

    public var body: some View {
        let theme = themeManager.currentTheme

        ZStack {
            Color.clear
                .themedContainer(theme: theme, showPattern: true, applyAnimation: true)
                .edgesIgnoringSafeArea(.all)

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
                        withAnimation {
                            showClipboardToast = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + Self.toastDisplayDuration) {
                            withAnimation {
                                showClipboardToast = false
                            }
                        }
                    }) {
                        HStack {
                            Text(shorten(address))
                                .font(theme.addressFont)
                                .foregroundColor(theme.textSecondary)
                            
                            Image(systemName: "doc.on.doc")
                                .font(.caption)
                                .foregroundColor(theme.accentColor)
                        }
                        .padding(theme.spacingS)
                        .background(theme.backgroundSecondary.opacity(0.5))
                        .cornerRadius(theme.cornerRadius)
                        .accessibilityLabel("Copy address to clipboard")
                    }
                    .padding(.bottom, theme.spacingM)
                }

                ScrollView {
                    VStack(spacing: theme.spacingXL) {
                        VStack(spacing: theme.spacingM) {
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
                        .padding(theme.spacing2XL)

                        HStack(spacing: theme.spacingXL) {
                            KryptoActionButton(icon: theme.iconSend, label: "Send") {
                                showingSend = true
                            }
                            KryptoActionButton(icon: theme.iconReceive, label: "Receive") {
                                showingReceive = true
                            }
                            if AppConfig.Features.isSwapEnabled {
                                KryptoActionButton(icon: theme.iconSwap, label: "Swap") {
                                    showingSwap = true
                                }
                            }
                        }
                        .padding(.horizontal)

                        VStack(alignment: .leading, spacing: theme.spacingL) {
                            KryptoSectionHeader("Assets")
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
                                // Skeleton loading state
                                ForEach(0..<3, id: \.self) { _ in
                                    KryptoLoadingRow()
                                        .padding(.horizontal)
                                }
                            }
                        }
                    }
                    .padding(.bottom, 100)
                }
            }
            if showClipboardToast {
                VStack {
                    Spacer()
                    ToastView(
                        message: "Address copied securely. Clipboard will be cleared automatically.",
                        iconName: "checkmark.shield.fill",
                        backgroundColor: theme.successColor,
                        textColor: theme.textPrimary
                    )
                    .padding()
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

struct AssetRow: View {
    let chain: Chain
    let balance: Balance
    let theme: ThemeProtocolV2

    var body: some View {
        HStack {
            KryptoAssetIcon(
                imageURL: chain.logoURL,
                fallbackText: chain.nativeCurrency,
                size: .medium
            )

            VStack(alignment: .leading, spacing: theme.spacingXS) {
                Text(chain.displayName)
                    .font(theme.font(style: .headline))
                    .foregroundColor(theme.textPrimary)
                Text(chain.nativeCurrency)
                    .font(theme.font(style: .caption))
                    .foregroundColor(theme.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: theme.spacingXS) {
                Text(balance.amount)
                    .font(theme.font(style: .body))
                    .foregroundColor(theme.textPrimary)

                if let usd = balance.usdValue {
                    Text(usd, format: .currency(code: "USD"))
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
