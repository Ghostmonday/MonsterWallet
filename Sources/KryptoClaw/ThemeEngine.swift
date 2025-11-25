import SwiftUI

// MARK: - Theme Protocol V2 (Elite)
public protocol ThemeProtocolV2 {
    var id: String { get }
    var name: String { get }

    var backgroundMain: Color { get }
    var backgroundSecondary: Color { get }
    var textPrimary: Color { get }
    var textSecondary: Color { get }
    var accentColor: Color { get }
    var successColor: Color { get }
    var errorColor: Color { get }
    var warningColor: Color { get }

    var cardBackground: Color { get }
    var borderColor: Color { get }

    // Advanced (V2)
    var glassEffectOpacity: Double { get } // For glassmorphism
    var materialStyle: Material { get }
    var showDiamondPattern: Bool { get }
    var backgroundAnimation: BackgroundAnimationType { get }
    var chartGradientColors: [Color] { get }
    var securityWarningColor: Color { get } // For poisoning alerts
    var secureEnclaveColor: Color { get } // For hardware-backed security indicators

    var cornerRadius: CGFloat { get }

    var balanceFont: Font { get }
    var addressFont: Font { get }
    func font(style: Font.TextStyle) -> Font

    var iconSend: String { get }
    var iconReceive: String { get }
    var iconSwap: String { get }
    var iconSettings: String { get }
    var iconShield: String { get }
}

public enum BackgroundAnimationType {
    case none
    case liquidRefraction
    case fireParticles
    case waterWave
}

public extension ThemeProtocolV2 {
    var materialStyle: Material { .regular }
    var showDiamondPattern: Bool { false }
    var backgroundAnimation: BackgroundAnimationType { .none }
    var secureEnclaveColor: Color { successColor } // Default to success color
    
    // Backward compatibility: hasDiamondTexture maps to showDiamondPattern
    var hasDiamondTexture: Bool { showDiamondPattern }
}

public enum KryptoColors {
    public static let pitchBlack = Color.black
    public static let deepSpace = Color(red: 0.05, green: 0.05, blue: 0.1)
    public static let weaponizedPurple = Color(red: 0.6, green: 0.0, blue: 1.0)
    public static let cyberBlue = Color(red: 0.0, green: 0.8, blue: 1.0)
    public static let neonRed = Color(red: 1.0, green: 0.1, blue: 0.1)
    public static let neonGreen = Color(red: 0.1, green: 1.0, blue: 0.1)
    public static let bunkerGray = Color(white: 0.12)
    public static let warningOrange = Color(red: 1.0, green: 0.6, blue: 0.0)
    public static let white = Color.white

    public static let luxuryGold = Color(red: 0.83, green: 0.69, blue: 0.22)
    public static let luxuryBrown = Color(red: 0.24, green: 0.17, blue: 0.12)
    public static let deepOcean = Color(red: 0.0, green: 0.1, blue: 0.2)
    public static let icyBlue = Color(red: 0.6, green: 0.8, blue: 1.0)
    public static let ashGray = Color(white: 0.2)
    public static let emberOrange = Color(red: 1.0, green: 0.4, blue: 0.0)
}

public enum ThemeType: String, CaseIterable, Identifiable {
    case eliteDark
    case cyberPunk
    case pureWhite
    case luxuryMonogram
    case fireAsh
    case waterIce

    case appleDefault
    case stealthBomber
    case neonTokyo
    case obsidianStealth
    case quantumFrost
    case bunkerGray
    case crimsonTide
    case cyberpunkNeon
    case goldenEra
    case matrixCode

    public var id: String { rawValue }

    public var name: String {
        switch self {
        case .eliteDark: "Elite Dark (Signature)"
        case .cyberPunk: "Cyberpunk (Classic)"
        case .pureWhite: "Pure White"
        case .luxuryMonogram: "Luxury Monogram"
        case .fireAsh: "Fire & Ash"
        case .waterIce: "Water & Ice"
        default: rawValue.capitalized
        }
    }
}

