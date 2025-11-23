import SwiftUI

public struct SplashScreenView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0.0
    
    public init() {}
    
    public var body: some View {
        ZStack {
            themeManager.currentTheme.backgroundMain
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Logo/Icon
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 100))
                    .foregroundColor(themeManager.currentTheme.accentColor)
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
