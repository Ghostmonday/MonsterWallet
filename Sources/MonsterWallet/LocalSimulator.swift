import Foundation

public class LocalSimulator: TransactionSimulatorProtocol {
    private let provider: BlockchainProviderProtocol
    
    public init(provider: BlockchainProviderProtocol) {
        self.provider = provider
    }
    
    public func simulate(tx: Transaction) async throws -> SimulationResult {
        // 1. Fetch Balance
        // Map chainId to Chain enum (Simplified for V1.0)
        let chain: Chain = .ethereum 
        
        let balance = try await provider.fetchBalance(address: tx.from, chain: chain)
        
        // 2. Calculate Cost
        // Note: In production, use BigInt. Here we use UInt64 which is unsafe for real ETH values but ok for tests.
        
        // Parse Balance (Hex)
        let balanceClean = balance.amount.hasPrefix("0x") ? String(balance.amount.dropFirst(2)) : balance.amount
        guard let balanceVal = UInt64(balanceClean, radix: 16) else {
             return SimulationResult(success: false, estimatedGasUsed: 0, balanceChanges: [:], error: "Invalid balance format")
        }
        
        // Parse Value (Hex or Decimal? Transaction struct usually carries what the UI/Signer needs. Let's assume Decimal string for simplicity or Hex)
        // If it comes from UI, it might be decimal. If from RPC, Hex.
        // Let's assume Hex for consistency with ETH.
        let valueClean = tx.value.hasPrefix("0x") ? String(tx.value.dropFirst(2)) : tx.value
        let valueVal = UInt64(valueClean, radix: 16) ?? 0
        
        // Parse Gas Price (Decimal string in our Router)
        let gasPriceVal = UInt64(tx.maxFeePerGas) ?? 0
        let gasCost = tx.gasLimit * gasPriceVal
        
        let totalCost = valueVal + gasCost
        
        if balanceVal < totalCost {
            return SimulationResult(
                success: false, 
                estimatedGasUsed: 0, 
                balanceChanges: [:], 
                error: "Insufficient funds"
            )
        }
        
        return SimulationResult(
            success: true,
            estimatedGasUsed: 21000,
            balanceChanges: [
                tx.from: "-\(totalCost)",
                tx.to: "+\(valueVal)"
            ],
            error: nil
        )
    }
}
