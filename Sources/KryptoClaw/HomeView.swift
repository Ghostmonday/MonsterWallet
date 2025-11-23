import SwiftUI

struct HomeView: View {
    @EnvironmentObject var wsm: WalletStateManager
    @EnvironmentObject var themeManager: ThemeManager
    
    // Navigation State
    @State private var showingSend = false
    @State private var showingReceive = false
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.currentTheme.backgroundMain.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        Image("AppIcon") // Uses the AppIcon from Assets
                            .resizable()
                            .frame(width: 40, height: 40)
                            .cornerRadius(2) // Razor-edged
                            .overlay(
                                RoundedRectangle(cornerRadius: 2)
                                    .stroke(themeManager.currentTheme.borderColor, lineWidth: 2)
                            )
                        
                        Text("KryptoClaw")
                            .font(themeManager.currentTheme.font(style: .title2))
                            .foregroundColor(themeManager.currentTheme.textPrimary)
                        
                        Spacer()
                        Button(action: { showingSettings = true }) {
                            Image(systemName: themeManager.currentTheme.iconSettings)
                                .foregroundColor(themeManager.currentTheme.textSecondary)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Balance Card
                    KryptoCard {
                        VStack(spacing: 12) {
                            Text("Total Balance")
                                .font(themeManager.currentTheme.font(style: .subheadline))
                                .foregroundColor(themeManager.currentTheme.textSecondary)
                            
                            if case .loaded(let balances) = wsm.state {
                                // For V1.0, we just show ETH as the primary display or a sum if we had prices
                                let ethBalance = balances[.ethereum]?.amount ?? "0.00"
                                Text("\(ethBalance) ETH")
                                    .font(themeManager.currentTheme.balanceFont)
                                    .foregroundColor(themeManager.currentTheme.textPrimary)
                            } else if case .loading = wsm.state {
                                ProgressView()
                            } else {
                                Text("$0.00")
                                    .font(themeManager.currentTheme.balanceFont)
                                    .foregroundColor(themeManager.currentTheme.textPrimary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal)
                    
                    // Action Buttons
                    HStack(spacing: 16) {
                        KryptoButton(title: "Send", icon: themeManager.currentTheme.iconSend, action: { showingSend = true }, isPrimary: true)
                        KryptoButton(title: "Receive", icon: themeManager.currentTheme.iconReceive, action: { showingReceive = true }, isPrimary: false)
                    }
                    .padding(.horizontal)
                    
                    // Assets List
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Assets")
                            .font(themeManager.currentTheme.font(style: .headline))
                            .foregroundColor(themeManager.currentTheme.textPrimary)
                            .padding(.horizontal)
                        
                        ScrollView {
                            VStack(spacing: 12) {
                                if case .loaded(let balances) = wsm.state {
                                    ForEach(Chain.allCases, id: \.self) { chain in
                                        if let balance = balances[chain] {
                                            AssetRow(chain: chain, balance: balance)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    Spacer()
                }
            }
            #if os(iOS)
            .navigationBarHidden(true)
            #endif
            .sheet(isPresented: $showingSend) {
                SendView()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }
}

struct AssetRow: View {
    let chain: Chain
    let balance: Balance
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        KryptoCard {
            HStack {
                // Icon placeholder
                Circle()
                    .fill(chainColor(chain))
                    .frame(width: 32, height: 32)
                    .overlay(Text(chain.rawValue.prefix(1).uppercased()).font(.caption).bold().foregroundColor(.white))
                
                Text(chain.rawValue.capitalized)
                    .font(themeManager.currentTheme.font(style: .body))
                    .foregroundColor(themeManager.currentTheme.textPrimary)
                
                Spacer()
                
                Text("\(balance.amount) \(balance.currency)")
                    .font(themeManager.currentTheme.font(style: .body))
                    .foregroundColor(themeManager.currentTheme.textPrimary)
            }
        }
        .padding(.horizontal)
    }
    
    func chainColor(_ chain: Chain) -> Color {
        switch chain {
        case .ethereum: return .blue
        case .solana: return .purple
        case .bitcoin: return .orange
        }
    }
}
