import Foundation
import LocalAuthentication
import Security

// MARK: - Secure Enclave Interface Protocol

public protocol SecureEnclaveInterfaceProtocol: Sendable {
    func armForHSK() async throws
    func storeHSKDerivedKey(keyHandle: Data, identifier: String) async throws
    func retrieveHSKDerivedKey(identifier: String) async throws -> Data
    func deleteHSKDerivedKey(identifier: String) async throws
    func isArmed() async -> Bool
}

// MARK: - Secure Enclave Interface

/// Wrapper around SecureEnclaveKeyStore for HSK operations
/// SECURITY: This actor ensures thread-safe access to the Secure Enclave
/// and validates authentication state before each sensitive operation.
@available(iOS 11.3, macOS 10.13.4, *)
public actor SecureEnclaveInterface: SecureEnclaveInterfaceProtocol {
    
    // MARK: - Properties
    
    private let keyStore: KeyStoreProtocol
    private let hskKeyPrefix = "hsk_derived_"
    private var armed = false
    private var armingContext: LAContext?
    /// SECURITY: Track when arming occurred to detect stale contexts
    private var armingTimestamp: Date?
    /// SECURITY: Maximum age of an armed context before re-authentication is required (10 seconds)
    private let maxArmingAge: TimeInterval = 10.0
    
    // MARK: - Initialization
    
    public init(keyStore: KeyStoreProtocol? = nil) {
        if let keyStore = keyStore {
            self.keyStore = keyStore
        } else {
            self.keyStore = SecureEnclaveKeyStore()
        }
    }
    
    // MARK: - Private Helpers
    
    /// SECURITY: Verify that the arming is still valid and hasn't expired
    private func verifyArmingValid() -> Bool {
        guard armed, armingContext != nil else { return false }
        
        // Check if arming has expired
        if let timestamp = armingTimestamp {
            let age = Date().timeIntervalSince(timestamp)
            if age > maxArmingAge {
                // SECURITY: Arming has expired, disarm
                KryptoLogger.shared.log(
                    level: .warning,
                    category: .security,
                    message: "HSK arming expired after \(Int(age)) seconds, re-authentication required"
                )
                armed = false
                armingContext = nil
                armingTimestamp = nil
                return false
            }
        }
        
        return true
    }
    
    // MARK: - Public Methods
    
    /// Prepare the Secure Enclave for incoming HSK-derived key material
    /// This pre-authenticates the user to reduce friction during key storage
    public func armForHSK() async throws {
        let context = LAContext()
        context.localizedReason = "Prepare secure storage for hardware key"
        
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            // Fall back to passcode if biometrics unavailable
            guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
                throw HSKError.enclaveNotAvailable
            }
            // Actually evaluate passcode authentication before arming
            let passcodeSuccess = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Bool, Error>) in
                context.evaluatePolicy(
                    .deviceOwnerAuthentication,
                    localizedReason: "Authorize hardware key wallet creation"
                ) { success, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: success)
                    }
                }
            }
            guard passcodeSuccess else {
                throw HSKError.enclaveNotAvailable
            }
            armingContext = context
            armed = true
            armingTimestamp = Date()
            return
        }
        
        // Pre-authenticate with biometrics
        let success = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Bool, Error>) in
            context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Authorize hardware key wallet creation"
            ) { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: success)
                }
            }
        }
        
        if success {
            armingContext = context
            armed = true
            armingTimestamp = Date()
            
            KryptoLogger.shared.log(
                level: .info,
                category: .security,
                message: "Secure Enclave armed for HSK operations"
            )
        } else {
            throw HSKError.enclaveNotAvailable
        }
    }
    
    /// Store an HSK-derived key in the Secure Enclave
    /// SECURITY: Verifies arming is still valid before storing sensitive data
    public func storeHSKDerivedKey(keyHandle: Data, identifier: String) async throws {
        guard verifyArmingValid() else {
            throw HSKError.enclaveNotAvailable
        }
        guard !identifier.isEmpty else {
            throw HSKError.bindingFailed("Identifier cannot be empty")
        }
        // SECURITY: Validate key handle size
        guard keyHandle.count == 32 else {
            throw HSKError.bindingFailed("Invalid key handle size: expected 32 bytes")
        }
        let storageId = hskKeyPrefix + identifier
        
        do {
            let success = try keyStore.storePrivateKey(key: keyHandle, id: storageId)
            
            if success {
                KryptoLogger.shared.log(
                    level: .info,
                    category: .security,
                    message: "HSK-derived key stored in Secure Enclave"
                )
            } else {
                throw HSKError.bindingFailed("Failed to store key in Secure Enclave")
            }
        } catch {
            KryptoLogger.shared.log(
                level: .error,
                category: .security,
                message: "Failed to store HSK-derived key",
                metadata: ["error": error.localizedDescription]
            )
            throw HSKError.bindingFailed(error.localizedDescription)
        }
    }
    
    /// Retrieve an HSK-derived key from the Secure Enclave
    /// SECURITY: Verifies arming is still valid before retrieving sensitive data
    public func retrieveHSKDerivedKey(identifier: String) async throws -> Data {
        guard verifyArmingValid() else {
            throw HSKError.enclaveNotAvailable
        }
        guard !identifier.isEmpty else {
            throw HSKError.keyNotFound
        }
        let storageId = hskKeyPrefix + identifier
        
        do {
            let keyData = try keyStore.getPrivateKey(id: storageId)
            
            KryptoLogger.shared.log(
                level: .info,
                category: .security,
                message: "HSK-derived key retrieved from Secure Enclave"
            )
            
            return keyData
        } catch KeyStoreError.itemNotFound {
            throw HSKError.keyNotFound
        } catch {
            throw HSKError.derivationFailed(error.localizedDescription)
        }
    }
    
    /// Delete an HSK-derived key from the Secure Enclave
    public func deleteHSKDerivedKey(identifier: String) async throws {
        guard !identifier.isEmpty else {
            return // No-op for empty identifier
        }
        let storageId = hskKeyPrefix + identifier
        
        do {
            try keyStore.deleteKey(id: storageId)
            
            KryptoLogger.shared.log(
                level: .info,
                category: .security,
                message: "HSK-derived key deleted from Secure Enclave"
            )
        } catch {
            // Ignore if key doesn't exist
            if case KeyStoreError.itemNotFound = error {
                return
            }
            throw HSKError.bindingFailed("Failed to delete key: \(error.localizedDescription)")
        }
    }
    
    /// Check if the interface is armed for HSK operations
    public func isArmed() async -> Bool {
        verifyArmingValid()
    }
    
    /// Disarm the interface
    /// SECURITY: Clears all authentication state
    public func disarm() {
        armed = false
        armingContext = nil
        armingTimestamp = nil
    }
}

