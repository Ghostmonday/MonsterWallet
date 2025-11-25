// MODULE: WalletCoreManager
// VERSION: 1.0.0
// PURPOSE: Actor-based wallet management with multi-chain derivation and parallel balance fetching

import Foundation
#if canImport(WalletCore)
import WalletCore
#endif

// MARK: - Wallet Core Error

public enum WalletCoreError: Error, LocalizedError, Sendable {
    case noSeedAvailable
    case derivationFailed(chain: AssetChain)
    case invalidMnemonic
    case balanceFetchFailed(chain: AssetChain, underlying: Error?)
    case priceFetchFailed(underlying: Error?)
    case walletNotUnlocked
    case walletCoreUnavailable
    
    public var errorDescription: String? {
        switch self {
        case .noSeedAvailable:
            return "No wallet seed found. Please create or import a wallet."
        case .derivationFailed(let chain):
            return "Failed to derive address for \(chain.displayName)."
        case .invalidMnemonic:
            return "The recovery phrase is invalid."
        case .balanceFetchFailed(let chain, let error):
            return "Failed to fetch \(chain.displayName) balance: \(error?.localizedDescription ?? "Unknown")"
        case .priceFetchFailed(let error):
            return "Failed to fetch prices: \(error?.localizedDescription ?? "Unknown")"
        case .walletNotUnlocked:
            return "Wallet is locked. Please authenticate to continue."
        case .walletCoreUnavailable:
            return "Wallet core functionality is not available."
        }
    }
}

// MARK: - Derivation Path Standards

/// Standard BIP derivation paths
public enum DerivationPath {
    /// BIP-44 for Ethereum: m/44'/60'/0'/0/0
    public static func ethereum(account: UInt32 = 0, index: UInt32 = 0) -> String {
        "m/44'/60'/\(account)'/0/\(index)"
    }
    
    /// BIP-84 for Bitcoin Native SegWit: m/84'/0'/0'/0/0
    public static func bitcoinNativeSegWit(account: UInt32 = 0, index: UInt32 = 0) -> String {
        "m/84'/0'/\(account)'/0/\(index)"
    }
    
    /// BIP-44 for Solana: m/44'/501'/0'/0'
    public static func solana(account: UInt32 = 0) -> String {
        "m/44'/501'/\(account)'/0'"
    }
}

// MARK: - Wallet Core Manager

