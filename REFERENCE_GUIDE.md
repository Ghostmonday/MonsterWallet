# KryptoClaw Reference Guide: Comments & Task Mapping

**Purpose:** Master reference document for advanced models to ensure complete understanding of all codebase comments and their associated implementation tasks.

**Last Updated:** 2025-01-27  
**Status:** Active Development Reference

---

## Table of Contents

1. [How to Use This Guide](#how-to-use-this-guide)
2. [Comment-to-Task Mapping](#comment-to-task-mapping)
3. [Task Categories & Priorities](#task-categories--priorities)
4. [Implementation Requirements](#implementation-requirements)
5. [Common Pitfalls & Warnings](#common-pitfalls--warnings)

---

## How to Use This Guide

This guide maps every actionable comment in `comments.md` to its corresponding task analysis in `c-2.md`. When implementing any feature:

1. **Find the comment** in Section 2 (Comment-to-Task Mapping)
2. **Check the task details** in Section 3 (Task Categories)
3. **Review requirements** in Section 4 (Implementation Requirements)
4. **Avoid pitfalls** listed in Section 5

**CRITICAL:** Every comment marked with `TODO`, `V2:`, `Pending`, or `In production` requires implementation. Do not skip any.

---

## Comment-to-Task Mapping

### UX/UI Tasks

#### Task 1: Chain Logo Implementation
**Comment Location:** `Sources/KryptoClaw/HomeView.swift:218`  
**Comment Text:** `// Placeholder for Chain Logo (V2: Replace with Image(chain.logoName))`

**What This Means:**
- Currently shows a placeholder circle with first letter of currency
- Need to replace with actual chain logo images
- Must support ETH, BTC, SOL chains
- Logo should come from `chain.logoName` property (may need to add this to Chain enum)

**Implementation Checklist:**
- [ ] Add `logoName` property to Chain enum (or use existing asset naming convention)
- [ ] Create/obtain logo assets for each chain
- [ ] Implement AsyncImage loading with fallback
- [ ] Add loading state (skeleton/spinner)
- [ ] Handle missing/failed-to-load logos gracefully
- [ ] Add accessibility labels
- [ ] Ensure consistent sizing (40x40 as per current implementation)

**Related Comments:**
- `Sources/KryptoClaw/UIComponents.swift:161` - `// Network image placeholder` (similar pattern)

---

#### Task 2: Shimmer/Skeleton Loading States
**Comment Location:** `Sources/KryptoClaw/HomeView.swift:131`  
**Comment Text:** `// Shimmer or Skeleton`

**What This Means:**
- Currently shows static text "Loading assets..."
- Need animated loading placeholders that match actual content layout
- Should show skeleton frames for asset rows while data loads

**Implementation Checklist:**
- [ ] Create SkeletonRow component matching AssetRow layout
- [ ] Implement shimmer animation (gradient animation)
- [ ] Replace static loading text with skeleton rows
- [ ] Ensure performance with multiple skeleton items
- [ ] Add accessibility announcement for loading state
- [ ] Match theme colors for skeleton appearance

**Current State:** Line 132 shows `Text("Loading assets...")` - this needs replacement

---

#### Task 3: Chain Detail Navigation Integration
**Comment Location:** `Sources/KryptoClaw/ChainDetailView.swift:66, 82`  
**Comment Text:** 
- `Button(action: { /* Navigation to Send with Chain Pre-selected */ })`
- `Button(action: { /* Navigation to Receive with Chain Pre-selected */ })`

**What This Means:**
- Send and Receive buttons in ChainDetailView are currently empty
- Need to navigate to SendView/ReceiveView with chain context
- Chain should be pre-selected/pre-filled in destination views

**Implementation Checklist:**
- [ ] Add chain parameter to SendView initializer
- [ ] Add chain parameter to ReceiveView initializer
- [ ] Implement navigation from ChainDetailView
- [ ] Pre-populate chain selection in SendView
- [ ] Ensure back navigation returns to ChainDetailView
- [ ] Add smooth transition animations
- [ ] Test state preservation across navigation

**Related Comments:**
- `Sources/KryptoClaw/HomeView.swift:143` - `SendView() // Assuming SendView exists and can handle context via environment or init`

---

#### Task 4: Clipboard Guard UI Integration
**Comment Location:** `Sources/KryptoClaw/HomeView.swift:51-52`  
**Comment Text:**
- `// Clipboard Guard Copy Trigger (Hidden or integrated)`
- `// For now, we integrate it into the header for the current address if available`

**What This Means:**
- Clipboard guard functionality exists but UI integration is temporary
- Currently integrated into header address display
- May need dedicated UI element or better visual feedback

**Implementation Checklist:**
- [ ] Review current integration (lines 53-70 in HomeView)
- [ ] Add visual indicator when clipboard protection is active
- [ ] Consider dedicated settings toggle for clipboard guard
- [ ] Add user education tooltip/help text
- [ ] Ensure accessibility announcements for clipboard actions
- [ ] Test clipboard clearing behavior

**Current Implementation:** Lines 54-56 call `walletState.copyCurrentAddress()` which triggers ClipboardGuard

---

#### Task 5: Color Theme Parsing ✅ COMPLETED
**Comment Location:** `Sources/KryptoClaw/WalletManagementView.swift:59`  
**Comment Text:** `// Parse colorTheme in real app`

**Status:** ✅ **IMPLEMENTED** - See `WalletManagementView.swift` lines 99-163

**What Was Done:**
- Created `parseColorTheme()` helper function
- Supports hex colors (#FF0000 or FF0000)
- Supports named colors (red, blue, purple, etc.)
- Fallback to theme accent color
- Updated WalletRow to use parsed colors

**No Further Action Required**

---

#### Task 6: Wallet Creation Verification Step
**Comment Location:** `Sources/KryptoClaw/WalletManagementView.swift:129`  
**Comment Text:** `// Step 3: Verify (Skipped for V1 UI Demo)`

**What This Means:**
- Wallet creation flow has 3 steps: Name → Seed → Verify
- Step 3 (Verify) is currently skipped
- User should re-enter seed phrase to confirm they saved it correctly

**Implementation Checklist:**
- [ ] Create verification UI (seed phrase input)
- [ ] Implement validation logic (compare entered vs original)
- [ ] Add error messages for incorrect entries
- [ ] Allow user to go back and view seed again
- [ ] Add accessibility labels and error announcements
- [ ] Consider preventing screenshots during verification (iOS)
- [ ] Update step flow to require verification before wallet creation

**Current State:** Line 129 shows "Verification Complete" text but no actual verification logic

---

#### Task 7: Wallet Deletion UI ✅ COMPLETED
**Comment Location:** `Sources/KryptoClaw/WalletManagementView.swift:34`  
**Comment Text:** `// Implement delete logic`

**Status:** ✅ **IMPLEMENTED** - See `WalletStateManager.swift` `deleteWallet()` method

**What Was Done:**
- Implemented `deleteWallet(id:)` in WalletStateManager
- Connected `.onDelete` handler in WalletManagementView
- Handles active wallet switching before deletion
- Proper cleanup of keys and wallet list

**No Further Action Required** (though confirmation dialog could be added)

---

#### Task 8: V2 Chain/Asset Detail View Tracking ✅ COMPLETED
**Comment Location:** `Sources/KryptoClaw/HomeView.swift:13`  
**Comment Text:** `// For V2: Track selected chain/asset for detail view`

**Status:** ✅ **IMPLEMENTED** - See `HomeView.swift` lines 14, 126, 154

**What Was Done:**
- `@State private var selectedChain: Chain?` already exists
- Tapping asset row sets `selectedChain = chain`
- `.sheet(item: $selectedChain)` shows ChainDetailView

**No Further Action Required**

---

### High Mathematical Complexity Tasks

#### Task 9: Ed25519 Signing Implementation
**Comment Location:** `Sources/KryptoClaw/Core/Blockchain/SolanaTransactionService.swift:4`  
**Comment Text:** `/// Pending implementation for binary message formatting and Ed25519 signing.`

**What This Means:**
- Current implementation returns dummy base64 string (line 22)
- Need real Ed25519 cryptographic signing
- Need Solana transaction binary formatting
- This is SECURITY-CRITICAL - do not implement without cryptographic expertise

**Implementation Requirements:**
- [ ] **DO NOT** implement from scratch - use well-tested library (e.g., `TweetNacl`, `SolanaKit`)
- [ ] Understand Solana transaction structure:
  - Compact array encoding
  - Account key serialization
  - Instruction encoding
  - Recent blockhash requirement
- [ ] Implement Ed25519 signing via library (not custom crypto)
- [ ] Binary message formatting per Solana spec
- [ ] Transaction serialization (little-endian)
- [ ] Signature verification
- [ ] Comprehensive testing with testnet transactions

**Current State:** Lines 20-21 explicitly state "This is NOT a valid Solana transaction, just a placeholder string"

**CRITICAL WARNING:** 
- 🔴 **DO NOT** implement cryptographic algorithms from scratch
- 🔴 **DO** use battle-tested libraries
- 🔴 **DO** get security audit before production use

**Related Comments:**
- `Sources/KryptoClaw/Core/Blockchain/SolanaTransactionService.swift:21` - Confirms placeholder status

---

#### Task 10: BIP32/BIP44 HD Wallet Derivation
**Comment Location:** `Sources/KryptoClaw/Core/HDWalletService.swift:25`  
**Comment Text:** `// In production, use proper BIP32/BIP44 derivation`

**What This Means:**
- Current implementation uses simplified SHA256-based derivation (line 30)
- Need full BIP32/BIP44 compliant key derivation
- This is CORE WALLET FUNCTIONALITY - critical for multi-account support

**Implementation Requirements:**
- [ ] **DO NOT** implement from scratch - use library (e.g., `BitcoinKit`, `CryptoSwift` BIP32)
- [ ] Implement BIP32 extended key derivation:
  - Master seed → Extended private key
  - Child key derivation (CKD)
  - Hardened vs non-hardened paths
  - Chain code management
- [ ] Implement BIP44 path structure:
  - `m/purpose'/coin_type'/account'/change/address_index`
  - Support multiple coins (ETH: m/44'/60'/0'/0/0, BTC: m/44'/0'/0'/0/0)
- [ ] Replace current `derivePrivateKey()` implementation
- [ ] Add path parameter to derivation function
- [ ] Comprehensive testing with known test vectors

**Current State:** 
- Line 24: "Simplified derivation for V1 - deterministic from mnemonic"
- Line 30: "Use SHA256 to create deterministic private key from mnemonic"
- This is NOT BIP32/BIP44 compliant

**CRITICAL WARNING:**
- 🔴 **DO NOT** use simplified derivation in production
- 🔴 **DO** use BIP32/BIP44 for wallet compatibility
- 🔴 **DO** test with standard wallet recovery phrases

**Related Comments:**
- `Sources/KryptoClaw/Core/HDWalletService.swift:9` - "Simplified mnemonic generation for V1"
- `Sources/KryptoClaw/Core/HDWalletService.swift:10` - "In production, use proper BIP39 library"

---

#### Task 11: Shamir Secret Sharing (SSS) Implementation
**Comment Location:** `Sources/KryptoClaw/ShamirHybridRecovery.swift:61`  
**Comment Text:** `// but good practice if we switched to SSS`

**What This Means:**
- Current implementation uses XOR-based N-of-N splitting
- Comment suggests upgrading to true Shamir Secret Sharing
- Would enable threshold schemes (e.g., 3-of-5 shares)

**Implementation Requirements:**
- [ ] **OPTIONAL** - Current XOR solution works for N-of-N
- [ ] If implementing SSS:
  - Use finite field arithmetic (GF(p) or GF(2^m))
  - Implement polynomial generation
  - Implement Lagrange interpolation
  - Support threshold schemes (k-of-n)
  - Secure random coefficient generation
- [ ] **DO NOT** implement from scratch - use library or reference implementation
- [ ] Test with known SSS test vectors

**Current State:**
- Line 15-16: "V1.0 Limitation: Only N-of-N splitting is supported"
- Line 16: "simple XOR splitting which is secure and easy to implement without complex math"
- Line 60-62: Comments about switching to SSS

**WARNING:**
- 🟡 **LOW PRIORITY** - Current XOR solution is functional
- 🟡 Only implement if threshold schemes are required
- 🟡 Requires advanced mathematical knowledge

---

#### Task 12: Full Transaction Trace Simulation
**Comment Location:** `Sources/KryptoClaw/LocalSimulator.swift:18`  
**Comment Text:** `// For full trace, we'd need Tenderly/Alchemy Simulate API.`

**What This Means:**
- Current simulation uses `eth_call` for basic revert detection
- Cannot trace internal calls or balance changes
- Need full transaction trace for complete simulation

**Implementation Requirements:**
- [ ] **RECOMMENDED:** Integrate external API (Tenderly or Alchemy Simulate)
- [ ] If building custom:
  - Full EVM opcode execution
  - State tree traversal
  - Storage slot calculations
  - Contract call stack management
  - Gas calculation per opcode
  - Balance change tracking
- [ ] Add balance change analysis to SimulationResult
- [ ] Extract revert reasons from trace
- [ ] Support for ERC-20 token transfers
- [ ] Handle contract creation costs

**Current State:**
- Line 17: "Partial Simulation (better than mock, but not full trace)"
- Line 114: "Real balance changes need full trace, not available in basic eth_call"
- Uses `eth_call` which only checks revert, not full execution

**RECOMMENDATION:**
- 🟡 **PREFER** API integration over custom implementation
- 🟡 Faster to implement and more reliable
- 🟡 Custom EVM interpreter is extremely complex

---

### Other Important Comments

#### Transaction History Fetching
**Comment Location:** `Sources/KryptoClaw/ModularHTTPProvider.swift:22-23`  
**Comment Text:** 
- `// TODO: Implement actual history fetching (Backlog).`
- `// Use Etherscan API (or similar indexer) for history as standard RPC nodes (like Cloudflare) do not efficiently support "get history by address".`

**What This Means:**
- Currently returns mock transaction data (lines 28-54)
- Need real transaction history from blockchain indexer
- RPC nodes don't efficiently support address history queries

**Implementation Checklist:**
- [ ] Integrate Etherscan API (or similar) for Ethereum
- [ ] Integrate mempool.space or Blockstream API for Bitcoin
- [ ] Integrate Solana explorer API for Solana
- [ ] Handle API rate limiting
- [ ] Cache recent history
- [ ] Pagination support for large histories
- [ ] Error handling for API failures

**Current State:** Lines 28-54 show mock transaction data with hardcoded timestamps

---

#### DEX Aggregator Integration
**Comment Location:** `Sources/KryptoClaw/Core/DEX/DEXAggregator.swift:15-16`  
**Comment Text:**
- `// Mock Implementation`
- `// In production, this would query 1inch/0x/Jupiter APIs in parallel`

**What This Means:**
- Current implementation returns random mock quotes
- Need real DEX aggregator API integration
- Should query multiple providers in parallel for best rates

**Implementation Checklist:**
- [ ] Integrate 1inch API
- [ ] Integrate 0x API
- [ ] Integrate Jupiter API (for Solana)
- [ ] Parallel API calls for best quote
- [ ] Quote comparison and selection logic
- [ ] Error handling and fallbacks
- [ ] Rate limiting management

**Current State:** Lines 20-23 generate random rate and return mock quote string

---

#### Bitcoin Transaction Service
**Comment Location:** `Sources/KryptoClaw/Core/Blockchain/BitcoinTransactionService.swift:4`  
**Comment Text:** `/// Pending implementation using BitcoinKit or similar library.`

**What This Means:**
- Current implementation creates mock transaction bytes
- Need real Bitcoin transaction construction
- Should use established library (BitcoinKit)

**Implementation Checklist:**
- [ ] Integrate BitcoinKit or similar library
- [ ] Implement UTXO fetching
- [ ] Transaction input/output construction
- [ ] Proper signing with private key
- [ ] Transaction broadcasting
- [ ] Fee calculation (sat/vB)

**Current State:** Lines 25-36 create mock transaction bytes, not real Bitcoin transactions

---

#### Gas Estimation for BTC/SOL
**Comment Location:** `Sources/KryptoClaw/ModularHTTPProvider.swift:187-189`  
**Comment Text:**
- `// For V1, we only support ETH gas estimation fully.`
- `// BTC/SOL would have different fee models.`
- `// Return a safe default or throw.`

**What This Means:**
- Gas estimation only works for Ethereum
- Bitcoin uses fee-per-byte (sat/vB) model
- Solana uses fee-per-signature model
- Need chain-specific fee estimation

**Implementation Checklist:**
- [ ] Implement Bitcoin fee estimation (mempool.space API)
- [ ] Implement Solana fee estimation (RPC getFeeForMessage)
- [ ] Update GasEstimate structure to support different fee models
- [ ] Chain-specific fee calculation logic

---

## Task Categories & Priorities

### Priority 1: Critical Security (Must Implement)
1. **BIP32/BIP44 HD Wallet Derivation** - Core wallet functionality
2. **Ed25519 Signing** - Required for Solana support
3. **Transaction History Fetching** - Core feature users expect

### Priority 2: High Value UX
1. **Shimmer/Skeleton Loading** - Improves perceived performance
2. **Wallet Creation Verification** - Prevents user errors
3. **Chain Detail Navigation** - Completes user flows
4. **Chain Logo Implementation** - Professional polish

### Priority 3: Nice to Have
1. **Shamir Secret Sharing** - Advanced feature, current solution works
2. **Full Transaction Trace** - Can use external APIs initially
3. **Clipboard Guard UI** - Current integration works
4. **DEX Aggregator** - Feature enhancement

---

## Implementation Requirements

### For Cryptographic Tasks

**MANDATORY:**
- ✅ Use well-tested libraries (CryptoSwift, BitcoinKit, SolanaKit, TweetNacl)
- ✅ Never implement cryptographic algorithms from scratch
- ✅ Get security audit before production deployment
- ✅ Test with known test vectors
- ✅ Follow established standards (BIP32, BIP44, RFC 8032)

**FORBIDDEN:**
- ❌ Custom cryptographic implementations
- ❌ Skipping security audits
- ❌ Using untested libraries
- ❌ Deviating from standards

### For UX Tasks

**MANDATORY:**
- ✅ Follow existing design system (ThemeProtocolV2)
- ✅ Ensure accessibility (VoiceOver, Dynamic Type)
- ✅ Test on multiple device sizes
- ✅ Provide loading/error states
- ✅ Smooth animations and transitions

**RECOMMENDED:**
- ✅ Prototype in design tools first
- ✅ Get user feedback before implementation
- ✅ Follow iOS Human Interface Guidelines

### For API Integration Tasks

**MANDATORY:**
- ✅ Handle rate limiting
- ✅ Implement proper error handling
- ✅ Add retry logic with exponential backoff
- ✅ Cache responses appropriately
- ✅ Handle network failures gracefully

---

## Common Pitfalls & Warnings

### ⚠️ Critical Mistakes to Avoid

1. **Implementing Cryptography from Scratch**
   - **WRONG:** Writing custom Ed25519 or BIP32 implementation
   - **RIGHT:** Using battle-tested libraries (TweetNacl, BitcoinKit)

2. **Ignoring Security Comments**
   - **WRONG:** Treating security comments as optional
   - **RIGHT:** All security-related comments are MANDATORY

3. **Skipping Validation**
   - **WRONG:** Not validating user inputs (addresses, amounts)
   - **RIGHT:** Always validate, especially for transactions

4. **Mock Data in Production**
   - **WRONG:** Leaving mock implementations in production code
   - **RIGHT:** Replace all mocks with real implementations

5. **Missing Error Handling**
   - **WRONG:** Not handling API failures or network errors
   - **RIGHT:** Comprehensive error handling with user-friendly messages

### 🔴 Security-Sensitive Areas

These comments indicate security-critical code:
- `SolanaTransactionService.swift:4` - Ed25519 signing
- `HDWalletService.swift:25` - BIP32/BIP44 derivation
- `SimpleP2PSigner.swift:40` - ECDSA signing
- `SecureEnclaveKeyStore.swift` - Key storage
- `ClipboardGuard.swift` - Clipboard security

**NEVER** modify security-sensitive code without:
1. Understanding the security implications
2. Testing thoroughly
3. Getting security review
4. Following established patterns

### 🟡 Complexity Warnings

These tasks require specialized knowledge:
- **Ed25519/BIP32/BIP44:** Cryptographic expertise required
- **Shamir Secret Sharing:** Advanced mathematics required
- **EVM Simulation:** Deep blockchain knowledge required
- **Transaction Formatting:** Protocol specification knowledge required

**If unsure:** Use libraries or consult experts. Do not guess.

---

## Quick Reference: Comment Status

| Comment Location | Status | Priority | Complexity |
|-----------------|--------|----------|------------|
| `HomeView.swift:218` | ⏳ Pending | P2 | Medium |
| `HomeView.swift:131` | ⏳ Pending | P2 | Medium |
| `ChainDetailView.swift:66,82` | ⏳ Pending | P2 | Medium |
| `HomeView.swift:51-52` | ⏳ Pending | P3 | Low-Medium |
| `WalletManagementView.swift:59` | ✅ Complete | - | Low |
| `WalletManagementView.swift:129` | ⏳ Pending | P2 | Medium |
| `WalletManagementView.swift:34` | ✅ Complete | - | Low |
| `HomeView.swift:13` | ✅ Complete | - | Low |
| `SolanaTransactionService.swift:4` | ⏳ Pending | P1 | Extremely High |
| `HDWalletService.swift:25` | ⏳ Pending | P1 | Extremely High |
| `ShamirHybridRecovery.swift:61` | ⏳ Optional | P3 | Extremely High |
| `LocalSimulator.swift:18` | ⏳ Pending | P3 | High |
| `ModularHTTPProvider.swift:22` | ⏳ Pending | P1 | Medium |
| `DEXAggregator.swift:15` | ⏳ Pending | P3 | Medium |

**Legend:**
- ✅ Complete - No action needed
- ⏳ Pending - Requires implementation
- 🔴 P1 - Critical priority
- 🟡 P2 - High priority
- 🟢 P3 - Nice to have

---

## Final Checklist Before Implementation

Before starting any task, verify:

- [ ] You understand what the comment is asking for
- [ ] You've read the full context in the source file
- [ ] You've checked this reference guide for requirements
- [ ] You've identified if it's security-sensitive (use libraries!)
- [ ] You've estimated complexity correctly
- [ ] You have the necessary expertise (or will use libraries)
- [ ] You've reviewed related comments in the same file
- [ ] You understand the current implementation state
- [ ] You know what "done" looks like (success criteria)

---

**Remember:** When in doubt, use libraries. When implementing security features, get audits. When building UX, test with users.

