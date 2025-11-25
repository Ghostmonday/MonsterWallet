// MODULE: Router
// VERSION: 1.0.0
// PURPOSE: Type-safe navigation system with NavigationPath-based routing

import SwiftUI
import Combine

// MARK: - Asset Model (for navigation context)

/// Lightweight asset reference for navigation
public struct AssetReference: Hashable, Codable, Sendable {
    public let symbol: String
    public let chain: String
    public let contractAddress: String?
    
    public init(symbol: String, chain: String, contractAddress: String? = nil) {
        self.symbol = symbol
        self.chain = chain
        self.contractAddress = contractAddress
    }
    
    /// Create from Chain enum
    public init(chain: Chain) {
        self.symbol = chain.nativeCurrency
        self.chain = chain.rawValue
        self.contractAddress = nil
    }
}

// MARK: - Route Enum

/// Type-safe route definitions for the entire application navigation
public enum Route: Hashable, Codable {
    // MARK: - Main Tabs
    case home
    case history
    case nftGallery
    case settings
    
    // MARK: - Transaction Flow
    case send(asset: AssetReference?)
    case sendToAddress(asset: AssetReference, recipient: String)
    case sendConfirmation(transactionId: String)
    case receive(asset: AssetReference?)
    case receiveQR(address: String, chain: String)
    
    // MARK: - Swap Flow
    case swap
    case swapConfirmation(fromAsset: AssetReference, toAsset: AssetReference, amount: String)
    
    // MARK: - Asset Management
    case assetDetail(asset: AssetReference)
    case chainDetail(chain: String)
    case tokenList(chain: String)
    
    // MARK: - Wallet Management
    case walletManagement
    case walletDetail(walletId: String)
    case createWallet
    case importWallet
    case backupWallet(walletId: String)
    case recoverWallet
    
    // MARK: - Security
    case securitySettings
    case biometricSetup
    case passcodeSetup
    case exportPrivateKey(walletId: String)
    case hskSetup
    
    // MARK: - Onboarding
    case onboarding
    case onboardingWelcome
    case onboardingCreateOrImport
    case onboardingBackup(mnemonic: String)
    case onboardingVerifyBackup(mnemonic: String)
    case onboardingComplete
    
    // MARK: - Utility
    case addressBook
    case addContact
    case editContact(contactId: String)
    case qrScanner
    case transactionDetail(txHash: String, chain: String)
    case webView(url: String, title: String)
    
    // MARK: - Deep Links
    case walletConnect(uri: String)
    case paymentRequest(address: String, amount: String?, chain: String)
}

// MARK: - Route Metadata

extension Route {
    /// Human-readable title for the route
    public var title: String {
        switch self {
        case .home: return "Home"
        case .history: return "History"
        case .nftGallery: return "NFT Gallery"
        case .settings: return "Settings"
        case .send: return "Send"
        case .sendToAddress: return "Confirm Recipient"
        case .sendConfirmation: return "Confirm Transaction"
        case .receive: return "Receive"
        case .receiveQR: return "Your Address"
        case .swap: return "Swap"
        case .swapConfirmation: return "Confirm Swap"
        case .assetDetail: return "Asset Details"
        case .chainDetail: return "Network Details"
        case .tokenList: return "Tokens"
        case .walletManagement: return "Wallets"
        case .walletDetail: return "Wallet Details"
        case .createWallet: return "Create Wallet"
        case .importWallet: return "Import Wallet"
        case .backupWallet: return "Backup Wallet"
        case .recoverWallet: return "Recover Wallet"
        case .securitySettings: return "Security"
        case .biometricSetup: return "Biometric Setup"
        case .passcodeSetup: return "Passcode Setup"
        case .exportPrivateKey: return "Export Key"
        case .hskSetup: return "Hardware Key Setup"
        case .onboarding, .onboardingWelcome: return "Welcome"
        case .onboardingCreateOrImport: return "Get Started"
        case .onboardingBackup: return "Backup Phrase"
        case .onboardingVerifyBackup: return "Verify Backup"
        case .onboardingComplete: return "Ready!"
        case .addressBook: return "Address Book"
        case .addContact: return "Add Contact"
        case .editContact: return "Edit Contact"
        case .qrScanner: return "Scan QR"
        case .transactionDetail: return "Transaction"
        case .webView(_, let title): return title
        case .walletConnect: return "WalletConnect"
        case .paymentRequest: return "Payment Request"
        }
    }
    
