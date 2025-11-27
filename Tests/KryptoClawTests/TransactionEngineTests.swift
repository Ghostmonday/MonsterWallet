import XCTest
@testable import KryptoClaw

class TEMockBlockchainProvider: BlockchainProviderProtocol {
    var balanceToReturn: Balance = Balance(amount: "1000.00", currency: "ETH", decimals: 18) // Decimal ETH format
    
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
        // Use valid test addresses
        let tx = Transaction(
            from: "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
            to: "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
            value: "1000000000000000", // 0.001 ETH in wei (decimal)
            data: Data(),
            nonce: 0,
            gasLimit: 21000,
            maxFeePerGas: "1000000000",
            maxPriorityFeePerGas: "1000000000",
            chainId: 31337 // Local testnet
        )
        
        let result = try await simulator.simulate(tx: tx)
        XCTAssertTrue(result.success, "Simulation should succeed, error: \(result.error ?? "none")")
        XCTAssertNil(result.error)
    }
    
    func testSimulationInsufficientFunds() async throws {
        mockProvider.balanceToReturn = Balance(amount: "0.00", currency: "ETH", decimals: 18) // Zero balance in decimal format
        
        let tx = Transaction(
            from: "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
            to: "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
            value: "1000000000000000000", // 1 ETH in wei
            data: Data(),
            nonce: 0,
            gasLimit: 21000,
            maxFeePerGas: "1000000000",
            maxPriorityFeePerGas: "1000000000",
            chainId: 31337
        )
        
        let result = try await simulator.simulate(tx: tx)
        XCTAssertFalse(result.success)
        XCTAssertTrue(result.error?.contains("Insufficient") ?? false, "Error should mention insufficient funds, got: \(result.error ?? "nil")")
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
