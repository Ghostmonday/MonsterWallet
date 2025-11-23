import Foundation

public class LocalSimulator: TransactionSimulatorProtocol {
    private let provider: BlockchainProviderProtocol
    
    public init(provider: BlockchainProviderProtocol) {
        self.provider = provider
    }
    
    public func simulate(tx: Transaction) async throws -> SimulationResult {
        // <<<<<<!!!!!JULES!!!!!!>>>>>>>>
        // [FUNCTIONALITY/SECURITY]
        // This entire simulator is a heuristic mock.
        // 1. Real Simulation: A production wallet should simulate the transaction against a forked state of the blockchain to see *actual* effects (internal txs, event logs, accurate gas usage).
        // 2. Current Logic: It basically just subtracts numbers locally. It won't catch revert reasons from smart contracts or tax-on-transfer tokens.
        // ACTION: Integrate a real simulation provider or remove the feature if it's not "True Simulation".

        // 0. Strict Security Check (V2)
        if AppConfig.Features.isAddressPoisoningProtectionEnabled {
             // Block infinite approvals (common scam pattern)
             // 0xffffff... is typical for infinite approval
             if tx.data.count > 0 && tx.data.hexString.contains("ffffffffffffffffffffffffffffffff") {
                 return SimulationResult(
                     success: false,
                     estimatedGasUsed: 0,
                     balanceChanges: [:],
                     error: "Security Risk: Infinite Token Approval detected. This is a common wallet drainer technique. Transaction blocked."
                 )
             }
        }

        // 1. Determine Chain
        let chain: Chain
        if tx.chainId == 1 {
            chain = .ethereum
        } else {
            // Simplified mapping for V1 mock: All non-1 IDs map to Bitcoin/Solana mock flow
            // In a real app, we'd check specific IDs.
            chain = .bitcoin // Default fallback for mock simulation
        }

        // 2. Fetch Balance
        let balance = try await provider.fetchBalance(address: tx.from, chain: chain)
        
        // 3. Calculate Cost
        // Note: In production, use BigInt. Here we use UInt64 which is unsafe for real ETH values but ok for tests.
        
        // Parse Balance (Hex or Decimal based on chain)
        var balanceVal: UInt64 = 0
        if chain == .ethereum {
            let balanceClean = balance.amount.hasPrefix("0x") ? String(balance.amount.dropFirst(2)) : balance.amount
            balanceVal = UInt64(balanceClean, radix: 16) ?? 0
        } else {
            // Mock BTC/SOL balance is returned as decimal string in our mock provider
            balanceVal = UInt64(Double(balance.amount) ?? 0)
        }

        if balanceVal == 0 && balance.amount != "0" {
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
