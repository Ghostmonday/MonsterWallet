import SwiftUI

struct ChainDetailView: View {
    let chain: Chain
    @EnvironmentObject var walletState: WalletStateManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var showingSend = false
    @State private var showingReceive = false

    var body: some View {
        let theme = themeManager.currentTheme

        ZStack {
            Color.clear
                .themedContainer(theme: theme, showPattern: true, applyAnimation: true)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                KryptoHeader(
                    title: chain.displayName,
                    onBack: { presentationMode.wrappedValue.dismiss() }
                )

                ScrollView {
                    VStack(spacing: theme.spacingXL) {
                        ZStack {
                            Circle()
                                .fill(theme.accentColor.opacity(0.1))
                                .frame(width: 100, height: 100)
                                .blur(radius: 10)

                            Circle()
                                .stroke(theme.accentColor, lineWidth: 2)
                                .background(Circle().fill(theme.backgroundSecondary))
                                .frame(width: 100, height: 100)

                            Text(chain.nativeCurrency.prefix(1))
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(theme.accentColor)
                        }
                        .padding(.top, theme.spacing2XL + theme.spacingS)

                        if case .loaded(let balances) = walletState.state, let balance = balances[chain] {
                            VStack(spacing: theme.spacingS) {
                                Text(balance.amount + " " + balance.currency)
                                    .font(theme.balanceFont)
                                    .foregroundColor(theme.textPrimary)
                                    .multilineTextAlignment(.center)

                                if let usd = balance.usdValue {
                                    Text(usd, format: .currency(code: "USD"))
                                        .font(theme.font(style: .title2))
                                        .foregroundColor(theme.textSecondary)
                                }
                            }
                        } else {
                            Text("Loading Balance...")
                                .font(theme.font(style: .title3))
                                .foregroundColor(theme.textSecondary)
                        }

                        HStack(spacing: theme.spacing2XL) {
                            VStack(spacing: theme.spacingS) {
                                Button(action: { showingSend = true }) {
                                    ZStack {
                                        Circle()
                                            .fill(theme.accentColor)
                                            .frame(width: theme.actionButtonSize, height: theme.actionButtonSize)
                                        Image(systemName: theme.iconSend)
                                            .font(.title2)
                                            .foregroundColor(theme.qrBackgroundColor)
                                    }
                                }
                                Text("Send")
                                    .font(theme.captionFont)
                                    .foregroundColor(theme.textPrimary)
                            }

                            VStack(spacing: theme.spacingS) {
                                Button(action: { showingReceive = true }) {
                                    ZStack {
                                        Circle()
                                            .fill(theme.backgroundSecondary)
                                            .frame(width: theme.actionButtonSize, height: theme.actionButtonSize)
                                            .overlay(Circle().stroke(theme.borderColor, lineWidth: 1))
                                        Image(systemName: theme.iconReceive)
                                            .font(.title2)
                                            .foregroundColor(theme.textPrimary)
                                    }
                                }
                                Text("Receive")
                                    .font(theme.captionFont)
                                    .foregroundColor(theme.textPrimary)
                            }
                        }
                        .padding(.vertical)

                        KryptoCard {
                            VStack(alignment: .leading, spacing: theme.spacingM) {
                                Text("Network Stats")
                                    .font(theme.headlineFont)
                                    .foregroundColor(theme.textPrimary)

                                KryptoListRow(title: "Network Status", value: "Operational", icon: theme.iconShield, isSystemIcon: true)
                                KryptoListRow(title: "Block Height", value: "Latest", icon: "cube.fill", isSystemIcon: true)
                            }
                        }
                        .padding(.horizontal)

                        Spacer()
                    }
                }
            }
        }
        .sheet(isPresented: $showingSend) {
            SendView(chain: chain)
        }
        .sheet(isPresented: $showingReceive) {
            ReceiveView(chain: chain)
        }
    }
}

extension Result {
    func get() throws -> Success {
        switch self {
        case let .success(value): return value
        case let .failure(error): throw error
        }
    }
}
