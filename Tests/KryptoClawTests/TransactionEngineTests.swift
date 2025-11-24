import XCTest
@testable import KryptoClaw

class TEMockBlockchainProvider: BlockchainProviderProtocol {
    var balanceToReturn: Balance = Balance(amount: "0x100000000000000", currency: "ETH", decimals: 18) // Fits in UInt64
    
    func fetchBalance(address: String, chain: Chain) async throws -> Balance {
        return balanceToReturn
    }
    
    func fetchHistory(address: String, chain: Chain) async throws -> TransactionHistory {
        return TransactionHistory(transactions: [])
    }
    
    func broadcast(signedTx: Data, chain: Chain) async throws -> String {
        return "0xHash"
    }
    
    func fetchPrice(chain: Chain) async throws -> Decimal {
        return Decimal(2000)
    }
    
    func estimateGas(to: String, value: String, data: Data, chain: Chain) async throws -> GasEstimate {
        return GasEstimate(gasLimit: 21000, maxFeePerGas: "20000000000", maxPriorityFeePerGas: "1000000000")
    }
}


final class TransactionEngineTests: XCTestCase {
    
    var simulator: LocalSimulator!
    var router: BasicGasRouter!
    var analyzer: BasicHeuristicAnalyzer!
    var mockProvider: TEMockBlockchainProvider!
    
    override func setUp() {
        super.setUp()
        mockProvider = TEMockBlockchainProvider()
        simulator = LocalSimulator(provider: mockProvider)
        router = BasicGasRouter(provider: mockProvider)
        analyzer = BasicHeuristicAnalyzer()
    }
    
    func testSimulationSuccess() async throws {
        let tx = Transaction(
            from: "0xSender",
            to: "0xReceiver",
            value: "0x100", // Small value
            data: Data(),
            nonce: 0,
            gasLimit: 21000,
            maxFeePerGas: "1000000000",
            maxPriorityFeePerGas: "1000000000",
            chainId: 1
        )
        
        let result = try await simulator.simulate(tx: tx)
        XCTAssertTrue(result.success)
        XCTAssertNil(result.error)
    }
    
    func testSimulationInsufficientFunds() async throws {
        mockProvider.balanceToReturn = Balance(amount: "0x0", currency: "ETH", decimals: 18)
        
        let tx = Transaction(
            from: "0xSender",
            to: "0xReceiver",
            value: "0x100",
            data: Data(),
            nonce: 0,
            gasLimit: 21000,
            maxFeePerGas: "1000000000",
            maxPriorityFeePerGas: "1000000000",
            chainId: 1
        )
        
        let result = try await simulator.simulate(tx: tx)
        XCTAssertFalse(result.success)
        XCTAssertEqual(result.error, "Insufficient funds")
    }
    
    func testRouterEstimate() async throws {
        let estimate = try await router.estimateGas(to: "0xTo", value: "0x0", data: Data(), chain: .ethereum)
        XCTAssertEqual(estimate.gasLimit, 21000)
    }
    
    func testAnalyzerHighValue() {
        let tx = Transaction(
            from: "0xSender",
            to: "0xReceiver",
            value: "0x12345678901234567890", // Long string > 19 chars
            data: Data(),
            nonce: 0,
            gasLimit: 21000,
            maxFeePerGas: "1000",
            maxPriorityFeePerGas: "1000",
            chainId: 1
        )
        
        let result = SimulationResult(success: true, estimatedGasUsed: 21000, balanceChanges: [:], error: nil)
        
        let alerts = analyzer.analyze(result: result, tx: tx)
        XCTAssertTrue(alerts.contains { $0.description == "High value transaction" })
    }
}
