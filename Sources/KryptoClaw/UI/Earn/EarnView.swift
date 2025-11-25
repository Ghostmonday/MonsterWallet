// MODULE: EarnView
// VERSION: 1.0.0
// PURPOSE: Polished earn/staking hub with full theme integration

import SwiftUI

// MARK: - Earn View

/// Polished earn/staking interface with theme-driven styling.
///
/// **Sections:**
/// - My Positions: Current staked balances with visual cards
/// - Opportunities: List of yield opportunities with APY highlights
///
/// **Features:**
/// - Stake sheet with input and simulation
/// - Unstake sheet with amount selection
/// - Filter and sort controls
/// - Pull-to-refresh
@available(iOS 15.0, macOS 12.0, *)
struct EarnView: View {
    @EnvironmentObject var themeManager: ThemeManager
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
        let theme = themeManager.currentTheme
        
        NavigationView {
            ZStack {
                Color.clear
                    .themedContainer(theme: theme, showPattern: true, applyAnimation: true)
                    .ignoresSafeArea()
                
                Group {
                    if viewModel.state.isLoading && viewModel.state.opportunities.isEmpty {
                        loadingView(theme: theme)
                    } else {
                        mainContent(theme: theme)
                    }
                }
            }
            .navigationTitle("Earn")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showFilters = true
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(theme.accentColor)
                    }
                }
                
                ToolbarItem(placement: .automatic) {
                    Button {
                        Task {
                            await viewModel.refreshFromNetwork()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(theme.accentColor)
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
    
    private func loadingView(theme: any ThemeProtocolV2) -> some View {
        VStack(spacing: theme.spacingL) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: theme.accentColor))
                .scaleEffect(1.5)
            
            Text("Loading opportunities...")
                .font(theme.bodyFont)
                .foregroundColor(theme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Main Content
    
    private func mainContent(theme: any ThemeProtocolV2) -> some View {
        ScrollView {
            VStack(spacing: theme.spacingL) {
                // Status Banner
                if case .cached = viewModel.state {
                    cachedBanner(theme: theme)
                }
                
                // My Positions Section
                positionsSection(theme: theme)
                
                // Opportunities Section
                opportunitiesSection(theme: theme)
            }
            .padding()
        }
        .refreshable {
            await viewModel.refreshFromNetwork()
        }
    }
    
    // MARK: - Cached Banner
    
    private func cachedBanner(theme: any ThemeProtocolV2) -> some View {
        HStack(spacing: theme.spacingS) {
            Image(systemName: "clock.arrow.circlepath")
                .foregroundColor(theme.textSecondary)
            
            Text("Showing cached data")
                .font(theme.captionFont)
                .foregroundColor(theme.textSecondary)
            
            Spacer()
            
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: theme.accentColor))
                .scaleEffect(0.8)
        }
        .padding()
        .background(theme.backgroundSecondary.opacity(0.8))
        .cornerRadius(theme.cornerRadius)
    }
    
    // MARK: - Positions Section
    
    private func positionsSection(theme: any ThemeProtocolV2) -> some View {
        VStack(alignment: .leading, spacing: theme.spacingM) {
            // Section header
            HStack {
                Image(systemName: "chart.pie.fill")
                    .foregroundColor(theme.accentColor)
                
                Text("My Positions")
                    .font(theme.headlineFont)
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
            }
            
            if viewModel.state.positions.isEmpty {
                // Empty state
                KryptoCard {
                    HStack(spacing: theme.spacingM) {
                        Image(systemName: "tray")
                            .font(.title2)
                            .foregroundColor(theme.textSecondary)
                        
                        VStack(alignment: .leading, spacing: theme.spacingXS) {
                            Text("No active positions")
                                .font(theme.bodyFont)
                                .foregroundColor(theme.textSecondary)
                            
                            Text("Stake your assets to start earning")
                                .font(theme.captionFont)
                                .foregroundColor(theme.textSecondary.opacity(0.7))
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, theme.spacingS)
                }
            } else {
                ForEach(viewModel.state.positions) { position in
                    PositionRowView(position: position) {
                        viewModel.selectPositionForUnstake(position)
                        showUnstakeSheet = true
                    }
                }
            }
        }
    }
    
    // MARK: - Opportunities Section
    
    private func opportunitiesSection(theme: any ThemeProtocolV2) -> some View {
        VStack(alignment: .leading, spacing: theme.spacingM) {
            // Section header
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(theme.accentColor)
                
                Text("Opportunities")
                    .font(theme.headlineFont)
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
                
                Text("\(viewModel.filteredOpportunities.count) available")
                    .font(theme.captionFont)
                    .foregroundColor(theme.textSecondary)
                    .padding(.horizontal, theme.spacingS)
                    .padding(.vertical, theme.spacingXS)
                    .background(theme.backgroundSecondary)
                    .cornerRadius(theme.cornerRadius / 2)
            }
            
            if viewModel.filteredOpportunities.isEmpty {
                KryptoCard {
                    HStack {
                        Spacer()
                        Text("No opportunities found")
                            .font(theme.bodyFont)
                            .foregroundColor(theme.textSecondary)
                        Spacer()
                    }
                    .padding(.vertical, theme.spacingL)
                }
            } else {
                ForEach(viewModel.filteredOpportunities) { opportunity in
                    OpportunityRowView(opportunity: opportunity) {
                        viewModel.selectOpportunity(opportunity)
                        showStakeSheet = true
                    }
                }
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
    @EnvironmentObject var themeManager: ThemeManager
    
    let position: StakingPosition
    let onTap: () -> Void
    
    var body: some View {
        let theme = themeManager.currentTheme
        
        Button(action: onTap) {
            KryptoCard {
                VStack(spacing: theme.spacingM) {
                    HStack {
                        // Protocol icon and name
                        ZStack {
                            Circle()
                                .fill(theme.accentColor.opacity(0.15))
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: position.protocol.iconName)
                                .foregroundColor(theme.accentColor)
                                .font(.title3)
                        }
                        
                        VStack(alignment: .leading, spacing: theme.spacingXS) {
                            Text(position.protocol.displayName)
                                .font(theme.headlineFont)
                                .foregroundColor(theme.textPrimary)
                            
                            Text(position.stakedAsset.symbol)
                                .font(theme.captionFont)
                                .foregroundColor(theme.textSecondary)
                        }
                        
                        Spacer()
                        
                        // Staked amount
                        VStack(alignment: .trailing, spacing: theme.spacingXS) {
                            Text(position.formattedStakedAmount)
                                .font(theme.headlineFont)
                                .foregroundColor(theme.textPrimary)
                            
                            Text(position.stakedAsset.symbol)
                                .font(theme.captionFont)
                                .foregroundColor(theme.textSecondary)
                        }
                    }
                    
                    Divider()
                        .background(theme.borderColor)
                    
                    HStack {
                        // Time staked
                        HStack(spacing: theme.spacingXS) {
                            Image(systemName: "clock")
                                .font(.caption)
                                .foregroundColor(theme.textSecondary)
                            
                            Text("Staked \(position.formattedTimeStaked) ago")
                                .font(theme.captionFont)
                                .foregroundColor(theme.textSecondary)
                        }
                        
                        Spacer()
                        
                        // Status badge
                        if position.isUnbonding {
                            HStack(spacing: theme.spacingXS) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: theme.securityWarningColor))
                                    .scaleEffect(0.6)
                                
                                Text("Unbonding...")
                                    .font(theme.captionFont)
                                    .foregroundColor(theme.securityWarningColor)
                            }
                            .padding(.horizontal, theme.spacingS)
                            .padding(.vertical, theme.spacingXS)
                            .background(theme.securityWarningColor.opacity(0.15))
                            .cornerRadius(theme.cornerRadius / 2)
                        } else {
                            HStack(spacing: theme.spacingXS) {
                                Circle()
                                    .fill(theme.successColor)
                                    .frame(width: 6, height: 6)
                                
                                Text("Active")
                                    .font(theme.captionFont)
                                    .foregroundColor(theme.successColor)
                            }
                            .padding(.horizontal, theme.spacingS)
                            .padding(.vertical, theme.spacingXS)
                            .background(theme.successColor.opacity(0.15))
                            .cornerRadius(theme.cornerRadius / 2)
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Opportunity Row View

struct OpportunityRowView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    let opportunity: YieldOpportunity
    let onTap: () -> Void
    
    var body: some View {
        let theme = themeManager.currentTheme
        
        Button(action: onTap) {
            KryptoCard {
                VStack(spacing: theme.spacingM) {
                    HStack {
                        // Protocol Info
                        ZStack {
                            Circle()
                                .fill(theme.accentColor.opacity(0.15))
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: opportunity.protocol.iconName)
                                .foregroundColor(theme.accentColor)
                                .font(.title3)
                        }
                        
                        VStack(alignment: .leading, spacing: theme.spacingXS) {
                            Text(opportunity.protocol.displayName)
                                .font(theme.headlineFont)
                                .foregroundColor(theme.textPrimary)
                            
                            Text("Stake \(opportunity.inputAsset.symbol)")
                                .font(theme.captionFont)
                                .foregroundColor(theme.textSecondary)
                        }
                        
                        Spacer()
                        
                        // APY
                        VStack(alignment: .trailing, spacing: theme.spacingXS) {
                            Text(opportunity.formattedAPY)
                                .font(theme.font(style: .title2))
                                .fontWeight(.bold)
                                .foregroundColor(theme.successColor)
                            
                            Text("APY")
                                .font(theme.captionFont)
                                .foregroundColor(theme.textSecondary)
                        }
                    }
                    
                    Divider()
                        .background(theme.borderColor)
                    
                    HStack(spacing: theme.spacingS) {
                        // Risk Badge
                        riskBadge(theme: theme)
                        
                        // Lockup Badge
                        lockupBadge(theme: theme)
                        
                        Spacer()
                        
                        // TVL
                        if let tvl = opportunity.formattedTVL {
                            Text("TVL: \(tvl)")
                                .font(theme.captionFont)
                                .foregroundColor(theme.textSecondary)
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    private func riskBadge(theme: any ThemeProtocolV2) -> some View {
        let color = riskColor(theme: theme)
        
        return Text(opportunity.riskLevel.displayName)
            .font(theme.captionFont)
            .fontWeight(.medium)
            .foregroundColor(color)
            .padding(.horizontal, theme.spacingS)
            .padding(.vertical, theme.spacingXS)
            .background(color.opacity(0.15))
            .cornerRadius(theme.cornerRadius / 2)
    }
    
    private func lockupBadge(theme: any ThemeProtocolV2) -> some View {
        Text(opportunity.lockup.displayText)
            .font(theme.captionFont)
            .foregroundColor(theme.textSecondary)
            .padding(.horizontal, theme.spacingS)
            .padding(.vertical, theme.spacingXS)
            .background(theme.backgroundSecondary)
            .cornerRadius(theme.cornerRadius / 2)
    }
    
    private func riskColor(theme: any ThemeProtocolV2) -> Color {
        switch opportunity.riskLevel {
        case .low: return theme.successColor
        case .medium: return theme.securityWarningColor
        case .high: return Color.orange
        case .veryHigh: return theme.errorColor
        }
    }
}

// MARK: - Stake Sheet View

struct StakeSheetView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var viewModel: EarnViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        let theme = themeManager.currentTheme
        
        NavigationView {
            ZStack {
                Color.clear
                    .themedContainer(theme: theme, showPattern: true, applyAnimation: true)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: theme.spacingL) {
                        if let opportunity = viewModel.selectedOpportunity {
                            // Opportunity Details Card
                            opportunityDetailsCard(opportunity: opportunity, theme: theme)
                            
                            // Amount Input Card
                            amountInputCard(opportunity: opportunity, theme: theme)
                            
                            // Simulation Status
                            simulationStatus(theme: theme)
                            
                            Spacer(minLength: theme.spacingXL)
                            
                            // Action Buttons
                            actionButtons(theme: theme)
                        }
                    }
                    .padding()
                }
            }
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
                    .foregroundColor(theme.textSecondary)
                }
            }
        }
    }
    
    private func opportunityDetailsCard(opportunity: YieldOpportunity, theme: any ThemeProtocolV2) -> some View {
        KryptoCard {
            VStack(alignment: .leading, spacing: theme.spacingM) {
                // Header
                HStack(spacing: theme.spacingM) {
                    ZStack {
                        Circle()
                            .fill(theme.accentColor.opacity(0.15))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: opportunity.protocol.iconName)
                            .foregroundColor(theme.accentColor)
                            .font(.title2)
                    }
                    
                    Text(opportunity.protocol.displayName)
                        .font(theme.font(style: .title2))
                        .fontWeight(.bold)
                        .foregroundColor(theme.textPrimary)
                    
                    Spacer()
                }
                
                Divider()
                    .background(theme.borderColor)
                
                // Stats
                HStack {
                    Text("APY")
                        .font(theme.bodyFont)
                        .foregroundColor(theme.textSecondary)
                    Spacer()
                    Text(opportunity.formattedAPY)
                        .font(theme.headlineFont)
                        .foregroundColor(theme.successColor)
                }
                
                HStack {
                    Text("Risk")
                        .font(theme.bodyFont)
                        .foregroundColor(theme.textSecondary)
                    Spacer()
                    Text(opportunity.riskLevel.displayName)
                        .font(theme.headlineFont)
                        .foregroundColor(theme.textPrimary)
                }
                
                HStack {
                    Text("Lockup")
                        .font(theme.bodyFont)
                        .foregroundColor(theme.textSecondary)
                    Spacer()
                    Text(opportunity.lockup.displayText)
                        .font(theme.headlineFont)
                        .foregroundColor(theme.textPrimary)
                }
                
                if let description = opportunity.strategyDescription {
                    Text(description)
                        .font(theme.captionFont)
                        .foregroundColor(theme.textSecondary)
                        .padding(.top, theme.spacingS)
                }
            }
        }
    }
    
    private func amountInputCard(opportunity: YieldOpportunity, theme: any ThemeProtocolV2) -> some View {
        KryptoCard {
            VStack(alignment: .leading, spacing: theme.spacingM) {
                Text("Amount to Stake")
                    .font(theme.captionFont)
                    .foregroundColor(theme.textSecondary)
                
                HStack {
                    TextField("0.0", text: $viewModel.stakingAmount)
                        .font(theme.balanceFont)
                        .foregroundColor(theme.textPrimary)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                    
                    Text(opportunity.inputAsset.symbol)
                        .font(theme.headlineFont)
                        .foregroundColor(theme.textSecondary)
                }
                
                if let minimum = opportunity.minimumStake {
                    Text("Minimum: \(minimum)")
                        .font(theme.captionFont)
                        .foregroundColor(theme.textSecondary)
                }
            }
        }
    }
    
    @ViewBuilder
    private func simulationStatus(theme: any ThemeProtocolV2) -> some View {
        switch viewModel.state {
        case .simulating:
            KryptoCard {
                HStack(spacing: theme.spacingM) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: theme.accentColor))
                    Text("Simulating transaction...")
                        .font(theme.bodyFont)
                        .foregroundColor(theme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, theme.spacingM)
            }
            
        case .readyToExecute(_, let receipt):
            KryptoCard {
                VStack(spacing: theme.spacingM) {
                    HStack(spacing: theme.spacingS) {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundColor(theme.successColor)
                            .font(.title2)
                        
                        Text("Simulation passed")
                            .font(theme.headlineFont)
                            .foregroundColor(theme.successColor)
                    }
                    
                    Text("Gas estimate: \(receipt.gasEstimate)")
                        .font(theme.captionFont)
                        .foregroundColor(theme.textSecondary)
                    
                    if viewModel.requiresApproval {
                        HStack(spacing: theme.spacingS) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(theme.securityWarningColor)
                            Text("Token approval required")
                                .font(theme.captionFont)
                                .foregroundColor(theme.securityWarningColor)
                        }
                        .padding()
                        .background(theme.securityWarningColor.opacity(0.15))
                        .cornerRadius(theme.cornerRadius)
                    }
                }
            }
            
        case .executing:
            KryptoCard {
                HStack(spacing: theme.spacingM) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: theme.accentColor))
                    Text("Processing...")
                        .font(theme.bodyFont)
                        .foregroundColor(theme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, theme.spacingM)
            }
            
        case .success(let hash):
            KryptoCard {
                VStack(spacing: theme.spacingM) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(theme.successColor)
                    
                    Text("Success!")
                        .font(theme.headlineFont)
                        .foregroundColor(theme.successColor)
                    
                    Text(hash)
                        .font(theme.addressFont)
                        .foregroundColor(theme.textSecondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, theme.spacingM)
            }
            
        default:
            EmptyView()
        }
    }
    
    @ViewBuilder
    private func actionButtons(theme: any ThemeProtocolV2) -> some View {
        switch viewModel.state {
        case .staking, .error:
            KryptoButton(
                title: "Simulate",
                icon: "bolt.fill",
                action: {
                    Task { await viewModel.simulateStake() }
                },
                isPrimary: true
            )
            .disabled(!viewModel.canStake)
            .opacity(viewModel.canStake ? 1.0 : 0.5)
            
        case .readyToExecute:
            KryptoButton(
                title: viewModel.requiresApproval ? "Approve & Stake" : "Stake Now",
                icon: "arrow.right.circle.fill",
                action: {
                    Task { await viewModel.executeStake() }
                },
                isPrimary: true
            )
            
        case .success:
            KryptoButton(
                title: "Done",
                icon: "checkmark.circle.fill",
                action: {
                    viewModel.reset()
                    dismiss()
                },
                isPrimary: true
            )
            
        default:
            EmptyView()
        }
    }
}

