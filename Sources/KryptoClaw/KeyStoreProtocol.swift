import Foundation

public protocol KeyStoreProtocol {
    /// Retrieves the private key (or handle) for the given ID.
    /// - Parameter id: The unique identifier for the key.
    /// - Returns: The key data (or handle).
    /// - Throws: An error if the key cannot be retrieved or authentication fails.
    func getPrivateKey(id: String) throws -> Data
    
    /// Stores a private key.
    /// - Parameters:
    ///   - key: The private key data to store.
    ///   - id: The unique identifier for the key.
    /// - Returns: True if storage was successful.
    /// - Throws: An error if storage fails.
    func storePrivateKey(key: Data, id: String) throws -> Bool
    
    /// Checks if the store is protected (e.g. requires User Authentication).
    /// - Returns: True if protected.
    func isProtected() -> Bool
    
    /// Deletes a specific key.
    func deleteKey(id: String) throws
    
    /// Deletes all keys managed by this store.
    func deleteAll() throws
}
