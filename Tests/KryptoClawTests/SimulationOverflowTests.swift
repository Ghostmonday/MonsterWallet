import XCTest
@testable import KryptoClaw
import BigInt

// Mock URLProtocol to intercept network requests
class SimulationMockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) -> (HTTPURLResponse, Data?))?

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        guard let handler = SimulationMockURLProtocol.requestHandler else {
            XCTFail("Received unexpected request with no handler set")
            return
        }

        let (response, data) = handler(request)
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        if let data = data {
            client?.urlProtocol(self, didLoad: data)
        }
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

final class SimulationOverflowTests: XCTestCase {

    var simulationService: TransactionSimulationService!
    var session: URLSession!

    override func setUp() {
        super.setUp()

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [SimulationMockURLProtocol.self]
        session = URLSession(configuration: config)

        let rpcRouter = RPCRouter(session: session)
        simulationService = TransactionSimulationService(rpcRouter: rpcRouter, session: session)
    }

    override func tearDown() {
        SimulationMockURLProtocol.requestHandler = nil
        super.tearDown()
    }

    func testSimulateLargeValueOverflow() async throws {
        // Arrange
        let fromAddress = "0xSender"
        let toAddress = "0xRecipient"

        // Value: 20 ETH = 20 * 10^18 Wei = 20,000,000,000,000,000,000
        // UInt64.max is approx 18.44 * 10^18.
        // So 20 ETH overflows UInt64.
        let largeValue = "20000000000000000000"

        let request = SimulationRequest(
            from: fromAddress,
            to: toAddress,
            value: largeValue,
            chain: .ethereum
        )

        // Mock RPC responses
        SimulationMockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!

            guard let httpBody = request.httpBody,
                  let json = try? JSONSerialization.jsonObject(with: httpBody) as? [String: Any],
                  let method = json["method"] as? String else {
                return (response, nil)
            }

            if method == "eth_call" {
                // Return success for simulation
                let result = ["jsonrpc": "2.0", "result": "0x", "id": 1] as [String : Any]
                let data = try! JSONSerialization.data(withJSONObject: result)
                return (response, data)
            } else if method == "eth_estimateGas" {
                // Return 21000 gas
                let result = ["jsonrpc": "2.0", "result": "0x5208", "id": 1] as [String : Any]
                let data = try! JSONSerialization.data(withJSONObject: result)
                return (response, data)
            }

            return (response, nil)
        }

        // Act
        let result = await simulationService.simulate(request: request)

        // Assert
        guard case .success(let receipt) = result else {
            XCTFail("Simulation failed")
            return
        }

        // Verify balance changes
        let fromChange = receipt.balanceChanges[fromAddress]

        // Expectation: "-20000630000000000000" (Value + Gas)
        // Gas = 21000 * 30 Gwei = 630,000,000,000,000 Wei
        // Total = 20,000,000,000,000,000,000 + 630,000,000,000,000 = 20,000,630,000,000,000,000

        // If the bug exists (UInt64 overflow), the value used in calculation will be 0 (due to overflow/coalescing).
        // So the deducted amount will be JUST the gas: "-630000000000000"

        let expectedGasCost = BigInt(21000) * BigInt(30_000_000_000)
        let expectedTotalDeduction = BigInt(largeValue)! + expectedGasCost
        let expectedString = "-\(expectedTotalDeduction)"

        XCTAssertEqual(fromChange, expectedString, "Balance change calculation failed due to overflow")
    }
}
