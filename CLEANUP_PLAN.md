# REPOSITORY CLEANUP PLAN
# Generated: 2025-11-25
# Status: REVIEW ONLY - DO NOT EXECUTE YET

## EXECUTIVE SUMMARY

**Scope:** 38 files to move, 100+ import statements to update
**Risk Level:** LOW (no logic changes, only structural)
**Estimated Impact:** 18 directories, 99 Swift files affected
**Validation:** Full compilation required after each phase

---

## PHASE 1: CREATE NEW DIRECTORY STRUCTURE

### New Directories to Create:
```bash
mkdir -p Sources/KryptoClaw/Core/Protocols
mkdir -p Sources/KryptoClaw/Core/Providers  
mkdir -p Sources/KryptoClaw/Core/Recovery
mkdir -p Sources/KryptoClaw/UI/Views
```

**Rationale:**
- `Core/Protocols/` - Centralize all protocol definitions
- `Core/Providers/` - Separate HTTP/API provider implementations
- `Core/Recovery/` - Group wallet recovery logic
- `UI/Views/` - Main feature views (not components/sheets)

**Files Affected:** 0 (additive only)
**Risk:** NONE

---

## PHASE 2: MOVE PROTOCOL FILES (5 files)

### 2.1 BlockchainProviderProtocol.swift
```diff
- Sources/KryptoClaw/BlockchainProviderProtocol.swift
+ Sources/KryptoClaw/Core/Protocols/BlockchainProviderProtocol.swift
```

**Import Updates Required:**
- `MultiChainProvider.swift`
- `WalletStateManager.swift`
- `WalletCoreManager.swift`
- `BlockchainProviderTests.swift`

### 2.2 KeyStoreProtocol.swift
```diff
- Sources/KryptoClaw/KeyStoreProtocol.swift
+ Sources/KryptoClaw/Core/Protocols/KeyStoreProtocol.swift
```

**Import Updates Required:**
- `SecureEnclaveKeyStore.swift`
- `KeyStoreTests.swift`

### 2.3 NFTProviderProtocol.swift
```diff
- Sources/KryptoClaw/NFTProviderProtocol.swift
+ Sources/KryptoClaw/Core/Protocols/NFTProviderProtocol.swift
```

**Import Updates Required:**
- `HTTPNFTProvider.swift`
- `NFTGalleryView.swift`

### 2.4 RecoveryStrategyProtocol.swift
```diff
- Sources/KryptoClaw/RecoveryStrategyProtocol.swift
+ Sources/KryptoClaw/Core/Protocols/RecoveryStrategyProtocol.swift
```

**Import Updates Required:**
- `ShamirHybridRecovery.swift`
- `RecoveryView.swift`
- `RecoveryTests.swift`

### 2.5 SignerProtocol.swift
```diff
- Sources/KryptoClaw/SignerProtocol.swift
+ Sources/KryptoClaw/Core/Protocols/SignerProtocol.swift
```

**Import Updates Required:**
- `SimpleP2PSigner.swift`
- `TransactionSigner.swift`
- `SignerTests.swift`

**Phase 2 Risk Assessment:** LOW
**Validation:** Compile after moving all 5 files

---

## PHASE 3: MOVE PROVIDER FILES (2 files)

### 3.1 HTTPNFTProvider.swift
```diff
- Sources/KryptoClaw/HTTPNFTProvider.swift
+ Sources/KryptoClaw/Core/Providers/HTTPNFTProvider.swift
```

**Import Updates Required:**
- `NFTGalleryView.swift`

### 3.2 ModularHTTPProvider.swift
```diff
- Sources/KryptoClaw/ModularHTTPProvider.swift
+ Sources/KryptoClaw/Core/Providers/ModularHTTPProvider.swift
```

**Import Updates Required:**
- `MultiChainProvider.swift`
- `WalletStateManager.swift`

**Phase 3 Risk Assessment:** LOW
**Validation:** Compile after moving both files

---

## PHASE 4: MOVE MODEL FILES (3 files)

### 4.1 Contact.swift
```diff
- Sources/KryptoClaw/Contact.swift
+ Sources/KryptoClaw/Core/Models/Contact.swift
```

**Import Updates Required:**
- `AddressBookView.swift`
- `ModelsTests.swift`

### 4.2 WalletInfo.swift
```diff
- Sources/KryptoClaw/WalletInfo.swift
+ Sources/KryptoClaw/Core/Models/WalletInfo.swift
```

