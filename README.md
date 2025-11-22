# Monster Wallet

**The "Coloring Book" Crypto Wallet.**

Monster Wallet is a secure, non-custodial iOS wallet built with a strict "Skin, Not Bones" philosophy. The core logic (The Bones) is immutable, secure, and compliant, while the UI (The Skin) is fully themeable via a modular JSON-like architecture.

---

## 🚀 Features (V1.0)

*   **Secure Enclave Storage**: Private keys never leave the device's hardware security module.
*   **Biometric Authentication**: FaceID/TouchID required for all transactions.
*   **Theme Engine**: Hot-swappable themes that change colors, fonts, and icons without touching logic.
*   **Local Simulation**: Transactions are simulated locally for gas estimation and risk analysis before signing.
*   **Privacy First**: No tracking, no analytics, no remote config.

---

## 🛠 Architecture

*   **Language**: Swift 5.9
*   **UI Framework**: SwiftUI
*   **Architecture**: Protocol-Oriented (MVVM-ish)
*   **Compliance**: strict V1.0 rules (No WebViews, No Remote Code).

### Directory Structure

```text
MonsterWallet/
├── Sources/MonsterWallet/
│   ├── Core/           # KeyStore, Blockchain, Transaction Logic
│   ├── UI/             # Views, Components, Theme Engine
│   └── App/            # Entry Point, Config
├── Tests/MonsterWalletTests/
│   ├── Unit/           # Logic Tests
│   ├── Integration/    # Simulation Demo
│   └── Compliance/     # Audit Scanner
├── BuildPlan.md        # The Master Plan
├── Spec.md             # The Blueprint
├── ThemeArtistGuide.md # The Designer's Manual
└── V2_ROADMAP.md       # The Future
```

---

## 🎨 Theming

Monster Wallet supports "Style Packs". Designers can create new themes by defining a Swift struct conforming to `ThemeProtocol`. See `ThemeArtistGuide.md` for details.

---

## 🔒 Security

*   **Keys**: Stored in Secure Enclave (`kSecAttrTokenIDSecureEnclave`).
*   **Network**: HTTPS only. No third-party trackers.
*   **Audit**: Automated compliance checks run on every build.

---

## 📜 License

Proprietary. See `LICENSE` file.

---

**Built for the future of DeFi.**
