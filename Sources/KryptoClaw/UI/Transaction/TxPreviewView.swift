// MODULE: TxPreviewView
// VERSION: 1.0.0
// PURPOSE: Transaction preview UI (Structural Only - Logic Validation)

import SwiftUI

// MARK: - Transaction Preview View (Structural)

/// Structural UI for transaction preview.
///
/// **Note: This view is intentionally unstyled.**
/// - Raw List displaying simulation status and gas estimates
/// - Buttons bound to ViewModel actions
/// - No colors, icons, fonts, or layout polish
@available(iOS 17.0, macOS 14.0, *)
public struct TxPreviewView: View {
    
    // MARK: - Properties
    
    @Bindable var viewModel: TxPreviewViewModel
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Initialization
    
    public init(viewModel: TxPreviewViewModel) {
        self.viewModel = viewModel
    }
    
    // MARK: - Body
    
    public var body: some View {
        NavigationStack {
            List {
                // Transaction Details Section
                transactionDetailsSection
                
                // Simulation Section
                simulationSection
                
                // Gas & Protection Section
                gasAndProtectionSection
                
                // Balance Changes Section
                balanceChangesSection
                
                // Actions Section
                actionsSection
            }
            .navigationTitle("Transaction Preview")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.cancel()
                        dismiss()
                    }
                    .disabled(viewModel.state.isProcessing)
                }
            }
            #endif
        }
    }
    
    // MARK: - Sections
    
    /// Transaction details section
    private var transactionDetailsSection: some View {
        Section("Transaction Details") {
            LabeledContent("Asset", value: viewModel.asset.symbol)
            LabeledContent("Recipient", value: viewModel.shortRecipient)
            LabeledContent("Amount", value: viewModel.formattedAmount)
            if !viewModel.data.isEmpty {
                LabeledContent("Data", value: "\(viewModel.data.count) bytes")
            }
        }
    }
    
    /// Simulation status section
    private var simulationSection: some View {
        Section("Simulation") {
            // Status text
            Text(viewModel.state.statusText)
            
            // State indicator
            switch viewModel.state {
            case .idle:
                Button("Simulate Transaction") {
                    Task {
                        await viewModel.simulate()
                    }
                }
                
            case .simulating:
                ProgressView()
                
            case .simulationFailed(let error):
                VStack(alignment: .leading) {
                    Text("Error: \(error)")
                    Button("Retry Simulation") {
                        Task {
                            await viewModel.simulate()
                        }
                    }
                }
                
            case .readyToSign(let receipt):
                VStack(alignment: .leading) {
                    Text("Receipt ID: \(receipt.receiptId.prefix(8))...")
                    if receipt.isExpired {
                        Text("Receipt Expired - Re-simulate")
                    } else {
                        Text("Valid until: \(receipt.expiresAt.formatted())")
                    }
                }
                
            case .signing, .broadcasting:
                ProgressView()
                
            case .broadcasted(let txHash):
                VStack(alignment: .leading) {
                    Text("Transaction Hash:")
                    Text(txHash)
                        .font(.caption)
                }
                
            case .failed(let error):
                VStack(alignment: .leading) {
                    Text("Failed: \(error)")
                    Button("Try Again") {
                        viewModel.reset()
                    }
                }
            }
        }
    }
    
    /// Gas and protection section
    private var gasAndProtectionSection: some View {
        Section("Gas & Protection") {
            LabeledContent("Estimated Gas", value: viewModel.estimatedGasCost)
            LabeledContent("Total Cost", value: viewModel.totalCost)
            
            // MEV Protection Status
            VStack(alignment: .leading) {
                Text("MEV Protection")
                Text(viewModel.mevProtectionStatus.description)
                    .font(.caption)
            }
        }
    }
    
    /// Balance changes section
    private var balanceChangesSection: some View {
        Section("Expected Balance Changes") {
            if viewModel.balanceChanges.isEmpty {
                Text("Simulate to see expected changes")
            } else {
                ForEach(Array(viewModel.balanceChanges.keys.sorted()), id: \.self) { address in
                    if let change = viewModel.balanceChanges[address] {
                        LabeledContent(shortenAddress(address), value: change)
                    }
                }
            }
        }
    }
    
    /// Actions section with slide to confirm
    private var actionsSection: some View {
        Section("Confirm") {
            if viewModel.canConfirmTransaction {
                VStack(spacing: 12) {
                    // Progress indicator
                    Text("Slide to Confirm: \(Int(viewModel.confirmProgress * 100))%")
                    
                    // Slide to confirm button (structural)
                    SlideToConfirmButton(
                        progress: Binding(
                            get: { viewModel.confirmProgress },
                            set: { viewModel.updateSlideProgress($0) }
                        ),
                        isEnabled: viewModel.canConfirmTransaction
                    ) {
                        Task {
                            await viewModel.confirm()
                        }
                    }
                    .frame(height: 50)
                }
            } else if viewModel.state == .idle {
                Text("Simulate first to enable confirmation")
            } else if viewModel.state.isProcessing {
                Text("Processing...")
            } else if viewModel.state.isFinal {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    /// Shorten an address for display
    private func shortenAddress(_ address: String) -> String {
        guard address.count > 12 else { return address }
        return "\(address.prefix(6))...\(address.suffix(4))"
    }
}

// MARK: - Transaction Success View

/// Simple success view after broadcast
@available(iOS 17.0, macOS 14.0, *)
public struct TransactionSuccessView: View {
    let txHash: String
    let chain: AssetChain
    let onDone: () -> Void
    
    public init(txHash: String, chain: AssetChain, onDone: @escaping () -> Void) {
        self.txHash = txHash
        self.chain = chain
        self.onDone = onDone
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            Text("Transaction Sent")
            Text("Hash: \(txHash)")
                .font(.caption)
            Text("Chain: \(chain.displayName)")
            Button("Done", action: onDone)
        }
        .padding()
    }
}

// MARK: - Transaction Failed View

/// Simple failure view
@available(iOS 17.0, macOS 14.0, *)
public struct TransactionFailedView: View {
    let error: String
    let onRetry: () -> Void
    let onDismiss: () -> Void
    
    public init(error: String, onRetry: @escaping () -> Void, onDismiss: @escaping () -> Void) {
        self.error = error
        self.onRetry = onRetry
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            Text("Transaction Failed")
            Text(error)
                .font(.caption)
            HStack {
                Button("Retry", action: onRetry)
                Button("Dismiss", action: onDismiss)
            }
        }
        .padding()
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

