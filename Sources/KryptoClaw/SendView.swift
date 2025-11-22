import SwiftUI

struct SendView: View {
    @EnvironmentObject var wsm: WalletStateManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var toAddress: String = ""
    @State private var amount: String = ""
    @State private var isSimulating = false
    @State private var showConfirmation = false
    
    var body: some View {
        ZStack {
            themeManager.currentTheme.backgroundMain.ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header
                HStack {
                    Text("Send Crypto")
                        .font(themeManager.currentTheme.font(style: .title2, weight: .bold))
                        .foregroundColor(themeManager.currentTheme.textPrimary)
                    Spacer()
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(themeManager.currentTheme.textSecondary)
                            .font(.title2)
                    }
                }
                .padding()
                
                // Inputs
                VStack(spacing: 16) {
                    KryptoTextField(placeholder: "Recipient Address (0x...)", text: $toAddress)
                    KryptoTextField(placeholder: "Amount (ETH)", text: $amount)
                }
                .padding(.horizontal)
                
                // Simulation Output
                if let result = wsm.simulationResult {
                    KryptoCard {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Simulation Result")
                                    .font(themeManager.currentTheme.font(style: .headline, weight: .bold))
                                    .foregroundColor(themeManager.currentTheme.textPrimary)
                                Spacer()
                                if result.success {
                                    Text("PASSED")
                                        .foregroundColor(themeManager.currentTheme.successColor)
                                        .bold()
                                } else {
                                    Text("FAILED")
                                        .foregroundColor(themeManager.currentTheme.errorColor)
                                        .bold()
                                }
                            }
                            
                            if !wsm.riskAlerts.isEmpty {
                                ForEach(wsm.riskAlerts, id: \.description) { alert in
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(themeManager.currentTheme.warningColor)
                                        Text(alert.description)
                                            .font(themeManager.currentTheme.font(style: .caption, weight: .medium))
                                            .foregroundColor(themeManager.currentTheme.textPrimary)
                                    }
                                }
                            }
                            
                            HStack {
                                Text("Est. Gas:")
                                    .foregroundColor(themeManager.currentTheme.textSecondary)
                                Text("\(result.estimatedGasUsed)")
                                    .foregroundColor(themeManager.currentTheme.textPrimary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // Actions
                VStack(spacing: 12) {
                    if wsm.simulationResult == nil || wsm.simulationResult?.success == false {
                        KryptoButton(title: isSimulating ? "Simulating..." : "Simulate Transaction", icon: "play.fill", action: {
                            Task {
                                isSimulating = true
                                await wsm.prepareTransaction(to: toAddress, value: amount)
                                isSimulating = false
                            }
                        }, isPrimary: false)
                    } else {
                        KryptoButton(title: "Confirm & Send", icon: themeManager.currentTheme.iconSend, action: {
                            Task {
                                await wsm.confirmTransaction(to: toAddress, value: amount)
                                presentationMode.wrappedValue.dismiss()
                            }
                        }, isPrimary: true)
                    }
                }
                .padding()
            }
        }
    }
}
