import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            themeManager.currentTheme.backgroundMain.ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header
                HStack {
                    Text("Settings")
                        .font(themeManager.currentTheme.font(style: .title2))
                        .foregroundColor(themeManager.currentTheme.textPrimary)
                    Spacer()
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(themeManager.currentTheme.textSecondary)
                            .font(.title2)
                    }
                }
                .padding()
                
                // Theme Selector
                KryptoCard {
                    VStack(alignment: .leading, spacing: 16) {
                        NavigationLink(destination: WalletManagementView()) {
                            HStack {
                                Text("Manage Wallets")
                                    .foregroundColor(themeManager.currentTheme.textPrimary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(themeManager.currentTheme.textSecondary)
                            }
                        }
                        Divider().background(themeManager.currentTheme.borderColor)
                        
                        NavigationLink(destination: AddressBookView()) {
                            HStack {
                                Text("Address Book")
                                    .foregroundColor(themeManager.currentTheme.textPrimary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(themeManager.currentTheme.textSecondary)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                // Theme Selector
                KryptoCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Appearance")
                            .font(themeManager.currentTheme.font(style: .headline))
                            .foregroundColor(themeManager.currentTheme.textPrimary)
                        
                        VStack(spacing: 0) {
                            ForEach(ThemeType.allCases) { themeType in
                                ThemeRow(name: themeType.name, isSelected: themeManager.currentTheme.id == themeType.id) {
                                    themeManager.setTheme(type: themeType)
                                }
                                if themeType != ThemeType.allCases.last {
                                    Divider().background(themeManager.currentTheme.borderColor)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal)
                
                // Compliance Links
                KryptoCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Link(destination: AppConfig.privacyPolicyURL) {
                            HStack {
                                Text("Privacy Policy")
                                    .foregroundColor(themeManager.currentTheme.textPrimary)
                                Spacer()
                                Image(systemName: "arrow.up.right.square")
                                    .foregroundColor(themeManager.currentTheme.textSecondary)
                            }
                        }
                        
                        Divider().background(themeManager.currentTheme.textSecondary)
                        
                        Link(destination: AppConfig.supportURL) {
                            HStack {
                                Text("Support")
                                    .foregroundColor(themeManager.currentTheme.textPrimary)
                                Spacer()
                                Image(systemName: "questionmark.circle")
                                    .foregroundColor(themeManager.currentTheme.textSecondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal)
                
                // <<<<<<!!!!!JULES!!!!!!>>>>>>>>
                // [COMPLIANCE CRITICAL] [BLOCKER]
                // App Store Guideline 5.1.1(v):
                // "Apps that support account creation must also offer account deletion within the app."
                // Since we have "Create Wallet", we technically have accounts (even if local).
                // Best practice for non-custodial: "Reset Wallet" or "Wipe Data" button.
                // ACTION: Add a "Destructive" section with a "Reset Wallet" button that wipes the KeyStore and UserDefaults.

                Spacer()
                
                Text("Version 1.0.0 (Build 1)")
                    .font(themeManager.currentTheme.font(style: .caption))
                    .foregroundColor(themeManager.currentTheme.textSecondary)
                    .padding(.bottom)
            }
        }
    }
}

struct ThemeRow: View {
    let name: String
    let isSelected: Bool
    let action: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(name)
                    .foregroundColor(themeManager.currentTheme.textPrimary)
                    .font(themeManager.currentTheme.font(style: .body))
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(themeManager.currentTheme.accentColor)
                }
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
    }
}
