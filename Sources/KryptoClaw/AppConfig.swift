import Foundation

public struct AppConfig {
    public static let privacyPolicyURL = URL(string: "https://kryptoclaw.app/privacy")!
    public static let supportURL = URL(string: "https://kryptoclaw.app/support")!
    
    // Infrastructure
    public static let rpcURL = URL(string: "https://eth.llamarpc.com")!
    public static let openseaAPIKey: String? = nil // Set via ENV or Build Config in production

    // Feature Flags
    // V1.0 Compliance: Novel/Risky features DISABLED. Standard features ENABLED.
    public struct Features {
        // Standard in Top-Tier Wallets
        public static let isMultiChainEnabled = true
        public static let isSwapEnabled = true // Standard interface, non-custodial
        public static let isAddressPoisoningProtectionEnabled = true // Enhanced Security

        // Novel/Risky (Disabled for approval safety)
        public static let isMPCEnabled = false
        public static let isGhostModeEnabled = false
        public static let isZKProofEnabled = false
        public static let isDAppBrowserEnabled = false // High risk of rejection (Store within Store)
        public static let isP2PSigningEnabled = false
    }
}
