import XCTest
import BigInt
@testable import KryptoClaw
#if canImport(WalletCore)
import WalletCore
#endif

/// End-to-End validation tests for TransactionSigner
/// Tests the complete flow: mnemonic -> key derivation -> transaction signing -> output validation
@available(iOS 13.0, macOS 10.15, *)
final class TransactionSignerE2ETests: XCTestCase {
    
    // Standard test mnemonic (DO NOT USE IN PRODUCTION)
    // Generate a valid mnemonic using WalletCore for testing
    private var testMnemonic: String = ""
    
    private var mockKeyStore: TestableMockKeyStore!
    private var transactionSigner: TransactionSigner!
    
    override func setUp() {
        super.setUp()
        
        // Try to use WalletCore if available, otherwise use test mnemonic
        var walletCoreAvailable = false
        
        #if canImport(WalletCore)
        // Try to generate a mnemonic to check if WalletCore is actually available
        if let wallet = HDWallet(strength: 128, passphrase: "") {
            testMnemonic = wallet.mnemonic
            walletCoreAvailable = true
            
            // Verify the mnemonic is valid
            XCTAssertTrue(Mnemonic.isValid(mnemonic: testMnemonic), "Generated mnemonic should be valid")
        }
        #endif
        
        if !walletCoreAvailable {
            // Fallback test mnemonic (valid BIP39)
            testMnemonic = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about"
        }
        
        // Ensure mnemonic is not empty
        XCTAssertFalse(testMnemonic.isEmpty, "Test mnemonic should not be empty")
        
        mockKeyStore = TestableMockKeyStore()
        // Store the test mnemonic as UTF-8 data (as TransactionSigner expects)
        guard let mnemonicData = testMnemonic.data(using: .utf8) else {
            XCTFail("Failed to convert mnemonic to Data")
            return
        }
        
        do {
            _ = try mockKeyStore.storePrivateKey(key: mnemonicData, id: "primary_account")
        } catch {
            XCTFail("Failed to store mnemonic: \(error)")
            return
        }
        
        // Verify we can retrieve it correctly and it's valid
        do {
            let retrievedData = try mockKeyStore.getPrivateKey(id: "primary_account")
            guard let retrievedMnemonic = String(data: retrievedData, encoding: .utf8) else {
                XCTFail("Failed to decode retrieved mnemonic")
                return
            }
            XCTAssertEqual(retrievedMnemonic, testMnemonic, "Mnemonic should be stored and retrieved correctly")
            
            #if canImport(WalletCore)
            XCTAssertTrue(Mnemonic.isValid(mnemonic: retrievedMnemonic), "Retrieved mnemonic should be valid")
            #endif
        } catch {
            XCTFail("Failed to retrieve mnemonic: \(error)")
            return
        }
        
        transactionSigner = TransactionSigner(keyStore: mockKeyStore)
    }
    
    // MARK: - Ethereum E2E Tests
    
    func testMnemonicValidation() {
        // Debug test to verify mnemonic validation works
        #if canImport(WalletCore)
        guard let wallet = HDWallet(strength: 128, passphrase: "") else {
            XCTFail("Failed to generate test mnemonic")
            return
        }
        let mnemonic = wallet.mnemonic
        print("Generated mnemonic: \(mnemonic)")
        
        // Test validation
        let isValid = Mnemonic.isValid(mnemonic: mnemonic)
        XCTAssertTrue(isValid, "Generated mnemonic should be valid")
        
        // Test that we can create an HDWallet from it
        guard let testWallet = HDWallet(mnemonic: mnemonic, passphrase: "") else {
            XCTFail("Failed to create HDWallet from generated mnemonic")
            return
        }
        XCTAssertEqual(testWallet.mnemonic, mnemonic, "Mnemonic should match")
        
        // Test HDWalletService validation
        let serviceValid = MnemonicService.validate(mnemonic: mnemonic)
        XCTAssertTrue(serviceValid, "MnemonicService should validate the mnemonic")
        #endif
    }
    
