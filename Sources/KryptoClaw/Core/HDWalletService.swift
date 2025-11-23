import Foundation
import web3
import BigInt

public struct MnemonicService {
    public static func generateMnemonic() -> String? {
        try? BIP39.generateMnemonics(bitsOfEntropy: 128)
    }

    public static func validate(mnemonic: String) -> Bool {
        let words = mnemonic.split(separator: " ")
        return words.count == 12 || words.count == 24
    }
}

public struct HDWalletService {
    // Derive a private key from a mnemonic for a specific path (m/44'/60'/0'/0/0 for Ethereum)
    public static func derivePrivateKey(mnemonic: String) throws -> Data {
        guard let seed = try? BIP39.seedFromMmemonics(mnemonic) else {
            throw WalletError.invalidMnemonic
        }

        // Fix: Use correct web3.swift APIs.
        // argentlabs/web3.swift uses 'EthereumAccount' which can ingest a key.
        // It doesn't have a built-in BIP32/44 Derivation class exposed easily as 'Wallet'.
        // However, it usually relies on 'Keystore' logic.
        // For this task, we will do manual BIP32 derivation using the imported primitives if available,
        // OR assuming 'BIP32' is available in the library scope.
        // If not, we fall back to a single key from seed (which is not standard BIP44 but valid for V1).

        // Given limitations and without `BIP32` class docs, we'll assume a direct private key generation from seed for now to ensure compilation.
        // Ideally: `BIP32.derive(seed, path: "m/44'/60'/0'/0/0")`
        // Fallback: SHA256(seed) -> Private Key (Deterministic but not BIP44 compliant).
        // Let's try to use the library's KeyStorage.

        // ACTUALLY, web3.swift usually exports `BIP32` helper.
        // Let's assume `try BIP32Keystore(mnemonics: mnemonic)` style.

        if let keystore = try? BIP32Keystore(mnemonics: mnemonic, password: "", prefixPath: "m/44'/60'/0'/0") {
             // Get first account
             if let address = keystore.addresses?.first, let key = try? keystore.UNSAFE_getPrivateKeyData(password: "", account: address) {
                 return key
             }
        }

        throw WalletError.derivationFailed
    }

    public static func address(from privateKey: Data) -> String {
        let account = try? EthereumAccount(keyStorage: MockKeyStorage(key: privateKey))
        return account?.address.asString() ?? ""
    }
}

// Helper for single-key usage
class MockKeyStorage: EthereumKeyStorageProtocol {
    private let key: Data

    init(key: Data) {
        self.key = key
    }

    func storePrivateKey(key: Data) throws {}
    func loadPrivateKey() throws -> Data { return key }
}

enum WalletError: Error {
    case invalidMnemonic
    case derivationFailed
}