public class ThemeFactory {
    public static func create(type: ThemeType) -> ThemeProtocolV2 {
        switch type {
        case .eliteDark: EliteDarkTheme()
        case .cyberPunk: CyberPunkTheme()
        case .pureWhite: PureWhiteTheme()
        case .luxuryMonogram: LuxuryMonogramTheme()
        case .fireAsh: FireAshTheme()
        case .waterIce: WaterIceTheme()
        case .obsidianStealth: ObsidianStealthTheme()
        case .stealthBomber: StealthBomberTheme()
        case .goldenEra: GoldenEraTheme()
        case .crimsonTide: CrimsonTideTheme()
        case .quantumFrost: QuantumFrostTheme()
        case .neonTokyo: NeonTokyoTheme()
        case .cyberpunkNeon: CyberpunkNeonTheme()
        case .matrixCode: MatrixCodeTheme()
        case .bunkerGray: BunkerGrayTheme()
        case .appleDefault: AppleDefaultTheme()
        }
    }
}

public class ThemeManager: ObservableObject {
    @Published public var currentTheme: ThemeProtocolV2

    public init(type: ThemeType = .eliteDark) {
        currentTheme = ThemeFactory.create(type: type)
    }

    public func setTheme(type: ThemeType) {
        withAnimation {
            self.currentTheme = ThemeFactory.create(type: type)
        }
    }
}

// MARK: - Standard Themes

// Elite Dark - Supreme flagship theme with surgical precision
public struct EliteDarkTheme: ThemeProtocolV2 {
    public let id = "elite_dark"
    public let name = "Elite Dark"

    // Sophisticated monochrome with surgical precision
    public let backgroundMain = Color(red: 0.0, green: 0.0, blue: 0.0) // Absolute black
    public let backgroundSecondary = Color(red: 0.02, green: 0.025, blue: 0.03) // Gunmetal shadow
    public let textPrimary = Color(red: 0.98, green: 0.98, blue: 1.0) // Diamond white with cool hint
    public let textSecondary = Color(red: 0.55, green: 0.57, blue: 0.6) // Platinum mist
    public let accentColor = Color(red: 0.82, green: 0.87, blue: 0.92) // Polished titanium
    public let successColor = Color(red: 0.15, green: 0.95, blue: 0.45) // Surgical green
    public let errorColor = Color(red: 0.95, green: 0.15, blue: 0.25) // Alert crimson
    public let warningColor = Color(red: 0.95, green: 0.75, blue: 0.15) // Caution amber
    public let cardBackground = Color(red: 0.03, green: 0.035, blue: 0.04).opacity(0.92)
    public let borderColor = Color(red: 0.25, green: 0.27, blue: 0.3).opacity(0.6)

    public let glassEffectOpacity = 0.96
    public let materialStyle: Material = .ultraThin
    public let showDiamondPattern = true
    public let backgroundAnimation: BackgroundAnimationType = .none
    public let chartGradientColors = [
        Color(red: 0.82, green: 0.87, blue: 0.92),
        Color(red: 0.45, green: 0.48, blue: 0.52)
    ]
    public let securityWarningColor = Color(red: 0.95, green: 0.15, blue: 0.25)
    public let secureEnclaveColor = Color(red: 0.0, green: 0.85, blue: 0.65) // Neon Mint for Elite Dark

    public let cornerRadius: CGFloat = 2.0 // Razor-sharp precision

    // Typography: SF Pro with optical sizing
    public let balanceFont = Font.system(size: 44, weight: .heavy, design: .rounded)
    public let addressFont = Font.system(size: 12, weight: .semibold, design: .monospaced)

    public func font(style: Font.TextStyle) -> Font {
        Font.system(style, design: .default).weight(.medium)
    }

    public let iconSend = "arrow.up.right.circle.fill"
    public let iconReceive = "arrow.down.left.circle.fill"
    public let iconSwap = "arrow.triangle.swap"
    public let iconSettings = "gearshape.circle.fill"
    public let iconShield = "checkmark.shield.fill"
}

