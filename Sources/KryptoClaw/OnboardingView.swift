import SwiftUI

public struct OnboardingView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var wsm: WalletStateManager
    
    let onComplete: () -> Void
    
    @State private var isCreating = false
    @State private var isImporting = false
    @State private var importText = ""
    
    public init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
    }
    
    public var body: some View {
        ZStack {
            themeManager.currentTheme.backgroundMain.ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Logo & Branding
                VStack(spacing: 24) {
                    Image("AppIcon") // Assuming AppIcon is available in assets
                        .resizable()
                        .frame(width: 100, height: 100)
                        .cornerRadius(2) // Razor-edged
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
                                .stroke(themeManager.currentTheme.borderColor, lineWidth: 1)
                        )
                        .shadow(color: themeManager.currentTheme.accentColor.opacity(0.3), radius: 20, x: 0, y: 0)
                    
                    VStack(spacing: 8) {
                        Text("KRYPTOCLAW")
                            .font(themeManager.currentTheme.font(style: .largeTitle))
                            .tracking(2) // Elite spacing
                            .foregroundColor(themeManager.currentTheme.textPrimary)
                        
                        Text("ELITE. SECURE. UNTRACEABLE.")
                            .font(themeManager.currentTheme.font(style: .caption))
                            .tracking(4)
                            .foregroundColor(themeManager.currentTheme.accentColor)
                    }
                }
                
                Spacer()
                
                // Actions
                VStack(spacing: 20) {
                    KryptoButton(
                        title: "INITIATE PROTOCOL",
                        icon: "terminal.fill",
                        action: { createWallet() },
                        isPrimary: true
                    )
                    
                    KryptoButton(
                        title: "RECOVER ASSETS",
                        icon: "arrow.down.doc.fill",
                        action: { isImporting = true },
                        isPrimary: false
                    )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 60)
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
                
                VStack(spacing: 32) {
                    VStack(spacing: 8) {
                        Text("RECOVERY SEQUENCE")
                            .font(themeManager.currentTheme.font(style: .headline))
                            .tracking(2)
                            .foregroundColor(themeManager.currentTheme.textPrimary)
                        
                        Text("Enter your 12 or 24 word phrase")
                            .font(themeManager.currentTheme.font(style: .caption))
                            .foregroundColor(themeManager.currentTheme.textSecondary)
                    }
                    .padding(.top, 32)
                    
                    TextEditor(text: $seedText)
                        .frame(height: 160)
                        .padding()
                        .background(themeManager.currentTheme.backgroundSecondary)
                        .cornerRadius(2) // Razor-edged
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
                                .stroke(themeManager.currentTheme.borderColor, lineWidth: 1)
                        )
                        .foregroundColor(themeManager.currentTheme.textPrimary)
                        .font(themeManager.currentTheme.addressFont)
                        .padding(.horizontal)
                    
                    KryptoButton(
                        title: "EXECUTE RECOVERY",
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
            .navigationBarHidden(true)
        }
    }
}
