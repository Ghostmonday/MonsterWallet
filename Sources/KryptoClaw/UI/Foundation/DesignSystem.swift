// KRYPTOCLAW DESIGN SYSTEM
// A luxury instrument. A precision device. A Leica camera.
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Shared Date Formatters (Performance Optimization)
// DateFormatter is expensive to create. Reusing these instances improves list scrolling performance.

public extension DateFormatter {
    /// Short time format (e.g., "3:45 PM")
    static let shortTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
    
    /// Medium date with short time (e.g., "Nov 27, 2025 at 3:45 PM")
    static let mediumDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    /// Section header date format (e.g., "NOV 27, 2025")
    static let sectionHeader: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter
    }()
}

// MARK: - Design Tokens

/// KC: KryptoClaw Design System namespace
public enum KC {
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - COLOR PALETTE
    // Jet black foundation. Gold whispers. No compromise.
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    public enum Color {
        // BACKGROUNDS
        /// #030304 - The void. Pure black canvas.
        public static let bg = SwiftUI.Color(hex: 0x030304)
        
        /// Elevated surface - barely visible lift
        public static let surface = SwiftUI.Color(hex: 0x0A0A0C)
        
        /// Card background - subtle presence
        public static let card = SwiftUI.Color(hex: 0x101014)
        
        /// Elevated card - for layered UI
        public static let cardElevated = SwiftUI.Color(hex: 0x161619)
        
        // TEXT HIERARCHY
        /// Pure white - reserved for hero content only
        public static let textPrimary = SwiftUI.Color.white
        
        /// 85% white - standard readable text
        public static let textSecondary = SwiftUI.Color.white.opacity(0.85)
        
        /// 55% white - supporting text
        public static let textTertiary = SwiftUI.Color.white.opacity(0.55)
        
        /// 30% white - disabled/placeholder
        public static let textMuted = SwiftUI.Color.white.opacity(0.30)
        
        /// 15% white - ghost text
        public static let textGhost = SwiftUI.Color.white.opacity(0.15)
        
        // ACCENT - WARM GOLD
        /// #FAD073 - The signature. Used sparingly.
        public static let gold = SwiftUI.Color(hex: 0xFAD073)
        
        /// Gold at 20% - for backgrounds
        public static let goldSubtle = SwiftUI.Color(hex: 0xFAD073).opacity(0.20)
        
        /// Gold at 10% - for hover states
        public static let goldGhost = SwiftUI.Color(hex: 0xFAD073).opacity(0.10)
        
        // SEMANTIC COLORS
        /// Success green - confident, not neon
        public static let positive = SwiftUI.Color(hex: 0x4ADE80)
        
        /// Error red - urgent but elegant
        public static let negative = SwiftUI.Color(hex: 0xF87171)
        
        /// Warning amber
        public static let warning = SwiftUI.Color(hex: 0xFBBF24)
        
        /// Info blue
        public static let info = SwiftUI.Color(hex: 0x60A5FA)
        
        // BORDERS & DIVIDERS
        /// 8% white - subtle dividers
        public static let divider = SwiftUI.Color.white.opacity(0.08)
        
        /// 12% white - card borders
        public static let border = SwiftUI.Color.white.opacity(0.12)
        
        /// 20% white - interactive borders
        public static let borderActive = SwiftUI.Color.white.opacity(0.20)
        
        // CHAIN COLORS
        public static func chain(_ symbol: String) -> SwiftUI.Color {
            switch symbol.uppercased() {
            case "ETH", "ETHEREUM": return SwiftUI.Color(hex: 0x627EEA)
            case "BTC", "BITCOIN": return SwiftUI.Color(hex: 0xF7931A)
            case "SOL", "SOLANA": return SwiftUI.Color(hex: 0x14F195)
            case "USDC": return SwiftUI.Color(hex: 0x2775CA)
            case "USDT": return SwiftUI.Color(hex: 0x50AF95)
            case "AVAX", "AVALANCHE": return SwiftUI.Color(hex: 0xE84142)
            case "MATIC", "POL", "POLYGON": return SwiftUI.Color(hex: 0x8247E5)
            case "BNB": return SwiftUI.Color(hex: 0xF3BA2F)
            case "ARB", "ARBITRUM": return SwiftUI.Color(hex: 0x28A0F0)
            case "OP", "OPTIMISM": return SwiftUI.Color(hex: 0xFF0420)
            default: return textTertiary
            }
        }
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - TYPOGRAPHY
    // Bold. Clean. No goofy fonts.
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    public enum Font {
        // DISPLAY SCALE
        /// 64pt - Hero balance display
        public static let hero = SwiftUI.Font.system(size: 64, weight: .bold, design: .rounded)
        
        /// 48pt - Large numbers
        public static let display = SwiftUI.Font.system(size: 48, weight: .bold, design: .rounded)
        
        /// 36pt - Section headers
        public static let title1 = SwiftUI.Font.system(size: 36, weight: .bold)
        
        /// 28pt - Page titles
        public static let title2 = SwiftUI.Font.system(size: 28, weight: .bold)
        
        /// 22pt - Section titles
        public static let title3 = SwiftUI.Font.system(size: 22, weight: .semibold)
        
        // BODY SCALE
        /// 17pt - Large body / emphasized
        public static let bodyLarge = SwiftUI.Font.system(size: 17, weight: .semibold)
        
        /// 15pt - Standard body
        public static let body = SwiftUI.Font.system(size: 15, weight: .medium)
        
        /// 13pt - Small body / captions
        public static let caption = SwiftUI.Font.system(size: 13, weight: .medium)
        
        /// 11pt - Labels / badges
        public static let label = SwiftUI.Font.system(size: 11, weight: .semibold)
        
        /// 9pt - Micro labels
        public static let micro = SwiftUI.Font.system(size: 9, weight: .bold)
        
        // MONOSPACE - For addresses and numbers
        /// 20pt mono - Large amounts
        public static let monoLarge = SwiftUI.Font.system(size: 20, weight: .medium, design: .monospaced)
        
        /// 14pt mono - Addresses
        public static let mono = SwiftUI.Font.system(size: 14, weight: .medium, design: .monospaced)
        
        /// 12pt mono - Small addresses
        public static let monoSmall = SwiftUI.Font.system(size: 12, weight: .medium, design: .monospaced)
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - SPACING
    // Generous whitespace. Room to breathe.
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    public enum Space {
        public static let xxs: CGFloat = 2
        public static let xs: CGFloat = 4
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 12
        public static let lg: CGFloat = 16
        public static let xl: CGFloat = 24
        public static let xxl: CGFloat = 32
        public static let xxxl: CGFloat = 48
        public static let huge: CGFloat = 64
        public static let massive: CGFloat = 96
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - RADIUS
    // Subtle curves. Nothing bubbly.
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    public enum Radius {
        public static let xs: CGFloat = 4
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 12
        public static let lg: CGFloat = 16
        public static let xl: CGFloat = 20
        public static let xxl: CGFloat = 24
        public static let full: CGFloat = 999
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - SIZES
    // Consistent dimensions.
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    public enum Size {
        // Icons
        public static let iconXS: CGFloat = 16
        public static let iconSM: CGFloat = 20
        public static let iconMD: CGFloat = 24
        public static let iconLG: CGFloat = 32
        public static let iconXL: CGFloat = 40
        
        // Avatars / Token Icons
        public static let avatarSM: CGFloat = 32
        public static let avatarMD: CGFloat = 44
        public static let avatarLG: CGFloat = 56
        public static let avatarXL: CGFloat = 72
        
        // Buttons
        public static let buttonHeight: CGFloat = 56
        public static let buttonHeightSM: CGFloat = 44
        public static let buttonHeightXS: CGFloat = 36
        
        // Inputs
        public static let inputHeight: CGFloat = 56
        
        // Hit targets
        public static let minTouchTarget: CGFloat = 44
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - ANIMATION
    // Premium motion physics.
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    public enum Anim {
        /// Quick micro-interactions
        public static let quick = Animation.easeOut(duration: 0.15)
        
        /// Standard transitions
        public static let standard = Animation.easeInOut(duration: 0.25)
        
        /// Smooth reveals
        public static let smooth = Animation.easeInOut(duration: 0.35)
        
        /// Luxurious slow reveals
        public static let slow = Animation.easeInOut(duration: 0.5)
        
        /// Spring for interactive elements
        public static let spring = Animation.spring(response: 0.35, dampingFraction: 0.7)
        
        /// Bouncy spring for success states
        public static let bounce = Animation.spring(response: 0.4, dampingFraction: 0.6)
    }
}

// MARK: - Color Hex Extension

extension SwiftUI.Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: alpha
        )
    }
}

// MARK: - View Extensions

public extension View {
    /// Apply the standard background
    func kcBackground() -> some View {
        self
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(KC.Color.bg.ignoresSafeArea())
    }
    
    /// Standard horizontal padding
    func kcPadding() -> some View {
        self.padding(.horizontal, KC.Space.xl)
    }
    
    /// Card style
    func kcCard() -> some View {
        self
            .background(KC.Color.card)
            .clipShape(RoundedRectangle(cornerRadius: KC.Radius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: KC.Radius.lg)
                    .stroke(KC.Color.border, lineWidth: 1)
            )
    }
}

// MARK: - Reusable Components

/// Primary action button - The gold standard
public struct KCButton: View {
    let title: String
    let icon: String?
    let style: Style
    let isLoading: Bool
    let action: () -> Void
    
    public enum Style {
        case primary    // Gold fill
        case secondary  // Bordered
        case ghost      // Text only
        case danger     // Red
    }
    
    public init(
        _ title: String,
        icon: String? = nil,
        style: Style = .primary,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.isLoading = isLoading
        self.action = action
    }
    
    public var body: some View {
        Button(action: {
            HapticEngine.shared.play(.selection)
            action()
        }) {
            HStack(spacing: KC.Space.sm) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: foreground))
                        .scaleEffect(0.8)
                } else {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .semibold))
                    }
                    Text(title)
                        .font(KC.Font.bodyLarge)
                }
            }
            .foregroundColor(foreground)
            .frame(maxWidth: .infinity)
            .frame(height: KC.Size.buttonHeight)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: KC.Radius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: KC.Radius.lg)
                    .stroke(borderColor, lineWidth: hasBorder ? 1 : 0)
            )
        }
        .disabled(isLoading)
        .opacity(isLoading ? 0.7 : 1)
    }
    
    private var foreground: Color {
        switch style {
        case .primary: return KC.Color.bg
        case .secondary: return KC.Color.textPrimary
        case .ghost: return KC.Color.gold
        case .danger: return KC.Color.negative
        }
    }
    
    private var background: Color {
        switch style {
        case .primary: return KC.Color.gold
        case .secondary: return KC.Color.card
        case .ghost: return .clear
        case .danger: return KC.Color.negative.opacity(0.15)
        }
    }
    
    private var borderColor: Color {
        switch style {
        case .secondary: return KC.Color.border
        case .danger: return KC.Color.negative.opacity(0.3)
        default: return .clear
        }
    }
    
    private var hasBorder: Bool {
        style == .secondary || style == .danger
    }
}

