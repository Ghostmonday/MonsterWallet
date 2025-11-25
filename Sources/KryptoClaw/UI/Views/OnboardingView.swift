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
    @State private var showHSKFlow = false

    public init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
    }

    public var body: some View {
        let theme = themeManager.currentTheme
        
        ZStack {
            Color.clear
                .themedContainer(theme: theme, showPattern: true, applyAnimation: true)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo & Branding
                VStack(spacing: theme.spacingXL) {
                    Image("Logo")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .cornerRadius(theme.cornerRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: theme.cornerRadius)
                                .stroke(theme.borderColor, lineWidth: 1)
                        )
                        .shadow(color: theme.accentColor.opacity(0.3), radius: 20, x: 0, y: 0)

                    VStack(spacing: theme.spacingS) {
                        Text("KRYPTOCLAW")
                            .font(theme.font(style: .largeTitle))
                            .tracking(2)
                            .foregroundColor(theme.textPrimary)

                        Text("ELITE. SECURE. UNTRACEABLE.")
                            .font(theme.font(style: .caption))
                            .tracking(4)
                            .foregroundColor(theme.accentColor)
                    }
                }

                Spacer()

                // Actions
                VStack(spacing: theme.spacingXL) {
                    KryptoProgressButton(
                        title: "INITIATE PROTOCOL",
                        icon: "terminal.fill",
                        isLoading: isCreating,
                        isPrimary: true
                    ) {
                        createWallet()
                    }

                    KryptoButton(
                        title: "RECOVER ASSETS",
                        icon: "arrow.down.doc.fill",
                        action: { isImporting = true },
                        isPrimary: false
                    )
                    
                    // HSK Wallet Option
                    if #available(iOS 15.0, macOS 12.0, *) {
                        KryptoButton(
                            title: "USE HARDWARE KEY",
                            icon: "key.horizontal.fill",
                            action: { showHSKFlow = true },
                            isPrimary: false
                        )
                    }
                }
                .padding(.horizontal, theme.spacingXL)
                .padding(.bottom, theme.spacingXL)

                VStack(spacing: theme.spacingM) {
                    Text("By proceeding, you agree to our Terms of Service.")
                        .font(theme.font(style: .caption))
                        .foregroundColor(theme.textSecondary)

                    HStack(spacing: theme.spacingXL) {
                        Link("Terms", destination: AppConfig.supportURL)
                        Link("Privacy Policy", destination: AppConfig.privacyPolicyURL)
                    }
                    .font(theme.font(style: .caption))
                    .foregroundColor(theme.accentColor)
                }
                .padding(.bottom, theme.spacing2XL + theme.spacingS)
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
        .sheet(isPresented: $showHSKFlow) {
            if #available(iOS 15.0, macOS 12.0, *) {
                HSKFlowView(mode: .createNewWallet) { address in
                    Task {
                        await wsm.loadAccount(id: address)
                        completeOnboarding()
                    }
                }
                .environmentObject(themeManager)
            }
        }
        .alert(isPresented: $showError) {
            Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
        }
    }

    @State private var showError = false
    @State private var errorMessage = ""

    func createWallet() {
        isCreating = true
        Task {
            if let mnemonic = await wsm.createWallet(name: "Main Wallet") {
                createdMnemonic = mnemonic
                showBackupSheet = true
            } else {
                // Handle error
                if case let .error(msg) = wsm.state {
                    errorMessage = msg
                } else {
                    errorMessage = "Failed to create wallet. Please try again."
                }
                showError = true
            }
            isCreating = false
        }
    }

    func importWallet(seed: String) {
        Task {
            if MnemonicService.validate(mnemonic: seed) {
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
        let theme = themeManager.currentTheme
        
        NavigationView {
            ZStack {
                Color.clear
                    .themedContainer(theme: theme, showPattern: true, applyAnimation: true)
                    .ignoresSafeArea()

                VStack(spacing: theme.spacing2XL) {
                    VStack(spacing: theme.spacingS) {
                        Text("RECOVERY SEQUENCE")
                            .font(theme.font(style: .headline))
                            .tracking(2)
                            .foregroundColor(theme.textPrimary)

                        Text("Enter your 12 or 24 word phrase")
                            .font(theme.font(style: .caption))
                            .foregroundColor(theme.textSecondary)
                    }
                    .padding(.top, theme.spacing2XL)

                    TextEditor(text: $seedText)
                        .frame(height: 160)
                        .padding()
                        .background(theme.backgroundSecondary)
                        .cornerRadius(theme.cornerRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: theme.cornerRadius)
                                .stroke(theme.borderColor, lineWidth: 1)
                        )
                        .foregroundColor(theme.textPrimary)
                        .font(theme.addressFont)
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
        let theme = themeManager.currentTheme
        
        ZStack {
            Color.clear
                .themedContainer(theme: theme, showPattern: true, applyAnimation: true)
                .ignoresSafeArea()

            VStack(spacing: theme.spacingXL) {
                Text("SECRET KEY")
                    .font(theme.font(style: .title2))
                    .foregroundColor(theme.errorColor)
                    .padding(.top, theme.spacing2XL + theme.spacingS)

                Text("Write this down immediately. Do not share it. We cannot recover it for you.")
                    .font(theme.font(style: .body))
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Text(mnemonic)
                    .font(theme.addressFont)
                    .foregroundColor(theme.textPrimary)
                    .padding()
                    .background(theme.backgroundSecondary)
                    .cornerRadius(theme.cornerRadius)
                    .padding(.horizontal)

                Spacer()

                KryptoButton(
                    title: "I HAVE SAVED IT",
                    icon: "lock.fill",
                    action: onConfirm,
                    isPrimary: true
                )
                .padding(.bottom, theme.spacing2XL + theme.spacingS)
            }
        }
    }
}