**Import Updates Required:**
- `WalletStateManager.swift`
- `WalletManagementView.swift`
- `ModelsTests.swift`

### 4.3 NFTModels.swift
```diff
- Sources/KryptoClaw/NFTModels.swift
+ Sources/KryptoClaw/Core/Models/NFTModels.swift
```

**Import Updates Required:**
- `NFTGalleryView.swift`
- `HTTPNFTProvider.swift`
- `ModelsTests.swift`

**Phase 4 Risk Assessment:** LOW
**Validation:** Compile after moving all 3 files

---

## PHASE 5: MOVE SERVICE FILES (4 files)

### 5.1 ErrorTranslator.swift
```diff
- Sources/KryptoClaw/ErrorTranslator.swift
+ Sources/KryptoClaw/Core/Services/ErrorTranslator.swift
```

**Import Updates Required:**
- `WalletStateManager.swift`
- `TransactionSigner.swift`
- `ErrorTranslatorTests.swift`

### 5.2 Logger.swift
```diff
- Sources/KryptoClaw/Logger.swift
+ Sources/KryptoClaw/Core/Services/Logger.swift
```

**Import Updates Required:**
- Multiple files use KryptoLogger.shared
- Search for "import.*Logger" or "KryptoLogger"

### 5.3 Telemetry.swift
```diff
- Sources/KryptoClaw/Telemetry.swift
+ Sources/KryptoClaw/Core/Services/Telemetry.swift
```

**Import Updates Required:**
- `WalletStateManager.swift`
- `TransactionSigner.swift`
- All modules using Telemetry.shared

### 5.4 LocalSimulator.swift
```diff
- Sources/KryptoClaw/LocalSimulator.swift
+ Sources/KryptoClaw/Core/Services/LocalSimulator.swift
```

**Import Updates Required:**
- `SimulationDemo.swift` (test file)

**Phase 5 Risk Assessment:** MEDIUM (Logger/Telemetry used widely)
**Validation:** Compile + run tests after each file

---

## PHASE 6: MOVE TRANSACTION FILES (3 files)

### 6.1 BasicGasRouter.swift
```diff
- Sources/KryptoClaw/BasicGasRouter.swift
+ Sources/KryptoClaw/Core/Transaction/BasicGasRouter.swift
```

**Import Updates Required:**
- `TransactionSigner.swift`
- `WalletStateManager.swift`

### 6.2 BasicHeuristicAnalyzer.swift
```diff
- Sources/KryptoClaw/BasicHeuristicAnalyzer.swift
+ Sources/KryptoClaw/Core/Transaction/BasicHeuristicAnalyzer.swift
```

**Import Updates Required:**
- `TransactionSigner.swift`

### 6.3 TransactionProtocols.swift
```diff
- Sources/KryptoClaw/TransactionProtocols.swift
+ Sources/KryptoClaw/Core/Transaction/TransactionProtocols.swift
```

**Import Updates Required:**
- `TransactionSigner.swift`
- `TxPreviewViewModel.swift`
- `TransactionEngineTests.swift`

**Phase 6 Risk Assessment:** LOW
**Validation:** Compile after moving all 3 files

---

## PHASE 7: MOVE RECOVERY FILES (2 files)

### 7.1 ShamirHybridRecovery.swift
```diff
- Sources/KryptoClaw/ShamirHybridRecovery.swift
+ Sources/KryptoClaw/Core/Recovery/ShamirHybridRecovery.swift
```

**Import Updates Required:**
- `RecoveryView.swift`
- `RecoveryTests.swift`

### 7.2 SimpleP2PSigner.swift
```diff
- Sources/KryptoClaw/SimpleP2PSigner.swift
+ Sources/KryptoClaw/Core/Recovery/SimpleP2PSigner.swift
```

**Import Updates Required:**
- `RecoveryView.swift`
- `SignerTests.swift`

**Phase 7 Risk Assessment:** LOW
**Validation:** Compile after moving both files

---

## PHASE 8: MOVE SECURITY FILES (3 files)

### 8.1 KeychainHelper.swift
```diff
- Sources/KryptoClaw/KeychainHelper.swift
+ Sources/KryptoClaw/Core/Security/KeychainHelper.swift
```

**Import Updates Required:**
- Check for usage across codebase
- **NOTE:** May be duplicate of KeychainVault - needs merge analysis

