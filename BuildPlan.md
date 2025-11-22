# Monster Wallet Build Plan

> **Adherence Protocol**: This plan strictly follows **Section 4 (Master Validation Rules)** of the `Spec.md`.
> **Rule**: No cycle may be marked complete until ALL its Validation Gates are PASSED.

---

## ⚖️ Execution Contract

**The Agent MUST acknowledge and adhere to the following immutable rules:**

### Contract Terms

1. **Plan Immutability**: This plan is **immutable** unless explicitly approved for changes by the user. The Agent must never modify, skip, or "optimize" steps without approval.

2. **Validation Gate Mandatory**: The Agent must **never skip a validation gate**. Every gate must be executed, verified, and logged before proceeding.

3. **No Module Combination**: The Agent must **never "optimize" steps by combining modules**. Each module must be built, validated, and integrated separately according to the cycle structure.

4. **Failure Stop Protocol**: If any validation gate fails, the Agent must **stop immediately**, rollback changes, analyze the failure, attempt repair, re-validate, and **report to the user** before proceeding.

5. **Gate Logging Requirement**: The Agent must **produce logs for each validation gate** showing:
   - Gate name and cycle number
   - Test results (pass/fail)
   - Any errors or warnings
   - Time taken
   - Next steps

**Violation of any contract term is grounds for immediate halt and user notification.**

---

## 📝 Required Logging Contract

**CRITICAL**: The Agent must enforce logging rules or bugs become invisible.

### Dev Mode Logging (Required)

The Agent must log the following in development builds:

- ✅ **Module Entry/Exit**: Every module's entry and exit points
- ✅ **Protocol Calls**: Every protocol method call (with parameters, redacted)
- ✅ **Errors**: All errors with full context (typed errors)
- ✅ **Boundary Events**: All data handoffs between modules
- ✅ **State Transitions**: All state machine transitions
- ✅ **Validation Gates**: All validation gate executions and results

**Log Format**:
```
[ModuleName] Entry: functionName(params: redacted)
[ModuleName] Protocol Call: ProtocolName.methodName
[ModuleName] State Transition: StateA → StateB
[ModuleName] Error: ErrorType(message)
[ModuleName] Exit: functionName(result: redacted)
```

### Production Logging (Required)

The Agent must ensure production builds log:

- ✅ **Error Fingerprints Only**: Hash or fingerprint of errors (not raw errors)
- ✅ **Never Raw Errors**: No stack traces, no technical details
- ✅ **Never Sensitive Data**: No keys, seeds, addresses, or personal data
- ✅ **User-Friendly Context**: Only user-facing error context

**Log Format**:
```
[ModuleName] Error Fingerprint: abc123def456
[ModuleName] User Context: "Transaction failed. Please try again."
```

### Logging Enforcement

The Agent must:
1. Implement logging infrastructure in Cycle 1
2. Add logging to every module as it's built
3. Verify logging in test builds
4. Verify redaction in production builds
5. Test that sensitive data never appears in logs

**This is essential for future debugging and compliance.**

---

## 🚨 Failure Protocol

**When ANY validation gate fails, the Agent MUST follow this exact protocol:**

### Failure Response Sequence

1. **STOP IMMEDIATELY**
   - Halt all current work
   - Do not proceed to next step
   - Do not attempt workarounds

2. **ROLLBACK CHANGES**
   - Revert to last known good state
   - Restore previous working code
   - Ensure system is in stable state

3. **ANALYZE FAILURE**
   - Identify root cause
   - Document failure type (test failure, validation boundary failure, protocol mismatch, compliance check failure)
   - Log all relevant context

4. **ATTEMPT REPAIR**
   - Fix the underlying issue
   - Do not skip validation to "fix" the problem
   - Ensure fix addresses root cause, not symptoms

5. **RE-VALIDATE**
   - Re-run the failed validation gate
   - Re-run all previous validation gates in the cycle
   - Ensure all gates pass before proceeding

6. **STOP AND REPORT**
   - Report failure to user with:
     - Cycle number and gate name
     - Failure type and root cause
     - Repair actions taken
     - Re-validation results
   - **DO NOT PROCEED** until user acknowledges

### Failure Types and Required Actions

| Failure Type | Required Action |
|:-------------|:----------------|
| **Test Failure** | Fix code, re-run test suite, verify all tests pass |
| **Validation Boundary Failure** | Fix integration, re-validate boundary, verify data handoff |
| **Protocol Mismatch** | Create ProtocolV2 if needed, update all mocks/tests, verify compatibility |
| **Compliance Check Failure** | Fix compliance violation, re-run compliance scan, verify all checks pass |

**Rule**: **No failure is acceptable. Every failure must be resolved before progression.**

---

## 🔬 Incremental Validation Strategy

**Critical**: Every cycle includes validation at three critical boundaries (Section 4.5):

1. **Pre-Integration** (Before modules connect): Protocol contracts, isolated tests, mocks
2. **Integration Boundary** (At connection point): Data handoffs, error propagation, state transitions
3. **Post-Integration** (After connection): Smoke tests, state consistency, regression

