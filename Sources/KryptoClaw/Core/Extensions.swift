import Foundation

public extension Data {
    var hexString: String {
        map { String(format: "%02x", $0) }.joined()
    }
    
    init?(hexString: String) {
        let len = hexString.count / 2
        var data = Data(capacity: len)
        var ptr = hexString.startIndex
        for _ in 0..<len {
            let end = hexString.index(ptr, offsetBy: 2)
            let bytes = hexString[ptr..<end]
            if let num = UInt8(bytes, radix: 16) {
                data.append(num)
            } else {
                return nil
            }
            ptr = end
        }
        self = data
    }
}
