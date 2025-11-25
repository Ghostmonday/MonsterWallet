// MODULE: SwapView
// VERSION: 2.0.0
// PURPOSE: Structural swap interface with simulation-first safety

import BigInt
import SwiftUI

// MARK: - Swap View (Structural)

/// Structural swap interface with simulation integration.
///
/// **Features:**
/// - Asset picker (From/To)
/// - Amount input
/// - Quote details (Rate, Slippage, Fees)
/// - Simulation status
/// - Swap button (disabled until simulation passes)
@available(iOS 15.0, macOS 12.0, *)
struct SwapViewV2: View {
    @StateObject private var viewModel: SwapViewModel
    @EnvironmentObject var wsm: WalletStateManager
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var showFromAssetPicker = false
    @State private var showToAssetPicker = false
    @State private var showSlippageSettings = false
    @State private var showQuoteComparison = false
    
    init(quoteService: QuoteService, swapRouter: SwapRouter, walletStateManager: WalletStateManager) {
        let vm = SwapViewModel(
            quoteService: quoteService,
            swapRouter: swapRouter,
            walletAddress: { walletStateManager.currentAddress },
            signTransaction: { tx in
                // Placeholder for signing - integrate with actual signer
                return Data()
            }
        )
        _viewModel = StateObject(wrappedValue: vm)
    }
    
