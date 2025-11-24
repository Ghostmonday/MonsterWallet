import SwiftUI

struct SendView: View {
    @EnvironmentObject var wsm: WalletStateManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.presentationMode) var presentationMode

    @State private var toAddress: String = ""
    @State private var amount: String = ""
    @State private var isSimulating = false
    @State private var showConfirmation = false

    private var hasCriticalRisk: Bool {
        wsm.riskAlerts.contains { $0.level == .critical }
    }

    var body: some View {
        ZStack {
            themeManager.currentTheme.backgroundMain.ignoresSafeArea()

            VStack(spacing: 24) {
                HStack {
                    Text("Send Crypto")
                        .font(themeManager.currentTheme.font(style: .title2))
                        .foregroundColor(themeManager.currentTheme.textPrimary)
                    Spacer()
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(themeManager.currentTheme.textSecondary)
                            .font(.system(size: 32))
                    }
                }
                .padding()

                VStack(spacing: 24) {
                    KryptoInput(title: "To", placeholder: "0x...", text: $toAddress)
                    KryptoInput(title: "Amount", placeholder: "0.00", text: $amount)
                }
                .padding(.horizontal)

                if let result = wsm.simulationResult {
                    KryptoCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Simulation Result")
                                    .font(themeManager.currentTheme.font(style: .headline))
                                    .foregroundColor(themeManager.currentTheme.textPrimary)
                                Spacer()
                                if result.success {
                                    Text("PASSED")
                                        .foregroundColor(themeManager.currentTheme.successColor)
                                        .font(themeManager.currentTheme.font(style: .headline))
                                } else {
                                    Text("FAILED")
                                        .foregroundColor(themeManager.currentTheme.errorColor)
                                        .font(themeManager.currentTheme.font(style: .headline))
                                }
                            }

                            if !wsm.riskAlerts.isEmpty {
                                ForEach(wsm.riskAlerts, id: \.description) { alert in
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(alert.level == .critical ? .white : themeManager.currentTheme.warningColor)

                                        Text(alert.description)
                                            .font(themeManager.currentTheme.font(style: .caption))
                                            .foregroundColor(alert.level == .critical ? .white : themeManager.currentTheme.textPrimary)
                                            .bold(alert.level == .critical)
                                    }
                                    .padding(alert.level == .critical ? 8 : 0)
                                    .background(alert.level == .critical ? themeManager.currentTheme.errorColor : Color.clear)
                                    .cornerRadius(4)
                                }
                            }

                            HStack {
                                Text("Est. Gas:")
                                    .foregroundColor(themeManager.currentTheme.textSecondary)
                                    .font(themeManager.currentTheme.font(style: .body))
                                Text("\(result.estimatedGasUsed)")
                                    .foregroundColor(themeManager.currentTheme.textPrimary)
                                    .font(themeManager.currentTheme.font(style: .body))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal)
                }

                Spacer()

                VStack(spacing: 16) {
                    if wsm.simulationResult == nil || wsm.simulationResult?.success == false {
                        KryptoButton(title: isSimulating ? "Simulating..." : "Simulate Transaction", icon: "play.fill", action: {
                            Task {
                                isSimulating = true
                                await wsm.prepareTransaction(to: toAddress, value: amount)
                                isSimulating = false
                            }
                        }, isPrimary: true)
                    } else {
                        if hasCriticalRisk {
                            Text("Cannot Send: Critical Risk Detected")
                                .font(themeManager.currentTheme.font(style: .caption))
                                .foregroundColor(themeManager.currentTheme.errorColor)
                                .bold()
                        }

                        KryptoButton(title: "Confirm & Send", icon: themeManager.currentTheme.iconSend, action: {
                            Task {
                                await wsm.confirmTransaction(to: toAddress, value: amount)
                                presentationMode.wrappedValue.dismiss()
                            }
                        }, isPrimary: true)
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
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(themeManager.currentTheme.font(style: .headline))
                .foregroundColor(themeManager.currentTheme.textPrimary)

            TextField(placeholder, text: $text)
                .font(themeManager.currentTheme.font(style: .title3))
                .foregroundColor(themeManager.currentTheme.textPrimary)
                .padding()
                .background(themeManager.currentTheme.cardBackground)
                .cornerRadius(2)
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(themeManager.currentTheme.borderColor, lineWidth: 2)
                )
        }
    }
}