/// Actor managing wallet derivation, balance fetching, and portfolio state.
///
/// **Architecture:**
/// - Uses KeychainVault for secure seed storage with envelope encryption
/// - Derives addresses for BTC (BIP-84), ETH (BIP-44), SOL (BIP-44)
/// - Fetches balances in parallel using TaskGroup
/// - Thread-safe state management via actor isolation
@available(iOS 15.0, macOS 12.0, *)
public actor WalletCoreManager {
    
    // MARK: - Dependencies
    
    private let vault: KeychainVault
    private let blockchainProvider: BlockchainProviderProtocol
    private let tokenService: TokenDiscoveryService
    
    // MARK: - State
    
    /// Current wallet account
    private(set) var currentAccount: WalletAccount?
    
    /// Current portfolio
    private(set) var portfolio: Portfolio = .empty
    
    /// Is the wallet unlocked (seed is cached)
    private(set) var isUnlocked: Bool = false
    
    /// Cached mnemonic (only in memory, cleared on lock)
    private var cachedMnemonic: String?
    
    /// Balance fetch in progress
    private var isFetchingBalances: Bool = false
    
    // MARK: - Initialization
    
    public init(
        vault: KeychainVault,
        blockchainProvider: BlockchainProviderProtocol,
        tokenService: TokenDiscoveryService
    ) {
        self.vault = vault
        self.blockchainProvider = blockchainProvider
        self.tokenService = tokenService
    }
    
    /// Convenience initializer with default dependencies
    public init(session: URLSession = .shared) {
        self.vault = KeychainVault()
        self.blockchainProvider = MultiChainProvider(session: session)
        self.tokenService = TokenDiscoveryService(session: session)
    }
    
    // MARK: - Wallet Lifecycle
    
    /// Check if a wallet exists
    public func hasWallet() async -> Bool {
        await vault.hasSeed()
    }
    
    /// Create a new wallet with a generated mnemonic
    /// - Returns: The generated mnemonic for backup
    public func createWallet() async throws -> String {
        guard let mnemonic = MnemonicService.generateMnemonic() else {
            throw WalletCoreError.derivationFailed(chain: .ethereum)
        }
        
        // Store the seed securely
        try await vault.storeSeed(mnemonic)
        
        // Derive addresses and unlock
        try await unlock()
        
        return mnemonic
    }
    
    /// Import a wallet from an existing mnemonic
    public func importWallet(mnemonic: String) async throws {
        // Validate mnemonic
        guard MnemonicService.validate(mnemonic: mnemonic) else {
            throw WalletCoreError.invalidMnemonic
        }
        
        // Store the seed
        try await vault.storeSeed(mnemonic)
        
        // Derive addresses and unlock
        try await unlock()
    }
    
    /// Unlock the wallet (requires biometric authentication)
    public func unlock() async throws {
        let mnemonic = try await vault.retrieveSeed()
        cachedMnemonic = mnemonic
        
        // Derive addresses for all chains
        let addresses = try deriveAllAddresses(from: mnemonic)
        
        currentAccount = WalletAccount(
            name: "Main Wallet",
            colorTheme: "blue",
            addresses: addresses,
            isPrimary: true
        )
        
        isUnlocked = true
        
        // Fetch initial balances
        try await refreshBalances()
    }
    
    /// Lock the wallet (clear cached data)
    public func lock() {
        cachedMnemonic = nil
        isUnlocked = false
        // Don't clear portfolio - it can be shown in read-only mode
    }
    
    /// Delete the wallet completely
    public func deleteWallet() async throws {
        lock()
        try await vault.wipeAll()
        currentAccount = nil
        portfolio = .empty
    }
    
    // MARK: - Address Derivation
    
    /// Derive addresses for all supported chains
    private func deriveAllAddresses(from mnemonic: String) throws -> [DerivedAddress] {
        var addresses: [DerivedAddress] = []
        
        // Ethereum - BIP-44
        let ethPath = DerivationPath.ethereum()
        if let ethAddress = try? deriveAddress(mnemonic: mnemonic, chain: .ethereum, path: ethPath) {
            addresses.append(DerivedAddress(chain: .ethereum, address: ethAddress, derivationPath: ethPath))
        }
        
        // Bitcoin - BIP-84 Native SegWit (bc1q...)
        let btcPath = DerivationPath.bitcoinNativeSegWit()
        if let btcAddress = try? deriveAddress(mnemonic: mnemonic, chain: .bitcoin, path: btcPath) {
            addresses.append(DerivedAddress(chain: .bitcoin, address: btcAddress, derivationPath: btcPath))
        }
        
        // Solana - BIP-44
        let solPath = DerivationPath.solana()
        if let solAddress = try? deriveAddress(mnemonic: mnemonic, chain: .solana, path: solPath) {
            addresses.append(DerivedAddress(chain: .solana, address: solAddress, derivationPath: solPath))
        }
        
        return addresses
    }
    
    /// Derive a single address for a chain
    private func deriveAddress(mnemonic: String, chain: AssetChain, path: String) throws -> String {
        #if canImport(WalletCore)
        guard let wallet = HDWallet(mnemonic: mnemonic, passphrase: "") else {
            throw WalletCoreError.derivationFailed(chain: chain)
        }
        
        let coinType: CoinType
        switch chain {
        case .ethereum:
            coinType = .ethereum
        case .bitcoin:
            coinType = .bitcoin
        case .solana:
            coinType = .solana
        }
        
        let privateKey = wallet.getKey(coin: coinType, derivationPath: path)
        return coinType.deriveAddress(privateKey: privateKey)
        #else
        // Fallback for simulator/testing - return mock addresses
        switch chain {
        case .ethereum:
            return "0x742d35Cc6634C0532925a3b844Bc9e7595f8dE4a"
        case .bitcoin:
            return "bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh"
        case .solana:
            return "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"
        }
        #endif
    }
    
    /// Derive a private key for signing (requires unlock)
    public func getPrivateKey(for chain: AssetChain) async throws -> Data {
        guard let mnemonic = cachedMnemonic else {
            throw WalletCoreError.walletNotUnlocked
        }
        
        let path: String
        switch chain {
        case .ethereum:
            path = DerivationPath.ethereum()
        case .bitcoin:
            path = DerivationPath.bitcoinNativeSegWit()
        case .solana:
            path = DerivationPath.solana()
        }
        
        return try HDWalletService.derivePrivateKey(
            mnemonic: mnemonic,
            path: path,
            for: chain.hdWalletServiceChain
        )
    }
    
    // MARK: - Balance Fetching
    
    /// Refresh all balances in parallel
    public func refreshBalances() async throws {
        guard let account = currentAccount else {
            throw WalletCoreError.noSeedAvailable
        }
        
        guard !isFetchingBalances else { return }
        isFetchingBalances = true
        defer { isFetchingBalances = false }
        
        // Fetch prices in parallel with balances
        async let pricesTask = tokenService.fetchPrices(for: AssetChain.allCases.map { $0.nativeSymbol.lowercased() })
        
        // Fetch balances for all chains in parallel
        let balances = await withTaskGroup(of: AssetBalance?.self) { group in
            for address in account.addresses {
                group.addTask {
                    await self.fetchBalance(for: address)
                }
            }
            
            var results: [AssetBalance] = []
            for await balance in group {
                if let balance = balance {
                    results.append(balance)
                }
            }
            return results
        }
        
        // Apply prices
        let prices = (try? await pricesTask) ?? [:]
        let balancesWithPrices = balances.map { balance -> AssetBalance in
            let coingeckoId = balance.asset.coingeckoId ?? balance.asset.symbol.lowercased()
            if let priceData = prices[coingeckoId] {
                return AssetBalance(
                    asset: balance.asset,
                    rawBalance: balance.rawBalance,
                    priceUSD: priceData.priceUSD,
                    priceChange24h: priceData.priceChange24h,
                    lastUpdated: Date()
                )
            }
            return balance
        }
        
        portfolio = Portfolio(balances: balancesWithPrices)
        
        // Play haptic feedback on main thread
        await MainActor.run {
            HapticEngine.shared.play(.balanceRefresh)
        }
    }
    
    /// Fetch balance for a single address
    private func fetchBalance(for derivedAddress: DerivedAddress) async -> AssetBalance? {
        let asset = Asset.native(chain: derivedAddress.chain)
        
        do {
            let balance = try await blockchainProvider.fetchBalance(
                address: derivedAddress.address,
                chain: derivedAddress.chain.legacyChain
            )
            
            // Convert to raw balance (already in formatted string from provider)
            let rawBalance = try convertToRawBalance(amount: balance.amount, decimals: asset.decimals)
            
            return AssetBalance(
                asset: asset,
                rawBalance: rawBalance,
                lastUpdated: Date()
            )
        } catch {
            print("[WalletCoreManager] Balance fetch failed for \(derivedAddress.chain): \(error)")
            return AssetBalance(
                asset: asset,
                rawBalance: "0",
                lastUpdated: Date()
            )
        }
    }
    
    /// Convert formatted amount to raw balance
    private func convertToRawBalance(amount: String, decimals: Int) throws -> String {
        guard let decimalValue = Decimal(string: amount) else {
            return "0"
        }
        
        let multiplier = pow(Decimal(10), decimals)
        let rawValue = decimalValue * multiplier
        
        // Convert to integer string
        var rawDecimal = rawValue
        var result: Decimal = 0
        NSDecimalRound(&result, &rawDecimal, 0, .plain)
        
        return "\(result)"
    }
    
    // MARK: - Fetch Token Balances
    
    /// Fetch ERC-20 token balances for Ethereum
    public func fetchTokenBalances(tokens: [Asset]) async throws -> [AssetBalance] {
        guard let account = currentAccount,
              account.address(for: .ethereum) != nil else {
            throw WalletCoreError.noSeedAvailable
        }
        
        // For now, return empty - token balance fetching requires Etherscan API or indexer
        // TODO: Implement ERC-20 balance fetching via Etherscan/Alchemy
        return []
    }
    
    // MARK: - Getters
    
    /// Get address for a specific chain
    public func getAddress(for chain: AssetChain) -> String? {
        currentAccount?.address(for: chain)?.address
    }
    
    /// Get all addresses
    public func getAllAddresses() -> [DerivedAddress] {
        currentAccount?.addresses ?? []
    }
    
    /// Get current portfolio value in USD
    public func getTotalValueUSD() -> Decimal {
        portfolio.totalValueUSD
    }
    
    /// Get balance for a specific chain
    public func getBalance(for chain: AssetChain) -> AssetBalance? {
        portfolio.balances.first { $0.asset.chain == chain }
    }
}

// MARK: - Chain Conversion Extension

extension AssetChain {
    /// Convert to HDWalletService.Chain
    var hdWalletServiceChain: HDWalletService.Chain {
        switch self {
        case .ethereum: return .ethereum
        case .bitcoin: return .bitcoin
        case .solana: return .solana
        }
    }
}

// Note: hskBindingsFile is already defined in HSKTypes.swift