    /// System image name for the route
    public var systemImage: String {
        switch self {
        case .home: return "house.fill"
        case .history: return "clock.arrow.circlepath"
        case .nftGallery: return "photo.stack.fill"
        case .settings: return "gearshape.fill"
        case .send, .sendToAddress, .sendConfirmation: return "arrow.up.circle.fill"
        case .receive, .receiveQR: return "arrow.down.circle.fill"
        case .swap, .swapConfirmation: return "arrow.triangle.swap"
        case .assetDetail, .chainDetail, .tokenList: return "chart.line.uptrend.xyaxis"
        case .walletManagement, .walletDetail: return "wallet.pass.fill"
        case .createWallet: return "plus.circle.fill"
        case .importWallet: return "square.and.arrow.down.fill"
        case .backupWallet: return "key.fill"
        case .recoverWallet: return "arrow.counterclockwise.circle.fill"
        case .securitySettings: return "lock.shield.fill"
        case .biometricSetup: return "faceid"
        case .passcodeSetup: return "lock.fill"
        case .exportPrivateKey: return "key.horizontal.fill"
        case .hskSetup: return "cpu.fill"
        case .onboarding, .onboardingWelcome, .onboardingCreateOrImport,
             .onboardingBackup, .onboardingVerifyBackup, .onboardingComplete:
            return "sparkles"
        case .addressBook, .addContact, .editContact: return "person.crop.circle.fill"
        case .qrScanner: return "qrcode.viewfinder"
        case .transactionDetail: return "doc.text.fill"
        case .webView: return "globe"
        case .walletConnect: return "link.circle.fill"
        case .paymentRequest: return "banknote.fill"
        }
    }
    
    /// Whether the route requires authentication
    public var requiresAuth: Bool {
        switch self {
        case .exportPrivateKey, .backupWallet, .sendConfirmation, .swapConfirmation:
            return true
        default:
            return false
        }
    }
    
    /// Whether the route should be presented modally
    public var isModal: Bool {
        switch self {
        case .send, .receive, .swap, .qrScanner, .createWallet, .importWallet,
             .biometricSetup, .passcodeSetup, .addContact, .editContact,
             .onboarding, .onboardingWelcome, .onboardingCreateOrImport,
             .onboardingBackup, .onboardingVerifyBackup, .onboardingComplete,
             .walletConnect, .paymentRequest:
            return true
        default:
            return false
        }
    }
}

// MARK: - Router

/// Observable router managing the navigation state with type-safe NavigationPath
@MainActor
@Observable
public final class Router {
    
    // MARK: - Navigation State
    
    /// The navigation path for push-based navigation
    public var path = NavigationPath()
    
    /// Currently presented sheet route
    public var presentedSheet: Route?
    
    /// Currently presented full-screen cover route
    public var presentedFullScreenCover: Route?
    
    /// Alert to present
    public var alertRoute: AlertRoute?
    
    /// Deep link waiting to be processed
    public private(set) var pendingDeepLink: URL?
    
    /// Tab selection for tab-based navigation
    public var selectedTab: TabRoute = .home
    
    // MARK: - History
    
    /// Navigation history for analytics
    private(set) var navigationHistory: [Route] = []
    private let maxHistoryCount = 50
    
    // MARK: - Callbacks
    
    /// Callback when navigation changes
    public var onNavigationChange: ((Route) -> Void)?
    
    // MARK: - Initialization
    
    public init() {}
    
    // MARK: - Navigation Methods
    
    /// Navigate to a route via push navigation
    public func navigate(to route: Route) {
        // Check if route should be modal
        if route.isModal {
            present(route)
            return
        }
        
        path.append(route)
        recordNavigation(route)
        
        // Play haptic feedback
        HapticEngine.shared.play(.selection)
    }
    
