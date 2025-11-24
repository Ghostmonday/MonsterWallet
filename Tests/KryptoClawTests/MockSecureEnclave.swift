import Foundation
import Security
@testable import KryptoClaw

class MockSecureEnclave: SecureEnclaveHelperProtocol {

    // We can't easily mock SecKey, so we will treat it as an OpaquePointer or just a dummy object if possible.
    // However, SecKey is a CFType. In Swift, we can cast arbitrary objects to SecKey if we are careful,
    // or we might need to rely on the fact that we can't create a real SecKey without hardware.
    //
    // Alternative: We return a dummy object that we cast to SecKey. This is dangerous but might work for mocking if we don't inspect it.
    // Better: We just return nil or fail if the test expects real keys,
    // BUT we want to test the FLOW.

    // For the purpose of this mock, we will use a dummy string cast to SecKey if possible? No.
    // We can use a real SecKey generated in software for the mock?
    // SecKeyCreateRandomKey works on macOS/iOS simulator without SE if we don't ask for SE.
    // But we are asking for SE.

    // Let's make the mock flexible.

    var shouldFailGeneration = false
    var shouldFailEncryption = false
    var shouldFailDecryption = false

    // Store keys in memory
    var keys: [String: Any] = [:] // Tag -> Key

    // Dummy key object (needs to be a CFTypeRef)
    private let dummyKey: SecKey

    init() {
        // Create a software key to act as our "dummy" handle
        let attributes: [String: Any] = [
             kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
             kSecAttrKeySizeInBits as String: 256
         ]
        var error: Unmanaged<CFError>?
        self.dummyKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error)!
    }

    func createRandomKey(_ attributes: [String: Any], _ error: UnsafeMutablePointer<Unmanaged<CFError>?>?) -> SecKey? {
        if shouldFailGeneration { return nil }

        // Return our dummy key to satisfy the type system
        // We could store it if needed
        return dummyKey
    }

    func copyPublicKey(_ key: SecKey) -> SecKey? {
        // Just return the same key for simplicity in mock (symmetric-ish behavior for testing flow)
        // Or generate another one.
        return dummyKey
    }

    func createEncryptedData(_ key: SecKey, _ algorithm: SecKeyAlgorithm, _ plaintext: CFData, _ error: UnsafeMutablePointer<Unmanaged<CFError>?>?) -> CFData? {
        if shouldFailEncryption { return nil }

        // Mock encryption: just return the plaintext (or base64 of it) so we can verify flow
        // In a real mock we might wrap it to prove "encryption" happened.
        let data = plaintext as Data
        let mockEncrypted = ("ENC:" + data.base64EncodedString()).data(using: .utf8)!
        return mockEncrypted as CFData
    }

    func createDecryptedData(_ key: SecKey, _ algorithm: SecKeyAlgorithm, _ ciphertext: CFData, _ error: UnsafeMutablePointer<Unmanaged<CFError>?>?) -> CFData? {
        if shouldFailDecryption { return nil }

        let data = ciphertext as Data
        guard let string = String(data: data, encoding: .utf8), string.hasPrefix("ENC:") else {
            // Failed to decrypt (bad format)
            return nil
        }

        let base64 = String(string.dropFirst(4))
        let original = Data(base64Encoded: base64)
        return original as CFData?
    }

    func copyMatching(_ query: [String: Any], result: UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus {
        // Mock finding the key
        // Always return success and our dummy key for the Master Key query
        if let tag = query[kSecAttrApplicationTag as String] as? String, tag == "com.kryptoclaw.vault.masterKey" {
             result?.pointee = dummyKey
             return errSecSuccess
        }
        return errSecItemNotFound
    }
}
