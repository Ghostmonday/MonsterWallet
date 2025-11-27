// KRYPTOCLAW SEND SCREEN
// Precision transfer. Zero mistakes.
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

public struct SendScreen: View {
    @EnvironmentObject var walletState: WalletStateManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var step: SendStep = .amount
    @State private var amount = ""
    @State private var recipient = ""
    @State private var selectedChain: Chain = .ethereum
    @State private var isProcessing = false
    @State private var showSuccess = false
    
    enum SendStep {
        case amount
        case recipient
        case confirm
    }
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                KC.Color.bg.ignoresSafeArea()
                
                if showSuccess {
                    successView
                } else {
                    switch step {
                    case .amount: amountView
                    case .recipient: recipientView
                    case .confirm: confirmView
                    }
                }
            }
            .kcNavigationInline()
            .toolbar {
                ToolbarItem(placement: .kcLeading) {
                    if step != .amount && !showSuccess {
                        KCBackButton {
                            withAnimation { step = previousStep }
                        }
                    }
                }
                ToolbarItem(placement: .principal) {
                    if !showSuccess {
                        StepIndicator(current: stepIndex, total: 3)
                    }
                }
                ToolbarItem(placement: .kcTrailing) {
                    if !showSuccess {
                        KCCloseButton { dismiss() }
                    }
                }
            }
        }
    }
    
    // MARK: - Step 1: Amount
    
    private var amountView: some View {
        VStack(spacing: 0) {
            VStack(spacing: KC.Space.sm) {
                Text("Send")
                    .font(KC.Font.title2)
                    .foregroundColor(KC.Color.textPrimary)
                
                Text("Enter amount to send")
                    .font(KC.Font.body)
                    .foregroundColor(KC.Color.textTertiary)
            }
            .padding(.top, KC.Space.xl)
            
            Spacer()
            
            // Amount display
            VStack(spacing: KC.Space.lg) {
                Text(amount.isEmpty ? "0" : amount)
                    .font(KC.Font.hero)
                    .foregroundColor(amount.isEmpty ? KC.Color.textMuted : KC.Color.textPrimary)
                
                // Chain selector
                Button(action: { /* Chain picker */ }) {
                    HStack(spacing: KC.Space.sm) {
                        KCTokenIcon(selectedChain.nativeCurrency, size: 28)
                        Text(selectedChain.nativeCurrency)
                            .font(KC.Font.bodyLarge)
                            .foregroundColor(KC.Color.textPrimary)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(KC.Color.textTertiary)
                    }
                    .padding(.horizontal, KC.Space.lg)
                    .padding(.vertical, KC.Space.md)
                    .background(KC.Color.card)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(KC.Color.border, lineWidth: 1))
                }
                
                // USD equivalent
                if let usdValue = calculateUSDValue() {
                    Text("≈ \(usdValue)")
                        .font(KC.Font.body)
                        .foregroundColor(KC.Color.textTertiary)
                }
            }
            
            Spacer()
            
            // Numpad
            NumPad(value: $amount)
                .padding(.horizontal, KC.Space.xl)
            
            // Continue button
            KCButton("Continue", icon: "arrow.right") {
                withAnimation { step = .recipient }
            }
            .kcPadding()
            .padding(.top, KC.Space.xl)
            .padding(.bottom, KC.Space.xxxl)
            .disabled(amount.isEmpty || amount == "0")
        }
    }
    
    // MARK: - Step 2: Recipient
    
    private var recipientView: some View {
        VStack(spacing: 0) {
            VStack(spacing: KC.Space.sm) {
                Text("Recipient")
                    .font(KC.Font.title2)
                    .foregroundColor(KC.Color.textPrimary)
                
                Text("Enter wallet address or select contact")
                    .font(KC.Font.body)
                    .foregroundColor(KC.Color.textTertiary)
            }
            .padding(.top, KC.Space.xl)
            
            // Address input
            VStack(alignment: .leading, spacing: KC.Space.sm) {
                Text("WALLET ADDRESS")
                    .font(KC.Font.label)
                    .tracking(1)
                    .foregroundColor(KC.Color.textMuted)
                
                HStack(spacing: KC.Space.md) {
                    TextField("0x...", text: $recipient)
                        .font(KC.Font.mono)
                        .foregroundColor(KC.Color.textPrimary)
                        .autocorrectionDisabled()
                    
                    // Paste button
                    Button(action: pasteAddress) {
                        Image(systemName: "doc.on.clipboard")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(KC.Color.gold)
                    }
                    
                    // Scan QR
                    Button(action: { /* QR Scanner */ }) {
                        Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(KC.Color.gold)
                    }
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
            .padding(.top, KC.Space.xxl)
            
            // Contacts
            if !walletState.contacts.isEmpty {
                VStack(alignment: .leading, spacing: KC.Space.md) {
                    Text("RECENT CONTACTS")
                        .font(KC.Font.label)
                        .tracking(1)
                        .foregroundColor(KC.Color.textMuted)
                        .padding(.top, KC.Space.xl)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: KC.Space.md) {
                            ForEach(walletState.contacts, id: \.id) { contact in
                                ContactChip(contact: contact) {
                                    recipient = contact.address
                                }
                            }
                        }
                    }
                }
                .kcPadding()
            }
            
            Spacer()
            
            KCButton("Continue") {
                Task {
                    await walletState.prepareTransaction(to: recipient, value: amount, chain: selectedChain)
                    withAnimation { step = .confirm }
                }
            }
            .kcPadding()
            .padding(.bottom, KC.Space.xxxl)
            .disabled(!isValidAddress(recipient))
        }
    }
    
    // MARK: - Step 3: Confirm
    
    private var confirmView: some View {
        VStack(spacing: 0) {
            VStack(spacing: KC.Space.sm) {
                Text("Confirm")
                    .font(KC.Font.title2)
                    .foregroundColor(KC.Color.textPrimary)
                
                Text("Review your transaction")
                    .font(KC.Font.body)
                    .foregroundColor(KC.Color.textTertiary)
            }
            .padding(.top, KC.Space.xl)
            
            ScrollView {
                VStack(spacing: KC.Space.lg) {
                    // Amount
                    ConfirmRow(label: "Amount", value: "\(amount) \(selectedChain.nativeCurrency)")
                    
                    // Recipient
                    ConfirmRow(label: "To", value: truncateAddress(recipient), isMono: true)
                    
                    // Network
                    ConfirmRow(label: "Network", value: selectedChain.displayName)
                    
                    // Gas estimate
                    if let sim = walletState.simulationResult {
                        ConfirmRow(label: "Network Fee", value: "~\(sim.estimatedGasUsed) gas")
                    }
                    
                    // Risk alerts
                    if !walletState.riskAlerts.isEmpty {
                        VStack(spacing: KC.Space.sm) {
                            ForEach(walletState.riskAlerts, id: \.description) { alert in
                                KCBanner(alert.description, type: alertType(for: alert.level))
                            }
                        }
                        .padding(.top, KC.Space.lg)
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
                .padding(.top, KC.Space.xxl)
            }
            
            // Slide to confirm
            SlideToConfirm(isLoading: $isProcessing) {
                confirmSend()
            }
            .kcPadding()
            .padding(.bottom, KC.Space.xxxl)
        }
    }
    
    // MARK: - Success
    
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
            
            VStack(spacing: KC.Space.sm) {
                Text("Sent Successfully")
                    .font(KC.Font.title2)
                    .foregroundColor(KC.Color.textPrimary)
                
                Text("\(amount) \(selectedChain.nativeCurrency)")
                    .font(KC.Font.monoLarge)
                    .foregroundColor(KC.Color.textTertiary)
            }
            
            if let hash = walletState.lastTxHash {
                Button(action: { openTransactionInExplorer(hash: hash) }) {
                    HStack(spacing: KC.Space.sm) {
                        Text("View Transaction")
                            .font(KC.Font.body)
                        Image(systemName: "arrow.up.right.square")
                            .font(.system(size: 14))
                    }
                    .foregroundColor(KC.Color.gold)
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
    
    private var stepIndex: Int {
        switch step {
        case .amount: return 1
        case .recipient: return 2
        case .confirm: return 3
        }
    }
    
    private var previousStep: SendStep {
        switch step {
        case .amount: return .amount
        case .recipient: return .amount
        case .confirm: return .recipient
        }
    }
    
    private func calculateUSDValue() -> String? {
        guard let amountNum = Decimal(string: amount), amountNum > 0 else { return nil }
        // This would use actual price data
        let mockPrice: Decimal = 2500
        let usd = amountNum * mockPrice
        return usd.formatted(.currency(code: "USD"))
    }
    
    private func pasteAddress() {
        #if canImport(UIKit)
        if let clipboardContent = UIPasteboard.general.string {
            recipient = clipboardContent
        }
        #endif
    }
    
    private func isValidAddress(_ address: String) -> Bool {
        // Basic validation
        address.hasPrefix("0x") && address.count == 42
    }
    
    private func truncateAddress(_ address: String) -> String {
        guard address.count > 12 else { return address }
        return "\(address.prefix(8))...\(address.suffix(6))"
    }
    
    private func openTransactionInExplorer(hash: String) {
        let baseURL: String
        
        switch selectedChain {
        case .ethereum:
            if AppConfig.isTestEnvironment {
                // For local testnet, we can't open in explorer - just copy hash
                #if canImport(UIKit)
                UIPasteboard.general.string = hash
                #endif
                return
            }
            baseURL = "https://etherscan.io/tx/"
        case .bitcoin:
            baseURL = "https://mempool.space/tx/"
        case .solana:
            baseURL = "https://solscan.io/tx/"
        }
        
        if let url = URL(string: baseURL + hash) {
            #if canImport(UIKit)
            UIApplication.shared.open(url)
            #endif
        }
    }
    
    private func alertType(for level: RiskLevel) -> KCBanner.BannerType {
        switch level {
        case .critical: return .error
        case .high: return .error
        case .medium: return .warning
        case .low: return .info
        }
    }
    
    private func confirmSend() {
        isProcessing = true
        Task {
            // Convert ETH to wei (multiply by 10^18)
            let weiValue = ethToWei(amount)
            NSLog("🔴 SEND TX: amount=%@ ETH, wei=%@, to=%@", amount, weiValue, recipient)
            
            let success = await walletState.confirmTransaction(to: recipient, value: weiValue, chain: selectedChain)
            
            await MainActor.run {
                isProcessing = false
                if success {
                    HapticEngine.shared.play(.success)
                    withAnimation {
                        showSuccess = true
                    }
                } else {
                    HapticEngine.shared.play(.error)
                    // Error state is set by confirmTransaction
                    NSLog("🔴 Transaction failed - not showing success screen")
                }
            }
        }
    }
    
    /// Convert ETH string to wei string
    private func ethToWei(_ eth: String) -> String {
        guard let ethDecimal = Decimal(string: eth) else { return "0" }
        let weiDecimal = ethDecimal * pow(10, 18)
        // Format without scientific notation
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.usesGroupingSeparator = false
        return formatter.string(from: weiDecimal as NSNumber) ?? "0"
    }
}

// MARK: - Supporting Views

struct StepIndicator: View {
    let current: Int
    let total: Int
    
    var body: some View {
        HStack(spacing: KC.Space.sm) {
            ForEach(1...total, id: \.self) { i in
                Capsule()
                    .fill(i <= current ? KC.Color.gold : KC.Color.textGhost)
                    .frame(width: i == current ? 24 : 8, height: 4)
            }
        }
    }
}

struct NumPad: View {
    @Binding var value: String
    
    private let keys = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        [".", "0", "⌫"]
    ]
    
    var body: some View {
        VStack(spacing: KC.Space.sm) {
            ForEach(keys, id: \.self) { row in
                HStack(spacing: KC.Space.sm) {
                    ForEach(row, id: \.self) { key in
                        NumPadKey(label: key) {
                            handleKey(key)
                        }
                    }
                }
            }
        }
    }
    
    private func handleKey(_ key: String) {
        HapticEngine.shared.play(.selection)
        switch key {
        case "⌫":
            if !value.isEmpty {
                value.removeLast()
            }
        case ".":
            if !value.contains(".") {
                value += value.isEmpty ? "0." : "."
            }
        default:
            if value == "0" {
                value = key
            } else {
                value += key
            }
        }
    }
}

struct NumPadKey: View {
    let label: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(KC.Font.title2)
                .foregroundColor(KC.Color.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(KC.Color.card)
                .clipShape(RoundedRectangle(cornerRadius: KC.Radius.md))
        }
    }
}

struct ContactChip: View {
    let contact: Contact
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: KC.Space.sm) {
                Circle()
                    .fill(KC.Color.gold.opacity(0.2))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text(String(contact.name.prefix(1)))
                            .font(KC.Font.caption)
                            .foregroundColor(KC.Color.gold)
                    )
                
                Text(contact.name)
                    .font(KC.Font.body)
                    .foregroundColor(KC.Color.textPrimary)
            }
            .padding(.horizontal, KC.Space.md)
            .padding(.vertical, KC.Space.sm)
            .background(KC.Color.card)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(KC.Color.border, lineWidth: 1))
        }
    }
}

