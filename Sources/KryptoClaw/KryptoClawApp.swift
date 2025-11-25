// MODULE: KryptoClawApp
// VERSION: 2.0.0
// PURPOSE: Main application entry point with MVVM-C architecture integration

import SwiftUI
import KryptoClaw
#if os(iOS)
import UIKit
#endif

// MARK: - App Entry Point

@main
public struct KryptoClawApp: App {
    
    // MARK: - Core Dependencies
    
    @StateObject private var walletStateManager: WalletStateManager
    @StateObject private var themeManager = ThemeManager()
    
    // MARK: - Navigation
    
    @State private var router = Router()
    
    // MARK: - App State
    
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("hasOnboarded") private var hasOnboarded: Bool = false
    @State private var showingSplash: Bool = true
    @State private var isAppReady: Bool = false
    
    // MARK: - Biometric Auth Manager
    
    private let biometricManager: BiometricAuthManager?
    
    // MARK: - Initialization
    
    public init() {
        // 0. Security: Jailbreak Detection (Phase 1 Compliance)
        if JailbreakDetector.isJailbroken() {
            // In production, show a blocking security screen instead of crashing
            // This is more App Store-friendly
            fatalError("CRITICAL SECURITY VIOLATION: Device is compromised. The Vault cannot operate safely.")
        }
        
        // 1. Initialize Foundation Layer
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
        
        // 2. Initialize Wallet State Manager
        let stateManager = WalletStateManager(
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
        
        _walletStateManager = StateObject(wrappedValue: stateManager)
        
        // 3. Initialize Biometric Auth Manager (iOS 15+)
        if #available(iOS 15.0, macOS 12.0, *) {
            biometricManager = BiometricAuthManager()
        } else {
            biometricManager = nil
        }
        
        // 4. Pre-warm Haptic Engine
        HapticEngine.shared.warmEngine()
    }
    
    // MARK: - Body
    
    public var body: some Scene {
        WindowGroup {
            ZStack {
                if showingSplash {
                    SplashScreenView()
                        .environmentObject(themeManager)
                        .transition(.opacity.combined(with: .scale(scale: 1.1)))
                } else if !hasOnboarded {
                    OnboardingContainerView(onComplete: handleOnboardingComplete)
                        .environmentObject(walletStateManager)
                        .environmentObject(themeManager)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .leading)
                        ))
                } else {
                    MainAppView()
                        .environmentObject(walletStateManager)
                        .environmentObject(themeManager)
                        .environment(router)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.5), value: showingSplash)
            .animation(.easeInOut(duration: 0.4), value: hasOnboarded)
            .deviceSecured(showLockIcon: true)
            .onAppear(perform: handleAppear)
            .onChange(of: scenePhase, handleScenePhaseChange)
            .onOpenURL(perform: handleDeepLink)
        }
    }
    
    // MARK: - Lifecycle Handlers
    
    private func handleAppear() {
        // Delay splash screen dismissal
        if hasOnboarded {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeOut(duration: 0.6)) {
                    showingSplash = false
                }
            }
        } else {
            // Skip splash for onboarding
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    showingSplash = false
                }
            }
        }
    }
    
    private func handleScenePhaseChange(_ oldPhase: ScenePhase, _ newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            // Resume haptic engine
            HapticEngine.shared.warmEngine()
            
            // Check for biometry changes if authenticated
            if hasOnboarded {
                Task {
                    await checkBiometryStatus()
                }
            }
            
        case .inactive:
            // Prepare for backgrounding
            break
            
        case .background:
            // Stop haptic engine to conserve resources
            HapticEngine.shared.stopEngine()
            
        @unknown default:
            break
        }
    }
    
    private func handleOnboardingComplete() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            hasOnboarded = true
        }
        HapticEngine.shared.play(.success)
    }
    
    private func handleDeepLink(_ url: URL) {
        _ = router.handleDeepLink(url)
    }
    
    @available(iOS 15.0, macOS 12.0, *)
    private func checkBiometryStatus() async {
        guard let manager = biometricManager else { return }
        
        do {
            let (available, type) = try await manager.checkAvailability()
            if !available {
                // Handle biometry not available
                print("[App] Biometry not available: \(type)")
            }
        } catch {
            // Handle biometry check failure
            print("[App] Biometry check failed: \(error)")
        }
    }
}