**Rule**: **NO progression to next cycle until ALL three validation boundaries pass.**

### Validation Checkpoint Matrix

Each cycle must validate:

| Checkpoint | When | What | Blocking? |
|:-----------|:-----|:-----|:----------|
| **Pre-Integration** | Before connecting | Protocol contracts, isolated tests | ✅ YES |
| **Boundary** | At connection | Data handoffs, errors, state | ✅ YES |
| **Post-Integration** | After connection | Smoke tests, regression | ✅ YES |
| **Protocol Call** | Every call | Input/output validation | ⚠️ Test builds |
| **Data Handoff** | Every transfer | Data integrity | ⚠️ Test builds |
| **State Transition** | Every change | Pre/post state | ⚠️ Test builds |
| **Error Boundary** | Every handler | Error handling | ✅ YES |

### Validation Certainty Requirements

Before marking any cycle complete, verify:

- [ ] **100% Test Coverage**: All code paths tested
- [ ] **Zero Known Bugs**: All issues resolved
- [ ] **Deterministic Behavior**: Consistent outputs verified
- [ ] **Error Handling Complete**: All error paths tested
- [ ] **Performance Acceptable**: No regressions
- [ ] **Memory Safe**: No leaks, crashes, undefined behavior
- [ ] **Compliance Verified**: All compliance checks pass

**Uncertainty = Block. Certainty = Proceed.**

### 🔒 Single-Cycle Rule (Hard Rule Against Parallel Work)

**CRITICAL**: The Agent may **ONLY work on ONE Cycle at a time**.

**Forbidden Actions**:
- ❌ Generating multiple modules simultaneously
- ❌ Wiring parts ahead of validation
- ❌ Anticipating dependencies before current cycle is complete
- ❌ Starting next cycle before current cycle is fully validated

**Required Sequence**:
1. Complete Cycle N
2. Validate ALL gates in Cycle N
3. Run regression tests
4. Confirm ALL gates pass
5. **ONLY THEN** touch Cycle N+1

**This rule prevents chaos from creeping in through "optimization."**

### 🔒 Protocol Freeze Rule

**CRITICAL**: Once a protocol is defined and validated in Cycle N, it is **FROZEN**.

**Rule**: The Agent may **NOT modify a protocol's signature** in Cycle N+1 without:
1. Creating `ProtocolNameV2` (new version)
2. Updating ALL dependent mocks
3. Updating ALL dependent tests
4. Maintaining backward compatibility (if needed)
5. Documenting the version change

**This ensures modular architecture never collapses through mid-build rot.**

### 📊 Testing Priority Hierarchy

**CRITICAL**: Tests MUST be executed in this exact order. Reversing this order causes chaos.

1. **Unit Tests First**: Test each module in isolation
2. **Boundary Tests Second**: Test module boundaries and data handoffs
3. **Integration Tests Third**: Test module combinations
4. **Simulation Tests Fourth**: Test business logic and end-to-end flows
5. **Regression Tests Last**: Verify nothing broke

**The Agent must NEVER skip or reorder these test levels.**

### 🔬 Determinism Verifier

**CRITICAL**: Every module MUST include a "Determinism Test" that verifies:

- Same input → Same output
- Same input → Same log events
- Same input → Same state transitions
- Same input → Same performance characteristics

**Required Test Pattern**:
```swift
func testDeterminism() {
    let input = createTestInput()
    let result1 = module.process(input)
    let result2 = module.process(input)
    XCTAssertEqual(result1, result2)
    // Verify logs match
    // Verify state transitions match
}
```

**The Agent must write this test automatically for every stateful module.**

### 🔒 State Machine Freeze Check

**CRITICAL**: Each module with state (WSM, TE, Signing, Recovery) MUST:

1. **Define state machine as enum**:
   ```swift
   enum ModuleState {
       case idle
       case processing
       case completed
       case error(Error)
   }
   ```

2. **Freeze transitions**: Document all valid state transitions

3. **Enforce invalid transition tests**: Test that invalid transitions are rejected

**Required Test Pattern**:
```swift
func testInvalidStateTransition() {
    let module = Module(state: .completed)
    XCTAssertThrowsError(try module.transition(to: .idle))
}
```

**This prevents undefined behavior under edge cases.**

---

## 🗓️ Phase 1: V1.0 Core Foundation (Compliance & Security)

**Goal**: Ship a secure, compliant, non-custodial iOS wallet that passes App Store review.

| Cycle | Module / Focus | Primary Validation Gate | Status |
|:------|:---------------|:------------------------|:-------|
| **1** | **Project Setup & CI/CD Rig** | The "Prime Directive" (Can we test?) | 🔴 Pending |
| **2** | **Key Management Layer (KML)** | `KeyStoreProtocol` Compliance | 🔴 Pending |
| **3** | **Blockchain Connectivity (BCL)** | `BlockchainProviderProtocol` (Read-Only) | 🔴 Pending |
| **4** | **Transaction Engine (TE) - Sim** | `TransactionSimulatorProtocol` | 🔴 Pending |
| **5** | **Wallet State Manager (WSM)** | Deterministic State Check | 🔴 Pending |
| **6** | **Transaction Engine (TE) - Sign** | `SignerProtocol` & Broadcast | 🔴 Pending |
| **7** | **Recovery Engine (R-E)** | `RecoveryStrategyProtocol` | 🔴 Pending |
| **8** | **UI Polish & Final Compliance** | **Validation Point G** (App Store Rules) | 🔴 Pending |

