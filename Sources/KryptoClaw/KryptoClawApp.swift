import SwiftUI

@main
public struct KryptoClawApp: App {
    @StateObject var wsm: WalletStateManager
    @StateObject var themeManager = ThemeManager()
    
    public init() {
        // Initialize Core Dependencies (Dependency Injection Root)
        // In a real app, these might be singletons or constructed by a DI container.
        // For V1.0, we construct the graph here.
        
        // 1. Foundation
        let keychain = SystemKeychain()
        let keyStore = SecureEnclaveKeyStore(keychain: keychain)
        let session = URLSession.shared
        let provider = ModularHTTPProvider(session: session)
        
        // 2. Logic
        let simulator = LocalSimulator(provider: provider)
        let router = BasicGasRouter(provider: provider)
        let securityPolicy = BasicHeuristicAnalyzer()
        let nftProvider = MockNFTProvider() // Using Mock for V1.0/Previews
        
        // 3. Signer (Requires KeyStore)
        // Note: In a real app, keyId would be dynamic or managed by an AccountManager.
        // For V1.0 Single Account, we use a fixed ID.
        let signer = SimpleP2PSigner(keyStore: keyStore, keyId: "primary_account")
        
        // 4. State Manager (The Brain)
        let stateManager = WalletStateManager(
            keyStore: keyStore,
            blockchainProvider: provider,
            simulator: simulator,
            router: router,
            securityPolicy: securityPolicy,
            signer: signer,
            nftProvider: nftProvider
        )
        
        _wsm = StateObject(wrappedValue: stateManager)
    }
    
    @AppStorage("hasOnboarded") var hasOnboarded: Bool = false
    
    public var body: some Scene {
        WindowGroup {
            if hasOnboarded {
                HomeView()
                    .environmentObject(wsm)
                    .environmentObject(themeManager)
            } else {
                OnboardingView(onComplete: {
                    hasOnboarded = true
                })
                .environmentObject(wsm)
                .environmentObject(themeManager)
            }
        }
    }
}