    var body: some View {
        let theme = themeManager.currentTheme
        
        ScrollView {
            VStack(spacing: theme.spacingL) {
                headerSection
                
                fromAssetSection
                
                swapDirectionButton
                
                toAssetSection
                
                if viewModel.state.currentQuote != nil {
                    quoteDetailsSection
                }
                
                simulationStatusSection
                
                if !viewModel.allQuotes.isEmpty {
                    alternativeQuotesSection
                }
                
                actionButton
                
                Spacer(minLength: theme.spacingXL)
            }
            .padding()
        }
        .sheet(isPresented: $showFromAssetPicker) {
            AssetPickerView(
                selectedAsset: $viewModel.fromAsset,
                excludedAsset: viewModel.toAsset,
                title: "Select Source Asset"
            )
        }
        .sheet(isPresented: $showToAssetPicker) {
            AssetPickerView(
                selectedAsset: $viewModel.toAsset,
                excludedAsset: viewModel.fromAsset,
                title: "Select Destination Asset"
            )
        }
        .sheet(isPresented: $showSlippageSettings) {
            SlippageSettingsView(slippage: $viewModel.slippageTolerance)
        }
        .alert("Swap Error", isPresented: showErrorBinding) {
            Button("OK") {
                if case .error = viewModel.state {
                    viewModel.cancel()
                }
            }
        } message: {
            if case .error(let error) = viewModel.state {
                Text(error.localizedDescription)
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        let theme = themeManager.currentTheme
        
        return HStack {
            Text("Swap")
                .font(theme.font(style: .title2))
                .fontWeight(.bold)
                .foregroundColor(theme.textPrimary)
            
            Spacer()
            
            Button {
                showSlippageSettings = true
            } label: {
                HStack(spacing: theme.spacingXS) {
                    Image(systemName: "gearshape")
                    Text(viewModel.formattedSlippage)
                }
                .foregroundColor(theme.accentColor)
            }
        }
    }
    
    // MARK: - From Asset Section
    
    private var fromAssetSection: some View {
        let theme = themeManager.currentTheme
        
        return VStack(alignment: .leading, spacing: theme.spacingS) {
            Text("From")
                .font(theme.captionFont)
                .foregroundColor(theme.textSecondary)
            
            HStack {
                // Amount Input
                TextField("0.0", text: $viewModel.inputAmount)
                    .font(theme.font(style: .title))
                    .foregroundColor(theme.textPrimary)
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif
                
                Spacer()
                
                // Asset Selector
                Button {
                    showFromAssetPicker = true
                } label: {
                    HStack {
                        if let asset = viewModel.fromAsset {
                            Text(asset.symbol)
                                .fontWeight(.semibold)
                                .foregroundColor(theme.textPrimary)
                        } else {
                            Text("Select")
                                .foregroundColor(theme.textSecondary)
                        }
                        Image(systemName: "chevron.down")
                            .foregroundColor(theme.textSecondary)
                    }
                    .padding(.horizontal, theme.spacingM)
                    .padding(.vertical, theme.spacingS)
                    .background(theme.backgroundSecondary)
                    .cornerRadius(theme.cornerRadius)
                }
            }
            
            if let asset = viewModel.fromAsset {
                Text(asset.chain.displayName)
                    .font(theme.captionFont)
                    .foregroundColor(theme.textSecondary)
            }
        }
        .padding()
        .background(theme.cardBackground)
        .cornerRadius(theme.cornerRadius)
    }
    
    // MARK: - Swap Direction Button
    
    private var swapDirectionButton: some View {
        let theme = themeManager.currentTheme
        
        return Button {
            viewModel.swapAssets()
        } label: {
            Image(systemName: "arrow.up.arrow.down")
                .font(.title2)
                .foregroundColor(theme.accentColor)
                .padding(theme.spacingM)
                .background(theme.backgroundSecondary)
                .clipShape(Circle())
        }
    }
    
    // MARK: - To Asset Section
    
    private var toAssetSection: some View {
        let theme = themeManager.currentTheme
        
        return VStack(alignment: .leading, spacing: theme.spacingS) {
            Text("To")
                .font(theme.captionFont)
                .foregroundColor(theme.textSecondary)
            
            HStack {
                // Output Amount (read-only)
                if let quote = viewModel.state.currentQuote {
                    Text(quote.formattedOutputAmount)
                        .font(theme.font(style: .title))
                        .foregroundColor(theme.textPrimary)
                } else {
                    Text("0.0")
                        .font(theme.font(style: .title))
                        .foregroundColor(theme.textSecondary)
                }
                
                Spacer()
                
                // Asset Selector
                Button {
                    showToAssetPicker = true
                } label: {
                    HStack {
                        if let asset = viewModel.toAsset {
                            Text(asset.symbol)
                                .fontWeight(.semibold)
                                .foregroundColor(theme.textPrimary)
                        } else {
                            Text("Select")
                                .foregroundColor(theme.textSecondary)
                        }
                        Image(systemName: "chevron.down")
                            .foregroundColor(theme.textSecondary)
                    }
                    .padding(.horizontal, theme.spacingM)
                    .padding(.vertical, theme.spacingS)
                    .background(theme.backgroundSecondary)
                    .cornerRadius(theme.cornerRadius)
                }
            }
            
            if let asset = viewModel.toAsset {
                Text(asset.chain.displayName)
                    .font(theme.captionFont)
                    .foregroundColor(theme.textSecondary)
            }
        }
        .padding()
        .background(theme.cardBackground)
        .cornerRadius(theme.cornerRadius)
    }
    
    // MARK: - Quote Details Section
    
    private var quoteDetailsSection: some View {
        let theme = themeManager.currentTheme
        
        return VStack(spacing: theme.spacingM) {
            if let quote = viewModel.state.currentQuote {
                // Exchange Rate
                HStack {
                    Text("Rate")
                        .foregroundColor(theme.textSecondary)
                    Spacer()
                    Text(quote.formattedRate)
                        .foregroundColor(theme.textPrimary)
                }
                
                KryptoDivider()
                
                // Price Impact
                if let impact = quote.priceImpact {
                    HStack {
                        Text("Price Impact")
                            .foregroundColor(theme.textSecondary)
                        Spacer()
                        Text("\(NSDecimalNumber(decimal: impact).stringValue)%")
                            .foregroundColor(priceImpactColor)
                    }
                }
                
                // Minimum Received
                HStack {
                    Text("Minimum Received")
                        .foregroundColor(theme.textSecondary)
                    Spacer()
                    Text("\(quote.formattedMinimumOutput) \(quote.toAsset.symbol)")
                        .foregroundColor(theme.textPrimary)
                }
                
                KryptoDivider()
                
                // Network Fee
                HStack {
                    Text("Network Fee")
                        .foregroundColor(theme.textSecondary)
                    Spacer()
                    if let feeUSD = quote.networkFeeUSD {
                        Text("~$\(NSDecimalNumber(decimal: feeUSD).stringValue)")
                            .foregroundColor(theme.textPrimary)
                    } else {
                        Text(quote.networkFeeEstimate)
                            .foregroundColor(theme.textPrimary)
                    }
                }
                
                // Provider
                HStack {
                    Text("Provider")
                        .foregroundColor(theme.textSecondary)
                    Spacer()
                    Text(quote.provider.displayName)
                        .foregroundColor(theme.textPrimary)
                }
                
                // Route
                if !quote.routePath.isEmpty {
                    HStack {
                        Text("Route")
                            .foregroundColor(theme.textSecondary)
                        Spacer()
                        Text(quote.routePath.joined(separator: " → "))
                            .font(theme.captionFont)
                            .foregroundColor(theme.textPrimary)
                    }
                }
                
                // Quote Expiration
                HStack {
                    Text("Quote expires in")
                        .foregroundColor(theme.textSecondary)
                    Spacer()
                    Text(viewModel.formattedTimeRemaining)
                        .foregroundColor(viewModel.quoteTimeRemaining < 10 ? theme.errorColor : theme.textPrimary)
                }
            }
        }
        .font(theme.bodyFont)
        .padding()
        .background(theme.cardBackground)
        .cornerRadius(theme.cornerRadius)
    }
    
    private var priceImpactColor: Color {
        let theme = themeManager.currentTheme
        switch viewModel.priceImpactLevel {
        case .low:
            return theme.successColor
        case .medium:
            return theme.textPrimary
        case .high:
            return theme.warningColor
        case .veryHigh:
            return theme.errorColor
        }
    }
    
    // MARK: - Simulation Status Section
    
    private var simulationStatusSection: some View {
        let theme = themeManager.currentTheme
        
        return Group {
            switch viewModel.state {
            case .idle:
                EmptyView()
                
            case .fetchingQuotes:
                HStack {
                    ProgressView()
                    Text("Fetching quotes...")
                        .foregroundColor(theme.textSecondary)
                }
                
            case .reviewing:
                HStack {
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(theme.successColor)
                    Text("Quote ready. Tap to simulate.")
                        .foregroundColor(theme.textPrimary)
                }
                
            case .simulating:
                HStack {
                    ProgressView()
                    Text("Simulating transaction...")
                        .foregroundColor(theme.textSecondary)
                }
                
            case .readyToSwap(_, let receipt):
                VStack(spacing: theme.spacingS) {
                    HStack {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundColor(theme.successColor)
                        Text("Simulation passed")
                            .foregroundColor(theme.successColor)
                    }
                    
                    Text("Gas estimate: \(receipt.gasEstimate)")
                        .font(theme.captionFont)
                        .foregroundColor(theme.textSecondary)
                    
                    if viewModel.requiresApproval {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(theme.warningColor)
                            Text("Token approval required")
                                .foregroundColor(theme.warningColor)
                        }
                        .font(theme.captionFont)
                    }
                }
                
            case .swapping:
                HStack {
                    ProgressView()
                    Text("Processing swap...")
                        .foregroundColor(theme.textSecondary)
                }
                
            case .success(let txHash):
                VStack(spacing: theme.spacingS) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(theme.successColor)
                        Text("Swap successful!")
                            .foregroundColor(theme.successColor)
                    }
                    
                    Text("Tx: \(txHash)")
                        .font(theme.captionFont)
                        .foregroundColor(theme.textSecondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                
            case .error:
                EmptyView() // Handled by alert
            }
            
            // Price impact warning
            if let warning = viewModel.priceImpactLevel.warningMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(theme.warningColor)
                    Text(warning)
                        .font(theme.captionFont)
                        .foregroundColor(theme.textPrimary)
                }
                .padding()
                .background(theme.warningColor.opacity(0.1))
                .cornerRadius(theme.cornerRadius)
            }
        }
        .padding(.vertical, theme.spacingS)
    }
    
    // MARK: - Alternative Quotes Section
    
    private var alternativeQuotesSection: some View {
        let theme = themeManager.currentTheme
        
        return VStack(alignment: .leading, spacing: theme.spacingS) {
            HStack {
                Text("All Quotes")
                    .font(theme.bodyFont)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.textPrimary)
                Spacer()
                Text("\(viewModel.allQuotes.count) providers")
                    .font(theme.captionFont)
                    .foregroundColor(theme.textSecondary)
            }
            
            ForEach(viewModel.allQuotes) { quote in
                Button {
                    viewModel.selectQuote(quote)
                } label: {
                    HStack {
                        Text(quote.provider.displayName)
                            .foregroundColor(theme.textPrimary)
                        Spacer()
                        Text(quote.formattedOutputAmount)
                            .foregroundColor(theme.textPrimary)
                        Text(quote.toAsset.symbol)
                            .foregroundColor(theme.textSecondary)
                        
                        if quote.id == viewModel.state.currentQuote?.id {
                            Image(systemName: "checkmark")
                                .foregroundColor(theme.successColor)
                        }
                    }
                    .padding(.vertical, theme.spacingXS)
                }
                .buttonStyle(.plain)
            }
            
            // Show provider errors
            if !viewModel.providerErrors.isEmpty {
                Text("Failed providers: \(viewModel.providerErrors.keys.map(\.displayName).joined(separator: ", "))")
                    .font(theme.captionFont)
                    .foregroundColor(theme.textSecondary)
            }
        }
        .padding()
        .background(theme.cardBackground)
        .cornerRadius(theme.cornerRadius)
    }
    
    // MARK: - Action Button
    
    private var actionButton: some View {
        let theme = themeManager.currentTheme
        
        return Button {
            Task {
                await handleAction()
            }
        } label: {
            HStack {
                if viewModel.state.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: theme.qrBackgroundColor))
                }
                
                Text(actionButtonTitle)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(actionButtonEnabled ? theme.accentColor : theme.disabledColor)
            .foregroundColor(theme.qrBackgroundColor)
            .cornerRadius(theme.cornerRadius)
        }
        .disabled(!actionButtonEnabled)
    }
    
    private var actionButtonTitle: String {
        switch viewModel.state {
        case .idle:
            return "Enter Amount"
        case .fetchingQuotes:
            return "Fetching..."
        case .reviewing:
            return "Simulate Swap"
        case .simulating:
            return "Simulating..."
        case .readyToSwap:
            return viewModel.requiresApproval ? "Approve & Swap" : "Swap"
        case .swapping:
            return "Swapping..."
        case .success:
            return "Done"
        case .error:
            return "Try Again"
        }
    }
    
    private var actionButtonEnabled: Bool {
        switch viewModel.state {
        case .idle:
            return viewModel.canInitiateSwap
        case .fetchingQuotes, .simulating, .swapping:
            return false
        case .reviewing:
            return true
        case .readyToSwap:
            return true
        case .success:
            return true
        case .error:
            return true
        }
    }
    
    private func handleAction() async {
        switch viewModel.state {
        case .idle:
            await viewModel.fetchQuotes()
        case .reviewing:
            await viewModel.simulateSwap()
        case .readyToSwap:
            await viewModel.executeSwap()
        case .success:
            viewModel.reset()
        case .error:
            viewModel.cancel()
        default:
            break
        }
    }
    
    private var showErrorBinding: Binding<Bool> {
        Binding(
            get: {
                if case .error = viewModel.state {
                    return true
                }
                return false
            },
            set: { _ in }
        )
    }
}

