import XCTest
@testable import KryptoClaw



class WSMMockSecurityPolicy: SecurityPolicyProtocol {
    func analyze(result: SimulationResult, tx: Transaction) -> [RiskAlert] {
        return [RiskAlert(level: .low, description: "Test Alert")]
    }
    func onBreach(alert: RiskAlert) {}
}

@available(iOS 13.0, macOS 10.15, *)
final class WalletStateManagerTests: XCTestCase {
    
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
            securityPolicy: WSMMockSecurityPolicy(),
            signer: mockSigner,
            nftProvider: MockNFTProvider()
        )
    }
    
    func testLoadAccount() async {
        await wsm.loadAccount(id: "0xAddr")
        
        let state = await wsm.state
        if case .loaded(let balances) = state {
            XCTAssertEqual(balances[.ethereum]?.currency, "ETH")
        } else {
            XCTFail("State should be loaded")
        }
    }
    
    func testPrepareTransaction() async {
        await wsm.loadAccount(id: "0xAddr")
        await wsm.prepareTransaction(to: "0xTo", value: "0x100")
        
        let result = await wsm.simulationResult
        XCTAssertNotNil(result)
        XCTAssertTrue(result!.success)
        
        let alerts = await wsm.riskAlerts
        XCTAssertEqual(alerts.count, 1)
        XCTAssertEqual(alerts.first?.description, "Test Alert")
    }
    
    func testConfirmTransaction() async {
        await wsm.loadAccount(id: "0xAddr")
        
        // Must prepare first
        await wsm.prepareTransaction(to: "0xTo", value: "0x100")
        
        await wsm.confirmTransaction(to: "0xTo", value: "0x100")
        
        let hash = await wsm.lastTxHash
        XCTAssertEqual(hash, "0xHash") // MockBlockchainProvider returns "0xHash"
    }
}
