import BigInt
import Foundation

public class BasicGasRouter: RoutingProtocol {
    private let provider: BlockchainProviderProtocol

    public init(provider: BlockchainProviderProtocol) {
        self.provider = provider
    }

    public func estimateGas(to: String, value: String, data: Data, chain: Chain) async throws -> GasEstimate {
        try await provider.estimateGas(to: to, value: value, data: data, chain: chain)
    }
}
