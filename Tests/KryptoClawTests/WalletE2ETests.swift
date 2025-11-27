// MODULE: WalletE2ETests
// VERSION: 1.0.0
// PURPOSE: Comprehensive end-to-end tests for complete wallet user journeys

import XCTest
import BigInt
@testable import KryptoClaw
#if canImport(WalletCore)
import WalletCore
#endif

/// Comprehensive E2E tests covering the complete wallet user journey
/// Tests: Wallet creation → Import → Balance fetching → Transaction flow → Multi-chain operations
@available(iOS 13.0, macOS 10.15, *)
final class WalletE2ETests: XCTestCase {
    
    // MARK: - Test Setup
    
    private var walletStateManager: WalletStateManager!
    private var testKeyStore: TestableMockKeyStore!
    private var mockProvider: EnhancedMockBlockchainProvider!
    private var mockSigner: EnhancedMockSigner!
    
    // Test addresses
    private let testEthereumAddress = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
    private let testBitcoinAddress = "bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh"
    private let testSolanaAddress = "9WzDXwBbmkg8ZTbNMqUxvQRAyrZzDsGYdLVL9zYtAWWM"
    
    @MainActor
    override func setUp() {
        super.setUp()
        
        testKeyStore = TestableMockKeyStore()
        mockProvider = EnhancedMockBlockchainProvider()
        mockSigner = EnhancedMockSigner()
        
        walletStateManager = WalletStateManager(
            keyStore: testKeyStore,
            blockchainProvider: mockProvider,
            simulator: LocalSimulator(provider: mockProvider),
            router: EnhancedMockRouter(),
            securityPolicy: BasicHeuristicAnalyzer(),
            signer: mockSigner,
            nftProvider: MockNFTProvider(),
            poisoningDetector: nil,
            clipboardGuard: nil
        )
    }
    
    @MainActor
    override func tearDown() {
        walletStateManager = nil
        testKeyStore = nil
        mockProvider = nil
        mockSigner = nil
        super.tearDown()
    }
    
    // MARK: - E2E Test: Complete Wallet Creation Flow
    
    @MainActor
    func testE2E_WalletCreationFlow() async {
        print("\n🧪 E2E Test: Complete Wallet Creation Flow")
        
        // Step 1: Create a new wallet
        let mnemonic = await walletStateManager.createWallet(name: "Test Wallet")
        
        XCTAssertNotNil(mnemonic, "Wallet creation should return a mnemonic")
        XCTAssertFalse(mnemonic!.isEmpty, "Mnemonic should not be empty")
        
        // Verify mnemonic is valid
        XCTAssertTrue(MnemonicService.validate(mnemonic: mnemonic!), "Generated mnemonic should be valid")
        
        // Step 2: Verify wallet was added to wallets list
        let wallets = await walletStateManager.wallets
        XCTAssertFalse(wallets.isEmpty, "Wallets list should contain the new wallet")
        XCTAssertEqual(wallets.first?.name, "Test Wallet", "Wallet name should match")
        
        // Step 3: Verify account is loaded
        let currentAddress = await walletStateManager.currentAddress
        XCTAssertNotNil(currentAddress, "Current address should be set after wallet creation")
        
        // Step 4: Verify balance is fetched
        let state = await walletStateManager.state
        if case .loaded(let balances) = state {
            XCTAssertFalse(balances.isEmpty, "Balances should be loaded")
            print("✅ Wallet created successfully with address: \(currentAddress ?? "nil")")
        } else {
            XCTFail("State should be loaded after wallet creation")
        }
    }
    
    // MARK: - E2E Test: Wallet Import Flow
    
