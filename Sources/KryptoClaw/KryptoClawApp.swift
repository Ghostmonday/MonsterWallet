import SwiftUI

@main
public struct KryptoClawApp: App {
    @StateObject var wsm: WalletStateManager
    @StateObject var themeManager = ThemeManager()

    public init() {
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