    /// Present a route as a sheet
    public func present(_ route: Route) {
        presentedSheet = route
        recordNavigation(route)
        
        HapticEngine.shared.play(.sheetPresent)
    }
    
    /// Present a route as a full-screen cover
    public func presentFullScreen(_ route: Route) {
        presentedFullScreenCover = route
        recordNavigation(route)
        
        HapticEngine.shared.play(.sheetPresent)
    }
    
    /// Dismiss the currently presented sheet
    public func dismissSheet() {
        presentedSheet = nil
        HapticEngine.shared.play(.sheetDismiss)
    }
    
    /// Dismiss the currently presented full-screen cover
    public func dismissFullScreenCover() {
        presentedFullScreenCover = nil
        HapticEngine.shared.play(.sheetDismiss)
    }
    
    /// Pop the last route from the navigation stack
    public func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
        HapticEngine.shared.play(.selection)
    }
    
    /// Pop to the root of the navigation stack
    public func popToRoot() {
        path = NavigationPath()
        HapticEngine.shared.play(.selection)
    }
    
    /// Pop a specific number of routes
    public func pop(count: Int) {
        let removeCount = min(count, path.count)
        path.removeLast(removeCount)
        HapticEngine.shared.play(.selection)
    }
    
    /// Replace the entire navigation stack with a single route
    public func replace(with route: Route) {
        path = NavigationPath()
        path.append(route)
        recordNavigation(route)
    }
    
    /// Switch to a specific tab
    public func switchTab(to tab: TabRoute) {
        selectedTab = tab
        HapticEngine.shared.play(.tabSwitch)
    }
    
    // MARK: - Alert Handling
    
    /// Show an alert
    public func showAlert(_ alert: AlertRoute) {
        alertRoute = alert
    }
    
    /// Dismiss the current alert
    public func dismissAlert() {
        alertRoute = nil
    }
    
    // MARK: - Deep Link Handling
    
    /// Handle an incoming deep link URL
    public func handleDeepLink(_ url: URL) -> Bool {
        guard let route = parseDeepLink(url) else {
            pendingDeepLink = url
            return false
        }
        
        navigate(to: route)
        return true
    }
    
    /// Clear any pending deep link
    public func clearPendingDeepLink() {
        pendingDeepLink = nil
    }
    
    /// Parse a deep link URL into a Route
    private func parseDeepLink(_ url: URL) -> Route? {
        // Handle kryptoclaw:// scheme
        guard url.scheme == "kryptoclaw" || url.scheme == "ethereum" else { return nil }
        
        let host = url.host?.lowercased() ?? ""
        let pathComponents = url.pathComponents.filter { $0 != "/" }
        let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        
        switch host {
        case "send":
            if let address = queryItems.first(where: { $0.name == "address" })?.value {
                let amount = queryItems.first(where: { $0.name == "amount" })?.value
                let chain = queryItems.first(where: { $0.name == "chain" })?.value ?? "ethereum"
                return .paymentRequest(address: address, amount: amount, chain: chain)
            }
            return .send(asset: nil)
            
        case "receive":
            return .receive(asset: nil)
            
        case "wc":
            if let uri = queryItems.first(where: { $0.name == "uri" })?.value {
                return .walletConnect(uri: uri)
            }
            return nil
            
        case "tx":
            if let hash = pathComponents.first {
                let chain = queryItems.first(where: { $0.name == "chain" })?.value ?? "ethereum"
                return .transactionDetail(txHash: hash, chain: chain)
            }
            return nil
            
        default:
            // Handle ethereum: protocol for EIP-681
            if url.scheme == "ethereum" {
                return parseEIP681(url)
            }
            return nil
        }
    }
    
    /// Parse EIP-681 payment request URLs
    private func parseEIP681(_ url: URL) -> Route? {
        // ethereum:0x...?value=1000000000000000000
        let path = url.path
        guard path.hasPrefix("0x"), path.count >= 42 else { return nil }
        
        let address = String(path.prefix(42))
        let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        let amount = queryItems.first(where: { $0.name == "value" })?.value
        
        return .paymentRequest(address: address, amount: amount, chain: "ethereum")
    }
    
    // MARK: - History
    
    private func recordNavigation(_ route: Route) {
        navigationHistory.append(route)
        if navigationHistory.count > maxHistoryCount {
            navigationHistory.removeFirst()
        }
        onNavigationChange?(route)
    }
    
    /// Get the last visited route
    public var lastRoute: Route? {
        navigationHistory.last
    }
    
    /// Check if a route exists in recent history
    public func hasVisited(_ route: Route, within count: Int = 10) -> Bool {
        navigationHistory.suffix(count).contains(route)
    }
}

