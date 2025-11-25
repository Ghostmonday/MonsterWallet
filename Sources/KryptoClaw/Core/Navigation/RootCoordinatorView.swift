// MODULE: RootCoordinatorView
// VERSION: 1.0.0
// PURPOSE: Single source of truth for view hierarchy with NavigationStack-based routing

import SwiftUI
#if os(macOS)
import AppKit
#endif

// MARK: - Root Coordinator View

/// The root coordinator view that manages the entire navigation hierarchy.
/// 
/// This view is the single source of truth for:
/// - NavigationStack with type-safe routing
/// - Modal sheet presentations
/// - Full-screen cover presentations
/// - Tab-based navigation
/// - Deep link handling
/// - Authentication state management
@MainActor
public struct RootCoordinatorView<Content: View>: View {
    
    // MARK: - Environment & State
    
    @Bindable private var router: Router
    @Environment(\.scenePhase) private var scenePhase
    
    private let rootContent: () -> Content
    
    // MARK: - Initialization
    
    public init(
        router: Router,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.router = router
        self.rootContent = content
    }
    
    // MARK: - Body
    
    public var body: some View {
        NavigationStack(path: $router.path) {
            rootContent()
                .navigationDestination(for: Route.self) { route in
                    destinationView(for: route)
                }
        }
        .sheet(item: $router.presentedSheet) { route in
            sheetView(for: route)
        }
        #if os(iOS)
        .fullScreenCover(item: $router.presentedFullScreenCover) { route in
            fullScreenView(for: route)
        }
        #endif
        .alert(
            router.alertRoute?.title ?? "",
            isPresented: Binding(
                get: { router.alertRoute != nil },
                set: { if !$0 { router.dismissAlert() } }
            ),
            presenting: router.alertRoute
        ) { alert in
            Button(alert.primaryButton.title, role: alert.primaryButton.role) {
                alert.primaryButton.action()
            }
            if let secondary = alert.secondaryButton {
                Button(secondary.title, role: secondary.role) {
                    secondary.action()
                }
            }
        } message: { alert in
            Text(alert.message)
        }
        .onOpenURL { url in
            _ = router.handleDeepLink(url)
        }
        .environment(\.router, router)
    }
    
    // MARK: - Destination Views
    
    @ViewBuilder
    private func destinationView(for route: Route) -> some View {
        switch route {
        // Main Views
        case .home:
            HomeView()
            
        case .history:
            HistoryView()
            
        case .nftGallery:
            NFTGalleryView()
            
        case .settings:
            SettingsView()
            
        // Transaction Flow
        case .send:
            SendView()
            
        case .sendToAddress:
            // TODO: Implement SendToAddressView
            PlaceholderView(route: route)
            
        case .sendConfirmation:
            // TODO: Implement SendConfirmationView
            PlaceholderView(route: route)
            
        case .receive:
            ReceiveView()
            
        case .receiveQR:
            // TODO: Implement ReceiveQRView
            PlaceholderView(route: route)
            
        // Swap Flow
        case .swap:
            SwapView()
            
        case .swapConfirmation:
            // TODO: Implement SwapConfirmationView
            PlaceholderView(route: route)
            
        // Asset Management
        case .assetDetail:
            // TODO: Implement AssetDetailView
            PlaceholderView(route: route)
            
        case .chainDetail(let chain):
            if let chainEnum = Chain(rawValue: chain) {
                ChainDetailView(chain: chainEnum)
            } else {
                PlaceholderView(route: route)
            }
            
        case .tokenList:
            // TODO: Implement TokenListView
            PlaceholderView(route: route)
            
        // Wallet Management
        case .walletManagement:
            WalletManagementView()
            
        case .walletDetail:
            // TODO: Implement WalletDetailView
            PlaceholderView(route: route)
            
        case .createWallet:
            // TODO: Implement CreateWalletView
            PlaceholderView(route: route)
            
        case .importWallet:
            // TODO: Implement ImportWalletView
            PlaceholderView(route: route)
            
        case .backupWallet:
            // TODO: Implement BackupWalletView
            PlaceholderView(route: route)
            
        case .recoverWallet:
            RecoveryView()
            
        // Security
        case .securitySettings:
            // Security settings would be part of SettingsView
            SettingsView()
            
        case .biometricSetup:
            // TODO: Implement BiometricSetupView
            PlaceholderView(route: route)
            
        case .passcodeSetup:
            // TODO: Implement PasscodeSetupView
            PlaceholderView(route: route)
            
        case .exportPrivateKey:
            // TODO: Implement ExportPrivateKeyView (requires biometric auth)
            PlaceholderView(route: route)
            
        case .hskSetup:
            // TODO: Implement HSK setup flow
            PlaceholderView(route: route)
            
        // Onboarding
        case .onboarding, .onboardingWelcome, .onboardingCreateOrImport,
             .onboardingBackup, .onboardingVerifyBackup, .onboardingComplete:
            OnboardingView(onComplete: {
                router.popToRoot()
            })
            
        // Utility
        case .addressBook:
            AddressBookView()
            
        case .addContact:
            // TODO: Implement AddContactView
            PlaceholderView(route: route)
            
        case .editContact:
            // TODO: Implement EditContactView
            PlaceholderView(route: route)
            
        case .qrScanner:
            // TODO: Implement QRScannerView
            PlaceholderView(route: route)
            
        case .transactionDetail:
            // TODO: Implement TransactionDetailView
            PlaceholderView(route: route)
            
        case .webView:
            // TODO: Implement WebView
            PlaceholderView(route: route)
            
        // Deep Links
        case .walletConnect:
            // TODO: Implement WalletConnectView
            PlaceholderView(route: route)
            
        case .paymentRequest:
            // Navigate to send with pre-filled data
            SendView()
        }
    }
    
