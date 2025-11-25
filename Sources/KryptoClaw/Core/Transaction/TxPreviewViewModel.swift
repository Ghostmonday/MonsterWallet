// MODULE: TxPreviewViewModel
// VERSION: 1.0.0
// PURPOSE: Transaction preview state machine with "Simulation First" enforcement

import Foundation
import SwiftUI

// MARK: - Transaction State Machine

/// State machine for transaction flow
/// Enforces: Idle → Simulating → ReadyToSign → Signing → Broadcasted
public enum TransactionState: Equatable, Sendable {
    case idle
    case simulating
    case simulationFailed(error: String)
    case readyToSign(receipt: SimulationReceipt)
    case signing
    case broadcasting
    case broadcasted(txHash: String)
    case failed(error: String)
    
    /// Human-readable status text
    public var statusText: String {
        switch self {
        case .idle:
            return "Ready to simulate"
        case .simulating:
            return "Simulating transaction..."
        case .simulationFailed(let error):
            return "Simulation failed: \(error)"
        case .readyToSign:
            return "Ready to sign"
        case .signing:
            return "Signing transaction..."
        case .broadcasting:
            return "Broadcasting to network..."
        case .broadcasted(let txHash):
            return "Confirmed: \(txHash.prefix(10))..."
        case .failed(let error):
            return "Failed: \(error)"
        }
    }
    
    /// Whether the transaction can be confirmed
    public var canConfirm: Bool {
        if case .readyToSign = self { return true }
        return false
    }
    
    /// Whether the transaction is in a final state
    public var isFinal: Bool {
        switch self {
        case .broadcasted, .failed:
            return true
        default:
            return false
        }
    }
    
    /// Whether the transaction is processing
    public var isProcessing: Bool {
        switch self {
        case .simulating, .signing, .broadcasting:
            return true
        default:
            return false
        }
    }
}

// MARK: - Transaction Preview ViewModel

/// ViewModel managing the transaction preview and confirmation flow.
///
/// **Security: Simulation First Policy**
/// - The `confirm()` function is DISABLED unless state == .readyToSign
/// - A valid SimulationReceipt is REQUIRED to transition to readyToSign
/// - Receipt verification occurs before signing is allowed
///
/// **State Machine:**
/// ```
/// Idle → Simulating → ReadyToSign → Signing → Broadcasting → Broadcasted
///              ↓                        ↓           ↓
///       SimulationFailed             Failed      Failed
/// ```
@available(iOS 17.0, macOS 14.0, *)
@Observable
@MainActor
public final class TxPreviewViewModel {
    
    // MARK: - Transaction Inputs
    
    /// The asset being sent
    public var asset: Asset
    
    /// Recipient address
    public var recipient: String
    
    /// Amount to send (in human-readable format)
    public var amount: String
    
    /// Optional data payload (for contract calls)
    public var data: Data
    
    // MARK: - State
    
    /// Current transaction state
    public private(set) var state: TransactionState = .idle
    
    /// Simulation receipt (only valid in readyToSign state)
    public private(set) var simulationReceipt: SimulationReceipt?
    
    /// MEV protection status
    public private(set) var mevProtectionStatus: MEVProtectionStatus = .unavailable
    
    /// Estimated gas cost in native currency
    public private(set) var estimatedGasCost: String = "-"
    
    /// Expected balance changes
    public private(set) var balanceChanges: [String: String] = [:]
    
    /// Transaction hash after broadcast
    public private(set) var transactionHash: String?
    
    /// Slide to confirm progress (0.0 to 1.0)
    public var confirmProgress: CGFloat = 0.0
    
    // MARK: - Dependencies
    
    private let simulationService: TransactionSimulationService
    private let rpcRouter: RPCRouter
    private let senderAddress: String
    
    // MARK: - Initialization
    
    public init(
        asset: Asset,
        recipient: String,
        amount: String,
        data: Data = Data(),
        senderAddress: String,
        simulationService: TransactionSimulationService,
        rpcRouter: RPCRouter
    ) {
        self.asset = asset
        self.recipient = recipient
        self.amount = amount
        self.data = data
        self.senderAddress = senderAddress
        self.simulationService = simulationService
        self.rpcRouter = rpcRouter
    }
    
    // MARK: - Actions
    
    /// Simulate the transaction
    /// Must be called before confirm() can be executed
    public func simulate() async {
        guard !state.isProcessing else { return }
        
        state = .simulating
        
        // Convert amount to smallest unit
        let valueInSmallestUnit = convertToSmallestUnit(amount: amount, decimals: asset.decimals)
        
        let request = SimulationRequest(
            from: senderAddress,
            to: recipient,
            value: valueInSmallestUnit,
            data: data,
            chain: asset.chain
        )
        
        let result: TxSimulationResult = await simulationService.simulate(request: request)
        
        switch result {
        case .success(let receipt):
            simulationReceipt = receipt
            estimatedGasCost = formatGasCost(receipt.gasEstimate, chain: asset.chain)
            balanceChanges = receipt.balanceChanges
            mevProtectionStatus = await rpcRouter.getMEVProtectionStatus(for: asset.chain)
            state = .readyToSign(receipt: receipt)
            
        case .failure(let error, let revertReason):
            let errorMessage = revertReason ?? error
            state = .simulationFailed(error: errorMessage)
            simulationReceipt = nil
        }
    }
    
