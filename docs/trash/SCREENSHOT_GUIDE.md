# App Store Screenshot Generation Guide

## Overview
KryptoClaw requires screenshots for App Store submission. This guide walks you through generating all required screenshots.

## Required Screenshots

### iPhone 6.7" (iPhone 15 Pro Max)
1. **Home Screen** - Multi-chain balance display
2. **Send Screen** - Transaction form with testnet address
3. **Settings Screen** - Privacy policy link visible
4. **Recovery Screen** - Backup/recovery phrase flow
5. **Theme Selection Screen** - Theme customization showcase

### iPad 12.9" (iPad Pro 6th generation)
Same 5 screenshots as iPhone, optimized for iPad layout.

## Step-by-Step Instructions

### 1. Setup Simulators

```bash
# Open Xcode
open KryptoClaw.xcodeproj

# Or use command line to list available simulators
xcrun simctl list devices available
```

### 2. Build and Run on iPhone Simulator

1. In Xcode, select **iPhone 15 Pro Max** from device selector
2. Press **Cmd+R** to build and run
3. Wait for app to launch

### 3. Navigate and Capture Screenshots

For each required screen:

1. **Home Screen**:
   - App launches here automatically
   - Ensure balance is displayed
   - Press **Cmd+S** or **Device > Screenshot**

2. **Send Screen**:
   - Tap "Send" button on home screen
   - Enter a testnet address (e.g., `0x742d35Cc6634C0532925a3b844Bc454e4438f44e`)
   - Enter an amount
   - Press **Cmd+S** to capture

3. **Settings Screen**:
   - Tap Settings icon (gear) on home screen
   - Ensure Privacy Policy link is visible
   - Press **Cmd+S** to capture

4. **Recovery Screen**:
   - Navigate to Wallet Management (from Settings)
   - Show backup/recovery options
   - Press **Cmd+S** to capture

5. **Theme Selection Screen**:
   - In Settings, scroll to Appearance section
   - Show theme selection options
   - Press **Cmd+S** to capture

### 4. Repeat for iPad

1. Change simulator to **iPad Pro 12.9"**
2. Rebuild and run
3. Capture same 5 screenshots

### 5. Organize Screenshots

Screenshots are saved to Desktop by default. Organize them:

```
AppStoreScreenshots/
├── iPhone-6.7/
│   ├── 01-home.png
│   ├── 02-send.png
│   ├── 03-settings.png
│   ├── 04-recovery.png
│   └── 05-theme.png
└── iPad-12.9/
    ├── 01-home.png
    ├── 02-send.png
    ├── 03-settings.png
    ├── 04-recovery.png
    └── 05-theme.png
```

## Screenshot Requirements

- **Format**: PNG or JPEG
- **Resolution**: 
  - iPhone 6.7": 1290 x 2796 pixels
  - iPad 12.9": 2048 x 2732 pixels
- **Content**: Must show actual app functionality (no placeholders)
- **Quality**: High resolution, no blur

## Tips

1. **Use Testnet Addresses**: For Send screen, use known testnet addresses
2. **Clean State**: Reset simulator if needed: `Device > Erase All Content and Settings`
3. **Consistent Data**: Use same wallet/address across screenshots for consistency
4. **Privacy Mode**: Consider showing privacy mode toggle in Settings screenshot

## Automated Alternative (Fastlane)

If you have Fastlane installed:

```bash
# Install fastlane (if not already installed)
gem install fastlane

# Run snapshot generation
fastlane snapshot
```

This requires a `Snapfile` configuration. See Fastlane documentation for setup.

## Next Steps

After generating screenshots:
1. Review all screenshots for quality
2. Upload to App Store Connect
3. Add to app version metadata
4. Submit for review


