# App Store Submission Steps

## Pre-Submission Checklist

- [x] Info.plist configured with Face ID and export compliance
- [x] Build compiles successfully
- [x] Privacy manifest (PrivacyInfo.xcprivacy) complete
- [x] App icons generated
- [ ] Screenshots generated (see SCREENSHOT_GUIDE.md)
- [ ] App Store Connect account setup
- [ ] App Store Connect metadata prepared

## Step 1: Archive the App

1. Open Xcode
2. Select **Any iOS Device** (not simulator) from device selector
3. Go to **Product > Archive**
4. Wait for archive to complete (may take a few minutes)

## Step 2: Upload to App Store Connect

1. In Xcode Organizer (Window > Organizer), select your archive
2. Click **Distribute App**
3. Select **App Store Connect**
4. Click **Next**
5. Choose **Upload** (not Export)
6. Select your team/certificate
7. Click **Upload**
8. Wait for upload to complete (10-30 minutes)

## Step 3: Complete App Store Connect Metadata

### App Information
- **Name**: KryptoClaw
- **Subtitle**: The "Coloring Book" Crypto Wallet
- **Category**: Finance
- **Age Rating**: 4+

### Description
```
KryptoClaw is a secure, non-custodial cryptocurrency wallet designed for iOS.

FEATURES:
• Secure Enclave Storage - Your private keys never leave your device
• Biometric Authentication - FaceID/TouchID for every transaction
• Multi-Chain Support - Ethereum, Bitcoin, and Solana
• Theme Engine - Customize your wallet's appearance
• Privacy First - No tracking, no analytics, no data collection

SECURITY:
• Keys stored in iOS Secure Enclave
• No server storage or cloud backups
• Local transaction simulation before signing
• User-friendly error messages

KryptoClaw is built for users who value security and privacy. Your keys, your crypto, your control.
```

### Keywords
`cryptocurrency, wallet, bitcoin, ethereum, solana, crypto, blockchain, secure, non-custodial, defi`

### URLs
- **Privacy Policy**: https://kryptoclaw.app/privacy
- **Support**: mailto:support@kryptoclaw.app
- **Marketing**: https://kryptoclaw.app

### Screenshots
Upload screenshots for:
- iPhone 6.7" (5 screenshots)
- iPad 12.9" (5 screenshots)

See `SCREENSHOT_GUIDE.md` for generation instructions.

## Step 4: App Review Information

### Review Notes (Critical for Crypto Apps)
```
This is a non-custodial cryptocurrency wallet. Key points for reviewers:

1. NON-CUSTODIAL: Users control their own private keys. Keys are stored locally in iOS Secure Enclave.

2. NO TRADING: This app does NOT facilitate trading, exchanges, or fiat onramps. It only enables peer-to-peer cryptocurrency transfers.

3. NO SERVER COMPONENTS: All functionality is local. No user data is collected or transmitted.

4. TESTING: 
   - Launch app to generate a new wallet
   - Use FaceID/TouchID when prompted
   - Navigate through screens to see features
   - Send screen requires testnet funds (not needed for review)

5. PRIVACY: No tracking, no analytics, no data collection. Privacy policy available at https://kryptoclaw.app/privacy

6. COMPLIANCE: Export compliance answered (standard encryption only).
```

### Contact Information
- **First Name**: [Your Name]
- **Last Name**: [Your Name]
- **Phone**: [Your Phone]
- **Email**: support@kryptoclaw.app

## Step 5: Export Compliance

Answer the export compliance questions:
- **Uses Encryption**: Yes
- **Exempt**: Yes (standard encryption only)
- **Info.plist Key**: `ITSAppUsesNonExemptEncryption` = false

## Step 6: Submit for Review

1. In App Store Connect, go to your app version
2. Review all information
3. Click **Submit for Review**
4. Monitor review status (typically 24-48 hours)

## Post-Submission

- Monitor App Store Connect for review status updates
- Respond promptly to any reviewer questions
- Be prepared to explain crypto functionality if asked

## Common Rejection Reasons (Crypto Apps)

1. **Guideline 3.1.5(b)**: Trading platform concerns
   - **Mitigation**: Clearly state this is P2P only, no trading

2. **Guideline 2.1**: App completeness
   - **Mitigation**: Ensure all features work, no placeholders

3. **Guideline 5.1.1**: Privacy concerns
   - **Mitigation**: Privacy policy accessible, no tracking

## Support

If you encounter issues:
1. Check App Store Connect for specific rejection reasons
2. Review Apple's App Store Review Guidelines
3. Contact Apple Developer Support if needed