---

## 🏁 CHECKPOINT: V1.0 RELEASE CANDIDATE
*Stop here. Submit to App Store. Only proceed to Phase 2 after approval or specific instruction.*

---

## 🗓️ Phase 2: V2.0 "Monster" Features (Advanced Protocol Modules)

**Goal**: Activate advanced capabilities by hot-swapping C-Tier modules.

| Cycle | Module / Focus | Attach Point | Status |
|:------|:---------------|:-------------|:-------|
| **9** | **MPC Signer** | `SignerProtocol` / `KeyStoreProtocol` | ⚪️ Planned |
| **10** | **Ghost Mode Vault** | `KeyStoreProtocol` | ⚪️ Planned |
| **11** | **ZK-Proof Engine** | `SignerProtocol` | ⚪️ Planned |
| **12** | **DApp Browser** | `FeatureFlagProtocol` | ⚪️ Planned |

---

## 🛠️ Detailed Cycle Breakdown

### 🔄 Cycle 1: Project Setup & CI/CD Rig

**Goal**: Establish the "Validation Rig" so that every future line of code can be immediately tested.

- [ ] **Validation Gates**:
    - [ ] **Point A**: Unit Test Target runs and passes on empty project.
    - [ ] **Point A**: Integration Test Target runs and passes.
    - [ ] **Point F**: CI Script (or local equivalent) runs all tests in < 10s.
    - [ ] **Spec Check**: Dependency manager (SPM/CocoaPods) configured.
    - [ ] **Point G (Compliance)**: Verify no BLE/NFC imports exist in project.
    - [ ] **Point G (Compliance)**: Verify no WebView/WKWebView dependencies added.

- **Tasks**:
    1.  Initialize Xcode Project (MonsterWallet).
    2.  Setup Test Targets (`MonsterWalletTests`, `MonsterWalletUITests`).
    3.  Create `Validation/` directory for mock protocols.
    4.  Implement `Logger` (Rule 4: Verbose Logging).
    5.  Verify "No Global State" pattern (Dependency Injection setup).
    6.  **Compliance**: Audit project dependencies for forbidden frameworks (CoreBluetooth, CoreNFC, WebKit).
    7.  **Compliance**: Create `ComplianceAudit.swift` test file to scan for violations.

---

### 🔄 Cycle 2: Key Management Layer (KML)

**Goal**: Securely generate and store private keys using the Secure Enclave.

- [ ] **Pre-Integration Validation** (Section 4.5.1):
    - [ ] **Protocol Contract**: `KeyStoreProtocol` defined with exact method signatures.
    - [ ] **Isolated Tests**: KML passes 100% unit tests in isolation.
    - [ ] **Mock Boundary**: KML tested with mocked callers (verify expectations).

- [ ] **Validation Gates**:
    - [ ] **Point A**: `KeyStoreProtocol` methods implemented exactly.
    - [ ] **Point B (Unit)**: Keys generated are unique. Keys persist across app restarts.
    - [ ] **Point B (Unit)**: Accessing key without Auth fails (mocked).
    - [ ] **Point B (Unit)**: All error paths tested (auth failure, key not found, secure enclave unavailable).
    - [ ] **Point B (Unit)**: Boundary conditions tested (empty key ID, invalid key data, max key count).
    - [ ] **Point G (Compliance)**: Keys stored ONLY in Secure Enclave (verify no UserDefaults/CoreData).
    - [ ] **Point G (Compliance)**: No key export functionality exists (no copy/paste, no file export).
    - [ ] **Point G (Compliance)**: LocalAuthentication (FaceID/TouchID) is ONLY authentication method.
    - [ ] **Point G (Compliance)**: Zero network calls to store/retrieve keys.

- [ ] **Post-Integration Validation** (Section 4.5.3):
    - [ ] **State Consistency**: KML state is valid and consistent after all operations.
    - [ ] **Regression**: All Cycle 1 tests still pass with KML integrated.
    - [ ] **Memory Safety**: No leaks, no crashes, no undefined behavior.

- **Tasks**:
    1.  Define `KeyStoreProtocol.swift` (with exact signatures).
    2.  Implement `SecureEnclaveKeyStore.swift`.
    3.  Implement `LocalAuthentication` wrapper (FaceID/TouchID).
    4.  **Incremental Validation**: Write unit tests for each method before implementing.
    5.  **Incremental Validation**: Test each method in isolation before integration.
    6.  Test: Generate Key → Store → Retrieve → Sign (mock data).
    7.  **Compliance**: Add unit test that verifies keys never written to UserDefaults.
    8.  **Compliance**: Add unit test that verifies no network requests made by KML.
    9.  **Boundary Validation**: Test protocol calls with invalid inputs, verify error handling.
    10. **State Transition Validation**: Test state changes (key creation, deletion, access) are atomic.

