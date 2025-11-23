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
                        Text("Appearance")
                            .font(themeManager.currentTheme.font(style: .headline))
                            .foregroundColor(themeManager.currentTheme.textPrimary)
                        
                        VStack(spacing: 0) {
                            ThemeRow(name: "Default (Apple)", isSelected: themeManager.currentTheme.id == "apple_default") {
                                themeManager.setTheme(AppleDefaultTheme())
                            }
                            Divider().background(themeManager.currentTheme.borderColor)
                            ThemeRow(name: "Obsidian Stealth", isSelected: themeManager.currentTheme.id == "obsidian_stealth") {
                                themeManager.setTheme(ObsidianStealthTheme())
                            }
                            Divider().background(themeManager.currentTheme.borderColor)
                            ThemeRow(name: "Cyberpunk Neon", isSelected: themeManager.currentTheme.id == "cyberpunk_neon") {
                                themeManager.setTheme(CyberpunkNeonTheme())
                            }
                            Divider().background(themeManager.currentTheme.borderColor)
                            ThemeRow(name: "Bunker Gray", isSelected: themeManager.currentTheme.id == "bunker_gray") {
                                themeManager.setTheme(BunkerGrayTheme())
                            }
                            Divider().background(themeManager.currentTheme.borderColor)
                            ThemeRow(name: "Crimson Tide", isSelected: themeManager.currentTheme.id == "crimson_tide") {
                                themeManager.setTheme(CrimsonTideTheme())
                            }
                            Divider().background(themeManager.currentTheme.borderColor)
                            ThemeRow(name: "Quantum Frost", isSelected: themeManager.currentTheme.id == "quantum_frost") {
                                themeManager.setTheme(QuantumFrostTheme())
                            }
                            Divider().background(themeManager.currentTheme.borderColor)
                            ThemeRow(name: "Golden Era", isSelected: themeManager.currentTheme.id == "golden_era") {
                                themeManager.setTheme(GoldenEraTheme())
                            }
                            Divider().background(themeManager.currentTheme.borderColor)
                            ThemeRow(name: "Matrix Code", isSelected: themeManager.currentTheme.id == "matrix_code") {
                                themeManager.setTheme(MatrixCodeTheme())
                            }
                            Divider().background(themeManager.currentTheme.borderColor)
                            ThemeRow(name: "Neon Tokyo", isSelected: themeManager.currentTheme.id == "neon_tokyo") {
                                themeManager.setTheme(NeonTokyoTheme())
                            }
                            Divider().background(themeManager.currentTheme.borderColor)
                            ThemeRow(name: "Stealth Bomber", isSelected: themeManager.currentTheme.id == "stealth_bomber") {
                                themeManager.setTheme(StealthBomberTheme())
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
