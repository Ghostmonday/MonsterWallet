# KryptoClaw V2.0 Roadmap & Execution Plan

**Objective**: Evolve KryptoClaw from a single-currency V1.0 foundation into a feature-complete, multi-currency, themeable DeFi powerhouse.

---

## 📅 Phase 1: Core Infrastructure (✅ COMPLETE)
*   **Status**: V1.0 Released.
*   **Foundation**: Secure Enclave, WalletStateManager, Transaction Engine, Theme Engine V1.
*   **Compliance**: App Store Ready, Privacy Policy, No Forbidden Frameworks.

---

## 📅 Phase 2: Multi-Currency Support (The Backend Expansion)
**Goal**: Expand the wallet to support ETH, BTC, SOL, and USDC natively.
**Constraint**: Must be completed BEFORE any UI work or third-party integrations.

### 2.1 Provider Abstraction
- [ ] Refactor `BlockchainProviderProtocol` to support multiple chains.
- [ ] Implement `BitcoinProvider` (UTXO model).
- [ ] Implement `SolanaProvider` (SPL model).
- [ ] Update `ModularHTTPProvider` to route requests based on chain ID.

### 2.2 Balance & State Management
- [ ] Update `WalletStateManager` to hold a dictionary of balances: `[Chain: Balance]`.
- [ ] Update `Transaction` struct to include `chainId` and `tokenContractAddress`.
- [ ] Implement `TokenStandard` enum (ERC20, SPL, etc.).

### 2.3 Gas & Fees
- [ ] Implement chain-specific gas estimators (Sat/vB for BTC, Lamports for SOL).
- [ ] Update `BasicGasRouter` to handle multi-chain fee logic.

---

## 📅 Phase 3: Third-Party Integrations (The Feature Layer)
**Goal**: Integrate external services to provide real utility.
**Constraint**: Use strict service wrappers; no direct API calls from UI.

### 3.1 Fiat On-Ramp
- [ ] **Service**: MoonPay / Ramp.
- [ ] **Task**: Create `FiatOnRampManager`.
- [ ] **Flow**: Select Currency -> Enter Amount -> SDK Handoff -> Callback.
- [ ] **Compliance**: Handle KYC/AML triggers via SDK.

### 3.2 DEX / Swaps
- [ ] **Service**: Uniswap / Sushiswap / Jupiter (SOL).
- [ ] **Task**: Create `DexSwapManager`.
- [ ] **Features**: Token List, Slippage Settings, Quote Fetching.
- [ ] **Security**: Simulate swap transactions before signing.

### 3.3 Market Data
- [ ] **Service**: CoinGecko / Chainlink.
- [ ] **Task**: Create `MarketDataProvider`.
- [ ] **Features**: Real-time prices, 24h change, sparkline data.
- [ ] **Performance**: Implement caching strategy (15s TTL).

### 3.4 Security Intelligence
- [ ] **Service**: Chainalysis / CipherTrace.
- [ ] **Task**: Create `FraudDetectionManager`.
- [ ] **Features**: Address screening, contract risk scoring.

---

## 📅 Phase 4: UI/UX Expansion (The Interface Layer)
**Goal**: Expose the new features via a polished, tab-based interface.
**Constraint**: Strictly follow the "Skin, Not Bones" theming philosophy.

### 4.1 Navigation Structure
- [ ] Implement `TabBarView` with 5 tabs:
    1.  **Portfolio**: Multi-asset dashboard.
    2.  **Actions**: Send, Receive, Swap, Buy.
    3.  **Activity**: History & Analytics.
    4.  **Security**: Alerts & Recovery.
    5.  **Settings**: Preferences & Themes.

### 4.2 Portfolio Tab
- [ ] **Multi-Card Layout**: Scrollable cards for ETH, BTC, SOL, USDC.
- [ ] **Total Balance**: Aggregated USD value.
- [ ] **Charts**: 24h/7d/30d line charts (themed).

### 4.3 Actions Tab
- [ ] **Unified Action Center**:
    -   **Send**: Chain selector -> Address -> Amount.
    -   **Receive**: QR Code + Copy Address.
    -   **Swap**: Token A -> Token B interface.
    -   **Buy**: Fiat On-Ramp trigger.
- [ ] **QR Scanner**: Camera overlay for addresses.

### 4.4 Activity & Insights
- [ ] **Transaction List**: Filterable by Chain/Token/Date.
- [ ] **Analytics**: Inflow/Outflow pie charts.
- [ ] **Status Indicators**: Pending, Confirmed, Failed (themed colors).

### 4.5 Security Center
- [ ] **Risk Dashboard**: Active alerts from `BasicHeuristicAnalyzer`.
- [ ] **Recovery Wizard**: Guided flow for seed phrase backup.
- [ ] **Biometric Toggle**: FaceID/TouchID control.

---

## 📅 Phase 5: Theme System V2 & Generation Pipeline
**Goal**: Scale theme production to hundreds of high-quality, compliant skins.

### 5.1 Expanded Theme Protocol
- [ ] Update `ThemeProtocol` documentation to cover new UI slots (Charts, Swaps, Alerts).
- [ ] **No New Slots**: Reuse existing slots (`accentColor`, `backgroundSecondary`) for new features.

### 5.2 Automated Theme Pipeline
**Input**: List of Theme Names (e.g., "Winter Glow", "Cyber Punk").

**Step 1: Generation**
- [ ] **LLM Prompt**: Expand name to JSON definition (Colors, Fonts, Icons, Vibe).
- [ ] **Brand Safety**: Filter trademarked terms (e.g., "Nintendo" -> "Retro Console").

**Step 2: Validation**
- [ ] **Programmatic**: Check WCAG contrast, Dark Mode compliance, Icon validity.
- [ ] **Visual**: Render snapshots of all 6 core screens.

**Step 3: Vision QA Gate (Gemini)**
- [ ] **Compliance Check**: "Is text legible? Are icons correct?"
- [ ] **Quality Score**: "Aesthetic harmony (0-10), Emotional resonance (0-10)."
- [ ] **Threshold**: Only themes scoring > 8.5 pass.

**Step 4: Packaging**
- [ ] **Output**: Swift Structs ready for `ThemeCatalog`.
- [ ] **Bundles**: "Holiday Pack", "Sports Pack", "Retro Pack".

---

## 📝 Execution Checklist

- [ ] **Phase 2**: Multi-Currency Backend
- [ ] **Phase 3**: Integrations (Fiat, DEX, Data, Security)
- [ ] **Phase 4**: UI Expansion (Tabs, Charts, Swaps)
- [ ] **Phase 5**: Theme Pipeline & V2 Guide

**Ready to Execute.**