    // MARK: - Sheet Views
    
    @ViewBuilder
    private func sheetView(for route: Route) -> some View {
        NavigationStack {
            destinationView(for: route)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") {
                            router.dismissSheet()
                        }
                    }
                }
        }
    }
    
    // MARK: - Full Screen Views
    
    @ViewBuilder
    private func fullScreenView(for route: Route) -> some View {
        NavigationStack {
            destinationView(for: route)
        }
    }
}

// MARK: - Route Identifiable Extension

extension Route: Identifiable {
    public var id: String {
        switch self {
        case .home: return "home"
        case .history: return "history"
        case .nftGallery: return "nftGallery"
        case .settings: return "settings"
        case .send(let asset): return "send-\(asset?.symbol ?? "none")"
        case .sendToAddress(let asset, let recipient): return "sendToAddress-\(asset.symbol)-\(recipient)"
        case .sendConfirmation(let id): return "sendConfirmation-\(id)"
        case .receive(let asset): return "receive-\(asset?.symbol ?? "none")"
        case .receiveQR(let address, let chain): return "receiveQR-\(address)-\(chain)"
        case .swap: return "swap"
        case .swapConfirmation(let from, let to, let amount): return "swapConfirmation-\(from.symbol)-\(to.symbol)-\(amount)"
        case .assetDetail(let asset): return "assetDetail-\(asset.symbol)"
        case .chainDetail(let chain): return "chainDetail-\(chain)"
        case .tokenList(let chain): return "tokenList-\(chain)"
        case .walletManagement: return "walletManagement"
        case .walletDetail(let id): return "walletDetail-\(id)"
        case .createWallet: return "createWallet"
        case .importWallet: return "importWallet"
        case .backupWallet(let id): return "backupWallet-\(id)"
        case .recoverWallet: return "recoverWallet"
        case .securitySettings: return "securitySettings"
        case .biometricSetup: return "biometricSetup"
        case .passcodeSetup: return "passcodeSetup"
        case .exportPrivateKey(let id): return "exportPrivateKey-\(id)"
        case .hskSetup: return "hskSetup"
        case .onboarding: return "onboarding"
        case .onboardingWelcome: return "onboardingWelcome"
        case .onboardingCreateOrImport: return "onboardingCreateOrImport"
        case .onboardingBackup(let mnemonic): return "onboardingBackup-\(mnemonic.hashValue)"
        case .onboardingVerifyBackup(let mnemonic): return "onboardingVerifyBackup-\(mnemonic.hashValue)"
        case .onboardingComplete: return "onboardingComplete"
        case .addressBook: return "addressBook"
        case .addContact: return "addContact"
        case .editContact(let id): return "editContact-\(id)"
        case .qrScanner: return "qrScanner"
        case .transactionDetail(let hash, let chain): return "transactionDetail-\(hash)-\(chain)"
        case .webView(let url, _): return "webView-\(url.hashValue)"
        case .walletConnect(let uri): return "walletConnect-\(uri.hashValue)"
        case .paymentRequest(let address, let amount, let chain): return "paymentRequest-\(address)-\(amount ?? "")-\(chain)"
        }
    }
}

