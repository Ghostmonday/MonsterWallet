// MODULE: EarnViewModel
// VERSION: 1.0.0
// PURPOSE: State machine for earn/staking flow with instant load policy

import Foundation
import Combine

// MARK: - Earn State

/// State machine states for the earn flow
public enum EarnState: Equatable, Sendable {
    case loading
    case cached(opportunities: [YieldOpportunity], positions: [StakingPosition])
    case fresh(opportunities: [YieldOpportunity], positions: [StakingPosition])
    case staking(YieldOpportunity)
    case unstaking(StakingPosition)
    case simulating
    case readyToExecute(PreparedStakingTransaction, SimulationReceipt)
    case executing
    case success(txHash: String)
    case error(StakingError)
    
    public static func == (lhs: EarnState, rhs: EarnState) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading):
            return true
        case (.cached(let a, let b), .cached(let c, let d)):
            return a.map(\.id) == c.map(\.id) && b.map(\.id) == d.map(\.id)
        case (.fresh(let a, let b), .fresh(let c, let d)):
            return a.map(\.id) == c.map(\.id) && b.map(\.id) == d.map(\.id)
        case (.staking(let a), .staking(let b)):
            return a.id == b.id
        case (.unstaking(let a), .unstaking(let b)):
            return a.id == b.id
        case (.simulating, .simulating):
            return true
        case (.readyToExecute, .readyToExecute):
            return true
        case (.executing, .executing):
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
        case .loading, .simulating, .executing:
            return true
        default:
            return false
        }
    }
    
    public var opportunities: [YieldOpportunity] {
        switch self {
        case .cached(let opps, _), .fresh(let opps, _):
            return opps
        default:
            return []
        }
    }
    
    public var positions: [StakingPosition] {
        switch self {
        case .cached(_, let pos), .fresh(_, let pos):
            return pos
        default:
            return []
        }
    }
}

// MARK: - Earn ViewModel

/// ViewModel managing the earn/staking flow with instant load policy.
///
/// **State Flow:**
/// Loading → Cached(Data) → Fresh(Data) → Staking(Opportunity) → Simulating → ReadyToExecute → Executing → Success
///
/// **Instant Load Policy:**
/// - Display cached data immediately (0ms)
/// - Fetch fresh data in background
/// - Update UI when fresh data arrives
@available(iOS 15.0, macOS 12.0, *)
@MainActor
public final class EarnViewModel: ObservableObject {
    
    // MARK: - Published State
    
    /// Current state
    @Published public private(set) var state: EarnState = .loading
    
    /// Selected opportunity for staking
    @Published public var selectedOpportunity: YieldOpportunity?
    
    /// Selected position for unstaking
    @Published public var selectedPosition: StakingPosition?
    
    /// Staking amount input (human-readable)
    @Published public var stakingAmount: String = ""
    
    /// Unstaking amount input (human-readable)
    @Published public var unstakingAmount: String = ""
    
    /// Filter by protocol
    @Published public var protocolFilter: YieldProtocol?
    
    /// Filter by risk level
    @Published public var riskFilter: YieldRiskLevel?
    
    /// Sort order
    @Published public var sortOrder: SortOrder = .apyDescending
    
    /// Whether approval is needed
    @Published public private(set) var requiresApproval: Bool = false
    
    // MARK: - Sort Options
    
    public enum SortOrder: String, CaseIterable {
        case apyDescending = "Highest APY"
        case apyAscending = "Lowest APY"
        case tvlDescending = "Highest TVL"
        case riskAscending = "Lowest Risk"
    }
    
    // MARK: - Dependencies
    
    private let dataService: EarnDataService
    private let cache: EarnCache
    private let stakingManager: StakingManager
    private let walletAddress: () -> String?
    private let signTransaction: (PreparedStakingTransaction) async throws -> Data
    
    // MARK: - Cancellables
    
    private var cancellables = Set<AnyCancellable>()
    private var refreshTask: Task<Void, Never>?
    
    // MARK: - Initialization
    
    public init(
        dataService: EarnDataService,
        cache: EarnCache,
        stakingManager: StakingManager,
        walletAddress: @escaping () -> String?,
        signTransaction: @escaping (PreparedStakingTransaction) async throws -> Data
    ) {
        self.dataService = dataService
        self.cache = cache
        self.stakingManager = stakingManager
        self.walletAddress = walletAddress
        self.signTransaction = signTransaction
    }
    
    // MARK: - Lifecycle
    
    /// Load data with instant load policy
    public func loadData() async {
        state = .loading
        
        // Step 1: Load from cache immediately (0ms target)
        if let cachedData = await cache.loadAllFromDisk() {
            state = .cached(
                opportunities: applySortAndFilter(cachedData.opportunities),
                positions: cachedData.positions
            )
        }
        
        // Step 2: Fetch fresh data in background
        await refreshFromNetwork()
    }
    
