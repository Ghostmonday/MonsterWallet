import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var wsm: WalletStateManager
    
    @State private var isCreating = false
    @State private var isImporting = false
    @State private var importText = ""
    
    // Callback to notify App that onboarding is done
    var onComplete: () -> Void
    
    var body: some View {
        ZStack {
            themeManager.currentTheme.backgroundMain.ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Logo & Branding
                VStack(spacing: 16) {
                    Image("AppIcon") // Assuming AppIcon is available in assets
                        .resizable()
                        .frame(width: 120, height: 120)
                        .cornerRadius(24)
                        .shadow(radius: 10)
                    
                    Text("KryptoClaw")
                        .font(themeManager.currentTheme.font(style: .largeTitle, weight: .bold))
                        .foregroundColor(themeManager.currentTheme.textPrimary)
                    
                    Text("The Coloring Book Crypto Wallet")
                        .font(themeManager.currentTheme.font(style: .headline, weight: .medium))
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                }
                
                Spacer()
                
                // Actions
                VStack(spacing: 16) {
                    KryptoButton(
                        title: "Create New Wallet",
                        icon: "plus.circle.fill",
                        action: { createWallet() },
                        isPrimary: true
                    )
                    
                    KryptoButton(
                        title: "Import Wallet",
                        icon: "arrow.down.doc.fill",
                        action: { isImporting = true },
                        isPrimary: false
                    )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
        .sheet(isPresented: $isImporting) {
            ImportWalletView(isPresented: $isImporting, onImport: { seed in
                importWallet(seed: seed)
            })
        }
    }
    
    func createWallet() {
        // In a real app, this would generate a seed phrase
        // For V1.0, we simulate by loading a demo account
        Task {
            await wsm.loadAccount(id: "0x1234567890abcdef1234567890abcdef12345678")
            completeOnboarding()
        }
    }
    
    func importWallet(seed: String) {
        // Simulate import
        Task {
            await wsm.loadAccount(id: "0x1234567890abcdef1234567890abcdef12345678")
            completeOnboarding()
        }
    }
    
    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasOnboarded")
        withAnimation {
            onComplete()
        }
    }
}

struct ImportWalletView: View {
    @Binding var isPresented: Bool
    var onImport: (String) -> Void
    @State private var seedText = ""
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.currentTheme.backgroundMain.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Text("Enter your Recovery Phrase")
                        .font(themeManager.currentTheme.font(style: .title3, weight: .bold))
                        .foregroundColor(themeManager.currentTheme.textPrimary)
                        .padding(.top)
                    
                    TextEditor(text: $seedText)
                        .frame(height: 150)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(themeManager.currentTheme.accentColor, lineWidth: 1)
                        )
                        .foregroundColor(themeManager.currentTheme.textPrimary)
                        .padding(.horizontal)
                    
                    KryptoButton(
                        title: "Import",
                        icon: "checkmark.circle.fill",
                        action: {
                            onImport(seedText)
                            isPresented = false
                        },
                        isPrimary: true
                    )
                    .padding(.horizontal)
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { isPresented = false }
                        .foregroundColor(themeManager.currentTheme.accentColor)
                }
            }
        }
    }
}
