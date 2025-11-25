import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var wsm: WalletStateManager
    @Environment(\.presentationMode) var presentationMode
    @State private var showResetConfirmation = false
    @State private var showHSKBinding = false

    var body: some View {
        let theme = themeManager.currentTheme
        
        ZStack {
            Color.clear
                .themedContainer(theme: theme, showPattern: true, applyAnimation: true)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: theme.spacingXL) {
                    HStack {
                        Text("Settings")
                            .font(theme.font(style: .title2))
                            .foregroundColor(theme.textPrimary)
                        Spacer()
                        KryptoCloseButton {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                    .padding()

                    KryptoCard {
                        VStack(alignment: .leading, spacing: theme.spacingL) {
                            NavigationLink(destination: WalletManagementView()) {
                                HStack {
                                    Text("Manage Wallets")
                                        .foregroundColor(theme.textPrimary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(theme.textSecondary)
                                }
                            }
                            KryptoDivider()

                            NavigationLink(destination: AddressBookView()) {
                                HStack {
                                    Text("Address Book")
                                        .foregroundColor(theme.textPrimary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(theme.textSecondary)
                                }
                            }
                            
                            // HSK Binding Option
                            if #available(iOS 15.0, macOS 12.0, *) {
                                KryptoDivider()
                                
                                Button(action: { showHSKBinding = true }) {
                                    HStack {
                                        Image(systemName: "key.horizontal.fill")
                                            .foregroundColor(theme.accentColor)
                                        Text("Bind Hardware Key")
                                            .foregroundColor(theme.textPrimary)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(theme.textSecondary)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)

                    KryptoCard {
                        VStack(alignment: .leading, spacing: theme.spacingL) {
                            Text("Appearance")
                                .font(theme.font(style: .headline))
                                .foregroundColor(theme.textPrimary)

                            VStack(spacing: 0) {
                                ForEach(ThemeType.allCases) { themeType in
                                    ThemeRow(name: themeType.name, isSelected: themeManager.currentTheme.id == themeType.id) {
                                        themeManager.setTheme(type: themeType)
                                    }
                                    if themeType != ThemeType.allCases.last {
                                        KryptoDivider()
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal)

                    KryptoCard {
                        VStack(alignment: .leading, spacing: theme.spacingL) {
                            Link(destination: AppConfig.privacyPolicyURL) {
                                HStack {
                                    Text("Privacy Policy")
                                        .foregroundColor(theme.textPrimary)
                                    Spacer()
                                    Image(systemName: "arrow.up.right.square")
                                        .foregroundColor(theme.textSecondary)
                                }
                            }

                            KryptoDivider()

                            Link(destination: AppConfig.supportURL) {
                                HStack {
                                    Text("Support")
                                        .foregroundColor(theme.textPrimary)
                                    Spacer()
                                    Image(systemName: "questionmark.circle")
                                        .foregroundColor(theme.textSecondary)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal)

                    KryptoCard {
                        Button(action: {
                            showResetConfirmation = true
                        }) {
                            HStack {
                                Text("Reset Wallet (Delete All Data)")
                                    .foregroundColor(theme.destructiveColor)
                                Spacer()
                                Image(systemName: "trash")
                                    .foregroundColor(theme.destructiveColor)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .alert(isPresented: $showResetConfirmation) {
                        Alert(
                            title: Text("Delete Wallet?"),
                            message: Text("This action is irreversible. Ensure you have backed up your Seed Phrase. All data will be wiped."),
                            primaryButton: .destructive(Text("Delete"), action: {
                                wsm.deleteAllData()
                                exit(0)
                            }),
                            secondaryButton: .cancel()
                        )
                    }
                    .sheet(isPresented: $showHSKBinding) {
                        if #available(iOS 15.0, macOS 12.0, *) {
                            if let walletId = wsm.currentAddress {
                                HSKFlowView(mode: .bindToExistingWallet(walletId: walletId)) { _ in
                                    showHSKBinding = false
                                }
                                .environmentObject(themeManager)
                            }
                        }
                    }

                    Spacer()

                    Text("Version 1.0.0 (Build 1)")
                        .font(theme.font(style: .caption))
                        .foregroundColor(theme.textSecondary)
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
        let theme = themeManager.currentTheme
        
        Button(action: action) {
            HStack {
                Text(name)
                    .foregroundColor(theme.textPrimary)
                    .font(theme.font(style: .body))
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(theme.accentColor)
                }
            }
            .padding(.vertical, theme.spacingM)
            .contentShape(Rectangle())
        }
    }
}
