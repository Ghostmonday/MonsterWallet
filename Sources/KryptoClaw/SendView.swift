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
                
                // Inputs
                VStack(spacing: 24) {
                    KryptoInput(title: "To", placeholder: "0x...", text: $toAddress)
                    KryptoInput(title: "Amount", placeholder: "0.00", text: $amount)
                }
                .padding(.horizontal)
                
                // Simulation Output
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
                                            .foregroundColor(themeManager.currentTheme.warningColor)
                                        // TODO: [JULES-REVIEW] UX Safety: Ensure "Critical" alerts are visually distinct (e.g., Red background)
                                        // and explain *why* it is dangerous.
                                        Text(alert.description)
                                            .font(themeManager.currentTheme.font(style: .caption))
                                            .foregroundColor(themeManager.currentTheme.textPrimary)
                                    }
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
                
                // Actions
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
                        // TODO: [JULES-REVIEW] Safety: Block "Confirm & Send" if there are Critical Risk Alerts,
                        // or require an explicit "I accept the risk" checkbox.
                        // Currently, a user can ignore the red text and just click Send because simulation passed.
                        KryptoButton(title: "Confirm & Send", icon: themeManager.currentTheme.iconSend, action: {
                            Task {
                                await wsm.confirmTransaction(to: toAddress, value: amount)
                                presentationMode.wrappedValue.dismiss()
                            }
                        }, isPrimary: true)
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
