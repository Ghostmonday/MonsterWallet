import BigInt
import CryptoKit
import Foundation
import web3

public class SimpleP2PSigner: SignerProtocol {
    private let keyStore: KeyStoreProtocol
    private let keyId: String

    public init(keyStore: KeyStoreProtocol, keyId: String) {
        self.keyStore = keyStore
        self.keyId = keyId
    }

    public func signTransaction(tx: Transaction) async throws -> SignedData {
        let privateKeyData = try keyStore.getPrivateKey(id: keyId)

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

        let account = try EthereumAccount(keyStorage: MockKeyStorage(key: privateKeyData))
        let signedTx = try account.sign(transaction: ethereumTx)

        guard let rawTx = signedTx.raw else {
            throw BlockchainError.parsingError
        }

        let txHash = signedTx.hash?.hexString ?? ""

        // Note: 'raw' MUST be RLP-encoded data for broadcast (web3.swift handles encoding)
        return SignedData(raw: rawTx, signature: Data(), txHash: txHash)
    }

    public func signMessage(message: String) async throws -> Data {
        let privateKeyData = try keyStore.getPrivateKey(id: keyId)
        guard let msgData = message.data(using: .utf8) else {
            throw BlockchainError.parsingError
        }

        let account = try EthereumAccount(keyStorage: MockKeyStorage(key: privateKeyData))
        let signature = try account.sign(message: msgData)

        return signature
    }
}
