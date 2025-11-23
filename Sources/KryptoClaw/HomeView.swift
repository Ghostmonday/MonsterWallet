import SwiftUI

public struct HomeView: View {
    @EnvironmentObject var walletState: WalletStateManager
    @EnvironmentObject var themeManager: ThemeManager
    
    // Navigation State
    @State private var showingSend = false
    @State private var showingReceive = false
    @State private var showingSwap = false
    @State private var showingSettings = false
    
    // For V2: Track selected chain/asset for detail view
    // TODO: [JULES-REVIEW] UX Gap: `selectedChain` is set on tap but does not trigger navigation.
    // Users expect to see transaction history or details for the specific chain when tapping an asset.
    @State private var selectedChain: Chain?

    public init() {}

    public var body: some View {
        let theme = themeManager.currentTheme

        ZStack {
            // Background
            theme.backgroundMain.edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                // Header
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

                // Clipboard Guard Copy Trigger (Hidden or integrated)
                // For now, we integrate it into the header for the current address if available
                if let address = walletState.currentAddress {
                    Button(action: {
                        // Trigger Security Feature
                        // Note: In a real app, we'd get this via DI or Environment.
                        // Since ClipboardGuard is internal to WSM or App, we might need to expose a method on WSM or access it via a singleton if we didn't inject it into the View.
                        // However, WSM doesn't expose 'copyAddress' helper.
                        // Ideally, WSM should handle this "safe copy".
                        // Let's assume we add a `copyAddressToClipboard` to WSM or just use UIPasteboard here for V1.
                        // But to use the *Guard*, we need access to it.
                        // Let's add `copyCurrentAddress()` to WalletStateManager to handle this securely.
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

                        // Total Balance Card
                        VStack(spacing: 10) {
                            Text("Total Portfolio Value")
                                .font(theme.font(style: .subheadline))
                                .foregroundColor(theme.textSecondary)
                            
                            if case .loaded(let balances) = walletState.state {
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

                        // Action Buttons
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
                        
                        // Multi-Chain Assets List
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Assets")
                                .font(theme.font(style: .title3))
                                .fontWeight(.bold)
                                .foregroundColor(theme.textPrimary)
                                .padding(.horizontal)

                            if case .loaded(let balances) = walletState.state {
                                ForEach(Chain.allCases, id: \.self) { chain in
                                    if let balance = balances[chain] {
                                        AssetRow(chain: chain, balance: balance, theme: theme)
                                            .onTapGesture {
                                                selectedChain = chain
                                            }
                                    }
                                }
                            } else {
                                // Shimmer or Skeleton
                                Text("Loading assets...")
                                    .foregroundColor(theme.textSecondary)
                                    .padding()
                            }
                        }
                    }
                    .padding(.bottom, 100) // Space for TabBar
                }
            }
        }
        .sheet(isPresented: $showingSend) {
            SendView() // Assuming SendView exists and can handle context via environment or init
        }
        .sheet(isPresented: $showingReceive) {
            // Placeholder for Receive View
            // TODO: [JULES-REVIEW] Missing UI: Implement `ReceiveView` with QR Code generation for `walletState.currentAddress`.
            Text("Receive View")
        }
        .sheet(isPresented: $showingSwap) {
            // TODO: [JULES-REVIEW] CRITICAL UI Gap: `SwapView` is referenced but file does not exist.
            // Feature `isSwapEnabled` is true in AppConfig, so this View must be implemented or the feature flag disabled.
            SwapView()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
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
            // Icon
            // TODO: [JULES-REVIEW] Asset Needed: Replace text overlay with proper Chain/Token Logo assets.
            // Example: `Image(chain.logoName)`
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
