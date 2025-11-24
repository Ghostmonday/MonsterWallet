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
        let mnemonicData = try keyStore.getPrivateKey(id: "primary_account")
        guard let mnemonic = String(data: mnemonicData, encoding: .utf8) else {
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
            input.chainID = Data(hexString: "01")!
            
            let nonceVal = BigInt(transaction.nonce ?? 0)
            input.nonce = Data(nonceVal.serialize())
            
            let feeVal = transaction.fee ?? BigInt(21000)
            input.gasPrice = Data(feeVal.serialize())
            
            let gasLimitVal = BigInt(21000)
            input.gasLimit = Data(gasLimitVal.serialize())
            
            var transfer = EthereumTransaction.Transfer()
            transfer.amount = Data(transaction.amount.serialize())
            
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
        // Fallback or Error if WalletCore is missing
        return "Error: WalletCore not available for signing"
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