/// Compact action button
public struct KCIconButton: View {
    let icon: String
    let size: CGFloat
    let action: () -> Void
    
    public init(_ icon: String, size: CGFloat = KC.Size.buttonHeightXS, action: @escaping () -> Void) {
        self.icon = icon
        self.size = size
        self.action = action
    }
    
    public var body: some View {
        Button(action: {
            HapticEngine.shared.play(.selection)
            action()
        }) {
            Image(systemName: icon)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundColor(KC.Color.textSecondary)
                .frame(width: size, height: size)
                .background(KC.Color.card)
                .clipShape(Circle())
                .overlay(Circle().stroke(KC.Color.border, lineWidth: 1))
        }
    }
}

/// Text input field
public struct KCInput: View {
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil
    #if os(iOS)
    var keyboardType: UIKeyboardType = .default
    #endif
    var isSecure: Bool = false
    
    #if os(iOS)
    public init(
        _ placeholder: String,
        text: Binding<String>,
        icon: String? = nil,
        keyboardType: UIKeyboardType = .default,
        isSecure: Bool = false
    ) {
        self.placeholder = placeholder
        self._text = text
        self.icon = icon
        self.keyboardType = keyboardType
        self.isSecure = isSecure
    }
    #else
    public init(
        _ placeholder: String,
        text: Binding<String>,
        icon: String? = nil,
        isSecure: Bool = false
    ) {
        self.placeholder = placeholder
        self._text = text
        self.icon = icon
        self.isSecure = isSecure
    }
    #endif
    
