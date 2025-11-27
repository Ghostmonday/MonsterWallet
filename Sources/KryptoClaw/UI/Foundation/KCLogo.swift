// KRYPTOCLAW LOGO
// Premium metallic KC monogram
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

import SwiftUI

/// The KryptoClaw monogram - KC in metallic silver
public struct KCLogo: View {
    let size: CGFloat
    var animated: Bool = false
    
    @State private var shimmerOffset: CGFloat = -1
    
    public init(size: CGFloat = 100, animated: Bool = false) {
        self.size = size
        self.animated = animated
    }
    
    public var body: some View {
        Image("Logo")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
            .overlay(
                // Seamless shimmer - diagonal sweep that loops perfectly
                GeometryReader { geometry in
                    let diagonal = sqrt(geometry.size.width * geometry.size.width + geometry.size.height * geometry.size.height)
                    let offsetX = (shimmerOffset - 0.5) * diagonal * 2.0
                    let offsetY = (shimmerOffset - 0.5) * diagonal * 2.0
                    
                    Rectangle()
                        .fill(
                            LinearGradient(
                                stops: [
                                    .init(color: .clear, location: 0.0),
                                    .init(color: .clear, location: 0.3),
                                    .init(color: .white.opacity(0.5), location: 0.5),
                                    .init(color: .clear, location: 0.7),
                                    .init(color: .clear, location: 1.0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: diagonal * 1.5, height: diagonal * 1.5)
                        .rotationEffect(.degrees(45))
                        .offset(x: offsetX, y: offsetY)
                        .opacity(animated ? 1 : 0)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: size * 0.1))
            .onAppear {
                if animated {
                    // Start completely off-screen, end completely off-screen for seamless loop
                    shimmerOffset = -0.3
                    withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                        shimmerOffset = 1.3
                    }
                }
            }
    }
}

// Old KCMonogram vector shape removed - now using image asset

/// Simplified icon version for small sizes
public struct KCLogoIcon: View {
    let size: CGFloat
    
    public init(size: CGFloat = 24) {
        self.size = size
    }
    
    public var body: some View {
        ZStack {
            Circle()
                .fill(KC.Color.bg)
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(hex: 0x808080),
                                    Color(hex: 0xD0D0D0),
                                    Color(hex: 0x808080),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: size * 0.06
                        )
                )
            
            Image("Logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size * 0.7, height: size * 0.7)
        }
        .frame(width: size, height: size)
    }
}

/// App icon style logo with background
public struct KCLogoFull: View {
    let size: CGFloat
    
    public init(size: CGFloat = 120) {
        self.size = size
    }
    
    public var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: size * 0.22)
                .fill(Color(hex: 0x030304))
            
            // Subtle gradient overlay
            RoundedRectangle(cornerRadius: size * 0.22)
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.03),
                            Color.clear
                        ],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: size
                    )
                )
            
            // Logo
            KCLogo(size: size * 0.7, animated: false)
        }
        .frame(width: size, height: size)
        .shadow(color: .black.opacity(0.3), radius: size * 0.1, y: size * 0.05)
    }
}

// MARK: - Previews

#Preview("KC Logo") {
    ZStack {
        Color(hex: 0x030304).ignoresSafeArea()
        
        VStack(spacing: 40) {
            KCLogo(size: 200, animated: true)
            
            HStack(spacing: 30) {
                KCLogoIcon(size: 44)
                KCLogoIcon(size: 32)
                KCLogoIcon(size: 24)
            }
            
            KCLogoFull(size: 120)
        }
    }
}

