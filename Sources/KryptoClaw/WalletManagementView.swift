import SwiftUI

struct WalletManagementView: View {
    @EnvironmentObject var wsm: WalletStateManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var showingCreate = false
    
    var body: some View {
        ZStack {
            themeManager.currentTheme.backgroundMain.ignoresSafeArea()
            
            VStack(spacing: 0) {
                KryptoHeader(
                    title: "Wallets",
                    onBack: { presentationMode.wrappedValue.dismiss() },
                    actionIcon: "plus",
                    onAction: { showingCreate = true }
                )
                
                List {
                    ForEach(wsm.wallets) { wallet in
                        WalletRow(wallet: wallet, isSelected: wsm.currentAddress == wallet.id)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .onTapGesture {
                                Task {
                                    await wsm.switchWallet(id: wallet.id)
                                }
                            }
                    }
                    .onDelete { indexSet in
                        // Implement delete logic
                    }
                }
                .listStyle(.plain)
            }
        }
        .sheet(isPresented: $showingCreate) {
            WalletCreationView(isPresented: $showingCreate)
        }
        .onAppear {
            KryptoLogger.shared.log(level: .info, category: .lifecycle, message: "ViewDidAppear", metadata: ["view": "WalletManagement"])
        }
    }
}

struct WalletRow: View {
    let wallet: WalletInfo
    let isSelected: Bool
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        KryptoCard {
            HStack {
                Circle()
                    .fill(Color.blue) // Parse colorTheme in real app
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(wallet.name.prefix(1).uppercased())
                            .foregroundColor(.white)
                            .font(.headline)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(wallet.name)
                        .font(themeManager.currentTheme.font(style: .headline))
                        .foregroundColor(themeManager.currentTheme.textPrimary)
                    
                    if isSelected {
                        Text("Active")
                            .font(themeManager.currentTheme.font(style: .caption))
                            .foregroundColor(themeManager.currentTheme.successColor)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(themeManager.currentTheme.successColor)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct WalletCreationView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var wsm: WalletStateManager
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var name = ""
    @State private var step = 0 // 0: Name, 1: Seed, 2: Verify
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.currentTheme.backgroundMain.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    if step == 0 {
                        // Step 1: Name
                        KryptoInput(title: "Wallet Name", placeholder: "My Vault", text: $name)
                        Spacer()
                        KryptoButton(title: "Next", icon: "arrow.right", action: { step = 1 }, isPrimary: true)
                    } else if step == 1 {
                        // Step 2: Seed (Simulation)
                        Text("Secret Recovery Phrase")
                            .font(themeManager.currentTheme.font(style: .headline))
                            .foregroundColor(themeManager.currentTheme.textPrimary)
                        
                        Text("apple banana cherry date elder fig grape honeydew igloo jackfruit kiwi lemon")
                            .padding()
                            .background(themeManager.currentTheme.backgroundSecondary)
                            .cornerRadius(8)
                            .foregroundColor(themeManager.currentTheme.textPrimary)
                        
                        Text("Write this down. We cannot recover it.")
                            .font(themeManager.currentTheme.font(style: .caption))
                            .foregroundColor(themeManager.currentTheme.errorColor)
                        
                        Spacer()
                        
                        KryptoButton(title: "I have saved it", icon: "checkmark", action: { step = 2 }, isPrimary: true)
                    } else {
                        // Step 3: Verify (Skipped for V1 UI Demo)
                        Text("Verification Complete")
                            .foregroundColor(themeManager.currentTheme.successColor)
                        
                        Spacer()
                        
                        KryptoButton(title: "Create Wallet", icon: "lock.fill", action: createWallet, isPrimary: true)
                    }
                }
                .padding()
                .navigationTitle(stepTitle)
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
            }
        }
    }
    
    var stepTitle: String {
        switch step {
        case 0: return "Name Wallet"
        case 1: return "Backup Seed"
        case 2: return "Verify"
        default: return ""
        }
    }
    
    func createWallet() {
        KryptoLogger.shared.log(level: .info, category: .stateTransition, message: "CreateWallet tapped", metadata: ["view": "WalletManagement"])
        Task {
            _ = await wsm.createWallet(name: name)
            isPresented = false
        }
    }
}

