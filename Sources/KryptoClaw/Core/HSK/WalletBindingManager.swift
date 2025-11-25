import Combine
import Foundation

// MARK: - Wallet Binding Manager Protocol

public protocol WalletBindingManagerProtocol {
    func completeBinding(hskId: String, derivedKeyHandle: Data, address: String, credentialId: Data?) async throws -> HSKBoundWallet
    func bindToExistingWallet(walletId: String, hskId: String, derivedKeyHandle: Data, credentialId: Data?) async throws -> HSKBoundWallet
    func getBinding(for walletAddress: String) async -> HSKBoundWallet?
    func getBinding(byHskId hskId: String) async -> HSKBoundWallet?
    func getAllBindings() async -> [HSKBoundWallet]
    func removeBinding(for walletAddress: String) async throws
    func isWalletBound(_ address: String) async -> Bool
    func updateLastUsed(for address: String) async throws
}

// MARK: - Wallet Binding Manager

/// SECURITY: This class is now an actor to ensure thread-safe access to the bindings array.
/// All mutable state is actor-isolated, preventing data races during concurrent operations.
public actor WalletBindingManager: WalletBindingManagerProtocol {
    
    // MARK: - Properties
    
    private let persistence: PersistenceServiceProtocol
    private let secureEnclaveInterface: SecureEnclaveInterfaceProtocol
    /// SECURITY: Actor isolation ensures thread-safe access to bindings.
    private var bindings: [HSKBoundWallet] = []
    
    // MARK: - Initialization
    
    public init(
        persistence: PersistenceServiceProtocol = PersistenceService.shared,
        secureEnclaveInterface: SecureEnclaveInterfaceProtocol
    ) {
        self.persistence = persistence
        self.secureEnclaveInterface = secureEnclaveInterface
        // Load bindings synchronously during init (actor not yet isolated)
        do {
            bindings = try persistence.load([HSKBoundWallet].self, from: PersistenceService.hskBindingsFile)
        } catch {
            bindings = []
        }
    }
    
    // MARK: - Public Methods
    
    /// Complete the binding process for a new HSK-bound wallet
    /// SECURITY: Validates all inputs before storing sensitive data
    public func completeBinding(
        hskId: String,
        derivedKeyHandle: Data,
        address: String,
        credentialId: Data?
    ) async throws -> HSKBoundWallet {
        
        // SECURITY: Input validation
        try validateBindingInputs(hskId: hskId, derivedKeyHandle: derivedKeyHandle, address: address)
        
        // Check if address is already bound
        if bindings.contains(where: { $0.address == address }) {
            throw HSKError.bindingFailed("Address is already bound to a hardware key")
        }
        
        // Store the derived key in secure enclave
        try await secureEnclaveInterface.storeHSKDerivedKey(
            keyHandle: derivedKeyHandle,
            identifier: address
        )
        
        // Create the binding record
        let binding = HSKBoundWallet(
            hskId: hskId,
            derivedKeyHandle: derivedKeyHandle,
            address: address,
            credentialId: credentialId
        )
        
        // Add to local cache
        bindings.append(binding)
        
        // Persist
        try saveBindings()
        
        KryptoLogger.shared.log(
            level: .info,
            category: .stateTransition,
            message: "HSK wallet binding completed"
            // SECURITY: Removed address and hskId from logs to prevent sensitive data leakage
        )
        
        return binding
    }
    
    /// Bind an HSK to an existing wallet
    /// SECURITY: Validates all inputs before storing sensitive data
    public func bindToExistingWallet(
        walletId: String,
        hskId: String,
        derivedKeyHandle: Data,
        credentialId: Data?
    ) async throws -> HSKBoundWallet {
        
        // SECURITY: Input validation
        try validateBindingInputs(hskId: hskId, derivedKeyHandle: derivedKeyHandle, address: walletId)
        
        // Check if wallet is already bound
        if bindings.contains(where: { $0.address == walletId }) {
            throw HSKError.bindingFailed("Wallet is already bound to a hardware key")
        }
        
        // Store the derived key
        try await secureEnclaveInterface.storeHSKDerivedKey(
            keyHandle: derivedKeyHandle,
            identifier: walletId
        )
        
        // Create binding
        let binding = HSKBoundWallet(
            hskId: hskId,
            derivedKeyHandle: derivedKeyHandle,
            address: walletId,
            credentialId: credentialId
        )
        
        bindings.append(binding)
        try saveBindings()
        
        KryptoLogger.shared.log(
            level: .info,
            category: .stateTransition,
            message: "HSK bound to existing wallet"
            // SECURITY: Removed walletId and hskId from logs to prevent sensitive data leakage
        )
        
        return binding
    }
    
    // MARK: - Input Validation
    
    /// SECURITY: Validates all binding inputs to prevent injection and malformed data
    private func validateBindingInputs(hskId: String, derivedKeyHandle: Data, address: String) throws {
        // Validate hskId
        guard !hskId.isEmpty, hskId.count >= 8, hskId.count <= 256 else {
            throw HSKError.bindingFailed("Invalid HSK ID format")
        }
        
        // Validate derivedKeyHandle is exactly 32 bytes (256 bits)
        guard derivedKeyHandle.count == 32 else {
            throw HSKError.bindingFailed("Invalid key handle length: expected 32 bytes")
        }
        
        // Validate key handle is not all zeros (weak key check)
        guard derivedKeyHandle.contains(where: { $0 != 0 }) else {
            throw HSKError.bindingFailed("Invalid key handle: all zeros detected")
        }
        
        // Validate Ethereum address format (0x + 40 hex chars)
        guard address.hasPrefix("0x"), address.count == 42 else {
            throw HSKError.bindingFailed("Invalid address format: expected 0x + 40 hex characters")
        }
        
        // Validate address contains only valid hex characters
        let hexPart = String(address.dropFirst(2))
        let validHex = CharacterSet(charactersIn: "0123456789abcdefABCDEF")
        guard hexPart.unicodeScalars.allSatisfy({ validHex.contains($0) }) else {
            throw HSKError.bindingFailed("Invalid address: contains non-hex characters")
        }
    }
    
    /// Get binding for a specific wallet address
    public func getBinding(for walletAddress: String) async -> HSKBoundWallet? {
        bindings.first { $0.address == walletAddress }
    }
    
    /// Get binding by HSK ID
    public func getBinding(byHskId hskId: String) async -> HSKBoundWallet? {
        bindings.first { $0.hskId == hskId }
    }
    
    /// Get all HSK bindings
    public func getAllBindings() async -> [HSKBoundWallet] {
        bindings
    }
    
    /// Remove binding for a wallet
    /// SECURITY: This operation also removes the key from Secure Enclave
    public func removeBinding(for walletAddress: String) async throws {
        guard let index = bindings.firstIndex(where: { $0.address == walletAddress }) else {
            throw HSKError.keyNotFound
        }
        
        // SECURITY: Remove key from Secure Enclave first
        try await secureEnclaveInterface.deleteHSKDerivedKey(identifier: walletAddress)
        
        bindings.remove(at: index)
        try saveBindings()
        
        KryptoLogger.shared.log(
            level: .info,
            category: .stateTransition,
            message: "HSK binding removed"
            // SECURITY: Removed address from logs to prevent sensitive data leakage
        )
    }
    
    /// Check if a wallet is bound to an HSK
    public func isWalletBound(_ address: String) async -> Bool {
        bindings.contains { $0.address == address }
    }
    
    /// Update last used timestamp for a binding
    public func updateLastUsed(for address: String) async throws {
        guard let index = bindings.firstIndex(where: { $0.address == address }) else {
            throw HSKError.keyNotFound
        }
        
        let existing = bindings[index]
        let updated = HSKBoundWallet(
            id: existing.id,
            hskId: existing.hskId,
            derivedKeyHandle: existing.derivedKeyHandle,
            address: existing.address,
            createdAt: existing.createdAt,
            lastUsedAt: Date(),
            credentialId: existing.credentialId
        )
        
        bindings[index] = updated
        try saveBindings()
    }
    
    // MARK: - Private Methods
    
    private func saveBindings() throws {
        try persistence.save(bindings, to: PersistenceService.hskBindingsFile)
    }
}

