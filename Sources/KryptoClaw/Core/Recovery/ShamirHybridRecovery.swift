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
        // Task 11: Shamir Secret Sharing (SSS) Implementation
        // Goal: Upgrade from XOR-based N-of-N splitting to true SSS (k-of-n).
        // Current Status: V1 uses XOR for N-of-N. True SSS requires GF(256) arithmetic.
        
        // Implementation Requirement:
        // For threshold < total (e.g. 3 of 5), we MUST use polynomial interpolation over a finite field.
        // DO NOT implement SSS math from scratch in production due to side-channel risks.
        // Recommended Library: https://github.com/koraykoska/ShamirSecretSharing (or similar audited Swift lib)
        
        if threshold < total {
             // TODO: Integrate SSS Library here.
             // For now, we throw to prevent unsafe usage of the XOR method (which requires all shares).
             // If SSS were implemented:
             // 1. Generate random polynomial P(x) of degree (threshold - 1) where P(0) = secret
             // 2. Generate 'total' points (x, y) where y = P(x)
             // 3. Return shares
             throw RecoveryError.invalidThreshold // XOR only supports N-of-N
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
        
        // XOR Reconstruction Logic (N-of-N)
        // Requires ALL shares (count == threshold == total)
        guard shares.count == threshold else {
            // If this were SSS, we would use Lagrange Interpolation here to recover P(0)
            // using any 'threshold' number of shares.
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
