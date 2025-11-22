# KryptoClaw Architecture Blueprint

**Version: V1.0 → V2.0 Progression**

---

## 📋 Table of Contents

1. [Full System Architecture Overview](#1-full-system-architecture-overview)
2. [Protocol-Oriented Interfaces](#2-protocol-oriented-interfaces-for-all-critical-systems)
3. [Compliance Strategy](#3-compliance-strategy-v10-only)
4. [Master Validation & Testing Rules](#4-master-validation--testing-rules)
5. [V1.0 Feature List](#5-v10-feature-list-implementation-plan)
6. [V2.0 Upgrade Map](#6-v20-upgrade-map-attach-points)
7. [Risk List & Mitigation](#7-risk-list--mitigation)
8. [Final Confirmation](#8-final-confirmation)

---

## 1. Full System Architecture Overview

The architecture is split into **three tiers**:

- **A-Tier**: Application Logic
- **P-Tier**: Protocol Interfaces
- **C-Tier**: Concrete Implementations

> **Note**: V1.0 ships only with C-Tier modules that satisfy compliance requirements. V2.0 introduces advanced C-Tier modules that adhere to the same P-Tier contracts.

### A. Core Modules (V1.0 Foundation)

| Module | V1.0 Concrete Implementation | Attach Point (P-Tier) | Purpose |
|:-------|:-----------------------------|:----------------------|:--------|
| **Key Management Layer (KML)** | SecureEnclaveKeyStore (iOS Native) | `KeyStoreProtocol` | Encrypted, device-bound key storage |
| **Transaction Engine (TE)** | SimpleP2PSigner & LocalSimulator | `SignerProtocol` & `TransactionSimulatorProtocol` | Offline signing & on-device fee/balance check |
| **Blockchain Connectivity Layer (BCL)** | ModularHTTPProvider | `BlockchainProviderProtocol` | Read-only balance and Tx history for ETH, BTC, SOL |
| **Wallet State Manager (WSM)** | LocalDeterministicState | *(No Protocol - Core App Logic)* | Manages UI state and local database (contacts, settings) |
| **Routing Engine (RE)** | BasicGasRouter | `RoutingProtocol` | Selects optimal gas price for single-chain transactions |
| **NFT Engine (NFT-E)** | GalleryViewer | `NFTProviderProtocol` | Fetches and displays token metadata (Read-only V1.0) |
| **Fraud/Circuit Analyzer (FCA)** | BasicHeuristicAnalyzer | `SecurityPolicyProtocol` | Checks simulation results against known attack vectors |
| **Recovery Engine (R-E)** | ShamirHybridRecovery | `RecoveryStrategyProtocol` | Splits seed phrase for local storage and optional iCloud backup |

### B. V2.0+ Optional Modules (Architecturally Prepared)

These are new **Concrete Implementations** that swap in or extend existing V1.0 Modules, requiring **zero change** to the A-Tier application code.

| V2.0 Module | V1.0 Module Replaced/Augmented | Attachment Protocol | V2.0 Capability Unlocked |
|:------------|:-------------------------------|:--------------------|:-------------------------|
| **MPCSigner** | SimpleP2PSigner | `SignerProtocol` / `KeyStoreProtocol` | Distributed key signing |
| **QuantumSigner** | SimpleP2PSigner | `SignerProtocol` | Post-quantum signature schemes (e.g., Dilithium) |
| **GhostModeVault** | SecureEnclaveKeyStore | `KeyStoreProtocol` | Plausible deniability key hierarchy (hidden secondary wallet) |
| **DAppBrowser** | *N/A (New UI Route)* | `FeatureFlagProtocol` | Web3 injection and dApp interaction |
| **P2PSigning** | ModularHTTPProvider | `BlockchainProviderProtocol` | Offline transmission/signing via NFC/BLE |
| **DeadManSwitch** | ShamirHybridRecovery & BasicHeuristicAnalyzer | `RecoveryStrategyProtocol` / `SecurityPolicyProtocol` | Time-locked, conditional recovery protocol |
| **ZKProofEngine** | SimpleP2PSigner | `SignerProtocol` | Proof generation for privacy-preserving transactions |

---

## 2. Protocol-Oriented Interfaces for All Critical Systems

These are the **contracts** that the Application Logic (A-Tier) depends on. The V1.0 and V2.0 C-Tier implementations must adhere to these exact interfaces.

| Protocol Name | Key Methods & Signature | V1.0 Default | V2.0 Expansion |
|:--------------|:------------------------|:-------------|:---------------|
| **KeyStoreProtocol** | `getPrivateKey(id: String) -> Data`<br>`storePrivateKey(key: Data, id: String) -> Bool`<br>`isProtected() -> Bool` | SecureEnclaveKeyStore | MPCSigner, GhostModeVault |
| **SignerProtocol** | `signTransaction(txData: Data) -> SignedData`<br>`signMessage(msg: String) -> Signature` | SimpleP2PSigner | MPCSigner, QuantumSigner, ZKProofEngine |
| **TransactionSimulatorProtocol** | `simulate(tx: Transaction) -> SimulationResult` | LocalSimulator | NodeAPIAdapter (external simulation) |
| **BlockchainProviderProtocol** | `fetchBalance(address: String, chain: Chain) -> Balance`<br>`broadcast(signedTx: Data) -> TxHash` | ModularHTTPProvider (Read-only) | P2PSigning (Broadcast) |
| **NFTProviderProtocol** | `fetchNFTs(address: String) -> [NFTMetadata]` | GalleryViewer | MintingEngine (add `mintToken` method) |
| **SecurityPolicyProtocol** | `analyze(result: SimulationResult) -> [RiskAlert]`<br>`onBreach(alert: RiskAlert)` | BasicHeuristicAnalyzer | DeadManSwitch (triggers), AI/ML Fraud Analyzer |
| **RecoveryStrategyProtocol** | `generateShares(seed: String) -> [Share]`<br>`reconstruct(shares: [Share]) -> SeedPhrase` | ShamirHybridRecovery | DeadManSwitch (enforced time delays) |
| **FeatureFlagProtocol** | `isFeatureEnabled(featureName: String) -> Bool` | LocalConfigFlag | RemoteConfigFlag (Firebase/CDN) |

---

## 3. Compliance Strategy (V1.0 Only)

> **Critical**: These requirements must be satisfied to ensure App Store approval.

| Compliance Area | V1.0 Strategy for App Store Approval | ⚠️ Forbidden Actions for V1.0 (Rejection Triggers) |
|:----------------|:-------------------------------------|:--------------------------------------------------|
| **Key Management** | Use iOS's Secure Enclave for primary keys. Only use LocalAuthentication (FaceID/TouchID) to authorize access to the key. | ❌ NEVER store keys on non-encrypted server<br>❌ NEVER use UserDefaults or CoreData for key storage |
| **Financial Services** | Only permit Person-to-Person (P2P) transfers using on-chain crypto assets. No internal trading logic. | ❌ Inclusion of any Fiat Ramps (Buy/Sell with bank/credit card)<br>❌ Inclusion of Swap/Exchange UI or API calls |
| **Content/DApps** | Do not include a Web browser or any functionality that injects Web3 logic into an external webpage. | ❌ Embedding a WebView/WKWebView that loads external URLs without clear content filtering/sandboxing |
| **Hidden Features** | All code paths must be clearly visible and functional for the reviewer. Use LocalConfigFlag (V1.0) to disable all V2.0 modules. | ❌ Using Remote Config (Firebase/CDN) to hide features from reviewer<br>❌ Utilizing IP/Geo-fencing to hide features |
| **Unauthorized Protocols** | BLE/NFC functionality must be disabled or entirely absent. | ❌ Calling BLE or NFC APIs, even for non-crypto use cases |
| **Error Handling** | Every failure (e.g., failed simulation, network error) must be accompanied by a clear, non-technical alert. | ❌ Displaying raw blockchain error codes (revert)<br>❌ Using `alert()` or `confirm()` |
| **Privacy Policy** | Must be integrated and explicitly state that the wallet is non-custodial and that the developer cannot recover keys. | ❌ Omitting the privacy policy<br>❌ Not clearly articulating the non-custodial nature |

---

### 3.1. Apple App Store Compliance Checklist (Validation Point G)

**This checklist MUST be verified before every release candidate and integrated into Cycle 8 validation gates.**

#### 🔐 Key Management Compliance

- [ ] **Secure Enclave Usage**: All private keys stored exclusively in iOS Secure Enclave
- [ ] **No Server Storage**: Zero code paths that upload keys to any server (encrypted or not)
- [ ] **No Persistent Storage**: Keys never stored in UserDefaults, CoreData, or Keychain (except Secure Enclave)
- [ ] **LocalAuthentication Only**: FaceID/TouchID used exclusively for key access authorization
- [ ] **No Key Export**: No functionality to export, copy, or transmit private keys

#### 💰 Financial Services Compliance

- [ ] **P2P Only**: Only Person-to-Person transfers allowed (no internal trading)
- [ ] **No Fiat Ramps**: Zero Buy/Sell functionality with bank/credit card
- [ ] **No Swap/Exchange**: No internal swap or exchange UI or API calls
- [ ] **No Trading Logic**: No order books, trading pairs, or market-making features
- [ ] **Clear P2P Labeling**: All transfer UI clearly labeled as "Send to Address" (not "Trade" or "Exchange")

#### 🌐 Content/DApps Compliance

- [ ] **No WebView**: Zero WebView/WKWebView instances that load external URLs
- [ ] **No Web3 Injection**: No JavaScript injection into external web pages
- [ ] **No Browser**: No embedded browser functionality
- [ ] **No External URLs**: No functionality that loads arbitrary external web content

#### 🚫 Hidden Features Compliance

- [ ] **All Code Visible**: All code paths are functional and visible to App Store reviewer
- [ ] **LocalConfigFlag Only**: V1.0 uses only local, hardcoded feature flags (no remote config)
- [ ] **V2.0 Disabled**: All V2.0 modules hardcoded to `false` in V1.0 binary
- [ ] **No Remote Config**: Zero Firebase/CDN remote configuration calls
- [ ] **No Geo-Fencing**: No IP-based or location-based feature hiding
- [ ] **No A/B Testing**: No experimental features or hidden test groups

#### 📡 Unauthorized Protocols Compliance

- [ ] **No BLE**: Zero Bluetooth Low Energy API calls (CoreBluetooth not imported)
- [ ] **No NFC**: Zero Near Field Communication API calls (CoreNFC not imported)
- [ ] **No P2P Transport**: No mesh networking or device-to-device communication
- [ ] **Network Audit**: `grep -r "CoreBluetooth\|CoreNFC\|CBCentralManager\|NFCNDEFReader"` returns zero results

#### ⚠️ Error Handling Compliance

- [ ] **User-Friendly Errors**: All errors display clear, non-technical messages
- [ ] **No Raw Codes**: Zero raw blockchain error codes (revert, gas estimation failures) shown to user
- [ ] **No Technical Alerts**: No `alert()` or `confirm()` dialogs with technical jargon
- [ ] **Localized Messages**: All error messages are localized and contextually appropriate
- [ ] **Error Translation**: Blockchain errors translated to user-friendly equivalents

#### 📄 Privacy Policy Compliance

- [ ] **Visible Integration**: Privacy Policy accessible from Settings and Onboarding
- [ ] **Non-Custodial Statement**: Explicitly states wallet is non-custodial
- [ ] **Key Recovery Disclaimer**: Clearly states developer cannot recover user keys
- [ ] **Data Collection**: Accurately describes what data is collected (if any)
- [ ] **Third-Party Services**: Lists all third-party services (RPC providers, etc.)
- [ ] **App Store Metadata**: Privacy Policy URL included in App Store Connect metadata

#### 🔍 Additional Apple Guidelines

- [ ] **Guideline 3.1.5(b)**: No cryptocurrency mining
- [ ] **Guideline 2.1**: App is complete and functional (no placeholder content)
- [ ] **Guideline 4.0**: Design follows Apple Human Interface Guidelines
- [ ] **Guideline 5.1.1**: Privacy policy is accurate and accessible
- [ ] **Guideline 5.2.1**: App does not collect user data without consent
- [ ] **Guideline 5.2.3**: No analytics/tracking without explicit user consent

---

## 4. Master Validation & Testing Rules

> **The Prime Directive**
>
> **Build nothing that cannot be validated immediately.**
> Every module must be testable at the moment it compiles. No exceptions.
>
> **If a module cannot be validated → it must be split.**

### 4.1. Module Completion Rule

Each module must follow this cycle:

1.  Implement smallest possible unit
2.  Write deterministic unit tests for it
3.  Run full test suite
4.  Fix until green
5.  Integrate module into parent
6.  Run simulation tests
7.  Run regression tests
8.  **Only then** continue to next module

**Rule**: You may never build two modules ahead of validation.

### 4.2. Granularity Rule

**Rule**: No module may exceed the size where a developer cannot explain its behavior in under 30 seconds.

-   This prevents hidden complexity and future debugging hell.
-   If a module becomes too large or too abstract → **split it**.

### 4.3. Deterministic Behavior Rule

Every module must produce:
-   The same output
-   For the same input
-   In all device states
-   Regardless of previous runs

This rules out hidden state, accidental caching, or side-effects. Modules must be pure unless explicitly stateful. Stateful modules must be logged, simulated, and mockable.

---

### 4.4. Validation Points (Perfect Form)

The Agent must perform these exact validation checkpoints to guarantee no future unsolvable bugs.

| Validation Point | Type | Trigger | Verification Steps | Reason |
|:---|:---|:---|:---|:---|
| **A** | **Protocol Compliance** | Compile-time | • All protocol methods implemented<br>• Method signatures match exactly<br>• Error/Return types match<br>• No extra side-effects | Catches architecture drift before runtime. |
| **B** | **Unit Test Snapshot** | Module-level | • Validate happy-path<br>• Validate failure-path<br>• Validate boundary conditions<br>• Validate malformed input | Eliminates unknown behavior inside the module. |
| **C** | **Interaction Test** | Protocol-layer | • Mock protocol<br>• Validate module interacts only with documented API<br>• Validate error propagation & sequencing | Preserves modular composability. |
| **D** | **Integration Test** | Adjacent modules | • Validate data contract alignment<br>• Validate timing & state handoff<br>• Validate rollback behavior | Ensures system remains predictable when modules combine. |
| **E** | **Simulator Pass** | Business logic | • Run Transaction Simulation<br>• Run Risk Analysis<br>• Validate deterministic output & UI consistency | Prevents catastrophic financial bugs. |
| **F** | **Regression Test** | System-wide | • Run full suite<br>• Compare snapshot deltas<br>• Check protocol stability | Ensures V2.0 prep features never leak into V1.0. |
| **G** | **Compliance Pass** | Release/Feature | • **Apple App Store Compliance Scan** (see Section 3.1)<br>• **Crypto Platform Rules** (non-custodial verification)<br>• **iOS API Usage** (Secure Enclave, LocalAuthentication only)<br>• **Privacy Policy Integration** (visible, accessible, accurate) | Protects launchability (the wallet's greatest asset). |

---

### 4.5. Incremental Validation Strategy — "Mortar Between Bricks"

**Principle**: Validation must occur at **every logical boundary** between modules, not just at cycle completion. Each integration point is a validation checkpoint that grants certainty before proceeding.

#### 4.5.1. Pre-Integration Validation (Before Modules Connect)

**Before** Module A connects to Module B, validate:

- [ ] **Protocol Contract Verification**:
    - [ ] Module A's output types match Module B's expected input types exactly
    - [ ] All required protocol methods exist and signatures match
    - [ ] Error types are compatible (Module A's errors can be handled by Module B)
    - [ ] Data models are identical (no serialization/deserialization mismatches)

- [ ] **Isolated Module Tests**:
    - [ ] Module A passes all unit tests in isolation (100% pass rate)
    - [ ] Module B passes all unit tests in isolation (100% pass rate)
    - [ ] Both modules have deterministic behavior verified independently

- [ ] **Mock Boundary Tests**:
    - [ ] Module A tested with mocked Module B (verify A's expectations)
    - [ ] Module B tested with mocked Module A (verify B's expectations)
    - [ ] Edge cases at boundary identified and tested

**Validation Gate**: **NO integration proceeds until all Pre-Integration checks pass.**

#### 4.5.2. Integration Boundary Validation (At Connection Point)

**At the moment** Module A connects to Module B, validate:

- [ ] **Data Contract Validation**:
    - [ ] First data handoff: A → B produces expected result
    - [ ] Reverse handoff: B → A (if applicable) produces expected result
    - [ ] Data transformation preserves all required fields
    - [ ] No data loss or corruption at boundary

- [ ] **State Transition Validation**:
    - [ ] Module A's state before handoff is valid
    - [ ] Module B's state after receiving is valid
    - [ ] No state leakage or side effects
    - [ ] Rollback behavior tested (if integration fails mid-handoff)

- [ ] **Error Propagation Validation**:
    - [ ] Errors from Module A are correctly handled by Module B
    - [ ] Errors from Module B are correctly propagated to Module A
    - [ ] Error types remain typed (no generic errors)
    - [ ] Error messages remain user-friendly through boundary

- [ ] **Timing Validation**:
    - [ ] Synchronous calls complete in expected time
    - [ ] Async calls have proper await/cancellation
    - [ ] No race conditions at boundary
    - [ ] Timeout behavior tested

**Validation Gate**: **Integration is BLOCKED until boundary validation passes.**

#### 4.5.3. Post-Integration Validation (Immediately After Connection)

**Immediately after** Module A connects to Module B, validate:

- [ ] **Integration Smoke Tests**:
    - [ ] Happy path: A → B → Result works end-to-end
    - [ ] Failure path: A → B → Error handled correctly
    - [ ] Boundary conditions: Min/max values pass through correctly
    - [ ] Null/empty inputs handled gracefully

- [ ] **State Consistency Validation**:
    - [ ] Combined state of A+B is consistent
    - [ ] No state conflicts or contradictions
    - [ ] State persistence works correctly (if applicable)
    - [ ] State restoration works correctly (if applicable)

- [ ] **Regression Validation**:
    - [ ] All previous tests for Module A still pass
    - [ ] All previous tests for Module B still pass
    - [ ] No performance degradation introduced
    - [ ] No new memory leaks introduced

**Validation Gate**: **Next module integration BLOCKED until post-integration validation passes.**

#### 4.5.4. Protocol Interface Validation (At Every Protocol Call)

**Every time** a module calls a protocol method, validate:

- [ ] **Input Validation**:
    - [ ] Input parameters match protocol signature exactly
    - [ ] Input values are within expected ranges
    - [ ] Input types are correct (no type coercion)
    - [ ] Required inputs are present (no nil where non-optional)

- [ ] **Output Validation**:
    - [ ] Return type matches protocol exactly
    - [ ] Return value is not nil (unless protocol allows optional)
    - [ ] Return value structure matches expected model
    - [ ] Return value is deterministic (same input → same output)

- [ ] **Side Effect Validation**:
    - [ ] No unexpected side effects (logging is expected)
    - [ ] No network calls unless protocol specifies them
    - [ ] No file system writes unless protocol specifies them
    - [ ] No state mutations unless protocol specifies them

**Validation Gate**: **Protocol calls are instrumented and validated in test builds.**

#### 4.5.5. Data Flow Validation (At Every Data Handoff)

**Every time** data moves between modules, validate:

- [ ] **Data Integrity**:
    - [ ] Data structure preserved (no field loss)
    - [ ] Data values preserved (no corruption)
    - [ ] Data types preserved (no implicit conversions)
    - [ ] Data encoding/decoding works correctly (if applicable)

- [ ] **Data Contract Compliance**:
    - [ ] Required fields present
    - [ ] Optional fields handled correctly
    - [ ] Validation rules enforced (e.g., address format, amount ranges)
    - [ ] Data sanitization applied (if applicable)

- [ ] **Data Transformation Validation**:
    - [ ] Transformations are reversible (if applicable)
    - [ ] Transformations preserve essential data
    - [ ] Transformations are deterministic
    - [ ] Transformations handle edge cases

**Validation Gate**: **Data handoffs are logged and validated in test builds.**

#### 4.5.6. State Transition Validation (Before/After State Changes)

**Every time** module state changes, validate:

- [ ] **Pre-State Validation**:
    - [ ] Current state is valid before transition
    - [ ] Transition conditions are met
    - [ ] No conflicting transitions in progress
    - [ ] State is in expected format

- [ ] **Transition Validation**:
    - [ ] Transition is atomic (all-or-nothing)
    - [ ] Transition is logged (for debugging)
    - [ ] Transition is reversible (if applicable)
    - [ ] Transition handles errors gracefully

- [ ] **Post-State Validation**:
    - [ ] New state is valid after transition
    - [ ] State invariants maintained
    - [ ] No state corruption
    - [ ] State is persisted correctly (if applicable)

**Validation Gate**: **State transitions are instrumented and validated in test builds.**

#### 4.5.7. Error Boundary Validation (At Every Error Handler)

**Every time** an error occurs, validate:

- [ ] **Error Detection**:
    - [ ] Error is caught (not swallowed)
    - [ ] Error is typed correctly (UserError/DeveloperError/SystemError)
    - [ ] Error context is preserved
    - [ ] Error is logged (with redaction in production)

- [ ] **Error Propagation**:
    - [ ] Error propagates to correct handler
    - [ ] Error type preserved through propagation
    - [ ] Error message remains user-friendly
    - [ ] Error doesn't cause cascading failures

- [ ] **Error Recovery**:
    - [ ] Recoverable errors allow retry
    - [ ] Unrecoverable errors show clear message
    - [ ] State is rolled back correctly (if applicable)
    - [ ] User is informed appropriately

**Validation Gate**: **Error boundaries are tested with all error types.**

#### 4.5.8. Validation Checkpoint Matrix

For each module integration, the following checkpoints **MUST** be validated:

| Checkpoint | When | What to Validate | Blocking? |
|:-----------|:-----|:-----------------|:----------|
| **Pre-Integration** | Before connecting modules | Protocol contracts, isolated tests, mocks | ✅ YES |
| **Boundary** | At connection point | Data contracts, state transitions, errors, timing | ✅ YES |
| **Post-Integration** | Immediately after connection | Smoke tests, state consistency, regression | ✅ YES |
| **Protocol Call** | Every protocol method call | Input/output, side effects | ⚠️ Test builds |
| **Data Handoff** | Every data transfer | Data integrity, contracts, transformations | ⚠️ Test builds |
| **State Transition** | Every state change | Pre/post state, transitions | ⚠️ Test builds |
| **Error Boundary** | Every error handler | Detection, propagation, recovery | ✅ YES |

**Blocking checkpoints** prevent progression until validation passes. **Test build checkpoints** are instrumented and validated during development.

#### 4.5.9. Validation Certainty Requirements

Before proceeding to the next module, **ALL** of the following must be true:

- [ ] **100% Test Coverage**: All code paths in integrated modules are tested
- [ ] **Zero Known Bugs**: All identified issues are resolved
- [ ] **Deterministic Behavior**: Same inputs produce same outputs consistently
- [ ] **Error Handling Complete**: All error paths are tested and handled
- [ ] **Performance Acceptable**: No performance regressions introduced
- [ ] **Memory Safe**: No leaks, no crashes, no undefined behavior
- [ ] **Compliance Verified**: All compliance checks pass for integrated modules

**Rule**: **Uncertainty = Block. Certainty = Proceed.**

---

### 4.6. "No Chaos" Rule — Debuggability Contract

These rules prevent the "untraceable bug piles" that usually destroy crypto apps.

- [ ] **🔥 Rule 1: No Global State**
    - If global state is needed, it must be: Singleton, Logged, Mockable, Resettable.
- [ ] **🔥 Rule 2: No Hidden Async Behavior**
    - Every async call must be: `awaited`, `traceable`, `cancellable`.
    - No fire-and-forget tasks anywhere in the system.
- [ ] **🔥 Rule 3: Every Error Must Be Typed**
    - `UserError` (recoverable), `DeveloperError` (invariant violation), `SystemError` (OS/Network).
    - No silent errors. No opaque errors. No swallowed exceptions.
- [ ] **🔥 Rule 4: Verbose Logging (Dev Only)**
    - Log entry/exit, protocol calls, simulation failures, risk alerts, signing attempts (redacted).
    - In production → logs are auto-redacted.
- [ ] **🔥 Rule 5: Immutable Interfaces**
    - Once defined, protocols are **immutable** unless versioned (e.g., `SignerProtocolV2`).

---

### 4.7. Perfect Testing Flow

The Agent must follow this flow to ensure the "never get stuck" guarantee:

1.  **Implement Module**
2.  **Write Unit Tests** → *Run Full Test Suite* (If RED: Fix → Repeat)
3.  **Integrate Adjacent Modules**
4.  **Run Integration Tests** (If RED: Fix → Repeat)
5.  **Run Business Simulation Tests**
6.  **Run Full Regression Tests**
7.  **Compliance Scan**
8.  **ONLY THEN** → Build Next Module

---

### 4.8. Guarantees Provided

By following these rules:
-   Bugs cannot stack
-   No module becomes un-debuggable
-   Architecture never drifts
-   V2.0 friction stays near zero
-   Tests fail immediately when something breaks
-   AI cannot produce spaghetti or hidden behavior

---

## 5. V1.0 Feature List (Implementation Plan)

The V1.0 build focuses on **security**, **simulation**, and **core utility**.

### Feature: Secure Enclave Signing

| Aspect | Details |
|:-------|:--------|
| **Inputs** | Raw Transaction Data, Key ID, LocalAuthentication Context |
| **Outputs** | Signed Transaction (Data) |
| **Data Models** | `Transaction` (nonce, gas, to, value) |
| **Dependencies** | `KeyStoreProtocol`, `SignerProtocol` |
| **UI Components** | Auth Gate (FaceID/TouchID prompt) |
| **Flow** | App → Auth Gate → KML → TE → Signed TX |

### Feature: NFT Viewing (Gallery)

| Aspect | Details |
|:-------|:--------|
| **Inputs** | User Wallet Address, Chain ID |
| **Outputs** | `[NFTMetadata]` (Name, Image URL, ID, Contract) |
| **Data Models** | `NFTMetadata` (Contract, TokenID, ImageURI) |
| **Dependencies** | `NFTProviderProtocol`, BCL |
| **UI Components** | NFT Gallery Tab, NFT Card (Image/Text) |
| **Flow** | NFT-E → BCL → Fetch → WSM → Gallery UI |

### Feature: On-Device Simulation

| Aspect | Details |
|:-------|:--------|
| **Inputs** | Unsigned Transaction |
| **Outputs** | `SimulationResult` (Success/Failure, Estimated Fee, Balance Change) |
| **Data Models** | `SimulationResult` (Fee, BalanceDelta) |
| **Dependencies** | `TransactionSimulatorProtocol` |
| **UI Components** | Review/Confirm Screen (Simulation results displayed clearly) |
| **Flow** | TE → LocalSimulator → Check Balance → Display Result |

### Feature: Fraud Analysis (V1)

| Aspect | Details |
|:-------|:--------|
| **Inputs** | `SimulationResult` |
| **Outputs** | `[RiskAlert]` (e.g., "Address not in contacts," "Sending > 90% balance") |
| **Data Models** | `RiskAlert` (Level: Low/Medium/High, Description) |
| **Dependencies** | `SecurityPolicyProtocol` |
| **UI Components** | Risk Banner on Confirm screen |
| **Flow** | Simulator Output → FCA → Risk Banner |

### Feature: Intelligent Routing

| Aspect | Details |
|:-------|:--------|
| **Inputs** | Target Address, Amount, Current Gas Price |
| **Outputs** | Recommended Gas Limit/Price |
| **Data Models** | `GasEstimate` (Limit, MaxFeePerGas) |
| **Dependencies** | `RoutingProtocol` |
| **UI Components** | Gas Setting Field (Auto-selected default) |
| **Flow** | User → RE → GasEstimate → TE → Signed TX |

### Feature: Auto-Recovery

| Aspect | Details |
|:-------|:--------|
| **Inputs** | Seed Phrase (during onboarding) |
| **Outputs** | Recovery Shares (3 of 5) |
| **Data Models** | `RecoveryShare` (ShareData, Location) |
| **Dependencies** | `RecoveryStrategyProtocol` |
| **UI Components** | Onboarding Screen, Settings (Backup Status) |
| **Flow** | Onboard → R-E → Split Shares → KML Store/iCloud Backup |

### Feature: Local-Only State

| Aspect | Details |
|:-------|:--------|
| **Inputs** | User Settings, Address Book entries |
| **Outputs** | Persisted Data |
| **Data Models** | `Contact` (Name, Address) |
| **Dependencies** | Firebase Firestore (Private scope only) |
| **UI Components** | Contacts Tab, Settings Menu |
| **Flow** | UI → WSM → Firestore (private path) |

---

## 6. V2.0 Upgrade Map (Attach Points)

This details the specific attachment strategy for the V2.0 "monster" features, leveraging the P-Tier protocols.

### MPC Signing

| Aspect | Details |
|:-------|:--------|
| **V1.0 Protocol/Module Plug-In** | `KeyStoreProtocol`, `SignerProtocol` |
| **V2.0 New Files/Modules** | `MPCSigner.swift/ts`, `MPCServerProxy.swift/ts` |
| **Existing Code Unchanged** | Application Logic: The TransferButton handler logic remains the same (it calls `SignerProtocol.signTransaction`) |
| **V2.0 Capabilities** | Distributed security, no single point of failure (no single private key exists on the device) |

### Quantum Signing

| Aspect | Details |
|:-------|:--------|
| **V1.0 Protocol/Module Plug-In** | `SignerProtocol` |
| **V2.0 New Files/Modules** | `QuantumSigner.swift/ts`, `DilithiumLibrary.swift/ts` |
| **Existing Code Unchanged** | Application Logic: Transaction construction (nonce, to, value) remains identical |
| **V2.0 Capabilities** | Future-proofed transaction signing using quantum-resistant algorithms |

### ZK-Proofs

| Aspect | Details |
|:-------|:--------|
| **V1.0 Protocol/Module Plug-In** | `SignerProtocol` (new method: `signAndProve`) |
| **V2.0 New Files/Modules** | `ZKProofEngine.swift/ts`, `ProverAPIClient.swift/ts` |
| **Existing Code Unchanged** | Application Logic: The underlying state management and balance fetching |
| **V2.0 Capabilities** | Private transactions (e.g., proving ownership of funds without revealing the amount) |

### Ghost Mode Vault

| Aspect | Details |
|:-------|:--------|
| **V1.0 Protocol/Module Plug-In** | `KeyStoreProtocol` |
| **V2.0 New Files/Modules** | `GhostModeVault.swift/ts` |
| **Existing Code Unchanged** | Application Logic: fetchBalance logic (the app retrieves two balances and displays one) |
| **V2.0 Capabilities** | Plausible deniability (user can show a low-value wallet to an attacker/authority) |

### DApp Browser

| Aspect | Details |
|:-------|:--------|
| **V1.0 Protocol/Module Plug-In** | New UI Route (Conditional on `FeatureFlagProtocol`) |
| **V2.0 New Files/Modules** | `DAppBrowserView.jsx/tsx`, `Web3InjectedScript.js` |
| **Existing Code Unchanged** | All Core Modules: KML, TE, BCL, WSM are reused for the browser injection |
| **V2.0 Capabilities** | Interaction with Decentralized Applications (DApps) and Web3 |

### P2P Offline Signing

| Aspect | Details |
|:-------|:--------|
| **V1.0 Protocol/Module Plug-In** | Augment `BlockchainProviderProtocol` (add P2P broadcast implementation) |
| **V2.0 New Files/Modules** | `P2PTransport.swift/ts` (NFC/BLE layer) |
| **Existing Code Unchanged** | `SignerProtocol`: The transaction is still signed offline first by the KML |
| **V2.0 Capabilities** | Broadcast transactions offline via nearby devices (mesh network) |

### DeadManSwitch

| Aspect | Details |
|:-------|:--------|
| **V1.0 Protocol/Module Plug-In** | `RecoveryStrategyProtocol`, `SecurityPolicyProtocol` |
| **V2.0 New Files/Modules** | `DeadManSwitchDaemon.swift/ts` (Timer service) |
| **Existing Code Unchanged** | Recovery Engine: The reconstruction process (`reconstruct(shares)`) remains the same |
| **V2.0 Capabilities** | Time-locked access control to recovery data for inheritance/loss prevention |

### Minting/Sidechain Routing

| Aspect | Details |
|:-------|:--------|
| **V1.0 Protocol/Module Plug-In** | Augment `NFTProviderProtocol` (add `mintToken` method), Augment `RoutingProtocol` |
| **V2.0 New Files/Modules** | `MintingEngine.swift/ts`, `SidechainRouter.swift/ts` |
| **Existing Code Unchanged** | `KeyStoreProtocol`: Keys are still generated and stored securely |
| **V2.0 Capabilities** | Creation of digital assets and complex cross-chain transaction routing |

---

## 7. Risk List & Mitigation

| Risk | Impact | Mitigation Strategy | Version |
|:-----|:-------|:-------------------|:--------|
| **App Store Rejection (V1.0)** | Zero market penetration | **Compliance Mapping** (Section 3): Adhere strictly to P2P only, non-custody, and Secure Enclave usage | V1.0 |
| **Key Compromise** | Total loss of user funds | **Defense in Depth**: Secure Enclave, FaceID authorization per transaction, and no network access to the primary key storage | V1.0 |
| **Transaction Failure (Gas)** | User loses fee, poor experience | `TransactionSimulatorProtocol`: Force all transfers through local simulation to catch insufficient gas/balance | V1.0 |
| **V2.0 Feature Leak (Trojanned Code)** | Immediate App Store ban | `FeatureFlagProtocol`: Use a local, deterministic flag that is hardcoded to `false` for all V2.0 modules in the V1.0 binary | V1.0 |
| **State Corruption** | Incorrect balances/Tx history | **Deterministic State**: WSM must derive all balances from the BCL, not cache long-term values | V1.0 |

---

## 8. Final Confirmation

The **KryptoClaw V1.0** will be a compliant, non-custodial, Secure Enclave-backed P2P wallet. It is built upon a **Protocol-Oriented Architecture** that will allow V2.0 features (MPC, Quantum Signing, ZK-Proofs, DApp Browser) to be seamlessly integrated by swapping concrete implementation modules without touching the core application logic. 

This foundation secures both **user funds** and the **future of the product**.

---

**End of Specification**
