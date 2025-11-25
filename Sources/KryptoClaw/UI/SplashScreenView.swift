import SwiftUI

public struct SplashScreenView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0.0

    public init() {}

    public var body: some View {
        ZStack {
            Color.clear
                .themedContainer(theme: themeManager.currentTheme, showPattern: true, applyAnimation: true)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image("Logo")
                    .resizable()
                    .frame(width: 120, height: 120)
                    .cornerRadius(themeManager.currentTheme.cornerRadius)
                    .overlay(
                        RoundedRectangle(cornerRadius: themeManager.currentTheme.cornerRadius)
                            .stroke(themeManager.currentTheme.borderColor, lineWidth: 1)
                    )
                    .shadow(color: themeManager.currentTheme.accentColor.opacity(0.3), radius: 20, x: 0, y: 0)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)

                Text("KRYPTOCLAW")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundColor(themeManager.currentTheme.textPrimary)
                    .opacity(logoOpacity)

                Text("Secure • Simple • Sovereign")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeManager.currentTheme.textSecondary)
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