// MARK: - Asset Picker View

struct AssetPickerView: View {
    @Binding var selectedAsset: Asset?
    let excludedAsset: Asset?
    let title: String
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        let theme = themeManager.currentTheme
        
        NavigationView {
            List {
                ForEach(SwapViewModel.availableAssets.filter { $0.id != excludedAsset?.id }, id: \.id) { asset in
                    Button {
                        selectedAsset = asset
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(asset.symbol)
                                    .fontWeight(.semibold)
                                    .foregroundColor(theme.textPrimary)
                                Text(asset.name)
                                    .font(theme.captionFont)
                                    .foregroundColor(theme.textSecondary)
                            }
                            
                            Spacer()
                            
                            Text(asset.chain.displayName)
                                .font(theme.captionFont)
                                .themedBadge(theme: theme)
                            
                            if asset.id == selectedAsset?.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(theme.accentColor)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle(title)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(theme.accentColor)
                }
            }
        }
    }
}

// MARK: - Slippage Settings View

struct SlippageSettingsView: View {
    @Binding var slippage: Decimal
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    
    private let presets: [Decimal] = [0.1, 0.5, 1.0, 3.0]
    @State private var customSlippage: String = ""
    
    var body: some View {
        let theme = themeManager.currentTheme
        
        NavigationView {
            VStack(spacing: theme.spacingXL) {
                Text("Slippage Tolerance")
                    .font(theme.headlineFont)
                    .foregroundColor(theme.textPrimary)
                
                Text("Your transaction will revert if the price changes unfavorably by more than this percentage.")
                    .font(theme.captionFont)
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
                
                // Preset buttons
                HStack(spacing: theme.spacingM) {
                    ForEach(presets, id: \.self) { preset in
                        Button {
                            slippage = preset
                            customSlippage = ""
                        } label: {
                            Text("\(NSDecimalNumber(decimal: preset).stringValue)%")
                                .padding(.horizontal, theme.spacingL)
                                .padding(.vertical, theme.spacingS)
                                .background(slippage == preset ? theme.accentColor : theme.backgroundSecondary)
                                .foregroundColor(slippage == preset ? theme.qrBackgroundColor : theme.textPrimary)
                                .cornerRadius(theme.cornerRadius)
                        }
                    }
                }
                
                // Custom input
                HStack {
                    TextField("Custom", text: $customSlippage)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: customSlippage) { _, newValue in
                            if let value = Decimal(string: newValue), value > 0, value <= SwapConfiguration.maxSlippage {
                                slippage = value
                            }
                        }
                    Text("%")
                        .foregroundColor(theme.textSecondary)
                }
                .padding(.horizontal)
                
                // Warning for high slippage
                if slippage > SwapConfiguration.highPriceImpactThreshold {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(theme.warningColor)
                        Text("High slippage increases the risk of unfavorable trades.")
                            .font(theme.captionFont)
                            .foregroundColor(theme.textPrimary)
                    }
                    .padding()
                    .background(theme.warningColor.opacity(0.1))
                    .cornerRadius(theme.cornerRadius)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Settings")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(theme.accentColor)
                }
            }
        }
    }
}

