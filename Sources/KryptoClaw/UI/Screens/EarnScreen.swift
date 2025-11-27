// KRYPTOCLAW EARN SCREEN
// Yield opportunities. Clear presentation.
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

import SwiftUI

public struct EarnScreen: View {
    @EnvironmentObject var walletState: WalletStateManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedOpportunity: EarnOpportunity?
    
    // Mock data
    private let opportunities: [EarnOpportunity] = [
        EarnOpportunity(id: "1", name: "ETH Staking", token: "ETH", apy: 4.5, tvl: 1_250_000_000, risk: .low, protocol: "Lido"),
        EarnOpportunity(id: "2", name: "USDC Lending", token: "USDC", apy: 8.2, tvl: 890_000_000, risk: .low, protocol: "Aave"),
        EarnOpportunity(id: "3", name: "ETH-USDC LP", token: "ETH", apy: 12.5, tvl: 450_000_000, risk: .medium, protocol: "Uniswap"),
        EarnOpportunity(id: "4", name: "SOL Staking", token: "SOL", apy: 6.8, tvl: 320_000_000, risk: .low, protocol: "Marinade"),
    ]
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                KC.Color.bg.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: KC.Space.xxl) {
                        // Summary card
                        summaryCard
                        
                        // Opportunities
                        opportunitiesSection
                    }
                    .padding(.top, KC.Space.lg)
                    .padding(.bottom, KC.Space.xxxl)
                }
            }
            .navigationTitle("Earn")
            .kcNavigationLarge()
            .toolbar {
                ToolbarItem(placement: .kcTrailing) {
                    KCCloseButton { dismiss() }
                }
            }
            .sheet(item: $selectedOpportunity) { opp in
                EarnDetailSheet(opportunity: opp)
            }
        }
    }
    
    // MARK: - Summary Card
    
    private var summaryCard: some View {
        VStack(spacing: KC.Space.lg) {
            HStack {
                VStack(alignment: .leading, spacing: KC.Space.xs) {
                    Text("EARNING")
                        .font(KC.Font.label)
                        .tracking(1.5)
                        .foregroundColor(KC.Color.textMuted)
                    
                    Text("$0.00")
                        .font(KC.Font.title1)
                        .foregroundColor(KC.Color.textPrimary)
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(KC.Color.positive.opacity(0.15))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(KC.Color.positive)
                }
            }
            
            Divider().background(KC.Color.divider)
            
            HStack {
                StatItem(label: "Avg APY", value: "0%")
                Spacer()
                StatItem(label: "Monthly Est.", value: "$0.00")
                Spacer()
                StatItem(label: "Positions", value: "0")
            }
        }
        .padding(KC.Space.xl)
        .background(KC.Color.card)
        .clipShape(RoundedRectangle(cornerRadius: KC.Radius.xl))
        .overlay(
            RoundedRectangle(cornerRadius: KC.Radius.xl)
                .stroke(KC.Color.border, lineWidth: 1)
        )
        .kcPadding()
    }
    
    // MARK: - Opportunities
    
    private var opportunitiesSection: some View {
        VStack(alignment: .leading, spacing: KC.Space.lg) {
            KCSectionHeader("Opportunities")
                .kcPadding()
            
            VStack(spacing: KC.Space.sm) {
                ForEach(opportunities) { opp in
                    EarnOpportunityRow(opportunity: opp)
                        .onTapGesture {
                            HapticEngine.shared.play(.selection)
                            selectedOpportunity = opp
                        }
                }
            }
            .kcPadding()
        }
    }
}

// MARK: - Stat Item

private struct StatItem: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(KC.Font.bodyLarge)
                .foregroundColor(KC.Color.textPrimary)
            
            Text(label)
                .font(KC.Font.caption)
                .foregroundColor(KC.Color.textTertiary)
        }
    }
}

// MARK: - Opportunity Row

private struct EarnOpportunityRow: View {
    let opportunity: EarnOpportunity
    
    var body: some View {
        HStack(spacing: KC.Space.lg) {
            // Token icon
            KCTokenIcon(opportunity.token)
            
            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(opportunity.name)
                    .font(KC.Font.body)
                    .foregroundColor(KC.Color.textPrimary)
                
                HStack(spacing: KC.Space.sm) {
                    Text(opportunity.protocol)
                        .font(KC.Font.caption)
                        .foregroundColor(KC.Color.textTertiary)
                    
                    RiskBadge(risk: opportunity.risk)
                }
            }
            
            Spacer()
            
            // APY
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(String(format: "%.1f", opportunity.apy))%")
                    .font(KC.Font.bodyLarge)
                    .foregroundColor(KC.Color.positive)
                
                Text("APY")
                    .font(KC.Font.caption)
                    .foregroundColor(KC.Color.textTertiary)
            }
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(KC.Color.textMuted)
        }
        .padding(KC.Space.lg)
        .background(KC.Color.card)
        .clipShape(RoundedRectangle(cornerRadius: KC.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: KC.Radius.md)
                .stroke(KC.Color.border, lineWidth: 1)
        )
    }
}

