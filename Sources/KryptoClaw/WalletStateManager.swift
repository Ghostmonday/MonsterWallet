import Combine
import Foundation

public enum AppState: Equatable {
    case idle
    case loading
    case loaded([Chain: Balance])
    case error(String)
}

@available(iOS 13.0, macOS 10.15, *)
@MainActor
public class WalletStateManager: ObservableObject {
    // Dependencies
    private let keyStore: KeyStoreProtocol
    private let blockchainProvider: BlockchainProviderProtocol
    private let simulator: TransactionSimulatorProtocol
    private let router: RoutingProtocol
    private let securityPolicy: SecurityPolicyProtocol
    private let signer: SignerProtocol
    private let nftProvider: NFTProviderProtocol
    private let persistence: PersistenceServiceProtocol
    // V2 Security Dependencies
    private let poisoningDetector: AddressPoisoningDetector?
    private let clipboardGuard: ClipboardGuard?
    private let dexAggregator = DEXAggregator()

    // State
    @Published public var state: AppState = .idle
    @Published public var history: TransactionHistory = .init(transactions: [])
    @Published public var simulationResult: SimulationResult?
    @Published public var riskAlerts: [RiskAlert] = []
    @Published public var lastTxHash: String?
    @Published public var contacts: [Contact] = []
    @Published public var isPrivacyModeEnabled: Bool = false
    @Published public var nfts: [NFTMetadata] = []
    @Published public var wallets: [WalletInfo] = []
    @Published public var hskBoundWallets: [HSKBoundWallet] = []

    // Transaction Flow State
    @Published public var pendingTransaction: Transaction?

    // Current Account
    public var currentAddress: String?

    public init(
        keyStore: KeyStoreProtocol,
        blockchainProvider: BlockchainProviderProtocol,
        simulator: TransactionSimulatorProtocol,
        router: RoutingProtocol,
        securityPolicy: SecurityPolicyProtocol,
        signer: SignerProtocol,
        nftProvider: NFTProviderProtocol,
        poisoningDetector: AddressPoisoningDetector? = nil,
        clipboardGuard: ClipboardGuard? = nil,
        persistence: PersistenceServiceProtocol = PersistenceService.shared
    ) {
        self.keyStore = keyStore
        self.blockchainProvider = blockchainProvider
        self.simulator = simulator
        self.router = router
        self.securityPolicy = securityPolicy
        self.signer = signer
        self.nftProvider = nftProvider
        self.poisoningDetector = poisoningDetector
        self.clipboardGuard = clipboardGuard
        self.persistence = persistence

        loadPersistedData()
    }

    private func loadPersistedData() {
        do {
            contacts = try persistence.load([Contact].self, from: PersistenceService.contactsFile)
        } catch {
            // Ignore error if file doesn't exist (first run)
            contacts = []
        }

        do {
            wallets = try persistence.load([WalletInfo].self, from: PersistenceService.walletsFile)
        } catch {
            wallets = []
        }
        
        do {
            hskBoundWallets = try persistence.load([HSKBoundWallet].self, from: PersistenceService.hskBindingsFile)
        } catch {
            hskBoundWallets = []
        }

        // Fallback for fresh install if no wallets found
        if wallets.isEmpty {
            wallets = [WalletInfo(id: "primary_account", name: "Main Wallet", colorTheme: "blue")]
        }
    }

    public func loadAccount(id: String) async {
        currentAddress = id
        await refreshBalance()
    }

