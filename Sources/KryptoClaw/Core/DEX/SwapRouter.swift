// MODULE: SwapRouter
// VERSION: 1.0.0
// PURPOSE: Actor-based swap transaction constructor and executor

import Foundation

// MARK: - Swap Router Actor

/// Actor responsible for constructing and routing swap transactions.
///
/// **Responsibilities:**
/// - Construct raw transaction payloads from swap quotes
/// - Build THORChain memo strings for cross-chain swaps
/// - Parse 1inch calldata for same-chain swaps
/// - Integrate with TransactionSimulationService for safety
/// - Execute swaps through appropriate transaction channels
@available(iOS 15.0, macOS 12.0, *)
public actor SwapRouter {
    
    // MARK: - Dependencies
    
    private let rpcRouter: RPCRouter
    private let simulationService: TransactionSimulationService
    private let session: URLSession
    
    // MARK: - Configuration
    
    private struct Config {
        // 1inch Router V5 addresses
        static let oneInchRouterV5 = "0x1111111254EEB25477B68fb85Ed929f73A960582"
        
        // Common token approval address (ERC20)
        static let maxApproval = "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
        
        // Gas buffer multiplier
        static let gasBufferMultiplier: Double = 1.2
    }
    
    // MARK: - Initialization
    
    public init(
        rpcRouter: RPCRouter,
        simulationService: TransactionSimulationService,
        session: URLSession = .shared
    ) {
        self.rpcRouter = rpcRouter
        self.simulationService = simulationService
        self.session = session
    }
    
    // MARK: - Public Interface
    
    /// Prepare a swap transaction from a quote
    /// - Parameters:
    ///   - quote: The swap quote to execute
    ///   - senderAddress: Address initiating the swap
    /// - Returns: Prepared swap transaction ready for simulation
    public func prepareSwapTransaction(
        quote: SwapQuoteV2,
        senderAddress: String
    ) async throws -> PreparedSwapTransaction {
        
        switch quote.routeType {
        case .crossChain:
            return try await prepareTHORChainTransaction(quote: quote, senderAddress: senderAddress)
            
        case .sameChain:
            return try await prepareSameChainTransaction(quote: quote, senderAddress: senderAddress)
            
        case .wrap:
            return try await prepareWrapTransaction(quote: quote, senderAddress: senderAddress)
            
        case .unwrap:
            return try await prepareUnwrapTransaction(quote: quote, senderAddress: senderAddress)
        }
    }
    
    /// Simulate a prepared swap transaction
    /// - Parameter transaction: The prepared swap transaction
    /// - Returns: Simulation result with receipt if successful
    public func simulateSwap(
        _ transaction: PreparedSwapTransaction
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
    
    /// Execute a swap with a valid simulation receipt
    /// - Parameters:
    ///   - transaction: The prepared swap transaction
    ///   - receipt: Valid simulation receipt
    ///   - signedTransaction: Signed transaction data
    /// - Returns: Transaction hash if successful
    public func executeSwap(
        _ transaction: PreparedSwapTransaction,
        receipt: SimulationReceipt,
        signedTransaction: Data
    ) async throws -> String {
        
        // Verify receipt is still valid
        guard !receipt.isExpired else {
            throw SwapError.quoteExpired
        }
        
        // Verify receipt matches transaction
        let simulationRequest = SimulationRequest(
            from: transaction.from,
            to: transaction.to,
            value: transaction.value,
            data: transaction.calldata,
            chain: transaction.chain,
            gasLimit: transaction.gasLimit
        )
        
        guard await simulationService.verifyReceipt(receipt, for: simulationRequest) else {
            throw SwapError.simulationFailed(reason: "Receipt verification failed")
        }
        
        // Broadcast the transaction
        let result = try await rpcRouter.sendRawTransaction(
            signedTx: signedTransaction,
            chain: transaction.chain
        )
        
        // Parse transaction hash from response
        guard let json = try? JSONSerialization.jsonObject(with: result.data) as? [String: Any],
              let txHash = json["result"] as? String else {
            throw SwapError.transactionFailed(reason: "Failed to parse transaction hash")
        }
        
        return txHash
    }
    
    // MARK: - THORChain Transaction Preparation
    
    /// Prepare a cross-chain swap via THORChain
    private func prepareTHORChainTransaction(
        quote: SwapQuoteV2,
        senderAddress: String
    ) async throws -> PreparedSwapTransaction {
        
        guard let txData = quote.transactionData else {
            throw SwapError.invalidParameters(reason: "Missing transaction data in quote")
        }
        
        guard let memo = txData.thorchainMemo else {
            throw SwapError.invalidParameters(reason: "Missing THORChain memo")
        }
        
        guard let vaultAddress = txData.vaultAddress else {
            throw SwapError.invalidParameters(reason: "Missing vault address")
        }
        
        // For THORChain, the transaction is a simple transfer to the vault with memo
        // The memo instructs THORChain what to do with the funds
        
        switch quote.fromAsset.chain {
        case .ethereum:
            return try prepareTHORChainEthereumTransaction(
                quote: quote,
                senderAddress: senderAddress,
                vaultAddress: vaultAddress,
                memo: memo
            )
            
        case .bitcoin:
            return try prepareTHORChainBitcoinTransaction(
                quote: quote,
                senderAddress: senderAddress,
                vaultAddress: vaultAddress,
                memo: memo
            )
            
        case .solana:
            return try prepareTHORChainSolanaTransaction(
                quote: quote,
                senderAddress: senderAddress,
                vaultAddress: vaultAddress,
                memo: memo
            )
        }
    }
    
    /// Prepare THORChain swap from Ethereum
    private func prepareTHORChainEthereumTransaction(
        quote: SwapQuoteV2,
        senderAddress: String,
        vaultAddress: String,
        memo: String
    ) throws -> PreparedSwapTransaction {
        
        // For native ETH, send to vault with memo in data
        // For ERC20, call router's depositWithExpiry
        
        if quote.fromAsset.type == .native {
            // Native ETH: Send to vault, memo in tx data
            let memoData = Data(memo.utf8)
            
            return PreparedSwapTransaction(
                from: senderAddress,
                to: vaultAddress,
                value: quote.inputAmount,
                calldata: memoData,
                chain: .ethereum,
                gasLimit: 80000,
                quote: quote,
                requiresApproval: false
            )
        } else {
            // ERC20: Need to call THORChain router
            guard let contractAddress = quote.fromAsset.contractAddress else {
                throw SwapError.invalidParameters(reason: "Missing token contract address")
            }
            
            // Build depositWithExpiry calldata
            // depositWithExpiry(address payable vault, address asset, uint256 amount, string memo, uint256 expiration)
            let calldata = buildTHORChainDepositCalldata(
                vault: vaultAddress,
                asset: contractAddress,
                amount: quote.inputAmount,
                memo: memo
            )
            
            // THORChain router address for Ethereum
            let thorchainRouter = "0xD37BbE5744D730a1d98d8DC97c42F0Ca46aD7146"
            
            return PreparedSwapTransaction(
                from: senderAddress,
                to: thorchainRouter,
                value: "0",
                calldata: calldata,
                chain: .ethereum,
                gasLimit: 150000,
                quote: quote,
                requiresApproval: true,
                approvalToken: contractAddress,
                approvalSpender: thorchainRouter
            )
        }
    }
    
    /// Build THORChain deposit calldata for ERC20
    private func buildTHORChainDepositCalldata(
        vault: String,
        asset: String,
        amount: String,
        memo: String
    ) -> Data {
        // Function selector for depositWithExpiry
        // keccak256("depositWithExpiry(address,address,uint256,string,uint256)")[:4]
        let selector = Data([0x44, 0xbc, 0x93, 0x7b])
        
        // Encode parameters (simplified - in production use proper ABI encoding)
        var calldata = selector
        
        // Add vault address (padded to 32 bytes)
        calldata.append(encodeAddress(vault))
        
        // Add asset address
        calldata.append(encodeAddress(asset))
        
        // Add amount (uint256)
        calldata.append(encodeUint256(amount))
        
        // Add memo string (dynamic - simplified encoding)
        // Offset to memo data (128 bytes from start of params)
        calldata.append(encodeUint256("160"))
        
        // Add expiration (current time + 1 hour)
        let expiration = "\(Int(Date().timeIntervalSince1970) + 3600)"
        calldata.append(encodeUint256(expiration))
        
        // Add memo length and data
        calldata.append(encodeUint256("\(memo.count)"))
        calldata.append(Data(memo.utf8))
        
        // Pad to 32-byte boundary
        let padding = (32 - (memo.count % 32)) % 32
        calldata.append(Data(repeating: 0, count: padding))
        
        return calldata
    }
    
    /// Prepare THORChain swap from Bitcoin
    private func prepareTHORChainBitcoinTransaction(
        quote: SwapQuoteV2,
        senderAddress: String,
        vaultAddress: String,
        memo: String
    ) throws -> PreparedSwapTransaction {
        
        // For Bitcoin, the memo is included in an OP_RETURN output
        // The transaction sends BTC to vault + OP_RETURN with memo
        
        // Simplified: Just return the transaction parameters
        // Actual Bitcoin tx construction happens in the signer
        
        return PreparedSwapTransaction(
            from: senderAddress,
            to: vaultAddress,
            value: quote.inputAmount,
            calldata: Data(memo.utf8), // Memo goes in OP_RETURN
            chain: .bitcoin,
            gasLimit: 250, // vBytes estimate
            quote: quote,
            requiresApproval: false,
            bitcoinMemo: memo
        )
    }
    
    /// Prepare THORChain swap from Solana
    private func prepareTHORChainSolanaTransaction(
        quote: SwapQuoteV2,
        senderAddress: String,
        vaultAddress: String,
        memo: String
    ) throws -> PreparedSwapTransaction {
        
        // For Solana, use THORChain's aggregator program
        // Memo is included as instruction data
        
        return PreparedSwapTransaction(
            from: senderAddress,
            to: vaultAddress,
            value: quote.inputAmount,
            calldata: Data(memo.utf8),
            chain: .solana,
            gasLimit: 5000, // Compute units
            quote: quote,
            requiresApproval: false
        )
    }
    
    // MARK: - Same-Chain Transaction Preparation
    
    /// Prepare a same-chain DEX swap (1inch, Jupiter, etc.)
    private func prepareSameChainTransaction(
        quote: SwapQuoteV2,
        senderAddress: String
    ) async throws -> PreparedSwapTransaction {
        
        guard let txData = quote.transactionData else {
            throw SwapError.invalidParameters(reason: "Missing transaction data in quote")
        }
        
        let requiresApproval = quote.fromAsset.type != .native
        
        return PreparedSwapTransaction(
            from: senderAddress,
            to: txData.to,
            value: txData.value,
            calldata: txData.calldata,
            chain: quote.fromAsset.chain,
            gasLimit: txData.gasLimit ?? 300000,
            quote: quote,
            requiresApproval: requiresApproval,
            approvalToken: quote.fromAsset.contractAddress,
            approvalSpender: txData.to
        )
    }
    
    // MARK: - Wrap/Unwrap Transaction Preparation
    
    /// Prepare ETH → WETH wrap transaction
    private func prepareWrapTransaction(
        quote: SwapQuoteV2,
        senderAddress: String
    ) async throws -> PreparedSwapTransaction {
        
        // WETH contract address on Ethereum mainnet
        let wethContract = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"
        
        // deposit() function selector
        let depositSelector = Data([0xd0, 0xe3, 0x0d, 0xb0])
        
        return PreparedSwapTransaction(
            from: senderAddress,
            to: wethContract,
            value: quote.inputAmount,
            calldata: depositSelector,
            chain: .ethereum,
            gasLimit: 50000,
            quote: quote,
            requiresApproval: false
        )
    }
    
    /// Prepare WETH → ETH unwrap transaction
    private func prepareUnwrapTransaction(
        quote: SwapQuoteV2,
        senderAddress: String
    ) async throws -> PreparedSwapTransaction {
        
        // WETH contract address on Ethereum mainnet
        let wethContract = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"
        
        // withdraw(uint256) function selector + amount
        let withdrawSelector = Data([0x2e, 0x1a, 0x7d, 0x4d])
        let calldata = withdrawSelector + encodeUint256(quote.inputAmount)
        
        return PreparedSwapTransaction(
            from: senderAddress,
            to: wethContract,
            value: "0",
            calldata: calldata,
            chain: .ethereum,
            gasLimit: 50000,
            quote: quote,
            requiresApproval: false
        )
    }
    
    // MARK: - Token Approval
    
    /// Check if token approval is needed
    public func checkApproval(
        token: String,
        owner: String,
        spender: String,
        amount: String,
        chain: AssetChain
    ) async throws -> Bool {
        guard chain == .ethereum else {
            // Solana uses different approval mechanism
            return false
        }
        
        // Build allowance check calldata
        // allowance(address owner, address spender)
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
            return true // Assume approval needed if check fails
        }
        
        // Parse allowance
        let allowanceHex = String(hexAllowance.dropFirst(2))
        guard let allowance = UInt64(allowanceHex, radix: 16),
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
    ) -> PreparedSwapTransaction {
        // approve(address spender, uint256 amount)
        let selector = Data([0x09, 0x5e, 0xa7, 0xb3])
        let calldata = selector + encodeAddress(spender) + encodeUint256(Config.maxApproval)
        
        return PreparedSwapTransaction(
            from: owner,
            to: token,
            value: "0",
            calldata: calldata,
            chain: .ethereum,
            gasLimit: 60000,
            quote: nil,
            requiresApproval: false,
            isApprovalTransaction: true
        )
    }
    
    // MARK: - ABI Encoding Helpers
    
    /// Encode an address to 32-byte ABI format
    private func encodeAddress(_ address: String) -> Data {
        var cleanAddress = address.lowercased()
        if cleanAddress.hasPrefix("0x") {
            cleanAddress = String(cleanAddress.dropFirst(2))
        }
        
        // Pad to 32 bytes (12 bytes padding + 20 byte address)
        var data = Data(repeating: 0, count: 12)
        if let addressBytes = Data(swapHexString: cleanAddress) {
            data.append(addressBytes)
        }
        
        return data
    }
    
    /// Encode a uint256 value
    private func encodeUint256(_ value: String) -> Data {
        var data = Data(repeating: 0, count: 32)
        
        if let intValue = UInt64(value) {
            // Encode as big-endian in last 8 bytes
            var bigEndian = intValue.bigEndian
            let bytes = withUnsafeBytes(of: &bigEndian) { Data($0) }
            data.replaceSubrange(24..<32, with: bytes)
        }
        
        return data
    }
}