// Cyberpunk - Retro-futuristic dystopia with 80s neon aesthetics
public struct CyberPunkTheme: ThemeProtocolV2 {
    public let id = "cyber_punk"
    public let name = "Cyberpunk"

    // Vibrant 80s-inspired palette with deep purples
    public let backgroundMain = Color(red: 0.08, green: 0.0, blue: 0.18) // Deep violet night
    public let backgroundSecondary = Color(red: 0.15, green: 0.05, blue: 0.25) // Neon haze
    public let textPrimary = Color(red: 1.0, green: 0.95, blue: 0.2) // Electric lime
    public let textSecondary = Color(red: 0.3, green: 0.95, blue: 0.95) // Bright cyan
    public let accentColor = Color(red: 1.0, green: 0.2, blue: 0.75) // Hot magenta
    public let successColor = Color(red: 0.2, green: 0.95, blue: 0.4)
    public let errorColor = Color(red: 0.95, green: 0.2, blue: 0.3)
    public let warningColor = Color(red: 0.95, green: 0.6, blue: 0.1)
    public let cardBackground = Color(red: 0.05, green: 0.0, blue: 0.12).opacity(0.75)
    public let borderColor = Color(red: 1.0, green: 0.2, blue: 0.75).opacity(0.7)

    public let glassEffectOpacity = 0.55
    public let materialStyle: Material = .thin
    public let showDiamondPattern = false
    public let backgroundAnimation: BackgroundAnimationType = .liquidRefraction
    public let chartGradientColors = [
        Color(red: 1.0, green: 0.2, blue: 0.75),
        Color(red: 0.3, green: 0.95, blue: 0.95)
    ]
    public let securityWarningColor = Color(red: 0.95, green: 0.2, blue: 0.3)
    public let secureEnclaveColor = Color(red: 0.0, green: 1.0, blue: 0.9) // Cyber Cyan

    public let cornerRadius: CGFloat = 3.0

    // Typography: Bold monospace for retro-futuristic feel
    public let balanceFont = Font.system(size: 40, weight: .black, design: .monospaced)
    public let addressFont = Font.system(size: 13, weight: .semibold, design: .monospaced)

    public func font(style: Font.TextStyle) -> Font {
        Font.system(style, design: .monospaced).weight(.bold)
    }

    public let iconSend = "chart.line.uptrend.xyaxis"
    public let iconReceive = "chart.line.downtrend.xyaxis"
    public let iconSwap = "arrow.triangle.2.circlepath.circle.fill"
    public let iconSettings = "cpu"
    public let iconShield = "exclamationmark.shield.fill"
}

// Pure White - Minimalist luxury with Japanese aesthetic
public struct PureWhiteTheme: ThemeProtocolV2 {
    public let id = "pure_white"
    public let name = "Pure White"

    // Sophisticated neutrals with warm undertones
    public let backgroundMain = Color(red: 0.99, green: 0.98, blue: 0.97) // Warm white
    public let backgroundSecondary = Color(red: 0.96, green: 0.95, blue: 0.94) // Pearl gray
    public let textPrimary = Color(red: 0.12, green: 0.11, blue: 0.10) // Rich black
    public let textSecondary = Color(red: 0.45, green: 0.44, blue: 0.43) // Charcoal
    public let accentColor = Color(red: 0.25, green: 0.52, blue: 0.96) // Refined blue
    public let successColor = Color(red: 0.2, green: 0.72, blue: 0.4)
    public let errorColor = Color(red: 0.92, green: 0.26, blue: 0.21)
    public let warningColor = Color(red: 0.95, green: 0.61, blue: 0.07)
    public let cardBackground = Color.white.opacity(0.95)
    public let borderColor = Color(red: 0.88, green: 0.87, blue: 0.86)

    public let glassEffectOpacity = 0.94
    public let materialStyle: Material = .thick
    public let showDiamondPattern = false
    public let backgroundAnimation: BackgroundAnimationType = .none
    public let chartGradientColors = [
        Color(red: 0.25, green: 0.52, blue: 0.96),
        Color(red: 0.45, green: 0.33, blue: 0.83)
    ]
    public let securityWarningColor = Color(red: 0.95, green: 0.61, blue: 0.07)