---

### 🔄 Cycle 3: Blockchain Connectivity (BCL)

**Goal**: Read balances and transaction history from public blockchains (ETH/SOL/BTC) without writing.

- [ ] **Pre-Integration Validation** (Section 4.5.1):
    - [ ] **Protocol Contract**: `BlockchainProviderProtocol` defined with exact signatures.
    - [ ] **Isolated Tests**: BCL passes 100% unit tests in isolation (with mocked network).
    - [ ] **Mock Boundary**: BCL tested with mocked callers; callers tested with mocked BCL.
    - [ ] **Data Contract**: `Balance` and `TransactionHistory` models match expected structure.

- [ ] **Integration Boundary Validation** (Section 4.5.2) - BCL ↔ KML:
    - [ ] **Data Handoff**: BCL receives addresses from KML, validates format.
    - [ ] **Error Propagation**: BCL errors properly typed and handled by callers.
    - [ ] **State Transition**: BCL state changes are atomic (no partial updates).
    - [ ] **Timing**: Network calls have proper timeout and cancellation.

- [ ] **Validation Gates**:
    - [ ] **Point A**: `BlockchainProviderProtocol` implemented exactly.
    - [ ] **Point B (Unit)**: Returns correct balance for known testnet address.
    - [ ] **Point B (Unit)**: Handles network timeout/failure gracefully (Rule 3: Typed Errors).
    - [ ] **Point B (Unit)**: All error paths tested (network error, invalid address, RPC error).
    - [ ] **Point B (Unit)**: Boundary conditions tested (zero balance, very large balance, invalid chain).
    - [ ] **Point C (Interaction)**: Mocked Provider returns deterministic data for UI tests.
    - [ ] **Point C (Interaction)**: BCL only calls documented protocol methods (no hidden calls).
    - [ ] **Point G (Compliance)**: BCL is READ-ONLY (no broadcast functionality yet).
    - [ ] **Point G (Compliance)**: All errors translated to user-friendly messages (no raw revert codes).

- [ ] **Post-Integration Validation** (Section 4.5.3):
    - [ ] **Smoke Tests**: KML → BCL → Balance retrieval works end-to-end.
    - [ ] **State Consistency**: BCL state doesn't conflict with KML state.
    - [ ] **Regression**: All Cycle 1 & 2 tests still pass.
    - [ ] **Data Flow**: Address from KML → Balance from BCL → Display works correctly.

- **Tasks**:
    1.  Define `BlockchainProviderProtocol.swift` (with exact signatures).
    2.  Create `Balance` and `TransactionHistory` data models (validate structure).
    3.  **Incremental Validation**: Implement error translator first, test in isolation.
    4.  Implement `ModularHTTPProvider.swift` (one method at a time, test each).
    5.  Integrate public RPC endpoints (Infura/Alchemy/Solana RPC).
    6.  **Boundary Validation**: Test data handoff KML → BCL (address format validation).
    7.  **Boundary Validation**: Test error propagation (network error → user-friendly message).
    8.  **Compliance**: Verify no swap/exchange API endpoints are called.
    9.  **State Transition Validation**: Test state changes (fetching → loaded → error states).
    10. **Protocol Call Validation**: Instrument and test every protocol method call.

---

### 🔄 Cycle 4: Transaction Engine (TE) - Simulation Only

**Goal**: Construct valid transaction data and **simulate** it to calculate fees/validity (NO SIGNING yet).

- [ ] **Pre-Integration Validation** (Section 4.5.1):
    - [ ] **Protocol Contracts**: `TransactionSimulatorProtocol`, `RoutingProtocol`, `SecurityPolicyProtocol` defined.
    - [ ] **Isolated Tests**: TE passes 100% unit tests in isolation (with mocked BCL/KML).
    - [ ] **Mock Boundary**: TE tested with mocked BCL/KML; BCL/KML tested with mocked TE.
    - [ ] **Data Contract**: Transaction model matches BCL's expected format.

- [ ] **Integration Boundary Validation** (Section 4.5.2) - TE ↔ BCL & KML:
    - [ ] **Data Handoff BCL → TE**: Nonce, gas price, balance data flows correctly.
    - [ ] **Data Handoff KML → TE**: Address data flows correctly (no key exposure).
    - [ ] **Error Propagation**: BCL errors → TE → User-friendly message chain works.
    - [ ] **State Transition**: Simulation state changes are atomic (no partial simulations).

- [ ] **Validation Gates**:
    - [ ] **Point A**: `TransactionSimulatorProtocol` implemented exactly.
    - [ ] **Point E (Sim)**: Simulation accurately predicts gas fees for test tx.
    - [ ] **Point E (Sim)**: Reverts/Errors are caught and translated to user-friendly alerts.
    - [ ] **Point E (Sim)**: All simulation paths tested (success, revert, insufficient gas, invalid address).
    - [ ] **Point D (Integration)**: TE accepts input from BCL (nonce/gas price) - validated at boundary.
    - [ ] **Point D (Integration)**: TE uses KML address without exposing keys - validated at boundary.
    - [ ] **Point G (Compliance)**: All simulation errors display user-friendly messages (no raw codes).
    - [ ] **Point G (Compliance)**: No swap/exchange logic in transaction construction.

