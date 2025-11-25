import SwiftUI

struct WalletManagementView: View {
    @EnvironmentObject var wsm: WalletStateManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.presentationMode) var presentationMode

    @State private var showingCreate = false

    var body: some View {
        let theme = themeManager.currentTheme
        
        ZStack {
            Color.clear
                .themedContainer(theme: theme, showPattern: true, applyAnimation: true)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                KryptoHeader(
                    title: "Wallets",
                    onBack: { presentationMode.wrappedValue.dismiss() },
                    actionIcon: "plus",
                    onAction: { showingCreate = true }
                )

                List {
                    ForEach(wsm.wallets) { wallet in
                        WalletRow(wallet: wallet, isSelected: wsm.currentAddress == wallet.id)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .onTapGesture {
                                Task {
                                    await wsm.switchWallet(id: wallet.id)
                                }
                            }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let wallet = wsm.wallets[index]
                            Task {
                                await wsm.deleteWallet(id: wallet.id)
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .sheet(isPresented: $showingCreate) {
            WalletCreationView(isPresented: $showingCreate)
        }
        .onAppear {
            KryptoLogger.shared.log(level: .info, category: .lifecycle, message: "ViewDidAppear", metadata: ["view": "WalletManagement"])
        }
    }
}

struct WalletRow: View {
    let wallet: WalletInfo
    let isSelected: Bool
    @EnvironmentObject var themeManager: ThemeManager

    // Parse colorTheme string to SwiftUI Color
    private var walletColor: Color {
        parseColorTheme(wallet.colorTheme)
    }

    var body: some View {
        let theme = themeManager.currentTheme
        
        KryptoCard {
            HStack {
                RoundedRectangle(cornerRadius: theme.cornerRadius)
                    .fill(walletColor)
                    .frame(width: theme.avatarSizeMedium, height: theme.avatarSizeMedium)
                    .overlay(
                        Text(wallet.name.prefix(1).uppercased())
                            .foregroundColor(theme.qrBackgroundColor)
                            .font(theme.headlineFont)
                    )

                VStack(alignment: .leading, spacing: theme.spacingXS) {
                    Text(wallet.name)
                        .font(theme.headlineFont)
                        .foregroundColor(theme.textPrimary)

                    if isSelected {
                        Text("Active")
                            .font(theme.captionFont)
                            .foregroundColor(theme.successColor)
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(theme.successColor)
                }
            }
        }
        .padding(.vertical, theme.spacingXS)
    }

    // MARK: - Color Theme Parsing Helper

    /// Parses a colorTheme string (hex color or named color) into a SwiftUI Color
    /// Supports formats: "#FF0000", "FF0000", "red", "blue", etc.
    private func parseColorTheme(_ colorTheme: String) -> Color {
        let trimmed = colorTheme.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        // Try hex color parsing (with or without #)
        if trimmed.hasPrefix("#") {
            let hex = String(trimmed.dropFirst())
            if let color = parseHexColor(hex) {
                return color
            }
        } else if trimmed.count == 6 || trimmed.count == 8 {
            // Assume hex without #
            if let color = parseHexColor(trimmed) {
                return color
            }
        }

        // Try named colors
        switch trimmed {
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "purple": return .purple
        case "orange": return .orange
        case "pink": return .pink
        case "yellow": return .yellow
        case "cyan": return .cyan
        case "mint": return .mint
        case "teal": return .teal
        case "indigo": return .indigo
        case "brown": return .brown
        case "gray", "grey": return .gray
        default:
            // Fallback to accent color from theme
            return themeManager.currentTheme.accentColor
        }
    }

    /// Parses a hex color string (RRGGBB or RRGGBBAA) into a SwiftUI Color
    private func parseHexColor(_ hex: String) -> Color? {
        let hex = hex.uppercased()
        var rgbValue: UInt64 = 0

        guard Scanner(string: hex).scanHexInt64(&rgbValue) else {
            return nil
        }

        if hex.count == 6 {
            // RRGGBB format
            let red = Double((rgbValue & 0xFF0000) >> 16) / 255.0
            let green = Double((rgbValue & 0x00FF00) >> 8) / 255.0
            let blue = Double(rgbValue & 0x0000FF) / 255.0
            return Color(red: red, green: green, blue: blue)
        } else if hex.count == 8 {
            // RRGGBBAA format
            let red = Double((rgbValue & 0xFF00_0000) >> 24) / 255.0
            let green = Double((rgbValue & 0x00FF_0000) >> 16) / 255.0
            let blue = Double((rgbValue & 0x0000_FF00) >> 8) / 255.0
            let alpha = Double(rgbValue & 0x0000_00FF) / 255.0
            return Color(red: red, green: green, blue: blue, opacity: alpha)
        }

        return nil
    }
}

struct WalletCreationView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var wsm: WalletStateManager
    @EnvironmentObject var themeManager: ThemeManager

    @State private var name = ""
    @State private var step = 0
    
    // In a real app, this would be generated by HDWalletService
    @State private var seedPhrase = "apple banana cherry date elder fig grape honeydew igloo jackfruit kiwi lemon"
    @State private var verificationInput = ""
    @State private var verificationError: String?
    @State private var isVerified = false

    var body: some View {
        let theme = themeManager.currentTheme
        
        NavigationView {
            ZStack {
                Color.clear
                    .themedContainer(theme: theme, showPattern: true, applyAnimation: true)
                    .ignoresSafeArea()

                VStack(spacing: theme.spacingXL) {
                    if step == 0 {
                        // Step 1: Name
                        KryptoInput(title: "Wallet Name", placeholder: "My Vault", text: $name)
                        Spacer()
                        KryptoButton(title: "Next", icon: "arrow.right", action: { step = 1 }, isPrimary: true)
                            .disabled(name.isEmpty)
                    } else if step == 1 {
                        // Step 2: Seed (Simulation)
                        Text("Secret Recovery Phrase")
                            .font(theme.headlineFont)
                            .foregroundColor(theme.textPrimary)

                        Text(seedPhrase)
                            .padding()
                            .background(theme.backgroundSecondary)
                            .cornerRadius(theme.cornerRadius)
                            .foregroundColor(theme.textPrimary)
                            .multilineTextAlignment(.center)

                        Text("Write this down. We cannot recover it.")
                            .font(theme.captionFont)
                            .foregroundColor(theme.errorColor)

                        Spacer()

                        KryptoButton(title: "I have saved it", icon: "checkmark", action: { step = 2 }, isPrimary: true)
                    } else {
                        // Step 3: Verify
                        if isVerified {
                            VStack(spacing: theme.spacingL) {
                                Image(systemName: "checkmark.shield.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(theme.successColor)
                                
                                Text("Verification Complete")
                                    .font(theme.font(style: .title3))
                                    .foregroundColor(theme.successColor)
                                
                                Text("Your wallet is ready to use.")
                                    .font(theme.bodyFont)
                                    .foregroundColor(theme.textSecondary)
                            }
                            
                            Spacer()

                            KryptoButton(title: "Create Wallet", icon: "lock.fill", action: createWallet, isPrimary: true)
                        } else {
                            VStack(alignment: .leading, spacing: theme.spacingM) {
                                Text("Verify Recovery Phrase")
                                    .font(theme.headlineFont)
                                    .foregroundColor(theme.textPrimary)
                                
                                Text("Enter your recovery phrase below to verify you saved it.")
                                    .font(theme.captionFont)
                                    .foregroundColor(theme.textSecondary)
                                
                                TextEditor(text: $verificationInput)
                                    .frame(height: 100)
                                    .padding(theme.spacingS)
                                    .background(theme.backgroundSecondary)
                                    .cornerRadius(theme.cornerRadius)
                                    .foregroundColor(theme.textPrimary)
                                    // Prevent capitalization and autocorrect for seed phrases usually
                                    .disableAutocorrection(true)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: theme.cornerRadius)
                                            .stroke(verificationError != nil ? theme.errorColor : Color.clear, lineWidth: 1)
                                    )
                                    .accessibilityLabel("Recovery Phrase Verification Input")
                                    .accessibilityHint("Type your secret recovery phrase exactly as shown in the previous step")
                                
                                if let error = verificationError {
                                    Text(error)
                                        .font(theme.captionFont)
                                        .foregroundColor(theme.errorColor)
                                        .accessibilityLabel("Error: \(error)")
                                }
                            }
                            
                            Spacer()
                            
                            KryptoButton(title: "Verify", icon: "checkmark.circle", action: verifySeed, isPrimary: true)
                                .disabled(verificationInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                }
                .padding()
                .navigationTitle(stepTitle)
                #if os(iOS)
                    .navigationBarTitleDisplayMode(.inline)
                #endif
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        if step > 0 {
                            Button("Back") {
                                step -= 1
                                // Reset verification state if going back from step 2
                                if step == 1 {
                                    verificationError = nil
                                }
                            }
                            .foregroundColor(theme.accentColor)
                        } else {
                            Button("Cancel") {
                                isPresented = false
                            }
                            .foregroundColor(theme.textSecondary)
                        }
                    }
                }
            }
        }
    }

    var stepTitle: String {
        switch step {
        case 0: "Name Wallet"
        case 1: "Backup Seed"
        case 2: "Verify"
        default: ""
        }
    }

    func createWallet() {
        KryptoLogger.shared.log(level: .info, category: .stateTransition, message: "CreateWallet tapped", metadata: ["view": "WalletManagement"])
        Task {
            _ = await wsm.createWallet(name: name)
            isPresented = false
        }
    }

    func verifySeed() {
        let normalizedInput = verificationInput.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let normalizedSeed = seedPhrase.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        if normalizedInput == normalizedSeed {
            isVerified = true
            verificationError = nil
            KryptoLogger.shared.log(level: .info, category: .security, message: "Seed verification successful")
        } else {
            verificationError = "The phrase you entered does not match. Please check your spelling and order."
            KryptoLogger.shared.log(level: .warning, category: .security, message: "Seed verification failed")
        }
    }
}
