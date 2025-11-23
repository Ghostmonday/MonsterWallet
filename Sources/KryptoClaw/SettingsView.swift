import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.presentationMode) var presentationMode
    @State private var showResetConfirmation = false
    
    var body: some View {
        ZStack {
            themeManager.currentTheme.backgroundMain.ignoresSafeArea()
            
            ScrollView {
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
                    
                    // Destructive / Account Deletion (Compliance)
                    KryptoCard {
                        Button(action: {
                            showResetConfirmation = true
                        }) {
                            HStack {
                                Text("Reset Wallet (Delete All Data)")
                                    .foregroundColor(.red)
                                Spacer()
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .alert(isPresented: $showResetConfirmation) {
                        Alert(
                            title: Text("Delete Wallet?"),
                            message: Text("This action is irreversible. Ensure you have backed up your Seed Phrase. All data will be wiped."),
                            primaryButton: .destructive(Text("Delete"), action: {
                                 // Wipe Data
                                 wsm.deleteAllData()
                                 // Force exit or restart (simplest for V1)
                                 exit(0)
                            }),
                            secondaryButton: .cancel()
                        )
                    }

                    Spacer()
                    
                    Text("Version 1.0.0 (Build 1)")
                        .font(themeManager.currentTheme.font(style: .caption))
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                        .padding(.bottom)
                }
                .padding(.horizontal)
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