- [ ] **Post-Integration Validation** (Section 4.5.3):
    - [ ] **Smoke Tests**: KML → BCL → TE → Simulation result works end-to-end.
    - [ ] **State Consistency**: TE state doesn't conflict with BCL/KML state.
    - [ ] **Regression**: All Cycle 1, 2, 3 tests still pass.
    - [ ] **Data Flow**: Transaction input → Simulation → Result → Display works correctly.

- **Tasks**:
    1.  Define `TransactionSimulatorProtocol`, `RoutingProtocol`, `SecurityPolicyProtocol`.
    2.  **Incremental Validation**: Implement `BasicGasRouter` first, test in isolation.
    3.  **Incremental Validation**: Implement `BasicHeuristicAnalyzer` next, test in isolation.
    4.  Implement `LocalSimulator` (basic offline checks) + RPC `eth_call` wrapper.
    5.  **Boundary Validation**: Test BCL → TE data handoff (nonce, gas, balance).
    6.  **Boundary Validation**: Test KML → TE data handoff (address only, no keys).
    7.  **Boundary Validation**: Test error propagation (BCL error → TE → User message).
    8.  Wire up `SecurityPolicyProtocol` (`BasicHeuristicAnalyzer`) to flag high-value txs.
    9.  **Compliance**: Verify transaction types are P2P only (no swap/exchange/order types).
    10. **Compliance**: Test error messages are non-technical and localized.
    11. **State Transition Validation**: Test simulation state machine (pending → running → success/error).
    12. **Protocol Call Validation**: Instrument every protocol call (BCL, KML, SecurityPolicy).

---

### 🔄 Cycle 5: Wallet State Manager (WSM)

**Goal**: Tie KML, BCL, and TE together into a cohesive app state (MVP UI).

- [ ] **Pre-Integration Validation** (Section 4.5.1):
    - [ ] **Protocol Contracts**: WSM interfaces with KML, BCL, TE protocols correctly.
    - [ ] **Isolated Tests**: WSM passes 100% unit tests in isolation (with mocked KML/BCL/TE).
    - [ ] **Mock Boundary**: WSM tested with mocked modules; modules tested with mocked WSM.
    - [ ] **Data Contract**: State models match expected structure from all modules.

- [ ] **Integration Boundary Validation** (Section 4.5.2) - WSM ↔ KML/BCL/TE:
    - [ ] **Data Handoff KML → WSM**: Address data flows correctly (no key exposure).
    - [ ] **Data Handoff BCL → WSM**: Balance/history data flows correctly.
    - [ ] **Data Handoff TE → WSM**: Simulation results flow correctly.
    - [ ] **Data Handoff WSM → TE**: Transaction inputs flow correctly.
    - [ ] **Error Propagation**: All module errors → WSM → UI display correctly.
    - [ ] **State Transition**: WSM state changes are atomic (no partial UI updates).

- [ ] **Validation Gates**:
    - [ ] **Point D (Integration)**: UI updates reactively when BCL finishes fetch - validated at boundary.
    - [ ] **Point D (Integration)**: App restoration loads last known state (safely) - validated.
    - [ ] **Point D (Integration)**: WSM → TE → Simulation → WSM → UI flow works end-to-end.
    - [ ] **Point F (Regression)**: Verify KML is still secure when WSM requests keys (boundary test).
    - [ ] **Point F (Regression)**: All Cycle 1-4 tests still pass.
    - [ ] **Point G (Compliance)**: No tracking/analytics leakage in state manager.
    - [ ] **Point G (Compliance)**: No WebView/WKWebView instances in UI.
    - [ ] **Point G (Compliance)**: All UI labels clearly indicate P2P transfers (not trading).
    - [ ] **Point G (Compliance)**: Feature flags are local only (no remote config).

- [ ] **Post-Integration Validation** (Section 4.5.3):
    - [ ] **Smoke Tests**: Full flow KML → BCL → TE → WSM → UI works end-to-end.
    - [ ] **State Consistency**: WSM state doesn't conflict with any module state.
    - [ ] **Regression**: All previous cycle tests still pass.
    - [ ] **Data Flow**: All data handoffs validated (address, balance, simulation, transaction).

- **Tasks**:
    1.  Implement `LocalDeterministicState` (ViewModel/Store) - test state transitions first.
    2.  **Boundary Validation**: Test WSM → KML boundary (address request, no key exposure).
    3.  **Boundary Validation**: Test WSM → BCL boundary (balance fetch, error handling).
    4.  **Boundary Validation**: Test WSM → TE boundary (simulation request, result handling).
    5.  Build "Home Screen" (Balance Display) - test UI updates reactively.
    6.  Build "Send Screen" (Inputs only, driving the Simulator) - test input validation.
    7.  Connect `GalleryViewer` (NFT-E) for read-only asset view - test data flow.
    8.  **State Transition Validation**: Test WSM state machine (loading → loaded → error states).
    9.  **Error Boundary Validation**: Test all error paths (KML error, BCL error, TE error).
    10. **Compliance**: Verify no analytics SDKs imported (Firebase Analytics, etc.).
    11. **Compliance**: Verify UI uses "Send" terminology, not "Trade" or "Swap".
    12. **Compliance**: Implement `LocalConfigFlag` (hardcoded, no remote config).
    13. **Protocol Call Validation**: Instrument every protocol call (KML, BCL, TE).

