import SwiftUI

// MARK: - Theme-Aware View Modifiers

/// Applies comprehensive theme styling to any view, including background, material effects, patterns, and animations
public struct ThemedContainerModifier: ViewModifier {
    let theme: ThemeProtocolV2
    let showPattern: Bool
    let applyAnimation: Bool
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    public init(theme: ThemeProtocolV2, showPattern: Bool = true, applyAnimation: Bool = true) {
        self.theme = theme
        self.showPattern = showPattern
        self.applyAnimation = applyAnimation
    }
    
    public func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Base background
                    theme.backgroundMain
                    
                    // Theme-specific pattern overlay
                    if showPattern && theme.showDiamondPattern {
                        DiamondPattern()
                            .stroke(theme.accentColor.opacity(0.03), lineWidth: 1)
                            .background(theme.backgroundMain)
                    }
                    
                    // Theme-specific background animation
                    if applyAnimation && !reduceMotion {
                        switch theme.backgroundAnimation {
                        case .liquidRefraction:
                            LiquidRefractionBackground(theme: theme)
                        case .fireParticles:
                            FireParticlesBackground(theme: theme)
                        case .waterWave:
                            WaterWaveBackground(theme: theme)
                        case .none:
                            EmptyView()
                        }
                    }
                }
            )
    }
}

/// Applies themed card styling with glassmorphism and material effects
public struct ThemedCardModifier: ViewModifier {
    let theme: ThemeProtocolV2
    let useMaterial: Bool
    
    public init(theme: ThemeProtocolV2, useMaterial: Bool = true) {
        self.theme = theme
        self.useMaterial = useMaterial
    }
    
    public func body(content: Content) -> some View {
        content
            .padding()
            .background(
                ZStack {
                    if useMaterial {
                        theme.cardBackground.opacity(theme.glassEffectOpacity)
                            .background(.ultraThinMaterial)
                    } else {
                        theme.cardBackground
                    }
                }
            )
            .cornerRadius(theme.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadius)
                    .stroke(theme.borderColor, lineWidth: 1)
            )
            .shadow(
                color: theme.accentColor.opacity(0.1),
                radius: theme.cornerRadius / 2,
                x: 0,
                y: 2
            )
    }
}

/// Applies themed button styling with hover effects and haptics
public struct ThemedButtonModifier: ViewModifier {
    let theme: ThemeProtocolV2
    let isPrimary: Bool
    @State private var isPressed = false
    @State private var isHovering = false
    
    public init(theme: ThemeProtocolV2, isPrimary: Bool) {
        self.theme = theme
        self.isPrimary = isPrimary
    }
    
    public func body(content: Content) -> some View {
        content
            .padding()
            .background(
                Group {
                    if isPrimary {
                        theme.accentColor
                    } else {
                        theme.backgroundSecondary
                    }
                }
            )
            .foregroundColor(isPrimary ? theme.backgroundMain : theme.textPrimary)
            .cornerRadius(theme.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadius)
                    .stroke(theme.borderColor, lineWidth: isPrimary ? 0 : 1)
            )
            .shadow(
                color: isHovering ? theme.accentColor.opacity(0.4) : theme.accentColor.opacity(0.1),
                radius: isHovering ? theme.cornerRadius : theme.cornerRadius / 2,
                x: 0,
                y: 2
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .animation(.easeInOut(duration: 0.2), value: isHovering)
            .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
                isPressed = pressing
            }, perform: {})
            .onHover { hovering in
                isHovering = hovering
            }
    }
}

// MARK: - Background Animation Views

struct LiquidRefractionBackground: View {
    let theme: ThemeProtocolV2
    @State private var phase: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    theme.accentColor.opacity(0.15),
                                    theme.accentColor.opacity(0.05),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 200
                            )
                        )
                        .frame(width: 400, height: 400)
                        .offset(
                            x: cos(phase + Double(index) * 2.0) * 100,
                            y: sin(phase + Double(index) * 1.5) * 100
                        )
                        .blur(radius: 50)
                }
            }
            .onAppear {
                withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                    phase = .pi * 2
                }
            }
        }
    }
}

struct FireParticlesBackground: View {
    let theme: ThemeProtocolV2
    @State private var particles: [FireParticle] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(theme.errorColor.opacity(particle.opacity))
                        .frame(width: particle.size, height: particle.size)
                        .position(x: particle.x, y: particle.y)
                        .blur(radius: 3)
                }
            }
            .onAppear {
                particles = (0..<15).map { _ in
                    FireParticle(
                        x: CGFloat.random(in: 0...geometry.size.width),
                        y: CGFloat.random(in: 0...geometry.size.height),
                        size: CGFloat.random(in: 20...60),
                        opacity: Double.random(in: 0.05...0.15)
                    )
                }
            }
        }
    }
}

struct WaterWaveBackground: View {
    let theme: ThemeProtocolV2
    @State private var waveOffset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<3, id: \.self) { index in
                    Wave(offset: waveOffset + CGFloat(index) * 0.3, percent: 0.6 + CGFloat(index) * 0.1)
                        .fill(theme.accentColor.opacity(0.05 - Double(index) * 0.01))
                        .frame(height: geometry.size.height)
                }
            }
            .onAppear {
                withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                    waveOffset = 360
                }
            }
        }
    }
}

// MARK: - Helper Shapes and Models

struct Wave: Shape {
    var offset: CGFloat
    var percent: CGFloat
    
    var animatableData: CGFloat {
        get { offset }
        set { offset = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midHeight = height * percent
        
        path.move(to: CGPoint(x: 0, y: midHeight))
        
        for x in stride(from: 0, through: width, by: 1) {
            let relativeX = x / width
            let sine = sin((relativeX + offset / 360) * .pi * 2)
            let y = midHeight + sine * 20
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        
        return path
    }
}

struct FireParticle: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let opacity: Double
}

// MARK: - View Extensions for Easy Theme Application

public extension View {
    /// Applies comprehensive themed container styling
    func themedContainer(theme: ThemeProtocolV2, showPattern: Bool = true, applyAnimation: Bool = true) -> some View {
        self.modifier(ThemedContainerModifier(theme: theme, showPattern: showPattern, applyAnimation: applyAnimation))
    }
    
    /// Applies themed card styling with glassmorphism
    func themedCard(theme: ThemeProtocolV2, useMaterial: Bool = true) -> some View {
        self.modifier(ThemedCardModifier(theme: theme, useMaterial: useMaterial))
    }
    
    /// Applies themed button styling
    func themedButton(theme: ThemeProtocolV2, isPrimary: Bool) -> some View {
        self.modifier(ThemedButtonModifier(theme: theme, isPrimary: isPrimary))
    }
    
    /// Applies theme transition animation
    func withThemeTransition() -> some View {
        self.transition(.opacity.combined(with: .scale(scale: 0.95)))
            .animation(.easeInOut(duration: 0.3), value: UUID())
    }
}
