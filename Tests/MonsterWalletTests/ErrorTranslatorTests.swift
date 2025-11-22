import XCTest
@testable import MonsterWallet

final class ErrorTranslatorTests: XCTestCase {
    
    func testBlockchainErrorTranslation() {
        let rpcError = BlockchainError.rpcError("Execution reverted: Out of gas")
        let message = ErrorTranslator.userFriendlyMessage(for: rpcError)
        
        XCTAssertEqual(message, "Transaction failed. The network rejected the request.")
        XCTAssertFalse(message.contains("Execution reverted")) // Ensure raw message is masked
    }
    
    func testNetworkErrorTranslation() {
        let netError = BlockchainError.networkError(NSError(domain: "NSURLErrorDomain", code: -1009, userInfo: nil))
        let message = ErrorTranslator.userFriendlyMessage(for: netError)
        
        XCTAssertEqual(message, "Unable to connect. Please check your internet connection.")
    }
    
    func testGenericErrorTranslation() {
        let genericError = NSError(domain: "Test", code: 1, userInfo: nil)
        let message = ErrorTranslator.userFriendlyMessage(for: genericError)
        
        XCTAssertEqual(message, "An unexpected error occurred. Please try again.")
    }
}