    func testEthereumTransactionSigning_E2E() async throws {
        // Verify mnemonic is set up correctly
        XCTAssertFalse(testMnemonic.isEmpty, "Test mnemonic should be initialized")
        
        // Verify mnemonic can be retrieved from key store
        let retrievedData = try mockKeyStore.getPrivateKey(id: "primary_account")
        guard let retrievedMnemonic = String(data: retrievedData, encoding: .utf8) else {
            XCTFail("Failed to decode mnemonic from key store")
            return
        }
        
        // Verify mnemonic is valid
        #if canImport(WalletCore)
        XCTAssertTrue(Mnemonic.isValid(mnemonic: retrievedMnemonic), 
                     "Retrieved mnemonic should be valid: '\(retrievedMnemonic)'")
        #endif
        
        // Given: A valid Ethereum transaction payload
        let payload = TransactionPayload(
            coinType: .ethereum,
            toAddress: "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb",
            amount: BigInt(1000000000000000000), // 1 ETH in wei
            fee: BigInt(20000000000), // 20 gwei
            nonce: 0,
            data: nil,
            recentBlockhash: nil,
            utxos: nil
        )
        
        // When: Signing the transaction
        let signedTxHex = try await transactionSigner.sign(transaction: payload)
        
        // Then: Validate the output
        XCTAssertFalse(signedTxHex.isEmpty, "Signed transaction should not be empty")
        
        // Remove 0x prefix if present for validation
        let cleanHex = signedTxHex.hasPrefix("0x") ? String(signedTxHex.dropFirst(2)) : signedTxHex
        XCTAssertTrue(cleanHex.allSatisfy { $0.isHexDigit }, "Signed transaction should be valid hex")
        
        // Validate transaction structure (RLP-encoded Ethereum transaction)
        // A valid signed Ethereum transaction should be at least 100+ bytes when RLP encoded
        guard let txData = Data(hexString: cleanHex) else {
            XCTFail("Failed to parse signed transaction hex")
            return
        }
        XCTAssertGreaterThan(txData.count, 50, "Signed transaction should have reasonable length")
        
        print("✅ Ethereum E2E Test: Signed transaction hex = \(signedTxHex.prefix(50))...")
    }
    
    func testEthereumTransactionSigning_WithContractData_E2E() async throws {
        // Given: An Ethereum transaction with contract call data
        // Remove 0x prefix if present
        let hexString = "a9059cbb000000000000000000000000742d35cc6634c0532925a3b844bc9e7595f0beb0000000000000000000000000000000000000000000000000de0b6b3a7640000"
        guard let contractData = Data(hexString: hexString) else {
            XCTFail("Failed to create contract data from hex string")
            return
        }
        
        let payload = TransactionPayload(
            coinType: .ethereum,
            toAddress: "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb",
            amount: BigInt(0), // No ETH transfer, just contract call
            fee: BigInt(50000000000), // 50 gwei
            nonce: 1,
            data: contractData,
            recentBlockhash: nil,
            utxos: nil
        )
        
        // When: Signing the transaction
        let signedTxHex = try await transactionSigner.sign(transaction: payload)
        
        // Then: Validate the output
        XCTAssertFalse(signedTxHex.isEmpty, "Signed contract transaction should not be empty")
        
        // Remove 0x prefix if present for validation
        let cleanHex = signedTxHex.hasPrefix("0x") ? String(signedTxHex.dropFirst(2)) : signedTxHex
        XCTAssertTrue(cleanHex.allSatisfy { $0.isHexDigit }, "Signed transaction should be valid hex")
        
        guard let txData = Data(hexString: cleanHex) else {
            XCTFail("Failed to parse signed contract transaction hex")
            return
        }
        XCTAssertGreaterThan(txData.count, 50, "Signed contract transaction should include data")
        
        print("✅ Ethereum Contract E2E Test: Signed transaction hex = \(signedTxHex.prefix(50))...")
    }
    
