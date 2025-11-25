// MODULE: SwapViewModel
// VERSION: 1.0.0
// PURPOSE: State machine for swap flow with auto-refresh and simulation guard

import Foundation
import Combine

// MARK: - Swap State

/// State machine states for the swap flow
public enum SwapState: Equatable, Sendable {
    case idle
    case fetchingQuotes
    case reviewing(SwapQuoteV2)
    case simulating
    case readyToSwap(SwapQuoteV2, SimulationReceipt)
    case swapping
    case success(txHash: String)
    case error(SwapError)
    
    public static func == (lhs: SwapState, rhs: SwapState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):
            return true
        case (.fetchingQuotes, .fetchingQuotes):
            return true
        case (.reviewing(let a), .reviewing(let b)):
            return a.id == b.id
        case (.simulating, .simulating):
            return true
        case (.readyToSwap(let q1, _), .readyToSwap(let q2, _)):
            return q1.id == q2.id
        case (.swapping, .swapping):
            return true
        case (.success(let a), .success(let b)):
            return a == b
        case (.error(let a), .error(let b)):
            return a.localizedDescription == b.localizedDescription
        default:
            return false
        }
    }
    
    public var isLoading: Bool {
        switch self {
        case .fetchingQuotes, .simulating, .swapping:
            return true
        default:
            return false
        }
    }
    
    public var canSwap: Bool {
        if case .readyToSwap = self {
            return true
        }
        return false
    }
    
    public var currentQuote: SwapQuoteV2? {
        switch self {
        case .reviewing(let quote), .readyToSwap(let quote, _):
            return quote
        default:
            return nil
        }
    }
    
    public var simulationReceipt: SimulationReceipt? {
        if case .readyToSwap(_, let receipt) = self {
            return receipt
        }
        return nil
    }
}

// MARK: - Swap ViewModel

/// ViewModel managing the swap flow with auto-refresh and simulation integration.
///
/// **State Machine Flow:**
/// Idle → FetchingQuotes → Reviewing(Quote) → Simulating → ReadyToSwap → Swapping → Success
///
/// **Features:**
/// - Auto-refresh quotes every 15 seconds
/// - Mandatory simulation before swap execution
/// - Quote expiration handling
/// - Price impact warnings
@available(iOS 15.0, macOS 12.0, *)
@MainActor
public final class SwapViewModel: ObservableObject {
    
    // MARK: - Published State
    
    /// Current swap state
    @Published public private(set) var state: SwapState = .idle
    
    /// Source asset
    @Published public var fromAsset: Asset?
    
    /// Destination asset
    @Published public var toAsset: Asset?
    
    /// Input amount (human-readable)
    @Published public var inputAmount: String = ""
    
    /// Slippage tolerance percentage
    @Published public var slippageTolerance: Decimal = SwapConfiguration.defaultSlippage
    
    /// All quotes from comparison
    @Published public private(set) var allQuotes: [SwapQuoteV2] = []
    
    /// Provider errors during quote fetch
    @Published public private(set) var providerErrors: [SwapProvider: String] = [:]
    
    /// Quote time remaining until expiration
    @Published public private(set) var quoteTimeRemaining: TimeInterval = 0
    
    /// Price impact level
    @Published public private(set) var priceImpactLevel: PriceImpactLevel = .low
    
    /// Whether approval is needed
    @Published public private(set) var requiresApproval: Bool = false
    
    // MARK: - Dependencies
    
    private let quoteService: QuoteService
    private let swapRouter: SwapRouter
    private let walletAddress: () -> String?
    private let signTransaction: (PreparedSwapTransaction) async throws -> Data
    
    // MARK: - Timers
    
    private var refreshTimer: Timer?
    private var expirationTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    public init(
        quoteService: QuoteService,
        swapRouter: SwapRouter,
        walletAddress: @escaping () -> String?,
        signTransaction: @escaping (PreparedSwapTransaction) async throws -> Data
    ) {
        self.quoteService = quoteService
        self.swapRouter = swapRouter
        self.walletAddress = walletAddress
        self.signTransaction = signTransaction
        
        setupInputObservers()
    }
    
    deinit {
        refreshTimer?.invalidate()
        expirationTimer?.invalidate()
    }
    
    // MARK: - Input Observers
    
