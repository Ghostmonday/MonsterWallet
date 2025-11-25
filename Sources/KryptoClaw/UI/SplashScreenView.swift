import SwiftUI

public struct SplashScreenView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0.0

    public init() {}

    public var body: some View {
        let theme = themeManager.currentTheme
        
        ZStack {
            Color.clear
                .themedContainer(theme: theme, showPattern: true, applyAnimation: true)
                .ignoresSafeArea()

            VStack(spacing: theme.spacingXL) {
                Image("Logo")
                    .resizable()
                    .frame(width: 120, height: 120)
                    .cornerRadius(theme.cornerRadius)
                    .overlay(
                        RoundedRectangle(cornerRadius: theme.cornerRadius)
                            .stroke(theme.borderColor, lineWidth: 1)
                    )
                    .shadow(color: theme.accentColor.opacity(0.3), radius: 20, x: 0, y: 0)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)

                Text("KRYPTOCLAW")
                    .font(theme.titleFont)
                    .fontWeight(.black)
                    .foregroundColor(theme.textPrimary)
                    .opacity(logoOpacity)

                Text("Secure • Simple • Sovereign")
                    .font(theme.captionFont)
                    .fontWeight(.medium)
                    .foregroundColor(theme.textSecondary)
                    .opacity(logoOpacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                logoScale = 1.0
            }
            withAnimation(.easeIn(duration: 0.4)) {
                logoOpacity = 1.0
            }
        }
    }
}
