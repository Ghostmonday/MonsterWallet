import Foundation
import CryptoKit

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
        
        // 2. Serialize Tx
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys // Deterministic
        let txData = try encoder.encode(tx)
        
        // 3. Sign (Mocking ECDSA for V1.0 without external dependencies)
        // In production, this would use CoreCrypto or CryptoKit with the specific curve (secp256k1 for ETH).
        // CryptoKit supports P256 (secp256r1) but not k1 natively until recently or with headers.
        // For this architecture demo, we will hash the data + key to simulate a signature.
        
        let signatureInput = txData + privateKeyData
        let signature = SHA256.hash(data: signatureInput).withUnsafeBytes { Data($0) }
        
        // 4. Calculate Hash (Tx Hash)
        let txHash = SHA256.hash(data: txData).compactMap { String(format: "%02x", $0) }.joined()
        
        return SignedData(raw: txData, signature: signature, txHash: "0x" + txHash)
    }
    
    public func signMessage(message: String) async throws -> Data {
        let privateKeyData = try keyStore.getPrivateKey(id: keyId)
        guard let msgData = message.data(using: .utf8) else {
            throw BlockchainError.parsingError
        }
        
        let signatureInput = msgData + privateKeyData
        let signature = SHA256.hash(data: signatureInput).withUnsafeBytes { Data($0) }
        
        return signature
    }
}
