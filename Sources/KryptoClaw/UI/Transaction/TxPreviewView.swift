// MODULE: TxPreviewView
// VERSION: 1.0.0
// PURPOSE: Transaction preview UI with full theme integration

import SwiftUI

// MARK: - Transaction Preview View

/// Polished transaction preview interface with theme-driven styling.
///
/// **Sections:**
/// - Transaction details with clean card layout
/// - Simulation status with visual indicators
/// - Gas & MEV protection information
/// - Expected balance changes
/// - Slide to confirm action
@available(iOS 17.0, macOS 14.0, *)
public struct TxPreviewView: View {
    
    // MARK: - Properties
    
    @EnvironmentObject var themeManager: ThemeManager
    @Bindable var viewModel: TxPreviewViewModel
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Initialization
    
    public init(viewModel: TxPreviewViewModel) {
        self.viewModel = viewModel
    }
    
    // MARK: - Body
    
    public var body: some View {
        let theme = themeManager.currentTheme
        
        NavigationStack {
            ZStack {
                // Background
                Color.clear
                    .themedContainer(theme: theme, showPattern: true, applyAnimation: true)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: theme.spacingL) {
                        // Transaction Details Card
                        transactionDetailsSection(theme: theme)
                        
                        // Simulation Status Card
                        simulationSection(theme: theme)
                        
                        // Gas & Protection Card
                        gasAndProtectionSection(theme: theme)
                        
                        // Balance Changes Card
                        balanceChangesSection(theme: theme)
                        
                        // Actions Section
                        actionsSection(theme: theme)
                    }
                    .padding()
                }
            }
            .navigationTitle("Transaction Preview")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        viewModel.cancel()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(theme.textSecondary)
                    }
                    .disabled(viewModel.state.isProcessing)
                }
            }
            #endif
        }
    }
    
    // MARK: - Transaction Details Section
    
    private func transactionDetailsSection(theme: any ThemeProtocolV2) -> some View {
        KryptoCard {
            VStack(alignment: .leading, spacing: theme.spacingM) {
                // Section header
                HStack {
                    Image(systemName: "arrow.up.right.circle.fill")
                        .foregroundColor(theme.accentColor)
                        .font(.title2)
                    
                    Text("Transaction Details")
                        .font(theme.headlineFont)
                        .foregroundColor(theme.textPrimary)
                    
                    Spacer()
                }
                
                Divider()
                    .background(theme.borderColor)
                
                // Asset
                DetailRow(
                    label: "Asset",
                    value: viewModel.asset.symbol,
                    icon: "bitcoinsign.circle.fill",
                    theme: theme
                )
                
                // Recipient
                DetailRow(
                    label: "Recipient",
                    value: viewModel.shortRecipient,
                    icon: "person.circle.fill",
                    theme: theme,
                    isMonospace: true
                )
                
                // Amount
                DetailRow(
                    label: "Amount",
                    value: viewModel.formattedAmount,
                    icon: "number.circle.fill",
                    theme: theme,
                    valueColor: theme.textPrimary
                )
                
                // Data (if present)
                if !viewModel.data.isEmpty {
                    DetailRow(
                        label: "Data",
                        value: "\(viewModel.data.count) bytes",
                        icon: "doc.text.fill",
                        theme: theme
                    )
                }
            }
        }
    }
    
    // MARK: - Simulation Section
    
    private func simulationSection(theme: any ThemeProtocolV2) -> some View {
        KryptoCard {
            VStack(alignment: .leading, spacing: theme.spacingM) {
                // Section header
                HStack {
                    Image(systemName: "cpu")
                        .foregroundColor(simulationStatusColor(theme: theme))
                        .font(.title2)
                    
                    Text("Simulation")
                        .font(theme.headlineFont)
                        .foregroundColor(theme.textPrimary)
                    
                    Spacer()
                    
                    // Status badge
                    simulationStatusBadge(theme: theme)
                }
                
                Divider()
                    .background(theme.borderColor)
                
                // Status content
                simulationContent(theme: theme)
            }
        }
    }
    
    @ViewBuilder
    private func simulationStatusBadge(theme: any ThemeProtocolV2) -> some View {
        let (text, color) = simulationBadgeInfo(theme: theme)
        
        Text(text)
            .font(theme.captionFont)
            .fontWeight(.medium)
            .foregroundColor(color)
            .padding(.horizontal, theme.spacingS)
            .padding(.vertical, theme.spacingXS)
            .background(color.opacity(0.15))
            .cornerRadius(theme.cornerRadius / 2)
    }
    
    private func simulationBadgeInfo(theme: any ThemeProtocolV2) -> (String, Color) {
        switch viewModel.state {
        case .idle:
            return ("Pending", theme.textSecondary)
        case .simulating:
            return ("Simulating...", theme.accentColor)
        case .simulationFailed:
            return ("Failed", theme.errorColor)
        case .readyToSign:
            return ("Ready", theme.successColor)
        case .signing:
            return ("Signing...", theme.accentColor)
        case .broadcasting:
            return ("Broadcasting...", theme.accentColor)
        case .broadcasted:
            return ("Sent", theme.successColor)
        case .failed:
            return ("Failed", theme.errorColor)
        }
    }
    
    private func simulationStatusColor(theme: any ThemeProtocolV2) -> Color {
        switch viewModel.state {
        case .idle:
            return theme.textSecondary
        case .simulating, .signing, .broadcasting:
            return theme.accentColor
        case .simulationFailed, .failed:
            return theme.errorColor
        case .readyToSign, .broadcasted:
            return theme.successColor
        }
    }
    
    @ViewBuilder
    private func simulationContent(theme: any ThemeProtocolV2) -> some View {
        switch viewModel.state {
        case .idle:
            VStack(spacing: theme.spacingM) {
                Image(systemName: "play.circle")
                    .font(.system(size: 40))
                    .foregroundColor(theme.textSecondary)
                
                Text("Simulate transaction to check for errors")
                    .font(theme.bodyFont)
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
                
                KryptoButton(
                    title: "Simulate Transaction",
                    icon: "bolt.fill",
                    action: {
                        Task { await viewModel.simulate() }
                    },
                    isPrimary: true
                )
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, theme.spacingM)
            
        case .simulating:
            HStack(spacing: theme.spacingM) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: theme.accentColor))
                
                Text("Simulating transaction...")
                    .font(theme.bodyFont)
                    .foregroundColor(theme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, theme.spacingL)
            
        case .simulationFailed(let error):
            VStack(spacing: theme.spacingM) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(theme.errorColor)
                
                Text("Simulation Failed")
                    .font(theme.headlineFont)
                    .foregroundColor(theme.errorColor)
                
                Text(error)
                    .font(theme.captionFont)
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
                
                KryptoButton(
                    title: "Retry Simulation",
                    icon: "arrow.clockwise",
                    action: {
                        Task { await viewModel.simulate() }
                    },
                    isPrimary: false
                )
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, theme.spacingM)
            
        case .readyToSign(let receipt):
            VStack(spacing: theme.spacingM) {
                HStack(spacing: theme.spacingS) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.title2)
                        .foregroundColor(theme.successColor)
                    
                    Text("Simulation Passed")
                        .font(theme.headlineFont)
                        .foregroundColor(theme.successColor)
                }
                
                VStack(spacing: theme.spacingS) {
                    HStack {
                        Text("Receipt ID")
                            .font(theme.captionFont)
                            .foregroundColor(theme.textSecondary)
                        Spacer()
                        Text(String(receipt.receiptId.prefix(12)) + "...")
                            .font(theme.addressFont)
                            .foregroundColor(theme.textPrimary)
                    }
                    
                    if receipt.isExpired {
                        HStack {
                            Image(systemName: "clock.badge.exclamationmark")
                                .foregroundColor(theme.securityWarningColor)
                            Text("Receipt Expired - Re-simulate")
                                .font(theme.captionFont)
                                .foregroundColor(theme.securityWarningColor)
                        }
                    } else {
                        HStack {
                            Text("Valid until")
                                .font(theme.captionFont)
                                .foregroundColor(theme.textSecondary)
                            Spacer()
                            Text(receipt.expiresAt.formatted())
                                .font(theme.captionFont)
                                .foregroundColor(theme.textSecondary)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, theme.spacingS)
            
        case .signing, .broadcasting:
            HStack(spacing: theme.spacingM) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: theme.accentColor))
                
                Text(viewModel.state == .signing ? "Signing transaction..." : "Broadcasting to network...")
                    .font(theme.bodyFont)
                    .foregroundColor(theme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, theme.spacingL)
            
        case .broadcasted(let txHash):
            VStack(spacing: theme.spacingM) {
                ZStack {
                    Circle()
                        .fill(theme.successColor.opacity(0.15))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(theme.successColor)
                }
                
                Text("Transaction Sent!")
                    .font(theme.headlineFont)
                    .foregroundColor(theme.successColor)
                
                VStack(spacing: theme.spacingXS) {
                    Text("Transaction Hash")
                        .font(theme.captionFont)
                        .foregroundColor(theme.textSecondary)
                    
                    Text(txHash)
                        .font(theme.addressFont)
                        .foregroundColor(theme.textPrimary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .padding(.horizontal, theme.spacingM)
                        .padding(.vertical, theme.spacingS)
                        .background(theme.backgroundSecondary)
                        .cornerRadius(theme.cornerRadius)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, theme.spacingM)
            
        case .failed(let error):
            VStack(spacing: theme.spacingM) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(theme.errorColor)
                
                Text("Transaction Failed")
                    .font(theme.headlineFont)
                    .foregroundColor(theme.errorColor)
                
                Text(error)
                    .font(theme.captionFont)
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
                
                KryptoButton(
                    title: "Try Again",
                    icon: "arrow.clockwise",
                    action: { viewModel.reset() },
                    isPrimary: false
                )
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, theme.spacingM)
        }
    }
    
    // MARK: - Gas & Protection Section
    
    private func gasAndProtectionSection(theme: any ThemeProtocolV2) -> some View {
        KryptoCard {
            VStack(alignment: .leading, spacing: theme.spacingM) {
                // Section header
                HStack {
                    Image(systemName: "fuelpump.fill")
                        .foregroundColor(theme.accentColor)
                        .font(.title2)
                    
                    Text("Gas & Protection")
                        .font(theme.headlineFont)
                        .foregroundColor(theme.textPrimary)
                    
                    Spacer()
                }
                
                Divider()
                    .background(theme.borderColor)
                
                // Gas estimate
                DetailRow(
                    label: "Estimated Gas",
                    value: viewModel.estimatedGasCost,
                    icon: "flame.fill",
                    theme: theme
                )
                
                // Total cost
                DetailRow(
                    label: "Total Cost",
                    value: viewModel.totalCost,
                    icon: "dollarsign.circle.fill",
                    theme: theme,
                    valueColor: theme.textPrimary
                )
                
                Divider()
                    .background(theme.borderColor)
                
                // MEV Protection
                HStack(spacing: theme.spacingM) {
                    Image(systemName: "shield.checkered")
                        .foregroundColor(mevProtectionColor(theme: theme))
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: theme.spacingXS) {
                        Text("MEV Protection")
                            .font(theme.font(style: .subheadline))
                            .foregroundColor(theme.textPrimary)
                        
                        Text(viewModel.mevProtectionStatus.description)
                            .font(theme.captionFont)
                            .foregroundColor(theme.textSecondary)
                    }
                    
                    Spacer()
                    
                    mevStatusBadge(theme: theme)
                }
            }
        }
    }
    
    private func mevProtectionColor(theme: any ThemeProtocolV2) -> Color {
        switch viewModel.mevProtectionStatus {
        case .enabled:
            return theme.successColor
        case .disabled:
            return theme.textSecondary
        case .unavailable:
            return theme.securityWarningColor
        }
    }
    
    @ViewBuilder
    private func mevStatusBadge(theme: any ThemeProtocolV2) -> some View {
        let (text, color) = switch viewModel.mevProtectionStatus {
        case .enabled:
            ("Active", theme.successColor)
        case .disabled:
            ("Off", theme.textSecondary)
        case .unavailable:
            ("Unavailable", theme.securityWarningColor)
        }
        
        Text(text)
            .font(theme.captionFont)
            .fontWeight(.medium)
            .foregroundColor(color)
            .padding(.horizontal, theme.spacingS)
            .padding(.vertical, theme.spacingXS)
            .background(color.opacity(0.15))
            .cornerRadius(theme.cornerRadius / 2)
    }
    
    // MARK: - Balance Changes Section
    
    private func balanceChangesSection(theme: any ThemeProtocolV2) -> some View {
        KryptoCard {
            VStack(alignment: .leading, spacing: theme.spacingM) {
                // Section header
                HStack {
                    Image(systemName: "arrow.left.arrow.right.circle.fill")
                        .foregroundColor(theme.accentColor)
                        .font(.title2)
                    
                    Text("Expected Changes")
                        .font(theme.headlineFont)
                        .foregroundColor(theme.textPrimary)
                    
                    Spacer()
                }
                
                Divider()
                    .background(theme.borderColor)
                
                if viewModel.balanceChanges.isEmpty {
                    HStack {
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(theme.textSecondary)
                        
                        Text("Simulate to see expected changes")
                            .font(theme.bodyFont)
                            .foregroundColor(theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, theme.spacingM)
                } else {
                    ForEach(Array(viewModel.balanceChanges.keys.sorted()), id: \.self) { address in
                        if let change = viewModel.balanceChanges[address] {
                            HStack {
                                Text(shortenAddress(address))
                                    .font(theme.addressFont)
                                    .foregroundColor(theme.textSecondary)
                                
                                Spacer()
                                
                                Text(change)
                                    .font(theme.font(style: .subheadline))
                                    .fontWeight(.medium)
                                    .foregroundColor(change.hasPrefix("-") ? theme.errorColor : theme.successColor)
                            }
                            .padding(.vertical, theme.spacingXS)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Actions Section
    
    @ViewBuilder
    private func actionsSection(theme: any ThemeProtocolV2) -> some View {
        VStack(spacing: theme.spacingM) {
            if viewModel.canConfirmTransaction {
                VStack(spacing: theme.spacingS) {
                    Text("Slide to confirm transaction")
                        .font(theme.captionFont)
                        .foregroundColor(theme.textSecondary)
                    
                    SlideToConfirmButton(
                        progress: Binding(
                            get: { viewModel.confirmProgress },
                            set: { viewModel.updateSlideProgress($0) }
                        ),
                        isEnabled: viewModel.canConfirmTransaction,
                        label: "Slide to Send"
                    ) {
                        Task {
                            await viewModel.confirm()
                        }
                    }
                }
            } else if viewModel.state == .idle {
                Text("Simulate transaction first to enable confirmation")
                    .font(theme.captionFont)
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
            } else if viewModel.state.isProcessing {
                Text("Processing transaction...")
                    .font(theme.captionFont)
                    .foregroundColor(theme.textSecondary)
            } else if viewModel.state.isFinal {
                KryptoButton(
                    title: "Done",
                    icon: "checkmark.circle.fill",
                    action: { dismiss() },
                    isPrimary: true
                )
            }
        }
        .padding(.top, theme.spacingM)
    }
    
    // MARK: - Helpers
    
    private func shortenAddress(_ address: String) -> String {
        guard address.count > 12 else { return address }
        return "\(address.prefix(6))...\(address.suffix(4))"
    }
}

// MARK: - Detail Row Component

private struct DetailRow: View {
    let label: String
    let value: String
    let icon: String
    let theme: any ThemeProtocolV2
    var isMonospace: Bool = false
    var valueColor: Color?
    
    var body: some View {
        HStack {
            HStack(spacing: theme.spacingS) {
                Image(systemName: icon)
                    .foregroundColor(theme.textSecondary)
                    .font(.subheadline)
                    .frame(width: 20)
                
                Text(label)
                    .font(theme.bodyFont)
                    .foregroundColor(theme.textSecondary)
            }
            
            Spacer()
            
            Text(value)
                .font(isMonospace ? theme.addressFont : theme.font(style: .subheadline))
                .fontWeight(.medium)
                .foregroundColor(valueColor ?? theme.textPrimary)
                .lineLimit(1)
        }
        .padding(.vertical, theme.spacingXS)
    }
}

// MARK: - Transaction Success View

/// Polished success view after broadcast
@available(iOS 17.0, macOS 14.0, *)
public struct TransactionSuccessView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    let txHash: String
    let chain: AssetChain
    let onDone: () -> Void
    
    @State private var showContent = false
    @State private var confettiScale: CGFloat = 0
    
    public init(txHash: String, chain: AssetChain, onDone: @escaping () -> Void) {
        self.txHash = txHash
        self.chain = chain
        self.onDone = onDone
    }
    
    public var body: some View {
        let theme = themeManager.currentTheme
        
        ZStack {
            Color.clear
                .themedContainer(theme: theme, showPattern: true, applyAnimation: true)
                .ignoresSafeArea()
            
            VStack(spacing: theme.spacing2XL) {
                Spacer()
                
                // Success animation
                ZStack {
                    // Celebration rings
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .stroke(
                                theme.successColor.opacity(0.3 - Double(index) * 0.1),
                                lineWidth: 2
                            )
                            .frame(
                                width: 120 + CGFloat(index) * 40,
                                height: 120 + CGFloat(index) * 40
                            )
                            .scaleEffect(confettiScale)
                    }
                    
                    Circle()
                        .fill(theme.successColor.opacity(0.15))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(theme.successColor)
                }
                .scaleEffect(showContent ? 1.0 : 0.5)
                .opacity(showContent ? 1.0 : 0)
                
                VStack(spacing: theme.spacingM) {
                    Text("Transaction Sent!")
                        .font(theme.font(style: .title))
                        .foregroundColor(theme.successColor)
                    
                    Text("Your transaction has been broadcast to \(chain.displayName)")
                        .font(theme.bodyFont)
                        .foregroundColor(theme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .opacity(showContent ? 1.0 : 0)
                .offset(y: showContent ? 0 : 20)
                
                // Transaction hash card
                KryptoCard {
                    VStack(spacing: theme.spacingS) {
                        Text("Transaction Hash")
                            .font(theme.captionFont)
                            .foregroundColor(theme.textSecondary)
                        
                        Text(txHash)
                            .font(theme.addressFont)
                            .foregroundColor(theme.textPrimary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
                .padding(.horizontal, theme.spacingXL)
                .opacity(showContent ? 1.0 : 0)
                
                Spacer()
                
                KryptoButton(
                    title: "Done",
                    icon: "checkmark.circle.fill",
                    action: onDone,
                    isPrimary: true
                )
                .padding(.horizontal, theme.spacingXL)
                .padding(.bottom, theme.spacing2XL)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                showContent = true
                confettiScale = 1.0
            }
        }
    }
}

// MARK: - Transaction Failed View

/// Polished failure view
@available(iOS 17.0, macOS 14.0, *)
public struct TransactionFailedView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    let error: String
    let onRetry: () -> Void
    let onDismiss: () -> Void
    
    public init(error: String, onRetry: @escaping () -> Void, onDismiss: @escaping () -> Void) {
        self.error = error
        self.onRetry = onRetry
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        let theme = themeManager.currentTheme
        
        ZStack {
            Color.clear
                .themedContainer(theme: theme, showPattern: true, applyAnimation: true)
                .ignoresSafeArea()
            
            VStack(spacing: theme.spacing2XL) {
                Spacer()
                
                // Error icon
                ZStack {
                    Circle()
                        .fill(theme.errorColor.opacity(0.15))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(theme.errorColor)
                }
                
                VStack(spacing: theme.spacingM) {
                    Text("Transaction Failed")
                        .font(theme.font(style: .title))
                        .foregroundColor(theme.errorColor)
                    
                    Text(error)
                        .font(theme.bodyFont)
                        .foregroundColor(theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, theme.spacingXL)
                }
                
                Spacer()
                
                VStack(spacing: theme.spacingM) {
                    KryptoButton(
                        title: "Try Again",
                        icon: "arrow.clockwise",
                        action: onRetry,
                        isPrimary: true
                    )
                    
                    Button(action: onDismiss) {
                        Text("Dismiss")
                            .font(theme.bodyFont)
                            .foregroundColor(theme.textSecondary)
                    }
                }
                .padding(.horizontal, theme.spacingXL)
                .padding(.bottom, theme.spacing2XL)
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
@available(iOS 17.0, macOS 14.0, *)
struct TxPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        TxPreviewPreviewContainer()
    }
}

@available(iOS 17.0, macOS 14.0, *)
struct TxPreviewPreviewContainer: View {
    var body: some View {
        let rpcRouter = RPCRouter()
        let simulationService = TransactionSimulationService(rpcRouter: rpcRouter)
        
        let viewModel = TxPreviewViewModel(
            asset: Asset.ethereum,
            recipient: "0x742d35Cc6634C0532925a3b844Bc9e7595f2b521",
            amount: "0.1",
            senderAddress: "0x1234567890abcdef1234567890abcdef12345678",
            simulationService: simulationService,
            rpcRouter: rpcRouter
        )
        
        TxPreviewView(viewModel: viewModel)
    }
}
#endif
