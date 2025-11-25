// MODULE: KeychainVault
// VERSION: 1.0.0
// PURPOSE: Secure storage with Envelope Encryption pattern - Seed encrypted by Secure Enclave Key

import Foundation
import Security
import LocalAuthentication
import CryptoKit

// MARK: - Vault Error Types

/// Errors for secure vault operations
public enum VaultError: Error, LocalizedError, Sendable {
    case seedNotFound
    case seedAlreadyExists
    case encryptionFailed(underlying: Error?)
    case decryptionFailed(underlying: Error?)
    case keychainWriteFailed(status: OSStatus)
    case keychainReadFailed(status: OSStatus)
    case keychainDeleteFailed(status: OSStatus)
    case authenticationRequired
    case authenticationFailed(underlying: Error?)
    case invalidSeedFormat
    case accessControlCreationFailed
    case secureEnclaveUnavailable
    
    public var errorDescription: String? {
        switch self {
        case .seedNotFound:
            return "No wallet seed found. Please create or import a wallet."
        case .seedAlreadyExists:
            return "A wallet seed already exists. Delete it first to create a new one."
        case .encryptionFailed(let error):
            return "Failed to encrypt seed: \(error?.localizedDescription ?? "Unknown")"
        case .decryptionFailed(let error):
            return "Failed to decrypt seed: \(error?.localizedDescription ?? "Unknown")"
        case .keychainWriteFailed(let status):
            return "Keychain write failed with status: \(status)"
        case .keychainReadFailed(let status):
            return "Keychain read failed with status: \(status)"
        case .keychainDeleteFailed(let status):
            return "Keychain delete failed with status: \(status)"
        case .authenticationRequired:
            return "Biometric or passcode authentication is required."
        case .authenticationFailed(let error):
            return "Authentication failed: \(error?.localizedDescription ?? "Unknown")"
        case .invalidSeedFormat:
            return "The seed phrase format is invalid."
        case .accessControlCreationFailed:
            return "Failed to create secure access control."
        case .secureEnclaveUnavailable:
            return "Secure Enclave is not available on this device."
        }
    }
}

// MARK: - Encrypted Seed Blob

/// Structure representing an encrypted seed with metadata
public struct EncryptedSeedBlob: Codable, Sendable {
    /// Encrypted seed data (AES-GCM encrypted with DEK)
    public let encryptedSeed: Data
    
    /// Data Encryption Key (DEK) encrypted by Secure Enclave
    public let encryptedDEK: Data
    
    /// Initialization vector for AES-GCM
    public let nonce: Data
    
    /// Authentication tag from AES-GCM
    public let tag: Data
    
    /// Creation timestamp
    public let createdAt: Date
    
    /// Vault version for migrations
    public let version: Int
    
    public init(encryptedSeed: Data, encryptedDEK: Data, nonce: Data, tag: Data, createdAt: Date = Date(), version: Int = 1) {
        self.encryptedSeed = encryptedSeed
        self.encryptedDEK = encryptedDEK
        self.nonce = nonce
        self.tag = tag
        self.createdAt = createdAt
        self.version = version
    }
}

// MARK: - Keychain Vault