    public var body: some View {
        HStack(spacing: KC.Space.md) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(KC.Color.textTertiary)
                    .frame(width: 24)
            }
            
            if isSecure {
                SecureField(placeholder, text: $text)
                    .font(KC.Font.body)
                    .foregroundColor(KC.Color.textPrimary)
            } else {
                TextField(placeholder, text: $text)
                    .font(KC.Font.body)
                    .foregroundColor(KC.Color.textPrimary)
                    #if os(iOS)
                    .keyboardType(keyboardType)
                    #endif
            }
        }
        .padding(.horizontal, KC.Space.lg)
        .frame(height: KC.Size.inputHeight)
        .background(KC.Color.card)
        .clipShape(RoundedRectangle(cornerRadius: KC.Radius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: KC.Radius.lg)
                .stroke(KC.Color.border, lineWidth: 1)
        )
    }
}

/// Token/Chain icon
public struct KCTokenIcon: View {
    let symbol: String
    let size: CGFloat
    
    public init(_ symbol: String, size: CGFloat = KC.Size.avatarMD) {
        self.symbol = symbol
        self.size = size
    }
    
    public var body: some View {
        let color = KC.Color.chain(symbol)
        ZStack {
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: size, height: size)
            
            Text(String(symbol.prefix(1)))
                .font(.system(size: size * 0.4, weight: .bold))
                .foregroundColor(color)
        }
    }
}

