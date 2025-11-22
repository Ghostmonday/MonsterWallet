import XCTest
@testable import MonsterWallet

class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            XCTFail("Received unexpected request with no handler set")
            return
        }
        
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
    
    override func stopLoading() {}
}

final class BlockchainProviderTests: XCTestCase {
    
    var provider: ModularHTTPProvider!
    
    override func setUp() {
        super.setUp()
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)
        provider = ModularHTTPProvider(session: session)
    }
    
    func testFetchBalanceSuccess() async throws {
        let expectedBalance = "0x123456"
        let jsonString = """
        {
            "jsonrpc": "2.0",
            "result": "\(expectedBalance)",
            "id": 1
        }
        """
        let data = jsonString.data(using: .utf8)!
        
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, data)
        }
        
        let balance = try await provider.fetchBalance(address: "0xAddr", chain: .ethereum)
        XCTAssertEqual(balance.amount, expectedBalance)
        XCTAssertEqual(balance.currency, "ETH")
    }
    
    func testFetchBalanceRPCError() async {
        let jsonString = """
        {
            "jsonrpc": "2.0",
            "error": {"code": -32000, "message": "Bad Request"},
            "id": 1
        }
        """
        let data = jsonString.data(using: .utf8)!
        
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, data)
        }
        
        do {
            _ = try await provider.fetchBalance(address: "0xAddr", chain: .ethereum)
            XCTFail("Should have thrown")
        } catch let error as BlockchainError {
            if case .rpcError(let msg) = error {
                XCTAssertEqual(msg, "Bad Request")
            } else {
                XCTFail("Wrong error type")
            }
        } catch {
            XCTFail("Wrong error type")
        }
    }
    
    func testUnsupportedChain() async {
        do {
            _ = try await provider.fetchBalance(address: "0xAddr", chain: .bitcoin)
            XCTFail("Should have thrown")
        } catch let error as BlockchainError {
            if case .unsupportedChain = error {
                // Success
            } else {
                XCTFail("Wrong error type")
            }
        } catch {
            XCTFail("Wrong error type")
        }
    }
    
    func testBroadcastSuccess() async throws {
        let expectedHash = "0xhash123"
        let jsonString = """
        {
            "jsonrpc": "2.0",
            "result": "\(expectedHash)",
            "id": 1
        }
        """
        let data = jsonString.data(using: .utf8)!
        
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, data)
        }
        
        let hash = try await provider.broadcast(signedTx: Data([0x01, 0x02]))
        XCTAssertEqual(hash, expectedHash)
    }
}
