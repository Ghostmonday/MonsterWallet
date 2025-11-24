import Foundation

public enum AppConfig {
    public static let privacyPolicyURL = URL(string: "https://kryptoclaw.app/privacy")!
    public static let supportURL = URL(string: "https://kryptoclaw.app/support")!

    // Infrastructure
    public static let rpcURL = URL(string: "https://eth.llamarpc.com")!
    // Optional API for full transaction simulation (e.g. Tenderly)
    public static let simulationAPIURL: URL? = nil

    public static let openseaAPIKey: String? = {
        if let envKey = ProcessInfo.processInfo.environment["OPENSEA_API_KEY"] {
            return envKey
        }
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

        public static let isMPCEnabled = false
        public static let isGhostModeEnabled = false
        public static let isZKProofEnabled = false
        public static let isDAppBrowserEnabled = false // App Store compliance: High risk of rejection
        public static let isP2PSigningEnabled = false
    }
}
