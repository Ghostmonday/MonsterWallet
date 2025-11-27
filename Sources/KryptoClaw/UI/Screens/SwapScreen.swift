// KRYPTOCLAW SWAP SCREEN
// Token exchange. Precise.
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

import SwiftUI

public struct SwapScreen: View {
    @EnvironmentObject var walletState: WalletStateManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var fromAmount = ""
    @State private var toAmount = ""
    @State private var fromToken = "ETH"
    @State private var toToken = "USDC"
    @State private var isLoadingQuote = false
    @State private var quote: LocalSwapQuote?
    @State private var isSwapping = false
    @State private var showSuccess = false
    @State private var showTokenPicker = false
    @State private var isSelectingFrom = true
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                KC.Color.bg.ignoresSafeArea()
                
                if showSuccess {
                    successView
                } else {
                    mainView
                }
            }
            .kcNavigationInline()
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Swap")
                        .font(KC.Font.bodyLarge)
                        .foregroundColor(KC.Color.textPrimary)
                }
                ToolbarItem(placement: .kcTrailing) {
                    if !showSuccess {
                        KCCloseButton { dismiss() }
                    }
                }
            }
        }
    }
    
    // MARK: - Main View
    
    private var mainView: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    // From section
                    VStack(alignment: .leading, spacing: KC.Space.sm) {
                        Text("FROM")
                            .font(KC.Font.label)
                            .tracking(1.5)
                            .foregroundColor(KC.Color.textMuted)
                        
                        HStack {
                            // Amount input
                            TextField("0", text: $fromAmount)
                                .font(KC.Font.display)
                                .foregroundColor(KC.Color.textPrimary)
                                #if os(iOS)
                                    .keyboardType(.decimalPad)
                                    #endif
                                .onChange(of: fromAmount) { _, _ in
                                    fetchQuote()
                                }
                            
                            Spacer()
                            
                            // Token selector
                            Button(action: {
                                isSelectingFrom = true
                                showTokenPicker = true
                            }) {
                                HStack(spacing: KC.Space.sm) {
                                    KCTokenIcon(fromToken, size: 32)
                                    Text(fromToken)
                                        .font(KC.Font.bodyLarge)
                                        .foregroundColor(KC.Color.textPrimary)
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(KC.Color.textTertiary)
                                }
                                .padding(.horizontal, KC.Space.md)
                                .padding(.vertical, KC.Space.sm)
                                .background(KC.Color.cardElevated)
                                .clipShape(Capsule())
                            }
                        }
                        
                        // Balance
                        HStack {
                            Text("Balance: 1.5 \(fromToken)")
                                .font(KC.Font.caption)
                                .foregroundColor(KC.Color.textTertiary)
                            
                            Spacer()
                            
                            Button("MAX") {
                                fromAmount = "1.5"
                                fetchQuote()
                            }
                            .font(KC.Font.label)
                            .foregroundColor(KC.Color.gold)
                        }
                    }
                    .padding(KC.Space.xl)
                    .background(KC.Color.card)
                    .clipShape(RoundedRectangle(cornerRadius: KC.Radius.xl))
                    .overlay(
                        RoundedRectangle(cornerRadius: KC.Radius.xl)
                            .stroke(KC.Color.border, lineWidth: 1)
                    )
                    .kcPadding()
                    .padding(.top, KC.Space.xl)
                    
                    // Swap button
                    Button(action: swapTokens) {
                        ZStack {
                            Circle()
                                .fill(KC.Color.bg)
                                .frame(width: 48, height: 48)
                            
                            Circle()
                                .fill(KC.Color.card)
                                .frame(width: 44, height: 44)
                                .overlay(Circle().stroke(KC.Color.border, lineWidth: 1))
                            
                            Image(systemName: "arrow.up.arrow.down")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(KC.Color.gold)
                        }
                    }
                    .offset(y: -24)
                    .zIndex(1)
                    
                    // To section
                    VStack(alignment: .leading, spacing: KC.Space.sm) {
                        Text("TO")
                            .font(KC.Font.label)
                            .tracking(1.5)
                            .foregroundColor(KC.Color.textMuted)
                        
                        HStack {
                            // Amount display
                            Group {
                                if isLoadingQuote {
                                    HStack(spacing: KC.Space.sm) {
                                        ProgressView()
                                            .tint(KC.Color.gold)
                                        Text("Getting quote...")
                                            .font(KC.Font.title3)
                                            .foregroundColor(KC.Color.textTertiary)
                                    }
                                } else {
                                    Text(toAmount.isEmpty ? "0" : toAmount)
                                        .font(KC.Font.display)
                                        .foregroundColor(toAmount.isEmpty ? KC.Color.textMuted : KC.Color.textPrimary)
                                }
                            }
                            
                            Spacer()
                            
                            // Token selector
                            Button(action: {
                                isSelectingFrom = false
                                showTokenPicker = true
                            }) {
                                HStack(spacing: KC.Space.sm) {
                                    KCTokenIcon(toToken, size: 32)
                                    Text(toToken)
                                        .font(KC.Font.bodyLarge)
                                        .foregroundColor(KC.Color.textPrimary)
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(KC.Color.textTertiary)
                                }
                                .padding(.horizontal, KC.Space.md)
                                .padding(.vertical, KC.Space.sm)
                                .background(KC.Color.cardElevated)
                                .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(KC.Space.xl)
                    .background(KC.Color.card)
                    .clipShape(RoundedRectangle(cornerRadius: KC.Radius.xl))
                    .overlay(
                        RoundedRectangle(cornerRadius: KC.Radius.xl)
                            .stroke(KC.Color.border, lineWidth: 1)
                    )
                    .kcPadding()
                    .offset(y: -24)
                    
                    // Quote details
                    if let quote = quote {
                        VStack(spacing: KC.Space.md) {
                            QuoteRow(label: "Rate", value: "1 \(fromToken) = \(quote.rate) \(toToken)")
                            QuoteRow(label: "Network Fee", value: "~$\(quote.gasCostUSD)")
                            QuoteRow(label: "Price Impact", value: "\(quote.priceImpact)%")
                            
                            if quote.priceImpact > 5 {
                                KCBanner("High price impact. Consider swapping a smaller amount.", type: .warning)
                            }
                        }
                        .padding(KC.Space.lg)
                        .background(KC.Color.card)
                        .clipShape(RoundedRectangle(cornerRadius: KC.Radius.lg))
                        .overlay(
                            RoundedRectangle(cornerRadius: KC.Radius.lg)
                                .stroke(KC.Color.border, lineWidth: 1)
                        )
                        .kcPadding()
                    }
                }
            }
            
            // Swap button
            KCButton("Swap", icon: "arrow.left.arrow.right", isLoading: isSwapping) {
                executeSwap()
            }
            .kcPadding()
            .padding(.bottom, KC.Space.xxxl)
            .disabled(fromAmount.isEmpty || toAmount.isEmpty)
        }
        .sheet(isPresented: $showTokenPicker) {
            TokenPickerSheet(
                selected: isSelectingFrom ? $fromToken : $toToken,
                excluding: isSelectingFrom ? toToken : fromToken
            )
        }
    }
    
    // MARK: - Success View
    
    private var successView: some View {
        VStack(spacing: KC.Space.xxl) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(KC.Color.positive.opacity(0.15))
                    .frame(width: 140, height: 140)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 56, weight: .bold))
                    .foregroundColor(KC.Color.positive)
            }
            
            VStack(spacing: KC.Space.lg) {
                Text("Swap Complete")
                    .font(KC.Font.title2)
                    .foregroundColor(KC.Color.textPrimary)
                
                HStack(spacing: KC.Space.lg) {
                    VStack(spacing: KC.Space.xs) {
                        Text(fromAmount)
                            .font(KC.Font.monoLarge)
                            .foregroundColor(KC.Color.textSecondary)
                        Text(fromToken)
                            .font(KC.Font.caption)
                            .foregroundColor(KC.Color.textTertiary)
                    }
                    
                    Image(systemName: "arrow.right")
                        .foregroundColor(KC.Color.gold)
                    
                    VStack(spacing: KC.Space.xs) {
                        Text(toAmount)
                            .font(KC.Font.monoLarge)
                            .foregroundColor(KC.Color.textPrimary)
                        Text(toToken)
                            .font(KC.Font.caption)
                            .foregroundColor(KC.Color.textTertiary)
                    }
                }
            }
            
            Spacer()
            
            KCButton("Done") {
                dismiss()
            }
            .kcPadding()
            .padding(.bottom, KC.Space.xxxl)
        }
    }
    
    // MARK: - Helpers
    
    private func swapTokens() {
        HapticEngine.shared.play(.selection)
        let temp = fromToken
        fromToken = toToken
        toToken = temp
        
        let tempAmount = fromAmount
        fromAmount = toAmount
        toAmount = tempAmount
        
        fetchQuote()
    }
    
    private func fetchQuote() {
        guard !fromAmount.isEmpty, let amount = Decimal(string: fromAmount), amount > 0 else {
            toAmount = ""
            quote = nil
            return
        }
        
        isLoadingQuote = true
        
        Task {
            do {
                // Convert amount to base units (wei for ETH)
                let decimals = fromToken == "ETH" ? 18 : 6 // ETH=18, USDC/USDT=6
                let baseAmount = (amount * pow(10, decimals)).description.split(separator: ".").first ?? "0"
                
                // Get real quote from DEX aggregator
                let swapQuote = try await walletState.getSwapQuote(
                    from: fromToken,
                    to: toToken,
                    amount: String(baseAmount),
                    chain: .ethereum
                )
                
                // Convert output amount from base units
                let outDecimals = toToken == "ETH" ? 18 : 6
                let outAmount = (Decimal(string: swapQuote.outAmount) ?? 0) / pow(10, outDecimals)
                
                // Calculate rate
                let rate = outAmount / amount
                
                await MainActor.run {
                    toAmount = String(format: "%.2f", (outAmount as NSDecimalNumber).doubleValue)
                    quote = LocalSwapQuote(
                        fromToken: fromToken,
                        toToken: toToken,
                        fromAmount: fromAmount,
                        toAmount: toAmount,
                        rate: String(format: "%.4f", (rate as NSDecimalNumber).doubleValue),
                        gasCostUSD: "2.50", // TODO: Get from gas estimate
                        priceImpact: swapQuote.priceImpact ?? 0.1
                    )
                    isLoadingQuote = false
                }
            } catch {
                // Fallback to mock quote on error
                await MainActor.run {
                    if let amt = Double(fromAmount) {
                        let rate = fromToken == "ETH" ? 3000.0 : 0.00033 // Approximate rates
                        toAmount = String(format: "%.2f", amt * rate)
                        quote = LocalSwapQuote(
                            fromToken: fromToken,
                            toToken: toToken,
                            fromAmount: fromAmount,
                            toAmount: toAmount,
                            rate: String(format: "%.4f", rate),
                            gasCostUSD: "2.50",
                            priceImpact: 0.3
                        )
                    }
                    isLoadingQuote = false
                }
            }
        }
    }
    
    private func executeSwap() {
        isSwapping = true
        
        // Simulate swap
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            HapticEngine.shared.play(.success)
            withAnimation {
                isSwapping = false
                showSuccess = true
            }
        }
    }
}