---

### 🔄 Cycle 6: Transaction Engine (TE) - Signing & Broadcast

**Goal**: The "Dangerous" Part. Sign the simulated transaction and broadcast to network.

- [ ] **Pre-Integration Validation** (Section 4.5.1):
    - [ ] **Protocol Contract**: `SignerProtocol` defined with exact signatures.
    - [ ] **Isolated Tests**: Signer passes 100% unit tests in isolation (with mocked KML).
    - [ ] **Mock Boundary**: Signer tested with mocked KML; KML tested with mocked Signer.
    - [ ] **Data Contract**: Signed transaction format matches BCL's expected format.

- [ ] **Integration Boundary Validation** (Section 4.5.2) - Signer ↔ KML & BCL:
    - [ ] **Data Handoff KML → Signer**: Key access request → Auth → Sign flow validated.
    - [ ] **Data Handoff Signer → BCL**: Signed transaction format validated.
    - [ ] **Error Propagation**: Signing errors → User-friendly messages validated.
    - [ ] **State Transition**: Signing state changes are atomic (no partial signatures).

- [ ] **Validation Gates**:
    - [ ] **Point A**: `SignerProtocol` implemented exactly.
    - [ ] **Point E (Sim)**: Final simulation run BEFORE signing prompt - validated at boundary.
    - [ ] **Point E (Sim)**: Simulation → Sign flow is atomic (no signing without simulation).
    - [ ] **Point G (Compliance)**: Auth (FaceID/TouchID) MUST appear before signing (mandatory) - boundary test.
    - [ ] **Point G (Compliance)**: Transaction is P2P only (no swap/exchange/batch) - validated at boundary.
    - [ ] **Point G (Compliance)**: All broadcast errors are user-friendly (no raw blockchain codes).
    - [ ] **Point D (Integration)**: Broadcast hash returned and stored in History - validated at boundary.
    - [ ] **Point D (Integration)**: Sign → Broadcast → History flow works end-to-end.

- [ ] **Post-Integration Validation** (Section 4.5.3):
    - [ ] **Smoke Tests**: Full flow Simulation → Sign → Broadcast → History works end-to-end.
    - [ ] **State Consistency**: Signing state doesn't conflict with other module states.
    - [ ] **Regression**: All Cycle 1-5 tests still pass.
    - [ ] **Security Validation**: Keys never exposed outside Secure Enclave (boundary test).

- **Tasks**:
    1.  Define `SignerProtocol.swift` (with exact signatures).
    2.  **Incremental Validation**: Implement `SimpleP2PSigner` (test each method in isolation).
    3.  **Boundary Validation**: Test KML → Signer boundary (key access, auth flow).
    4.  **Boundary Validation**: Test Signer → BCL boundary (signed tx format, error handling).
    5.  Implement `broadcast(signedTx:)` in BCL (test in isolation first).
    6.  **State Transition Validation**: Test signing state machine (pending → auth → signing → signed).
    7.  Build "Confirm Transaction" screen (The "Auth Gate") - test auth prompt appears.
    8.  **Error Boundary Validation**: Test all error paths (auth failure, signing failure, broadcast failure).
    9.  Test on Testnet (Goerli/Sepolia) - validate end-to-end flow.
    10. **Compliance**: Verify LocalAuthentication prompt appears before every sign operation (boundary test).
    11. **Compliance**: Verify transaction type validation (reject swap/exchange transactions) (boundary test).
    12. **Compliance**: Test error handling for broadcast failures (network errors, etc.).
    13. **Protocol Call Validation**: Instrument every protocol call (KML, BCL).
    14. **Security Validation**: Verify keys never leave Secure Enclave (boundary test).

---

### 🔄 Cycle 7: Recovery Engine (R-E)

**Goal**: Ensure user can recover funds if device is lost (Shamir Secret Sharing).

- [ ] **Pre-Integration Validation** (Section 4.5.1):
    - [ ] **Protocol Contract**: `RecoveryStrategyProtocol` defined with exact signatures.
    - [ ] **Isolated Tests**: R-E passes 100% unit tests in isolation (with mocked storage).
    - [ ] **Mock Boundary**: R-E tested with mocked storage; storage tested with mocked R-E.
    - [ ] **Data Contract**: Recovery share format matches expected structure.

- [ ] **Integration Boundary Validation** (Section 4.5.2) - R-E ↔ KML & Storage:
    - [ ] **Data Handoff R-E → Storage**: Share storage format validated (no key exposure).
    - [ ] **Data Handoff Storage → R-E**: Share retrieval format validated.
    - [ ] **Error Propagation**: Recovery errors → User-friendly messages validated.
    - [ ] **State Transition**: Recovery state changes are atomic (no partial recovery).

