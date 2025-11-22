# Monster Wallet Theme Artist Guide

## 🎨 Philosophy: "The Skin, Not The Bones"

Monster Wallet uses a **Strict Separation of Concerns**. The app logic (The Bones) is immutable and secure. The Theme (The Skin) is where you unleash creativity.

As a Theme Artist, you are providing a **JSON-equivalent configuration** (via Swift structs) that completely transforms the user's emotional experience without touching a single line of business logic.

---

## 📐 The "Coloring Book" Rules

Every theme MUST provide values for these exact slots. You cannot add new slots, but you can use these slots creatively.

### 1. The Palette (Colors)

| Slot Name | Usage | Artistic Directive |
|:---|:---|:---|
| `backgroundMain` | The infinite void behind everything. | **Dark Mode First**. Deep blacks, midnight blues, or textured dark patterns. Avoid pure white. |
| `backgroundSecondary` | Cards, lists, floating elements. | Must contrast with Main. Usually lighter/brighter. Think "Glass" or "Metal". |
| `textPrimary` | Headlines, balances, input text. | **Legibility is King**. High contrast against both backgrounds. |
| `textSecondary` | Subtitles, captions, placeholders. | Subtle but readable. 60-70% opacity of Primary. |
| `accentColor` | Primary buttons, active states, brand moments. | **The "Pop"**. Neon greens, electric blues, hot pinks. This defines the vibe. |
| `successColor` | "Transaction Sent", "Safe". | Must read as "Good/Go". Green, Cyan, Teal. |
| `errorColor` | "Failed", "Danger". | Must read as "Bad/Stop". Red, Crimson, Orange. |
| `warningColor` | "Risk Detected", "Check this". | Yellow, Amber, Gold. |

### 2. The Typography (Fonts)

| Slot Name | Usage | Artistic Directive |
|:---|:---|:---|
| `font(style, weight)` | All text rendering. | You control the typeface. **Monospace** for hacker vibes, **Serif** for luxury, **Rounded** for playful. |

### 3. The Iconography (SF Symbols)

| Slot Name | Usage | Artistic Directive |
|:---|:---|:---|
| `iconSend` | The "Send" button. | Arrow up, rocket, paper plane, bolt. |
| `iconReceive` | The "Receive" button. | Arrow down, wallet, hand, magnet. |
| `iconSettings` | The gear menu. | Gear, sliders, hexagon, hamburger. |
| `iconShield` | The security/recovery icon. | Shield, lock, vault, key. |

---

## 🎭 Theme Archetypes (Inspiration)

### Archetype A: "Cyber-Sec"
*   **Vibe**: Matrix, Terminal, Hacker.
*   **Background**: #000000 (Pure Black)
*   **Accent**: #00FF00 (Terminal Green)
*   **Font**: Monospace (Courier/Menlo)
*   **Icons**: Sharp, geometric.

### Archetype B: "Vegas Gold"
*   **Vibe**: Luxury, Casino, High Roller.
*   **Background**: #1A1A1A (Charcoal)
*   **Accent**: #FFD700 (Gold)
*   **Font**: Serif (New York/Playfair)
*   **Icons**: Filled, heavy.

### Archetype C: "Cotton Candy"
*   **Vibe**: Playful, Web3, NFT.
*   **Background**: #1E1E2E (Deep Purple)
*   **Accent**: #FF79C6 (Hot Pink)
*   **Font**: Rounded (Nunito/System Rounded)
*   **Icons**: Bubble, soft.

---

## ⚠️ Technical Constraints (The "Don'ts")

1.  **NO Dynamic Assets**: You cannot load images from a server. All assets must be SF Symbols or vector code.
2.  **NO Layout Changes**: You cannot move the "Send" button to the top. You can only color it.
3.  **Contrast Compliance**: `textPrimary` on `backgroundMain` must meet WCAG AA standards.
4.  **Dark Mode Only**: V1.0 is optimized for Dark Mode. Light themes are allowed but risky for battery/vibe.

---

## 📝 Deliverable Format

Provide your theme as a Swift Struct:

```swift
struct MyCoolTheme: ThemeProtocol {
    let id = "my_cool_theme"
    let name = "My Cool Theme"
    let isPremium = true
    
    var backgroundMain: Color { Color(hex: "...") }
    // ... implement all protocol requirements
}
```