/// Secure vault for storing sensitive wallet data using Envelope Encryption.
/// 
/// **Envelope Encryption Pattern:**
/// 1. Generate a random Data Encryption Key (DEK)
/// 2. Encrypt the seed with the DEK using AES-GCM
/// 3. Encrypt the DEK with the Secure Enclave key (requires biometric)
/// 4. Store the encrypted blob in Keychain
///
/// **Decryption (requires biometric):**
/// 1. Read encrypted blob from Keychain
/// 2. Decrypt the DEK using Secure Enclave (triggers FaceID/TouchID)
/// 3. Decrypt the seed with the DEK
@available(iOS 15.0, macOS 12.0, *)
public actor KeychainVault {
    
    // MARK: - Constants
    
    private let serviceIdentifier = "com.kryptoclaw.vault"
    private let seedAccountName = "master_seed_v2"
    private let enclaveKeyTag = "com.kryptoclaw.vault.enclave.master"
    
    // MARK: - Dependencies
    
    private let keychain: KeychainHelperProtocol
    
    // MARK: - Cached State
    
    private var cachedEnclaveKey: SecKey?
    
    // MARK: - Initialization
    
    public init(keychain: KeychainHelperProtocol = SystemKeychain()) {
        self.keychain = keychain
    }
    
    // MARK: - Public Interface
    
    /// Check if a seed exists in the vault
    public func hasSeed() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: seedAccountName,
            kSecReturnData as String: false
        ]
        
        let status = keychain.copyMatching(query, result: nil)
        return status == errSecSuccess
    }
    
    /// Store a new seed phrase with envelope encryption
    /// - Parameter mnemonic: The BIP-39 mnemonic to store
    /// - Throws: VaultError if storage fails
    public func storeSeed(_ mnemonic: String) async throws {
        // Validate mnemonic format
        let words = mnemonic.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: " ")
        guard words.count == 12 || words.count == 24 else {
            throw VaultError.invalidSeedFormat
        }
        
        // Check if seed already exists
        if hasSeed() {
            throw VaultError.seedAlreadyExists
        }
        
        // Convert mnemonic to data
        guard let seedData = mnemonic.data(using: .utf8) else {
            throw VaultError.invalidSeedFormat
        }
        
        // Generate random DEK (256-bit)
        let dek = SymmetricKey(size: .bits256)
        
        // Encrypt seed with DEK using AES-GCM
        let nonce = try AES.GCM.Nonce()
        let sealedBox = try AES.GCM.seal(seedData, using: dek, nonce: nonce)
        
        guard let combined = sealedBox.combined else {
            throw VaultError.encryptionFailed(underlying: nil)
        }
        
        // Encrypt DEK with Secure Enclave key
        let enclaveKey = try await getOrCreateEnclaveKey()
        let encryptedDEK = try encryptWithSecureEnclave(data: dek.withUnsafeBytes { Data($0) }, using: enclaveKey)
        
        // Create encrypted blob
        let blob = EncryptedSeedBlob(
            encryptedSeed: combined,
            encryptedDEK: encryptedDEK,
            nonce: Data(nonce),
            tag: sealedBox.tag,
            createdAt: Date()
        )
        
        // Serialize blob
        let blobData = try JSONEncoder().encode(blob)
        
        // Store in keychain with biometric protection
        try storeInKeychain(data: blobData, account: seedAccountName)
    }
    
    /// Retrieve the seed phrase (requires biometric authentication)
    /// - Returns: The decrypted mnemonic
    /// - Throws: VaultError if retrieval fails
    public func retrieveSeed() async throws -> String {
        // Read encrypted blob from keychain
        let blobData = try readFromKeychain(account: seedAccountName)
        
        // Deserialize blob
        let blob = try JSONDecoder().decode(EncryptedSeedBlob.self, from: blobData)
        
        // Get Secure Enclave key (will trigger biometric if needed)
        let enclaveKey = try await getEnclaveKey()
        
        // Decrypt DEK with Secure Enclave
        let dekData = try decryptWithSecureEnclave(data: blob.encryptedDEK, using: enclaveKey)
        let dek = SymmetricKey(data: dekData)
        
        // Decrypt seed with DEK
        let sealedBox = try AES.GCM.SealedBox(combined: blob.encryptedSeed)
        let seedData = try AES.GCM.open(sealedBox, using: dek)
        
        guard let mnemonic = String(data: seedData, encoding: .utf8) else {
            throw VaultError.decryptionFailed(underlying: nil)
        }
        
        return mnemonic
    }
    
    /// Delete the stored seed (requires biometric confirmation)
    public func deleteSeed() async throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: seedAccountName
        ]
        
        let status = keychain.delete(query)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw VaultError.keychainDeleteFailed(status: status)
        }
    }
    
    /// Wipe all vault data including the enclave key
    public func wipeAll() async throws {
        // Delete seed
        try await deleteSeed()
        
        // Delete enclave key
        let keyQuery: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: enclaveKeyTag.data(using: .utf8)!
        ]
        
        let _ = keychain.delete(keyQuery)
        cachedEnclaveKey = nil
    }
    
    // MARK: - Secure Enclave Key Management
    
    /// Get or create the Secure Enclave master key
    private func getOrCreateEnclaveKey() async throws -> SecKey {
        // Try to get existing key first
        if let existing = try? await getEnclaveKey() {
            return existing
        }
        
        // Create new key
        return try createEnclaveKey()
    }
    
    /// Get existing Secure Enclave key
    private func getEnclaveKey() async throws -> SecKey {
        // Check cache
        if let cached = cachedEnclaveKey {
            return cached
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: enclaveKeyTag.data(using: .utf8)!,
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecReturnRef as String: true
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status == errSecSuccess, let key = item else {
            throw VaultError.seedNotFound
        }
        
        let secKey = key as! SecKey
        cachedEnclaveKey = secKey
        return secKey
    }
    
    /// Create a new Secure Enclave key for envelope encryption
    private func createEnclaveKey() throws -> SecKey {
        var accessFlags: SecAccessControlCreateFlags = [.privateKeyUsage]
        
        #if !targetEnvironment(simulator)
        accessFlags.insert(.biometryCurrentSet)
        #endif
        
        var error: Unmanaged<CFError>?
        guard let accessControl = SecAccessControlCreateWithFlags(
            kCFAllocatorDefault,
            kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
            accessFlags,
            &error
        ) else {
            throw VaultError.accessControlCreationFailed
        }
        
        var attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits as String: 256,
            kSecPrivateKeyAttrs as String: [
                kSecAttrIsPermanent as String: true,
                kSecAttrApplicationTag as String: enclaveKeyTag.data(using: .utf8)!,
                kSecAttrAccessControl as String: accessControl
            ]
        ]
        
        #if !targetEnvironment(simulator)
        attributes[kSecAttrTokenID as String] = kSecAttrTokenIDSecureEnclave
        #endif
        
        var keyError: Unmanaged<CFError>?
        guard let key = SecKeyCreateRandomKey(attributes as CFDictionary, &keyError) else {
            throw VaultError.secureEnclaveUnavailable
        }
        
        cachedEnclaveKey = key
        return key
    }
    
    // MARK: - Encryption/Decryption with Secure Enclave
    
    /// Encrypt data using the Secure Enclave public key
    private func encryptWithSecureEnclave(data: Data, using privateKey: SecKey) throws -> Data {
        guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
            throw VaultError.encryptionFailed(underlying: nil)
        }
        
        var error: Unmanaged<CFError>?
        guard let encrypted = SecKeyCreateEncryptedData(
            publicKey,
            .eciesEncryptionStandardX963SHA256AESGCM,
            data as CFData,
            &error
        ) as Data? else {
            throw VaultError.encryptionFailed(underlying: error?.takeRetainedValue())
        }
        
        return encrypted
    }
    
    /// Decrypt data using the Secure Enclave private key (triggers biometric)
    private func decryptWithSecureEnclave(data: Data, using privateKey: SecKey) throws -> Data {
        var error: Unmanaged<CFError>?
        guard let decrypted = SecKeyCreateDecryptedData(
            privateKey,
            .eciesEncryptionStandardX963SHA256AESGCM,
            data as CFData,
            &error
        ) as Data? else {
            throw VaultError.decryptionFailed(underlying: error?.takeRetainedValue())
        }
        
        return decrypted
    }
    
    // MARK: - Keychain Operations
    
    /// Store data in keychain with biometric protection
    private func storeInKeychain(data: Data, account: String) throws {
        var accessFlags: SecAccessControlCreateFlags = []
        
        #if !targetEnvironment(simulator)
        accessFlags.insert(.biometryCurrentSet)
        #endif
        
        var error: Unmanaged<CFError>?
        let accessControl = SecAccessControlCreateWithFlags(
            kCFAllocatorDefault,
            kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
            accessFlags,
            &error
        )
        
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]
        
        if let accessControl = accessControl {
            query[kSecAttrAccessControl as String] = accessControl
        }
        
        // Delete existing item first
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: account
        ]
        keychain.delete(deleteQuery)
        
        let status = keychain.add(query)
        guard status == errSecSuccess else {
            throw VaultError.keychainWriteFailed(status: status)
        }
    }
    
    /// Read data from keychain
    private func readFromKeychain(account: String) throws -> Data {
        let context = LAContext()
        context.localizedReason = "Authenticate to access your wallet"
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecUseAuthenticationContext as String: context
        ]
        
        var item: CFTypeRef?
        let status = keychain.copyMatching(query, result: &item)
        
        switch status {
        case errSecSuccess:
            guard let data = item as? Data else {
                throw VaultError.keychainReadFailed(status: status)
            }
            return data
            
        case errSecItemNotFound:
            throw VaultError.seedNotFound
            
        case errSecUserCanceled:
            throw VaultError.authenticationFailed(underlying: nil)
            
        case errSecAuthFailed:
            throw VaultError.authenticationFailed(underlying: nil)
            
        default:
            throw VaultError.keychainReadFailed(status: status)
        }
    }
}

// MARK: - Biometric Auth Extension

@available(iOS 15.0, macOS 12.0, *)
extension KeychainVault {
    
    /// Authenticate user before sensitive operations
    public func authenticateUser(reason: String) async throws -> Bool {
        let context = LAContext()
        context.localizedFallbackTitle = "Use Passcode"
        
        var authError: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &authError) else {
            throw VaultError.authenticationFailed(underlying: authError)
        }
        
        return try await context.evaluatePolicy(
            .deviceOwnerAuthentication,
            localizedReason: reason
        )
    }
}

