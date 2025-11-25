import SwiftUI

struct SendView: View {
    let chain: Chain
    @EnvironmentObject var wsm: WalletStateManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.presentationMode) var presentationMode

    @State private var toAddress: String = ""
    @State private var amount: String = ""
    @State private var isSimulating = false
    @State private var showConfirmation = false
    
    init(chain: Chain = .ethereum) {
        self.chain = chain
    }

    private var hasCriticalRisk: Bool {
        wsm.riskAlerts.contains { $0.level == .critical }
    }

    var body: some View {
        let theme = themeManager.currentTheme
        
        ZStack {
            Color.clear
                .themedContainer(theme: theme, showPattern: true, applyAnimation: true)
                .ignoresSafeArea()

            VStack(spacing: theme.spacingXL) {
                HStack {
                    Text("Send \(chain.displayName)")
                        .font(theme.font(style: .title2))
                        .foregroundColor(theme.textPrimary)
                    Spacer()
                    KryptoCloseButton {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                .padding()

                VStack(spacing: theme.spacingXL) {
                    KryptoInput(title: "To", placeholder: "0x...", text: $toAddress)
                    KryptoInput(title: "Amount", placeholder: "0.00", text: $amount)
                }
                .padding(.horizontal)

                if let result = wsm.simulationResult {
                    KryptoCard {
                        VStack(alignment: .leading, spacing: theme.spacingM) {
                            HStack {
                                Text("Simulation Result")
                                    .font(theme.font(style: .headline))
                                    .foregroundColor(theme.textPrimary)
                                Spacer()
                                if result.success {
                                    Text("PASSED")
                                        .foregroundColor(theme.successColor)
                                        .font(theme.font(style: .headline))
                                } else {
                                    Text("FAILED")
                                        .foregroundColor(theme.errorColor)
                                        .font(theme.font(style: .headline))
                                }
                            }

                            if !wsm.riskAlerts.isEmpty {
                                ForEach(wsm.riskAlerts, id: \.description) { alert in
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(alert.level == .critical ? theme.qrBackgroundColor : theme.warningColor)

                                        Text(alert.description)
                                            .font(theme.font(style: .caption))
                                            .foregroundColor(alert.level == .critical ? theme.qrBackgroundColor : theme.textPrimary)
                                            .bold(alert.level == .critical)
                                    }
                                    .padding(alert.level == .critical ? theme.spacingS : 0)
                                    .background(alert.level == .critical ? theme.errorColor : Color.clear)
                                    .cornerRadius(theme.cornerRadius)
                                }
                            }

                            HStack {
                                Text("Est. Gas:")
                                    .foregroundColor(theme.textSecondary)
                                    .font(theme.font(style: .body))
                                Text("\(result.estimatedGasUsed)")
                                    .foregroundColor(theme.textPrimary)
                                    .font(theme.font(style: .body))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal)
                }

                Spacer()

                VStack(spacing: theme.spacingL) {
                    if wsm.simulationResult == nil || wsm.simulationResult?.success == false {
                        KryptoProgressButton(
                            title: "Simulate Transaction",
                            icon: "play.fill",
                            isLoading: isSimulating,
                            isPrimary: true
                        ) {
                            Task {
                                isSimulating = true
                                await wsm.prepareTransaction(to: toAddress, value: amount, chain: chain)
                                isSimulating = false
                            }
                        }
                    } else {
                        if hasCriticalRisk {
                            Text("Cannot Send: Critical Risk Detected")
                                .font(theme.font(style: .caption))
                                .foregroundColor(theme.errorColor)
                                .bold()
                        }

                        KryptoButton(
                            title: "Confirm & Send",
                            icon: theme.iconSend,
                            action: {
                                Task {
                                    await wsm.confirmTransaction(to: toAddress, value: amount, chain: chain)
                                    presentationMode.wrappedValue.dismiss()
                                }
                            },
                            isPrimary: true
                        )
                        .opacity(hasCriticalRisk ? 0.5 : 1.0)
                        .disabled(hasCriticalRisk)
                    }
                }
                .padding()
                .padding(.bottom)
            }
        }
    }
}

struct KryptoInput: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        let theme = themeManager.currentTheme
        
        VStack(alignment: .leading, spacing: theme.spacingS) {
            Text(title)
                .font(theme.font(style: .headline))
                .foregroundColor(theme.textPrimary)

            TextField(placeholder, text: $text)
                .font(theme.font(style: .title3))
                .foregroundColor(theme.textPrimary)
                .padding()
                .background(theme.cardBackground)
                .cornerRadius(theme.cornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: theme.cornerRadius)
                        .stroke(theme.borderColor, lineWidth: 2)
                )
        }
    }
}