### 8.2 LocalAuthenticationWrapper.swift
```diff
- Sources/KryptoClaw/LocalAuthenticationWrapper.swift
+ Sources/KryptoClaw/Core/Security/LocalAuthenticationWrapper.swift
```

**Import Updates Required:**
- Check for usage
- **NOTE:** May be duplicate of BiometricAuthManager - needs merge analysis

### 8.3 SecureEnclaveKeyStore.swift
```diff
- Sources/KryptoClaw/SecureEnclaveKeyStore.swift
+ Sources/KryptoClaw/Core/Security/SecureEnclaveKeyStore.swift
```

**Import Updates Required:**
- Check for usage
- **NOTE:** May be duplicate of SecureEnclaveInterface - needs merge analysis

**Phase 8 Risk Assessment:** HIGH (potential duplicates, crypto code)
**Validation:** Review code before moving, compile + security tests after

---

## PHASE 9: MOVE UI VIEW FILES (11 files)

### 9.1 AddressBookView.swift
```diff
- Sources/KryptoClaw/AddressBookView.swift
+ Sources/KryptoClaw/UI/Views/AddressBookView.swift
```

### 9.2 ChainDetailView.swift
```diff
- Sources/KryptoClaw/ChainDetailView.swift
+ Sources/KryptoClaw/UI/Views/ChainDetailView.swift
```

### 9.3 HistoryView.swift
```diff
- Sources/KryptoClaw/HistoryView.swift
+ Sources/KryptoClaw/UI/Views/HistoryView.swift
```

### 9.4 HomeView.swift
```diff
- Sources/KryptoClaw/HomeView.swift
+ Sources/KryptoClaw/UI/Views/HomeView.swift
```

### 9.5 NFTGalleryView.swift
```diff
- Sources/KryptoClaw/NFTGalleryView.swift
+ Sources/KryptoClaw/UI/Views/NFTGalleryView.swift
```

### 9.6 OnboardingView.swift
```diff
- Sources/KryptoClaw/OnboardingView.swift
+ Sources/KryptoClaw/UI/Views/OnboardingView.swift
```

### 9.7 RecoveryView.swift
```diff
- Sources/KryptoClaw/RecoveryView.swift
+ Sources/KryptoClaw/UI/Views/RecoveryView.swift
```

### 9.8 SendView.swift
```diff
- Sources/KryptoClaw/SendView.swift
+ Sources/KryptoClaw/UI/Views/SendView.swift
```

### 9.9 SettingsView.swift
```diff
- Sources/KryptoClaw/SettingsView.swift
+ Sources/KryptoClaw/UI/Views/SettingsView.swift
```

### 9.10 WalletManagementView.swift
```diff
- Sources/KryptoClaw/WalletManagementView.swift
+ Sources/KryptoClaw/UI/Views/WalletManagementView.swift
```

**Import Updates Required:**
- `KryptoClawApp.swift` (root navigation)
- `RootCoordinatorView.swift`
- `Router.swift`
- `HomeView.swift` (navigation targets)
- `ComponentTests.swift`

**Phase 9 Risk Assessment:** MEDIUM (many navigation references)
**Validation:** Compile + run app to verify navigation

---

## PHASE 10: MOVE UI COMPONENT FILES (2 files)

### 10.1 UIComponents.swift
```diff
- Sources/KryptoClaw/UIComponents.swift
+ Sources/KryptoClaw/UI/Components/UIComponents.swift
```

**Import Updates Required:**
- All view files using KryptoButton, KryptoCard, etc.
- Search for "KryptoButton", "KryptoCard", "KryptoTextField"

### 10.2 ThemeViewModifiers.swift
```diff
- Sources/KryptoClaw/ThemeViewModifiers.swift
+ Sources/KryptoClaw/UI/Components/ThemeViewModifiers.swift
```

**Import Updates Required:**
- All views using .themedContainer, .themedCard, etc.
- Search for ".themedContainer", ".themedCard"

**Phase 10 Risk Assessment:** HIGH (UI components used everywhere)
**Validation:** Compile + visual testing

---

## PHASE 11: MOVE ROOT CONFIG FILE (1 file)

### 11.1 AppConfig.swift
```diff
- Sources/KryptoClaw/AppConfig.swift
+ Sources/KryptoClaw/Core/AppConfig.swift
```

**Import Updates Required:**
- `KryptoClawApp.swift`
- Any file referencing app configuration

**Phase 11 Risk Assessment:** LOW
**Validation:** Compile

---

## IMPORT UPDATE SUMMARY

