import XCTest
import BigInt
@testable import KryptoClaw

final class SimulationOverflowTests: XCTestCase {

    // Mock classes for testing
    class MockRPCRouter: RPCRouter {
        override func sendRequest(method: String, params: [Any], chain: AssetChain) async throws -> RPCResponse {
            if method == "eth_estimateGas" {
                // Return a standard gas estimate
                let json = ["result": "0x5208"] // 21000
                let data = try! JSONSerialization.data(withJSONObject: json)
                return RPCResponse(data: data, response: URLResponse())
            }
            if method == "eth_call" {
                return RPCResponse(data: Data(), response: URLResponse())
            }
            throw URLError(.badURL)
        }
    }

    func testCalculateBalanceChanges_Overflow() async throws {
        // Arrange
        let router = MockRPCRouter(rpcURL: URL(string: "http://localhost")!)
        let service = TransactionSimulationService(rpcRouter: router)

        // A value larger than UInt64.max
        // UInt64.max is 18,446,744,073,709,551,615
        // 20 ETH = 20,000,000,000,000,000,000
        let largeValue = "20000000000000000000"

        let request = SimulationRequest(
            from: "0xSender",
            to: "0xReceiver",
            value: largeValue,
            chain: .ethereum
        )

        // Act
        let result = await service.simulate(request: request)

        // Assert
        guard case .success(let receipt) = result else {
            XCTFail("Simulation failed: \(result.errorMessage ?? "Unknown error")")
            return
        }

        // Currently, because of the bug, balanceChanges might be empty or incorrect
        // We expect it to be present and correct
        let senderChange = receipt.balanceChanges["0xSender"]
        let receiverChange = receipt.balanceChanges["0xReceiver"]

        XCTAssertNotNil(senderChange, "Sender balance change should not be nil")
        XCTAssertNotNil(receiverChange, "Receiver balance change should not be nil")

        // The sender change should be roughly -20 ETH (plus gas)
        // If it failed/overflowed to 0 or skipped, this will fail
        // Using string comparison because BigInt might not be directly equatable to String easily in assertion without parsing
        // But we just check if it's there and looks like a large negative number

        if let senderChange = senderChange {
             XCTAssertTrue(senderChange.starts(with: "-"), "Sender change should be negative")
             // Check if the magnitude is correct (longer than typical small numbers)
             XCTAssertTrue(senderChange.count > 18, "Sender change should reflect the large value")
        }
    }
}