// MARK: - Risk Badge

private struct RiskBadge: View {
    let risk: EarnOpportunity.Risk
    
    var color: Color {
        switch risk {
        case .low: return KC.Color.positive
        case .medium: return KC.Color.warning
        case .high: return KC.Color.negative
        }
    }
    
    var body: some View {
        Text(risk.rawValue.uppercased())
            .font(KC.Font.micro)
            .foregroundColor(color)
            .padding(.horizontal, KC.Space.sm)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
    }
}

// MARK: - Earn Detail Sheet

struct EarnDetailSheet: View {
    let opportunity: EarnOpportunity
    @Environment(\.dismiss) private var dismiss
    @State private var amount = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                KC.Color.bg.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: KC.Space.xl) {
                            // Header
                            VStack(spacing: KC.Space.lg) {
                                KCTokenIcon(opportunity.token, size: 64)
                                
                                VStack(spacing: KC.Space.sm) {
                                    Text(opportunity.name)
                                        .font(KC.Font.title2)
                                        .foregroundColor(KC.Color.textPrimary)
                                    
                                    Text("via \(opportunity.protocol)")
                                        .font(KC.Font.body)
                                        .foregroundColor(KC.Color.textTertiary)
                                }
                                
                                // APY highlight
                                HStack(spacing: KC.Space.sm) {
                                    Text("\(String(format: "%.1f", opportunity.apy))%")
                                        .font(KC.Font.title1)
                                        .foregroundColor(KC.Color.positive)
                                    
                                    Text("APY")
                                        .font(KC.Font.body)
                                        .foregroundColor(KC.Color.textTertiary)
                                }
                            }
                            .padding(.top, KC.Space.xl)
                            
                            // Stats
                            VStack(spacing: 0) {
                                DetailStatRow(label: "Total Value Locked", value: formatTVL(opportunity.tvl))
                                Divider().background(KC.Color.divider)
                                DetailStatRow(label: "Risk Level", value: opportunity.risk.rawValue.capitalized, valueColor: riskColor)
                                Divider().background(KC.Color.divider)
                                DetailStatRow(label: "Token", value: opportunity.token)
                            }
                            .background(KC.Color.card)
                            .clipShape(RoundedRectangle(cornerRadius: KC.Radius.lg))
                            .overlay(
                                RoundedRectangle(cornerRadius: KC.Radius.lg)
                                    .stroke(KC.Color.border, lineWidth: 1)
                            )
                            .kcPadding()
                            
                            // Amount input
                            VStack(alignment: .leading, spacing: KC.Space.sm) {
                                Text("AMOUNT TO STAKE")
                                    .font(KC.Font.label)
                                    .tracking(1.5)
                                    .foregroundColor(KC.Color.textMuted)
                                
                                KCInput("0.0", text: $amount)
                            }
                            .kcPadding()
                        }
                    }
                    
                    // Stake button
                    KCButton("Stake \(opportunity.token)", icon: "lock") {
                        // Stake action
                        HapticEngine.shared.play(.success)
                        dismiss()
                    }
                    .kcPadding()
                    .padding(.bottom, KC.Space.xxxl)
                    .disabled(amount.isEmpty)
                }
            }
            .kcNavigationInline()
            .toolbar {
                ToolbarItem(placement: .kcTrailing) {
                    KCCloseButton { dismiss() }
                }
            }
        }
    }
    
    private var riskColor: Color {
        switch opportunity.risk {
        case .low: return KC.Color.positive
        case .medium: return KC.Color.warning
        case .high: return KC.Color.negative
        }
    }
    
    private func formatTVL(_ value: Double) -> String {
        if value >= 1_000_000_000 {
            return String(format: "$%.1fB", value / 1_000_000_000)
        } else if value >= 1_000_000 {
            return String(format: "$%.1fM", value / 1_000_000)
        } else {
            return String(format: "$%.0f", value)
        }
    }
}

private struct DetailStatRow: View {
    let label: String
    let value: String
    var valueColor: Color = KC.Color.textPrimary
    
    var body: some View {
        HStack {
            Text(label)
                .font(KC.Font.body)
                .foregroundColor(KC.Color.textTertiary)
            Spacer()
            Text(value)
                .font(KC.Font.body)
                .foregroundColor(valueColor)
        }
        .padding(KC.Space.lg)
    }
}

// MARK: - Models

struct EarnOpportunity: Identifiable {
    let id: String
    let name: String
    let token: String
    let apy: Double
    let tvl: Double
    let risk: Risk
    let `protocol`: String
    
    enum Risk: String {
        case low, medium, high
    }
}

#Preview {
    EarnScreen()
}