### Files Requiring Import Updates (Estimated):

**Category A: High Priority (Navigation/Core)**
- `KryptoClawApp.swift` - 11 imports to update
- `RootCoordinatorView.swift` - 8 imports to update
- `Router.swift` - 8 imports to update
- `WalletStateManager.swift` - 15 imports to update
- `WalletCoreManager.swift` - 5 imports to update

**Category B: Medium Priority (Views)**
- All view files in `UI/Views/` - 3-5 imports each
- Total: ~40 import updates

**Category C: Low Priority (Tests)**
- All test files - 2-3 imports each
- Total: ~20 import updates

**Total Estimated Import Updates: 75-100**

---

## DUPLICATE CODE ANALYSIS

### Files to Analyze for Merging:

#### 1. KeychainHelper.swift vs KeychainVault.swift
**Location:**
- Current: `Sources/KryptoClaw/KeychainHelper.swift`
- Existing: `Sources/KryptoClaw/Core/Security/KeychainVault.swift`

**Analysis Required:**
```bash
# Compare implementations
diff KeychainHelper.swift Core/Security/KeychainVault.swift

# Search for usage
grep -r "KeychainHelper" Sources/
grep -r "KeychainVault" Sources/
```

**Recommendation:** 
- If KeychainHelper is a thin wrapper → merge into KeychainVault
- If different purposes → rename and keep separate

#### 2. LocalAuthenticationWrapper.swift vs BiometricAuthManager.swift
**Location:**
- Current: `Sources/KryptoClaw/LocalAuthenticationWrapper.swift`
- Existing: `Sources/KryptoClaw/Core/Security/BiometricAuthManager.swift`

**Analysis Required:**
```bash
diff LocalAuthenticationWrapper.swift Core/Security/BiometricAuthManager.swift
grep -r "LocalAuthenticationWrapper" Sources/
grep -r "BiometricAuthManager" Sources/
```

**Recommendation:**
- Likely duplicates → merge into BiometricAuthManager
- Keep better implementation

#### 3. SecureEnclaveKeyStore.swift vs SecureEnclaveInterface.swift
**Location:**
- Current: `Sources/KryptoClaw/SecureEnclaveKeyStore.swift`
- Existing: `Sources/KryptoClaw/Core/HSK/SecureEnclaveInterface.swift`

**Analysis Required:**
```bash
diff SecureEnclaveKeyStore.swift Core/HSK/SecureEnclaveInterface.swift
grep -r "SecureEnclaveKeyStore" Sources/
grep -r "SecureEnclaveInterface" Sources/
```

**Recommendation:**
- If KeyStore implements Interface → keep separate
- If both do same thing → merge

---

## VALIDATION CHECKLIST

### After Each Phase:
- [ ] Run `swift build --build-tests`
- [ ] Check for compilation errors
- [ ] Review import statements
- [ ] Verify no circular dependencies

### After All Phases:
- [ ] Run full test suite: `swift test`
- [ ] Launch app and test navigation
- [ ] Verify theme system still works
- [ ] Check SwiftUI previews
- [ ] Run security tests
- [ ] Test transaction flows
- [ ] Verify HSK flows

---

## RISK MITIGATION STRATEGY

### High-Risk Areas:
1. **Security Files** (Phase 8)
   - Create backup before moving
   - Test cryptographic operations
   - Verify keychain access

2. **UI Components** (Phase 10)
   - UI components used in 50+ files
   - Visual testing required
   - Check theme integration

3. **Service Files** (Phase 5)
   - Logger/Telemetry used globally
   - Check singleton access patterns
   - Verify no breaking changes

### Safety Measures:
1. **One phase at a time**
2. **Compile between phases**
3. **Git checkpoint after each successful phase**
4. **Keep rollback plan ready**

---

## EXECUTION COMMANDS (DO NOT RUN YET)

### Phase 1: Create Directories
```bash
cd Sources/KryptoClaw
mkdir -p Core/Protocols
mkdir -p Core/Providers
mkdir -p Core/Recovery
mkdir -p UI/Views
```

### Phase 2: Move Protocols
```bash
git mv BlockchainProviderProtocol.swift Core/Protocols/
git mv KeyStoreProtocol.swift Core/Protocols/
git mv NFTProviderProtocol.swift Core/Protocols/
git mv RecoveryStrategyProtocol.swift Core/Protocols/
git mv SignerProtocol.swift Core/Protocols/
```

