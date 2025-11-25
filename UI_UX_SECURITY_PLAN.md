# UI/UX Security Integration Plan

## Objective
Extend the existing UI/UX to fully integrate newly implemented security features (Secure Enclave, Biometric Binding, HSK) across all themes, ensuring a seamless, educational, and accessible user experience.

## 1. Theme Engine Updates
**Goal**: Ensure all themes have consistent security indicators.
- [x] Verify `iconShield` and `securityWarningColor` exist in `ThemeProtocolV2`. (Verified)
- [ ] Add `secureEnclaveColor` (e.g., a specific green or gold) to `ThemeProtocolV2` to differentiate "standard security" from "hardware-backed security".
- [ ] Update all themes to provide this new color token.

## 2. Component Development
**Goal**: Create reusable UI components for security feedback.
- [ ] **`SecurityBadge`**: A capsule-style badge showing "Secure Enclave Protected" or "Standard Encryption".
- [ ] **`BiometricStatusView`**: A view in Settings showing the status of FaceID/TouchID binding (Active/Inactive/Reset Detected).
- [ ] **`SecurityEducationTooltip`**: A popover or inline info box explaining *why* a feature is secure (e.g., "Your keys never leave the device").

## 3. Onboarding Enhancements
**Goal**: Educate users about security choices upfront.
- [ ] Update `OnboardingView` to include a "Security Level" indicator when creating a wallet.
- [ ] Add a dedicated "Security Setup" step after wallet creation to prompt for Biometric Binding immediately if not already done.

## 4. Settings & Wallet Management
**Goal**: Provide transparency and control.
- [ ] Update `SettingsView` to display the `SecurityBadge` prominently at the top.
- [ ] Add a "Security Center" section in Settings:
    - Biometric Binding Status
    - Hardware Key (HSK) Status
    - Jailbreak Detection Status (Green checkmark if safe)
- [ ] Add visual feedback for "Biometric Reset" (if the OS reports a change in biometrics, show a warning that keys were wiped).

## 5. Accessibility & Localization
**Goal**: Ensure inclusivity.
- [ ] Add `accessibilityLabel` and `accessibilityHint` to all new security controls.
- [ ] Ensure high contrast for security warnings (red/orange against backgrounds).
- [ ] Support Dynamic Type for all new text elements.

## Implementation Steps

### Step 1: Update Theme Engine
Modify `ThemeEngine.swift` to include `secureEnclaveColor`.

### Step 2: Create Security Components
Create `Sources/KryptoClaw/UI/Components/SecurityBadge.swift` and `Sources/KryptoClaw/UI/Components/BiometricStatusView.swift`.

### Step 3: Integrate into Settings
Modify `SettingsView.swift` to include the new Security Center section.

### Step 4: Integrate into Onboarding
Modify `OnboardingView.swift` to highlight security features.

### Step 5: Verify & Polish
Run the app (mental check) and ensure all themes look consistent.