// MARK: - Placeholder View

/// Temporary placeholder view for routes not yet implemented
struct PlaceholderView: View {
    let route: Route
    @Environment(\.router) private var router
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: route.systemImage)
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text(route.title)
                .font(.title)
                .fontWeight(.bold)
            
            Text("This view is under construction")
                .font(.body)
                .foregroundStyle(.secondary)
            
            if let router = router {
                Button("Go Back") {
                    router.pop()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(placeholderBackgroundColor)
        .navigationTitle(route.title)
    }
    
    private var placeholderBackgroundColor: Color {
        #if os(iOS)
        Color(.systemGroupedBackground)
        #else
        Color(nsColor: .windowBackgroundColor)
        #endif
    }
}

// MARK: - Tab Coordinator View

/// A tab-based coordinator view for main app navigation
@MainActor
public struct TabCoordinatorView: View {
    
    @Bindable private var router: Router
    @EnvironmentObject var walletState: WalletStateManager
    @EnvironmentObject var themeManager: ThemeManager
    
    public init(router: Router) {
        self.router = router
    }
    
    public var body: some View {
        TabView(selection: $router.selectedTab) {
            ForEach(TabRoute.allCases) { tab in
                tabContent(for: tab)
                    .tabItem {
                        Label(tab.title, systemImage: tab.systemImage)
                    }
                    .tag(tab)
            }
        }
        .environment(\.router, router)
    }
    
    @ViewBuilder
    private func tabContent(for tab: TabRoute) -> some View {
        NavigationStack(path: $router.path) {
            Group {
                switch tab {
                case .home:
                    HomeView()
                case .history:
                    HistoryView()
                case .nftGallery:
                    NFTGalleryView()
                case .settings:
                    SettingsView()
                }
            }
            .navigationDestination(for: Route.self) { route in
                routeDestination(for: route)
            }
        }
    }
    
    @ViewBuilder
    private func routeDestination(for route: Route) -> some View {
        switch route {
        case .chainDetail(let chain):
            if let chainEnum = Chain(rawValue: chain) {
                ChainDetailView(chain: chainEnum)
            }
        case .addressBook:
            AddressBookView()
        case .walletManagement:
            WalletManagementView()
        case .recoverWallet:
            RecoveryView()
        default:
            PlaceholderView(route: route)
        }
    }
}

// MARK: - Navigation View Modifier

/// View modifier for easy navigation
public struct NavigationModifier: ViewModifier {
    @Environment(\.router) private var router
    let route: Route
    
    public func body(content: Content) -> some View {
        Button {
            router?.navigate(to: route)
        } label: {
            content
        }
    }
}

extension View {
    /// Make the view navigate to a route when tapped
    public func navigates(to route: Route) -> some View {
        modifier(NavigationModifier(route: route))
    }
}

// MARK: - Navigation Link Builder

/// A reusable navigation link that uses the Router
public struct RouterLink<Label: View>: View {
    @Environment(\.router) private var router
    
    let route: Route
    let label: () -> Label
    
    public init(to route: Route, @ViewBuilder label: @escaping () -> Label) {
        self.route = route
        self.label = label
    }
    
    public var body: some View {
        Button {
            router?.navigate(to: route)
        } label: {
            label()
        }
    }
}

// MARK: - Convenience Initializers

extension RouterLink where Label == Text {
    public init(_ title: String, to route: Route) {
        self.route = route
        self.label = { Text(title) }
    }
}

extension RouterLink where Label == SwiftUI.Label<Text, Image> {
    public init(_ title: String, systemImage: String, to route: Route) {
        self.route = route
        self.label = { Label(title, systemImage: systemImage) }
    }
}