/// Section header
public struct KCSectionHeader: View {
    let title: String
    let action: (() -> Void)?
    let actionLabel: String?
    
    public init(_ title: String, action: (() -> Void)? = nil, actionLabel: String? = nil) {
        self.title = title
        self.action = action
        self.actionLabel = actionLabel
    }
    
    public var body: some View {
        HStack {
            Text(title.uppercased())
                .font(KC.Font.label)
                .tracking(1.5)
                .foregroundColor(KC.Color.textTertiary)
            
            Spacer()
            
            if let action = action, let label = actionLabel {
                Button(action: action) {
                    HStack(spacing: KC.Space.xs) {
                        Text(label)
                            .font(KC.Font.caption)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(KC.Color.gold)
                }
            }
        }
    }
}

/// Loading shimmer effect
public struct KCShimmer: View {
    @State private var phase: CGFloat = 0
    let width: CGFloat
    let height: CGFloat
    
    public init(width: CGFloat = 100, height: CGFloat = 16) {
        self.width = width
        self.height = height
    }
    
    public var body: some View {
        RoundedRectangle(cornerRadius: KC.Radius.xs)
            .fill(KC.Color.cardElevated)
            .frame(width: width, height: height)
            .overlay(
                RoundedRectangle(cornerRadius: KC.Radius.xs)
                    .fill(
                        LinearGradient(
                            colors: [.clear, KC.Color.textGhost, .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: phase)
            )
            .clipShape(RoundedRectangle(cornerRadius: KC.Radius.xs))
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = width * 2
                }
            }
    }
}

/// Empty state view
public struct KCEmptyState: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    public init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    public var body: some View {
        VStack(spacing: KC.Space.xl) {
            ZStack {
                Circle()
                    .fill(KC.Color.goldGhost)
                    .frame(width: 80, height: 80)
                
                Image(systemName: icon)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(KC.Color.gold)
            }
            
            VStack(spacing: KC.Space.sm) {
                Text(title)
                    .font(KC.Font.title3)
                    .foregroundColor(KC.Color.textPrimary)
                
                Text(message)
                    .font(KC.Font.body)
                    .foregroundColor(KC.Color.textTertiary)
                    .multilineTextAlignment(.center)
            }
            
            if let actionTitle = actionTitle, let action = action {
                KCButton(actionTitle, style: .secondary, action: action)
                    .frame(width: 200)
            }
        }
        .padding(KC.Space.xxl)
    }
}

/// Close button (X)
public struct KCCloseButton: View {
    let action: () -> Void
    
    public init(action: @escaping () -> Void) {
        self.action = action
    }
    
    public var body: some View {
        KCIconButton("xmark", action: action)
    }
}

/// Back button (chevron)
public struct KCBackButton: View {
    let action: () -> Void
    
    public init(action: @escaping () -> Void) {
        self.action = action
    }
    
    public var body: some View {
        KCIconButton("chevron.left", action: action)
    }
}

/// Toast/Alert banner
public struct KCBanner: View {
    let message: String
    let type: BannerType
    
    public enum BannerType {
        case success, error, warning, info
        
        var color: Color {
            switch self {
            case .success: return KC.Color.positive
            case .error: return KC.Color.negative
            case .warning: return KC.Color.warning
            case .info: return KC.Color.info
            }
        }
        
        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "exclamationmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .info: return "info.circle.fill"
            }
        }
    }
    
    public init(_ message: String, type: BannerType) {
        self.message = message
        self.type = type
    }
    
    public var body: some View {
        HStack(spacing: KC.Space.md) {
            Image(systemName: type.icon)
                .foregroundColor(type.color)
            
            Text(message)
                .font(KC.Font.body)
                .foregroundColor(KC.Color.textPrimary)
            
            Spacer()
        }
        .padding(KC.Space.lg)
        .background(type.color.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: KC.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: KC.Radius.md)
                .stroke(type.color.opacity(0.3), lineWidth: 1)
        )
    }
}

