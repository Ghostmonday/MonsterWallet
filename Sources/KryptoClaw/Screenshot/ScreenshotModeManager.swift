// MODULE: ScreenshotModeManager
// VERSION: 1.0.0
// PURPOSE: Configuration and state management for Screenshot Mode

import SwiftUI
import Combine

// MARK: - Screenshot Mode Configuration

/// Global configuration for Screenshot Mode
/// This enables fake data injection for App Store screenshots
public final class ScreenshotModeManager: ObservableObject {
    
    // MARK: - Singleton
    
    public static let shared = ScreenshotModeManager()
    
    // MARK: - Published State
    
    /// Whether screenshot mode is currently active
    @Published public private(set) var isEnabled: Bool = false
    
    /// Current screenshot being captured (1-12)
    @Published public var currentScreenshot: ScreenshotType = .homeDashboard
    
    /// Whether to show status bar in screenshots
    @Published public var showStatusBar: Bool = true
    
    /// Whether animations are enabled (disable for static screenshots)
    @Published public var animationsEnabled: Bool = false
    
    // MARK: - Screenshot Types
    
    public enum ScreenshotType: Int, CaseIterable, Identifiable {
        case homeDashboard = 1
        case multiChainOverview = 2
        case transactionHistory = 3
        case nftGallery = 4
        case earnOpportunities = 5
        case activePositions = 6
        case swapPreview = 7
        case transactionSimulation = 8
        case slideToConfirm = 9
        case hardwareSecurity = 10
        case settings = 11
        case onboarding = 12
        
        public var id: Int { rawValue }
        
        public var title: String {
            switch self {
            case .homeDashboard: return "Home Dashboard"
            case .multiChainOverview: return "Multi-Chain Overview"
            case .transactionHistory: return "Transaction History"
            case .nftGallery: return "NFT Gallery"
            case .earnOpportunities: return "Earn Opportunities"
            case .activePositions: return "Active Positions"
            case .swapPreview: return "Swap Preview"
            case .transactionSimulation: return "Transaction Simulation"
            case .slideToConfirm: return "Slide to Confirm"
            case .hardwareSecurity: return "Hardware Security"
            case .settings: return "Settings"
            case .onboarding: return "Onboarding"
            }
        }
        
        public var description: String {
            switch self {
            case .homeDashboard: return "Total balance, token list, clean dark theme"
            case .multiChainOverview: return "ETH/BTC/SOL balances with network badges"
            case .transactionHistory: return "Color-coded statuses, professional feed"
            case .nftGallery: return "Grid layout, luxury presentation"
            case .earnOpportunities: return "APY cards, stake now CTA"
            case .activePositions: return "Rewards accumulating, position details"
            case .swapPreview: return "Simulation results, gas estimator, MEV badge"
            case .transactionSimulation: return "Pre-flight verification, success screen"
            case .slideToConfirm: return "Themed slider, success animation"
            case .hardwareSecurity: return "HSK pairing, Secure Enclave badge"
            case .settings: return "Security center, appearance, networks"
            case .onboarding: return "Premium intro, security-first branding"
            }
        }
    }
    
    // MARK: - Initialization
    
    private init() {
        // Auto-enable when compiled with SCREENSHOT_MODE flag
        #if SCREENSHOT_MODE
        isEnabled = true
        animationsEnabled = false
        KryptoLogger.shared.log(level: .info, category: .lifecycle, message: "Screenshot Mode auto-enabled via compiler flag")
        #elseif DEBUG
        // Check for screenshot mode launch argument or environment variable
        checkForScreenshotMode()
        #endif
    }
    
    // MARK: - Public Methods
    
    /// Enable screenshot mode programmatically
    public func enable() {
        isEnabled = true
        animationsEnabled = false
        KryptoLogger.shared.log(level: .info, category: .lifecycle, message: "Screenshot Mode enabled")
    }
    
    /// Disable screenshot mode
    public func disable() {
        isEnabled = false
        animationsEnabled = true
        KryptoLogger.shared.log(level: .info, category: .lifecycle, message: "Screenshot Mode disabled")
    }
    
    /// Set the current screenshot for capture
    public func setScreenshot(_ type: ScreenshotType) {
        currentScreenshot = type
        KryptoLogger.shared.log(level: .info, category: .lifecycle, message: "Screenshot set to: \(type.title)")
    }
    
    /// Navigate to next screenshot
    public func nextScreenshot() {
        let allCases = ScreenshotType.allCases
        if let currentIndex = allCases.firstIndex(of: currentScreenshot),
           currentIndex < allCases.count - 1 {
            currentScreenshot = allCases[currentIndex + 1]
        }
    }
    
    /// Navigate to previous screenshot
    public func previousScreenshot() {
        let allCases = ScreenshotType.allCases
        if let currentIndex = allCases.firstIndex(of: currentScreenshot),
           currentIndex > 0 {
            currentScreenshot = allCases[currentIndex - 1]
        }
    }
    
    // MARK: - Private Methods
    
    private func checkForScreenshotMode() {
        // Check launch arguments
        if ProcessInfo.processInfo.arguments.contains("-SCREENSHOT_MODE") {
            enable()
        }
        
        // Check environment variable
        if ProcessInfo.processInfo.environment["SCREENSHOT_MODE"] == "1" {
            enable()
        }
        
        // Check for specific screenshot number
        if let screenshotArg = ProcessInfo.processInfo.environment["SCREENSHOT_NUMBER"],
           let number = Int(screenshotArg),
           let type = ScreenshotType(rawValue: number) {
            currentScreenshot = type
        }
    }
}

// MARK: - Environment Key

private struct ScreenshotModeKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    public var isScreenshotMode: Bool {
        get { self[ScreenshotModeKey.self] }
        set { self[ScreenshotModeKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {
    /// Apply screenshot mode environment
    public func screenshotMode(_ enabled: Bool = true) -> some View {
        self.environment(\.isScreenshotMode, enabled)
    }
    
    /// Conditionally modify view for screenshot mode
    public func screenshotModifier<Content: View>(
        @ViewBuilder content: @escaping (Self) -> Content
    ) -> some View {
        if ScreenshotModeManager.shared.isEnabled {
            return AnyView(content(self))
        } else {
            return AnyView(self)
        }
    }
}