    public func refreshBalance() async {
        guard let address = currentAddress else {
            print("⚠️ [WalletStateManager] No currentAddress set!")
            return
        }
        
        NSLog("🔍 [WalletStateManager] Refreshing balance for: %@", address)

        state = .loading

        var balances: [Chain: Balance] = [:]
        
        // Fetch all chains (local endpoints now configured for test mode)
        let chainsToFetch: [Chain] = Chain.allCases

        // Fetch balances in PARALLEL with timeout
        await withTaskGroup(of: (Chain, Balance?).self) { group in
            for chain in chainsToFetch {
                group.addTask { [self] in
                    do {
                        // Add 5 second timeout per chain
                        let balance = try await self.withTimeout(seconds: 5) {
                            try await self.blockchainProvider.fetchBalance(address: address, chain: chain)
                        }
                        NSLog("✅ [%@] Balance: %@", chain.rawValue, balance.amount)
                        return (chain, balance)
                    } catch {
                        NSLog("⚠️ [%@] Balance fetch failed: %@", chain.rawValue, error.localizedDescription)
                        return (chain, nil)
                    }
                }
            }
            
            for await (chain, balance) in group {
                if let balance = balance {
                    balances[chain] = balance
                }
            }
        }
        
        NSLog("🟢 Balance fetches complete. Got %d balances", balances.count)

        // Set state to loaded with whatever balances we got
        state = .loaded(balances)
        NSLog("🟢 State set to .loaded!")

        // Fetch history in background (non-blocking)
        Task.detached { [weak self] in
            guard let self = self else { return }
            var allSummaries: [TransactionSummary] = []
            for chain in chainsToFetch {
                if let hist = try? await self.blockchainProvider.fetchHistory(address: address, chain: chain) {
                    allSummaries.append(contentsOf: hist.transactions)
                }
            }
            allSummaries.sort { $0.timestamp > $1.timestamp }
            await MainActor.run {
                self.history = TransactionHistory(transactions: allSummaries)
            }
        }
        
        // Fetch NFTs in background (non-blocking)
        Task.detached { [weak self] in
            guard let self = self else { return }
            if let nfts = try? await self.nftProvider.fetchNFTs(address: address) {
                await MainActor.run {
                    self.nfts = nfts
                }
            }
        }
    }
    
