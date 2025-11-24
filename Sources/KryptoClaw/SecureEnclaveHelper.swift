import Foundation
import Security

/// Protocol wrapper for Secure Enclave and Cryptographic operations.
/// Allows mocking of hardware-bound features for unit testing.
public protocol SecureEnclaveHelperProtocol {
    func createRandomKey(_ attributes: [String: Any], _ error: UnsafeMutablePointer<Unmanaged<CFError>?>?) -> SecKey?
    func copyPublicKey(_ key: SecKey) -> SecKey?
    func createEncryptedData(_ key: SecKey, _ algorithm: SecKeyAlgorithm, _ plaintext: CFData, _ error: UnsafeMutablePointer<Unmanaged<CFError>?>?) -> CFData?
    func createDecryptedData(_ key: SecKey, _ algorithm: SecKeyAlgorithm, _ ciphertext: CFData, _ error: UnsafeMutablePointer<Unmanaged<CFError>?>?) -> CFData?
    func copyMatching(_ query: [String: Any], result: UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus
}

public class SystemSecureEnclave: SecureEnclaveHelperProtocol {
    public init() {}

    public func createRandomKey(_ attributes: [String: Any], _ error: UnsafeMutablePointer<Unmanaged<CFError>?>?) -> SecKey? {
        return SecKeyCreateRandomKey(attributes as CFDictionary, error)
    }

    public func copyPublicKey(_ key: SecKey) -> SecKey? {
        return SecKeyCopyPublicKey(key)
    }

    public func createEncryptedData(_ key: SecKey, _ algorithm: SecKeyAlgorithm, _ plaintext: CFData, _ error: UnsafeMutablePointer<Unmanaged<CFError>?>?) -> CFData? {
        return SecKeyCreateEncryptedData(key, algorithm, plaintext, error)
    }

    public func createDecryptedData(_ key: SecKey, _ algorithm: SecKeyAlgorithm, _ ciphertext: CFData, _ error: UnsafeMutablePointer<Unmanaged<CFError>?>?) -> CFData? {
        return SecKeyCreateDecryptedData(key, algorithm, ciphertext, error)
    }

    public func copyMatching(_ query: [String: Any], result: UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus {
        return SecItemCopyMatching(query as CFDictionary, result)
    }
}