    // MARK: - Bitcoin E2E Tests
    
    func testBitcoinTransactionSigning_E2E() async throws {
        // Given: A Bitcoin transaction with UTXOs
        let utxos = [
            UTXO(
                hash: "a1075db55d416d3ca199f55b6084e2115b9345e16c5cf302fc80e9d5fbf5d48d",
                index: 0,
                amount: 100000000, // 1 BTC in satoshis
                script: nil
            )
        ]
        
        let payload = TransactionPayload(
            coinType: .bitcoin,
            toAddress: "bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh",
            amount: BigInt(50000000), // 0.5 BTC
            fee: nil,
            nonce: nil,
            data: nil,
            recentBlockhash: nil,
            utxos: utxos
        )
        
        // When: Signing the transaction
        let signedTxHex = try await transactionSigner.sign(transaction: payload)
        
        // Then: Validate the output
        XCTAssertFalse(signedTxHex.isEmpty, "Signed Bitcoin transaction should not be empty")
        
        // Remove 0x prefix if present for validation
        let cleanHex = signedTxHex.hasPrefix("0x") ? String(signedTxHex.dropFirst(2)) : signedTxHex
        XCTAssertTrue(cleanHex.allSatisfy { $0.isHexDigit }, "Signed Bitcoin transaction should be valid hex")
        
        guard let txData = Data(hexString: cleanHex) else {
            XCTFail("Failed to parse signed Bitcoin transaction hex")
            return
        }
        XCTAssertGreaterThan(txData.count, 50, "Signed Bitcoin transaction should have reasonable length")
        
        print("✅ Bitcoin E2E Test: Signed transaction hex = \(signedTxHex.prefix(50))...")
    }
    
    // MARK: - Solana E2E Tests
    
    func testSolanaTransactionSigning_E2E() async throws {
        // Given: A Solana transaction with blockhash
        let recentBlockhash = "11111111111111111111111111111111" // Test blockhash
        
        let payload = TransactionPayload(
            coinType: .solana,
            toAddress: "9WzDXwBbmkg8ZTbNMqUxvQRAyrZzDsGYdLVL9zYtAWWM",
            amount: BigInt(1000000000), // 1 SOL in lamports
            fee: nil,
            nonce: nil,
            data: nil,
            recentBlockhash: recentBlockhash,
            utxos: nil
        )
        
        // When: Signing the transaction
        let signedTxBase64 = try await transactionSigner.sign(transaction: payload)
        
        // Then: Validate the output (Solana returns base64 encoded)
        XCTAssertFalse(signedTxBase64.isEmpty, "Signed Solana transaction should not be empty")
        
        // Solana transactions are base64 encoded, not hex
        // Verify it's valid base64
        let txData = Data(base64Encoded: signedTxBase64)
        XCTAssertNotNil(txData, "Solana transaction should be valid base64")
        XCTAssertGreaterThan(txData?.count ?? 0, 50, "Signed Solana transaction should have reasonable length")
        
        print("✅ Solana E2E Test: Signed transaction base64 = \(signedTxBase64.prefix(50))...")
    }
    
    // MARK: - Error Handling Tests
    
    func testEthereumTransactionSigning_MissingMnemonic() async throws {
        // Given: A key store without a mnemonic
        let emptyKeyStore = TestableMockKeyStore()
        let emptySigner = TransactionSigner(keyStore: emptyKeyStore)
        
        let payload = TransactionPayload(
            coinType: .ethereum,
            toAddress: "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb",
            amount: BigInt(1000000000000000000),
            fee: BigInt(20000000000),
            nonce: 0,
            data: nil,
            recentBlockhash: nil,
            utxos: nil
        )
        
        // When/Then: Should throw an error
        do {
            _ = try await emptySigner.sign(transaction: payload)
            XCTFail("Should have thrown an error for missing mnemonic")
        } catch {
            // Expected error
            print("✅ Error handling test: Correctly caught error - \(error)")
        }
    }
    
