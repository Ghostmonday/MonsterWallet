// KRYPTOCLAW BUY SCREEN
// Fiat on-ramp. Simple.
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

import SwiftUI

public struct BuyScreen: View {
    @EnvironmentObject var walletState: WalletStateManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var amount = ""
    @State private var selectedToken = "ETH"
    @State private var selectedProvider: BuyProvider?
    @State private var showProviders = false
    
    private let providers: [BuyProvider] = [
        BuyProvider(id: "moonpay", name: "MoonPay", fee: "4.5%", minAmount: 30, logo: "creditcard"),
        BuyProvider(id: "ramp", name: "Ramp Network", fee: "2.9%", minAmount: 50, logo: "banknote"),
        BuyProvider(id: "transak", name: "Transak", fee: "3.5%", minAmount: 20, logo: "dollarsign.circle"),
    ]
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                KC.Color.bg.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: KC.Space.xxl) {
                            // Amount section
                            VStack(spacing: KC.Space.lg) {
                                Text("BUY CRYPTO")
                                    .font(KC.Font.label)
                                    .tracking(2)
                                    .foregroundColor(KC.Color.textMuted)
                                
                                // Amount input
                                HStack(alignment: .center) {
                                    Text("$")
                                        .font(KC.Font.display)
                                        .foregroundColor(KC.Color.textMuted)
                                    
                                    TextField("0", text: $amount)
                                        .font(KC.Font.hero)
                                        .foregroundColor(KC.Color.textPrimary)
                                        #if os(iOS)
                                        #if os(iOS)
                                    .keyboardType(.numberPad)
                                    #endif
                                        #endif
                                        .multilineTextAlignment(.center)
                                        .frame(maxWidth: .infinity)
                                }
                                .kcPadding()
                                
                                // Quick amounts
                                HStack(spacing: KC.Space.md) {
                                    QuickAmountButton(amount: "$50") { amount = "50" }
                                    QuickAmountButton(amount: "$100") { amount = "100" }
                                    QuickAmountButton(amount: "$250") { amount = "250" }
                                    QuickAmountButton(amount: "$500") { amount = "500" }
                                }
                                .kcPadding()
                            }
                            .padding(.top, KC.Space.xl)
                            
                            // Token selector
                            VStack(alignment: .leading, spacing: KC.Space.md) {
                                Text("RECEIVE")
                                    .font(KC.Font.label)
                                    .tracking(1.5)
                                    .foregroundColor(KC.Color.textMuted)
                                
                                HStack(spacing: KC.Space.lg) {
                                    KCTokenIcon(selectedToken)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(selectedToken)
                                            .font(KC.Font.body)
                                            .foregroundColor(KC.Color.textPrimary)
                                        
                                        if let estimated = estimatedAmount {
                                            Text("≈ \(estimated) \(selectedToken)")
                                                .font(KC.Font.caption)
                                                .foregroundColor(KC.Color.textTertiary)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(KC.Color.textTertiary)
                                }
                                .padding(KC.Space.lg)
                                .background(KC.Color.card)
                                .clipShape(RoundedRectangle(cornerRadius: KC.Radius.lg))
                                .overlay(
                                    RoundedRectangle(cornerRadius: KC.Radius.lg)
                                        .stroke(KC.Color.border, lineWidth: 1)
                                )
                            }
                            .kcPadding()
                            
                            // Provider selection
                            VStack(alignment: .leading, spacing: KC.Space.md) {
                                Text("PAYMENT PROVIDER")
                                    .font(KC.Font.label)
                                    .tracking(1.5)
                                    .foregroundColor(KC.Color.textMuted)
                                
                                VStack(spacing: KC.Space.sm) {
                                    ForEach(providers) { provider in
                                        ProviderRow(
                                            provider: provider,
                                            isSelected: selectedProvider?.id == provider.id
                                        )
                                        .onTapGesture {
                                            HapticEngine.shared.play(.selection)
                                            selectedProvider = provider
                                        }
                                    }
                                }
                            }
                            .kcPadding()
                        }
                    }
                    
                    // Continue button
                    KCButton("Continue with \(selectedProvider?.name ?? "Provider")", icon: "arrow.right") {
                        // Open provider flow
                        HapticEngine.shared.play(.success)
                    }
                    .kcPadding()
                    .padding(.bottom, KC.Space.xxxl)
                    .disabled(amount.isEmpty || selectedProvider == nil)
                }
            }
            .navigationTitle("Buy")
            .kcNavigationInline()
            .toolbar {
                ToolbarItem(placement: .kcTrailing) {
                    KCCloseButton { dismiss() }
                }
            }
        }
    }
    
    private var estimatedAmount: String? {
        guard let amountNum = Double(amount), amountNum > 0 else { return nil }
        let price: Double = selectedToken == "ETH" ? 2500 : 1
        let estimated = amountNum / price
        return String(format: "%.4f", estimated)
    }
}

// MARK: - Quick Amount Button

private struct QuickAmountButton: View {
    let amount: String
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticEngine.shared.play(.selection)
            action()
        }) {
            Text(amount)
                .font(KC.Font.caption)
                .foregroundColor(KC.Color.textSecondary)
                .padding(.horizontal, KC.Space.md)
                .padding(.vertical, KC.Space.sm)
                .background(KC.Color.card)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(KC.Color.border, lineWidth: 1))
        }
    }
}

// MARK: - Provider Row

private struct ProviderRow: View {
    let provider: BuyProvider
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: KC.Space.lg) {
            // Logo
            ZStack {
                Circle()
                    .fill(KC.Color.gold.opacity(0.15))
                    .frame(width: KC.Size.avatarMD, height: KC.Size.avatarMD)
                
                Image(systemName: provider.logo)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(KC.Color.gold)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(provider.name)
                    .font(KC.Font.body)
                    .foregroundColor(KC.Color.textPrimary)
                
                Text("Fee: \(provider.fee) • Min: $\(Int(provider.minAmount))")
                    .font(KC.Font.caption)
                    .foregroundColor(KC.Color.textTertiary)
            }
            
            Spacer()
            
            // Selection indicator
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(KC.Color.gold)
            } else {
                Circle()
                    .stroke(KC.Color.border, lineWidth: 2)
                    .frame(width: 22, height: 22)
            }
        }
        .padding(KC.Space.lg)
        .background(isSelected ? KC.Color.goldGhost : KC.Color.card)
        .clipShape(RoundedRectangle(cornerRadius: KC.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: KC.Radius.md)
                .stroke(isSelected ? KC.Color.gold.opacity(0.3) : KC.Color.border, lineWidth: 1)
        )
    }
}

// MARK: - Models

struct BuyProvider: Identifiable {
    let id: String
    let name: String
    let fee: String
    let minAmount: Double
    let logo: String
}

#Preview {
    BuyScreen()
}

