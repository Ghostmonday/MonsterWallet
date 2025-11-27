import BigInt
import Foundation

public class BasicGasRouter: RoutingProtocol {
    private let provider: BlockchainProviderProtocol
    private let session: URLSession

    public init(provider: BlockchainProviderProtocol, session: URLSession = .shared) {
        self.provider = provider
        self.session = session
    }

    public func estimateGas(to: String, value: String, data: Data, chain: Chain) async throws -> GasEstimate {
        try await provider.estimateGas(to: to, value: value, data: data, chain: chain)
    }
    
    public func getTransactionCount(address: String) async throws -> UInt64 {
        let url = AppConfig.rpcURL
        
        let payload: [String: Any] = [
            "jsonrpc": "2.0",
            "method": "eth_getTransactionCount",
            "params": [address, "pending"],
            "id": 1
        ]
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: payload) else {
            throw BlockchainError.parsingError
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = httpBody
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30.0
        
        let (data, _) = try await session.data(for: request)
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let result = json["result"] as? String else {
            throw BlockchainError.parsingError
        }
        
        // Parse hex result
        let hexString = result.hasPrefix("0x") ? String(result.dropFirst(2)) : result
        guard let nonce = UInt64(hexString, radix: 16) else {
            throw BlockchainError.parsingError
        }
        
        return nonce
    }
}