- [ ] **Validation Gates**:
    - [ ] **Point A**: `RecoveryStrategyProtocol` implemented exactly.
    - [ ] **Point B (Unit)**: Split seed → Recombine shares = Exact original seed - validated.
    - [ ] **Point B (Unit)**: 2 of 3 shares fails; 3 of 3 succeeds - boundary conditions tested.
    - [ ] **Point B (Unit)**: All error paths tested (invalid shares, corrupted shares, missing shares).
    - [ ] **Point B (Unit)**: Boundary conditions tested (empty seed, very long seed, special characters).
    - [ ] **Point G (Compliance)**: Recovery phrase is NEVER sent to server - boundary test.
    - [ ] **Point G (Compliance)**: Recovery shares stored locally only (no network calls).

- [ ] **Post-Integration Validation** (Section 4.5.3):
    - [ ] **Smoke Tests**: Full flow Generate → Split → Store → Retrieve → Reconstruct works end-to-end.
    - [ ] **State Consistency**: Recovery state doesn't conflict with other module states.
    - [ ] **Regression**: All Cycle 1-6 tests still pass.
    - [ ] **Security Validation**: Seeds never exposed outside recovery flow (boundary test).

- **Tasks**:
    1.  Define `RecoveryStrategyProtocol.swift` (with exact signatures).
    2.  **Incremental Validation**: Implement `ShamirHybridRecovery` (test split/reconstruct in isolation).
    3.  **Boundary Validation**: Test R-E → Storage boundary (share format, no key exposure).
    4.  **Boundary Validation**: Test Storage → R-E boundary (share retrieval, error handling).
    5.  **State Transition Validation**: Test recovery state machine (generating → splitting → storing → reconstructing).
    6.  Build "Onboarding/Backup" flow - test UI flow.
    7.  **Error Boundary Validation**: Test all error paths (invalid shares, storage failure, reconstruction failure).
    8.  Test backup and restore flow on fresh simulator - validate end-to-end.
    9.  **Compliance**: Verify recovery phrase never sent to server (boundary test).
    10. **Protocol Call Validation**: Instrument every protocol call (Storage).
    11. **Security Validation**: Verify seeds never exposed outside Secure Enclave (boundary test).

---

### 🔄 Cycle 8: UI Polish & Final Compliance

**Goal**: The "App Store Ready" Polish and comprehensive compliance verification with complete validation checkpoint audit.

- [ ] **Pre-Integration Validation** (Section 4.5.1) - Final System Check:
    - [ ] **Protocol Contracts**: All protocols verified for exact signature compliance.
    - [ ] **Isolated Tests**: All modules pass 100% unit tests in isolation.
    - [ ] **Mock Boundaries**: All module boundaries tested with mocks.

- [ ] **Integration Boundary Validation** (Section 4.5.2) - Complete System Audit:
    - [ ] **All Data Handoffs**: Every module → module data handoff validated.
    - [ ] **All Error Boundaries**: Every error propagation path validated.
    - [ ] **All State Transitions**: Every state change validated for atomicity.
    - [ ] **All Protocol Calls**: Every protocol method call instrumented and validated.

- [ ] **Validation Gates**:
    - [ ] **Point G (Compliance)**: Full audit against Section 3.1 Compliance Checklist (ALL items).
    - [ ] **Point G (Compliance)**: Privacy Policy visible and accessible from Settings.
    - [ ] **Point G (Compliance)**: Privacy Policy URL included in App Store Connect.
    - [ ] **Point F (Regression)**: Full automated suite green (all cycles 1-7 still pass).
    - [ ] **Point F (Regression)**: All validation checkpoints from cycles 1-7 still pass.
    - [ ] **Point E**: All error messages are localized and friendly (zero technical jargon).
    - [ ] **Point E**: All error boundaries tested and validated.
    - [ ] **Point G (Compliance)**: Code scan confirms no BLE/NFC imports.
    - [ ] **Point G (Compliance)**: Code scan confirms no WebView/WKWebView usage.
    - [ ] **Point G (Compliance)**: Code scan confirms no remote config calls.
    - [ ] **Point G (Compliance)**: Code scan confirms no swap/exchange/trading logic.

- [ ] **Post-Integration Validation** (Section 4.5.3) - System-Wide Certainty:
    - [ ] **Smoke Tests**: Complete end-to-end flows validated (onboarding → send → receive → recovery).
    - [ ] **State Consistency**: All module states verified for consistency.
    - [ ] **Regression**: 100% of all previous tests pass.
    - [ ] **Validation Certainty**: All Validation Certainty Requirements (see Incremental Validation Strategy) verified.