// MARK: - Main App View

/// The main authenticated app view with navigation
struct MainAppView: View {
    
    @EnvironmentObject var walletState: WalletStateManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(Router.self) private var router
    
    var body: some View {
        RootCoordinatorView(router: router) {
            HomeView()
        }
        .environmentObject(walletState)
        .environmentObject(themeManager)
    }
}

// MARK: - Onboarding Container

/// Container view for the onboarding flow
struct OnboardingContainerView: View {
    
    let onComplete: () -> Void
    
    @EnvironmentObject var walletState: WalletStateManager
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        OnboardingView(onComplete: onComplete)
    }
}

// MARK: - Splash Screen View

/// Animated splash screen with branding
public struct SplashScreenView: View {
    
    @EnvironmentObject var themeManager: ThemeManager
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var ringRotation: Double = 0
    
    public init() {}
    
    public var body: some View {
        let theme = themeManager.currentTheme
        
        ZStack {
            // Background
            theme.backgroundMain
                .ignoresSafeArea()
            
            // Animated background pattern
            if theme.showDiamondPattern {
                DiamondPatternView()
                    .opacity(0.1)
            }
            
            VStack(spacing: 24) {
                // Animated Logo
                ZStack {
                    // Outer rotating ring
                    Circle()
                        .stroke(
                            AngularGradient(
                                colors: [theme.accentColor, theme.accentColor.opacity(0.3), theme.accentColor],
                                center: .center
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(ringRotation))
                    
                    // Inner icon
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 50, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [theme.accentColor, theme.textPrimary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(logoScale)
                }
                .opacity(logoOpacity)
                
                // App Name
                VStack(spacing: 8) {
                    Text("KryptoClaw")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(theme.textPrimary)
                    
                    Text("Secure Crypto Vault")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(theme.textSecondary)
                        .tracking(2)
                        .textCase(.uppercase)
                }
                .opacity(textOpacity)
            }
        }
        .onAppear {
            // Animate logo
            withAnimation(.easeOut(duration: 0.8)) {
                logoOpacity = 1
                logoScale = 1
            }
            
            // Animate text with delay
            withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                textOpacity = 1
            }
            
            // Continuous ring rotation
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                ringRotation = 360
            }
        }
    }
}

// MARK: - Diamond Pattern View

/// Subtle diamond pattern for background decoration
struct DiamondPatternView: View {
    
    let spacing: CGFloat = 30
    
    var body: some View {
        GeometryReader { geometry in
            let columns = Int(geometry.size.width / spacing) + 1
            let rows = Int(geometry.size.height / spacing) + 1
            
            Canvas { context, size in
                for row in 0..<rows {
                    for col in 0..<columns {
                        let x = CGFloat(col) * spacing
                        let y = CGFloat(row) * spacing + (col.isMultiple(of: 2) ? spacing / 2 : 0)
                        
                        let diamond = Path { path in
                            path.move(to: CGPoint(x: x, y: y - 4))
                            path.addLine(to: CGPoint(x: x + 4, y: y))
                            path.addLine(to: CGPoint(x: x, y: y + 4))
                            path.addLine(to: CGPoint(x: x - 4, y: y))
                            path.closeSubpath()
                        }
                        
                        context.stroke(diamond, with: .color(.white.opacity(0.3)), lineWidth: 0.5)
                    }
                }
            }
        }
    }
}

// MARK: - App Delegate Adapter (iOS)

#if os(iOS)
/// App delegate for handling system events
class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Configure appearance
        configureAppearance()
        return true
    }
    
    func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
    ) -> Bool {
        // Handle universal links
        return true
    }
    
    private func configureAppearance() {
        // Configure navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        // Configure tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithDefaultBackground()
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
    }
}
#endif