    @MainActor
    func testE2E_WalletImportFlow() async {
        print("\n🧪 E2E Test: Wallet Import Flow")
        
        // Use known test mnemonic (Anvil/Hardhat default)
        let testMnemonic = "test test test test test test test test test test test junk"
        
        // Step 1: Import wallet
        await walletStateManager.importWallet(mnemonic: testMnemonic)
        
        // Step 2: Verify wallet was imported
        let wallets = await walletStateManager.wallets
        XCTAssertFalse(wallets.isEmpty, "Wallets list should contain imported wallet")
        
        // Step 3: Verify address matches expected
        let currentAddress = await walletStateManager.currentAddress
        XCTAssertNotNil(currentAddress, "Current address should be set")
        XCTAssertEqual(currentAddress, testEthereumAddress, "Imported wallet should derive to expected address")
        
        // Step 4: Verify balance is loaded
        let state = await walletStateManager.state
        if case .loaded(let balances) = state {
            XCTAssertNotNil(balances[.ethereum], "ETH balance should be loaded")
            print("✅ Wallet imported successfully. Address: \(currentAddress ?? "nil")")
        } else {
            XCTFail("State should be loaded after import")
        }
    }
    
    // MARK: - E2E Test: Multi-Chain Balance Fetching
    
    @MainActor
    func testE2E_MultiChainBalanceFetching() async {
        print("\n🧪 E2E Test: Multi-Chain Balance Fetching")
        
        // Setup: Import wallet first
        let testMnemonic = "test test test test test test test test test test test junk"
        await walletStateManager.importWallet(mnemonic: testMnemonic)
        
        // Step 1: Load account
        await walletStateManager.loadAccount(id: testEthereumAddress)
        
        // Step 2: Refresh balances (should fetch all chains in parallel)
        await walletStateManager.refreshBalance()
        
        // Step 3: Verify balances for all chains
        let state = await walletStateManager.state
        if case .loaded(let balances) = state {
            // Verify ETH balance
            XCTAssertNotNil(balances[.ethereum], "ETH balance should be present")
            XCTAssertEqual(balances[.ethereum]?.currency, "ETH", "ETH currency should match")
            
            // Verify BTC balance (may be 0 in test)
            XCTAssertNotNil(balances[.bitcoin], "BTC balance should be present")
            
            // Verify SOL balance (may be 0 in test)
            XCTAssertNotNil(balances[.solana], "SOL balance should be present")
            
            print("✅ Multi-chain balances fetched:")
            balances.forEach { chain, balance in
                print("   \(chain.rawValue): \(balance.amount) \(balance.currency)")
            }
        } else {
            XCTFail("State should be loaded with balances")
        }
    }
    
    // MARK: - E2E Test: Complete Transaction Flow
    
    @MainActor
    func testE2E_CompleteTransactionFlow() async {
        print("\n🧪 E2E Test: Complete Transaction Flow")
        
        // Setup: Import wallet
        let testMnemonic = "test test test test test test test test test test test junk"
        await walletStateManager.importWallet(mnemonic: testMnemonic)
        await walletStateManager.loadAccount(id: testEthereumAddress)
        
        // Set initial balance in mock provider
        mockProvider.setBalance(address: testEthereumAddress, chain: .ethereum, amount: "5.0")
        
        // Step 1: Prepare transaction
        let recipientAddress = "0x70997970C51812dc3A010C7d01b50e0d17dc79C8"
        let amount = "1000000000000000000" // 1 ETH in wei
        
        await walletStateManager.prepareTransaction(
            to: recipientAddress,
            value: amount,
            chain: .ethereum
        )
        
        // Step 2: Verify simulation result
        let simulationResult = await walletStateManager.simulationResult
        XCTAssertNotNil(simulationResult, "Simulation result should be present")
        XCTAssertTrue(simulationResult!.success, "Transaction simulation should succeed")
        
        // Step 3: Verify pending transaction
        let pendingTx = await walletStateManager.pendingTransaction
        XCTAssertNotNil(pendingTx, "Pending transaction should be set")
        XCTAssertEqual(pendingTx?.to, recipientAddress, "Recipient address should match")
        
        // Step 4: Confirm and broadcast transaction
        let success = await walletStateManager.confirmTransaction(
            to: recipientAddress,
            value: amount,
            chain: .ethereum
        )
        
        XCTAssertTrue(success, "Transaction confirmation should succeed")
        
        // Step 5: Verify transaction hash
        let txHash = await walletStateManager.lastTxHash
        XCTAssertNotNil(txHash, "Transaction hash should be set")
        XCTAssertFalse(txHash!.isEmpty, "Transaction hash should not be empty")
        
        // Step 6: Verify balance refresh was triggered
        let finalState = await walletStateManager.state
        if case .loaded(let balances) = finalState {
            XCTAssertNotNil(balances[.ethereum], "Balance should still be present after TX")
        }
        
        print("✅ Transaction flow completed successfully. TX Hash: \(txHash ?? "nil")")
    }
    