// MARK: - Mock Wallet Binding Manager for Testing

public actor MockWalletBindingManager: WalletBindingManagerProtocol {
    
    public var bindings: [HSKBoundWallet] = []
    public var shouldFail = false
    public var failureError = HSKError.bindingFailed("Mock failure")
    
    public init() {}
    
    public func completeBinding(
        hskId: String,
        derivedKeyHandle: Data,
        address: String,
        credentialId: Data?
    ) async throws -> HSKBoundWallet {
        if shouldFail {
            throw failureError
        }
        
        let binding = HSKBoundWallet(
            hskId: hskId,
            derivedKeyHandle: derivedKeyHandle,
            address: address,
            credentialId: credentialId
        )
        bindings.append(binding)
        return binding
    }
    
    public func bindToExistingWallet(
        walletId: String,
        hskId: String,
        derivedKeyHandle: Data,
        credentialId: Data?
    ) async throws -> HSKBoundWallet {
        if shouldFail {
            throw failureError
        }
        
        let binding = HSKBoundWallet(
            hskId: hskId,
            derivedKeyHandle: derivedKeyHandle,
            address: walletId,
            credentialId: credentialId
        )
        bindings.append(binding)
        return binding
    }
    
    public func getBinding(for walletAddress: String) async -> HSKBoundWallet? {
        bindings.first { $0.address == walletAddress }
    }
    
    public func getBinding(byHskId hskId: String) async -> HSKBoundWallet? {
        bindings.first { $0.hskId == hskId }
    }
    
    public func getAllBindings() async -> [HSKBoundWallet] {
        bindings
    }
    
    public func removeBinding(for walletAddress: String) async throws {
        bindings.removeAll { $0.address == walletAddress }
    }
    
    public func isWalletBound(_ address: String) async -> Bool {
        bindings.contains { $0.address == address }
    }
    
    public func updateLastUsed(for address: String) async throws {
        // No-op for mock
    }
    
    // Test helper methods
    public func setShouldFail(_ value: Bool) {
        shouldFail = value
    }
    
    public func getBindingsCount() -> Int {
        bindings.count
    }
}

