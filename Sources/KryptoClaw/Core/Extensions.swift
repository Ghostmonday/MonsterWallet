import Foundation

public extension Data {
    var hexString: String {
        map { String(format: "%02x", $0) }.joined()
    }
    
    init?(hexString: String) {
        // Handle 0x prefix
        var cleanHex = hexString
        if cleanHex.hasPrefix("0x") || cleanHex.hasPrefix("0X") {
            cleanHex = String(cleanHex.dropFirst(2))
        }
        
        // Handle odd-length strings by padding with leading zero
        if cleanHex.count % 2 != 0 {
            cleanHex = "0" + cleanHex
        }
        
        guard !cleanHex.isEmpty else {
            return nil
        }
        
        let len = cleanHex.count / 2
        var data = Data(capacity: len)
        var ptr = cleanHex.startIndex
        
        for _ in 0..<len {
            guard ptr < cleanHex.endIndex else { return nil }
            let end = cleanHex.index(ptr, offsetBy: 2, limitedBy: cleanHex.endIndex) ?? cleanHex.endIndex
            let bytes = cleanHex[ptr..<end]
            guard let num = UInt8(bytes, radix: 16) else {
                return nil
            }
            data.append(num)
            ptr = end
        }
        self = data
    }
}

public extension Array {
    /// Split array into chunks of specified size
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
