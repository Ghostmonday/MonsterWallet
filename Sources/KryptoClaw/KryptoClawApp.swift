// KRYPTOCLAW APP
// Entry point. Clean. Simple.
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

import SwiftUI

@main
public struct KryptoClawApp: App {
    
    @StateObject private var walletState: WalletStateManager
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @State private var showingSplash = true
    
    public init() {
        // Security check
        if JailbreakDetector.isJailbroken() {
            fatalError("Device compromised.")
        }
        
        // Initialize backend (WORLD 1 - untouched)
        let keychain = SystemKeychain()
        let keyStore = SecureEnclaveKeyStore(keychain: keychain)
        let session = URLSession.shared
        let provider = MultiChainProvider(session: session)
        let simulator = LocalSimulator(provider: provider, session: session)
        let gasRouter = BasicGasRouter(provider: provider)
        let securityPolicy = BasicHeuristicAnalyzer()
        let nftProvider = HTTPNFTProvider(session: session, apiKey: AppConfig.openseaAPIKey)
        let poisoningDetector = AddressPoisoningDetector()
        let clipboardGuard = ClipboardGuard()
        let signer = SimpleP2PSigner(keyStore: keyStore, keyId: "primary_account")
        
        let state = WalletStateManager(
            keyStore: keyStore,
            blockchainProvider: provider,
            simulator: simulator,
            router: gasRouter,
            securityPolicy: securityPolicy,
            signer: signer,
            nftProvider: nftProvider,
            poisoningDetector: poisoningDetector,
            clipboardGuard: clipboardGuard
        )
        
        _walletState = StateObject(wrappedValue: state)
        HapticEngine.shared.warmEngine()
    }
    
    public var body: some Scene {
        WindowGroup {
            ZStack {
                // Background - The void
                KC.Color.bg.ignoresSafeArea()
                
                // Splash
                if showingSplash {
                    SplashScreen()
                        .transition(.opacity)
                }
                // Onboarding
                else if !hasOnboarded {
                    OnboardingScreen {
                        withAnimation(KC.Anim.smooth) { hasOnboarded = true }
                        HapticEngine.shared.play(.success)
                    }
                    .environmentObject(walletState)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .opacity
                    ))
                }
                // Main app
                else {
                    HomeScreen()
                        .environmentObject(walletState)
                        .transition(.opacity)
                }
            }
            .animation(KC.Anim.smooth, value: showingSplash)
            .animation(KC.Anim.smooth, value: hasOnboarded)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(KC.Anim.smooth) { showingSplash = false }
                }
            }
            .task {
                // AUTO-IMPORT test wallet in test environment (first launch)
                if AppConfig.isTestEnvironment && !hasOnboarded {
                    NSLog("🔴 AUTO-IMPORTING TEST WALLET")
                    await walletState.importWallet(mnemonic: AppConfig.TestWallet.mnemonic)
                    hasOnboarded = true
                    NSLog("🔴 AUTO-IMPORT COMPLETE")
                }
                // Load existing wallet on subsequent launches
                else if hasOnboarded {
                    NSLog("🔴 LOADING EXISTING WALLET")
                    // In test mode, always use test wallet address
                    if AppConfig.isTestEnvironment {
                        await walletState.loadAccount(id: AppConfig.TestWallet.address)
                    } else if let firstWallet = walletState.wallets.first {
                        await walletState.loadAccount(id: firstWallet.id)
                    }
                    NSLog("🔴 WALLET LOADED")
                }
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .background {
                    HapticEngine.shared.stopEngine()
                } else if phase == .active {
                    HapticEngine.shared.warmEngine()
                }
            }
        }
    }
}
