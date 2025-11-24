import Foundation
import LocalAuthentication
import Security

/// 🔒 COMPLIANCE: Vault / Key Management
/// This module implements the "The Vault" (Phase 2) requirement.
/// It uses "Envelope Encryption" where the Master Key never leaves the Secure Enclave.
///
/// // A) SKELETON INSTRUCTIONS
/// - This class acts as the GATEKEEPER for the Private Key Mnemonic.
/// - It must NEVER return the mnemonic unless `biometryCurrentSet` is satisfied.
///
/// // B) IMPLEMENTATION INSTRUCTIONS
/// - Ensure `kSecAttrAccessControl` uses `.biometryCurrentSet` to invalidate keys if FaceID is reset.
/// - The "Master Key" (SE) wraps the "Payload Key" (Mnemonic).
/// - <<<<<<!!!!!JULES!!!!!!>>>>>>>>: Ensure `memset` or equivalent zeroing happens to the `Data` object in RAM after use. Swift `Data` is copy-on-write, so standard `reset` is hard. Consider using `SecureBytes` wrapper in Phase 3.
///
/// // REF: COLLABORATION GUIDE
/// - Status: 🚧 Phase 2 Scaffolding Complete.
/// - Next Steps: Implement unit tests with `MockSecureEnclave`. Implement `SecureBytes` for memory safety.
public enum KeyStoreError: Error {
    case itemNotFound
    case invalidData
    case accessControlSetupFailed
    case encryptionFailed
    case decryptionFailed
    case keyGenerationFailed
    case unhandledError(OSStatus)
}

@available(iOS 11.3, macOS 10.13.4, *)
public class SecureEnclaveKeyStore: KeyStoreProtocol {
    private let keychain: KeychainHelperProtocol
    private let seHelper: SecureEnclaveHelperProtocol
    private let masterKeyTag = "com.kryptoclaw.vault.masterKey"
    
    public init(keychain: KeychainHelperProtocol = SystemKeychain(),
                seHelper: SecureEnclaveHelperProtocol = SystemSecureEnclave()) {
        self.keychain = keychain
        self.seHelper = seHelper
    }
    
    // MARK: - Public Interface

    /// Unwraps the private key (mnemonic) using the Secure Enclave Master Key.
    /// Trigger: FaceID/TouchID prompt.
    public func getPrivateKey(id: String) throws -> Data {
        // 1. Fetch the Encrypted Blob (Wrapped Key) from Keychain (RAM access only)
        // Note: This blob is NOT protected by Biometrics directly, but it is useless without the SE Key.
        // This allows the app to load the blob into memory before prompting the user.
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: id,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var item: CFTypeRef?
        let status = keychain.copyMatching(query, result: &item)

        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeyStoreError.itemNotFound
            }
            throw KeyStoreError.unhandledError(status)
        }
        
        guard let encryptedBlob = item as? Data else {
            throw KeyStoreError.invalidData
        }
        
        // 2. Fetch the Master Key (Private) from Secure Enclave
        // Trigger: This call will prompt FaceID/TouchID because the Key was created with .biometryCurrentSet
        let masterKey = try getOrGenerateMasterKey()

        // 3. Decrypt the Blob
        // Algo: ECIES (Elliptic Curve Integrated Encryption Scheme)
        var error: Unmanaged<CFError>?
        guard let plaintext = seHelper.createDecryptedData(masterKey,
                                                        .eciesEncryptionCofactorVariableIVX963SHA256AESGCM,
                                                        encryptedBlob as CFData,
                                                        &error) as Data? else {
            throw KeyStoreError.decryptionFailed
        }

        return plaintext
    }
    
    /// Wraps the private key (mnemonic) using the Secure Enclave Master Key.
    /// The resulting blob is stored in Keychain.
    public func storePrivateKey(key: Data, id: String) throws -> Bool {
        // 1. Get Public Key of Master Key
        // Note: Getting Public Key does NOT require Biometrics.
        let masterPrivateKey = try getOrGenerateMasterKey()
        guard let masterPublicKey = seHelper.copyPublicKey(masterPrivateKey) else {
            throw KeyStoreError.keyGenerationFailed
        }

        // 2. Encrypt the data (Wrap)
        var error: Unmanaged<CFError>?
        guard let encryptedBlob = seHelper.createEncryptedData(masterPublicKey,
                                                            .eciesEncryptionCofactorVariableIVX963SHA256AESGCM,
                                                            key as CFData,
                                                            &error) as Data? else {
            throw KeyStoreError.encryptionFailed
        }
        
        // 3. Store the Encrypted Blob in Keychain
        // We use GenericPassword class. No Biometric Access Control needed here because the data is already encrypted by SE.
        // This allows backup/restore of the blob (e.g. iCloud Keychain) without exposing secrets.
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: id,
            kSecValueData as String: encryptedBlob
        ]

        let status = keychain.add(query)

        if status == errSecDuplicateItem {
            let updateQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: id,
            ]

            _ = keychain.delete(updateQuery)
            let retryStatus = keychain.add(query)
            return retryStatus == errSecSuccess
        }

        return status == errSecSuccess
    }

    public func isProtected() -> Bool {
        true
    }

    public func deleteKey(id: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: id,
        ]

        let status = keychain.delete(query)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeyStoreError.unhandledError(status)
        }
    }

    public func deleteAll() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
        ]

        let status = keychain.delete(query)

        // Also delete the Master Key?
        // Usually we keep the Master Key unless specifically wiping the device identity.
        // But for completeness of "deleteAll", we should probably consider it.
        // For this implementation, we only delete the stored blobs.

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeyStoreError.unhandledError(status)
        }
    }

    // MARK: - Internal Helper: Master Key Management

    /// Retrieves or generates the Secure Enclave Key Pair.
    private func getOrGenerateMasterKey() throws -> SecKey {
        // 1. Try to fetch existing key
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: masterKeyTag,
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecReturnRef as String: true
        ]

        var item: CFTypeRef?
        let status = seHelper.copyMatching(query, result: &item)

        if status == errSecSuccess, let key = item {
            return (key as! SecKey)
        }

        // 2. Generate new key if not found
        // This key is strictly bound to the Secure Enclave and Biometrics.
        var error: Unmanaged<CFError>?
        // Note: We keep SecAccessControlCreateWithFlags here because it's a struct creation,
        // hard to mock and usually safe. If it fails in tests, we can abstract it too.
        guard let accessControl = SecAccessControlCreateWithFlags(
            kCFAllocatorDefault,
            kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
            [.privateKeyUsage, .biometryCurrentSet], // Critical: Invalidates if FaceID is reset
            &error
        ) else {
            throw KeyStoreError.accessControlSetupFailed
        }

        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits as String: 256,
            kSecAttrTokenID as String: kSecAttrTokenIDSecureEnclave,
            kSecPrivateKeyAttrs as String: [
                kSecAttrIsPermanent as String: true,
                kSecAttrApplicationTag as String: masterKeyTag,
                kSecAttrAccessControl as String: accessControl
            ]
        ]

        guard let key = seHelper.createRandomKey(attributes, &error) else {
            throw KeyStoreError.keyGenerationFailed
        }

        return key
    }
}
