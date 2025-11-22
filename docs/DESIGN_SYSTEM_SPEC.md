# 🎨 KryptoClaw Design System: "Electric Crayon"
**Version 1.0 | Status: APPROVED | Target: iOS 17+**

---

## 1. 🌟 Emotional Narrative & Philosophy
**"Crypto doesn't have to be cold. It should be colorful."**

KryptoClaw is not just a wallet; it is a **digital playground for value**. The interface is designed to evoke the feeling of opening a fresh box of high-end markers—tactile, vibrant, and full of potential.

*   **Empowerment**: Large, confident touch targets make users feel in control. No tiny text, no hidden menus.
*   **Safety**: The "Thick Border" aesthetic implies structural integrity. It feels robust, like a bank vault painted by a street artist.
*   **Joy**: Every interaction yields a satisfying "pop" or "squish." Sending money should feel as satisfying as sending a text message with confetti.

---

## 2. 🧠 Information Architecture (IA)

### 2.1 Core Navigation (The "Claw Pad")
Instead of a traditional tab bar, we use a floating **"Claw Pad"** bottom sheet that morphs based on context.

1.  **Home (The Canvas)**:
    *   **State**: `Idle` (View Balance) -> `Active` (Scroll Assets).
    *   **Primary Action**: "Scan/Send" (Floating Action Button).
2.  **Wallet Actions**:
    *   `Send` -> `Select Asset` -> `Enter Amount` -> `Review` -> `Sign`.
    *   `Receive` -> `Show QR` -> `Share`.
3.  **Settings (The Toolbox)**:
    *   Security, Themes, Network, Support.

### 2.2 User Flows
*   **Onboarding ("The First Stroke")**:
    *   Splash -> "Create" or "Import" -> Biometric Lock -> **Confetti Explosion** -> Home.
*   **Transaction ("The Paper Airplane")**:
    *   Tap "Send" -> UI dims, focus on input -> Slide to Confirm (Haptic heavy) -> "Sent!" Animation.

---

## 3. 🎨 Visual Design System

### 3.1 Color Palette ("The Box of 64")
We use a high-contrast, accessible palette.

| Token | Hex | Usage |
| :--- | :--- | :--- |
| **`InkBlack`** | `#1A1A1A` | Primary Text, Borders, Backgrounds (Dark Mode) |
| **`PaperWhite`** | `#FFFFFF` | Cards, Inputs, Backgrounds (Light Mode) |
| **`ElectricPurple`** | `#8B5CF6` | Primary Brand, Accents, "Active" states |
| **`SlimeGreen`** | `#10B981` | Success, Positive Delta, "Go" buttons |
| **`HotPink`** | `#EC4899` | Alerts, Errors, "Stop" actions |
| **`SkyBlue`** | `#3B82F6` | Info, Links, Ethereum |
| **`SunYellow`** | `#F59E0B` | Bitcoin, Warnings |

### 3.2 Typography ("Rounded & Readable")
*   **Headings**: *Rounded Sans* (e.g., SF Pro Rounded). Bold, Tight Tracking.
    *   `Display`: 34pt, Heavy.
    *   `Title 1`: 28pt, Bold.
*   **Body**: *System Sans* (SF Pro). Legible, Open Tracking.
    *   `Body`: 17pt, Regular.
    *   `Caption`: 13pt, Medium (Uppercase).

### 3.3 The "Thick Line" Shape Language
*   **Borders**: All interactive elements have a **2pt solid border** (`InkBlack` or `PaperWhite`).
*   **Corner Radius**:
    *   Cards: `24pt`
    *   Buttons: `16pt`
    *   Inputs: `12pt`
*   **Shadows**: Hard shadows (No blur).
    *   `PopShadow`: X: 4, Y: 4, Blur: 0, Color: `InkBlack` (opacity 0.2).

---

## 4. 🧩 Component Library

### 4.1 Buttons ("Tactile Taps")
*   **Primary Button ("The Big Press")**:
    *   Height: `56pt`.
    *   Fill: `ElectricPurple`.
    *   Border: 2pt `InkBlack`.
    *   Text: White, Bold, Center.
    *   *Interaction*: Scales down to 95% on press. Shadow disappears.
*   **Secondary Button ("The Outline")**:
    *   Height: `56pt`.
    *   Fill: `Transparent`.
    *   Border: 2pt `InkBlack`.
    *   Text: `InkBlack`, Medium.

### 4.2 Cards ("Asset Tiles")
*   **Asset Row**:
    *   Padding: `16pt`.
    *   Background: `PaperWhite`.
    *   Border: 1pt `InkBlack` (Opacity 0.1).
    *   *Hover*: Border becomes 2pt Solid `ElectricPurple`.

### 4.3 Inputs ("The Drawing Box")
*   **Amount Field**:
    *   Background: `OffWhite` (`#F9FAFB`).
    *   Border: 2pt `InkBlack` (Bottom only).
    *   Font: Monospace (for numbers), Huge (40pt).

---

## 5. 📐 Layout & Responsiveness

### 5.1 The Grid
*   **Margins**: `20pt` (Mobile), `40pt` (Tablet).
*   **Columns**: 1 (Mobile), 2 (Tablet Split View), 3 (Desktop Dashboard).
*   **Spacing Scale**: 4, 8, 16, 24, 32, 48, 64.

### 5.2 Adaptive Layouts
*   **Mobile**: Stacked vertical list. Bottom sheet navigation.
*   **iPad**: Sidebar navigation. "Master-Detail" view for Assets -> History.
*   **Desktop (Mac)**: Three-pane layout. Sidebar / Asset List / Transaction Detail.

---

## 6. ✨ Micro-Interactions & Motion

### 6.1 The "Squish" Effect
All buttons use a spring animation:
```swift
.animation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0))
```

### 6.2 Loading States ("The Scribble")
Instead of a spinner, use a **"Scribble" animation** where a line draws itself in a loop.

### 6.3 Haptic Feedback
*   **Success**: `UINotificationFeedbackGenerator(.success)` (Crisp, double tap).
*   **Error**: `UINotificationFeedbackGenerator(.error)` (Heavy, triple tap).
*   **Selection**: `UISelectionFeedbackGenerator` (Light tick on scroll).

---

## 7. 🚀 Technical Readiness Spec

### 7.1 SwiftUI Implementation Guide
*   **ThemeManager**: Already implemented. Extend with `Color` and `Font` structs defined above.
*   **Components**: Create `KryptoButton`, `KryptoCard`, `KryptoInput` as reusable Views.
*   **Assets**: Export all icons as SVG/PDF vectors.
*   **Dark Mode**: Map `InkBlack` to White and `PaperWhite` to Black in `Assets.xcassets`.

### 7.2 Accessibility (A11y)
*   **Dynamic Type**: All fonts must scale.
*   **VoiceOver**: Every button must have a `.accessibilityLabel`.
*   **Contrast**: Verify 4.5:1 ratio on all text/background pairs.

---

**"This is not just a wallet. It's a statement."**
*Signed, Antigravity.*
