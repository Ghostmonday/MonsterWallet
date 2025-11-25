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
        ScrollView {
            VStack(spacing: 16) {
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
                
                Spacer(minLength: 20)
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
        HStack {
            Text("Swap")
                .font(.title2)
                .fontWeight(.bold)
            
            Spacer()
            
            Button {
                showSlippageSettings = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "gearshape")
                    Text(viewModel.formattedSlippage)
                }
            }
        }
    }
    
    // MARK: - From Asset Section
    
    private var fromAssetSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("From")
                .font(.caption)
            
            HStack {
                // Amount Input
                TextField("0.0", text: $viewModel.inputAmount)
                    .font(.title)
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
                        } else {
                            Text("Select")
                        }
                        Image(systemName: "chevron.down")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            
            if let asset = viewModel.fromAsset {
                Text(asset.chain.displayName)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Swap Direction Button
    
    private var swapDirectionButton: some View {
        Button {
            viewModel.swapAssets()
        } label: {
            Image(systemName: "arrow.up.arrow.down")
                .font(.title2)
                .padding(12)
                .background(Color.secondary.opacity(0.1))
                .clipShape(Circle())
        }
    }
    
    // MARK: - To Asset Section
    
    private var toAssetSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("To")
                .font(.caption)
            
            HStack {
                // Output Amount (read-only)
                if let quote = viewModel.state.currentQuote {
                    Text(quote.formattedOutputAmount)
                        .font(.title)
                } else {
                    Text("0.0")
                        .font(.title)
                        .foregroundColor(.secondary)
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
                        } else {
                            Text("Select")
                        }
                        Image(systemName: "chevron.down")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            
            if let asset = viewModel.toAsset {
                Text(asset.chain.displayName)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Quote Details Section
    
    private var quoteDetailsSection: some View {
        VStack(spacing: 12) {
            if let quote = viewModel.state.currentQuote {
                // Exchange Rate
                HStack {
                    Text("Rate")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(quote.formattedRate)
                }
                
                Divider()
                
                // Price Impact
                if let impact = quote.priceImpact {
                    HStack {
                        Text("Price Impact")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(NSDecimalNumber(decimal: impact).stringValue)%")
                            .foregroundColor(priceImpactColor)
                    }
                }
                
                // Minimum Received
                HStack {
                    Text("Minimum Received")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(quote.formattedMinimumOutput) \(quote.toAsset.symbol)")
                }
                
                Divider()
                
                // Network Fee
                HStack {
                    Text("Network Fee")
                        .foregroundColor(.secondary)
                    Spacer()
                    if let feeUSD = quote.networkFeeUSD {
                        Text("~$\(NSDecimalNumber(decimal: feeUSD).stringValue)")
                    } else {
                        Text(quote.networkFeeEstimate)
                    }
                }
                
                // Provider
                HStack {
                    Text("Provider")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(quote.provider.displayName)
                }
                
                // Route
                if !quote.routePath.isEmpty {
                    HStack {
                        Text("Route")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(quote.routePath.joined(separator: " → "))
                            .font(.caption)
                    }
                }
                
                // Quote Expiration
                HStack {
                    Text("Quote expires in")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(viewModel.formattedTimeRemaining)
                        .foregroundColor(viewModel.quoteTimeRemaining < 10 ? .red : .primary)
                }
            }
        }
        .font(.subheadline)
        .padding()
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(12)
    }
    
    private var priceImpactColor: Color {
        switch viewModel.priceImpactLevel {
        case .low:
            return .green
        case .medium:
            return .primary
        case .high:
            return .orange
        case .veryHigh:
            return .red
        }
    }
    
    // MARK: - Simulation Status Section
    
    private var simulationStatusSection: some View {
        Group {
            switch viewModel.state {
            case .idle:
                EmptyView()
                
            case .fetchingQuotes:
                HStack {
                    ProgressView()
                    Text("Fetching quotes...")
                }
                
            case .reviewing:
                HStack {
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(.green)
                    Text("Quote ready. Tap to simulate.")
                }
                
            case .simulating:
                HStack {
                    ProgressView()
                    Text("Simulating transaction...")
                }
                
            case .readyToSwap(_, let receipt):
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundColor(.green)
                        Text("Simulation passed")
                    }
                    
                    Text("Gas estimate: \(receipt.gasEstimate)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if viewModel.requiresApproval {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.orange)
                            Text("Token approval required")
                        }
                        .font(.caption)
                    }
                }
                
            case .swapping:
                HStack {
                    ProgressView()
                    Text("Processing swap...")
                }
                
            case .success(let txHash):
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Swap successful!")
                    }
                    
                    Text("Tx: \(txHash)")
                        .font(.caption)
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
                        .foregroundColor(.orange)
                    Text(warning)
                        .font(.caption)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Alternative Quotes Section
    
    private var alternativeQuotesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("All Quotes")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(viewModel.allQuotes.count) providers")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ForEach(viewModel.allQuotes) { quote in
                Button {
                    viewModel.selectQuote(quote)
                } label: {
                    HStack {
                        Text(quote.provider.displayName)
                        Spacer()
                        Text(quote.formattedOutputAmount)
                        Text(quote.toAsset.symbol)
                            .foregroundColor(.secondary)
                        
                        if quote.id == viewModel.state.currentQuote?.id {
                            Image(systemName: "checkmark")
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
            
            // Show provider errors
            if !viewModel.providerErrors.isEmpty {
                Text("Failed providers: \(viewModel.providerErrors.keys.map(\.displayName).joined(separator: ", "))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Action Button
    
    private var actionButton: some View {
        Button {
            Task {
                await handleAction()
            }
        } label: {
            HStack {
                if viewModel.state.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
                
                Text(actionButtonTitle)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(actionButtonEnabled ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(12)
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
    
    var body: some View {
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
                                Text(asset.name)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text(asset.chain.displayName)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(4)
                            
                            if asset.id == selectedAsset?.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
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
                }
            }
        }
    }
}

// MARK: - Slippage Settings View

struct SlippageSettingsView: View {
    @Binding var slippage: Decimal
    @Environment(\.dismiss) private var dismiss
    
    private let presets: [Decimal] = [0.1, 0.5, 1.0, 3.0]
    @State private var customSlippage: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Slippage Tolerance")
                    .font(.headline)
                
                Text("Your transaction will revert if the price changes unfavorably by more than this percentage.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                // Preset buttons
                HStack(spacing: 12) {
                    ForEach(presets, id: \.self) { preset in
                        Button {
                            slippage = preset
                            customSlippage = ""
                        } label: {
                            Text("\(NSDecimalNumber(decimal: preset).stringValue)%")
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(slippage == preset ? Color.blue : Color.secondary.opacity(0.1))
                                .foregroundColor(slippage == preset ? .white : .primary)
                                .cornerRadius(8)
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
                }
                .padding(.horizontal)
                
                // Warning for high slippage
                if slippage > SwapConfiguration.highPriceImpactThreshold {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("High slippage increases the risk of unfavorable trades.")
                            .font(.caption)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
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
        ZStack {
            Color.clear
                .themedContainer(theme: themeManager.currentTheme, showPattern: true, applyAnimation: true)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Swap")
                    .font(themeManager.currentTheme.font(style: .title2))
                    .foregroundColor(themeManager.currentTheme.textPrimary)
                    .padding(.top)

                SwapInputCard(
                    title: "From",
                    amount: $fromAmount,
                    symbol: "ETH",
                    theme: themeManager.currentTheme
                )
                .onChange(of: fromAmount) { _, newValue in
                    Task {
                        await calculateQuote(input: newValue)
                    }
                }

                Image(systemName: themeManager.currentTheme.iconReceive)
                    .font(.title)
                    .foregroundColor(themeManager.currentTheme.accentColor)

                SwapInputCard(
                    title: "To",
                    amount: $toAmount,
                    symbol: "USDC",
                    theme: themeManager.currentTheme
                )

                HStack {
                    Text("Slippage Tolerance")
                        .font(themeManager.currentTheme.font(style: .caption))
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                    Spacer()
                    Text("\(String(format: "%.1f", slippage))%")
                        .font(themeManager.currentTheme.font(style: .caption))
                        .foregroundColor(themeManager.currentTheme.accentColor)
                }
                .padding(.horizontal)

                if let p = price {
                    HStack {
                        Text("Price")
                            .font(themeManager.currentTheme.font(style: .caption))
                            .foregroundColor(themeManager.currentTheme.textSecondary)
                        Spacer()
                        Text("1 ETH ≈ $\(NSDecimalNumber(decimal: p).stringValue)")
                            .font(themeManager.currentTheme.font(style: .caption))
                            .foregroundColor(themeManager.currentTheme.textPrimary)
                    }
                    .padding(.horizontal)
                }

                Spacer()

                if isCalculating {
                    ProgressView()
                } else {
                    KryptoButton(
                        title: fromAmount.isEmpty ? "ENTER AMOUNT" : "REVIEW SWAP",
                        icon: themeManager.currentTheme.iconSwap,
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
        VStack(alignment: .leading, spacing: 8) {
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
                    .padding(8)
                    .background(theme.backgroundMain)
                    .cornerRadius(8)
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

