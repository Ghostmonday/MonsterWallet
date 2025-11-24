import BigInt
import Foundation
import web3
#if canImport(WalletCore)
import WalletCore
#endif

// MARK: - BIP39/BIP32/BIP44 Implementation

public enum MnemonicService {
    public static func generateMnemonic() -> String? {
        #if canImport(WalletCore)
        guard let wallet = HDWallet(strength: 128, passphrase: "") else {
            return nil
        }
        return wallet.mnemonic
        #else
        return nil // Or throw fatalError("WalletCore not available")
        #endif
    }

    public static func validate(mnemonic: String) -> Bool {
        #if canImport(WalletCore)
        return Mnemonic.isValid(mnemonic: mnemonic)
        #else
        return false
        #endif
    }
}

public enum HDWalletService {
    
    public enum Chain {
        case ethereum
        case bitcoin
        case solana
        
        #if canImport(WalletCore)
        var coinType: CoinType {
            switch self {
            case .ethereum: return .ethereum
            case .bitcoin: return .bitcoin
            case .solana: return .solana
            }
        }
        #endif
    }
    
    /// Derives BIP44 private key from mnemonic.
    public static func derivePrivateKey(mnemonic: String, for coin: Chain = .ethereum, accountIndex: UInt32 = 0) throws -> Data {
        guard MnemonicService.validate(mnemonic: mnemonic) else {
             throw WalletError.invalidMnemonic
        }
        
        #if canImport(WalletCore)
        guard let wallet = HDWallet(mnemonic: mnemonic, passphrase: "") else {
            throw WalletError.derivationFailed
        }
        
        // Derivation path standard: m/44'/coin_type'/account'/change/address_index
        // WalletCore defaults:
        // Ethereum: m/44'/60'/0'/0/0
        // Bitcoin: m/44'/0'/0'/0/0
        // Solana: m/44'/501'/0'/0' (Solana uses different path sometimes, but WalletCore handles defaults)
        
        let privateKey = wallet.getKeyForCoin(coin: coin.coinType)
        return privateKey.data
        #else
        throw WalletError.derivationFailed
        #endif
    }

    public static func address(from privateKeyData: Data, for coin: Chain = .ethereum) -> String {
        #if canImport(WalletCore)
        guard let privateKey = PrivateKey(data: privateKeyData) else {
            return ""
        }
        return coin.coinType.deriveAddress(privateKey: privateKey)
        #else
        return ""
        #endif
    }
}


// Mock storage for web3.swift integration (kept for legacy support where needed)
class MockKeyStorage: EthereumKeyStorageProtocol {
    private let key: Data

    init(key: Data) {
        self.key = key
    }

    func storePrivateKey(key _: Data) throws {}
    func loadPrivateKey() throws -> Data { key }
}

enum WalletError: Error, LocalizedError {
    case invalidMnemonic
    case derivationFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidMnemonic: return "Seed phrase invalid - double-check words."
        case .derivationFailed: return "Key generation failed."
        }
    }
}
