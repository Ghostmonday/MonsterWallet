import Foundation
@testable import KryptoClaw

class MockBlockchainProvider: BlockchainProviderProtocol {
    func fetchBalance(address: String, chain: Chain) async throws -> Balance {
        return Balance(amount: "1.0", currency: chain.nativeCurrency, decimals: chain.decimals)
    }

    func fetchHistory(address: String, chain: Chain) async throws -> TransactionHistory {
        return TransactionHistory(transactions: [])
    }

    func broadcast(signedTx: Data, chain: Chain) async throws -> String {
        return "0xMockHash"
    }
}

class MockKeyStore: KeyStoreProtocol {
    func storePrivateKey(key: Data, id: String) throws -> Bool { return true }
    func getPrivateKey(id: String) throws -> Data { return Data() }
    func isProtected() -> Bool { return true }
}

class MockSimulator: TransactionSimulatorProtocol {
    func simulate(tx: Transaction) async throws -> SimulationResult {
        return SimulationResult(success: true, estimatedGasUsed: 21000, balanceChanges: [:], error: nil)
    }
}

class MockRouter: RoutingProtocol {
    func estimateGas(to: String, value: String, data: Data, chain: Chain) async throws -> GasEstimate {
        return GasEstimate(gasLimit: 21000, maxFeePerGas: "20000000000", maxPriorityFeePerGas: "1000000000")
    }
}

class MockSecurityPolicy: SecurityPolicyProtocol {
    func analyze(result: SimulationResult, tx: Transaction) -> [RiskAlert] {
        return []
    }
    func onBreach(alert: RiskAlert) {}
}

class MockSigner: SignerProtocol {
    func signTransaction(tx: Transaction) async throws -> SignedData {
        return SignedData(raw: Data(), signature: Data(), txHash: "0xHash")
    }

    func signMessage(message: String) async throws -> Data {
        return Data()
    }
}

class MockNFTProvider: NFTProviderProtocol {
    func fetchNFTs(address: String) async throws -> [NFTMetadata] {
        return []
    }
}
