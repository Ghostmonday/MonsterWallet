import Foundation
import BigInt

public class BasicGasRouter: RoutingProtocol {
    private let provider: BlockchainProviderProtocol
    
    public init(provider: BlockchainProviderProtocol) {
        self.provider = provider
    }
    
    public func estimateGas(to: String, value: String, data: Data, chain: Chain) async throws -> GasEstimate {
        // Real Estimation Logic via RPC
        // Note: In a cleaner architecture, the Provider should expose 'estimateGas' and 'getFeeData'.
        // Here we are patching the Router to do it or call provider.
        // Assuming provider is ModularHTTPProvider and we can't easily extend protocol in this patch without touching many files.
        // We will do a direct RPC call here similar to Provider for expedience in this "Audit Fix".
        
        let url = AppConfig.rpcURL
        
        // 1. Estimate Gas Limit
        let estimatePayload: [String: Any] = [
            "jsonrpc": "2.0",
            "method": "eth_estimateGas",
            "params": [[
                "to": to,
                "value": "0x" + (BigUInt(value)?.toString(radix: 16) ?? "0"),
                "data": "0x" + data.toHexString()
            ]],
            "id": 1
        ]
        
        let limit = try await rpcCall(url: url, payload: estimatePayload)
        let gasLimit = UInt64(limit.dropFirst(2), radix: 16) ?? 21000

        // 2. Get Gas Price (EIP-1559)
        // For simplicity, we fallback to eth_gasPrice (legacy) or simple priority fee.
        // Real app should use eth_maxPriorityFeePerGas.
        let pricePayload: [String: Any] = [
            "jsonrpc": "2.0",
            "method": "eth_gasPrice",
            "params": [],
            "id": 2
        ]
        let priceHex = try await rpcCall(url: url, payload: pricePayload)
        let baseFee = BigUInt(priceHex.dropFirst(2), radix: 16) ?? BigUInt(20_000_000_000)

        // Add tip
        let priorityFee = BigUInt(2_000_000_000) // 2 Gwei tip
        let maxFee = baseFee + priorityFee // Simplified for V1
        
        return GasEstimate(
            gasLimit: gasLimit,
            maxFeePerGas: String(maxFee),
            maxPriorityFeePerGas: String(priorityFee)
        )
    }

    private func rpcCall(url: URL, payload: [String: Any]) async throws -> String {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, _) = try await URLSession.shared.data(for: request)
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { throw BlockchainError.parsingError }

        if let err = json["error"] as? [String: Any] { throw BlockchainError.rpcError(err["message"] as? String ?? "RPC Error") }
        return json["result"] as? String ?? "0x0"
    }
}
