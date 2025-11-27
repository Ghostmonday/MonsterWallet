// KRYPTOCLAW SETTINGS SCREEN
// Control panel. Security first.
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

import SwiftUI

public struct SettingsScreen: View {
    @EnvironmentObject var walletState: WalletStateManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingWalletManagement = false
    @State private var showingAddressBook = false
    @State private var showingSecuritySettings = false
    @State private var showingHSKManagement = false
    @State private var showingAbout = false
    @State private var showingDeleteConfirm = false
    
    @AppStorage("biometricsEnabled") private var biometricsEnabled = true
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                KC.Color.bg.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: KC.Space.xxl) {
                        // Wallet section
                        walletSection
                        
                        // Security section
                        securitySection
                        
                        // Preferences section
                        preferencesSection
                        
                        // About section
                        aboutSection
                        
                        // Danger zone
                        dangerSection
                    }
                    .padding(.top, KC.Space.lg)
                    .padding(.bottom, KC.Space.xxxl)
                }
            }
            .navigationTitle("Settings")
            .kcNavigationLarge()
            .toolbar {
                ToolbarItem(placement: .kcTrailing) {
                    KCCloseButton { dismiss() }
                }
            }
            .sheet(isPresented: $showingWalletManagement) {
                WalletManagementScreen()
                    .environmentObject(walletState)
            }
            .sheet(isPresented: $showingAddressBook) {
                AddressBookScreen()
                    .environmentObject(walletState)
            }
            .sheet(isPresented: $showingHSKManagement) {
                HSKManagementScreen()
                    .environmentObject(walletState)
            }
            .sheet(isPresented: $showingAbout) {
                AboutScreen()
            }
            .alert("Delete All Data", isPresented: $showingDeleteConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deleteAllData()
                }
            } message: {
                Text("This will permanently delete all wallets and data. This action cannot be undone.")
            }
        }
    }
    
    // MARK: - Wallet Section
    
    private var walletSection: some View {
        SettingsSection(title: "Wallet") {
            SettingsRow(icon: "wallet.pass", title: "Manage Wallets") {
                showingWalletManagement = true
            }
            
            SettingsRow(icon: "person.crop.circle", title: "Address Book") {
                showingAddressBook = true
            }
        }
    }
    
    // MARK: - Security Section
    
    private var securitySection: some View {
        SettingsSection(title: "Security") {
            SettingsToggleRow(
                icon: "faceid",
                title: "Face ID / Touch ID",
                isOn: $biometricsEnabled
            )
            
            SettingsRow(icon: "key.horizontal", title: "Hardware Security Keys") {
                showingHSKManagement = true
            }
            
            SettingsRow(icon: "lock.shield", title: "Security Settings") {
                showingSecuritySettings = true
            }
        }
    }
    
    // MARK: - Preferences Section
    
    private var preferencesSection: some View {
        SettingsSection(title: "Preferences") {
            SettingsToggleRow(
                icon: "bell",
                title: "Notifications",
                isOn: $notificationsEnabled
            )
            
            SettingsValueRow(icon: "dollarsign.circle", title: "Currency", value: "USD")
            
            SettingsValueRow(icon: "globe", title: "Language", value: "English")
        }
    }
    
    // MARK: - About Section
    
    private var aboutSection: some View {
        SettingsSection(title: "About") {
            SettingsRow(icon: "info.circle", title: "About KryptoClaw") {
                showingAbout = true
            }
            
            SettingsRow(icon: "doc.text", title: "Terms of Service") {
                // Open terms
            }
            
            SettingsRow(icon: "hand.raised", title: "Privacy Policy") {
                // Open privacy
            }
            
            SettingsValueRow(icon: "number", title: "Version", value: "1.0.0")
        }
    }
    
    // MARK: - Danger Section
    
    private var dangerSection: some View {
        SettingsSection(title: "Danger Zone") {
            Button(action: { showingDeleteConfirm = true }) {
                HStack(spacing: KC.Space.lg) {
                    ZStack {
                        Circle()
                            .fill(KC.Color.negative.opacity(0.15))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "trash")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(KC.Color.negative)
                    }
                    
                    Text("Delete All Data")
                        .font(KC.Font.body)
                        .foregroundColor(KC.Color.negative)
                    
                    Spacer()
                }
                .padding(KC.Space.lg)
                .background(KC.Color.card)
                .clipShape(RoundedRectangle(cornerRadius: KC.Radius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: KC.Radius.md)
                        .stroke(KC.Color.negative.opacity(0.3), lineWidth: 1)
                )
            }
        }
    }
    
    private func deleteAllData() {
        HapticEngine.shared.play(.error)
        walletState.deleteAllData()
        dismiss()
    }
}