- **Tasks**:
    1.  **Validation Checkpoint Audit**: Verify all Pre-Integration validations from cycles 1-7 passed.
    2.  **Validation Checkpoint Audit**: Verify all Integration Boundary validations from cycles 1-7 passed.
    3.  **Validation Checkpoint Audit**: Verify all Post-Integration validations from cycles 1-7 passed.
    4.  **Compliance Audit**: Run automated compliance scanner (see ComplianceAudit.swift).
    5.  **Compliance Audit**: Manual review of all UI screens for forbidden terminology.
    6.  **Compliance Audit**: Verify Privacy Policy is complete and accurate.
    7.  **Compliance Audit**: Test all error paths display user-friendly messages.
    8.  **Compliance Audit**: Verify no analytics/tracking without consent.
    9.  **Compliance Audit**: Verify all V2.0 feature flags are hardcoded to `false`.
    10. **Compliance Audit**: Verify no hidden features or geo-fencing.
    11. **Boundary Validation**: Re-test all critical boundaries (KML → Signer, BCL → TE, etc.).
    12. **Error Boundary Validation**: Re-test all error boundaries for proper handling.
    13. **State Transition Validation**: Re-test all state transitions for atomicity.
    14. **UI Polish**: Audit all error alerts for non-technical language.
    15. **UI Polish**: Check dark mode / responsiveness / accessibility.
    16. **App Store Prep**: Prepare App Store metadata (description, screenshots, privacy URL).
    17. **Final Verification**: Run full regression test suite (all cycles).
    18. **Final Verification**: Perform manual App Store review simulation.
    19. **Final Verification**: Verify all validation certainty requirements met.

---

## 🔍 Compliance Audit Tools

### 🚫 Forbidden Libraries & Patterns List (V1.0)

**CRITICAL**: The following are **EXPLICITLY FORBIDDEN** in V1.0. The Agent must assert this list at every cycle.

#### Forbidden Frameworks/Libraries:
- ❌ **CoreBluetooth** - No Bluetooth Low Energy functionality
- ❌ **CoreNFC** - No Near Field Communication functionality
- ❌ **WebKit** - No WKWebView, no UIWebView, no web browsing
- ❌ **Firebase Remote Config** - No remote configuration
- ❌ **JavaScriptCore** - No JavaScript injection
- ❌ **dlopen/dlsym** - No dynamic code loading

#### Forbidden Patterns:
- ❌ **Key Export** - No functionality to export, copy, or transmit private keys
- ❌ **Raw Blockchain Errors** - No raw error codes (revert, gas failures) shown to users
- ❌ **Swap/Exchange/Trade Terminology** - No trading language in UI or code
- ❌ **Analytics Without Consent** - No tracking without explicit user consent
- ❌ **Background Web3 RPC Calls** - No background blockchain calls
- ❌ **Hidden Features** - No code paths hidden from App Store reviewers
- ❌ **Geo-Fencing** - No IP/location-based feature hiding
- ❌ **Remote Feature Flags** - No remote configuration of features

**The Agent must scan for these violations at EVERY cycle and BLOCK progression if found.**

### 🔒 V1.0 Zero-Mutation Rule

**CRITICAL**: V1.0 must be **FROZEN** so App Store reviewers see:

- ✅ No hidden dApp browser
- ✅ No ghost mode vault
- ✅ No MPC signing
- ✅ No ZK-proof features
- ✅ No unreachable code paths
- ✅ No dormant modules
- ✅ No commented-out experiments

**Explicit Instruction**: All V2.0 features must be **excluded from the V1.0 binary at compile-time**.

**Required Actions**:
1. **No Partial Files**: V2.0 modules must not exist in V1.0 codebase
2. **No Dormant Modules**: No V2.0 code that can be activated
3. **No Commented Code**: No experimental V2.0 code in comments
4. **Protocol Acknowledgment Only**: Only the P-Tier protocols may acknowledge V2.0's future existence

**The Agent must verify this at Cycle 8 before release candidate.**

### Automated Compliance Scanner

Create `ComplianceAudit.swift` in test target to scan for violations:

```swift
// Example compliance checks (to be implemented in Cycle 1)
func testNoBLEImports() {
    // Scan for CoreBluetooth imports
}
func testNoNFCImports() {
    // Scan for CoreNFC imports
}
func testNoWebViewUsage() {
    // Scan for WKWebView/UIWebView usage
}
func testNoRemoteConfig() {
    // Scan for Firebase Remote Config or CDN config calls
}
func testNoSwapLogic() {
    // Scan for swap/exchange/trading keywords
}
func testNoKeyExport() {
    // Verify KeyStoreProtocol has no export methods
}
func testNoV2Features() {
    // Scan for V2.0 module imports/existence
}
func testNoJavaScriptInjection() {
    // Scan for JavaScriptCore usage
}
func testNoDynamicLoading() {
    // Scan for dlopen/dlsym usage
}
```

### Manual Compliance Checklist

Before marking Cycle 8 complete, manually verify:
- [ ] All items in **Spec.md Section 3.1** (Apple App Store Compliance Checklist)
- [ ] Privacy Policy is accessible and accurate
- [ ] App Store Connect metadata includes Privacy Policy URL
- [ ] All error messages reviewed for technical jargon
- [ ] UI terminology reviewed for compliance (P2P only, no trading language)

---

**End of Build Plan**