    func testBitcoinTransactionSigning_MissingUTXOs() async throws {
        // Given: A Bitcoin transaction without UTXOs
        let payload = TransactionPayload(
            coinType: .bitcoin,
            toAddress: "bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh",
            amount: BigInt(50000000),
            fee: nil,
            nonce: nil,
            data: nil,
            recentBlockhash: nil,
            utxos: nil // Missing UTXOs
        )
        
        // When/Then: Should throw an error
        do {
            _ = try await transactionSigner.sign(transaction: payload)
            XCTFail("Should have thrown an error for missing UTXOs")
        } catch {
            // Check if it's a BlockchainError.rpcError which contains the message
            if let blockchainError = error as? BlockchainError,
               case .rpcError(let message) = blockchainError {
                let errorDesc = message.lowercased()
                XCTAssertTrue(errorDesc.contains("utxo") || 
                             errorDesc.contains("missing"),
                             "Error should mention UTXOs. Got: \(message)")
            } else {
                // For other error types, just verify we got an error
                XCTAssertNotNil(error, "Should have thrown an error for missing UTXOs")
            }
            print("✅ Error handling test: Correctly caught error - \(error)")
        }
    }
    
    func testSolanaTransactionSigning_MissingBlockhash() async throws {
        // Given: A Solana transaction without blockhash
        let payload = TransactionPayload(
            coinType: .solana,
            toAddress: "9WzDXwBbmkg8ZTbNMqUxvQRAyrZzDsGYdLVL9zYtAWWM",
            amount: BigInt(1000000000),
            fee: nil,
            nonce: nil,
            data: nil,
            recentBlockhash: nil, // Missing blockhash
            utxos: nil
        )
        
        // When/Then: Should throw an error
        do {
            _ = try await transactionSigner.sign(transaction: payload)
            XCTFail("Should have thrown an error for missing blockhash")
        } catch {
            // Check if it's a BlockchainError.rpcError which contains the message
            if let blockchainError = error as? BlockchainError,
               case .rpcError(let message) = blockchainError {
                let errorDesc = message.lowercased()
                XCTAssertTrue(errorDesc.contains("blockhash") || 
                             errorDesc.contains("missing"),
                             "Error should mention blockhash. Got: \(message)")
            } else {
                // For other error types, just verify we got an error
                XCTAssertNotNil(error, "Should have thrown an error for missing blockhash")
            }
            print("✅ Error handling test: Correctly caught error - \(error)")
        }
    }
}

// MARK: - Test Helper: Enhanced Mock KeyStore

/// A testable mock key store that can store and retrieve mnemonics
class TestableMockKeyStore: KeyStoreProtocol {
    private var storage: [String: Data] = [:]
    
    func storePrivateKey(key: Data, id: String) throws -> Bool {
        storage[id] = key
        return true
    }
    
    func getPrivateKey(id: String) throws -> Data {
        guard let data = storage[id] else {
            throw KeyStoreError.itemNotFound
        }
        return data
    }
    
    func deleteKey(id: String) throws {
        storage.removeValue(forKey: id)
    }
    
    func deleteAll() throws {
        storage.removeAll()
    }
    
    func isProtected() -> Bool {
        return true
    }
}

// MARK: - Helper Extensions

extension Character {
    var isHexDigit: Bool {
        return ("0"..."9").contains(self) || ("a"..."f").contains(self) || ("A"..."F").contains(self)
    }
}

extension String {
    var isHexString: Bool {
        let hexString = hasPrefix("0x") ? String(dropFirst(2)) : self
        return !hexString.isEmpty && hexString.allSatisfy { $0.isHexDigit }
    }
}