struct ConfirmRow: View {
    let label: String
    let value: String
    var isMono: Bool = false
    
    var body: some View {
        HStack {
            Text(label)
                .font(KC.Font.body)
                .foregroundColor(KC.Color.textTertiary)
            
            Spacer()
            
            Text(value)
                .font(isMono ? KC.Font.mono : KC.Font.body)
                .foregroundColor(KC.Color.textPrimary)
        }
        .padding(.vertical, KC.Space.sm)
    }
}

struct SlideToConfirm: View {
    @Binding var isLoading: Bool
    let action: () -> Void
    
    @State private var offset: CGFloat = 0
    @State private var width: CGFloat = 0
    
    private let thumbSize: CGFloat = 56
    private let threshold: CGFloat = 0.85
    
    var body: some View {
        GeometryReader { geo in
            slideContent(geo: geo)
        }
        .frame(height: thumbSize)
    }
    
    @ViewBuilder
    private func slideContent(geo: GeometryProxy) -> some View {
        ZStack(alignment: .leading) {
            // Track
            RoundedRectangle(cornerRadius: KC.Radius.lg)
                .fill(KC.Color.card)
                .overlay(
                    RoundedRectangle(cornerRadius: KC.Radius.lg)
                        .stroke(KC.Color.border, lineWidth: 1)
                )
            
            // Progress fill
            RoundedRectangle(cornerRadius: KC.Radius.lg)
                .fill(KC.Color.goldGhost)
                .frame(width: offset + thumbSize)
            
            // Label
            labelView(geo: geo)
            
            // Thumb
            thumbView(geo: geo)
        }
        .frame(height: thumbSize)
        .onAppear { width = geo.size.width }
    }
    
