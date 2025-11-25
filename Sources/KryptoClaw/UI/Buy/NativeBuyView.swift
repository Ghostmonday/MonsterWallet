// MODULE: NativeBuyView
// VERSION: 1.0.0
// PURPOSE: Native headless on-ramp UI with state machine flow

import SwiftUI

// MARK: - Buy Flow State Machine

/// State machine for the buy flow
public enum BuyFlowState: Equatable, Sendable {
    case inputAmount
    case fetchingQuote
    case selectPayment
    case confirmingOrder
    case processing
    case success(transactionId: String)
    case failure(error: String)
    
    public var title: String {
        switch self {
        case .inputAmount: return "Buy Crypto"
        case .fetchingQuote: return "Getting Quote"
        case .selectPayment: return "Payment Method"
        case .confirmingOrder: return "Confirm Order"
        case .processing: return "Processing"
        case .success: return "Success!"
        case .failure: return "Order Failed"
        }
    }
    
    public var canGoBack: Bool {
        switch self {
        case .inputAmount, .processing, .success, .failure:
            return false
        default:
            return true
        }
    }
}

// MARK: - Payment Method

/// Supported payment methods
public enum PaymentMethod: String, CaseIterable, Identifiable, Sendable {
    case applePay = "Apple Pay"
    case card = "Credit/Debit Card"
    case bankTransfer = "Bank Transfer"
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .applePay: return "apple.logo"
        case .card: return "creditcard.fill"
        case .bankTransfer: return "building.columns.fill"
        }
    }
    
    public var processingTime: String {
        switch self {
        case .applePay: return "Instant"
        case .card: return "1-3 minutes"
        case .bankTransfer: return "1-3 business days"
        }
    }
    
    public var fee: Decimal {
        switch self {
        case .applePay: return 0.015 // 1.5%
        case .card: return 0.029 // 2.9%
        case .bankTransfer: return 0.01 // 1%
        }
    }
}

// MARK: - Buy Quote

/// Quote for a crypto purchase
public struct BuyQuote: Sendable {
    public let fiatAmount: Decimal
    public let cryptoAmount: Decimal
    public let asset: Asset
    public let exchangeRate: Decimal
    public let networkFee: Decimal
    public let processingFee: Decimal
    public let totalCost: Decimal
    public let expiresAt: Date
    
    public var isExpired: Bool {
        Date() > expiresAt
    }
    
    public init(
        fiatAmount: Decimal,
        cryptoAmount: Decimal,
        asset: Asset,
        exchangeRate: Decimal,
        networkFee: Decimal,
        processingFee: Decimal,
        totalCost: Decimal,
        expiresAt: Date
    ) {
        self.fiatAmount = fiatAmount
        self.cryptoAmount = cryptoAmount
        self.asset = asset
        self.exchangeRate = exchangeRate
        self.networkFee = networkFee
        self.processingFee = processingFee
        self.totalCost = totalCost
        self.expiresAt = expiresAt
    }
}

// MARK: - Buy Flow ViewModel

@available(iOS 15.0, macOS 12.0, *)
@MainActor
public class BuyFlowViewModel: ObservableObject {
    
    // MARK: - State
    
    @Published public var state: BuyFlowState = .inputAmount
    @Published public var fiatAmount: String = ""
    @Published public var selectedAsset: Asset = .native(chain: .ethereum)
    @Published public var selectedPaymentMethod: PaymentMethod = .applePay
    @Published public var quote: BuyQuote?
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?
    
    // MARK: - Available Options
    
    public let supportedAssets: [Asset] = [
        .native(chain: .ethereum),
        .native(chain: .bitcoin),
        .native(chain: .solana),
        .usdc
    ]
    
    public let fiatCurrency: String = "USD"
    public let minAmount: Decimal = 10
    public let maxAmount: Decimal = 10000
    
    // MARK: - Computed Properties
    
    public var fiatAmountDecimal: Decimal? {
        Decimal(string: fiatAmount)
    }
    
    public var isValidAmount: Bool {
        guard let amount = fiatAmountDecimal else { return false }
        return amount >= minAmount && amount <= maxAmount
    }
    