    // MARK: - E2E Test: Transaction with Contract Data
    
    @MainActor
    func testE2E_TransactionWithContractData() async {
        print("\n🧪 E2E Test: Transaction with Contract Data")
        
        // Setup
        let testMnemonic = "test test test test test test test test test test test junk"
        await walletStateManager.importWallet(mnemonic: testMnemonic)
        await walletStateManager.loadAccount(id: testEthereumAddress)
        mockProvider.setBalance(address: testEthereumAddress, chain: .ethereum, amount: "5.0")
        
        // ERC-20 transfer data (transfer(address,uint256))
        let contractData = Data(hexString: "a9059cbb00000000000000000000000070997970c51812dc3a010c7d01b50e0d17dc79c80000000000000000000000000000000000000000000000000de0b6b3a7640000")!
        
        let contractAddress = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48" // USDC
        
        await walletStateManager.prepareTransaction(
            to: contractAddress,
            value: "0",
            chain: .ethereum,
            data: contractData
        )
        
        let simulationResult = await walletStateManager.simulationResult
        XCTAssertNotNil(simulationResult, "Contract transaction should be simulated")
        
        let success = await walletStateManager.confirmTransaction(
            to: contractAddress,
            value: "0",
            chain: .ethereum
        )
        
        XCTAssertTrue(success, "Contract transaction should succeed")
        print("✅ Contract transaction completed successfully")
    }
    
    // MARK: - E2E Test: Error Handling - Insufficient Funds
    
    @MainActor
    func testE2E_ErrorHandling_InsufficientFunds() async {
        print("\n🧪 E2E Test: Error Handling - Insufficient Funds")
        
        // Setup: Import wallet with low balance
        let testMnemonic = "test test test test test test test test test test test junk"
        await walletStateManager.importWallet(mnemonic: testMnemonic)
        await walletStateManager.loadAccount(id: testEthereumAddress)
        
        // Set balance to 0.001 ETH (less than transaction amount)
        mockProvider.setBalance(address: testEthereumAddress, chain: .ethereum, amount: "0.001")
        
        // Try to send 1 ETH
        await walletStateManager.prepareTransaction(
            to: "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
            value: "1000000000000000000", // 1 ETH
            chain: .ethereum
        )
        
        // Verify error state
        let state = await walletStateManager.state
        if case .error(let message) = state {
            XCTAssertTrue(
                message.lowercased().contains("insufficient") || 
                message.lowercased().contains("funds"),
                "Error message should mention insufficient funds. Got: \(message)"
            )
            print("✅ Insufficient funds error handled correctly: \(message)")
        } else {
            // Simulation might pass, but actual send should fail
            let success = await walletStateManager.confirmTransaction(
                to: "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
                value: "1000000000000000000",
                chain: .ethereum
            )
            XCTAssertFalse(success, "Transaction should fail with insufficient funds")
        }
    }
    
    // MARK: - E2E Test: Wallet Switching
    
    @MainActor
    func testE2E_WalletSwitching() async {
        print("\n🧪 E2E Test: Wallet Switching")
        
        // Step 1: Create first wallet
        let mnemonic1 = await walletStateManager.createWallet(name: "Wallet 1")
        XCTAssertNotNil(mnemonic1)
        let address1 = await walletStateManager.currentAddress
        
        // Step 2: Create second wallet
        let mnemonic2 = await walletStateManager.createWallet(name: "Wallet 2")
        XCTAssertNotNil(mnemonic2)
        let address2 = await walletStateManager.currentAddress
        
        XCTAssertNotEqual(address1, address2, "Wallets should have different addresses")
        
        // Step 3: Switch back to first wallet
        await walletStateManager.switchWallet(id: address1!)
        
        let currentAddress = await walletStateManager.currentAddress
        XCTAssertEqual(currentAddress, address1, "Should switch back to first wallet")
        
        // Step 4: Verify balances are loaded for switched wallet
        let state = await walletStateManager.state
        if case .loaded(let balances) = state {
            XCTAssertFalse(balances.isEmpty, "Balances should be loaded after switch")
        }
        
        print("✅ Wallet switching works correctly")
    }
    