### Phase 3: Move Providers
```bash
git mv HTTPNFTProvider.swift Core/Providers/
git mv ModularHTTPProvider.swift Core/Providers/
```

### Phase 4: Move Models
```bash
git mv Contact.swift Core/Models/
git mv WalletInfo.swift Core/Models/
git mv NFTModels.swift Core/Models/
```

### Phase 5: Move Services
```bash
git mv ErrorTranslator.swift Core/Services/
git mv Logger.swift Core/Services/
git mv Telemetry.swift Core/Services/
git mv LocalSimulator.swift Core/Services/
```

### Phase 6: Move Transaction Files
```bash
git mv BasicGasRouter.swift Core/Transaction/
git mv BasicHeuristicAnalyzer.swift Core/Transaction/
git mv TransactionProtocols.swift Core/Transaction/
```

### Phase 7: Move Recovery Files
```bash
git mv ShamirHybridRecovery.swift Core/Recovery/
git mv SimpleP2PSigner.swift Core/Recovery/
```

### Phase 8: Move Security Files (REVIEW FIRST)
```bash
git mv KeychainHelper.swift Core/Security/
git mv LocalAuthenticationWrapper.swift Core/Security/
git mv SecureEnclaveKeyStore.swift Core/Security/
```

### Phase 9: Move Views
```bash
git mv AddressBookView.swift UI/Views/
git mv ChainDetailView.swift UI/Views/
git mv HistoryView.swift UI/Views/
git mv HomeView.swift UI/Views/
git mv NFTGalleryView.swift UI/Views/
git mv OnboardingView.swift UI/Views/
git mv RecoveryView.swift UI/Views/
git mv SendView.swift UI/Views/
git mv SettingsView.swift UI/Views/
git mv WalletManagementView.swift UI/Views/
```

### Phase 10: Move UI Components
```bash
git mv UIComponents.swift UI/Components/
git mv ThemeViewModifiers.swift UI/Components/
```

### Phase 11: Move Config
```bash
git mv AppConfig.swift Core/
```

---

## POST-CLEANUP DIRECTORY STRUCTURE

