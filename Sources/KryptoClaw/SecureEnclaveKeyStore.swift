import Foundation
import Security
import LocalAuthentication

public enum KeyStoreError: Error {
    case itemNotFound
    case invalidData
    case accessControlSetupFailed
    case unhandledError(OSStatus)
}

@available(iOS 11.3, macOS 10.13.4, *)
public class SecureEnclaveKeyStore: KeyStoreProtocol {
    
    private let keychain: KeychainHelperProtocol
    
    public init(keychain: KeychainHelperProtocol = SystemKeychain()) {
        self.keychain = keychain
    }
    
    public func getPrivateKey(id: String) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: id,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = keychain.copyMatching(query, result: &item)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeyStoreError.itemNotFound
            }
            throw KeyStoreError.unhandledError(status)
        }
        
        guard let data = item as? Data else {
            throw KeyStoreError.invalidData
        }
        
        return data
    }
    
    public func storePrivateKey(key: Data, id: String) throws -> Bool {
        var error: Unmanaged<CFError>?
        guard let accessControl = SecAccessControlCreateWithFlags(
            kCFAllocatorDefault,
            kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
            .biometryCurrentSet,
            &error
        ) else {
            throw KeyStoreError.accessControlSetupFailed
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: id,
            kSecValueData as String: key,
            kSecAttrAccessControl as String: accessControl
        ]
        
        let status = keychain.add(query)
        
        if status == errSecDuplicateItem {
            let updateQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: id
            ]
            
            _ = keychain.delete(updateQuery)
            let retryStatus = keychain.add(query)
            return retryStatus == errSecSuccess
        }
        
        return status == errSecSuccess
    }
    
    public func isProtected() -> Bool {
        return true
    }
    
    public func deleteKey(id: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: id
        ]
        
        let status = keychain.delete(query)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeyStoreError.unhandledError(status)
        }
    }
    
    public func deleteAll() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword
        ]
        
        let status = keychain.delete(query)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeyStoreError.unhandledError(status)
        }
    }
}
