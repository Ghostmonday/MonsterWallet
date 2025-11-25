// MODULE: EarnView
// VERSION: 1.0.0
// PURPOSE: Structural UI for earn/staking hub

import SwiftUI

// MARK: - Earn View (Structural)

/// Structural earn/staking interface.
///
/// **Sections:**
/// - My Positions: Current staked balances
/// - Opportunities: List of yield opportunities
///
/// **Features:**
/// - Stake sheet with input and simulation
/// - Unstake sheet with amount selection
/// - Filter and sort controls
@available(iOS 15.0, macOS 12.0, *)
struct EarnView: View {
    @StateObject private var viewModel: EarnViewModel
    
    @State private var showStakeSheet = false
    @State private var showUnstakeSheet = false
    @State private var showFilters = false
    
    init(
        dataService: EarnDataService,
        cache: EarnCache,
        stakingManager: StakingManager,
        walletAddress: @escaping () -> String?,
        signTransaction: @escaping (PreparedStakingTransaction) async throws -> Data
    ) {
        let vm = EarnViewModel(
            dataService: dataService,
            cache: cache,
            stakingManager: stakingManager,
            walletAddress: walletAddress,
            signTransaction: signTransaction
        )
        _viewModel = StateObject(wrappedValue: vm)
    }
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.state.isLoading && viewModel.state.opportunities.isEmpty {
                    loadingView
                } else {
                    mainContent
                }
            }
            .navigationTitle("Earn")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showFilters = true
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
                
                ToolbarItem(placement: .automatic) {
                    Button {
                        Task {
                            await viewModel.refreshFromNetwork()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.state.isLoading)
                }
            }
        }
        .task {
            await viewModel.loadData()
        }
        .sheet(isPresented: $showStakeSheet) {
            StakeSheetView(viewModel: viewModel)
        }
        .sheet(isPresented: $showUnstakeSheet) {
            UnstakeSheetView(viewModel: viewModel)
        }
        .sheet(isPresented: $showFilters) {
            FilterSheetView(viewModel: viewModel)
        }
        .alert("Error", isPresented: showErrorBinding) {
            Button("OK") {
                viewModel.cancelOperation()
            }
        } message: {
            if case .error(let error) = viewModel.state {
                Text(error.localizedDescription)
            }
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading opportunities...")
        }
    }
    
    // MARK: - Main Content
    
    private var mainContent: some View {
        List {
            // Status Banner
            if case .cached = viewModel.state {
                Section {
                    HStack {
                        Image(systemName: "clock")
                        Text("Showing cached data")
                        Spacer()
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    .font(.caption)
                }
            }
            
            // My Positions Section
            positionsSection
            
            // Opportunities Section
            opportunitiesSection
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #endif
        .refreshable {
            await viewModel.refreshFromNetwork()
        }
    }
    
    // MARK: - Positions Section
    
    private var positionsSection: some View {
        Section {
            if viewModel.state.positions.isEmpty {
                HStack {
                    Image(systemName: "tray")
                    Text("No active positions")
                        .foregroundColor(.secondary)
                }
            } else {
                ForEach(viewModel.state.positions) { position in
                    PositionRowView(position: position) {
                        viewModel.selectPositionForUnstake(position)
                        showUnstakeSheet = true
                    }
                }
            }
        } header: {
            Text("My Positions")
        }
    }
    
    // MARK: - Opportunities Section
    
    private var opportunitiesSection: some View {
        Section {
            if viewModel.filteredOpportunities.isEmpty {
                Text("No opportunities found")
                    .foregroundColor(.secondary)
            } else {
                ForEach(viewModel.filteredOpportunities) { opportunity in
                    OpportunityRowView(opportunity: opportunity) {
                        viewModel.selectOpportunity(opportunity)
                        showStakeSheet = true
                    }
                }
            }
        } header: {
            HStack {
                Text("Opportunities")
                Spacer()
                Text("\(viewModel.filteredOpportunities.count) available")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Error Binding
    
    private var showErrorBinding: Binding<Bool> {
        Binding(
            get: {
                if case .error = viewModel.state { return true }
                return false
            },
            set: { _ in }
        )
    }
}

// MARK: - Position Row View

struct PositionRowView: View {
    let position: StakingPosition
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(position.protocol.displayName)
                            .font(.headline)
                        Text(position.stakedAsset.symbol)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text(position.formattedStakedAmount)
                            .font(.headline)
                        Text(position.stakedAsset.symbol)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    Text("Staked \(position.formattedTimeStaked) ago")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if position.isUnbonding {
                        Text("Unbonding...")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Opportunity Row View

struct OpportunityRowView: View {
    let opportunity: YieldOpportunity
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    // Protocol Info
                    VStack(alignment: .leading) {
                        HStack {
                            Image(systemName: opportunity.protocol.iconName)
                            Text(opportunity.protocol.displayName)
                                .font(.headline)
                        }
                        
                        Text("Stake \(opportunity.inputAsset.symbol)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // APY
                    VStack(alignment: .trailing) {
                        Text(opportunity.formattedAPY)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        
                        Text("APY")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    // Risk Badge
                    Text(opportunity.riskLevel.displayName)
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(riskColor.opacity(0.2))
                        .cornerRadius(4)
                    
                    // Lockup Badge
                    Text(opportunity.lockup.displayText)
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(4)
                    
                    Spacer()
                    
                    // TVL
                    if let tvl = opportunity.formattedTVL {
                        Text("TVL: \(tvl)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
    
    private var riskColor: Color {
        switch opportunity.riskLevel {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .veryHigh: return .red
        }
    }
}

// MARK: - Stake Sheet View

struct StakeSheetView: View {
    @ObservedObject var viewModel: EarnViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let opportunity = viewModel.selectedOpportunity {
                    // Opportunity Details
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: opportunity.protocol.iconName)
                            Text(opportunity.protocol.displayName)
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        
                        HStack {
                            Text("APY")
                            Spacer()
                            Text(opportunity.formattedAPY)
                                .foregroundColor(.green)
                        }
                        
                        HStack {
                            Text("Risk")
                            Spacer()
                            Text(opportunity.riskLevel.displayName)
                        }
                        
                        HStack {
                            Text("Lockup")
                            Spacer()
                            Text(opportunity.lockup.displayText)
                        }
                        
                        if let description = opportunity.strategyDescription {
                            Text(description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.05))
                    .cornerRadius(12)
                    
                    // Amount Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Amount to Stake")
                            .font(.caption)
                        
                        HStack {
                            TextField("0.0", text: $viewModel.stakingAmount)
                                .font(.title)
                                #if os(iOS)
                                .keyboardType(.decimalPad)
                                #endif
                            
                            Text(opportunity.inputAsset.symbol)
                                .fontWeight(.semibold)
                        }
                        
                        if let minimum = opportunity.minimumStake {
                            Text("Minimum: \(minimum)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.05))
                    .cornerRadius(12)
                    
                    // Simulation Status
                    simulationStatus
                    
                    Spacer()
                    
                    // Action Buttons
                    actionButtons
                }
            }
            .padding()
            .navigationTitle("Stake")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.cancelOperation()
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var simulationStatus: some View {
        Group {
            switch viewModel.state {
            case .simulating:
                HStack {
                    ProgressView()
                    Text("Simulating transaction...")
                }
                
            case .readyToExecute(_, let receipt):
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
                
            case .executing:
                HStack {
                    ProgressView()
                    Text("Processing...")
                }
                
            case .success(let hash):
                VStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.green)
                    Text("Success!")
                    Text(hash)
                        .font(.caption)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                
            default:
                EmptyView()
            }
        }
        .padding()
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            switch viewModel.state {
            case .staking, .error:
                Button {
                    Task {
                        await viewModel.simulateStake()
                    }
                } label: {
                    Text("Simulate")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.canStake ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(!viewModel.canStake)
                
            case .readyToExecute:
                Button {
                    Task {
                        await viewModel.executeStake()
                    }
                } label: {
                    Text(viewModel.requiresApproval ? "Approve & Stake" : "Stake Now")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                
            case .success:
                Button {
                    viewModel.reset()
                    dismiss()
                } label: {
                    Text("Done")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                
            default:
                EmptyView()
            }
        }
    }
}

// MARK: - Unstake Sheet View

struct UnstakeSheetView: View {
    @ObservedObject var viewModel: EarnViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let position = viewModel.selectedPosition {
                    // Position Details
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(position.protocol.displayName)
                                .font(.title2)
                                .fontWeight(.bold)
                            Spacer()
                        }
                        
                        HStack {
                            Text("Staked Amount")
                            Spacer()
                            Text("\(position.formattedStakedAmount) \(position.stakedAsset.symbol)")
                        }
                        
                        HStack {
                            Text("Time Staked")
                            Spacer()
                            Text(position.formattedTimeStaked)
                        }
                        
                        HStack {
                            Text("Rewards Earned")
                            Spacer()
                            Text("\(position.formattedRewards) \(position.stakedAsset.symbol)")
                                .foregroundColor(.green)
                        }
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.05))
                    .cornerRadius(12)
                    
                    // Amount Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Amount to Unstake")
                            .font(.caption)
                        
                        HStack {
                            TextField("0.0", text: $viewModel.unstakingAmount)
                                .font(.title)
                                #if os(iOS)
                                .keyboardType(.decimalPad)
                                #endif
                            
                            Button("Max") {
                                viewModel.unstakingAmount = position.formattedStakedAmount
                            }
                            .font(.caption)
                        }
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.05))
                    .cornerRadius(12)
                    
                    Spacer()
                    
                    // Unstake Button
                    Button {
                        Task {
                            await viewModel.simulateUnstake()
                        }
                    } label: {
                        Text("Unstake")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(!viewModel.unstakingAmount.isEmpty ? Color.red : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(viewModel.unstakingAmount.isEmpty)
                }
            }
            .padding()
            .navigationTitle("Unstake")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.cancelOperation()
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Filter Sheet View

struct FilterSheetView: View {
    @ObservedObject var viewModel: EarnViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                // Sort Order
                Section("Sort By") {
                    Picker("Sort", selection: $viewModel.sortOrder) {
                        ForEach(EarnViewModel.SortOrder.allCases, id: \.self) { order in
                            Text(order.rawValue).tag(order)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
                
                // Protocol Filter
                Section("Protocol") {
                    Button("All Protocols") {
                        viewModel.protocolFilter = nil
                    }
                    .foregroundColor(viewModel.protocolFilter == nil ? .blue : .primary)
                    
                    ForEach(YieldProtocol.allCases, id: \.self) { protocol_ in
                        Button(protocol_.displayName) {
                            viewModel.protocolFilter = protocol_
                        }
                        .foregroundColor(viewModel.protocolFilter == protocol_ ? .blue : .primary)
                    }
                }
                
                // Risk Filter
                Section("Risk Level") {
                    Button("All Risk Levels") {
                        viewModel.riskFilter = nil
                    }
                    .foregroundColor(viewModel.riskFilter == nil ? .blue : .primary)
                    
                    ForEach(YieldRiskLevel.allCases, id: \.self) { level in
                        Button(level.displayName) {
                            viewModel.riskFilter = level
                        }
                        .foregroundColor(viewModel.riskFilter == level ? .blue : .primary)
                    }
                }
            }
            .navigationTitle("Filters")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        viewModel.applyFilters()
                        dismiss()
                    }
                }
            }
        }
    }
}


