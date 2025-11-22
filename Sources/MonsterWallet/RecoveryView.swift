import SwiftUI

struct RecoveryView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.presentationMode) var presentationMode
    
    // State
    @State private var seedPhrase: [String] = Array(repeating: "••••", count: 12)
    @State private var isRevealed = false
    @State private var isCopied = false
    
    // Mock Data for V1.0 Template
    let mockSeed = ["witch", "collapse", "practice", "feed", "shame", "open", "despair", "creek", "road", "again", "ice", "least"]
    
    var body: some View {
        ZStack {
            themeManager.currentTheme.backgroundMain.ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header
                HStack {
                    Text("Backup Wallet")
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
                
                // Warning Banner
                MonsterCard {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: themeManager.currentTheme.iconShield)
                            .foregroundColor(themeManager.currentTheme.warningColor)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Secret Recovery Phrase")
                                .font(themeManager.currentTheme.font(style: .headline, weight: .bold))
                                .foregroundColor(themeManager.currentTheme.textPrimary)
                            Text("This is the ONLY way to recover your wallet. Write it down and keep it safe.")
                                .font(themeManager.currentTheme.font(style: .caption, weight: .regular))
                                .foregroundColor(themeManager.currentTheme.textSecondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal)
                
                // Seed Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(0..<12, id: \.self) { index in
                        HStack {
                            Text("\(index + 1).")
                                .font(themeManager.currentTheme.font(style: .caption, weight: .medium))
                                .foregroundColor(themeManager.currentTheme.textSecondary)
                            
                            Text(isRevealed ? mockSeed[index] : "••••")
                                .font(themeManager.currentTheme.font(style: .body, weight: .bold))
                                .foregroundColor(themeManager.currentTheme.textPrimary)
                                .blur(radius: isRevealed ? 0 : 4)
                        }
                        .padding(8)
                        .frame(maxWidth: .infinity)
                        .background(themeManager.currentTheme.backgroundSecondary)
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Actions
                VStack(spacing: 16) {
                    MonsterButton(title: isRevealed ? "Hide Phrase" : "Reveal Phrase", icon: isRevealed ? "eye.slash.fill" : "eye.fill", action: {
                        withAnimation {
                            isRevealed.toggle()
                        }
                    }, isPrimary: false)
                    
                    if isRevealed {
                        MonsterButton(title: "I Have Written It Down", icon: "checkmark.circle.fill", action: {
                            presentationMode.wrappedValue.dismiss()
                        }, isPrimary: true)
                    }
                }
                .padding()
            }
        }
    }
}