// MARK: - Mock Secure Enclave Interface for Testing

public actor MockSecureEnclaveInterface: SecureEnclaveInterfaceProtocol {
    
    public var storedKeys: [String: Data] = [:]
    public var isArmedState = false
    public var shouldFail = false
    public var failureError = HSKError.enclaveNotAvailable
    
    public init() {}
    
    public func armForHSK() async throws {
        if shouldFail {
            throw failureError
        }
        isArmedState = true
    }
    
    public func storeHSKDerivedKey(keyHandle: Data, identifier: String) async throws {
        if shouldFail {
            throw failureError
        }
        storedKeys[identifier] = keyHandle
    }
    
    public func retrieveHSKDerivedKey(identifier: String) async throws -> Data {
        if shouldFail {
            throw failureError
        }
        guard let key = storedKeys[identifier] else {
            throw HSKError.keyNotFound
        }
        return key
    }
    
    public func deleteHSKDerivedKey(identifier: String) async throws {
        if shouldFail {
            throw failureError
        }
        storedKeys.removeValue(forKey: identifier)
    }
    
    public func isArmed() async -> Bool {
        isArmedState
    }
    
    // Test helper methods
    public func setShouldFail(_ value: Bool) {
        shouldFail = value
    }
    
    public func getStoredKeysCount() -> Int {
        storedKeys.count
    }
}