    /// Confirm and sign the transaction
    /// **CRITICAL: This function is DISABLED unless state == .readyToSign**
    public func confirm() async {
        // SECURITY: Guard against execution without valid simulation
        guard case .readyToSign(let receipt) = state else {
            // This should never happen if UI is correctly bound to canConfirm
            assertionFailure("confirm() called without valid simulation receipt")
            return
        }
        
        // Verify receipt is still valid
        let request = SimulationRequest(
            from: senderAddress,
            to: recipient,
            value: convertToSmallestUnit(amount: amount, decimals: asset.decimals),
            data: data,
            chain: asset.chain
        )
        
        let isValid = await simulationService.verifyReceipt(receipt, for: request)
        guard isValid else {
            state = .failed(error: "Simulation receipt expired or invalid")
            return
        }
        
        // Transition to signing
        state = .signing
        
        // TODO: Implement actual signing with WalletCoreManager
        // For now, simulate the signing process
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Transition to broadcasting
        state = .broadcasting
        
        // Mock broadcast
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        
        // Generate mock transaction hash
        let mockTxHash = "0x" + UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
        transactionHash = mockTxHash
        state = .broadcasted(txHash: mockTxHash)
        
        // Reset confirm progress
        confirmProgress = 0.0
    }
    
    /// Reset the transaction state
    public func reset() {
        state = .idle
        simulationReceipt = nil
        transactionHash = nil
        estimatedGasCost = "-"
        balanceChanges = [:]
        confirmProgress = 0.0
    }
    
    /// Cancel the transaction (if possible)
    public func cancel() {
        guard !state.isFinal, !state.isProcessing else { return }
        reset()
    }
    
    // MARK: - Slide to Confirm
    
    /// Update slide progress and trigger confirm if threshold reached
    public func updateSlideProgress(_ progress: CGFloat) {
        guard state.canConfirm else {
            confirmProgress = 0.0
            return
        }
        
        confirmProgress = min(max(progress, 0.0), 1.0)
        
        // Trigger confirm when threshold is reached
        if confirmProgress >= 0.95 {
            Task {
                await confirm()
            }
        }
    }
    
    /// Reset slide progress
    public func resetSlideProgress() {
        guard confirmProgress < 0.95 else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            confirmProgress = 0.0
        }
    }
    
    // MARK: - Computed Properties
    
    /// Whether the confirm action is available
    public var canConfirmTransaction: Bool {
        state.canConfirm
    }
    
    /// Formatted amount with symbol
    public var formattedAmount: String {
        "\(amount) \(asset.symbol)"
    }
    
    /// Shortened recipient address
    public var shortRecipient: String {
        guard recipient.count > 12 else { return recipient }
        return "\(recipient.prefix(6))...\(recipient.suffix(4))"
    }
    
    /// Total cost (amount + gas)
    public var totalCost: String {
        guard let receipt = simulationReceipt else { return "-" }
        let gasCost = formatGasCost(receipt.gasEstimate, chain: asset.chain)
        return "\(formattedAmount) + \(gasCost) gas"
    }
    
    // MARK: - Private Helpers
    
    /// Convert human-readable amount to smallest unit (wei, satoshi, lamport)
    private func convertToSmallestUnit(amount: String, decimals: Int) -> String {
        guard let decimalValue = Decimal(string: amount) else { return "0" }
        let multiplier = pow(Decimal(10), decimals)
        let smallestUnit = decimalValue * multiplier
        
        // Convert to integer string
        var result = smallestUnit
        var rounded: Decimal = 0
        NSDecimalRound(&rounded, &result, 0, .plain)
        
        return "\(rounded)"
    }
    
    /// Format gas cost for display
    private func formatGasCost(_ gas: UInt64, chain: AssetChain) -> String {
        switch chain {
        case .ethereum:
            // Convert gas units to ETH (assuming 30 gwei gas price)
            let gasCostWei = Decimal(gas) * Decimal(30_000_000_000)
            let gasCostEth = gasCostWei / pow(Decimal(10), 18)
            return String(format: "%.6f ETH", NSDecimalNumber(decimal: gasCostEth).doubleValue)
            
        case .bitcoin:
            // Gas is already in satoshis
            let satoshis = Decimal(gas)
            let btc = satoshis / pow(Decimal(10), 8)
            return String(format: "%.8f BTC", NSDecimalNumber(decimal: btc).doubleValue)
            
        case .solana:
            // Gas is in lamports
            let lamports = Decimal(gas)
            let sol = lamports / pow(Decimal(10), 9)
            return String(format: "%.9f SOL", NSDecimalNumber(decimal: sol).doubleValue)
        }
    }
}

// MARK: - Factory

@available(iOS 17.0, macOS 14.0, *)
extension TxPreviewViewModel {
    
    /// Create a view model for a simple transfer
    public static func forTransfer(
        asset: Asset,
        recipient: String,
        amount: String,
        senderAddress: String,
        rpcRouter: RPCRouter
    ) -> TxPreviewViewModel {
        let simulationService = TransactionSimulationService(rpcRouter: rpcRouter)
        
        return TxPreviewViewModel(
            asset: asset,
            recipient: recipient,
            amount: amount,
            senderAddress: senderAddress,
            simulationService: simulationService,
            rpcRouter: rpcRouter
        )
    }
}

