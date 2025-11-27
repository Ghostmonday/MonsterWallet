import Foundation

public enum AppConfig {
    public static let privacyPolicyURL = URL(string: "https://kryptoclaw.app/privacy")!
    public static let supportURL = URL(string: "https://kryptoclaw.app/support")!
    
    // MARK: - API Keys (Optional - features work without them, just with rate limits)
    
    /// Etherscan API key for mainnet transaction history
    /// Get free key at: https://etherscan.io/apis
    public static var etherscanAPIKey: String? {
        ProcessInfo.processInfo.environment["ETHERSCAN_API_KEY"]
    }
    
    /// 1inch API key for swap quotes
    /// Get key at: https://portal.1inch.dev/
    public static var oneInchAPIKey: String? {
        ProcessInfo.processInfo.environment["ONEINCH_API_KEY"]
    }

    // MARK: - Environment Detection
    
    /// Check if running in test/development mode
    /// ⚠️ TEMPORARILY FORCED TO TRUE FOR LOCAL TESTING - REVERT BEFORE RELEASE
    public static var isTestEnvironment: Bool {
        #if DEBUG
        return true // FORCED FOR TESTING - was: env/args check
        #else
        return false
        #endif
    }
    
    // MARK: - Docker Test Environment (localhost)
    
    public struct TestEndpoints {
        public static let ethereumRPC = URL(string: "http://localhost:8545")!
        public static let solanaRPC = URL(string: "http://localhost:8899")!
        public static let solanaWS = URL(string: "ws://localhost:8900")!
        public static let bitcoinRPC = URL(string: "http://localhost:18443")!
        public static let bitcoinAuth = "kryptoclaw:testpass123"
        public static let proxyURL = URL(string: "http://localhost:8080")!
        
        // Test chain IDs
        public static let ethereumChainId = 31337 // Anvil local (0x7a69)
    }
    
    // MARK: - Test Wallet (Pre-funded with 10,000 ETH)
    
    /// Standard test wallet for local blockchain testing
    /// ⚠️  PUBLIC TEST WALLET - Never use with real funds
    public struct TestWallet {
        /// Standard test mnemonic from Hardhat/Anvil
        public static let mnemonic = "test test test test test test test test test test test junk"
        
        /// Primary test account address (m/44'/60'/0'/0/0)
        public static let address = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
        
        /// Private key for primary account
        public static let privateKey = "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
        
        /// Additional pre-funded accounts (same mnemonic, different indices)
        public static let additionalAccounts = [
            "0x70997970C51812dc3A010C7d01b50e0d17dc79C8", // Account 1
            "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC", // Account 2
            "0x90F79bf6EB2c4f870365E785982E1f101E93b906"  // Account 3
        ]
    }
    
    // MARK: - Chain ID Helpers
    
    /// Get the appropriate Ethereum chain ID based on environment
    public static func getEthereumChainId() -> Int {
        return isTestEnvironment ? TestEndpoints.ethereumChainId : 1
    }

    // MARK: - Infrastructure
    
    public static var rpcURL: URL {
        isTestEnvironment ? TestEndpoints.ethereumRPC : URL(string: "https://eth.llamarpc.com")!
    }
    
    // Optional API for full transaction simulation (e.g. Tenderly)
    public static let simulationAPIURL: URL? = nil

    public static let openseaAPIKey: String? = {
        if let envKey = ProcessInfo.processInfo.environment["OPENSEA_API_KEY"] {
            return envKey
        }
        return nil
    }()

    // // B) IMPLEMENTATION INSTRUCTIONS
    // The following keys are placeholders for future provider expansion (Phase 3).
    // - alchemyAPIKey: Will replace LlamaRPC for higher reliability.
    // - walletConnectProjectId: Required for WalletConnect V2 integration.
    public static let alchemyAPIKey: String? = nil
    public static let walletConnectProjectId: String? = nil

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
