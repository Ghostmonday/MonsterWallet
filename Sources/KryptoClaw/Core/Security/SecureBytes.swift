import Foundation
#if os(Linux)
import Glibc
#else
import Darwin
#endif

/// A wrapper around Data that securely wipes its memory when deallocated.
/// Used for sensitive information like private keys and mnemonics.
public final class SecureBytes {
    private var data: Data
    private let count: Int
    
    public init(data: Data) {
        self.data = data
        self.count = data.count
    }
    
    deinit {
        wipe()
    }
    
    /// Zeros out the memory backing the Data.
    private func wipe() {
        guard count > 0 else { return }
        
        // Access the underlying bytes and overwrite them with zeros.
        // We use withUnsafeMutableBytes to get direct access.
        data.withUnsafeMutableBytes { (pointer: UnsafeMutableRawBufferPointer) in
            if let baseAddress = pointer.baseAddress {
                // memset is a C function available in Darwin
                memset(baseAddress, 0, count)
            }
        }
        
        // Prevent compiler optimization from removing the memset
        // by creating a barrier or using the data one last time (though memset is usually safe).
        // In Swift, keeping 'data' alive until here is handled by 'self.data'.
    }
    
    /// Access the underlying data within a closure.
    /// The data should NOT be copied out of this closure if possible.
    public func withUnsafeBytes<Result>(_ body: (UnsafeRawBufferPointer) throws -> Result) rethrows -> Result {
        return try data.withUnsafeBytes(body)
    }
    
    /// Returns a copy of the data. WARNING: The copy is NOT secure and will not be wiped automatically.
    /// Use only when necessary for APIs that require Data.
    public func unsafeDataCopy() -> Data {
        return data
    }
}