// MARK: - Unstake Sheet View

struct UnstakeSheetView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var viewModel: EarnViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        let theme = themeManager.currentTheme
        
        NavigationView {
            ZStack {
                Color.clear
                    .themedContainer(theme: theme, showPattern: true, applyAnimation: true)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: theme.spacingL) {
                        if let position = viewModel.selectedPosition {
                            // Position Details Card
                            positionDetailsCard(position: position, theme: theme)
                            
                            // Amount Input Card
                            amountInputCard(position: position, theme: theme)
                            
                            Spacer(minLength: theme.spacingXL)
                            
                            // Unstake Button
                            KryptoButton(
                                title: "Unstake",
                                icon: "arrow.down.circle.fill",
                                action: {
                                    Task { await viewModel.simulateUnstake() }
                                },
                                isPrimary: true
                            )
                            .disabled(viewModel.unstakingAmount.isEmpty)
                            .opacity(viewModel.unstakingAmount.isEmpty ? 0.5 : 1.0)
                        }
                    }
                    .padding()
                }
            }
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
                    .foregroundColor(theme.textSecondary)
                }
            }
        }
    }
    
    private func positionDetailsCard(position: StakingPosition, theme: any ThemeProtocolV2) -> some View {
        KryptoCard {
            VStack(alignment: .leading, spacing: theme.spacingM) {
                Text(position.protocol.displayName)
                    .font(theme.font(style: .title2))
                    .fontWeight(.bold)
                    .foregroundColor(theme.textPrimary)
                
                Divider()
                    .background(theme.borderColor)
                
                HStack {
                    Text("Staked Amount")
                        .font(theme.bodyFont)
                        .foregroundColor(theme.textSecondary)
                    Spacer()
                    Text("\(position.formattedStakedAmount) \(position.stakedAsset.symbol)")
                        .font(theme.headlineFont)
                        .foregroundColor(theme.textPrimary)
                }
                
                HStack {
                    Text("Time Staked")
                        .font(theme.bodyFont)
                        .foregroundColor(theme.textSecondary)
                    Spacer()
                    Text(position.formattedTimeStaked)
                        .font(theme.headlineFont)
                        .foregroundColor(theme.textPrimary)
                }
                
                HStack {
                    Text("Rewards Earned")
                        .font(theme.bodyFont)
                        .foregroundColor(theme.textSecondary)
                    Spacer()
                    Text("\(position.formattedRewards) \(position.stakedAsset.symbol)")
                        .font(theme.headlineFont)
                        .foregroundColor(theme.successColor)
                }
            }
        }
    }
    
    private func amountInputCard(position: StakingPosition, theme: any ThemeProtocolV2) -> some View {
        KryptoCard {
            VStack(alignment: .leading, spacing: theme.spacingM) {
                Text("Amount to Unstake")
                    .font(theme.captionFont)
                    .foregroundColor(theme.textSecondary)
                
                HStack {
                    TextField("0.0", text: $viewModel.unstakingAmount)
                        .font(theme.balanceFont)
                        .foregroundColor(theme.textPrimary)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                    
                    Button("Max") {
                        viewModel.unstakingAmount = position.formattedStakedAmount
                    }
                    .font(theme.captionFont)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.accentColor)
                    .padding(.horizontal, theme.spacingM)
                    .padding(.vertical, theme.spacingS)
                    .background(theme.accentColor.opacity(0.15))
                    .cornerRadius(theme.cornerRadius)
                }
            }
        }
    }
}

