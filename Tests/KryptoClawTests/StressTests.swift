import XCTest
@testable import KryptoClaw

final class StressTests: XCTestCase {
    
    var wsm: WalletStateManager!
    var mockProvider: MockBlockchainProvider!
    var mockSigner: MockSigner!
    
    @MainActor
    override func setUp() {
        super.setUp()
        // Note: Mock classes must be available in the test target.
        // Assuming they are defined in a support file or similar.
        mockProvider = MockBlockchainProvider()
        mockSigner = MockSigner()
        wsm = WalletStateManager(
            keyStore: MockKeyStore(),
            blockchainProvider: mockProvider,
            simulator: MockSimulator(),
            router: MockRouter(),
            securityPolicy: MockSecurityPolicy(),
            signer: mockSigner,
            nftProvider: MockNFTProvider()
        )
    }
    
    @MainActor
    func testRapidStateUpdates() async {
        // Simulate rapid-fire balance refreshes (e.g., user spamming refresh)
        // Scaled up to 1000 for "Rigorous" testing
        await wsm.loadAccount(id: "0xAddr")
        
        for _ in 0..<1000 {
            await wsm.refreshBalance()
        }
        
        let state = wsm.state
        if case .loaded = state {
            // Success
        } else {
            XCTFail("State should settle to loaded after stress")
        }
    }
    
    @MainActor
    func testTransactionConcurrency() async {
        // Simulate preparing multiple transactions in rapid succession
        await wsm.loadAccount(id: "0xAddr")
        
        // 200 concurrent tasks
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<200 {
                group.addTask {
                    await self.wsm.prepareTransaction(to: "0xTo\(i)", value: "0x\(i)")
                }
            }
        }
        
        // We just want to ensure no crash and final state is valid
        XCTAssertNotNil(wsm.state)
    }
    
    @MainActor
    func testMultiChainHammering() async {
        // Hammer the multi-chain provider logic
        await wsm.loadAccount(id: "0xAddr")

        for _ in 0..<500 {
            await wsm.refreshBalance() // triggers 3 concurrent fetches internally
        }

        // Check if we survived
        if case .loaded(let balances) = wsm.state {
            XCTAssertEqual(balances.count, 3) // ETH, BTC, SOL
        } else {
            XCTFail("Failed to load all chains under stress")
        }
    }
}
