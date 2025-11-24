import Foundation

public struct AppConfig {
    public static let privacyPolicyURL = URL(string: "https://kryptoclaw.app/privacy")!
    public static let supportURL = URL(string: "https://kryptoclaw.app/support")!
    
    // Infrastructure
    public static let rpcURL = URL(string: "https://eth.llamarpc.com")!

    // Secrets Management
    // For local development, use Secrets.xcconfig (which is git-ignored).
    // In CI/Production, use Environment Variables.
    public static let openseaAPIKey: String? = {
        // 1. Try Environment Variable (CI/Production)
        if let envKey = ProcessInfo.processInfo.environment["OPENSEA_API_KEY"] {
            return envKey
        }

        // 2. Try Info.plist / Build Configuration (iOS App runtime)
        // Note: Reading from Secrets.xcconfig at runtime requires exposing it in Info.plist
        // or using a build script to generate a .swift file.
        // For this skeleton, we assume the environment variable or manual injection is primary.
        return nil
    }()

    // Feature Flags
    // V1.0 Compliance: Novel/Risky features DISABLED. Standard features ENABLED.
    public struct Features {
        // Standard in Top-Tier Wallets
        // DISABLED for V1 Submission to ensure stability (Pending full implementation)
        public static let isMultiChainEnabled = false
        public static let isSwapEnabled = false // Standard interface, non-custodial
        public static let isAddressPoisoningProtectionEnabled = true // Enhanced Security

        // Novel/Risky (Disabled for approval safety)
        public static let isMPCEnabled = false
        public static let isGhostModeEnabled = false
        public static let isZKProofEnabled = false
        public static let isDAppBrowserEnabled = false // High risk of rejection (Store within Store)
        public static let isP2PSigningEnabled = false
    }
}
