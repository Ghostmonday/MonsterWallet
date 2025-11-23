import SwiftUI

public struct OnboardingView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var wsm: WalletStateManager
    
    let onComplete: () -> Void
    
    @State private var isCreating = false
    @State private var isImporting = false
    @State private var importText = ""
    @State private var createdMnemonic: String? = nil
    @State private var showBackupSheet = false
    
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
                    Image("AppIcon")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .cornerRadius(2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
                                .stroke(themeManager.currentTheme.borderColor, lineWidth: 1)
                        )
                        .shadow(color: themeManager.currentTheme.accentColor.opacity(0.3), radius: 20, x: 0, y: 0)
                    
                    VStack(spacing: 8) {
                        Text("KRYPTOCLAW")
                            .font(themeManager.currentTheme.font(style: .largeTitle))
                            .tracking(2)
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
                .padding(.bottom, 20)

                // Footer (Compliance)
                VStack(spacing: 12) {
                    Text("By proceeding, you agree to our Terms of Service.")
                        .font(themeManager.currentTheme.font(style: .caption))
                        .foregroundColor(themeManager.currentTheme.textSecondary)

                    HStack(spacing: 20) {
                        Link("Terms", destination: AppConfig.supportURL)
                        Link("Privacy Policy", destination: AppConfig.privacyPolicyURL)
                    }
                    .font(themeManager.currentTheme.font(style: .caption))
                    .foregroundColor(themeManager.currentTheme.accentColor)
                }
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $isImporting) {
            ImportWalletView(isPresented: $isImporting, onImport: { seed in
                importWallet(seed: seed)
            })
        }
        .sheet(isPresented: $showBackupSheet) {
            if let mnemonic = createdMnemonic {
                BackupMnemonicView(mnemonic: mnemonic) {
                    completeOnboarding()
                }
            }
        }
    }
    
    func createWallet() {
        Task {
            if let mnemonic = await wsm.createWallet(name: "Main Wallet") {
                createdMnemonic = mnemonic
                showBackupSheet = true
            }
        }
    }
    
    func importWallet(seed: String) {
        Task {
            // Real Import Logic
            if MnemonicService.validate(mnemonic: seed) {
                // We assume WSM has 'importWallet' method now
                await wsm.importWallet(mnemonic: seed)
                completeOnboarding()
            }
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
            #if os(iOS)
            .navigationBarHidden(true)
            #endif
        }
    }
}

struct BackupMnemonicView: View {
    let mnemonic: String
    let onConfirm: () -> Void
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        ZStack {
            themeManager.currentTheme.backgroundMain.ignoresSafeArea()

            VStack(spacing: 24) {
                Text("SECRET KEY")
                    .font(themeManager.currentTheme.font(style: .title2))
                    .foregroundColor(.red)
                    .padding(.top, 40)

                Text("Write this down immediately. Do not share it. We cannot recover it for you.")
                    .font(themeManager.currentTheme.font(style: .body))
                    .foregroundColor(themeManager.currentTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Text(mnemonic)
                    .font(themeManager.currentTheme.addressFont)
                    .foregroundColor(themeManager.currentTheme.textPrimary)
                    .padding()
                    .background(themeManager.currentTheme.backgroundSecondary)
                    .cornerRadius(8)
                    .padding(.horizontal)

                Spacer()

                KryptoButton(
                    title: "I HAVE SAVED IT",
                    icon: "lock.fill",
                    action: onConfirm,
                    isPrimary: true
                )
                .padding(.bottom, 40)
            }
        }
    }
}
