import Foundation
import Security

public protocol KeychainHelperProtocol {
    func add(_ attributes: [String: Any]) -> OSStatus
    func copyMatching(_ query: [String: Any], result: UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus
    func delete(_ query: [String: Any]) -> OSStatus
}

public class SystemKeychain: KeychainHelperProtocol {
    public init() {}
    public func add(_ attributes: [String: Any]) -> OSStatus {
        SecItemAdd(attributes as CFDictionary, nil)
    }

    public func copyMatching(_ query: [String: Any], result: UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus {
        SecItemCopyMatching(query as CFDictionary, result)
    }

    public func delete(_ query: [String: Any]) -> OSStatus {
        SecItemDelete(query as CFDictionary)
    }
}
