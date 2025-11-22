import XCTest
@testable import MonsterWallet

class MockKeyStore: KeyStoreProtocol {
    func getPrivateKey(id: String) throws -> Data { return Data() }
    func storePrivateKey(key: Data, id: String) throws -> Bool { return true }
    func isProtected() -> Bool { return true }
}

class MockSimulator: TransactionSimulatorProtocol {
    var resultToReturn: SimulationResult = SimulationResult(success: true, estimatedGasUsed: 21000, balanceChanges: [:], error: nil)
    func simulate(tx: Transaction) async throws -> SimulationResult {
        return resultToReturn
    }
}

class MockRouter: RoutingProtocol {
    func estimateGas(to: String, value: String, data: Data, chain: Chain) async throws -> GasEstimate {
        return GasEstimate(gasLimit: 21000, maxFeePerGas: "100", maxPriorityFeePerGas: "10")
    }
}

class MockSecurityPolicy: SecurityPolicyProtocol {
    func analyze(result: SimulationResult, tx: Transaction) -> [RiskAlert] {
        return [RiskAlert(level: .low, description: "Test Alert")]
    }
    func onBreach(alert: RiskAlert) {}
}

class MockSigner: SignerProtocol {
    func signTransaction(tx: Transaction) async throws -> SignedData {
        return SignedData(raw: Data(), signature: Data(), txHash: "0xMockHash")
    }
    func signMessage(message: String) async throws -> Data {
        return Data()
    }
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
            securityPolicy: MockSecurityPolicy(),
            signer: mockSigner
        )
    }
    
    func testLoadAccount() async {
        await wsm.loadAccount(id: "0xAddr")
        
        let state = await wsm.state
        if case .loaded(let balance) = state {
            XCTAssertEqual(balance.currency, "ETH")
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
