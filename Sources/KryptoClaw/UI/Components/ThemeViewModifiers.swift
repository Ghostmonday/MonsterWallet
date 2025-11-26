import SwiftUI

// MARK: - Theme-Aware View Modifiers
// VERSION: 2.0.0
// PURPOSE: Comprehensive theme-driven styling modifiers for consistent UI

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
                color: theme.shadowColor,
                radius: theme.shadowRadius,
                x: 0,
                y: theme.shadowY
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
                color: isHovering ? theme.accentColor.opacity(0.4) : theme.shadowColor,
                radius: isHovering ? theme.shadowRadius * 1.5 : theme.shadowRadius,
                x: 0,
                y: theme.shadowY
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
            .simultaneousGesture(TapGesture().onEnded {
                SoundManager.shared.playSound(named: theme.soundButtonPress)
            })
    }
}

// MARK: - Additional Theme Modifiers

/// Applies themed input field styling
public struct ThemedInputModifier: ViewModifier {
    let theme: ThemeProtocolV2
    let isError: Bool
    
    public init(theme: ThemeProtocolV2, isError: Bool = false) {
        self.theme = theme
        self.isError = isError
    }
    
    public func body(content: Content) -> some View {
        content
            .padding()
            .background(theme.inputBackgroundColor)
            .cornerRadius(theme.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadius)
                    .stroke(isError ? theme.errorColor : theme.borderColor, lineWidth: isError ? 2 : 1)
            )
            .foregroundColor(theme.textPrimary)
    }
}

/// Applies themed section header styling
public struct ThemedSectionHeaderModifier: ViewModifier {
    let theme: ThemeProtocolV2
    
    public init(theme: ThemeProtocolV2) {
        self.theme = theme
    }
    
    public func body(content: Content) -> some View {
        content
            .font(theme.headlineFont)
            .foregroundColor(theme.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Applies themed list row styling
public struct ThemedListRowModifier: ViewModifier {
    let theme: ThemeProtocolV2
    
    public init(theme: ThemeProtocolV2) {
        self.theme = theme
    }
    
    public func body(content: Content) -> some View {
        content
            .padding(.vertical, theme.spacingM)
            .padding(.horizontal, theme.spacingL)
            .background(theme.cardBackground)
            .cornerRadius(theme.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadius)
                    .stroke(theme.borderColor, lineWidth: 1)
            )
    }
}

/// Applies themed badge/chip styling
public struct ThemedBadgeModifier: ViewModifier {
    let theme: ThemeProtocolV2
    let color: Color?
    
    public init(theme: ThemeProtocolV2, color: Color? = nil) {
        self.theme = theme
        self.color = color
    }
    
    public func body(content: Content) -> some View {
        content
            .font(theme.captionFont)
            .padding(.horizontal, theme.spacingS)
            .padding(.vertical, theme.spacingXS)
            .background((color ?? theme.accentColor).opacity(0.15))
            .foregroundColor(color ?? theme.accentColor)
            .cornerRadius(theme.cornerRadiusSmall)
    }
}

/// Applies themed toast/alert styling
public struct ThemedToastModifier: ViewModifier {
    let theme: ThemeProtocolV2
    let type: ToastType
    
    public enum ToastType {
        case success
        case error
        case warning
        case info
    }
    
    public init(theme: ThemeProtocolV2, type: ToastType) {
        self.theme = theme
        self.type = type
    }
    
    private var backgroundColor: Color {
        switch type {
        case .success: return theme.successColor
        case .error: return theme.errorColor
        case .warning: return theme.warningColor
        case .info: return theme.accentColor
        }
    }
    
    public func body(content: Content) -> some View {
        content
            .padding()
            .background(theme.cardBackground)
            .cornerRadius(theme.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadius)
                    .stroke(backgroundColor, lineWidth: 1)
            )
            .shadow(color: theme.shadowColor, radius: theme.shadowRadius, x: 0, y: theme.shadowY)
            .onAppear {
                switch type {
                case .success:
                    SoundManager.shared.playSound(named: theme.soundSuccess)
                case .error:
                    SoundManager.shared.playSound(named: theme.soundError)
                case .warning, .info:
                    // Optional: Add warning/info sounds if needed
                    break
                }
            }
    }
}

/// Applies themed modal/sheet styling
public struct ThemedSheetModifier: ViewModifier {
    let theme: ThemeProtocolV2
    
    public init(theme: ThemeProtocolV2) {
        self.theme = theme
    }
    
    public func body(content: Content) -> some View {
        content
            .background(theme.backgroundMain)
    }
}

/// Applies themed destructive button styling
public struct ThemedDestructiveButtonModifier: ViewModifier {
    let theme: ThemeProtocolV2
    
    public init(theme: ThemeProtocolV2) {
        self.theme = theme
    }
    
    public func body(content: Content) -> some View {
        content
            .foregroundColor(theme.destructiveColor)
    }
}

/// Applies themed disabled state styling
public struct ThemedDisabledModifier: ViewModifier {
    let theme: ThemeProtocolV2
    let isDisabled: Bool
    
    public init(theme: ThemeProtocolV2, isDisabled: Bool) {
        self.theme = theme
        self.isDisabled = isDisabled
    }
    