    /// Refresh data from network
    public func refreshFromNetwork() async {
        do {
            // Fetch opportunities
            let opportunities = try await dataService.fetchAllOpportunities()
            
            // Fetch user positions (if wallet connected)
            var positions: [StakingPosition] = []
            if let address = walletAddress() {
                positions = try await dataService.fetchUserPositions(address: address)
            }
            
            // Save to cache
            let cacheData = EarnCacheData(
                opportunities: opportunities,
                positions: positions
            )
            try await cache.saveAll(cacheData)
            
            // Update state
            state = .fresh(
                opportunities: applySortAndFilter(opportunities),
                positions: positions
            )
            
        } catch {
            // Don't override cached state on network error
            if case .loading = state {
                state = .error(.networkError(underlying: error.localizedDescription))
            }
            print("[EarnViewModel] Network refresh failed: \(error)")
        }
    }
    
    // MARK: - Staking Flow
    
    /// Select an opportunity for staking
    public func selectOpportunity(_ opportunity: YieldOpportunity) {
        selectedOpportunity = opportunity
        stakingAmount = ""
        state = .staking(opportunity)
    }
    
    /// Select a position for unstaking
    public func selectPositionForUnstake(_ position: StakingPosition) {
        selectedPosition = position
        unstakingAmount = ""
        state = .unstaking(position)
    }
    
    /// Prepare and simulate staking transaction
    public func simulateStake() async {
        guard let opportunity = selectedOpportunity,
              let address = walletAddress(),
              !stakingAmount.isEmpty else {
            return
        }
        
        guard let amount = Decimal(string: stakingAmount), amount > 0 else {
            state = .error(.invalidAmount)
            return
        }
        
        state = .simulating
        
        do {
            // Convert to raw amount
            let rawAmount = convertToRawAmount(amount, decimals: opportunity.inputAsset.decimals)
            
            // Create staking request
            let request = StakingRequest(
                opportunity: opportunity,
                amount: rawAmount,
                senderAddress: address
            )
            
            // Prepare transaction
            let preparedTx = try await stakingManager.prepareStakeTransaction(request)
            
            // Check if approval needed (for ERC20 tokens)
            if opportunity.inputAsset.type != .native,
               let tokenAddress = opportunity.inputAsset.contractAddress {
                let needsApproval = try await stakingManager.checkApprovalNeeded(
                    token: tokenAddress,
                    owner: address,
                    spender: preparedTx.to,
                    amount: rawAmount
                )
                requiresApproval = needsApproval
            }
            
            // Simulate
            let result = await stakingManager.simulateStake(preparedTx)
            
            switch result {
            case .success(let receipt):
                state = .readyToExecute(preparedTx, receipt)
                
            case .failure(let error, let revertReason):
                state = .error(.simulationFailed(reason: revertReason ?? error))
            }
            
        } catch let error as StakingError {
            state = .error(error)
        } catch {
            state = .error(.simulationFailed(reason: error.localizedDescription))
        }
    }
    
    /// Execute the staking transaction
    public func executeStake() async {
        guard case .readyToExecute(let transaction, let receipt) = state else {
            return
        }
        
        guard !receipt.isExpired else {
            state = .error(.simulationFailed(reason: "Simulation expired"))
            return
        }
        
        state = .executing
        
        do {
            // Handle approval if needed
            if requiresApproval,
               let opportunity = selectedOpportunity,
               let tokenAddress = opportunity.inputAsset.contractAddress,
               let address = walletAddress() {
                try await executeApproval(
                    token: tokenAddress,
                    spender: transaction.to,
                    owner: address
                )
            }
            
            // Sign the transaction
            let signedTx = try await signTransaction(transaction)
            
            // Execute
            let txHash = try await stakingManager.executeStake(
                transaction,
                receipt: receipt,
                signedTransaction: signedTx
            )
            
            state = .success(txHash: txHash)
            
            // Refresh data after successful stake
            Task {
                try await Task.sleep(nanoseconds: 2_000_000_000) // Wait 2 seconds
                await refreshFromNetwork()
            }
            
        } catch let error as StakingError {
            state = .error(error)
        } catch {
            state = .error(.transactionFailed(reason: error.localizedDescription))
        }
    }
    
    /// Execute approval transaction
    private func executeApproval(token: String, spender: String, owner: String) async throws {
        let approvalTx = await stakingManager.buildApprovalTransaction(
            token: token,
            spender: spender,
            owner: owner
        )
        
        // Simulate approval
        let approvalResult = await stakingManager.simulateStake(approvalTx)
        
        guard case .success(let approvalReceipt) = approvalResult else {
            throw StakingError.simulationFailed(reason: "Approval simulation failed")
        }
        
        // Sign approval
        let signedApproval = try await signTransaction(approvalTx)
        
        // Execute approval
        _ = try await stakingManager.executeStake(
            approvalTx,
            receipt: approvalReceipt,
            signedTransaction: signedApproval
        )
        
        // Wait for confirmation
        try await Task.sleep(nanoseconds: 2_000_000_000)
        
        requiresApproval = false
    }
    