    // MARK: - E2E Test: Wallet Deletion
    
    @MainActor
    func testE2E_WalletDeletion() async {
        print("\n🧪 E2E Test: Wallet Deletion")
        
        // Step 1: Create two wallets
        let mnemonic1 = await walletStateManager.createWallet(name: "Wallet 1")
        let address1 = await walletStateManager.currentAddress
        
        let mnemonic2 = await walletStateManager.createWallet(name: "Wallet 2")
        let address2 = await walletStateManager.currentAddress
        
        // Step 2: Verify both wallets exist
        var wallets = await walletStateManager.wallets
        XCTAssertEqual(wallets.count, 2, "Should have 2 wallets")
        
        // Step 3: Delete first wallet (should switch to second)
        await walletStateManager.deleteWallet(id: address1!)
        
        // Step 4: Verify wallet was deleted and switched
        wallets = await walletStateManager.wallets
        XCTAssertEqual(wallets.count, 1, "Should have 1 wallet after deletion")
        XCTAssertEqual(wallets.first?.id, address2, "Remaining wallet should be Wallet 2")
        
        let currentAddress = await walletStateManager.currentAddress
        XCTAssertEqual(currentAddress, address2, "Should switch to remaining wallet")
        
        print("✅ Wallet deletion works correctly")
    }
    
    // MARK: - E2E Test: Balance Refresh After Transaction
    
    @MainActor
    func testE2E_BalanceRefreshAfterTransaction() async {
        print("\n🧪 E2E Test: Balance Refresh After Transaction")
        
        // Setup
        let testMnemonic = "test test test test test test test test test test test junk"
        await walletStateManager.importWallet(mnemonic: testMnemonic)
        await walletStateManager.loadAccount(id: testEthereumAddress)
        
        // Set initial balance
        mockProvider.setBalance(address: testEthereumAddress, chain: .ethereum, amount: "5.0")
        await walletStateManager.refreshBalance()
        
        // Get initial balance
        let initialState = await walletStateManager.state
        var initialBalance: String = "0"
        if case .loaded(let balances) = initialState {
            initialBalance = balances[.ethereum]?.amount ?? "0"
        }
        
        // Send transaction
        let success = await walletStateManager.confirmTransaction(
            to: "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
            value: "1000000000000000000", // 1 ETH
            chain: .ethereum
        )
        
        XCTAssertTrue(success, "Transaction should succeed")
        
        // Update mock balance (simulate blockchain update)
        mockProvider.setBalance(address: testEthereumAddress, chain: .ethereum, amount: "4.0")
        
        // Refresh balance
        await walletStateManager.refreshBalance()
        
        // Verify balance updated
        let finalState = await walletStateManager.state
        if case .loaded(let balances) = finalState {
            let finalBalance = balances[.ethereum]?.amount ?? "0"
            XCTAssertNotEqual(initialBalance, finalBalance, "Balance should change after transaction")
            print("✅ Balance refreshed: \(initialBalance) → \(finalBalance)")
        } else {
            XCTFail("State should be loaded")
        }
    }
    
    // MARK: - E2E Test: Transaction History
    
    @MainActor
    func testE2E_TransactionHistory() async {
        print("\n🧪 E2E Test: Transaction History")
        
        // Setup
        let testMnemonic = "test test test test test test test test test test test junk"
        await walletStateManager.importWallet(mnemonic: testMnemonic)
        await walletStateManager.loadAccount(id: testEthereumAddress)
        
        // Add mock transaction history
        let mockTx = TransactionSummary(
            hash: "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
            from: testEthereumAddress,
            to: "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
            value: "1.0",
            timestamp: Date(),
            chain: .ethereum
        )
        mockProvider.addTransactionHistory(address: testEthereumAddress, chain: .ethereum, tx: mockTx)
        
        // Refresh balance (triggers history fetch in background)
        await walletStateManager.refreshBalance()
        
        // Wait a bit for history to load
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Verify history
        let history = await walletStateManager.history
        XCTAssertFalse(history.transactions.isEmpty, "History should contain transactions")
        
        if let firstTx = history.transactions.first {
            XCTAssertEqual(firstTx.hash, mockTx.hash, "Transaction hash should match")
            print("✅ Transaction history loaded: \(history.transactions.count) transactions")
        }
    }
}