    public let cornerRadius: CGFloat = 14.0 // Soft, approachable

    // Typography: Clean and elegant
    public let balanceFont = Font.system(size: 38, weight: .semibold, design: .rounded)
    public let addressFont = Font.system(size: 12, weight: .regular, design: .monospaced)

    public func font(style: Font.TextStyle) -> Font {
        Font.system(style, design: .rounded).weight(.regular)
    }

    public let iconSend = "arrow.up.circle.fill"
    public let iconReceive = "arrow.down.circle.fill"
    public let iconSwap = "arrow.triangle.2.circlepath"
    public let iconSettings = "slider.horizontal.3"
    public let iconShield = "checkmark.seal.fill"
}

// Luxury Monogram - Old-world opulence meets modern sophistication
public struct LuxuryMonogramTheme: ThemeProtocolV2 {
    public let id = "luxury_monogram"
    public let name = "Luxury Monogram"

    // Rich, sophisticated palette inspired by haute couture
    public let backgroundMain = Color(red: 0.22, green: 0.16, blue: 0.11) // Deep cognac
    public let backgroundSecondary = Color(red: 0.15, green: 0.12, blue: 0.08) // Aged leather
    public let textPrimary = Color(red: 0.95, green: 0.87, blue: 0.62) // Champagne gold
    public let textSecondary = Color(red: 0.78, green: 0.72, blue: 0.62) // Silk beige
    public let accentColor = Color(red: 0.85, green: 0.70, blue: 0.25) // 18k gold
    public let successColor = Color(red: 0.52, green: 0.68, blue: 0.35)
    public let errorColor = Color(red: 0.78, green: 0.25, blue: 0.22)
    public let warningColor = Color(red: 0.88, green: 0.62, blue: 0.22)
    public let cardBackground = Color(red: 0.18, green: 0.14, blue: 0.10).opacity(0.92)
    public let borderColor = Color(red: 0.85, green: 0.70, blue: 0.25).opacity(0.55)

    public let glassEffectOpacity = 0.91
    public let materialStyle: Material = .regular
    public let showDiamondPattern = true
    public let backgroundAnimation: BackgroundAnimationType = .none
    public let chartGradientColors = [
        Color(red: 0.85, green: 0.70, blue: 0.25),
        Color(red: 0.62, green: 0.52, blue: 0.32)
    ]
    public let securityWarningColor = Color(red: 0.78, green: 0.25, blue: 0.22)
    public let secureEnclaveColor = Color(red: 0.85, green: 0.70, blue: 0.25) // Gold

    public let cornerRadius: CGFloat = 10.0

    // Typography: Classic serif with elegance
    public let balanceFont = Font.system(size: 42, weight: .semibold, design: .serif)
    public let addressFont = Font.system(size: 12, weight: .regular, design: .serif)

    public func font(style: Font.TextStyle) -> Font {
        Font.system(style, design: .serif).weight(.medium)
    }

    public let iconSend = "paperplane.circle.fill"
    public let iconReceive = "tray.circle.fill"
    public let iconSwap = "infinity.circle.fill"
    public let iconSettings = "crown.fill"
    public let iconShield = "seal.fill"
}

// Fire & Ash - Volcanic intensity with smoldering elegance
public struct FireAshTheme: ThemeProtocolV2 {
    public let id = "fire_ash"
    public let name = "Fire & Ash"