    // MARK: - Unstaking Flow
    
    /// Simulate unstaking transaction
    public func simulateUnstake() async {
        guard let position = selectedPosition,
              let address = walletAddress(),
              !unstakingAmount.isEmpty else {
            return
        }
        
        guard let amount = Decimal(string: unstakingAmount), amount > 0 else {
            state = .error(.invalidAmount)
            return
        }
        
        state = .simulating
        
        do {
            let rawAmount = convertToRawAmount(amount, decimals: position.stakedAsset.decimals)
            
            let request = UnstakingRequest(
                position: position,
                amount: rawAmount,
                senderAddress: address
            )
            
            let preparedTx = try await stakingManager.prepareUnstakeTransaction(request)
            let result = await stakingManager.simulateStake(preparedTx)
            
            switch result {
            case .success(let receipt):
                state = .readyToExecute(preparedTx, receipt)
            case .failure(let error, let revertReason):
                state = .error(.simulationFailed(reason: revertReason ?? error))
            }
            
        } catch let error as StakingError {
            state = .error(error)
        } catch {
            state = .error(.simulationFailed(reason: error.localizedDescription))
        }
    }
    
    // MARK: - Navigation
    
    /// Cancel current operation and return to list
    public func cancelOperation() {
        selectedOpportunity = nil
        selectedPosition = nil
        stakingAmount = ""
        unstakingAmount = ""
        requiresApproval = false
        
        // Restore cached/fresh state
        Task {
            await loadData()
        }
    }
    
    /// Reset after success
    public func reset() {
        cancelOperation()
    }
    
    // MARK: - Filtering & Sorting
    
    /// Apply current filters and sort order
    private func applySortAndFilter(_ opportunities: [YieldOpportunity]) -> [YieldOpportunity] {
        var filtered = opportunities
        
        // Apply protocol filter
        if let protocolFilter = protocolFilter {
            filtered = filtered.filter { $0.protocol == protocolFilter }
        }
        
        // Apply risk filter
        if let riskFilter = riskFilter {
            filtered = filtered.filter { $0.riskLevel == riskFilter }
        }
        
        // Apply sort
        switch sortOrder {
        case .apyDescending:
            filtered.sort { $0.apy > $1.apy }
        case .apyAscending:
            filtered.sort { $0.apy < $1.apy }
        case .tvlDescending:
            filtered.sort { ($0.tvlUSD ?? 0) > ($1.tvlUSD ?? 0) }
        case .riskAscending:
            filtered.sort { $0.riskLevel.score < $1.riskLevel.score }
        }
        
        return filtered
    }
    
    /// Reapply filters to current state
    public func applyFilters() {
        switch state {
        case .cached(let opps, let pos):
            state = .cached(opportunities: applySortAndFilter(opps), positions: pos)
        case .fresh(let opps, let pos):
            state = .fresh(opportunities: applySortAndFilter(opps), positions: pos)
        default:
            break
        }
    }
    
    // MARK: - Computed Properties
    
    /// Filtered opportunities
    public var filteredOpportunities: [YieldOpportunity] {
        state.opportunities
    }
    
    /// User's total staked value (USD)
    public var totalStakedValueUSD: Decimal {
        // Calculate from positions - would need price data
        Decimal(0)
    }
    
    /// Estimated annual earnings (USD)
    public var estimatedAnnualEarnings: Decimal {
        // Calculate from positions * APY
        Decimal(0)
    }
    
    /// Status message for current state
    public var statusMessage: String {
        switch state {
        case .loading:
            return "Loading opportunities..."
        case .cached:
            return "Showing cached data"
        case .fresh:
            return "Data is up to date"
        case .staking(let opp):
            return "Staking \(opp.inputAsset.symbol)"
        case .unstaking(let pos):
            return "Unstaking from \(pos.protocol.displayName)"
        case .simulating:
            return "Simulating transaction..."
        case .readyToExecute:
            return "Ready to execute"
        case .executing:
            return "Processing transaction..."
        case .success(let hash):
            return "Success! Tx: \(hash.prefix(10))..."
        case .error(let error):
            return error.localizedDescription
        }
    }
    
    /// Whether stake button should be enabled
    public var canStake: Bool {
        guard let opportunity = selectedOpportunity,
              !stakingAmount.isEmpty,
              let amount = Decimal(string: stakingAmount),
              amount > 0 else {
            return false
        }
        
        // Check minimum stake
        if let minimum = opportunity.minimumStake,
           let minAmount = Decimal(string: minimum),
           let inputDecimals = Decimal(string: stakingAmount) {
            let rawInput = inputDecimals * pow(Decimal(10), opportunity.inputAsset.decimals)
            if rawInput < minAmount {
                return false
            }
        }
        
        return true
    }
    
    // MARK: - Helpers
    
    private func convertToRawAmount(_ amount: Decimal, decimals: Int) -> String {
        let multiplier = pow(Decimal(10), decimals)
        let raw = amount * multiplier
        return "\(raw)"
    }
}


