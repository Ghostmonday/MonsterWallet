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
        guard let address = currentAddress else { return }

        state = .loading

        do {
            var balances: [Chain: Balance] = [:]

            // Fetch balances for all chains concurrently
            try await withThrowingTaskGroup(of: (Chain, Balance).self) { group in
                for chain in Chain.allCases {
                    group.addTask {
                        let balance = try await self.blockchainProvider.fetchBalance(address: address, chain: chain)
                        return (chain, balance)
                    }
                }

                for try await (chain, balance) in group {
                    balances[chain] = balance
                }
            }

            // Parallel data fetching for History and NFTs
            // We fetch history for ALL chains now (JULES-REVIEW requirement met)
            async let historyResult: TransactionHistory = {
                var allSummaries: [TransactionSummary] = []
                // We use a task group for histories as well
                try await withThrowingTaskGroup(of: TransactionHistory.self) { group in
                    for chain in Chain.allCases {
                        group.addTask {
                            try await self.blockchainProvider.fetchHistory(address: address, chain: chain)
                        }
                    }
                    for try await hist in group {
                        allSummaries.append(contentsOf: hist.transactions)
                    }
                }
                // Sort by timestamp descending (newest first)
                allSummaries.sort { $0.timestamp > $1.timestamp }
                return TransactionHistory(transactions: allSummaries)
            }()

            async let nftsResult = nftProvider.fetchNFTs(address: address)

            let (history, nfts) = try await (historyResult, nftsResult)

            state = .loaded(balances)
            self.history = history
            self.nfts = nfts
        } catch {
            state = .error(ErrorTranslator.userFriendlyMessage(for: error))
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

            let tx = Transaction(
                from: from,
                to: to,
                value: value,
                data: txData,
                nonce: 0,
                gasLimit: estimate.gasLimit,
                maxFeePerGas: estimate.maxFeePerGas,
                maxPriorityFeePerGas: estimate.maxPriorityFeePerGas,
                chainId: chain == .ethereum ? 1 : 0 // Simplified chain mapping
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

    public func confirmTransaction(to: String, value: String, chain: Chain = .ethereum) async {
        guard let from = currentAddress else { return }
        guard let simResult = simulationResult, simResult.success else {
            state = .error("Cannot confirm: Simulation failed or not run")
            return
        }

        do {
            // Safety check: Use pending transaction if inputs match, otherwise re-estimate
            var txToSign: Transaction

            if let pending = pendingTransaction, pending.to == to, pending.value == value {
                txToSign = pending
            } else {
                KryptoLogger.shared.log(level: .warning, category: .stateTransition, message: "Pending transaction mismatch or missing. Re-estimating.", metadata: ["to": to, "value": value])
                let estimate = try await router.estimateGas(to: to, value: value, data: Data(), chain: chain)
                txToSign = Transaction(
                    from: from,
                    to: to,
                    value: value,
                    data: Data(),
                    nonce: 0,
                    gasLimit: estimate.gasLimit,
                    maxFeePerGas: estimate.maxFeePerGas,
                    maxPriorityFeePerGas: estimate.maxPriorityFeePerGas,
                    chainId: chain == .ethereum ? 1 : 0
                )
            }

            let signedData = try await signer.signTransaction(tx: txToSign)
            let txHash = try await blockchainProvider.broadcast(signedTx: signedData.raw, chain: chain)

            lastTxHash = txHash
            pendingTransaction = nil
            await refreshBalance()

        } catch {
            state = .error(ErrorTranslator.userFriendlyMessage(for: error))
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
            let privateKey = try HDWalletService.derivePrivateKey(mnemonic: mnemonic, for: .ethereum)
            let address = HDWalletService.address(from: privateKey, for: .ethereum)

            // Check if already exists? (Optional)

            _ = try keyStore.storePrivateKey(key: privateKey, id: address)

            let newWallet = WalletInfo(id: address, name: "Imported Wallet", colorTheme: "blue")
            wallets.append(newWallet)
            saveWallets()
            await loadAccount(id: address)
        } catch {
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
            currentAddress = nil
            contacts.removeAll()
            // Clear UserDefaults
            UserDefaults.standard.removeObject(forKey: "hasOnboarded")
            // Clear persisted files
            try persistence.delete(filename: PersistenceService.contactsFile)
            try persistence.delete(filename: PersistenceService.walletsFile)
        } catch {
            KryptoLogger.shared.logError(module: "WalletStateManager", error: error)
        }
    }
}
