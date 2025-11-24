import SwiftUI

@main
public struct KryptoClawApp: App {
    @StateObject var wsm: WalletStateManager
    @StateObject var themeManager = ThemeManager()
    
    @Environment(\.scenePhase) private var scenePhase
    @State private var isPrivacyActive: Bool = false

    public init() {
        // 0. Compliance Check (Jailbreak Detection)
        // Ref: Master Execution Blueprint - Phase 1
        if JailbreakDetector.isJailbroken() {
            // In a real production app, we would crash or show a "Not Supported" screen.
            // For now, we log the violation. Strict enforcement can use `fatalError()`.
            fatalError("CRITICAL SECURITY VIOLATION: Device is Jailbroken. The Vault cannot operate safely.")
        }

        // Initialize Core Dependencies (Dependency Injection Root)
        
        // 1. Foundation
        let keychain = SystemKeychain()
        let keyStore = SecureEnclaveKeyStore(keychain: keychain)
        let session = URLSession.shared
        let provider = MultiChainProvider(session: session)
        let simulator = LocalSimulator(provider: provider, session: session)
        let router = BasicGasRouter(provider: provider)
        let securityPolicy = BasicHeuristicAnalyzer()
        let nftProvider = HTTPNFTProvider(session: session, apiKey: AppConfig.openseaAPIKey)
        let poisoningDetector = AddressPoisoningDetector()
        let clipboardGuard = ClipboardGuard()
        let signer = SimpleP2PSigner(keyStore: keyStore, keyId: "primary_account")

        let stateManager = WalletStateManager(
            keyStore: keyStore,
            blockchainProvider: provider,
            simulator: simulator,
            router: router,
            securityPolicy: securityPolicy,
            signer: signer,
            nftProvider: nftProvider,
            poisoningDetector: poisoningDetector,
            clipboardGuard: clipboardGuard
        )

        _wsm = StateObject(wrappedValue: stateManager)
    }

    @AppStorage("hasOnboarded") var hasOnboarded: Bool = false
    @State private var showingSplash: Bool = true

    public var body: some Scene {
        WindowGroup {
            ZStack {
                if hasOnboarded, !showingSplash {
                    HomeView()
                        .environmentObject(wsm)
                        .environmentObject(themeManager)
                        .transition(.opacity)
                } else if !hasOnboarded {
                    OnboardingView(onComplete: {
                        hasOnboarded = true
                        Task {
                            await wsm.createWallet(name: "Main Wallet")
                        }
                    })
                    .environmentObject(wsm)
                    .environmentObject(themeManager)
                    .transition(.opacity)
                } else {
                    SplashScreenView()
                        .environmentObject(themeManager)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.5), value: showingSplash)
            // Privacy Screen Overlay (App Switcher Protection)
            .overlay(
                ZStack {
                    if isPrivacyActive {
                        // Visual Blur
                        VisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
                            .ignoresSafeArea()

                        // Icon Lock
                        VStack(spacing: 20) {
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.white)
                            Text("Vault Secured")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                    }
                }
            )
            .onChange(of: scenePhase) { newPhase in
                switch newPhase {
                case .inactive, .background:
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isPrivacyActive = true
                    }
                case .active:
                    withAnimation(.easeOut(duration: 0.3)) {
                        isPrivacyActive = false
                    }
                @unknown default:
                    break
                }
            }
            .onAppear {
                if hasOnboarded {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation {
                            showingSplash = false
                        }
                    }
                }
            }
        }
    }
}

// Helper for Blur Effect (UIViewRepresentable)
struct VisualEffectView: UIViewRepresentable {
    var effect: UIVisualEffect?
    func makeUIView(context: UIViewRepresentableContext<Self>) -> UIVisualEffectView { UIVisualEffectView() }
    func updateUIView(_ uiView: UIVisualEffectView, context: UIViewRepresentableContext<Self>) { uiView.effect = effect }
}
