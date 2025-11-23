import Foundation
import Combine

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
    
    // State
    @Published public var state: AppState = .idle
    @Published public var history: TransactionHistory = TransactionHistory(transactions: [])
    @Published public var simulationResult: SimulationResult?
    @Published public var riskAlerts: [RiskAlert] = []
    @Published public var lastTxHash: String?
    @Published public var contacts: [Contact] = []
    @Published public var isPrivacyModeEnabled: Bool = false
    @Published public var nfts: [NFTMetadata] = []
    @Published public var wallets: [WalletInfo] = [
        WalletInfo(id: "primary_account", name: "Main Wallet", colorTheme: "blue")
    ]
    
    // Current Account
    public var currentAddress: String?
    
    public init(
        keyStore: KeyStoreProtocol,
        blockchainProvider: BlockchainProviderProtocol,
        simulator: TransactionSimulatorProtocol,
        router: RoutingProtocol,
        securityPolicy: SecurityPolicyProtocol,
        signer: SignerProtocol,
        nftProvider: NFTProviderProtocol
    ) {
        self.keyStore = keyStore
        self.blockchainProvider = blockchainProvider
        self.simulator = simulator
        self.router = router
        self.securityPolicy = securityPolicy
        self.signer = signer
        self.nftProvider = nftProvider
    }
    
    public func loadAccount(id: String) async {
        self.currentAddress = id
        await refreshBalance()
    }
    
    public func refreshBalance() async {
        guard let address = currentAddress else { return }
        
        self.state = .loading
        
        do {
            var balances: [Chain: Balance] = [:]
            
            // Fetch all chains concurrently
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
            
            // For history, we just fetch ETH for now as the main history
            // In a real app, we'd merge histories
            let history = try await blockchainProvider.fetchHistory(address: address, chain: .ethereum)
            
            // Fetch NFTs
            // In a real app, this would be parallel
            let nfts = try await nftProvider.fetchNFTs(address: address)
            
            self.state = .loaded(balances)
            self.history = history
            self.nfts = nfts
        } catch {
            self.state = .error(ErrorTranslator.userFriendlyMessage(for: error))
        }
    }
    
    public func prepareTransaction(to: String, value: String, chain: Chain = .ethereum) async {
        guard let from = currentAddress else { return }
        
        do {
            let estimate = try await router.estimateGas(to: to, value: value, data: Data(), chain: chain)
            
            let tx = Transaction(
                from: from,
                to: to,
                value: value,
                data: Data(),
                nonce: 0, 
                gasLimit: estimate.gasLimit,
                maxFeePerGas: estimate.maxFeePerGas,
                maxPriorityFeePerGas: estimate.maxPriorityFeePerGas,
                chainId: chain == .ethereum ? 1 : 0 // Simplified chain mapping
            )
            
            let result = try await simulator.simulate(tx: tx)
            let alerts = securityPolicy.analyze(result: result, tx: tx)
            
            self.simulationResult = result
            self.riskAlerts = alerts
            
        } catch {
            self.state = .error(ErrorTranslator.userFriendlyMessage(for: error))
        }
    }
    
    public func confirmTransaction(to: String, value: String, chain: Chain = .ethereum) async {
        guard let from = currentAddress else { return }
        guard let simResult = simulationResult, simResult.success else {
            self.state = .error("Cannot confirm: Simulation failed or not run")
            return
        }
        
        do {
            // Re-create tx (in a real app, we'd store the prepared tx)
            // For V1.0, we assume inputs haven't changed or we'd store the Tx in state.
            // Let's assume we need to re-estimate or use stored values.
            // To be safe and atomic, we should probably store the `pendingTransaction` in state.
            // But for now, let's re-create it using the same logic (assuming deterministic).
            
            let estimate = try await router.estimateGas(to: to, value: value, data: Data(), chain: chain)
            
            let tx = Transaction(
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
            
            // 1. Sign
            let signedData = try await signer.signTransaction(tx: tx)
            
            // 2. Broadcast
            let txHash = try await blockchainProvider.broadcast(signedTx: signedData.raw, chain: chain)
            
            self.lastTxHash = txHash
            
            // 3. Refresh
            await refreshBalance()
            
        } catch {
            self.state = .error(ErrorTranslator.userFriendlyMessage(for: error))
        }
    }
    
    // MARK: - Privacy
    public func togglePrivacyMode() {
        isPrivacyModeEnabled.toggle()
    }
    
    // MARK: - Contact Management
    public func addContact(_ contact: Contact) {
        contacts.append(contact)
        // In a real app, we would persist to disk here
    }
    
    public func removeContact(id: UUID) {
        contacts.removeAll { $0.id == id }
    }
    
    // MARK: - Wallet Management
    public func createWallet(name: String) async {
        // In a real app:
        // 1. Generate Mnemonic
        // 2. Derive Key
        // 3. Store in KeyStore
        // 4. Update State
        
        // Simulation
        let newId = UUID().uuidString
        let newWallet = WalletInfo(id: newId, name: name, colorTheme: "purple")
        wallets.append(newWallet)
        await loadAccount(id: newId)
    }
    
    public func switchWallet(id: String) async {
        print("[WalletManagement] SwitchWallet: \(id)")
        await loadAccount(id: id)
    }
}
