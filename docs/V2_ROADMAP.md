# KryptoClaw Development Task Breakdown

This document outlines the remaining work for KryptoClaw, divided into three distinct groups suitable for parallel development by separate models/agents.

## Group 1: Core Blockchain & Security (Critical/Backend)
**Focus:** Cryptography, Transaction Signing, and Wallet Logic using `WalletCore`.
**Goal:** Replace all stubs with real, secure blockchain interactions.

1.  **Solana Transaction Signing (`SolanaTransactionService.swift`)**
    *   **Task:** Implement `sign(message:privateKey:)` and `sendSol(...)` using `WalletCore`'s `SolanaSigner`.
    *   **Requirements:** Use Ed25519, handle blockhash, serialization, and returning the signed base64 transaction string.
    *   **Context:** `Sources/KryptoClaw/Core/Blockchain/SolanaTransactionService.swift`.

2.  **Bitcoin Transaction Construction (`BitcoinTransactionService.swift`)**
    *   **Task:** Implement UTXO selection and transaction building using `WalletCore`'s `BitcoinScript` and `BitcoinTransaction`.
    *   **Requirements:** Calculate fees (sat/vB), sign inputs, and serialize for broadcast.
    *   **Context:** `Sources/KryptoClaw/Core/Blockchain/BitcoinTransactionService.swift`.

3.  **Secure Enclave & Key Storage Hardening**
    *   **Task:** Review `SecureEnclaveKeyStore.swift` and ensure keys are never exposed in memory longer than necessary. Implement `SecureBytes` if not present.
    *   **Context:** `Sources/KryptoClaw/SecureEnclaveKeyStore.swift`.

---

## Group 2: Data Integration & Networking (API/Middleware)
**Focus:** Real-world data fetching, APIs, and connecting the app to the blockchain.
**Goal:** Replace mock data providers with real live data.

1.  **Transaction History Indexer (`ModularHTTPProvider.swift`)**
    *   **Task:** Implement `fetchHistory(address:chain:)` using real APIs.
    *   **APIs:** Etherscan (ETH), Mempool.space (BTC), Solscan/Helius (SOL).
    *   **Requirements:** Parse JSON responses into `TransactionHistory` models. Remove mock data.
    *   **Context:** `Sources/KryptoClaw/ModularHTTPProvider.swift`.

2.  **DEX Aggregator Integration (`DEXAggregator.swift`)**
    *   **Task:** Implement `getQuote(...)` to query real DEX APIs.
    *   **APIs:** 1inch (EVM), Jupiter (Solana).
    *   **Requirements:** Return real price impact, estimated gas, and call data.
    *   **Context:** `Sources/KryptoClaw/Core/DEX/DEXAggregator.swift`.

3.  **NFT Data Provider (`HTTPNFTProvider.swift`)**
    *   **Task:** Implement `fetchNFTs(address:)` to replace `MockNFTProvider`.
    *   **APIs:** OpenSea, MagicEden, or a multichain indexer like SimpleHash.
    *   **Requirements:** Fetch images and metadata asynchronously.
    *   **Context:** `Sources/KryptoClaw/NFTProviderProtocol.swift`.

---

## Group 3: UI/UX Polish & Advanced Features (Frontend)
**Focus:** User experience, visual assets, and advanced interaction flows.
**Goal:** Make the app look professional and complete the user journey.

1.  **Chain Logo Assets (`HomeView.swift` & `UIComponents.swift`)**
    *   **Task:** Replace placeholder circles with actual logo assets for ETH, BTC, SOL, and popular tokens.
    *   **Requirements:** Add assets to `Assets.xcassets`, update `Chain` enum to return correct image names, handle loading states.
    *   **Context:** `Sources/KryptoClaw/HomeView.swift`.

2.  **Clipboard Guard UI Feedback**
    *   **Task:** Improve the visual feedback when Clipboard Guard is triggered.
    *   **Requirements:** Show a clear toast or status indicator that the address was copied safely and/or cleared after usage.
    *   **Context:** `Sources/KryptoClaw/HomeView.swift`.

3.  **Transaction Simulation Visualization (`SendView.swift`)**
    *   **Task:** Improve how simulation results are displayed to the user.
    *   **Requirements:** Show detailed "Expected Changes" (e.g., "-0.1 ETH", "+100 USDT"), gas cost in USD, and explicit risk warnings.
    *   **Context:** `Sources/KryptoClaw/SendView.swift`.