// MARK: - Filter Sheet View

struct FilterSheetView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var viewModel: EarnViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        let theme = themeManager.currentTheme
        
        NavigationView {
            ZStack {
                Color.clear
                    .themedContainer(theme: theme, showPattern: true, applyAnimation: true)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: theme.spacingL) {
                        // Sort Order Section
                        sortOrderSection(theme: theme)
                        
                        // Protocol Filter Section
                        protocolFilterSection(theme: theme)
                        
                        // Risk Filter Section
                        riskFilterSection(theme: theme)
                    }
                    .padding()
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
                    .fontWeight(.semibold)
                    .foregroundColor(theme.accentColor)
                }
            }
        }
    }
    
    private func sortOrderSection(theme: any ThemeProtocolV2) -> some View {
        KryptoCard {
            VStack(alignment: .leading, spacing: theme.spacingM) {
                Text("Sort By")
                    .font(theme.headlineFont)
                    .foregroundColor(theme.textPrimary)
                
                ForEach(EarnViewModel.SortOrder.allCases, id: \.self) { order in
                    Button {
                        viewModel.sortOrder = order
                    } label: {
                        HStack {
                            Text(order.rawValue)
                                .font(theme.bodyFont)
                                .foregroundColor(theme.textPrimary)
                            
                            Spacer()
                            
                            if viewModel.sortOrder == order {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(theme.accentColor)
                            }
                        }
                        .padding(.vertical, theme.spacingS)
                    }
                }
            }
        }
    }
    
    private func protocolFilterSection(theme: any ThemeProtocolV2) -> some View {
        KryptoCard {
            VStack(alignment: .leading, spacing: theme.spacingM) {
                Text("Protocol")
                    .font(theme.headlineFont)
                    .foregroundColor(theme.textPrimary)
                
                Button {
                    viewModel.protocolFilter = nil
                } label: {
                    HStack {
                        Text("All Protocols")
                            .font(theme.bodyFont)
                            .foregroundColor(theme.textPrimary)
                        
                        Spacer()
                        
                        if viewModel.protocolFilter == nil {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(theme.accentColor)
                        }
                    }
                    .padding(.vertical, theme.spacingS)
                }
                
                ForEach(YieldProtocol.allCases, id: \.self) { protocol_ in
                    Button {
                        viewModel.protocolFilter = protocol_
                    } label: {
                        HStack {
                            Text(protocol_.displayName)
                                .font(theme.bodyFont)
                                .foregroundColor(theme.textPrimary)
                            
                            Spacer()
                            
                            if viewModel.protocolFilter == protocol_ {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(theme.accentColor)
                            }
                        }
                        .padding(.vertical, theme.spacingS)
                    }
                }
            }
        }
    }
    
    private func riskFilterSection(theme: any ThemeProtocolV2) -> some View {
        KryptoCard {
            VStack(alignment: .leading, spacing: theme.spacingM) {
                Text("Risk Level")
                    .font(theme.headlineFont)
                    .foregroundColor(theme.textPrimary)
                
                Button {
                    viewModel.riskFilter = nil
                } label: {
                    HStack {
                        Text("All Risk Levels")
                            .font(theme.bodyFont)
                            .foregroundColor(theme.textPrimary)
                        
                        Spacer()
                        
                        if viewModel.riskFilter == nil {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(theme.accentColor)
                        }
                    }
                    .padding(.vertical, theme.spacingS)
                }
                
                ForEach(YieldRiskLevel.allCases, id: \.self) { level in
                    Button {
                        viewModel.riskFilter = level
                    } label: {
                        HStack {
                            Text(level.displayName)
                                .font(theme.bodyFont)
                                .foregroundColor(theme.textPrimary)
                            
                            Spacer()
                            
                            if viewModel.riskFilter == level {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(theme.accentColor)
                            }
                        }
                        .padding(.vertical, theme.spacingS)
                    }
                }
            }
        }
    }
}