    private func setupInputObservers() {
        // Debounce input changes and auto-fetch quotes
        $inputAmount
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] amount in
                guard let self = self,
                      !amount.isEmpty,
                      Decimal(string: amount) != nil else {
                    return
                }
                Task { @MainActor in
                    await self.fetchQuotes()
                }
            }
            .store(in: &cancellables)
        
        // React to asset changes
        Publishers.CombineLatest($fromAsset, $toAsset)
            .dropFirst()
            .sink { [weak self] _, _ in
                self?.state = .idle
                self?.stopAutoRefresh()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Actions
    
    /// Fetch quotes for current input
    public func fetchQuotes() async {
        guard let from = fromAsset,
              let to = toAsset,
              let address = walletAddress(),
              !inputAmount.isEmpty else {
            return
        }
        
        guard let inputDecimal = Decimal(string: inputAmount), inputDecimal > 0 else {
            return
        }
        
        // Convert human-readable to raw amount
        let rawAmount = convertToRawAmount(inputDecimal, decimals: from.decimals)
        
        state = .fetchingQuotes
        stopAutoRefresh()
        
        do {
            let request = SwapQuoteRequest(
                fromAsset: from,
                toAsset: to,
                amount: rawAmount,
                slippageTolerance: slippageTolerance,
                senderAddress: address
            )
            
            let result = try await quoteService.fetchBestQuote(for: request)
            
            allQuotes = result.allQuotes
            providerErrors = result.failedProviders
            
            let quote = result.bestQuote
            priceImpactLevel = PriceImpactLevel(impact: quote.priceImpact)
            
            state = .reviewing(quote)
            startExpirationTimer(expiresAt: quote.expiresAt)
            startAutoRefresh()
            
        } catch let error as SwapError {
            state = .error(error)
        } catch {
            state = .error(.networkError(underlying: error.localizedDescription))
        }
    }
    
    /// Simulate the current quote
    public func simulateSwap() async {
        guard case .reviewing(let quote) = state,
              let address = walletAddress() else {
            return
        }
        
        // Check quote expiration
        guard !quote.isExpired else {
            state = .error(.quoteExpired)
            return
        }
        
        state = .simulating
        
        do {
            // Prepare transaction
            let preparedTx = try await swapRouter.prepareSwapTransaction(
                quote: quote,
                senderAddress: address
            )
            
            // Check if approval is needed
            if preparedTx.requiresApproval,
               let token = preparedTx.approvalToken,
               let spender = preparedTx.approvalSpender {
                
                let needsApproval = try await swapRouter.checkApproval(
                    token: token,
                    owner: address,
                    spender: spender,
                    amount: quote.inputAmount,
                    chain: quote.fromAsset.chain
                )
                
                requiresApproval = needsApproval
            }
            
            // Simulate
            let result = await swapRouter.simulateSwap(preparedTx)
            
            switch result {
            case .success(let receipt):
                state = .readyToSwap(quote, receipt)
                
            case .failure(let error, let revertReason):
                let reason = revertReason ?? error
                state = .error(.simulationFailed(reason: reason))
            }
            
        } catch let error as SwapError {
            state = .error(error)
        } catch {
            state = .error(.simulationFailed(reason: error.localizedDescription))
        }
    }
    
    /// Execute the swap (requires valid simulation)
    public func executeSwap() async {
        guard case .readyToSwap(let quote, let receipt) = state,
              let address = walletAddress() else {
            return
        }
        
        // Safety guards
        guard !quote.isExpired else {
            state = .error(.quoteExpired)
            return
        }
        
        guard !receipt.isExpired else {
            state = .error(.simulationRequired)
            return
        }
        
        state = .swapping
        stopAutoRefresh()
        
        do {
            // Prepare transaction again (for signing)
            let preparedTx = try await swapRouter.prepareSwapTransaction(
                quote: quote,
                senderAddress: address
            )
            
            // Handle approval if needed
            if requiresApproval,
               let token = preparedTx.approvalToken,
               let spender = preparedTx.approvalSpender {
                
                try await executeApproval(token: token, spender: spender, owner: address)
            }
            
            // Sign the swap transaction
            let signedTx = try await signTransaction(preparedTx)
            
            // Execute
            let txHash = try await swapRouter.executeSwap(
                preparedTx,
                receipt: receipt,
                signedTransaction: signedTx
            )
            
            state = .success(txHash: txHash)
            
        } catch let error as SwapError {
            state = .error(error)
        } catch {
            state = .error(.transactionFailed(reason: error.localizedDescription))
        }
    }
    
    /// Handle token approval
    private func executeApproval(token: String, spender: String, owner: String) async throws {
        let approvalTx = await swapRouter.buildApprovalTransaction(
            token: token,
            spender: spender,
            owner: owner
        )
        
        // Simulate approval
        let approvalResult = await swapRouter.simulateSwap(approvalTx)
        
        guard case .success(let approvalReceipt) = approvalResult else {
            throw SwapError.simulationFailed(reason: "Approval simulation failed")
        }
        
        // Sign approval
        let signedApproval = try await signTransaction(approvalTx)
        
        // Execute approval
        _ = try await swapRouter.executeSwap(
            approvalTx,
            receipt: approvalReceipt,
            signedTransaction: signedApproval
        )
        
        // Wait for approval confirmation (simplified)
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        requiresApproval = false
    }
    
    /// Cancel current operation and reset
    public func cancel() {
        stopAutoRefresh()
        state = .idle
        allQuotes = []
        providerErrors = [:]
        quoteTimeRemaining = 0
        requiresApproval = false
    }
    
    /// Reset to idle for new swap
    public func reset() {
        cancel()
        inputAmount = ""
        fromAsset = nil
        toAsset = nil
    }
    
    /// Swap the from and to assets
    public func swapAssets() {
        let temp = fromAsset
        fromAsset = toAsset
        toAsset = temp
        
        // Clear and refetch if we have an amount
        if !inputAmount.isEmpty {
            state = .idle
            Task {
                await fetchQuotes()
            }
        }
    }
    
    /// Select a different quote from alternatives
    public func selectQuote(_ quote: SwapQuoteV2) {
        guard !quote.isExpired else { return }
        priceImpactLevel = PriceImpactLevel(impact: quote.priceImpact)
        state = .reviewing(quote)
        startExpirationTimer(expiresAt: quote.expiresAt)
    }
    
    // MARK: - Auto Refresh
    
    private func startAutoRefresh() {
        stopAutoRefresh()
        
        refreshTimer = Timer.scheduledTimer(
            withTimeInterval: SwapConfiguration.autoRefreshInterval,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.fetchQuotes()
            }
        }
    }
    
    private func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        expirationTimer?.invalidate()
        expirationTimer = nil
    }
    
    private func startExpirationTimer(expiresAt: Date) {
        expirationTimer?.invalidate()
        
        quoteTimeRemaining = expiresAt.timeIntervalSinceNow
        
        expirationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                self.quoteTimeRemaining = expiresAt.timeIntervalSinceNow
                
                if self.quoteTimeRemaining <= 0 {
                    self.expirationTimer?.invalidate()
                    
                    // Quote expired - refetch
                    if case .reviewing = self.state {
                        await self.fetchQuotes()
                    }
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func convertToRawAmount(_ amount: Decimal, decimals: Int) -> String {
        let multiplier = pow(Decimal(10), decimals)
        let raw = amount * multiplier
        return "\(raw)"
    }
    
    /// Check if swap button should be enabled
    public var canInitiateSwap: Bool {
        guard fromAsset != nil,
              toAsset != nil,
              !inputAmount.isEmpty,
              let amount = Decimal(string: inputAmount),
              amount > 0 else {
            return false
        }
        return true
    }
    
    /// Formatted slippage for display
    public var formattedSlippage: String {
        "\(slippageTolerance)%"
    }
    
    /// Formatted quote expiration time
    public var formattedTimeRemaining: String {
        let seconds = Int(max(0, quoteTimeRemaining))
        return "\(seconds)s"
    }
    
    /// Status message for current state
    public var statusMessage: String {
        switch state {
        case .idle:
            return "Enter amount to get quote"
        case .fetchingQuotes:
            return "Fetching best prices..."
        case .reviewing:
            return "Review your swap"
        case .simulating:
            return "Simulating transaction..."
        case .readyToSwap:
            return "Ready to swap"
        case .swapping:
            return "Processing swap..."
        case .success(let hash):
            return "Success! Tx: \(hash.prefix(10))..."
        case .error(let error):
            return error.localizedDescription
        }
    }
}

// MARK: - Available Assets

extension SwapViewModel {
    /// Common assets for swapping
    public static var availableAssets: [Asset] {
        [
            .ethereum,
            .bitcoin,
            .solana,
            .usdc,
            .usdt,
            .weth
        ]
    }
    
    /// Assets available for a specific chain
    public static func assets(for chain: AssetChain) -> [Asset] {
        switch chain {
        case .ethereum:
            return [.ethereum, .usdc, .usdt, .weth]
        case .bitcoin:
            return [.bitcoin]
        case .solana:
            return [.solana]
        }
    }
}