// MARK: - Tab Route

/// Tab-based navigation routes
public enum TabRoute: String, CaseIterable, Identifiable {
    case home
    case history
    case nftGallery
    case settings
    
    public var id: String { rawValue }
    
    public var title: String {
        switch self {
        case .home: return "Home"
        case .history: return "History"
        case .nftGallery: return "NFTs"
        case .settings: return "Settings"
        }
    }
    
    public var systemImage: String {
        switch self {
        case .home: return "house.fill"
        case .history: return "clock.arrow.circlepath"
        case .nftGallery: return "photo.stack.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

// MARK: - Alert Route

/// Type-safe alert definitions
public struct AlertRoute: Identifiable {
    public let id = UUID()
    public let title: String
    public let message: String
    public let primaryButton: AlertButton
    public let secondaryButton: AlertButton?
    
    public init(
        title: String,
        message: String,
        primaryButton: AlertButton,
        secondaryButton: AlertButton? = nil
    ) {
        self.title = title
        self.message = message
        self.primaryButton = primaryButton
        self.secondaryButton = secondaryButton
    }
    
    public struct AlertButton {
        public let title: String
        public let role: ButtonRole?
        public let action: () -> Void
        
        public init(title: String, role: ButtonRole? = nil, action: @escaping () -> Void = {}) {
            self.title = title
            self.role = role
            self.action = action
        }
        
        public static func ok(action: @escaping () -> Void = {}) -> AlertButton {
            AlertButton(title: "OK", action: action)
        }
        
        public static func cancel(action: @escaping () -> Void = {}) -> AlertButton {
            AlertButton(title: "Cancel", role: .cancel, action: action)
        }
        
        public static func destructive(_ title: String, action: @escaping () -> Void) -> AlertButton {
            AlertButton(title: title, role: .destructive, action: action)
        }
    }
    
    // Common alerts
    public static func error(message: String, onDismiss: @escaping () -> Void = {}) -> AlertRoute {
        AlertRoute(
            title: "Error",
            message: message,
            primaryButton: .ok(action: onDismiss)
        )
    }
    
    public static func confirm(
        title: String,
        message: String,
        confirmTitle: String = "Confirm",
        onConfirm: @escaping () -> Void,
        onCancel: @escaping () -> Void = {}
    ) -> AlertRoute {
        AlertRoute(
            title: title,
            message: message,
            primaryButton: AlertButton(title: confirmTitle, action: onConfirm),
            secondaryButton: .cancel(action: onCancel)
        )
    }
    
    public static func destructive(
        title: String,
        message: String,
        destructiveTitle: String,
        onConfirm: @escaping () -> Void,
        onCancel: @escaping () -> Void = {}
    ) -> AlertRoute {
        AlertRoute(
            title: title,
            message: message,
            primaryButton: .destructive(destructiveTitle, action: onConfirm),
            secondaryButton: .cancel(action: onCancel)
        )
    }
}

// MARK: - Environment Key

private struct RouterKey: EnvironmentKey {
    static let defaultValue: Router? = nil
}

extension EnvironmentValues {
    public var router: Router? {
        get { self[RouterKey.self] }
        set { self[RouterKey.self] = newValue }
    }
}

extension View {
    /// Inject the router into the environment
    public func withRouter(_ router: Router) -> some View {
        self.environment(\.router, router)
    }
}

