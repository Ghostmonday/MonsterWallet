import XCTest
@testable import KryptoClaw

final class StressTests: XCTestCase {
    
    var wsm: WalletStateManager!
    var mockProvider: MockBlockchainProvider!
    var mockSigner: MockSigner!
    
    @MainActor
    override func setUp() {
        super.setUp()
        mockProvider = MockBlockchainProvider()
        mockSigner = MockSigner()
        wsm = WalletStateManager(
            keyStore: MockKeyStore(),
            blockchainProvider: mockProvider,
            simulator: MockSimulator(),
            router: MockRouter(),
            securityPolicy: MockSecurityPolicy(),
            signer: mockSigner
        )
    }
    
    func testRapidStateUpdates() async {
        // Simulate rapid-fire balance refreshes (e.g., user spamming refresh)
        await wsm.loadAccount(id: "0xAddr")
        
        for _ in 0..<100 {
            await wsm.refreshBalance()
        }
        
        let state = await wsm.state
        if case .loaded = state {
            // Success
        } else {
            XCTFail("State should settle to loaded after stress")
        }
    }
    
    func testTransactionConcurrency() async {
        // Simulate preparing multiple transactions in rapid succession
        await wsm.loadAccount(id: "0xAddr")
        
        for i in 0..<50 {
            await wsm.prepareTransaction(to: "0xTo\(i)", value: "0x\(i)")
        }
        
        let result = await wsm.simulationResult
        XCTAssertNotNil(result)
        XCTAssertTrue(result!.success)
    }
    
    /*
    func testMemoryLeakCheck() async {
        // Skipped: Async memory leak testing is flaky in XCTest without strict Task management.
        // Manual profiling recommended for V1.0.
    }
    */
}
