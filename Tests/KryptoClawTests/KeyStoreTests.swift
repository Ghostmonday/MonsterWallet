import XCTest
@testable import KryptoClaw

class MockKeychain: KeychainHelperProtocol {
    var store: [String: Data] = [:]
    var shouldFailAuth = false
    var shouldFailAdd = false
    
    func add(_ attributes: [String: Any]) -> OSStatus {
        if shouldFailAdd { return errSecInternalError }
        
        guard let account = attributes[kSecAttrAccount as String] as? String,
              let data = attributes[kSecValueData as String] as? Data else {
            return errSecParam
        }
        
        if store[account] != nil {
            return errSecDuplicateItem
        }
        
        store[account] = data
        return errSecSuccess
    }
    
    func copyMatching(_ query: [String: Any], result: UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus {
        if shouldFailAuth { return errSecAuthFailed }
        
        guard let account = query[kSecAttrAccount as String] as? String else {
            return errSecParam
        }
        
        if let data = store[account] {
            result?.pointee = data as CFData
            return errSecSuccess
        }
        
        return errSecItemNotFound
    }
    
    func delete(_ query: [String: Any]) -> OSStatus {
        guard let account = query[kSecAttrAccount as String] as? String else {
            return errSecParam
        }
        store.removeValue(forKey: account)
        return errSecSuccess
    }
}

@available(iOS 11.3, macOS 10.13.4, *)
final class KeyStoreTests: XCTestCase {
    
    var keyStore: SecureEnclaveKeyStore!
    var mockKeychain: MockKeychain!
    var mockSE: MockSecureEnclave!
    
    override func setUp() {
        super.setUp()
        mockKeychain = MockKeychain()
        mockSE = MockSecureEnclave()
        keyStore = SecureEnclaveKeyStore(keychain: mockKeychain, seHelper: mockSE)
    }
    
    func testStoreAndRetrieve() throws {
        let keyID = "testKey"
        let keyData = "secretData".data(using: .utf8)!
        
        let stored = try keyStore.storePrivateKey(key: keyData, id: keyID)
        XCTAssertTrue(stored)
        
        let retrieved = try keyStore.getPrivateKey(id: keyID)
        XCTAssertEqual(retrieved.unsafeDataCopy(), keyData)
    }
    
    func testItemNotFound() {
        XCTAssertThrowsError(try keyStore.getPrivateKey(id: "missing")) { error in
            guard let keyError = error as? KeyStoreError else {
                XCTFail("Wrong error type")
                return
            }
            if case .itemNotFound = keyError {
                // Success
            } else {
                XCTFail("Expected itemNotFound")
            }
        }
    }
    
    func testAuthFailure() {
        mockKeychain.shouldFailAuth = true
        // Pre-populate
        mockKeychain.store["authKey"] = Data()
        
        XCTAssertThrowsError(try keyStore.getPrivateKey(id: "authKey")) { error in
            guard let keyError = error as? KeyStoreError else {
                XCTFail("Wrong error type")
                return
            }
            if case .unhandledError(let status) = keyError {
                XCTAssertEqual(status, errSecAuthFailed)
            } else {
                XCTFail("Expected unhandledError(errSecAuthFailed)")
            }
        }
    }
    
    func testDuplicateItemUpdate() throws {
        let keyID = "dupKey"
        let data1 = "data1".data(using: .utf8)!
        let data2 = "data2".data(using: .utf8)!
        
        // First store
        _ = try keyStore.storePrivateKey(key: data1, id: keyID)
        
        // Second store (should update)
        let stored = try keyStore.storePrivateKey(key: data2, id: keyID)
        XCTAssertTrue(stored)
        
        let retrieved = try keyStore.getPrivateKey(id: keyID)
        XCTAssertEqual(retrieved.unsafeDataCopy(), data2)
    }
    
    func testIsProtected() {
        XCTAssertTrue(keyStore.isProtected())
    }
}
