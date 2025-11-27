// KRYPTOCLAW SPLASH SCREEN
// First impression. Make it count.
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

import SwiftUI

public struct SplashScreen: View {
    @State private var logoOpacity: Double = 0
    @State private var logoScale: CGFloat = 0.8
    @State private var textOpacity: Double = 0
    @State private var underlineWidth: CGFloat = 0
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // The void
            KC.Color.bg.ignoresSafeArea()
            
            VStack(spacing: KC.Space.xxl) {
                Spacer()
                
                // Premium KC Logo
                KCLogo(size: 160, animated: true)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                
                // Brand
                VStack(spacing: KC.Space.md) {
                    Text("KRYPTOCLAW")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .tracking(4)
                        .foregroundColor(KC.Color.textPrimary)
                    
                    // Animated underline
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, KC.Color.gold, .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: underlineWidth, height: 2)
                        .clipShape(Capsule())
                    
                    Text("SECURE BY DESIGN")
                        .font(KC.Font.label)
                        .tracking(3)
                        .foregroundColor(KC.Color.textTertiary)
                        .padding(.top, KC.Space.xs)
                }
                .opacity(textOpacity)
                
                Spacer()
                Spacer()
            }
        }
        .onAppear {
            animateEntrance()
        }
    }
    
    private func animateEntrance() {
        // Logo fade in and scale
        withAnimation(.easeOut(duration: 0.7)) {
            logoOpacity = 1
            logoScale = 1
        }
        
        // Text fade
        withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
            textOpacity = 1
        }
        
        // Underline expand
        withAnimation(.easeInOut(duration: 0.6).delay(0.5)) {
            underlineWidth = 120
        }
    }
}

#Preview {
    SplashScreen()
}

