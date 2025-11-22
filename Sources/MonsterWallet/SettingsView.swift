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
                        .font(themeManager.currentTheme.font(style: .title2, weight: .bold))
                        .foregroundColor(themeManager.currentTheme.textPrimary)
                    Spacer()
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(themeManager.currentTheme.textSecondary)
                            .font(.title2)
                    }
                }
                .padding()
                
                // Theme Selector (Monetization Hook)
                MonsterCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Themes")
                            .font(themeManager.currentTheme.font(style: .headline, weight: .bold))
                            .foregroundColor(themeManager.currentTheme.textPrimary)
                        
                        HStack {
                            Text("Current: \(themeManager.currentTheme.name)")
                                .foregroundColor(themeManager.currentTheme.textSecondary)
                            Spacer()
                            if themeManager.currentTheme.isPremium {
                                Image(systemName: "star.fill")
                                    .foregroundColor(themeManager.currentTheme.warningColor)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal)
                
                // Compliance Links
                MonsterCard {
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
                    .font(themeManager.currentTheme.font(style: .caption, weight: .regular))
                    .foregroundColor(themeManager.currentTheme.textSecondary)
                    .padding(.bottom)
            }
        }
    }
}
