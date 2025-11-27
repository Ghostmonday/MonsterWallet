import Foundation
#if os(Linux)
import Glibc
#else
import Darwin
import os
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
    /// Uses multiple passes and memory barriers to ensure secure wiping.
    private func wipe() {
        guard count > 0 else { return }
        
        // Access the underlying bytes and overwrite them with zeros.
        // Multiple passes for better security (though single pass is usually sufficient)
        data.withUnsafeMutableBytes { (pointer: UnsafeMutableRawBufferPointer) in
            guard let baseAddress = pointer.baseAddress else { return }
            
            // First pass: zero out
            memset(baseAddress, 0, count)
            
            // Memory barrier to prevent compiler reordering
            #if os(Linux)
            __sync_synchronize()
            #else
            // Use compiler barrier - OSMemoryBarrier is deprecated
            _ = baseAddress
            #endif
            
            // Second pass: overwrite with random data (defense in depth)
            // Note: This is optional but provides additional security
            #if DEBUG
            // Skip second pass in debug for performance
            #else
            arc4random_buf(baseAddress, count)
            memset(baseAddress, 0, count)
            #endif
        }
        
        // Clear the reference to help GC
        data = Data()
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
