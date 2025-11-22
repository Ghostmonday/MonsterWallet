import Foundation

public struct AppConfig {
    public static let privacyPolicyURL = URL(string: "https://monsterwallet.app/privacy")!
    public static let supportURL = URL(string: "https://monsterwallet.app/support")!
    
    // Feature Flags (V1.0 Compliance: All V2.0 features MUST be false)
    public struct Features {
        public static let isMPCEnabled = false
        public static let isGhostModeEnabled = false
        public static let isZKProofEnabled = false
        public static let isDAppBrowserEnabled = false
        public static let isP2PSigningEnabled = false
    }
}
