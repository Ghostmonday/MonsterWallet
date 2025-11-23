import Foundation
import BigInt

public class BasicGasRouter: RoutingProtocol {
    private let provider: BlockchainProviderProtocol
    
    public init(provider: BlockchainProviderProtocol) {
        self.provider = provider
    }
    
    public func estimateGas(to: String, value: String, data: Data, chain: Chain) async throws -> GasEstimate {
        // Refactored to use provider-exposed method as per audit
        return try await provider.estimateGas(to: to, value: value, data: data, chain: chain)
    }
}