// MARK: - Quote Row

private struct QuoteRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(KC.Font.body)
                .foregroundColor(KC.Color.textTertiary)
            Spacer()
            Text(value)
                .font(KC.Font.body)
                .foregroundColor(KC.Color.textPrimary)
        }
    }
}

// MARK: - Token Picker

struct TokenPickerSheet: View {
    @Binding var selected: String
    let excluding: String
    @Environment(\.dismiss) private var dismiss
    
    private let tokens = ["ETH", "USDC", "USDT", "DAI", "WBTC", "MATIC", "ARB", "OP"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                KC.Color.bg.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: KC.Space.sm) {
                        ForEach(tokens.filter { $0 != excluding }, id: \.self) { token in
                            Button(action: {
                                HapticEngine.shared.play(.selection)
                                selected = token
                                dismiss()
                            }) {
                                HStack(spacing: KC.Space.lg) {
                                    KCTokenIcon(token)
                                    
                                    Text(token)
                                        .font(KC.Font.body)
                                        .foregroundColor(KC.Color.textPrimary)
                                    
                                    Spacer()
                                    
                                    if token == selected {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(KC.Color.gold)
                                    }
                                }
                                .padding(KC.Space.lg)
                                .background(token == selected ? KC.Color.goldGhost : KC.Color.card)
                                .clipShape(RoundedRectangle(cornerRadius: KC.Radius.md))
                                .overlay(
                                    RoundedRectangle(cornerRadius: KC.Radius.md)
                                        .stroke(token == selected ? KC.Color.gold.opacity(0.3) : KC.Color.border, lineWidth: 1)
                                )
                            }
                        }
                    }
                    .kcPadding()
                    .padding(.top, KC.Space.lg)
                }
            }
            .navigationTitle("Select Token")
            .kcNavigationInline()
            .toolbar {
                ToolbarItem(placement: .kcTrailing) {
                    KCCloseButton { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// Local quote model for UI display
struct LocalSwapQuote {
    let fromToken: String
    let toToken: String
    let fromAmount: String
    let toAmount: String
    let rate: String
    let gasCostUSD: String
    let priceImpact: Double
}

#Preview {
    SwapScreen()
}