// MARK: - Settings Components

struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: KC.Space.md) {
            Text(title.uppercased())
                .font(KC.Font.label)
                .tracking(1.5)
                .foregroundColor(KC.Color.textMuted)
                .padding(.horizontal, KC.Space.xl)
            
            VStack(spacing: KC.Space.sm) {
                content
            }
            .padding(.horizontal, KC.Space.xl)
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticEngine.shared.play(.selection)
            action()
        }) {
            HStack(spacing: KC.Space.lg) {
                ZStack {
                    Circle()
                        .fill(KC.Color.cardElevated)
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(KC.Color.textSecondary)
                }
                
                Text(title)
                    .font(KC.Font.body)
                    .foregroundColor(KC.Color.textPrimary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(KC.Color.textMuted)
            }
            .padding(KC.Space.lg)
            .background(KC.Color.card)
            .clipShape(RoundedRectangle(cornerRadius: KC.Radius.md))
            .overlay(
                RoundedRectangle(cornerRadius: KC.Radius.md)
                    .stroke(KC.Color.border, lineWidth: 1)
            )
        }
    }
}

struct SettingsToggleRow: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: KC.Space.lg) {
            ZStack {
                Circle()
                    .fill(KC.Color.cardElevated)
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(KC.Color.textSecondary)
            }
            
            Text(title)
                .font(KC.Font.body)
                .foregroundColor(KC.Color.textPrimary)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(KC.Color.gold)
        }
        .padding(KC.Space.lg)
        .background(KC.Color.card)
        .clipShape(RoundedRectangle(cornerRadius: KC.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: KC.Radius.md)
                .stroke(KC.Color.border, lineWidth: 1)
        )
    }
}

struct SettingsValueRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: KC.Space.lg) {
            ZStack {
                Circle()
                    .fill(KC.Color.cardElevated)
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(KC.Color.textSecondary)
            }
            
            Text(title)
                .font(KC.Font.body)
                .foregroundColor(KC.Color.textPrimary)
            
            Spacer()
            
            Text(value)
                .font(KC.Font.body)
                .foregroundColor(KC.Color.textTertiary)
        }
        .padding(KC.Space.lg)
        .background(KC.Color.card)
        .clipShape(RoundedRectangle(cornerRadius: KC.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: KC.Radius.md)
                .stroke(KC.Color.border, lineWidth: 1)
        )
    }
}

// MARK: - About Screen

struct AboutScreen: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                KC.Color.bg.ignoresSafeArea()
                
                VStack(spacing: KC.Space.xxl) {
                    Spacer()
                    
                    // Logo
                    VStack(spacing: KC.Space.xl) {
                        ZStack {
                            Circle()
                                .stroke(KC.Color.gold.opacity(0.3), lineWidth: 2)
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: "shield.checkered")
                                .font(.system(size: 44, weight: .medium))
                                .foregroundColor(KC.Color.gold)
                        }
                        
                        VStack(spacing: KC.Space.sm) {
                            Text("KRYPTOCLAW")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .tracking(3)
                                .foregroundColor(KC.Color.textPrimary)
                            
                            Text("Version 1.0.0")
                                .font(KC.Font.body)
                                .foregroundColor(KC.Color.textTertiary)
                        }
                    }
                    
                    // Description
                    Text("A precision instrument for digital asset management. Built with security at its core.")
                        .font(KC.Font.body)
                        .foregroundColor(KC.Color.textSecondary)
                        .multilineTextAlignment(.center)
                        .kcPadding()
                    
                    Spacer()
                    
                    // Credits
                    VStack(spacing: KC.Space.sm) {
                        Text("SECURE BY DESIGN")
                            .font(KC.Font.label)
                            .tracking(2)
                            .foregroundColor(KC.Color.textMuted)
                        
                        Text("© 2024 KryptoClaw")
                            .font(KC.Font.caption)
                            .foregroundColor(KC.Color.textMuted)
                    }
                    .padding(.bottom, KC.Space.xxxl)
                }
            }
            .kcNavigationInline()
            .toolbar {
                ToolbarItem(placement: .kcTrailing) {
                    KCCloseButton { dismiss() }
                }
            }
        }
    }
}

#Preview {
    SettingsScreen()
}