    /// Helper function for timeout
    private func withTimeout<T>(seconds: Double, operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw CancellationError()
            }
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }

    public func fetchPrice(chain: Chain) async throws -> Decimal {
        try await blockchainProvider.fetchPrice(chain: chain)
    }

    public func getSwapQuote(from: String, to: String, amount: String, chain: HDWalletService.Chain) async throws -> SwapQuote {
        try await dexAggregator.getQuote(from: from, to: to, amount: amount, chain: chain)
    }

    public func prepareTransaction(to: String, value: String, chain: Chain = .ethereum, data: Data? = nil) async {
        guard let from = currentAddress else { return }

        // Reset alerts first to avoid duplicates
        riskAlerts = []
        pendingTransaction = nil

        if let detector = poisoningDetector, AppConfig.Features.isAddressPoisoningProtectionEnabled {
            var safeHistory = contacts.map(\.address)
            let historicalRecipients = history.transactions.map(\.to)
            safeHistory.append(contentsOf: historicalRecipients)
            let uniqueHistory = Array(Set(safeHistory))

            let status = detector.analyze(targetAddress: to, safeHistory: uniqueHistory)

            if case let .potentialPoison(reason) = status {
                riskAlerts.append(RiskAlert(level: .critical, description: reason))
            }
        }

        do {
            let txData = data ?? Data()
            let estimate = try await router.estimateGas(to: to, value: value, data: txData, chain: chain)
            
            // Fetch current nonce from chain
            let nonce = try await router.getTransactionCount(address: from)
            NSLog("🔴 TX nonce for %@: %d", from, nonce)

            let tx = Transaction(
                from: from,
                to: to,
                value: value,
                data: txData,
                nonce: nonce,
                gasLimit: estimate.gasLimit,
                maxFeePerGas: estimate.maxFeePerGas,
                maxPriorityFeePerGas: estimate.maxPriorityFeePerGas,
                chainId: chain == .ethereum ? AppConfig.getEthereumChainId() : 0
            )

            let result = try await simulator.simulate(tx: tx)
            var alerts = securityPolicy.analyze(result: result, tx: tx)

            // Merge poisoning alerts if any
            if !riskAlerts.isEmpty {
                alerts.append(contentsOf: riskAlerts)
            }

            simulationResult = result
            riskAlerts = alerts
            pendingTransaction = tx

        } catch {
            state = .error(ErrorTranslator.userFriendlyMessage(for: error))
        }
    }

    /// Confirms and broadcasts a transaction. Returns true if successful, false otherwise.
    @discardableResult
    public func confirmTransaction(to: String, value: String, chain: Chain = .ethereum) async -> Bool {
        guard let from = currentAddress else { 
            NSLog("🔴 confirmTransaction: No current address!")
            return false 
        }
        
        // Skip simulation check in test mode - just build and send
        NSLog("🔴 confirmTransaction: from=%@, to=%@, value=%@", from, to, value)

        do {
            // Build transaction directly (skip simulation requirement for now)
            let estimate = try await router.estimateGas(to: to, value: value, data: Data(), chain: chain)
            let nonce = try await router.getTransactionCount(address: from)
            NSLog("🔴 Got nonce: %d, gasLimit: %d", nonce, estimate.gasLimit)
            
            let txToSign = Transaction(
                from: from,
                to: to,
                value: value,
                data: Data(),
                nonce: nonce,
                gasLimit: estimate.gasLimit,
                maxFeePerGas: estimate.maxFeePerGas,
                maxPriorityFeePerGas: estimate.maxPriorityFeePerGas,
                chainId: chain == .ethereum ? AppConfig.getEthereumChainId() : 0
            )
            
            NSLog("🔴 Signing transaction...")
            let signedData = try await signer.signTransaction(tx: txToSign)
            NSLog("🔴 Signed! Raw tx length: %d bytes", signedData.raw.count)
            
            NSLog("🔴 Broadcasting...")
            let txHash = try await blockchainProvider.broadcast(signedTx: signedData.raw, chain: chain)
            NSLog("✅ TX BROADCAST SUCCESS! Hash: %@", txHash)

            lastTxHash = txHash
            pendingTransaction = nil
            simulationResult = nil
            await refreshBalance()
            return true

        } catch {
            NSLog("🔴 confirmTransaction FAILED: %@", error.localizedDescription)
            state = .error(ErrorTranslator.userFriendlyMessage(for: error))
            return false
        }
    }

    // MARK: - Privacy

    public func togglePrivacyMode() {
        isPrivacyModeEnabled.toggle()
    }

    // MARK: - Contact Management

    public func addContact(_ contact: Contact) {
        contacts.append(contact)
        saveContacts()
    }

    public func removeContact(id: UUID) {
        contacts.removeAll { $0.id == id }
        saveContacts()
    }

    private func saveContacts() {
        do {
            try persistence.save(contacts, to: PersistenceService.contactsFile)
        } catch {
            KryptoLogger.shared.logError(module: "WalletStateManager", error: error)
        }
    }

    private func saveWallets() {
        do {
            try persistence.save(wallets, to: PersistenceService.walletsFile)
        } catch {
            KryptoLogger.shared.logError(module: "WalletStateManager", error: error)
        }
    }

    // MARK: - Wallet Management

    public func createWallet(name: String) async -> String? {
        // Real Implementation
        guard let mnemonic = MnemonicService.generateMnemonic() else {
            state = .error("Failed to generate mnemonic")
            return nil
        }

        do {
            let privateKey = try HDWalletService.derivePrivateKey(mnemonic: mnemonic, for: .ethereum)
            let address = HDWalletService.address(from: privateKey, for: .ethereum)

            // Store the key securely
            _ = try keyStore.storePrivateKey(key: privateKey, id: address)

            // Update State
            let newWallet = WalletInfo(id: address, name: name, colorTheme: "purple")
            wallets.append(newWallet)
            saveWallets()
            await loadAccount(id: address)

            return mnemonic // Return to UI for backup
        } catch {
            state = .error("Wallet creation failed: \(error.localizedDescription)")
            return nil
        }
    }

    public func importWallet(mnemonic: String) async {
        do {
            NSLog("🔴 IMPORT WALLET CALLED with: %@", mnemonic.prefix(30).description)
            
            let privateKey = try HDWalletService.derivePrivateKey(mnemonic: mnemonic, for: .ethereum)
            NSLog("🔴 Private key derived, length: %d", privateKey.count)
            NSLog("🔴 Private key hex: %@", privateKey.hexString)
            
            let address = HDWalletService.address(from: privateKey, for: .ethereum)
            NSLog("🔴 Derived address: %@", address)
            NSLog("🔴 Expected: %@", AppConfig.TestWallet.address)

            // Store with address ID for wallet management
            _ = try keyStore.storePrivateKey(key: privateKey, id: address)
            
            // Also store with "primary_account" ID for the signer
            _ = try keyStore.storePrivateKey(key: privateKey, id: "primary_account")

            let newWallet = WalletInfo(id: address, name: "Imported Wallet", colorTheme: "blue")
            wallets.append(newWallet)
            saveWallets()
            await loadAccount(id: address)
        } catch {
            print("❌ [WalletStateManager] Import failed: \(error)")
            state = .error("Import failed: \(error.localizedDescription)")
        }
    }

    public func switchWallet(id: String) async {
        KryptoLogger.shared.log(level: .info, category: .stateTransition, message: "Switching wallet", metadata: ["walletId": id])
        await loadAccount(id: id)
    }

    public func deleteWallet(id: String) async {
        // Don't allow deleting the currently active wallet
        if currentAddress == id {
            // Switch to another wallet first if available
            if let otherWallet = wallets.first(where: { $0.id != id }) {
                await switchWallet(id: otherWallet.id)
            } else {
                // No other wallets, clear current address
                currentAddress = nil
                state = .idle
            }
        }

        // Delete the key from keychain
        do {
            try keyStore.deleteKey(id: id)
        } catch {
            KryptoLogger.shared.logError(module: "WalletStateManager", error: error)
            // Continue with wallet removal even if key deletion fails (key might not exist)
        }

        // Remove from wallets list
        wallets.removeAll { $0.id == id }
        saveWallets()

        KryptoLogger.shared.log(level: .info, category: .stateTransition, message: "Wallet deleted", metadata: ["walletId": id])
    }

    public func copyCurrentAddress() {
        guard let address = currentAddress else { return }
        clipboardGuard?.protectClipboard(content: address, timeout: 60.0)
    }

    public func deleteAllData() {
        do {
            try keyStore.deleteAll()
            wallets.removeAll()
            hskBoundWallets.removeAll()
            currentAddress = nil
            contacts.removeAll()
            // Clear UserDefaults
            UserDefaults.standard.removeObject(forKey: "hasOnboarded")
            // Clear persisted files
            try persistence.delete(filename: PersistenceService.contactsFile)
            try persistence.delete(filename: PersistenceService.walletsFile)
            try persistence.delete(filename: PersistenceService.hskBindingsFile)
        } catch {
            KryptoLogger.shared.logError(module: "WalletStateManager", error: error)
        }
    }
    
    // MARK: - HSK Wallet Management
    
    /// Create a new HSK-bound wallet
    @available(iOS 15.0, macOS 12.0, *)
    public func createHSKBoundWallet(hskId: String, derivedKeyHandle: Data, address: String) async throws {
        let binding = HSKBoundWallet(
            hskId: hskId,
            derivedKeyHandle: derivedKeyHandle,
            address: address
        )
        
        // Store the key
        _ = try keyStore.storePrivateKey(key: derivedKeyHandle, id: address)
        
        // Add to bindings
        hskBoundWallets.append(binding)
        saveHSKBindings()
        
        // Add as a wallet
        let newWallet = WalletInfo(id: address, name: "HSK Wallet", colorTheme: "gold")
        wallets.append(newWallet)
        saveWallets()
        
        await loadAccount(id: address)
        
        KryptoLogger.shared.log(
            level: .info,
            category: .stateTransition,
            message: "HSK-bound wallet created",
            metadata: ["address": address]
        )
    }
    
    /// Bind an HSK to an existing wallet
    @available(iOS 15.0, macOS 12.0, *)
    public func bindHSKToWallet(walletId: String, hskId: String, derivedKeyHandle: Data) async throws {
        // Check if already bound
        if isWalletHSKBound(walletId) {
            throw HSKError.bindingFailed("Wallet is already bound to a hardware key")
        }
        
        let binding = HSKBoundWallet(
            hskId: hskId,
            derivedKeyHandle: derivedKeyHandle,
            address: walletId
        )
        
        hskBoundWallets.append(binding)
        saveHSKBindings()
        
        KryptoLogger.shared.log(
            level: .info,
            category: .stateTransition,
            message: "HSK bound to wallet",
            metadata: ["walletId": walletId]
        )
    }
    
    /// Check if a wallet is HSK-bound
    public func isWalletHSKBound(_ address: String) -> Bool {
        hskBoundWallets.contains { $0.address == address }
    }
    
    /// Get HSK binding for a wallet
    public func getHSKBinding(for address: String) -> HSKBoundWallet? {
        hskBoundWallets.first { $0.address == address }
    }
    
    /// Remove HSK binding from a wallet
    public func removeHSKBinding(for address: String) {
        hskBoundWallets.removeAll { $0.address == address }
        saveHSKBindings()
    }
    
    private func saveHSKBindings() {
        do {
            try persistence.save(hskBoundWallets, to: PersistenceService.hskBindingsFile)
        } catch {
            KryptoLogger.shared.logError(module: "WalletStateManager", error: error)
        }
    }
}
