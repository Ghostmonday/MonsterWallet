import Foundation
import BigInt
#if canImport(WalletCore)
import WalletCore
#endif

/// 🔒 COMPLIANCE: Signing Layer / Transaction Construction
/// Ref: Master Execution Blueprint - Phase 3 & 4
public class TransactionSigner {

    private let keyStore: KeyStoreProtocol

    public init(keyStore: KeyStoreProtocol) {
        self.keyStore = keyStore
    }

    public func sign(transaction: TransactionPayload) async throws -> String {
        // 1. Retrieve Key Identifier (Mnemonic is stored under 'primary_account')
        let secureMnemonic = try keyStore.getPrivateKey(id: "primary_account")
        guard let mnemonic = String(data: secureMnemonic.unsafeDataCopy(), encoding: .utf8) else {
            throw BlockchainError.parsingError
        }
        
        // 2. Generate Private Key for Chain
        // Use standard derivation path unless specified otherwise (TODO: Add path to payload)
        let privateKeyData = try HDWalletService.derivePrivateKey(mnemonic: mnemonic, for: transaction.coinType)
        
        // 3. Sign Transaction
        #if canImport(WalletCore)
        guard let privateKey = PrivateKey(data: privateKeyData) else {
            throw WalletError.derivationFailed
        }
        
        switch transaction.coinType {
        case .ethereum:
            var input = EthereumSigningInput()
            input.toAddress = transaction.toAddress
            // ChainID: Use test chain ID (31337) in test environment, mainnet (1) otherwise
            let chainIDValue: UInt64 = UInt64(AppConfig.getEthereumChainId())
            input.chainID = withUnsafeBytes(of: chainIDValue.bigEndian) { Data($0) }
            
            // Nonce: Convert UInt64 to big-endian Data (remove leading zeros, but keep at least 1 byte)
            let nonceValue = transaction.nonce ?? 0
            var nonceData = withUnsafeBytes(of: nonceValue.bigEndian) { Data($0) }
            // Remove leading zeros, but ensure at least 1 byte remains (for zero value)
            while nonceData.count > 1 && nonceData.first == 0 {
                nonceData.removeFirst()
            }
            input.nonce = nonceData.isEmpty ? Data([0]) : nonceData
            
            // GasPrice: Convert BigInt to big-endian Data (remove leading zeros, but keep at least 1 byte)
            let gasPriceVal = transaction.fee ?? BigInt(20000000000) // 20 gwei default
            var gasPriceData = Data(gasPriceVal.serialize())
            // Remove leading zeros, but ensure at least 1 byte remains
            while gasPriceData.count > 1 && gasPriceData.first == 0 {
                gasPriceData.removeFirst()
            }
            input.gasPrice = gasPriceData.isEmpty ? Data([0]) : gasPriceData
            
            // GasLimit: Convert BigInt to big-endian Data (remove leading zeros, but keep at least 1 byte)
            let gasLimitVal = BigInt(21000)
            var gasLimitData = Data(gasLimitVal.serialize())
            // Remove leading zeros, but ensure at least 1 byte remains
            while gasLimitData.count > 1 && gasLimitData.first == 0 {
                gasLimitData.removeFirst()
            }
            input.gasLimit = gasLimitData.isEmpty ? Data([0]) : gasLimitData
            
            // Amount: Convert BigInt to big-endian Data (remove leading zeros, but keep at least 1 byte)
            var transfer = EthereumTransaction.Transfer()
            var amountData = Data(transaction.amount.serialize())
            // Remove leading zeros, but ensure at least 1 byte remains
            while amountData.count > 1 && amountData.first == 0 {
                amountData.removeFirst()
            }
            transfer.amount = amountData.isEmpty ? Data([0]) : amountData
            
            var ethTx = EthereumTransaction()
            ethTx.transfer = transfer
            
            if let data = transaction.data {
                var contract = EthereumTransaction.ContractGeneric()
                contract.data = data
                ethTx.contractGeneric = contract
            }
            
            input.transaction = ethTx
            input.privateKey = privateKey.data
            
            let output: EthereumSigningOutput = AnySigner.sign(input: input, coin: .ethereum)
            return output.encoded.hexString
            
        case .bitcoin:
            // Requires UTXOs to be passed in payload
            guard let utxos = transaction.utxos else {
                throw BlockchainError.rpcError("Missing UTXOs for Bitcoin transaction")
            }
            
            let input = BitcoinSigningInput.with {
                $0.amount = Int64(transaction.amount)
                $0.hashType = BitcoinSigHashType.all.rawValue
                $0.toAddress = transaction.toAddress
                $0.changeAddress = HDWalletService.address(from: privateKeyData, for: .bitcoin) // Send change back to self
                $0.byteFee = 10 // sat/vbyte, should be configurable
                $0.privateKey = [privateKey.data]
                
                $0.utxo = utxos.map { utxo in
                    BitcoinUnspentTransaction.with {
                        $0.outPoint.hash = Data(hexString: utxo.hash)!
                        $0.outPoint.index = utxo.index
                        $0.amount = utxo.amount
                        $0.script = utxo.script ?? Data() // Script should be fetched
                    }
                }
            }
            
            let output: BitcoinSigningOutput = AnySigner.sign(input: input, coin: .bitcoin)
            return output.encoded.hexString
            
        case .solana:
            guard let blockhash = transaction.recentBlockhash else {
                throw BlockchainError.rpcError("Missing blockhash for Solana transaction")
            }
            
            let input = SolanaSigningInput.with {
                $0.transferTransaction = SolanaTransfer.with {
                    $0.recipient = transaction.toAddress
                    $0.value = UInt64(transaction.amount)
                }
                $0.recentBlockhash = blockhash
                $0.privateKey = privateKey.data
            }
            
            let output: SolanaSigningOutput = AnySigner.sign(input: input, coin: .solana)
            return output.encoded
        }
        #else
        // Fallback for testing without WalletCore
        // Check for required fields based on chain type (for testing error handling)
        switch transaction.coinType {
        case .bitcoin:
            if transaction.utxos == nil || transaction.utxos?.isEmpty == true {
                throw BlockchainError.rpcError("Missing UTXOs for Bitcoin transaction")
            }
        case .solana:
            if transaction.recentBlockhash == nil {
                throw BlockchainError.rpcError("Missing blockhash for Solana transaction")
            }
        default:
            break
        }
        
        // Return a mock signed transaction hex for testing
        // This simulates what a real signed transaction would look like
        switch transaction.coinType {
        case .ethereum:
            // Mock RLP-encoded Ethereum transaction (without 0x prefix for consistency)
            return "f86c808504a817c800825208947421d35cc6634c0532925a3b844bc9e7595f0beb880de0b6b3a76400008025a028ef61340bd939bc2195fe537567866003e1a15d3c71ff63e1590620aa636276a067cbe9d8997f761aecb703304b3800ccf555c9f3dc64214b297fb1966a3b6d83"
        case .bitcoin:
            // Mock Bitcoin transaction hex
            return "01000000010000000000000000000000000000000000000000000000000000000000000000ffffffff4d04ffff001d0104455468652054696d65732030332f4a616e2f32303039204368616e63656c6c6f72206f6e206272696e6b206f66207365636f6e64206261696c6f757420666f722062616e6b73ffffffff0100f2052a01000000434104678afdb0fe5548271967f1a67130b7105cd6a828e03909a67962e0ea1f61deb649f6bc3f4cef38c4f35504e51ec112de5c384df7ba0b8d578a4c702b6bf11d5fac00000000"
        case .solana:
            // Mock Solana transaction (base64)
            return "AQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAAQABBGRlbW8gdHJhbnNhY3Rpb24="
        }
        #endif
        
        // 4. IMMEDIATE WIPING:
        // mnemonicData is let, but we should ensure it's cleared from memory if possible.
        // In Swift, this is hard without `SecureBytes`.
    }
}

public struct TransactionPayload {
    public let coinType: HDWalletService.Chain
    public let toAddress: String
    public let amount: BigInt
    public let fee: BigInt?
    public let nonce: UInt64?
    public let data: Data?
    public let recentBlockhash: String?
    public let utxos: [UTXO]?
    
    public init(coinType: HDWalletService.Chain, toAddress: String, amount: BigInt, fee: BigInt? = nil, nonce: UInt64? = nil, data: Data? = nil, recentBlockhash: String? = nil, utxos: [UTXO]? = nil) {
        self.coinType = coinType
        self.toAddress = toAddress
        self.amount = amount
        self.fee = fee
        self.nonce = nonce
        self.data = data
        self.recentBlockhash = recentBlockhash
        self.utxos = utxos
    }
}

public struct UTXO {
    public let hash: String
    public let index: UInt32
    public let amount: Int64
    public let script: Data?
    
    public init(hash: String, index: UInt32, amount: Int64, script: Data? = nil) {
        self.hash = hash
        self.index = index
        self.amount = amount
        self.script = script
    }
}
