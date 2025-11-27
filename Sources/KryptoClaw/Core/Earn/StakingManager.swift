// MODULE: StakingManager
// VERSION: 1.0.0
// PURPOSE: Actor-based staking transaction executor with simulation guard

import Foundation
import BigInt

// MARK: - Staking Manager

/// Actor responsible for constructing and validating staking transactions.
///
/// **Responsibilities:**
/// - Construct transaction payloads for Lido, Aave, and other protocols
/// - Build specific calldata (submit, supply, etc.)
/// - Integrate with TransactionSimulationService for safety
/// - Execute staking transactions through WalletCoreManager
///
/// **Safety:**
/// All transactions MUST pass simulation before returning to ViewModel
@available(iOS 15.0, macOS 12.0, *)
public actor StakingManager {
    
    // MARK: - Dependencies
    
    private let simulationService: TransactionSimulationService
    private let rpcRouter: RPCRouter
    private let session: URLSession
    
    // MARK: - Initialization
    
    public init(
        simulationService: TransactionSimulationService,
        rpcRouter: RPCRouter,
        session: URLSession = .shared
    ) {
        self.simulationService = simulationService
        self.rpcRouter = rpcRouter
        self.session = session
    }
    
    // MARK: - Public Interface: Stake
    
    /// Prepare a staking transaction
    /// - Parameter request: The staking request
    /// - Returns: PreparedStakingTransaction ready for signing
    public func prepareStakeTransaction(
        _ request: StakingRequest
    ) async throws -> PreparedStakingTransaction {
        
        // Validate opportunity is active
        guard request.opportunity.isActive else {
            throw StakingError.opportunityInactive
        }
        
        // Validate minimum stake
        if let minimum = request.opportunity.minimumStake,
           let minAmount = Decimal(string: minimum),
           let requestAmount = Decimal(string: request.amount),
           requestAmount < minAmount {
            throw StakingError.belowMinimumStake(minimum: minimum)
        }
        
        // Build protocol-specific transaction
        let transaction: PreparedStakingTransaction
        
        switch request.opportunity.protocol {
        case .lido:
            transaction = try buildLidoStakeTransaction(request)
        case .aave:
            transaction = try buildAaveSupplyTransaction(request)
        case .rocket:
            transaction = try buildRocketPoolStakeTransaction(request)
        case .compound:
            transaction = try buildCompoundSupplyTransaction(request)
        case .eigenlayer:
            transaction = try buildEigenLayerRestakeTransaction(request)
        }
        
        return transaction
    }
    
    /// Simulate a prepared staking transaction
    /// - Parameter transaction: The prepared transaction
    /// - Returns: Simulation result with receipt if successful
    public func simulateStake(
        _ transaction: PreparedStakingTransaction
    ) async -> TxSimulationResult {
        let request = SimulationRequest(
            from: transaction.from,
            to: transaction.to,
            value: transaction.value,
            data: transaction.calldata,
            chain: transaction.chain,
            gasLimit: transaction.gasLimit
        )
        
        return await simulationService.simulate(request: request)
    }
    
    /// Execute a staking transaction with valid simulation receipt
    /// - Parameters:
    ///   - transaction: The prepared transaction
    ///   - receipt: Valid simulation receipt
    ///   - signedTransaction: Signed transaction data
    /// - Returns: Transaction hash
    public func executeStake(
        _ transaction: PreparedStakingTransaction,
        receipt: SimulationReceipt,
        signedTransaction: Data
    ) async throws -> String {
        
        // Verify receipt is valid
        guard !receipt.isExpired else {
            throw StakingError.simulationFailed(reason: "Simulation expired")
        }
        
        // Broadcast transaction
        let result = try await rpcRouter.sendRawTransaction(
            signedTx: signedTransaction,
            chain: transaction.chain
        )
        
        // Parse transaction hash
        guard let json = try? JSONSerialization.jsonObject(with: result.data) as? [String: Any],
              let txHash = json["result"] as? String else {
            throw StakingError.transactionFailed(reason: "Failed to parse transaction hash")
        }
        
        return txHash
    }
    
    // MARK: - Public Interface: Unstake
    
    /// Prepare an unstaking transaction
    public func prepareUnstakeTransaction(
        _ request: UnstakingRequest
    ) async throws -> PreparedStakingTransaction {
        
        // Check if position is locked
        if let unlocksAt = request.position.unlocksAt, Date() < unlocksAt {
            throw StakingError.unstakingLocked(unlocksAt: unlocksAt)
        }
        
        let transaction: PreparedStakingTransaction
        
        switch request.position.protocol {
        case .lido:
            transaction = try buildLidoUnstakeTransaction(request)
        case .aave:
            transaction = try buildAaveWithdrawTransaction(request)
        case .rocket:
            transaction = try buildRocketPoolUnstakeTransaction(request)
        case .compound:
            transaction = try buildCompoundWithdrawTransaction(request)
        case .eigenlayer:
            transaction = try buildEigenLayerUnstakeTransaction(request)
        }
        
        return transaction
    }
    
    // MARK: - Lido (ETH Staking)
    
    /// Build Lido stETH submit transaction
    /// Function: submit(address _referral) payable
    private func buildLidoStakeTransaction(_ request: StakingRequest) throws -> PreparedStakingTransaction {
        // Function selector for submit(address)
        // keccak256("submit(address)")[:4] = 0xa1903eab
        let selector = Data([0xa1, 0x90, 0x3e, 0xab])
        
        // Encode referral address (zero address for no referral)
        let referralAddress = request.referralCode ?? "0x0000000000000000000000000000000000000000"
        let calldata = selector + encodeAddress(referralAddress)
        
        return PreparedStakingTransaction(
            from: request.senderAddress,
            to: ProtocolContracts.lidoStETH,
            value: request.amount, // ETH value to stake
            calldata: calldata,
            chain: .ethereum,
            gasLimit: 150000,
            transactionType: .stake,
            opportunity: request.opportunity
        )
    }
    
    /// Build Lido withdrawal request
    private func buildLidoUnstakeTransaction(_ request: UnstakingRequest) throws -> PreparedStakingTransaction {
        // For Lido, unstaking requires:
        // 1. Request withdrawal via Lido Withdrawal contract
        // 2. Wait for processing (~1-5 days)
        // 3. Claim ETH
        
        // requestWithdrawals(uint256[] amounts, address owner)
        let selector = Data([0xd6, 0x68, 0x10, 0xa1])
        
        // Encode amounts array and owner
        // Simplified: single amount withdrawal
        var calldata = selector
        
        // Offset to amounts array (64 bytes)
        calldata.append(encodeUint256("64"))
        // Owner address
        calldata.append(encodeAddress(request.senderAddress))
        // Array length
        calldata.append(encodeUint256("1"))
        // Amount
        calldata.append(encodeUint256(request.amount))
        
        return PreparedStakingTransaction(
            from: request.senderAddress,
            to: ProtocolContracts.lidoWithdrawal,
            value: "0",
            calldata: calldata,
            chain: .ethereum,
            gasLimit: 200000,
            transactionType: .unstake,
            opportunity: nil
        )
    }
    
    // MARK: - Aave (Lending)
    
    /// Build Aave V3 supply transaction
    /// Function: supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode)
    private func buildAaveSupplyTransaction(_ request: StakingRequest) throws -> PreparedStakingTransaction {
        // Function selector for supply(address,uint256,address,uint16)
        // keccak256("supply(address,uint256,address,uint16)")[:4] = 0x617ba037
        let selector = Data([0x61, 0x7b, 0xa0, 0x37])
        
        // Get asset address
        guard let assetAddress = request.opportunity.inputAsset.contractAddress else {
            // For native ETH, use WETH gateway
            throw StakingError.invalidAmount
        }
        
        var calldata = selector
        // asset
        calldata.append(encodeAddress(assetAddress))
        // amount
        calldata.append(encodeUint256(request.amount))
        // onBehalfOf (self)
        calldata.append(encodeAddress(request.senderAddress))
        // referralCode (0 for none)
        calldata.append(encodeUint256("0"))
        
        return PreparedStakingTransaction(
            from: request.senderAddress,
            to: ProtocolContracts.aavePool,
            value: "0", // ERC20 supply, no ETH value
            calldata: calldata,
            chain: .ethereum,
            gasLimit: 300000,
            transactionType: .stake,
            opportunity: request.opportunity
        )
    }
    
    /// Build Aave V3 withdraw transaction
    /// Function: withdraw(address asset, uint256 amount, address to)
    private func buildAaveWithdrawTransaction(_ request: UnstakingRequest) throws -> PreparedStakingTransaction {
        // Function selector for withdraw(address,uint256,address)
        // keccak256("withdraw(address,uint256,address)")[:4] = 0x69328dec
        let selector = Data([0x69, 0x32, 0x8d, 0xec])
        
        guard let assetAddress = request.position.stakedAsset.contractAddress else {
            throw StakingError.invalidAmount
        }
        
        var calldata = selector
        // asset
        calldata.append(encodeAddress(assetAddress))
        // amount (max uint256 for full withdrawal)
        let maxUint = "115792089237316195423570985008687907853269984665640564039457584007913129639935"
        let amount = request.amount == "max" ? maxUint : request.amount
        calldata.append(encodeUint256(amount))
        // to (self)
        calldata.append(encodeAddress(request.senderAddress))
        
        return PreparedStakingTransaction(
            from: request.senderAddress,
            to: ProtocolContracts.aavePool,
            value: "0",
            calldata: calldata,
            chain: .ethereum,
            gasLimit: 300000,
            transactionType: .unstake,
            opportunity: nil
        )
    }
    
    // MARK: - Rocket Pool
    
    /// Build Rocket Pool rETH deposit transaction
    private func buildRocketPoolStakeTransaction(_ request: StakingRequest) throws -> PreparedStakingTransaction {
        // Function: deposit() payable
        // Simply sends ETH to the deposit pool
        let selector = Data([0xd0, 0xe3, 0x0d, 0xb0])
        
        return PreparedStakingTransaction(
            from: request.senderAddress,
            to: ProtocolContracts.rocketDepositPool,
            value: request.amount,
            calldata: selector,
            chain: .ethereum,
            gasLimit: 200000,
            transactionType: .stake,
            opportunity: request.opportunity
        )
    }
    
    /// Build Rocket Pool rETH burn/withdrawal
    private func buildRocketPoolUnstakeTransaction(_ request: UnstakingRequest) throws -> PreparedStakingTransaction {
        // Function: burn(uint256 _rethAmount)
        // Burns rETH for ETH
        let selector = Data([0x42, 0x96, 0x6c, 0x68])
        
        let calldata = selector + encodeUint256(request.amount)
        
        // rETH contract address
        let rETHAddress = "0xae78736Cd615f374D3085123A210448E74Fc6393"
        
        return PreparedStakingTransaction(
            from: request.senderAddress,
            to: rETHAddress,
            value: "0",
            calldata: calldata,
            chain: .ethereum,
            gasLimit: 200000,
            transactionType: .unstake,
            opportunity: nil
        )
    }
    
    // MARK: - Compound
    
    /// Build Compound supply transaction (simplified)
    private func buildCompoundSupplyTransaction(_ request: StakingRequest) throws -> PreparedStakingTransaction {
        // Compound V3 supply
        // Function: supply(address asset, uint amount)
        let selector = Data([0xf2, 0xb9, 0xfa, 0xd8])
        
        guard let assetAddress = request.opportunity.inputAsset.contractAddress else {
            throw StakingError.invalidAmount
        }
        
        var calldata = selector
        calldata.append(encodeAddress(assetAddress))
        calldata.append(encodeUint256(request.amount))
        
        // Compound V3 USDC market
        let cometUSDC = "0xc3d688B66703497DAA19211EEdff47f25384cdc3"
        
        return PreparedStakingTransaction(
            from: request.senderAddress,
            to: cometUSDC,
            value: "0",
            calldata: calldata,
            chain: .ethereum,
            gasLimit: 250000,
            transactionType: .stake,
            opportunity: request.opportunity
        )
    }
    
    /// Build Compound withdraw transaction
    private func buildCompoundWithdrawTransaction(_ request: UnstakingRequest) throws -> PreparedStakingTransaction {
        // Function: withdraw(address asset, uint amount)
        let selector = Data([0xf3, 0xfe, 0x3a, 0x3a])
        
        guard let assetAddress = request.position.stakedAsset.contractAddress else {
            throw StakingError.invalidAmount
        }
        
        var calldata = selector
        calldata.append(encodeAddress(assetAddress))
        calldata.append(encodeUint256(request.amount))
        
        let cometUSDC = "0xc3d688B66703497DAA19211EEdff47f25384cdc3"
        
        return PreparedStakingTransaction(
            from: request.senderAddress,
            to: cometUSDC,
            value: "0",
            calldata: calldata,
            chain: .ethereum,
            gasLimit: 250000,
            transactionType: .unstake,
            opportunity: nil
        )
    }
    
    // MARK: - EigenLayer
    
    /// Build EigenLayer restaking transaction
    private func buildEigenLayerRestakeTransaction(_ request: StakingRequest) throws -> PreparedStakingTransaction {
        // EigenLayer Strategy Manager depositIntoStrategy
        // Function: depositIntoStrategy(address strategy, address token, uint256 amount)
        let selector = Data([0xe7, 0xa0, 0x50, 0xaa])
        
        guard let tokenAddress = request.opportunity.inputAsset.contractAddress else {
            throw StakingError.invalidAmount
        }
        
        // stETH strategy address
        let stETHStrategy = "0x93c4b944D05dfe6df7645A86cd2206016c51564D"
        
        var calldata = selector
        calldata.append(encodeAddress(stETHStrategy))
        calldata.append(encodeAddress(tokenAddress))
        calldata.append(encodeUint256(request.amount))
        
        // EigenLayer Strategy Manager
        let strategyManager = "0x858646372CC42E1A627fcE94aa7A7033e7CF075A"
        
        return PreparedStakingTransaction(
            from: request.senderAddress,
            to: strategyManager,
            value: "0",
            calldata: calldata,
            chain: .ethereum,
            gasLimit: 350000,
            transactionType: .stake,
            opportunity: request.opportunity
        )
    }
    
    /// Build EigenLayer unstaking transaction
    private func buildEigenLayerUnstakeTransaction(_ request: UnstakingRequest) throws -> PreparedStakingTransaction {
        // EigenLayer queueWithdrawal (simplified)
        // Actual implementation is more complex with multiple parameters
        let selector = Data([0x0d, 0xd8, 0xdd, 0x02])
        
        let strategyManager = "0x858646372CC42E1A627fcE94aa7A7033e7CF075A"
        
        return PreparedStakingTransaction(
            from: request.senderAddress,
            to: strategyManager,
            value: "0",
            calldata: selector + encodeUint256(request.amount),
            chain: .ethereum,
            gasLimit: 400000,
            transactionType: .unstake,
            opportunity: nil
        )
    }
    
    // MARK: - Token Approval
    
    /// Check if token approval is needed for staking
    public func checkApprovalNeeded(
        token: String,
        owner: String,
        spender: String,
        amount: String
    ) async throws -> Bool {
        // Build allowance check
        let selector = Data([0xdd, 0x62, 0xed, 0x3e])
        let calldata = selector + encodeAddress(owner) + encodeAddress(spender)
        
        let result = try await rpcRouter.sendRequest(
            method: "eth_call",
            params: [
                [
                    "to": token,
                    "data": "0x" + calldata.map { String(format: "%02x", $0) }.joined()
                ],
                "latest"
            ],
            chain: .ethereum
        )
        
        guard let json = try? JSONSerialization.jsonObject(with: result.data) as? [String: Any],
              let hexAllowance = json["result"] as? String else {
            return true
        }
        
        let allowanceHex = String(hexAllowance.dropFirst(2))
        guard let allowance = UInt64(allowanceHex.prefix(16), radix: 16),
              let requiredAmount = UInt64(amount) else {
            return true
        }
        
        return allowance < requiredAmount
    }
    
    /// Build approval transaction
    public func buildApprovalTransaction(
        token: String,
        spender: String,
        owner: String
    ) -> PreparedStakingTransaction {
        // approve(address,uint256)
        let selector = Data([0x09, 0x5e, 0xa7, 0xb3])
        let maxApproval = "115792089237316195423570985008687907853269984665640564039457584007913129639935"
        
        let calldata = selector + encodeAddress(spender) + encodeUint256(maxApproval)
        
        return PreparedStakingTransaction(
            from: owner,
            to: token,
            value: "0",
            calldata: calldata,
            chain: .ethereum,
            gasLimit: 60000,
            transactionType: .stake,
            opportunity: nil
        )
    }
    
    // MARK: - ABI Encoding Helpers
    
    /// Encode an address to 32-byte ABI format (12 bytes padding + 20 bytes address)
    private func encodeAddress(_ address: String) -> Data {
        var cleanAddress = address.lowercased()
        if cleanAddress.hasPrefix("0x") {
            cleanAddress = String(cleanAddress.dropFirst(2))
        }
        
        // Validate address length (should be 40 hex chars = 20 bytes)
        guard cleanAddress.count == 40 else {
            return Data(repeating: 0, count: 32) // Return zero-filled data on error
        }
        
        // Start with 12 bytes of padding (zeros)
        var data = Data(repeating: 0, count: 12)
        
        // Convert hex string to bytes and append
        var index = cleanAddress.startIndex
        for _ in 0..<20 {
            guard index < cleanAddress.endIndex else { break }
            let nextIndex = cleanAddress.index(index, offsetBy: 2, limitedBy: cleanAddress.endIndex) ?? cleanAddress.endIndex
            if let byte = UInt8(cleanAddress[index..<nextIndex], radix: 16) {
                data.append(byte)
            } else {
                // Invalid hex, return zero-filled data
                return Data(repeating: 0, count: 32)
            }
            index = nextIndex
        }
        
        // Ensure we have exactly 32 bytes (12 padding + 20 address)
        if data.count < 32 {
            data.append(Data(repeating: 0, count: 32 - data.count))
        }
        
        return data
    }
    
    /// Encode a uint256 value (32 bytes, big-endian)
    private func encodeUint256(_ value: String) -> Data {
        var data = Data(repeating: 0, count: 32)
        
        // Handle hex strings
        if value.hasPrefix("0x") {
            let hexString = String(value.dropFirst(2))
            if let hexData = Data(hexString: hexString) {
                // Pad or truncate to 32 bytes
                if hexData.count <= 32 {
                    data.replaceSubrange((32 - hexData.count)..<32, with: hexData)
                } else {
                    // Truncate if too long
                    data.replaceSubrange(0..<32, with: hexData.prefix(32))
                }
                return data
            }
        }
        
        // Handle decimal strings (UInt64 max is 18,446,744,073,709,551,615)
        // For larger values, should use BigInt, but for now handle UInt64
        if let intValue = UInt64(value) {
            var bigEndian = intValue.bigEndian
            let bytes = withUnsafeBytes(of: &bigEndian) { Data($0) }
            data.replaceSubrange(24..<32, with: bytes)
        } else if let bigIntValue = BigUInt(value) {
            // Handle larger values with BigUInt
            let hexString = String(bigIntValue, radix: 16)
            if let hexData = Data(hexString: hexString) {
                if hexData.count <= 32 {
                    data.replaceSubrange((32 - hexData.count)..<32, with: hexData)
                } else {
                    data.replaceSubrange(0..<32, with: hexData.prefix(32))
                }
            }
        }
        
        return data
    }
}