    public var estimatedCrypto: String {
        guard let amount = fiatAmountDecimal, amount > 0 else { return "0" }
        // Mock estimation - in production would use real rates
        let mockRate: Decimal
        switch selectedAsset.symbol {
        case "ETH": mockRate = 2000
        case "BTC": mockRate = 40000
        case "SOL": mockRate = 100
        case "USDC": mockRate = 1
        default: mockRate = 1
        }
        let crypto = amount / mockRate
        return String(format: "%.6f", NSDecimalNumber(decimal: crypto).doubleValue)
    }
    
    public var processingFee: Decimal {
        guard let amount = fiatAmountDecimal else { return 0 }
        return amount * selectedPaymentMethod.fee
    }
    
    public var networkFee: Decimal {
        switch selectedAsset.chain {
        case .ethereum: return 5
        case .bitcoin: return 2
        case .solana: return 0.001
        }
    }
    
    public var totalCost: Decimal {
        (fiatAmountDecimal ?? 0) + processingFee + networkFee
    }
    
    // MARK: - Actions
    
    /// Proceed to quote fetching
    public func fetchQuote() async {
        guard isValidAmount else { return }
        
        state = .fetchingQuote
        isLoading = true
        
        // Simulate API call
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        
        guard let amount = fiatAmountDecimal else {
            state = .failure(error: "Invalid amount")
            return
        }
        
        // Mock quote generation
        let mockRate: Decimal
        switch selectedAsset.symbol {
        case "ETH": mockRate = 2000
        case "BTC": mockRate = 40000
        case "SOL": mockRate = 100
        case "USDC": mockRate = 1
        default: mockRate = 1
        }
        
        let cryptoAmount = amount / mockRate
        let processingFee = amount * selectedPaymentMethod.fee
        let networkFee = self.networkFee
        
        quote = BuyQuote(
            fiatAmount: amount,
            cryptoAmount: cryptoAmount,
            asset: selectedAsset,
            exchangeRate: mockRate,
            networkFee: networkFee,
            processingFee: processingFee,
            totalCost: amount + processingFee + networkFee,
            expiresAt: Date().addingTimeInterval(300) // 5 minutes
        )
        
        isLoading = false
        state = .selectPayment
        HapticEngine.shared.play(.success)
    }
    
    /// Select payment method and proceed to confirmation
    public func selectPayment(_ method: PaymentMethod) {
        selectedPaymentMethod = method
        
        // Recalculate quote with new payment method
        if let oldQuote = quote {
            let newProcessingFee = oldQuote.fiatAmount * method.fee
            quote = BuyQuote(
                fiatAmount: oldQuote.fiatAmount,
                cryptoAmount: oldQuote.cryptoAmount,
                asset: oldQuote.asset,
                exchangeRate: oldQuote.exchangeRate,
                networkFee: oldQuote.networkFee,
                processingFee: newProcessingFee,
                totalCost: oldQuote.fiatAmount + newProcessingFee + oldQuote.networkFee,
                expiresAt: oldQuote.expiresAt
            )
        }
        
        state = .confirmingOrder
        HapticEngine.shared.play(.selection)
    }
    
    /// Confirm and execute the purchase
    public func confirmPurchase() async {
        guard let quote = quote, !quote.isExpired else {
            state = .failure(error: "Quote expired. Please try again.")
            return
        }
        
        state = .processing
        isLoading = true
        HapticEngine.shared.play(.cryptoSwapLock)
        
        // Simulate processing
        try? await Task.sleep(nanoseconds: 3_000_000_000)
        
        // Mock success (90% success rate for demo)
        let isSuccess = Int.random(in: 1...10) <= 9
        
        isLoading = false
        
        if isSuccess {
            let txId = "TX\(UUID().uuidString.prefix(8).uppercased())"
            state = .success(transactionId: txId)
            HapticEngine.shared.play(.transactionSent)
        } else {
            state = .failure(error: "Payment processing failed. Your card was not charged.")
            HapticEngine.shared.play(.error)
        }
    }
    
    /// Go back to previous state
    public func goBack() {
        switch state {
        case .selectPayment:
            state = .inputAmount
        case .confirmingOrder:
            state = .selectPayment
        default:
            break
        }
        HapticEngine.shared.play(.selection)
    }
    
    /// Reset the flow
    public func reset() {
        state = .inputAmount
        fiatAmount = ""
        quote = nil
        isLoading = false
        errorMessage = nil
    }
    
