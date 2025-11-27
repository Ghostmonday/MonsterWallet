// MODULE: E2ETestRunner
// VERSION: 1.0.0
// PURPOSE: Test runner and utilities for E2E test execution

import XCTest
@testable import KryptoClaw

/// Test runner that executes all E2E tests and generates a report
@available(iOS 13.0, macOS 10.15, *)
final class E2ETestRunner {
    
    /// Run all E2E tests and generate a summary report
    static func runAllTests() async throws {
        print("\n" + "=".repeating(60))
        print("🧪 KRYPTOCLAW E2E TEST SUITE")
        print("=".repeating(60) + "\n")
        
        let testSuite = WalletE2ETests()
        try testSuite.setUp()
        
        var passed = 0
        var failed = 0
        var results: [(String, Bool, String?)] = []
        
        // Test 1: Wallet Creation
        do {
            print("Running: Wallet Creation Flow...")
            await testSuite.testE2E_WalletCreationFlow()
            passed += 1
            results.append(("Wallet Creation", true, nil))
            print("✅ PASSED\n")
        } catch {
            failed += 1
            results.append(("Wallet Creation", false, "\(error)"))
            print("❌ FAILED: \(error)\n")
        }
        
        // Test 2: Wallet Import
        do {
            print("Running: Wallet Import Flow...")
            await testSuite.testE2E_WalletImportFlow()
            passed += 1
            results.append(("Wallet Import", true, nil))
            print("✅ PASSED\n")
        } catch {
            failed += 1
            results.append(("Wallet Import", false, "\(error)"))
            print("❌ FAILED: \(error)\n")
        }
        
        // Test 3: Multi-Chain Balance Fetching
        do {
            print("Running: Multi-Chain Balance Fetching...")
            await testSuite.testE2E_MultiChainBalanceFetching()
            passed += 1
            results.append(("Multi-Chain Balances", true, nil))
            print("✅ PASSED\n")
        } catch {
            failed += 1
            results.append(("Multi-Chain Balances", false, "\(error)"))
            print("❌ FAILED: \(error)\n")
        }
        
        // Test 4: Complete Transaction Flow
        do {
            print("Running: Complete Transaction Flow...")
            await testSuite.testE2E_CompleteTransactionFlow()
            passed += 1
            results.append(("Transaction Flow", true, nil))
            print("✅ PASSED\n")
        } catch {
            failed += 1
            results.append(("Transaction Flow", false, "\(error)"))
            print("❌ FAILED: \(error)\n")
        }
        
        // Test 5: Contract Transaction
        do {
            print("Running: Contract Transaction...")
            await testSuite.testE2E_TransactionWithContractData()
            passed += 1
            results.append(("Contract Transaction", true, nil))
            print("✅ PASSED\n")
        } catch {
            failed += 1
            results.append(("Contract Transaction", false, "\(error)"))
            print("❌ FAILED: \(error)\n")
        }
        
        // Test 6: Error Handling
        do {
            print("Running: Error Handling (Insufficient Funds)...")
            await testSuite.testE2E_ErrorHandling_InsufficientFunds()
            passed += 1
            results.append(("Error Handling", true, nil))
            print("✅ PASSED\n")
        } catch {
            failed += 1
            results.append(("Error Handling", false, "\(error)"))
            print("❌ FAILED: \(error)\n")
        }
        
        // Test 7: Wallet Switching
        do {
            print("Running: Wallet Switching...")
            await testSuite.testE2E_WalletSwitching()
            passed += 1
            results.append(("Wallet Switching", true, nil))
            print("✅ PASSED\n")
        } catch {
            failed += 1
            results.append(("Wallet Switching", false, "\(error)"))
            print("❌ FAILED: \(error)\n")
        }
        
        // Test 8: Wallet Deletion
        do {
            print("Running: Wallet Deletion...")
            await testSuite.testE2E_WalletDeletion()
            passed += 1
            results.append(("Wallet Deletion", true, nil))
            print("✅ PASSED\n")
        } catch {
            failed += 1
            results.append(("Wallet Deletion", false, "\(error)"))
            print("❌ FAILED: \(error)\n")
        }
        
        // Test 9: Balance Refresh After Transaction
        do {
            print("Running: Balance Refresh After Transaction...")
            await testSuite.testE2E_BalanceRefreshAfterTransaction()
            passed += 1
            results.append(("Balance Refresh", true, nil))
            print("✅ PASSED\n")
        } catch {
            failed += 1
            results.append(("Balance Refresh", false, "\(error)"))
            print("❌ FAILED: \(error)\n")
        }
        
        // Test 10: Transaction History
        do {
            print("Running: Transaction History...")
            await testSuite.testE2E_TransactionHistory()
            passed += 1
            results.append(("Transaction History", true, nil))
            print("✅ PASSED\n")
        } catch {
            failed += 1
            results.append(("Transaction History", false, "\(error)"))
            print("❌ FAILED: \(error)\n")
        }
        
        testSuite.tearDown()
        
        // Print summary
        print("\n" + "=".repeating(60))
        print("📊 E2E TEST SUMMARY")
        print("=".repeating(60))
        print("Total Tests: \(passed + failed)")
        print("✅ Passed: \(passed)")
        print("❌ Failed: \(failed)")
        print("\nDetailed Results:")
        print("-".repeating(60))
        
        for (name, success, error) in results {
            let status = success ? "✅ PASS" : "❌ FAIL"
            print("\(status) - \(name)")
            if let error = error {
                print("   Error: \(error)")
            }
        }
        
        print("=".repeating(60) + "\n")
    }
}

extension String {
    func repeating(_ count: Int) -> String {
        return String(repeating: self, count: count)
    }
}

