import XCTest
@testable import MonsterWallet

final class SimulationDemo: XCTestCase {
    
    @MainActor
    func testRunDemo() async {
        print("\n\n==================================================")
        print("📱 MONSTER WALLET V1.0 - HEADLESS DEMO RUN")
        print("==================================================\n")
        
        // 1. App Launch
        print("🚀 App Launching...")
        let keychain = MockKeyStore() // Use Mock for demo to avoid biometric prompt on CI
        let provider = MockBlockchainProvider()
        let simulator = LocalSimulator(provider: provider)
        let router = MockRouter()
        let securityPolicy = BasicHeuristicAnalyzer()
        let signer = MockSigner()
        
        let wsm = WalletStateManager(
            keyStore: keychain,
            blockchainProvider: provider,
            simulator: simulator,
            router: router,
            securityPolicy: securityPolicy,
            signer: signer
        )
        
        print("✅ Core Systems Initialized.")
        
        // 2. Load Account (Home Screen)
        print("\n👤 User opens Home Screen...")
        await wsm.loadAccount(id: "0xUserWallet")
        
        if case .loaded(let balance) = await wsm.state {
            print("💰 Balance Displayed: \(balance.amount) \(balance.currency)")
        } else {
            print("❌ Failed to load balance")
        }
        
        // 3. User Taps Send
        print("\n👉 User taps 'Send'...")
        let toAddress = "0xRecipient"
        let amount = "0x100" // Hex for 256
        print("📝 User enters Recipient: \(toAddress)")
        print("📝 User enters Amount: \(amount)")
        
        // 4. Simulation (Auto-runs on input)
        print("\n🔄 Running Transaction Simulation...")
        await wsm.prepareTransaction(to: toAddress, value: amount)
        
        if let result = await wsm.simulationResult {
            if result.success {
                print("✅ Simulation PASSED")
                print("   - Est. Gas: \(result.estimatedGasUsed)")
                print("   - Risk Analysis: \(await wsm.riskAlerts.isEmpty ? "Safe" : "Risks Detected")")
            } else {
                print("❌ Simulation FAILED: \(result.error ?? "Unknown")")
            }
        }
        
        // 5. Confirmation
        print("\n🔓 User taps 'Confirm' (FaceID Triggered)...")
        await wsm.confirmTransaction(to: toAddress, value: amount)
        
        if let hash = await wsm.lastTxHash {
            print("🚀 Transaction Broadcasted Successfully!")
            print("🔗 Tx Hash: \(hash)")
        } else {
            print("❌ Transaction Failed Broadcast")
        }
        
        print("\n==================================================")
        print("🏁 DEMO COMPLETE")
        print("==================================================\n\n")
    }
}
