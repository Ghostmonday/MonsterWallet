import XCTest
@testable import MonsterWallet

final class RecoveryTests: XCTestCase {
    
    var recovery: ShamirHybridRecovery!
    
    override func setUp() {
        super.setUp()
        recovery = ShamirHybridRecovery()
    }
    
    func testSplitAndReconstruct() throws {
        let seed = "monster wallet secret seed"
        let total = 3
        let threshold = 3
        
        let shares = try recovery.generateShares(seed: seed, total: total, threshold: threshold)
        XCTAssertEqual(shares.count, total)
        
        let reconstructed = try recovery.reconstruct(shares: shares)
        XCTAssertEqual(reconstructed, seed)
    }
    
    func testInvalidThreshold() {
        let seed = "seed"
        XCTAssertThrowsError(try recovery.generateShares(seed: seed, total: 3, threshold: 2)) { error in
            XCTAssertEqual(error as? RecoveryError, .invalidThreshold)
        }
    }
    
    func testMissingShares() throws {
        let seed = "seed"
        let shares = try recovery.generateShares(seed: seed, total: 3, threshold: 3)
        
        let subset = Array(shares.prefix(2))
        XCTAssertThrowsError(try recovery.reconstruct(shares: subset)) { error in
            XCTAssertEqual(error as? RecoveryError, .invalidShares)
        }
    }
    
    func testCorruptedShare() throws {
        let seed = "seed"
        var shares = try recovery.generateShares(seed: seed, total: 2, threshold: 2)
        
        // Corrupt first share
        let badData = Data([0x00, 0x00]).base64EncodedString()
        shares[0] = RecoveryShare(id: shares[0].id, data: badData, threshold: shares[0].threshold)
        
        // Should either fail encoding or produce wrong seed
        // In XOR, it will produce wrong seed.
        let reconstructed = try? recovery.reconstruct(shares: shares)
        XCTAssertNotEqual(reconstructed, seed)
    }
}
