import XCTest
@testable import MonsterWallet

@available(iOS 13.0, macOS 10.15, *)
final class SignerTests: XCTestCase {
    
    var signer: SimpleP2PSigner!
    var mockKeyStore: MockKeyStore!
    
    override func setUp() {
        super.setUp()
        mockKeyStore = MockKeyStore()
        signer = SimpleP2PSigner(keyStore: mockKeyStore, keyId: "testKey")
    }
    
    func testSignTransaction() async throws {
        let tx = Transaction(
            from: "0xSender",
            to: "0xReceiver",
            value: "0x100",
            data: Data(),
            nonce: 0,
            gasLimit: 21000,
            maxFeePerGas: "100",
            maxPriorityFeePerGas: "10",
            chainId: 1
        )
        
        let signedData = try await signer.signTransaction(tx: tx)
        
        XCTAssertFalse(signedData.raw.isEmpty)
        XCTAssertFalse(signedData.signature.isEmpty)
        XCTAssertTrue(signedData.txHash.hasPrefix("0x"))
    }
    
    func testSignMessage() async throws {
        let message = "Hello Monster"
        let signature = try await signer.signMessage(message: message)
        XCTAssertFalse(signature.isEmpty)
    }
}