```
Sources/KryptoClaw/
├── KryptoClawApp.swift                    ✅ (entry point)
├── ThemeEngine.swift                      ✅ (theme manager)
├── WalletStateManager.swift               ✅ (main state)
│
├── Core/
│   ├── AppConfig.swift                    📦 (moved)
│   │
│   ├── Blockchain/
│   │   ├── BitcoinTransactionService.swift
│   │   └── SolanaTransactionService.swift
│   │
│   ├── DEX/
│   │   ├── DEXAggregator.swift
│   │   ├── QuoteService.swift
│   │   ├── SwapProviders.swift
│   │   ├── SwapRouter.swift
│   │   ├── SwapTypes.swift
│   │   └── SwapViewModel.swift
│   │
│   ├── Earn/
│   │   ├── EarnCache.swift
│   │   ├── EarnDataService.swift
│   │   ├── EarnViewModel.swift
│   │   ├── StakingManager.swift
│   │   └── YieldModels.swift
│   │
│   ├── HSK/
│   │   ├── HSKKeyDerivationManager.swift
│   │   ├── HSKTypes.swift
│   │   ├── SecureEnclaveInterface.swift
│   │   └── WalletBindingManager.swift
│   │
│   ├── Models/
│   │   ├── AssetModel.swift
│   │   ├── Contact.swift                  📦 (moved)
│   │   ├── NFTModels.swift                📦 (moved)
│   │   └── WalletInfo.swift               📦 (moved)
│   │
│   ├── Navigation/
│   │   ├── RootCoordinatorView.swift
│   │   └── Router.swift
│   │
│   ├── Protocols/                         🆕 (new directory)
│   │   ├── BlockchainProviderProtocol.swift 📦
│   │   ├── KeyStoreProtocol.swift         📦
│   │   ├── NFTProviderProtocol.swift      📦
│   │   ├── RecoveryStrategyProtocol.swift 📦
│   │   └── SignerProtocol.swift           📦
│   │
│   ├── Providers/                         🆕 (new directory)
│   │   ├── HTTPNFTProvider.swift          📦
│   │   └── ModularHTTPProvider.swift      📦
│   │
│   ├── Recovery/                          🆕 (new directory)
│   │   ├── ShamirHybridRecovery.swift     📦
│   │   └── SimpleP2PSigner.swift          📦
│   │
│   ├── Security/
│   │   ├── BiometricAuthManager.swift
│   │   ├── JailbreakDetector.swift
│   │   ├── KeychainHelper.swift           📦 (moved)
│   │   ├── KeychainVault.swift
│   │   ├── LocalAuthenticationWrapper.swift 📦 (moved)
│   │   ├── SecureBytes.swift
│   │   └── SecureEnclaveKeyStore.swift    📦 (moved)
│   │
│   ├── Services/
│   │   ├── ErrorTranslator.swift          📦 (moved)
│   │   ├── LocalSimulator.swift           📦 (moved)
│   │   ├── Logger.swift                   📦 (moved)
│   │   ├── Telemetry.swift                📦 (moved)
│   │   └── TokenDiscoveryService.swift
│   │
│   ├── Signer/
│   │   └── TransactionSigner.swift
│   │
│   ├── Transaction/
│   │   ├── BasicGasRouter.swift           📦 (moved)
│   │   ├── BasicHeuristicAnalyzer.swift   📦 (moved)
│   │   ├── RPCRouter.swift
│   │   ├── TransactionProtocols.swift     📦 (moved)
│   │   ├── TransactionSimulationService.swift
│   │   └── TxPreviewViewModel.swift
│   │
│   ├── ViewModifiers/
│   │   └── PerformanceModifiers.swift
│   │
│   ├── AddressPoisoningDetector.swift
│   ├── ClipboardGuard.swift
│   ├── Extensions.swift
│   ├── HapticEngine.swift
│   ├── HDWalletService.swift
│   ├── MultiChainProvider.swift
│   ├── PersistenceService.swift
│   └── WalletCoreManager.swift
│
├── Themes/
│   ├── AppleDefaultTheme.swift
│   ├── BunkerGrayTheme.swift
│   ├── CrimsonTideTheme.swift
│   ├── CyberpunkNeonTheme.swift
│   ├── GoldenEraTheme.swift
│   ├── MatrixCodeTheme.swift
│   ├── NeonTokyoTheme.swift
│   ├── ObsidianStealthTheme.swift
│   ├── QuantumFrostTheme.swift
│   └── StealthBomberTheme.swift
│
└── UI/
    ├── Buy/
    │   └── NativeBuyView.swift
    │
    ├── Components/
    │   ├── SecurityToast.swift
    │   ├── ThemeViewModifiers.swift       📦 (moved)
    │   └── UIComponents.swift             📦 (moved)
    │
    ├── Earn/
    │   └── EarnView.swift
    │
    ├── HSK/
    │   ├── HSKFlowCoordinator.swift
    │   ├── HSKWalletInitiationView.swift
    │   ├── InsertHSKView.swift
    │   ├── KeyDerivationView.swift
    │   └── WalletCreationCompleteView.swift
    │
    ├── Transaction/
    │   ├── SlideToConfirmButton.swift
    │   └── TxPreviewView.swift
    │
    ├── Views/                              🆕 (new directory)
    │   ├── AddressBookView.swift          📦 (moved)
    │   ├── ChainDetailView.swift          📦 (moved)
    │   ├── HistoryView.swift              📦 (moved)
    │   ├── HomeView.swift                 📦 (moved)
    │   ├── NFTGalleryView.swift           📦 (moved)
    │   ├── OnboardingView.swift           📦 (moved)
    │   ├── RecoveryView.swift             📦 (moved)
    │   ├── SendView.swift                 📦 (moved)
    │   ├── SettingsView.swift             📦 (moved)
    │   └── WalletManagementView.swift     📦 (moved)
    │
    ├── ReceiveView.swift
    ├── SplashScreenView.swift
    └── SwapView.swift
```

**Legend:**
- ✅ = Already correctly placed
- 📦 = File moved in cleanup
- 🆕 = New directory created

---

## NEXT STEPS

1. **Review this plan carefully**
2. **Identify any concerns or modifications needed**
3. **Approve phases individually**
4. **Execute one phase at a time**
5. **Validate after each phase**

---

## QUESTIONS FOR REVIEW

Before proceeding, please confirm:

1. ✅ Is the directory structure acceptable?
2. ✅ Are the file categorizations correct?
3. ✅ Should we analyze duplicates (Phase 8) before moving?
4. ✅ Any files that should NOT be moved?
5. ✅ Any additional cleanup tasks needed?

---

**Status: AWAITING APPROVAL**
**Ready to Execute: NO**
**Next Action: Review and approve Phase 1**