    private func labelView(geo: GeometryProxy) -> some View {
        let labelFont: SwiftUI.Font = .system(size: 15, weight: .medium)
        let textOpacity = 1 - (offset / (geo.size.width - thumbSize))
        return HStack {
            Spacer()
            Text(isLoading ? "Confirming..." : "Slide to Confirm")
                .font(labelFont)
                .foregroundColor(KC.Color.textTertiary)
                .opacity(textOpacity)
            Spacer()
        }
    }
    
    private func thumbView(geo: GeometryProxy) -> some View {
        Circle()
            .fill(isLoading ? KC.Color.gold.opacity(0.5) : KC.Color.gold)
            .frame(width: thumbSize - 8, height: thumbSize - 8)
            .overlay(thumbIcon)
            .padding(4)
            .offset(x: offset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        guard !isLoading else { return }
                        let newOffset = min(max(0, value.translation.width), geo.size.width - thumbSize)
                        offset = newOffset
                    }
                    .onEnded { _ in
                        guard !isLoading else { return }
                        let progress = offset / (geo.size.width - thumbSize)
                        if progress >= threshold {
                            HapticEngine.shared.play(.success)
                            action()
                        }
                        withAnimation(KC.Anim.spring) {
                            offset = 0
                        }
                    }
            )
    }
    
    @ViewBuilder
    private var thumbIcon: some View {
        if isLoading {
            ProgressView()
                .tint(KC.Color.bg)
        } else {
            Image(systemName: "arrow.right")
                .imageScale(.large)
                .fontWeight(.bold)
                .foregroundColor(KC.Color.bg)
        }
    }
}

#Preview {
    SendScreen()
}