    public func body(content: Content) -> some View {
        content
            .opacity(isDisabled ? 0.5 : 1.0)
            .allowsHitTesting(!isDisabled)
    }
}

/// Applies themed action button (circular) styling
public struct ThemedActionButtonModifier: ViewModifier {
    let theme: ThemeProtocolV2
    let isPrimary: Bool
    
    public init(theme: ThemeProtocolV2, isPrimary: Bool = true) {
        self.theme = theme
        self.isPrimary = isPrimary
    }
    
    public func body(content: Content) -> some View {
        content
            .frame(width: theme.actionButtonSize, height: theme.actionButtonSize)
            .background(
                RoundedRectangle(cornerRadius: theme.cornerRadius * 2)
                    .fill(isPrimary ? theme.accentColor.opacity(0.1) : theme.backgroundSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadius * 2)
                    .stroke(isPrimary ? theme.accentColor.opacity(0.5) : theme.borderColor, lineWidth: 1)
            )
            .simultaneousGesture(TapGesture().onEnded {
                SoundManager.shared.playSound(named: theme.soundButtonPress)
            })
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
    
    /// Applies themed input field styling
    func themedInput(theme: ThemeProtocolV2, isError: Bool = false) -> some View {
        self.modifier(ThemedInputModifier(theme: theme, isError: isError))
    }
    
    /// Applies themed section header styling
    func themedSectionHeader(theme: ThemeProtocolV2) -> some View {
        self.modifier(ThemedSectionHeaderModifier(theme: theme))
    }
    
    /// Applies themed list row styling
    func themedListRow(theme: ThemeProtocolV2) -> some View {
        self.modifier(ThemedListRowModifier(theme: theme))
    }
    
    /// Applies themed badge/chip styling
    func themedBadge(theme: ThemeProtocolV2, color: Color? = nil) -> some View {
        self.modifier(ThemedBadgeModifier(theme: theme, color: color))
    }
    
    /// Applies themed toast styling
    func themedToast(theme: ThemeProtocolV2, type: ThemedToastModifier.ToastType) -> some View {
        self.modifier(ThemedToastModifier(theme: theme, type: type))
    }
    
    /// Applies themed sheet styling
    func themedSheet(theme: ThemeProtocolV2) -> some View {
        self.modifier(ThemedSheetModifier(theme: theme))
    }
    
    /// Applies themed destructive styling
    func themedDestructive(theme: ThemeProtocolV2) -> some View {
        self.modifier(ThemedDestructiveButtonModifier(theme: theme))
    }
    
    /// Applies themed disabled styling
    func themedDisabled(theme: ThemeProtocolV2, isDisabled: Bool) -> some View {
        self.modifier(ThemedDisabledModifier(theme: theme, isDisabled: isDisabled))
    }
    
    /// Applies themed action button styling
    func themedActionButton(theme: ThemeProtocolV2, isPrimary: Bool = true) -> some View {
        self.modifier(ThemedActionButtonModifier(theme: theme, isPrimary: isPrimary))
    }
    
    /// Applies theme transition animation
    func withThemeTransition() -> some View {
        self.transition(.opacity.combined(with: .scale(scale: 0.95)))
            .animation(.easeInOut(duration: 0.3), value: UUID())
    }
    
    /// Applies standard themed shadow
    func themedShadow(theme: ThemeProtocolV2) -> some View {
        self.shadow(color: theme.shadowColor, radius: theme.shadowRadius, x: 0, y: theme.shadowY)
    }
    
    /// Applies themed corner radius
    func themedCornerRadius(_ theme: ThemeProtocolV2, size: CornerRadiusSize = .standard) -> some View {
        let radius: CGFloat
        switch size {
        case .small: radius = theme.cornerRadiusSmall
        case .standard: radius = theme.cornerRadius
        case .large: radius = theme.cornerRadiusLarge
        case .pill: radius = theme.cornerRadiusPill
        }
        return self.cornerRadius(radius)
    }
}

/// Corner radius size options
public enum CornerRadiusSize {
    case small
    case standard
    case large
    case pill
}

// MARK: - Themed Text Styles

public extension Text {
    /// Applies primary text styling
    func themedPrimary(_ theme: ThemeProtocolV2) -> some View {
        self.foregroundColor(theme.textPrimary)
    }
    
    /// Applies secondary text styling
    func themedSecondary(_ theme: ThemeProtocolV2) -> some View {
        self.foregroundColor(theme.textSecondary)
    }
    
    /// Applies accent text styling
    func themedAccent(_ theme: ThemeProtocolV2) -> some View {
        self.foregroundColor(theme.accentColor)
    }
    
    /// Applies success text styling
    func themedSuccess(_ theme: ThemeProtocolV2) -> some View {
        self.foregroundColor(theme.successColor)
    }
    
    /// Applies error text styling
    func themedError(_ theme: ThemeProtocolV2) -> some View {
        self.foregroundColor(theme.errorColor)
    }
    
    /// Applies warning text styling
    func themedWarning(_ theme: ThemeProtocolV2) -> some View {
        self.foregroundColor(theme.warningColor)
    }
}
