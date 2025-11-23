# Build Plan for KryptoClaw (v1.0 → v2.0)

## Overview
This document outlines the current state of development, what has been completed, and the remaining steps needed to get the app ready for App Store submission and the next major feature milestone (V2 – Elite Multi‑Chain Wallet).

## Completed Milestones
- [x] **Core Architecture** – Multi‑Chain provider, wallet state manager, basic UI scaffolding (real back‑ends for ETH, BTC, SOL)
- [x] **Swap View** – UI for token swap, real price feed via CoinGecko (placeholder DEX aggregator UI)
- [x] **NFT Gallery** – Real NFT fetching using OpenSea API (HTTPNFTProvider) with fallback when API key missing
- [x] **Security** – Address poisoning detection, clipboard guard, secure key store, delete‑all‑data flow added
- [x] **Gas Estimation** – Refactored BasicGasRouter to delegate to provider’s `estimateGas`
- [x] **Settings & Wallet Deletion** – Full‑screen reset flow using `WalletStateManager.deleteAllData()`
- [x] **Repository Cleanup** – Moved dead/unfinished code to `Trash/`, updated dependencies, added `openseaAPIKey` config, fixed `Package.swift`
- [x] **Documentation** – JULES audit, BuildPlan, Competitive analysis added

## Pending Work (Next Sprint)
- [ ] **DEX Aggregator Integration** – Connect to 1inch/Uniswap/Jupiter API to obtain real swap quotes and execute transactions.
- [ ] **Full BTC & SOL Transaction Support** – Implement signing/broadcast for Bitcoin (via `BitcoinKit` or Blockstream API) and Solana (via RPC `sendTransaction`).
- [ ] **Persistence Layer** – Persist wallet state, transaction history, and NFT cache securely (Keychain + encrypted file storage).
- [ ] **App Store Compliance** – Add privacy‑preserving analytics backend, finalize screenshots, and verify all App Store metadata.
- [ ] **Testing & CI** – Expand unit & integration tests for new provider logic, add CI steps for lint, type‑check, and build on macOS.
- [ ] **Theme System V2** – Finalize remaining premium themes and ensure dynamic theming works across all views.

## Build & Release Steps
1. **Update Secrets** – Populate `AppConfig.openseaAPIKey` (environment variable or build config).
2. **Run Build**:
   ```bash
   cd /Users/rentamac/MonsterWallet
   swift build -c release
   ```
3. **Run Tests**:
   ```bash
   swift test
   ```
4. **Archive for App Store** – Open the Xcode project, select **Generic iOS Device**, then **Product → Archive**.
5. **Upload via Transporter** – Validate and submit the archive.

## Repository Structure (post‑cleanup)
```
KryptoClaw/
├─ Sources/
│   ├─ KryptoClaw/               # Core app code
│   │   ├─ AppConfig.swift
│   │   ├─ BlockchainProviderProtocol.swift
│   │   ├─ BasicGasRouter.swift   # Delegates to provider
│   │   ├─ ModularHTTPProvider.swift (real fetchPrice, estimateGas)
│   │   ├─ Core/
│   │   │   ├─ MultiChainProvider.swift (real BTC/SOL back‑ends)
│   │   │   └─ WalletStateManager.swift (deleteAllData)
│   │   ├─ HTTPNFTProvider.swift   # Real NFT fetching
│   │   ├─ SettingsView.swift      # Uses wsm.deleteAllData()
│   │   └─ SwapView.swift          # Real price feed
│   └─ Trash/                     # Deprecated mock code, old stubs, etc.
├─ Tests/
│   └─ KryptoClawTests/
├─ docs/
│   ├─ BuildPlan.md               # ← this file
│   ├─ JULES_WORK_AUDIT.md
│   └─ COMPETITIVE_ANALYSIS.md
└─ Package.swift
```

## Risks & Mitigations
| Risk | Impact | Mitigation |
|------|--------|------------|
| Missing API keys (OpenSea, CoinGecko) | Feature fallback to empty data | Store keys securely in CI, provide graceful UI messages |
| BTC/SOL integration complexity | Delayed V2 release | Use simulated back‑ends for V1, schedule dedicated sprint |
| App Store privacy review | Possible rejection | Keep all novel/risky features disabled via `AppConfig.Features` |

---
*Prepared by the Antigravity assistant on 2025‑11‑23.*
