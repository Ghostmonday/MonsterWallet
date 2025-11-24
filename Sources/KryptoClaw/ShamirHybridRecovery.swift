import Foundation

public enum RecoveryError: Error {
    case invalidThreshold
    case invalidShares
    case reconstructionFailed
    case encodingError
}

public class ShamirHybridRecovery: RecoveryStrategyProtocol {
    public init() {}

    public func generateShares(seed: String, total: Int, threshold: Int) throws -> [RecoveryShare] {
        // TODO: Implement true Shamir Secret Sharing (SSS) for threshold < total
        // Current implementation only supports N-of-N (threshold == total) using XOR
        guard threshold == total else {
            throw RecoveryError.invalidThreshold
        }

        guard let seedData = seed.data(using: .utf8) else {
            throw RecoveryError.encodingError
        }

        var shares: [RecoveryShare] = []
        var accumulatedXor = Data(count: seedData.count)

        for i in 1 ..< total {
            var randomData = Data(count: seedData.count)
            let result = randomData.withUnsafeMutableBytes {
                SecRandomCopyBytes(kSecRandomDefault, seedData.count, $0.baseAddress!)
            }
            guard result == errSecSuccess else { throw RecoveryError.encodingError }

            accumulatedXor = xor(data1: accumulatedXor, data2: randomData)

            let shareString = randomData.base64EncodedString()
            shares.append(RecoveryShare(id: i, data: shareString, threshold: threshold))
        }

        let lastShareData = xor(data1: seedData, data2: accumulatedXor)
        let lastShareString = lastShareData.base64EncodedString()
        shares.append(RecoveryShare(id: total, data: lastShareString, threshold: threshold))

        return shares
    }

    public func reconstruct(shares: [RecoveryShare]) throws -> String {
        guard !shares.isEmpty else { throw RecoveryError.invalidShares }

        let threshold = shares[0].threshold
        guard shares.count == threshold else {
            throw RecoveryError.invalidShares
        }

        var resultData = Data()

        for (index, share) in shares.enumerated() {
            guard let data = Data(base64Encoded: share.data) else {
                throw RecoveryError.encodingError
            }

            if index == 0 {
                resultData = data
            } else {
                resultData = xor(data1: resultData, data2: data)
            }
        }

        guard let seed = String(data: resultData, encoding: .utf8) else {
            throw RecoveryError.reconstructionFailed
        }

        return seed
    }

    private func xor(data1: Data, data2: Data) -> Data {
        var result = Data(count: max(data1.count, data2.count))
        for i in 0 ..< result.count {
            let b1 = i < data1.count ? data1[i] : 0
            let b2 = i < data2.count ? data2[i] : 0
            result[i] = b1 ^ b2
        }
        return result
    }
}
