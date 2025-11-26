// MODULE: ScreenshotViews2
// VERSION: 1.0.0
// PURPOSE: Screenshot views 7-12 for App Store presentation

import SwiftUI

// MARK: - Screen 7: Swap Preview

struct Screenshot_SwapPreview: View {
    @EnvironmentObject var themeManager: ThemeManager
    private let data = FakeDataProvider.shared
    
    var body: some View {
        let theme = themeManager.currentTheme
        let quote = data.swapQuote
        
        ZStack {
            Color.clear
                .themedContainer(theme: theme, showPattern: true, applyAnimation: false)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Swap")
                        .font(theme.font(style: .title))
                        .foregroundColor(theme.textPrimary)
                    Spacer()
                    
                    // Settings button
                    Image(systemName: "slider.horizontal.3")
                        .foregroundColor(theme.accentColor)
                }
                .padding()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: theme.spacingM) {
                        // From token card
                        KryptoCard {
                            VStack(alignment: .leading, spacing: theme.spacingM) {
                                Text("You Pay")
                                    .font(theme.captionFont)
                                    .foregroundColor(theme.textSecondary)
                                
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(quote.fromAmount)
                                            .font(theme.balanceFont)
                                            .foregroundColor(theme.textPrimary)
                                        Text(quote.fromValue)
                                            .font(theme.captionFont)
                                            .foregroundColor(theme.textSecondary)
                                    }
                                    
                                    Spacer()
                                    
                                    // Token selector
                                    HStack(spacing: theme.spacingS) {
                                        Circle()
                                            .fill(Color.blue.opacity(0.2))
                                            .frame(width: 32, height: 32)
                                            .overlay(
                                                Text("E")
                                                    .font(theme.headlineFont)
                                                    .foregroundColor(.blue)
                                            )
                                        Text(quote.fromToken)
                                            .font(theme.headlineFont)
                                            .foregroundColor(theme.textPrimary)
                                        Image(systemName: "chevron.down")
                                            .font(.caption)
                                            .foregroundColor(theme.textSecondary)
                                    }
                                    .padding(.horizontal, theme.spacingM)
                                    .padding(.vertical, theme.spacingS)
                                    .background(theme.backgroundSecondary)
                                    .cornerRadius(theme.cornerRadius)
                                }
                            }
                        }
                        
                        // Swap direction button
                        ZStack {
                            Circle()
                                .fill(theme.accentColor)
                                .frame(width: 44, height: 44)
                            Image(systemName: "arrow.up.arrow.down")
                                .foregroundColor(.white)
                                .fontWeight(.semibold)
                        }
                        .shadow(color: theme.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                        
                        // To token card
                        KryptoCard {
                            VStack(alignment: .leading, spacing: theme.spacingM) {
                                Text("You Receive")
                                    .font(theme.captionFont)
                                    .foregroundColor(theme.textSecondary)
                                
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(quote.toAmount)
                                            .font(theme.balanceFont)
                                            .foregroundColor(theme.successColor)
                                        Text(quote.toValue)
                                            .font(theme.captionFont)
                                            .foregroundColor(theme.textSecondary)
                                    }
                                    
                                    Spacer()
                                    
                                    // Token selector
                                    HStack(spacing: theme.spacingS) {
                                        Circle()
                                            .fill(Color.green.opacity(0.2))
                                            .frame(width: 32, height: 32)
                                            .overlay(
                                                Text("$")
                                                    .font(theme.headlineFont)
                                                    .foregroundColor(.green)
                                            )
                                        Text(quote.toToken)
                                            .font(theme.headlineFont)
                                            .foregroundColor(theme.textPrimary)
                                        Image(systemName: "chevron.down")
                                            .font(.caption)
                                            .foregroundColor(theme.textSecondary)
                                    }
                                    .padding(.horizontal, theme.spacingM)
                                    .padding(.vertical, theme.spacingS)
                                    .background(theme.backgroundSecondary)
                                    .cornerRadius(theme.cornerRadius)
                                }
                            }
                        }
                        
                        // Quote details card
                        KryptoCard {
                            VStack(spacing: theme.spacingM) {
                                quoteRow("Rate", quote.exchangeRate, theme: theme)
                                quoteRow("Price Impact", quote.priceImpact, theme: theme, valueColor: theme.successColor)
                                quoteRow("Min. Received", quote.minimumReceived, theme: theme)
                                quoteRow("Slippage", quote.slippage, theme: theme)
                                
                                Divider()
                                    .background(theme.borderColor)
                                
                                quoteRow("Network Fee", quote.gasFeeUSD, theme: theme)
                                
                                // MEV Protection badge
                                HStack {
                                    Text("MEV Protection")
                                        .font(theme.bodyFont)
                                        .foregroundColor(theme.textSecondary)
                                    Spacer()
                                    HStack(spacing: theme.spacingXS) {
                                        Image(systemName: "shield.checkered")
                                            .foregroundColor(theme.successColor)
                                        Text("ON")
                                            .fontWeight(.bold)
                                            .foregroundColor(theme.successColor)
                                    }
                                    .font(theme.captionFont)
                                    .padding(.horizontal, theme.spacingS)
                                    .padding(.vertical, theme.spacingXS)
                                    .background(theme.successColor.opacity(0.15))
                                    .cornerRadius(theme.cornerRadius / 2)
                                }
                                
                                // Route
                                HStack {
                                    Text("Route")
                                        .font(theme.bodyFont)
                                        .foregroundColor(theme.textSecondary)
                                    Spacer()
                                    HStack(spacing: 4) {
                                        ForEach(Array(quote.route.enumerated()), id: \.offset) { index, token in
                                            if index > 0 {
                                                Image(systemName: "chevron.right")
                                                    .font(.caption2)
                                                    .foregroundColor(theme.textSecondary)
                                            }
                                            Text(token)
                                                .font(theme.captionFont)
                                                .foregroundColor(theme.textPrimary)
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Swap button
                        KryptoButton(
                            title: "Review Swap",
                            icon: "arrow.right.circle.fill",
                            action: {},
                            isPrimary: true
                        )
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    private func quoteRow(_ label: String, _ value: String, theme: any ThemeProtocolV2, valueColor: Color? = nil) -> some View {
        HStack {
            Text(label)
                .font(theme.bodyFont)
                .foregroundColor(theme.textSecondary)
            Spacer()
            Text(value)
                .font(theme.bodyFont)
                .foregroundColor(valueColor ?? theme.textPrimary)
        }
    }
}

// MARK: - Screen 8: Transaction Simulation

struct Screenshot_TransactionSimulation: View {
    @EnvironmentObject var themeManager: ThemeManager
    private let data = FakeDataProvider.shared
    
    var body: some View {
        let theme = themeManager.currentTheme
        
        ZStack {
            Color.clear
                .themedContainer(theme: theme, showPattern: true, applyAnimation: false)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Transaction Preview")
                        .font(theme.font(style: .title))
                        .foregroundColor(theme.textPrimary)
                    Spacer()
                }
                .padding()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: theme.spacingL) {
                        // Simulation success card
                        KryptoCard {
                            VStack(spacing: theme.spacingM) {
                                ZStack {
                                    Circle()
                                        .fill(theme.successColor.opacity(0.15))
                                        .frame(width: 80, height: 80)
                                    
                                    Image(systemName: "checkmark.shield.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(theme.successColor)
                                }
                                
                                Text("Simulation Passed")
                                    .font(theme.font(style: .title2))
                                    .fontWeight(.bold)
                                    .foregroundColor(theme.successColor)
                                
                                Text("This transaction is safe to execute")
                                    .font(theme.bodyFont)
                                    .foregroundColor(theme.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, theme.spacingM)
                        }
                        
                        // Transaction details
                        KryptoCard {
                            VStack(alignment: .leading, spacing: theme.spacingM) {
                                HStack {
                                    Image(systemName: "doc.text.fill")
                                        .foregroundColor(theme.accentColor)
                                    Text("Transaction Details")
                                        .font(theme.headlineFont)
                                        .foregroundColor(theme.textPrimary)
                                }
                                
                                Divider()
                                    .background(theme.borderColor)
                                
                                detailRow("Action", "Swap ETH → USDC", theme: theme)
                                detailRow("Amount", "0.5 ETH", theme: theme)
                                detailRow("Recipient", "Uniswap V3 Router", theme: theme)
                                detailRow("Network", "Ethereum Mainnet", theme: theme)
                            }
                        }
                        
                        // Gas estimation
                        KryptoCard {
                            VStack(alignment: .leading, spacing: theme.spacingM) {
                                HStack {
                                    Image(systemName: "fuelpump.fill")
                                        .foregroundColor(theme.accentColor)
                                    Text("Gas Estimation")
                                        .font(theme.headlineFont)
                                        .foregroundColor(theme.textPrimary)
                                }
                                
                                Divider()
                                    .background(theme.borderColor)
                                
                                detailRow("Gas Limit", "185,000", theme: theme)
                                detailRow("Gas Price", "25 Gwei", theme: theme)
                                detailRow("Max Fee", "$5.76", theme: theme, valueColor: theme.textPrimary)
                            }
                        }
                        
                        // Balance changes
                        KryptoCard {
                            VStack(alignment: .leading, spacing: theme.spacingM) {
                                HStack {
                                    Image(systemName: "arrow.left.arrow.right")
                                        .foregroundColor(theme.accentColor)
                                    Text("Expected Changes")
                                        .font(theme.headlineFont)
                                        .foregroundColor(theme.textPrimary)
                                }
                                
                                Divider()
                                    .background(theme.borderColor)
                                
                                HStack {
                                    Text("ETH Balance")
                                        .font(theme.bodyFont)
                                        .foregroundColor(theme.textSecondary)
                                    Spacer()
                                    Text("-0.5024")
                                        .font(theme.headlineFont)
                                        .foregroundColor(theme.errorColor)
                                }
                                
                                HStack {
                                    Text("USDC Balance")
                                        .font(theme.bodyFont)
                                        .foregroundColor(theme.textSecondary)
                                    Spacer()
                                    Text("+1,198.45")
                                        .font(theme.headlineFont)
                                        .foregroundColor(theme.successColor)
                                }
                            }
                        }
                        
                        // Confirm section
                        VStack(spacing: theme.spacingS) {
                            Text("Ready to confirm")
                                .font(theme.captionFont)
                                .foregroundColor(theme.textSecondary)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    private func detailRow(_ label: String, _ value: String, theme: any ThemeProtocolV2, valueColor: Color? = nil) -> some View {
        HStack {
            Text(label)
                .font(theme.bodyFont)
                .foregroundColor(theme.textSecondary)
            Spacer()
            Text(value)
                .font(theme.bodyFont)
                .foregroundColor(valueColor ?? theme.textSecondary)
        }
    }
}

// MARK: - Screen 9: Slide to Confirm

struct Screenshot_SlideToConfirm: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var slideProgress: CGFloat = 0.65
    
    var body: some View {
        let theme = themeManager.currentTheme
        
        ZStack {
            Color.clear
                .themedContainer(theme: theme, showPattern: true, applyAnimation: false)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Transaction summary
                VStack(spacing: theme.spacingL) {
                    // Success checkmark (partially shown as if sliding)
                    ZStack {
                        Circle()
                            .fill(theme.accentColor.opacity(0.15))
                            .frame(width: 100, height: 100)
                        
                        Circle()
                            .trim(from: 0, to: slideProgress)
                            .stroke(theme.accentColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .frame(width: 100, height: 100)
                            .rotationEffect(.degrees(-90))
                        
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 40))
                            .foregroundColor(theme.accentColor)
                    }
                    
                    VStack(spacing: theme.spacingS) {
                        Text("Sending")
                            .font(theme.captionFont)
                            .foregroundColor(theme.textSecondary)
                        
                        Text("0.5 ETH")
                            .font(theme.balanceFont)
                            .foregroundColor(theme.textPrimary)
                        
                        Text("$1,201.09")
                            .font(theme.bodyFont)
                            .foregroundColor(theme.textSecondary)
                    }
                    
                    // Recipient
                    KryptoCard {
                        HStack {
                            VStack(alignment: .leading, spacing: theme.spacingXS) {
                                Text("To")
                                    .font(theme.captionFont)
                                    .foregroundColor(theme.textSecondary)
                                Text("alice.eth")
                                    .font(theme.headlineFont)
                                    .foregroundColor(theme.textPrimary)
                                Text("0x1234...5678")
                                    .font(theme.addressFont)
                                    .foregroundColor(theme.textSecondary)
                            }
                            
                            Spacer()
                            
                            // Verified badge
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(theme.successColor)
                                .font(.title2)
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // Slide to confirm
                VStack(spacing: theme.spacingM) {
                    // Custom slide button visualization
                    GeometryReader { geo in
                        let width = geo.size.width
                        let thumbSize: CGFloat = 52
                        let maxOffset = width - thumbSize - 8
                        
                        ZStack(alignment: .leading) {
                            // Track
                            RoundedRectangle(cornerRadius: 30)
                                .fill(theme.backgroundSecondary)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 30)
                                        .stroke(theme.borderColor.opacity(0.5), lineWidth: 1)
                                )
                            
                            // Progress fill
                            RoundedRectangle(cornerRadius: 30)
                                .fill(
                                    LinearGradient(
                                        colors: [theme.accentColor, theme.accentColor.opacity(0.7)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: thumbSize + 8 + (maxOffset * slideProgress))
                            
                            // Label
                            HStack {
                                Spacer()
                                HStack(spacing: 8) {
                                    Image(systemName: "chevron.right.2")
                                        .font(.system(size: 14, weight: .semibold))
                                    Text("Slide to Send")
                                        .font(theme.font(style: .subheadline))
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(theme.textSecondary.opacity(max(0, 1 - Double(slideProgress) * 2)))
                                Spacer()
                            }
                            .padding(.leading, thumbSize + 16)
                            
                            // Thumb
                            ZStack {
                                Circle()
                                    .fill(theme.accentColor.opacity(0.4))
                                    .frame(width: thumbSize + 10, height: thumbSize + 10)
                                    .blur(radius: 8)
                                
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [theme.accentColor, theme.accentColor.opacity(0.8)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: thumbSize, height: thumbSize)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    )
                                    .shadow(color: theme.shadowColor.opacity(0.3), radius: 4, x: 0, y: 2)
                                
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .offset(x: 4 + maxOffset * slideProgress)
                        }
                    }
                    .frame(height: 60)
                    .padding(.horizontal)
                    
                    Text("Slide right to confirm this transaction")
                        .font(theme.captionFont)
                        .foregroundColor(theme.textSecondary)
                }
                .padding(.bottom, theme.spacing2XL)
            }
        }
    }
}

// MARK: - Screen 10: Hardware Security

struct Screenshot_HardwareSecurity: View {
    @EnvironmentObject var themeManager: ThemeManager
    private let data = FakeDataProvider.shared
    
    var body: some View {
        let theme = themeManager.currentTheme
        let hsk = data.hskData
        
        ZStack {
            Color.clear
                .themedContainer(theme: theme, showPattern: true, applyAnimation: false)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Hardware Security")
                        .font(theme.font(style: .title))
                        .foregroundColor(theme.textPrimary)
                    Spacer()
                }
                .padding()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: theme.spacingL) {
                        // Key verified card
                        KryptoCard {
                            VStack(spacing: theme.spacingL) {
                                ZStack {
                                    // Outer glow rings
                                    ForEach(0..<3, id: \.self) { index in
                                        Circle()
                                            .stroke(theme.successColor.opacity(0.2 - Double(index) * 0.06), lineWidth: 2)
                                            .frame(width: CGFloat(120 + index * 30), height: CGFloat(120 + index * 30))
                                    }
                                    
                                    Circle()
                                        .fill(theme.successColor.opacity(0.15))
                                        .frame(width: 100, height: 100)
                                    
                                    Image(systemName: "key.horizontal.fill")
                                        .font(.system(size: 44))
                                        .foregroundColor(theme.successColor)
                                }
                                
                                VStack(spacing: theme.spacingS) {
                                    HStack(spacing: theme.spacingS) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(theme.successColor)
                                        Text("Key Verified")
                                            .font(theme.font(style: .title2))
                                            .fontWeight(.bold)
                                            .foregroundColor(theme.successColor)
                                    }
                                    
                                    Text(hsk.keyName)
                                        .font(theme.bodyFont)
                                        .foregroundColor(theme.textSecondary)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, theme.spacingL)
                        }
                        
                        // Key details
                        KryptoCard {
                            VStack(alignment: .leading, spacing: theme.spacingM) {
                                HStack {
                                    Image(systemName: "key.fill")
                                        .foregroundColor(theme.accentColor)
                                    Text("Key Details")
                                        .font(theme.headlineFont)
                                        .foregroundColor(theme.textPrimary)
                                }
                                
                                Divider()
                                    .background(theme.borderColor)
                                
                                detailRow("Device", hsk.keyName, theme: theme)
                                detailRow("Serial", hsk.keySerial, theme: theme)
                                detailRow("Bound Wallet", hsk.boundWallet, theme: theme)
                                detailRow("Last Used", data.formatTimeAgo(hsk.lastUsed), theme: theme)
                            }
                        }
                        
                        // Security features
                        KryptoCard {
                            VStack(alignment: .leading, spacing: theme.spacingM) {
                                HStack {
                                    Image(systemName: "shield.checkered")
                                        .foregroundColor(theme.accentColor)
                                    Text("Security Features")
                                        .font(theme.headlineFont)
                                        .foregroundColor(theme.textPrimary)
                                }
                                
                                Divider()
                                    .background(theme.borderColor)
                                
                                securityFeature("FIDO2 / WebAuthn", "Industry standard", true, theme: theme)
                                securityFeature("Secure Enclave", "Hardware protected", hsk.secureEnclaveEnabled, theme: theme)
                                securityFeature("Phishing Resistant", "Origin bound keys", true, theme: theme)
                                securityFeature("Biometric Backup", "Face ID enabled", true, theme: theme)
                            }
                        }
                        
                        // Bound address
                        KryptoCard {
                            VStack(alignment: .leading, spacing: theme.spacingM) {
                                Text("Bound Address")
                                    .font(theme.captionFont)
                                    .foregroundColor(theme.textSecondary)
                                
                                HStack {
                                    Text(hsk.boundAddress)
                                        .font(theme.addressFont)
                                        .foregroundColor(theme.textPrimary)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "lock.fill")
                                        .foregroundColor(theme.successColor)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    private func detailRow(_ label: String, _ value: String, theme: any ThemeProtocolV2) -> some View {
        HStack {
            Text(label)
                .font(theme.bodyFont)
                .foregroundColor(theme.textSecondary)
            Spacer()
            Text(value)
                .font(theme.bodyFont)
                .foregroundColor(theme.textPrimary)
        }
    }
    
    private func securityFeature(_ title: String, _ subtitle: String, _ enabled: Bool, theme: any ThemeProtocolV2) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(theme.bodyFont)
                    .foregroundColor(theme.textPrimary)
                Text(subtitle)
                    .font(theme.captionFont)
                    .foregroundColor(theme.textSecondary)
            }
            
            Spacer()
            
            if enabled {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(theme.successColor)
            } else {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(theme.errorColor)
            }
        }
    }
}

// MARK: - Screen 11: Settings

struct Screenshot_Settings: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        let theme = themeManager.currentTheme
        
        ZStack {
            Color.clear
                .themedContainer(theme: theme, showPattern: true, applyAnimation: false)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Settings")
                        .font(theme.font(style: .title))
                        .foregroundColor(theme.textPrimary)
                    Spacer()
                }
                .padding()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: theme.spacingL) {
                        // Security section
                        settingsSection("Security", icon: "shield.fill", theme: theme) {
                            settingsRow("Security Center", "shield.checkered", badge: nil, theme: theme)
                            settingsRow("Face ID", "faceid", badge: "Enabled", badgeColor: theme.successColor, theme: theme)
                            settingsRow("Auto-Lock", "lock.fill", badge: "1 min", theme: theme)
                            settingsRow("Clipboard Guard", "doc.on.clipboard", badge: "Active", badgeColor: theme.successColor, theme: theme)
                            settingsRow("Address Poisoning Protection", "exclamationmark.shield", badge: "On", badgeColor: theme.successColor, theme: theme)
                        }
                        
                        // Appearance section
                        settingsSection("Appearance", icon: "paintbrush.fill", theme: theme) {
                            settingsRow("Theme", "moon.stars.fill", badge: "Dark", theme: theme)
                            settingsRow("App Icon", "app.fill", badge: "Default", theme: theme)
                            settingsRow("Currency", "dollarsign.circle", badge: "USD", theme: theme)
                        }
                        
                        // Network section
                        settingsSection("Network", icon: "network", theme: theme) {
                            settingsRow("Default Network", "globe", badge: "Ethereum", theme: theme)
                            settingsRow("Custom RPC", "server.rack", badge: nil, theme: theme)
                            settingsRow("MEV Protection", "shield.checkered", badge: "Enabled", badgeColor: theme.successColor, theme: theme)
                        }
                        
                        // Wallet section
                        settingsSection("Wallet", icon: "wallet.pass.fill", theme: theme) {
                            settingsRow("Manage Wallets", "rectangle.stack", badge: "2", theme: theme)
                            settingsRow("Address Book", "person.2", badge: "5 contacts", theme: theme)
                            settingsRow("Backup", "arrow.down.doc", badge: nil, theme: theme)
                        }
                        
                        // About section
                        settingsSection("About", icon: "info.circle.fill", theme: theme) {
                            settingsRow("Version", "number", badge: "1.0.0", theme: theme)
                            settingsRow("Privacy Policy", "hand.raised.fill", badge: nil, theme: theme)
                            settingsRow("Terms of Service", "doc.text", badge: nil, theme: theme)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    private func settingsSection(_ title: String, icon: String, theme: any ThemeProtocolV2, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: theme.spacingS) {
            HStack(spacing: theme.spacingS) {
                Image(systemName: icon)
                    .foregroundColor(theme.accentColor)
                    .font(.subheadline)
                Text(title)
                    .font(theme.headlineFont)
                    .foregroundColor(theme.textPrimary)
            }
            .padding(.horizontal, theme.spacingS)
            
            KryptoCard {
                VStack(spacing: 0) {
                    content()
                }
            }
        }
    }
    
    private func settingsRow(_ title: String, _ icon: String, badge: String?, badgeColor: Color? = nil, theme: any ThemeProtocolV2) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(theme.textSecondary)
                .frame(width: 24)
            
            Text(title)
                .font(theme.bodyFont)
                .foregroundColor(theme.textPrimary)
            
            Spacer()
            
            if let badge = badge {
                Text(badge)
                    .font(theme.captionFont)
                    .foregroundColor(badgeColor ?? theme.textSecondary)
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(theme.textSecondary.opacity(0.5))
        }
        .padding(.vertical, theme.spacingM)
    }
}

// MARK: - Screen 12: Onboarding

struct Screenshot_Onboarding: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        let theme = themeManager.currentTheme
        
        ZStack {
            // Premium dark gradient background
            LinearGradient(
                colors: [
                    theme.backgroundMain,
                    theme.backgroundMain.opacity(0.95),
                    theme.accentColor.opacity(0.1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Subtle pattern overlay
            GeometryReader { geo in
                ForEach(0..<20, id: \.self) { i in
                    Circle()
                        .fill(theme.accentColor.opacity(0.03))
                        .frame(width: CGFloat.random(in: 100...300))
                        .position(
                            x: CGFloat.random(in: 0...geo.size.width),
                            y: CGFloat.random(in: 0...geo.size.height)
                        )
                        .blur(radius: 50)
                }
            }
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Logo and branding
                VStack(spacing: theme.spacing2XL) {
                    // App icon
                    ZStack {
                        // Glow effect
                        Circle()
                            .fill(theme.accentColor.opacity(0.2))
                            .frame(width: 160, height: 160)
                            .blur(radius: 40)
                        
                        // Icon background
                        RoundedRectangle(cornerRadius: 32)
                            .fill(
                                LinearGradient(
                                    colors: [theme.accentColor, theme.accentColor.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                            .shadow(color: theme.accentColor.opacity(0.3), radius: 20, x: 0, y: 10)
                        
                        // Monster icon
                        Image(systemName: "shield.checkered")
                            .font(.system(size: 50, weight: .medium))
                            .foregroundColor(.white)
                    }
                    
                    VStack(spacing: theme.spacingM) {
                        Text("Monster Wallet")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(theme.textPrimary)
                        
                        Text("The Security-First\nCrypto Wallet")
                            .font(theme.font(style: .title3))
                            .foregroundColor(theme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                }
                
                Spacer()
                
                // Feature highlights
                VStack(spacing: theme.spacingL) {
                    featureRow(icon: "shield.checkered", title: "Hardware Key Support", description: "FIDO2 & Secure Enclave", theme: theme)
                    featureRow(icon: "cpu", title: "Transaction Simulation", description: "Preview before you sign", theme: theme)
                    featureRow(icon: "eye.slash", title: "Privacy Mode", description: "Hide sensitive balances", theme: theme)
                }
                .padding(.horizontal, theme.spacingXL)
                
                Spacer()
                
                // CTA buttons
                VStack(spacing: theme.spacingM) {
                    // Primary button
                    Button(action: {}) {
                        HStack {
                            Text("Create New Wallet")
                                .fontWeight(.semibold)
                            Image(systemName: "plus.circle.fill")
                        }
                        .font(theme.headlineFont)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(theme.accentColor)
                        .cornerRadius(theme.cornerRadius)
                    }
                    
                    // Secondary button
                    Button(action: {}) {
                        HStack {
                            Text("Import Existing Wallet")
                            Image(systemName: "square.and.arrow.down")
                        }
                        .font(theme.headlineFont)
                        .foregroundColor(theme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(theme.backgroundSecondary)
                        .cornerRadius(theme.cornerRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: theme.cornerRadius)
                                .stroke(theme.borderColor, lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, theme.spacingXL)
                .padding(.bottom, theme.spacing2XL)
            }
        }
    }
    
    private func featureRow(icon: String, title: String, description: String, theme: any ThemeProtocolV2) -> some View {
        HStack(spacing: theme.spacingM) {
            ZStack {
                Circle()
                    .fill(theme.accentColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .foregroundColor(theme.accentColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(theme.headlineFont)
                    .foregroundColor(theme.textPrimary)
                
                Text(description)
                    .font(theme.captionFont)
                    .foregroundColor(theme.textSecondary)
            }
            
            Spacer()
        }
    }
}