    /// Set a preset amount
    public func setPresetAmount(_ amount: Decimal) {
        fiatAmount = "\(amount)"
        HapticEngine.shared.play(.selection)
    }
}

// MARK: - Native Buy View

@available(iOS 15.0, macOS 12.0, *)
public struct NativeBuyView: View {
    
    @StateObject private var viewModel = BuyFlowViewModel()
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    public init() {}
    
    public var body: some View {
        let theme = themeManager.currentTheme
        
        NavigationStack {
            ZStack {
                theme.backgroundMain
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Progress Indicator
                    progressIndicator(theme: theme)
                    
                    // Content
                    ScrollView {
                        VStack(spacing: 24) {
                            switch viewModel.state {
                            case .inputAmount:
                                amountInputView(theme: theme)
                            case .fetchingQuote:
                                loadingView(theme: theme, message: "Getting the best rate...")
                            case .selectPayment:
                                paymentSelectionView(theme: theme)
                            case .confirmingOrder:
                                orderConfirmationView(theme: theme)
                            case .processing:
                                loadingView(theme: theme, message: "Processing your order...")
                            case .success(let txId):
                                successView(theme: theme, transactionId: txId)
                            case .failure(let error):
                                failureView(theme: theme, error: error)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle(viewModel.state.title)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if viewModel.state.canGoBack {
                        Button("Back") {
                            viewModel.goBack()
                        }
                        .foregroundColor(theme.accentColor)
                    } else if case .inputAmount = viewModel.state {
                        Button("Cancel") {
                            dismiss()
                        }
                        .foregroundColor(theme.textSecondary)
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    if case .success = viewModel.state {
                        Button("Done") {
                            dismiss()
                        }
                        .foregroundColor(theme.accentColor)
                    }
                }
            }
        }
    }
    
    // MARK: - Progress Indicator
    
    @ViewBuilder
    private func progressIndicator(theme: ThemeProtocolV2) -> some View {
        let steps: [BuyFlowState] = [.inputAmount, .selectPayment, .confirmingOrder, .processing]
        let currentIndex = steps.firstIndex(where: { $0 == viewModel.state }) ?? 0
        
        HStack(spacing: 4) {
            ForEach(0..<4, id: \.self) { index in
                Capsule()
                    .fill(index <= currentIndex ? theme.accentColor : theme.borderColor)
                    .frame(height: 4)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    // MARK: - Amount Input View
    
    @ViewBuilder
    private func amountInputView(theme: ThemeProtocolV2) -> some View {
        VStack(spacing: 24) {
            // Asset Selector
            Menu {
                ForEach(viewModel.supportedAssets, id: \.id) { asset in
                    Button {
                        viewModel.selectedAsset = asset
                    } label: {
                        Label(asset.name, systemImage: asset.chain == .bitcoin ? "bitcoinsign.circle" : "circle.fill")
                    }
                }
            } label: {
                HStack {
                    AsyncImage(url: viewModel.selectedAsset.iconURL) { image in
                        image.resizable().aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Circle().fill(theme.backgroundSecondary)
                    }
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                    
                    Text(viewModel.selectedAsset.name)
                        .font(theme.font(style: .headline))
                        .foregroundColor(theme.textPrimary)
                    
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                }
                .padding()
                .background(theme.cardBackground)
                .cornerRadius(theme.cornerRadius)
            }
            
            // Amount Input
            VStack(spacing: 8) {
                HStack(alignment: .center, spacing: 4) {
                    Text("$")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(theme.textSecondary)
                    
                    TextField("0", text: $viewModel.fiatAmount)
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(theme.textPrimary)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
                
                Text("≈ \(viewModel.estimatedCrypto) \(viewModel.selectedAsset.symbol)")
                    .font(theme.font(style: .subheadline))
                    .foregroundColor(theme.textSecondary)
            }
            .padding(.vertical, 32)
            
            // Preset Amounts
            HStack(spacing: 12) {
                ForEach([25, 50, 100, 500] as [Decimal], id: \.self) { amount in
                    Button {
                        viewModel.setPresetAmount(amount)
                    } label: {
                        Text("$\(amount)")
                            .font(theme.font(style: .subheadline))
                            .fontWeight(.medium)
                            .foregroundColor(theme.textPrimary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(theme.backgroundSecondary)
                            .cornerRadius(theme.cornerRadius)
                    }
                }
            }
            
            // Limits info
            Text("Min $\(viewModel.minAmount) · Max $\(viewModel.maxAmount)")
                .font(theme.font(style: .caption))
                .foregroundColor(theme.textSecondary)
            
            Spacer(minLength: 40)
            
            // Continue Button
            Button {
                Task {
                    await viewModel.fetchQuote()
                }
            } label: {
                Text("Continue")
                    .font(theme.font(style: .headline))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.isValidAmount ? theme.accentColor : theme.borderColor)
                    .cornerRadius(theme.cornerRadius)
            }
            .disabled(!viewModel.isValidAmount)
        }
    }
    
    // MARK: - Payment Selection View
    
    @ViewBuilder
    private func paymentSelectionView(theme: ThemeProtocolV2) -> some View {
        VStack(spacing: 20) {
            // Quote Summary
            if let quote = viewModel.quote {
                VStack(spacing: 8) {
                    Text("You'll receive")
                        .font(theme.font(style: .subheadline))
                        .foregroundColor(theme.textSecondary)
                    
                    Text("\(quote.cryptoAmount.formatAsCurrency(symbol: "", maximumFractionDigits: 6)) \(quote.asset.symbol)")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(theme.textPrimary)
                    
                    Text("@ $\(quote.exchangeRate) per \(quote.asset.symbol)")
                        .font(theme.font(style: .caption))
                        .foregroundColor(theme.textSecondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(theme.cardBackground)
                .cornerRadius(theme.cornerRadius)
            }
            
            Text("Select Payment Method")
                .font(theme.font(style: .headline))
                .foregroundColor(theme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Payment Methods
            ForEach(PaymentMethod.allCases) { method in
                Button {
                    viewModel.selectPayment(method)
                } label: {
                    HStack {
                        Image(systemName: method.icon)
                            .font(.title2)
                            .foregroundColor(theme.accentColor)
                            .frame(width: 40)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(method.rawValue)
                                .font(theme.font(style: .body))
                                .fontWeight(.medium)
                                .foregroundColor(theme.textPrimary)
                            
                            Text(method.processingTime)
                                .font(theme.font(style: .caption))
                                .foregroundColor(theme.textSecondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(NSDecimalNumber(decimal: method.fee * 100).doubleValue, specifier: "%.1f")% fee")
                                .font(theme.font(style: .caption))
                                .foregroundColor(theme.textSecondary)
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(theme.textSecondary)
                        }
                    }
                    .padding()
                    .background(theme.cardBackground)
                    .cornerRadius(theme.cornerRadius)
                    .overlay(
                        RoundedRectangle(cornerRadius: theme.cornerRadius)
                            .stroke(viewModel.selectedPaymentMethod == method ? theme.accentColor : theme.borderColor, lineWidth: 1)
                    )
                }
            }
        }
    }
    
    // MARK: - Order Confirmation View
    
    @ViewBuilder
    private func orderConfirmationView(theme: ThemeProtocolV2) -> some View {
        VStack(spacing: 24) {
            if let quote = viewModel.quote {
                // Order Summary Card
                VStack(spacing: 16) {
                    // You Pay
                    HStack {
                        Text("You Pay")
                            .foregroundColor(theme.textSecondary)
                        Spacer()
                        Text(quote.fiatAmount.formatAsCurrency())
                            .fontWeight(.medium)
                            .foregroundColor(theme.textPrimary)
                    }
                    
                    Divider()
                    
                    // You Receive
                    HStack {
                        Text("You Receive")
                            .foregroundColor(theme.textSecondary)
                        Spacer()
                        Text("\(quote.cryptoAmount.formatAsCurrency(symbol: "", maximumFractionDigits: 6)) \(quote.asset.symbol)")
                            .fontWeight(.bold)
                            .foregroundColor(theme.accentColor)
                    }
                    
                    Divider()
                    
                    // Fees
                    HStack {
                        Text("Processing Fee")
                            .foregroundColor(theme.textSecondary)
                        Spacer()
                        Text(quote.processingFee.formatAsCurrency())
                            .foregroundColor(theme.textPrimary)
                    }
                    
                    HStack {
                        Text("Network Fee")
                            .foregroundColor(theme.textSecondary)
                        Spacer()
                        Text(quote.networkFee.formatAsCurrency())
                            .foregroundColor(theme.textPrimary)
                    }
                    
                    Divider()
                    
                    // Total
                    HStack {
                        Text("Total")
                            .font(theme.font(style: .headline))
                            .foregroundColor(theme.textPrimary)
                        Spacer()
                        Text(quote.totalCost.formatAsCurrency())
                            .font(theme.font(style: .headline))
                            .fontWeight(.bold)
                            .foregroundColor(theme.textPrimary)
                    }
                }
                .font(theme.font(style: .body))
                .padding()
                .background(theme.cardBackground)
                .cornerRadius(theme.cornerRadius)
                
                // Payment Method
                HStack {
                    Image(systemName: viewModel.selectedPaymentMethod.icon)
                        .foregroundColor(theme.accentColor)
                    Text(viewModel.selectedPaymentMethod.rawValue)
                        .foregroundColor(theme.textPrimary)
                    Spacer()
                    Button("Change") {
                        viewModel.goBack()
                    }
                    .font(theme.font(style: .caption))
                    .foregroundColor(theme.accentColor)
                }
                .padding()
                .background(theme.cardBackground)
                .cornerRadius(theme.cornerRadius)
                
                // Timer
                Text("Quote expires in 5:00")
                    .font(theme.font(style: .caption))
                    .foregroundColor(theme.warningColor)
                
                Spacer()
                
                // Confirm Button
                Button {
                    Task {
                        await viewModel.confirmPurchase()
                    }
                } label: {
                    HStack {
                        Image(systemName: viewModel.selectedPaymentMethod.icon)
                        Text("Pay \(quote.totalCost.formatAsCurrency())")
                    }
                    .font(theme.font(style: .headline))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(theme.accentColor)
                    .cornerRadius(theme.cornerRadius)
                }
            }
        }
    }
    
    // MARK: - Loading View
    
    @ViewBuilder
    private func loadingView(theme: ThemeProtocolV2, message: String) -> some View {
        VStack(spacing: 24) {
            Spacer()
            
            ProgressView()
                .scaleEffect(1.5)
                .tint(theme.accentColor)
            
            Text(message)
                .font(theme.font(style: .body))
                .foregroundColor(theme.textSecondary)
            
            Spacer()
        }
    }
    
    // MARK: - Success View
    
    @ViewBuilder
    private func successView(theme: ThemeProtocolV2, transactionId: String) -> some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(theme.successColor)
            
            Text("Purchase Complete!")
                .font(theme.font(style: .title))
                .fontWeight(.bold)
                .foregroundColor(theme.textPrimary)
            
            if let quote = viewModel.quote {
                Text("You purchased \(quote.cryptoAmount.formatAsCurrency(symbol: "", maximumFractionDigits: 6)) \(quote.asset.symbol)")
                    .font(theme.font(style: .body))
                    .foregroundColor(theme.textSecondary)
            }
            
            // Transaction ID
            VStack(spacing: 4) {
                Text("Transaction ID")
                    .font(theme.font(style: .caption))
                    .foregroundColor(theme.textSecondary)
                Text(transactionId)
                    .font(theme.addressFont)
                    .foregroundColor(theme.textPrimary)
            }
            .padding()
            .background(theme.cardBackground)
            .cornerRadius(theme.cornerRadius)
            
            Text("Your crypto will arrive in your wallet within a few minutes.")
                .font(theme.font(style: .caption))
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
    }
    
    // MARK: - Failure View
    
    @ViewBuilder
    private func failureView(theme: ThemeProtocolV2, error: String) -> some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(theme.errorColor)
            
            Text("Purchase Failed")
                .font(theme.font(style: .title))
                .fontWeight(.bold)
                .foregroundColor(theme.textPrimary)
            
            Text(error)
                .font(theme.font(style: .body))
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)
            
            Spacer()
            
            Button {
                viewModel.reset()
            } label: {
                Text("Try Again")
                    .font(theme.font(style: .headline))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(theme.accentColor)
                    .cornerRadius(theme.cornerRadius)
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
@available(iOS 15.0, macOS 12.0, *)
struct NativeBuyView_Previews: PreviewProvider {
    static var previews: some View {
        NativeBuyView()
            .environmentObject(ThemeManager())
    }
}
#endif

