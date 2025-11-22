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
                        Text("Monster Wallet")
                            .font(themeManager.currentTheme.font(style: .title2, weight: .bold))
                            .foregroundColor(themeManager.currentTheme.textPrimary)
                        Spacer()
                        Button(action: { showingSettings = true }) {
                            Image(systemName: themeManager.currentTheme.iconSettings)
                                .foregroundColor(themeManager.currentTheme.textSecondary)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Balance Card
                    MonsterCard {
                        VStack(spacing: 12) {
                            Text("Total Balance")
                                .font(themeManager.currentTheme.font(style: .subheadline, weight: .medium))
                                .foregroundColor(themeManager.currentTheme.textSecondary)
                            
                            if case .loaded(let balance) = wsm.state {
                                // Simple formatter for V1.0
                                Text("\(balance.amount) \(balance.currency)")
                                    .font(themeManager.currentTheme.font(style: .largeTitle, weight: .bold))
                                    .foregroundColor(themeManager.currentTheme.textPrimary)
                            } else if case .loading = wsm.state {
                                ProgressView()
                            } else {
                                Text("$0.00")
                                    .font(themeManager.currentTheme.font(style: .largeTitle, weight: .bold))
                                    .foregroundColor(themeManager.currentTheme.textPrimary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal)
                    
                    // Action Buttons
                    HStack(spacing: 16) {
                        MonsterButton(title: "Send", icon: themeManager.currentTheme.iconSend, action: { showingSend = true }, isPrimary: true)
                        MonsterButton(title: "Receive", icon: themeManager.currentTheme.iconReceive, action: { showingReceive = true }, isPrimary: false)
                    }
                    .padding(.horizontal)
                    
                    // Recent Transactions (Placeholder for V1.0 UI Template)
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Recent Activity")
                            .font(themeManager.currentTheme.font(style: .headline, weight: .bold))
                            .foregroundColor(themeManager.currentTheme.textPrimary)
                            .padding(.horizontal)
                        
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(wsm.history.transactions, id: \.hash) { tx in
                                    MonsterCard {
                                        HStack {
                                            Image(systemName: "arrow.up.right") // Simplified icon logic
                                                .foregroundColor(themeManager.currentTheme.textSecondary)
                                            VStack(alignment: .leading) {
                                                Text(tx.to.prefix(6) + "..." + tx.to.suffix(4))
                                                    .font(themeManager.currentTheme.font(style: .body, weight: .medium))
                                                    .foregroundColor(themeManager.currentTheme.textPrimary)
                                                Text(tx.timestamp.description)
                                                    .font(themeManager.currentTheme.font(style: .caption, weight: .regular))
                                                    .foregroundColor(themeManager.currentTheme.textSecondary)
                                            }
                                            Spacer()
                                            Text(tx.value)
                                                .font(themeManager.currentTheme.font(style: .body, weight: .bold))
                                                .foregroundColor(themeManager.currentTheme.textPrimary)
                                        }
                                    }
                                    .padding(.horizontal)
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
        .onAppear {
            Task {
                // Hardcoded ID for V1.0 Demo
                await wsm.loadAccount(id: "0x1234567890abcdef1234567890abcdef12345678")
            }
        }
    }
}
