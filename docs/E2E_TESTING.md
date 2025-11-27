# 🧪 E2E Testing Guide

Comprehensive end-to-end testing suite for KryptoClaw wallet.

## Overview

The E2E test suite validates complete user journeys from wallet creation to transaction execution, ensuring all components work together correctly.

## Test Structure

### Test Files

- **`WalletE2ETests.swift`** - Main E2E test suite covering:
  - Wallet creation and import flows
  - Multi-chain balance fetching
  - Complete transaction flows (simple and contract)
  - Error handling scenarios
  - Wallet management (switching, deletion)
  - Balance refresh after transactions
  - Transaction history

- **`TransactionSignerE2ETests.swift`** - Transaction signing E2E tests for:
  - Ethereum transaction signing
  - Bitcoin transaction signing
  - Solana transaction signing
  - Error handling for missing parameters

## Running E2E Tests

### Via Xcode

1. Open `KryptoClaw.xcodeproj`
2. Select the `KryptoClawTests` scheme
3. Press `Cmd+U` to run all tests
4. Or run specific test classes:
   - `WalletE2ETests`
   - `TransactionSignerE2ETests`

### Via Command Line

```bash
# Run all tests
swift test

# Run specific test class
swift test --filter WalletE2ETests

# Run specific test
swift test --filter WalletE2ETests.testE2E_CompleteTransactionFlow
```

### Via Test Runner

```swift
// In a test file or playground
await E2ETestRunner.runAllTests()
```

## Test Coverage

### ✅ Wallet Lifecycle
- [x] Wallet creation with mnemonic generation
- [x] Wallet import with existing mnemonic
- [x] Wallet switching between multiple wallets
- [x] Wallet deletion with automatic switching

### ✅ Balance Operations
- [x] Single-chain balance fetching
- [x] Multi-chain parallel balance fetching
- [x] Balance refresh after transactions
- [x] Balance display formatting

### ✅ Transaction Flow
- [x] Simple ETH transfer
- [x] Contract interaction (ERC-20 transfer)
- [x] Transaction simulation
- [x] Transaction signing
- [x] Transaction broadcasting
- [x] Transaction history fetching

### ✅ Error Handling
- [x] Insufficient funds detection
- [x] Invalid address handling
- [x] Missing transaction parameters
- [x] Network error recovery

### ✅ Multi-Chain Support
- [x] Ethereum (ETH)
- [x] Bitcoin (BTC)
- [x] Solana (SOL)

## Mock Providers

The E2E tests use enhanced mock providers that simulate real blockchain behavior:

### `EnhancedMockBlockchainProvider`
- Configurable balances per address/chain
- Transaction history management
- Network delay simulation
- Realistic error responses

### `EnhancedMockSigner`
- Transaction signing simulation
- Signature generation
- Signing operation tracking

### `EnhancedMockRouter`
- Gas estimation
- Nonce management
- Transaction count tracking

## Test Data

### Test Mnemonics

**⚠️ WARNING: These are TEST-ONLY mnemonics. NEVER use in production!**

- **Anvil/Hardhat Default**: `test test test test test test test test test test test junk`
  - Derives to: `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266`
  
- **BIP39 Test**: `abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about`

### Test Addresses

- **Ethereum**: `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266`
- **Bitcoin**: `bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh`
- **Solana**: `9WzDXwBbmkg8ZTbNMqUxvQRAyrZzDsGYdLVL9zYtAWWM`

## Writing New E2E Tests

### Template

```swift
func testE2E_YourTestName() async {
    print("\n🧪 E2E Test: Your Test Name")
    
    // Setup
    let testMnemonic = "test test test test test test test test test test test junk"
    await walletStateManager.importWallet(mnemonic: testMnemonic)
    await walletStateManager.loadAccount(id: testEthereumAddress)
    
    // Configure mocks
    mockProvider.setBalance(address: testEthereumAddress, chain: .ethereum, amount: "5.0")
    
    // Execute
    // ... your test steps ...
    
    // Verify
    XCTAssertTrue(condition, "Description")
    print("✅ Test completed successfully")
}
```

### Best Practices

1. **Use descriptive test names**: `testE2E_WhatYouAreTesting`
2. **Print progress**: Use `print()` statements to track test execution
3. **Clean setup/teardown**: Ensure tests don't interfere with each other
4. **Verify state**: Check both success and error states
5. **Test edge cases**: Include error scenarios, not just happy paths

## Continuous Integration

E2E tests run automatically on:
- Pull requests
- Commits to `main` branch
- Nightly builds

### CI Configuration

```yaml
# Example GitHub Actions
- name: Run E2E Tests
  run: |
    swift test --filter WalletE2ETests
    swift test --filter TransactionSignerE2ETests
```

## Troubleshooting

### Tests Failing Locally

1. **Check WalletCore availability**: Some tests require WalletCore
   ```swift
   #if canImport(WalletCore)
   // WalletCore-specific tests
   #endif
   ```

2. **Verify test data**: Ensure test mnemonics and addresses are correct

3. **Check mock configuration**: Verify mock providers are set up correctly

4. **Review async/await**: Ensure all async operations are properly awaited

### Common Issues

- **Balance not updating**: Check mock provider balance configuration
- **Transaction failing**: Verify nonce and gas estimation
- **State not loading**: Check address format and chain configuration

## Performance

E2E tests include realistic network delays:
- Balance fetch: 50ms
- History fetch: 100ms
- Transaction broadcast: 200ms

Total test suite execution time: ~2-3 seconds

## Future Enhancements

- [ ] UI automation tests with XCUITest
- [ ] Integration with real testnet nodes
- [ ] Performance benchmarking
- [ ] Load testing with multiple concurrent operations
- [ ] Security testing (address poisoning, etc.)

## Related Documentation

- [Unit Testing Guide](../Tests/README.md)
- [Mock Providers Documentation](../Tests/KryptoClawTests/MockProviders.swift)
- [Transaction Signing Tests](../Tests/KryptoClawTests/TransactionSignerE2ETests.swift)