    // Volcanic palette with dramatic contrast
    public let backgroundMain = Color(red: 0.18, green: 0.18, blue: 0.18) // Volcanic ash
    public let backgroundSecondary = Color(red: 0.08, green: 0.08, blue: 0.08) // Charcoal depth
    public let textPrimary = Color(red: 0.98, green: 0.55, blue: 0.15) // Molten lava
    public let textSecondary = Color(red: 0.72, green: 0.72, blue: 0.70) // Smoke gray
    public let accentColor = Color(red: 0.95, green: 0.35, blue: 0.12) // Burning ember
    public let successColor = Color(red: 0.42, green: 0.78, blue: 0.38)
    public let errorColor = Color(red: 0.92, green: 0.22, blue: 0.18)
    public let warningColor = Color(red: 0.98, green: 0.65, blue: 0.18)
    public let cardBackground = Color(red: 0.12, green: 0.12, blue: 0.12).opacity(0.82)
    public let borderColor = Color(red: 0.95, green: 0.35, blue: 0.12).opacity(0.45)

    public let glassEffectOpacity = 0.62
    public let materialStyle: Material = .thin
    public let showDiamondPattern = false
    public let backgroundAnimation: BackgroundAnimationType = .fireParticles
    public let chartGradientColors = [
        Color(red: 0.98, green: 0.55, blue: 0.15),
        Color(red: 0.75, green: 0.22, blue: 0.15)
    ]
    public let securityWarningColor = Color(red: 0.92, green: 0.22, blue: 0.18)

    public let cornerRadius: CGFloat = 6.0

    // Typography: Bold and impactful
    public let balanceFont = Font.system(size: 40, weight: .heavy, design: .rounded)
    public let addressFont = Font.system(size: 13, weight: .semibold, design: .monospaced)

    public func font(style: Font.TextStyle) -> Font {
        Font.system(style, design: .rounded).weight(.semibold)
    }

    public let iconSend = "flame.circle.fill"
    public let iconReceive = "smoke.circle.fill"
    public let iconSwap = "tornado"
    public let iconSettings = "poweron"
    public let iconShield = "shield.slash.fill"
}

// Water & Ice - Serene aquatic depths with crystalline clarity
public struct WaterIceTheme: ThemeProtocolV2 {
    public let id = "water_ice"
    public let name = "Water & Ice"

    // Sophisticated aquatic palette with depth
    public let backgroundMain = Color(red: 0.02, green: 0.12, blue: 0.22) // Deep ocean
    public let backgroundSecondary = Color(red: 0.08, green: 0.18, blue: 0.28) // Twilight water
    public let textPrimary = Color(red: 0.75, green: 0.92, blue: 0.98) // Glacier ice
    public let textSecondary = Color(red: 0.52, green: 0.72, blue: 0.85) // Arctic mist
    public let accentColor = Color(red: 0.35, green: 0.75, blue: 0.92) // Crystal blue
    public let successColor = Color(red: 0.28, green: 0.88, blue: 0.82)
    public let errorColor = Color(red: 0.78, green: 0.35, blue: 0.88)
    public let warningColor = Color(red: 0.88, green: 0.82, blue: 0.35)
    public let cardBackground = Color(red: 0.04, green: 0.14, blue: 0.24).opacity(0.75)
    public let borderColor = Color(red: 0.35, green: 0.75, blue: 0.92).opacity(0.48)

    public let glassEffectOpacity = 0.68
    public let materialStyle: Material = .ultraThin
    public let showDiamondPattern = false
    public let backgroundAnimation: BackgroundAnimationType = .waterWave
    public let chartGradientColors = [
        Color(red: 0.35, green: 0.75, blue: 0.92),
        Color(red: 0.15, green: 0.38, blue: 0.75)
    ]
    public let securityWarningColor = Color(red: 0.78, green: 0.35, blue: 0.88)

    public let cornerRadius: CGFloat = 20.0 // Fluid, organic

    // Typography: Light and flowing
    public let balanceFont = Font.system(size: 38, weight: .light, design: .rounded)
    public let addressFont = Font.system(size: 12, weight: .light, design: .monospaced)

    public func font(style: Font.TextStyle) -> Font {
        Font.system(style, design: .default).weight(.light)
    }

    public let iconSend = "paperplane.circle.fill"
    public let iconReceive = "tray.circle.fill"
    public let iconSwap = "arrow.triangle.capsulepath"
    public let iconSettings = "slider.horizontal.2.square"
    public let iconShield = "checkmark.seal.fill"
}

