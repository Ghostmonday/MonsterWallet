import Foundation
import CryptoKit
import web3
import BigInt

public class SimpleP2PSigner: SignerProtocol {
    
    private let keyStore: KeyStoreProtocol
    private let keyId: String
    
    public init(keyStore: KeyStoreProtocol, keyId: String) {
        self.keyStore = keyStore
        self.keyId = keyId
    }
    
    public func signTransaction(tx: Transaction) async throws -> SignedData {
        // 1. Get Private Key (Triggers Auth)
        let privateKeyData = try keyStore.getPrivateKey(id: keyId)
        
        // 2. Construct Ethereum Transaction
        // Using web3.swift structures.
        
        guard let valueBig = BigUInt(tx.value) else { throw BlockchainError.parsingError }
        guard let gasPriceBig = BigUInt(tx.maxFeePerGas) else { throw BlockchainError.parsingError }
        
        let toAddress = EthereumAddress(tx.to)
        let fromAddress = try EthereumAccount(keyStorage: MockKeyStorage(key: privateKeyData)).address
        
        let ethereumTx = EthereumTransaction(
            from: fromAddress,
            to: toAddress,
            value: valueBig,
            data: tx.data,
            nonce: Int(tx.nonce),
            gasPrice: gasPriceBig,
            gasLimit: BigUInt(exactly: tx.gasLimit) ?? BigUInt(21000),
            chainId: tx.chainId
        )
        
        // 3. Sign with Real ECDSA (secp256k1)
        let account = try EthereumAccount(keyStorage: MockKeyStorage(key: privateKeyData))

        // Web3.swift handles RLP encoding + Hashing + ECDSA Signing
        let signedTx = try account.sign(transaction: ethereumTx)

        // 4. Get RLP encoded data
        guard let rawTx = signedTx.raw else {
             throw BlockchainError.parsingError
        }

        // 5. Get Tx Hash
        let txHash = signedTx.hash?.hexString ?? ""

        // 6. Return
        // We assume 'signature' field in SignedData is just for reference or legacy,
        // but 'raw' MUST be the RLP encoded data for broadcast.
        return SignedData(raw: rawTx, signature: Data(), txHash: txHash)
    }
    
    public func signMessage(message: String) async throws -> Data {
        let privateKeyData = try keyStore.getPrivateKey(id: keyId)
        guard let msgData = message.data(using: .utf8) else {
            throw BlockchainError.parsingError
        }
        
        // Real ECDSA Signing (EIP-191 Personal Sign)
        let account = try EthereumAccount(keyStorage: MockKeyStorage(key: privateKeyData))

        // Web3.swift 'sign(message:)' typically implements standard personal_sign prefixing.
        let signature = try account.sign(message: msgData)
        
        return signature
    }
}
