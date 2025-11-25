import SwiftUI

struct RecoveryView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.presentationMode) var presentationMode

    @State private var seedPhrase: [String] = Array(repeating: "••••", count: 12)
    @State private var isRevealed = false
    @State private var isCopied = false

    let mockSeed = ["witch", "collapse", "practice", "feed", "shame", "open", "despair", "creek", "road", "again", "ice", "least"]

    var body: some View {
        let theme = themeManager.currentTheme
        
        ZStack {
            Color.clear
                .themedContainer(theme: theme, showPattern: true, applyAnimation: true)
                .ignoresSafeArea()

            VStack(spacing: theme.spacingXL) {
                HStack {
                    Text("Backup Wallet")
                        .font(theme.font(style: .title2).weight(.bold))
                        .foregroundColor(theme.textPrimary)
                    Spacer()
                    KryptoCloseButton {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                .padding()

                KryptoCard {
                    HStack(alignment: .top, spacing: theme.spacingM) {
                        Image(systemName: theme.iconShield)
                            .foregroundColor(theme.warningColor)
                            .font(.title2)

                        VStack(alignment: .leading, spacing: theme.spacingXS) {
                            Text("Secret Recovery Phrase")
                                .font(theme.font(style: .headline).weight(.bold))
                                .foregroundColor(theme.textPrimary)
                            Text("This is the ONLY way to recover your wallet. Write it down and keep it safe.")
                                .font(theme.font(style: .caption).weight(.regular))
                                .foregroundColor(theme.textSecondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: theme.spacingM) {
                    ForEach(0 ..< 12, id: \.self) { index in
                        HStack {
                            Text("\(index + 1).")
                                .font(theme.font(style: .caption).weight(.medium))
                                .foregroundColor(theme.textSecondary)

                            Text(isRevealed ? mockSeed[index] : "••••")
                                .font(theme.font(style: .body).weight(.bold))
                                .foregroundColor(theme.textPrimary)
                                .blur(radius: isRevealed ? 0 : 4)
                        }
                        .padding(theme.spacingS)
                        .frame(maxWidth: .infinity)
                        .background(theme.backgroundSecondary)
                        .cornerRadius(theme.cornerRadius)
                    }
                }
                .padding(.horizontal)

                Spacer()

                VStack(spacing: theme.spacingL) {
                    KryptoButton(title: isRevealed ? "Hide Phrase" : "Reveal Phrase", icon: isRevealed ? "eye.slash.fill" : "eye.fill", action: {
                        withAnimation {
                            isRevealed.toggle()
                        }
                    }, isPrimary: false)

                    if isRevealed {
                        KryptoButton(title: "I Have Written It Down", icon: "checkmark.circle.fill", action: {
                            presentationMode.wrappedValue.dismiss()
                        }, isPrimary: true)
                    }
                }
                .padding()
            }
        }
    }
}
