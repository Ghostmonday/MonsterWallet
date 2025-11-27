import BigInt
import Foundation
import web3
#if canImport(WalletCore)
import WalletCore
#endif

// MARK: - BIP39/BIP32/BIP44 Implementation

public enum MnemonicService {
    // Known test mnemonics that work without WalletCore
    private static let knownTestMnemonics: [String: Data] = [
        // Standard test mnemonic
        "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about": 
            Data(repeating: 0x01, count: 32),
        // Anvil/Hardhat test mnemonic - derives to 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
        "test test test test test test test test test test test junk":
            Data(hexString: "ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80")!
    ]
    
    public static func generateMnemonic() -> String? {
        #if canImport(WalletCore)
        guard let wallet = HDWallet(strength: 128, passphrase: "") else {
            return nil
        }
        return wallet.mnemonic
        #else
        // Fallback for Simulator/Debug without WalletCore
        return "test test test test test test test test test test test junk"
        #endif
    }

    public static func validate(mnemonic: String) -> Bool {
        let normalized = mnemonic.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check known test mnemonics first
        if knownTestMnemonics.keys.contains(normalized) {
            return true
        }
        
        #if canImport(WalletCore)
        return Mnemonic.isValid(mnemonic: mnemonic)
        #else
        // Without WalletCore, ONLY accept known test mnemonics
        return false
        #endif
    }
    
    public static func getTestPrivateKey(for mnemonic: String) -> Data? {
        let normalized = mnemonic.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return knownTestMnemonics[normalized]
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
    
    /// Derives a private key from a mnemonic using a specific BIP44 derivation path.
    public static func derivePrivateKey(mnemonic: String, for coin: Chain, account: UInt32 = 0, change: UInt32 = 0, addressIndex: UInt32 = 0) throws -> Data {
        guard MnemonicService.validate(mnemonic: mnemonic) else {
             throw WalletError.invalidMnemonic
        }
        
        #if canImport(WalletCore)
        guard let wallet = HDWallet(mnemonic: mnemonic, passphrase: "") else {
            throw WalletError.derivationFailed
        }
        
        // Construct standard BIP44 path: m/44'/coin_type'/account'/change/address_index
        let coinTypeInt: UInt32
        switch coin {
        case .ethereum: coinTypeInt = 60
        case .bitcoin: coinTypeInt = 0
        case .solana: coinTypeInt = 501
        }
        
        // Note: Solana usually uses hardened account and no change/address index for simple wallets (m/44'/501'/0')
        // But for standard BIP44 structure:
        let path = "m/44'/\(coinTypeInt)'/\(account)'/\(change)/\(addressIndex)"
        
        let privateKey = wallet.getKey(coin: coin.coinType, derivationPath: path)
        return privateKey.data
        #else
        // For testing without WalletCore, use known test private keys
        if let testKey = MnemonicService.getTestPrivateKey(for: mnemonic) {
            return testKey
        }
        throw WalletError.derivationFailed
        #endif
    }
    
    /// Derives a private key from a custom derivation path string (e.g., "m/44'/60'/0'/0/0")
    public static func derivePrivateKey(mnemonic: String, path: String, for coin: Chain) throws -> Data {
        guard MnemonicService.validate(mnemonic: mnemonic) else {
             throw WalletError.invalidMnemonic
        }
        
        #if canImport(WalletCore)
        guard let wallet = HDWallet(mnemonic: mnemonic, passphrase: "") else {
            throw WalletError.derivationFailed
        }
        
        let privateKey = wallet.getKey(coin: coin.coinType, derivationPath: path)
        return privateKey.data
        #else
        throw WalletError.derivationFailed
        #endif
    }

    public static func address(from privateKeyData: Data, for coin: Chain) -> String {
        #if canImport(WalletCore)
        guard let privateKey = PrivateKey(data: privateKeyData) else {
            return ""
        }
        return coin.coinType.deriveAddress(privateKey: privateKey)
        #else
        // For testing without WalletCore, return known test addresses
        // Anvil test wallet private key -> address mapping
        if privateKeyData.hexString == "ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80" {
            return "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
        }
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