// MARK: - Prepared Swap Transaction

/// A swap transaction ready for simulation and signing
public struct PreparedSwapTransaction: Sendable {
    /// Sender address
    public let from: String
    
    /// Target contract/address
    public let to: String
    
    /// Value to send (in wei/satoshi/lamports)
    public let value: String
    
    /// Transaction calldata
    public let calldata: Data
    
    /// Target chain
    public let chain: AssetChain
    
    /// Estimated gas limit
    public let gasLimit: UInt64
    
    /// Original quote (nil for approval transactions)
    public let quote: SwapQuoteV2?
    
    /// Whether token approval is required first
    public let requiresApproval: Bool
    
    /// Token to approve (if applicable)
    public let approvalToken: String?
    
    /// Spender to approve (if applicable)
    public let approvalSpender: String?
    
    /// Bitcoin memo for OP_RETURN (if applicable)
    public let bitcoinMemo: String?
    
    /// Whether this is an approval transaction
    public let isApprovalTransaction: Bool
    
    public init(
        from: String,
        to: String,
        value: String,
        calldata: Data,
        chain: AssetChain,
        gasLimit: UInt64,
        quote: SwapQuoteV2?,
        requiresApproval: Bool = false,
        approvalToken: String? = nil,
        approvalSpender: String? = nil,
        bitcoinMemo: String? = nil,
        isApprovalTransaction: Bool = false
    ) {
        self.from = from
        self.to = to
        self.value = value
        self.calldata = calldata
        self.chain = chain
        self.gasLimit = gasLimit
        self.quote = quote
        self.requiresApproval = requiresApproval
        self.approvalToken = approvalToken
        self.approvalSpender = approvalSpender
        self.bitcoinMemo = bitcoinMemo
        self.isApprovalTransaction = isApprovalTransaction
    }
    
    /// Hex-encoded calldata
    public var calldataHex: String {
        "0x" + calldata.map { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Data Extension for Hex (SwapRouter)

extension Data {
    /// Initialize Data from hex string (SwapRouter specific)
    init?(swapHexString hexString: String) {
        let len = hexString.count / 2
        var data = Data(capacity: len)
        var index = hexString.startIndex
        for _ in 0..<len {
            let nextIndex = hexString.index(index, offsetBy: 2)
            if let byte = UInt8(hexString[index..<nextIndex], radix: 16) {
                data.append(byte)
            } else {
                return nil
            }
            index = nextIndex
        }
        self = data
    }
}