// MARK: - Legacy SwapView Compatibility

/// Legacy SwapView wrapper for backward compatibility
struct SwapView: View {
    @EnvironmentObject var wsm: WalletStateManager
    @EnvironmentObject var themeManager: ThemeManager

    @State private var fromAmount: String = ""
    @State private var toAmount: String = ""
    @State private var isCalculating = false
    @State private var slippage: Double = 0.5
    @State private var showError = false
    @State private var errorMessage = ""

    @State private var price: Decimal?

    var body: some View {
        let theme = themeManager.currentTheme
        
        ZStack {
            Color.clear
                .themedContainer(theme: theme, showPattern: true, applyAnimation: true)
                .ignoresSafeArea()

            VStack(spacing: theme.spacingXL) {
                Text("Swap")
                    .font(theme.font(style: .title2))
                    .foregroundColor(theme.textPrimary)
                    .padding(.top)

                SwapInputCard(
                    title: "From",
                    amount: $fromAmount,
                    symbol: "ETH",
                    theme: theme
                )
                .onChange(of: fromAmount) { _, newValue in
                    Task {
                        await calculateQuote(input: newValue)
                    }
                }

                Image(systemName: theme.iconReceive)
                    .font(.title)
                    .foregroundColor(theme.accentColor)

                SwapInputCard(
                    title: "To",
                    amount: $toAmount,
                    symbol: "USDC",
                    theme: theme
                )

                HStack {
                    Text("Slippage Tolerance")
                        .font(theme.font(style: .caption))
                        .foregroundColor(theme.textSecondary)
                    Spacer()
                    Text("\(String(format: "%.1f", slippage))%")
                        .font(theme.font(style: .caption))
                        .foregroundColor(theme.accentColor)
                }
                .padding(.horizontal)

                if let p = price {
                    HStack {
                        Text("Price")
                            .font(theme.font(style: .caption))
                            .foregroundColor(theme.textSecondary)
                        Spacer()
                        Text("1 ETH ≈ $\(NSDecimalNumber(decimal: p).stringValue)")
                            .font(theme.font(style: .caption))
                            .foregroundColor(theme.textPrimary)
                    }
                    .padding(.horizontal)
                }

                Spacer()

                if isCalculating {
                    ProgressView()
                } else {
                    KryptoButton(
                        title: fromAmount.isEmpty ? "ENTER AMOUNT" : "REVIEW SWAP",
                        icon: theme.iconSwap,
                        action: {
                            if wsm.currentAddress == nil {
                                showError = true
                                errorMessage = "Please create or import a wallet first."
                            } else if toAmount.isEmpty {
                            } else {
                                showError = true
                                errorMessage = "Swap execution requires a DEX Aggregator API key (e.g. 1inch). Price feed is live."
                            }
                        },
                        isPrimary: !fromAmount.isEmpty
                    )
                    .padding()
                    .disabled(fromAmount.isEmpty)
                    .opacity(fromAmount.isEmpty ? 0.6 : 1.0)
                }
            }
        }
        .alert(isPresented: $showError) {
            Alert(title: Text("Swap Info"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
        }
        .onAppear {
            Task {
                do {
                    price = try await wsm.fetchPrice(chain: .ethereum)
                } catch {
                    KryptoLogger.shared.logError(module: "SwapView", error: error)
                }
            }
        }
    }

    func calculateQuote(input: String) async {
        isCalculating = true
        defer { isCalculating = false }

        guard let amount = Double(input), let currentPrice = price else {
            toAmount = ""
            return
        }

        let quote = Decimal(amount) * currentPrice
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2

        toAmount = formatter.string(from: NSDecimalNumber(decimal: quote)) ?? ""
    }
}

struct SwapInputCard: View {
    let title: String
    @Binding var amount: String
    let symbol: String
    let theme: ThemeProtocolV2

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacingS) {
            Text(title)
                .font(theme.font(style: .caption))
                .foregroundColor(theme.textSecondary)

            HStack {
                TextField("0.0", text: $amount)
                    .font(theme.font(style: .title))
                    .foregroundColor(theme.textPrimary)
                #if os(iOS)
                    .keyboardType(.decimalPad)
                #endif

                Text(symbol)
                    .fontWeight(.bold)
                    .foregroundColor(theme.textPrimary)
                    .padding(theme.spacingS)
                    .background(theme.backgroundMain)
                    .cornerRadius(theme.cornerRadius)
            }
        }
        .padding()
        .background(theme.backgroundSecondary)
        .cornerRadius(theme.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .stroke(theme.borderColor, lineWidth: 1)
        )
        .padding(.horizontal)
    }
}