// MARK: - Enhanced Mock Providers

/// Enhanced mock blockchain provider with configurable balances and transaction history
class EnhancedMockBlockchainProvider: BlockchainProviderProtocol {
    private var balances: [String: [Chain: Balance]] = [:]
    private var transactionHistory: [String: [Chain: [TransactionSummary]]] = [:]
    
    func setBalance(address: String, chain: Chain, amount: String) {
        if balances[address] == nil {
            balances[address] = [:]
        }
        balances[address]?[chain] = Balance(
            amount: amount,
            currency: chain.nativeCurrency,
            decimals: chain.decimals
        )
    }
    
    func addTransactionHistory(address: String, chain: Chain, tx: TransactionSummary) {
        if transactionHistory[address] == nil {
            transactionHistory[address] = [:]
        }
        if transactionHistory[address]?[chain] == nil {
            transactionHistory[address]?[chain] = []
        }
        transactionHistory[address]?[chain]?.append(tx)
    }
    
    func fetchBalance(address: String, chain: Chain) async throws -> Balance {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 50_000_000) // 50ms
        
        if let balance = balances[address]?[chain] {
            return balance
        }
        
        // Default balance
        return Balance(amount: "0.0", currency: chain.nativeCurrency, decimals: chain.decimals)
    }
    
    func fetchHistory(address: String, chain: Chain) async throws -> TransactionHistory {
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        let txs = transactionHistory[address]?[chain] ?? []
        return TransactionHistory(transactions: txs)
    }
    
    func broadcast(signedTx: Data, chain: Chain) async throws -> String {
        try await Task.sleep(nanoseconds: 200_000_000) // 200ms
        
        // Generate mock transaction hash
        let hash = "0x" + Data((0..<32).map { _ in UInt8.random(in: 0...255) })
            .map { String(format: "%02x", $0) }
            .joined()
        return hash
    }
    
    func fetchPrice(chain: Chain) async throws -> Decimal {
        return Decimal(2000) // Mock price
    }
    
    func estimateGas(to: String, value: String, data: Data, chain: Chain) async throws -> GasEstimate {
        return GasEstimate(
            gasLimit: 21000,
            maxFeePerGas: "20000000000",
            maxPriorityFeePerGas: "1000000000"
        )
    }
}

/// Enhanced mock signer that tracks signing operations
class EnhancedMockSigner: SignerProtocol {
    private(set) var signedTransactions: [Transaction] = []
    
    func signTransaction(tx: Transaction) async throws -> SignedData {
        signedTransactions.append(tx)
        
        // Generate mock signed transaction
        let mockSignature = Data((0..<65).map { _ in UInt8.random(in: 0...255) })
        let mockRaw = Data((0..<100).map { _ in UInt8.random(in: 0...255) })
        let mockHash = "0x" + Data((0..<32).map { _ in UInt8.random(in: 0...255) })
            .map { String(format: "%02x", $0) }
            .joined()
        
        return SignedData(raw: mockRaw, signature: mockSignature, txHash: mockHash)
    }
    
    func signMessage(message: String) async throws -> Data {
        return Data((0..<65).map { _ in UInt8.random(in: 0...255) })
    }
}

/// Enhanced mock router with nonce support
class EnhancedMockRouter: RoutingProtocol {
    private var nonces: [String: UInt64] = [:]
    
    func estimateGas(to: String, value: String, data: Data, chain: Chain) async throws -> GasEstimate {
        return GasEstimate(
            gasLimit: 21000,
            maxFeePerGas: "20000000000",
            maxPriorityFeePerGas: "1000000000"
        )
    }
    
    func getTransactionCount(address: String) async throws -> UInt64 {
        let nonce = nonces[address] ?? 0
        nonces[address] = nonce + 1
        return nonce
    }
}

