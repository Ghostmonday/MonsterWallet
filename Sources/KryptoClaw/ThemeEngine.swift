import SwiftUI

// MARK: - Theme Protocol V2 (Elite)
public protocol ThemeProtocolV2 {
    var id: String { get }
    var name: String { get }
    
    // Core Colors
    var backgroundMain: Color { get }
    var backgroundSecondary: Color { get }
    var textPrimary: Color { get }
    var textSecondary: Color { get }
    var accentColor: Color { get }
    var successColor: Color { get }
    var errorColor: Color { get }
    var warningColor: Color { get }

    // UI Elements
    var cardBackground: Color { get }
    var borderColor: Color { get }
    
    // Advanced (V2)
    var glassEffectOpacity: Double { get } // For glassmorphism
    var chartGradientColors: [Color] { get }
    var securityWarningColor: Color { get } // For poisoning alerts
    var hasDiamondTexture: Bool { get } // New: Support for "Diamond Indentation"

    // Metrics
    var cornerRadius: CGFloat { get }

    // Typography
    var balanceFont: Font { get }
    var addressFont: Font { get }
    func font(style: Font.TextStyle) -> Font
    
    // Assets
    var iconSend: String { get }
    var iconReceive: String { get }
    var iconSwap: String { get }
    var iconSettings: String { get }
    var iconShield: String { get }
}

// MARK: - Color Constants
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
}

// MARK: - Theme Factory (Scalable)
public enum ThemeType: String, CaseIterable, Identifiable {
    case eliteDark
    case cyberPunk
    case pureWhite
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
        case .eliteDark: return "Elite Dark"
        case .cyberPunk: return "Cyberpunk (Classic)"
        case .pureWhite: return "Pure White"
        case .appleDefault: return "Default (Apple)"
        case .stealthBomber: return "Stealth Bomber"
        case .neonTokyo: return "Neon Tokyo"
        case .obsidianStealth: return "Obsidian Stealth"
        case .quantumFrost: return "Quantum Frost"
        case .bunkerGray: return "Bunker Gray"
        case .crimsonTide: return "Crimson Tide"
        case .cyberpunkNeon: return "Cyberpunk Neon"
        case .goldenEra: return "Golden Era"
        case .matrixCode: return "Matrix Code"
        }
    }
}

public class ThemeFactory {
    public static func create(type: ThemeType) -> ThemeProtocolV2 {
        switch type {
        case .eliteDark: return EliteDarkTheme()
        case .cyberPunk: return CyberPunkTheme()
        case .pureWhite: return PureWhiteTheme()
        case .appleDefault: return AppleDefaultTheme()
        case .stealthBomber: return StealthBomberTheme()
        case .neonTokyo: return NeonTokyoTheme()
        case .obsidianStealth: return ObsidianStealthTheme()
        case .quantumFrost: return QuantumFrostTheme()
        case .bunkerGray: return BunkerGrayTheme()
        case .crimsonTide: return CrimsonTideTheme()
        case .cyberpunkNeon: return CyberpunkNeonTheme()
        case .goldenEra: return GoldenEraTheme()
        case .matrixCode: return MatrixCodeTheme()
        }
    }
}

// MARK: - Theme Manager
public class ThemeManager: ObservableObject {
    @Published public var currentTheme: ThemeProtocolV2

    public init(type: ThemeType = .eliteDark) {
        self.currentTheme = ThemeFactory.create(type: type)
    }

    public func setTheme(type: ThemeType) {
        withAnimation {
            self.currentTheme = ThemeFactory.create(type: type)
        }
    }
}

// MARK: - Standard Themes

public struct EliteDarkTheme: ThemeProtocolV2 {
    public let id = "elite_dark"
    public let name = "Elite Dark"

    public let backgroundMain = KryptoColors.pitchBlack
    public let backgroundSecondary = KryptoColors.deepSpace
    public let textPrimary = KryptoColors.white
    public let textSecondary = Color.gray
    public let accentColor = KryptoColors.cyberBlue
    public let successColor = KryptoColors.neonGreen
    public let errorColor = KryptoColors.neonRed
    public let warningColor = KryptoColors.warningOrange
    public let cardBackground = KryptoColors.bunkerGray
    public let borderColor = Color.white.opacity(0.1)
    
    public let glassEffectOpacity = 0.8
    public let chartGradientColors = [KryptoColors.cyberBlue, KryptoColors.weaponizedPurple]
    public let securityWarningColor = KryptoColors.neonRed
    public let hasDiamondTexture = true

    public let cornerRadius: CGFloat = 20.0

    public let balanceFont = Font.system(size: 36, weight: .bold, design: .rounded)
    public let addressFont = Font.system(size: 14, weight: .medium, design: .monospaced)

    public func font(style: Font.TextStyle) -> Font {
        return Font.system(style, design: .default)
    }

    public let iconSend = "arrow.up.circle.fill"
    public let iconReceive = "arrow.down.circle.fill"
    public let iconSwap = "arrow.triangle.2.circlepath.circle.fill"
    public let iconSettings = "gearshape.fill"
    public let iconShield = "shield.checkerboard"
}

public struct CyberPunkTheme: ThemeProtocolV2 {
    public let id = "cyber_punk"
    public let name = "Cyberpunk"

    public let backgroundMain = Color(red: 0.1, green: 0.0, blue: 0.2)
    public let backgroundSecondary = Color(red: 0.2, green: 0.0, blue: 0.3)
    public let textPrimary = Color.yellow
    public let textSecondary = Color.cyan
    public let accentColor = Color.pink
    public let successColor = Color.green
    public let errorColor = Color.red
    public let warningColor = Color.orange
    public let cardBackground = Color.black.opacity(0.6)
    public let borderColor = Color.pink

    public let glassEffectOpacity = 0.6
    public let chartGradientColors = [Color.pink, Color.yellow]
    public let securityWarningColor = Color.red
    public let hasDiamondTexture = false

    public let cornerRadius: CGFloat = 4.0 // Sharp corners

    public let balanceFont = Font.system(size: 36, weight: .heavy, design: .monospaced)
    public let addressFont = Font.system(size: 14, weight: .regular, design: .monospaced)

    public func font(style: Font.TextStyle) -> Font {
        return Font.system(style, design: .monospaced)
    }
    
    public let iconSend = "paperplane.fill"
    public let iconReceive = "tray.and.arrow.down.fill"
    public let iconSwap = "arrow.2.squarepath"
    public let iconSettings = "wrench.and.screwdriver.fill"
    public let iconShield = "lock.fill"
}

public struct PureWhiteTheme: ThemeProtocolV2 {
    public let id = "pure_white"
    public let name = "Pure White"

    public let backgroundMain = Color.white
    public let backgroundSecondary = Color(white: 0.95)
    public let textPrimary = Color.black
    public let textSecondary = Color.gray
    public let accentColor = Color.blue
    public let successColor = Color.green
    public let errorColor = Color.red
    public let warningColor = Color.orange
    public let cardBackground = Color.white
    public let borderColor = Color(white: 0.9)

    public let glassEffectOpacity = 0.9
    public let chartGradientColors = [Color.blue, Color.purple]
    public let securityWarningColor = Color.orange
    public let hasDiamondTexture = false

    public let cornerRadius: CGFloat = 16.0

    public let balanceFont = Font.system(size: 36, weight: .medium, design: .serif)
    public let addressFont = Font.system(size: 14, weight: .regular, design: .default)

    public func font(style: Font.TextStyle) -> Font {
        return Font.system(style, design: .serif)
    }

    public let iconSend = "arrow.up"
    public let iconReceive = "arrow.down"
    public let iconSwap = "arrow.left.and.right"
    public let iconSettings = "gear"
    public let iconShield = "shield"
}

// Fallback Themes
public struct AppleDefaultTheme: ThemeProtocolV2 {
    public let id = "apple_default"
    public let name = "Default (Apple)"
    public let backgroundMain = Color.white
    public let backgroundSecondary = Color(white: 0.95)
    public let textPrimary = Color.black
    public let textSecondary = Color.gray
    public let accentColor = Color.blue
    public let successColor = Color.green
    public let errorColor = Color.red
    public let warningColor = Color.orange
    public let cardBackground = Color.white
    public let borderColor = Color(white: 0.9)
    public let glassEffectOpacity = 1.0
    public let chartGradientColors = [Color.blue, Color.blue]
    public let securityWarningColor = Color.red
    public let hasDiamondTexture = false
    public let cornerRadius: CGFloat = 10.0
    public let balanceFont = Font.system(size: 32)
    public let addressFont = Font.system(size: 12)
    public func font(style: Font.TextStyle) -> Font { .system(style) }
    public let iconSend = "arrow.up"
    public let iconReceive = "arrow.down"
    public let iconSwap = "arrow.left.and.right"
    public let iconSettings = "gear"
    public let iconShield = "shield"
}

public struct StealthBomberTheme: ThemeProtocolV2 {
    public let id = "stealth_bomber"
    public let name = "Stealth Bomber"
    public let backgroundMain = Color.black
    public let backgroundSecondary = Color.black
    public let textPrimary = Color(white: 0.8)
    public let textSecondary = Color.gray
    public let accentColor = Color.gray
    public let successColor = Color.green
    public let errorColor = Color.red
    public let warningColor = Color.orange
    public let cardBackground = Color(white: 0.1)
    public let borderColor = Color(white: 0.2)
    public let glassEffectOpacity = 1.0
    public let chartGradientColors = [Color.gray, Color.gray]
    public let securityWarningColor = Color.red
    public let hasDiamondTexture = true
    public let cornerRadius: CGFloat = 0.0
    public let balanceFont = Font.system(size: 32, design: .monospaced)
    public let addressFont = Font.system(size: 12, design: .monospaced)
    public func font(style: Font.TextStyle) -> Font { .system(style, design: .monospaced) }
    public let iconSend = "arrow.up"
    public let iconReceive = "arrow.down"
    public let iconSwap = "arrow.left.and.right"
    public let iconSettings = "gear"
    public let iconShield = "shield"
}

public struct NeonTokyoTheme: ThemeProtocolV2 {
    public let id = "neon_tokyo"
    public let name = "Neon Tokyo"
    public let backgroundMain = Color(red: 0.05, green: 0.0, blue: 0.1)
    public let backgroundSecondary = Color(red: 0.1, green: 0.0, blue: 0.2)
    public let textPrimary = Color.white
    public let textSecondary = Color.pink
    public let accentColor = Color.cyan
    public let successColor = Color.green
    public let errorColor = Color.red
    public let warningColor = Color.yellow
    public let cardBackground = Color.black.opacity(0.8)
    public let borderColor = Color.cyan
    public let glassEffectOpacity = 0.8
    public let chartGradientColors = [Color.cyan, Color.pink]
    public let securityWarningColor = Color.red
    public let hasDiamondTexture = false
    public let cornerRadius: CGFloat = 12.0
    public let balanceFont = Font.system(size: 32, design: .rounded)
    public let addressFont = Font.system(size: 12)
    public func font(style: Font.TextStyle) -> Font { .system(style, design: .rounded) }
    public let iconSend = "arrow.up"
    public let iconReceive = "arrow.down"
    public let iconSwap = "arrow.left.and.right"
    public let iconSettings = "gear"
    public let iconShield = "shield"
}

public struct ObsidianStealthTheme: ThemeProtocolV2 {
    public let id = "obsidian_stealth"
    public let name = "Obsidian Stealth"
    public let backgroundMain = Color.black
    public let backgroundSecondary = Color.black
    public let textPrimary = Color.white
    public let textSecondary = Color.gray
    public let accentColor = Color.white
    public let successColor = Color.green
    public let errorColor = Color.red
    public let warningColor = Color.orange
    public let cardBackground = Color(white: 0.05)
    public let borderColor = Color(white: 0.1)
    public let glassEffectOpacity = 1.0
    public let chartGradientColors = [Color.white, Color.gray]
    public let securityWarningColor = Color.red
    public let hasDiamondTexture = true
    public let cornerRadius: CGFloat = 8.0
    public let balanceFont = Font.system(size: 32)
    public let addressFont = Font.system(size: 12)
    public func font(style: Font.TextStyle) -> Font { .system(style) }
    public let iconSend = "arrow.up"
    public let iconReceive = "arrow.down"
    public let iconSwap = "arrow.left.and.right"
    public let iconSettings = "gear"
    public let iconShield = "shield"
}

public struct QuantumFrostTheme: ThemeProtocolV2 {
    public let id = "quantum_frost"
    public let name = "Quantum Frost"
    public let backgroundMain = Color(red: 0.9, green: 0.95, blue: 1.0)
    public let backgroundSecondary = Color.white
    public let textPrimary = Color.black
    public let textSecondary = Color.blue
    public let accentColor = Color.blue
    public let successColor = Color.green
    public let errorColor = Color.red
    public let warningColor = Color.orange
    public let cardBackground = Color.white.opacity(0.9)
    public let borderColor = Color.blue.opacity(0.3)
    public let glassEffectOpacity = 0.9
    public let chartGradientColors = [Color.blue, Color.cyan]
    public let securityWarningColor = Color.orange
    public let hasDiamondTexture = false
    public let cornerRadius: CGFloat = 16.0
    public let balanceFont = Font.system(size: 32, design: .serif)
    public let addressFont = Font.system(size: 12)
    public func font(style: Font.TextStyle) -> Font { .system(style, design: .serif) }
    public let iconSend = "arrow.up"
    public let iconReceive = "arrow.down"
    public let iconSwap = "arrow.left.and.right"
    public let iconSettings = "gear"
    public let iconShield = "shield"
}

public struct BunkerGrayTheme: ThemeProtocolV2 {
    public let id = "bunker_gray"
    public let name = "Bunker Gray"
    public let backgroundMain = Color(white: 0.2)
    public let backgroundSecondary = Color(white: 0.15)
    public let textPrimary = Color.white
    public let textSecondary = Color(white: 0.7)
    public let accentColor = Color.yellow
    public let successColor = Color.green
    public let errorColor = Color.red
    public let warningColor = Color.orange
    public let cardBackground = Color(white: 0.25)
    public let borderColor = Color(white: 0.3)
    public let glassEffectOpacity = 1.0
    public let chartGradientColors = [Color.yellow, Color.orange]
    public let securityWarningColor = Color.red
    public let hasDiamondTexture = false
    public let cornerRadius: CGFloat = 4.0
    public let balanceFont = Font.system(size: 32, design: .monospaced)
    public let addressFont = Font.system(size: 12)
    public func font(style: Font.TextStyle) -> Font { .system(style, design: .monospaced) }
    public let iconSend = "arrow.up"
    public let iconReceive = "arrow.down"
    public let iconSwap = "arrow.left.and.right"
    public let iconSettings = "gear"
    public let iconShield = "shield"
}

public struct CrimsonTideTheme: ThemeProtocolV2 {
    public let id = "crimson_tide"
    public let name = "Crimson Tide"
    public let backgroundMain = Color(red: 0.2, green: 0.0, blue: 0.0)
    public let backgroundSecondary = Color(red: 0.1, green: 0.0, blue: 0.0)
    public let textPrimary = Color.white
    public let textSecondary = Color.red
    public let accentColor = Color.red
    public let successColor = Color.green
    public let errorColor = Color.red
    public let warningColor = Color.orange
    public let cardBackground = Color(red: 0.3, green: 0.0, blue: 0.0).opacity(0.8)
    public let borderColor = Color.red
    public let glassEffectOpacity = 0.8
    public let chartGradientColors = [Color.red, Color.orange]
    public let securityWarningColor = Color.yellow
    public let hasDiamondTexture = true
    public let cornerRadius: CGFloat = 10.0
    public let balanceFont = Font.system(size: 32)
    public let addressFont = Font.system(size: 12)
    public func font(style: Font.TextStyle) -> Font { .system(style) }
    public let iconSend = "arrow.up"
    public let iconReceive = "arrow.down"
    public let iconSwap = "arrow.left.and.right"
    public let iconSettings = "gear"
    public let iconShield = "shield"
}

public struct CyberpunkNeonTheme: ThemeProtocolV2 {
    public let id = "cyberpunk_neon"
    public let name = "Cyberpunk Neon"
    public let backgroundMain = Color.black
    public let backgroundSecondary = Color(red: 0.1, green: 0.1, blue: 0.2)
    public let textPrimary = Color.cyan
    public let textSecondary = Color.pink
    public let accentColor = Color.yellow
    public let successColor = Color.green
    public let errorColor = Color.red
    public let warningColor = Color.orange
    public let cardBackground = Color.black.opacity(0.7)
    public let borderColor = Color.cyan
    public let glassEffectOpacity = 0.7
    public let chartGradientColors = [Color.cyan, Color.purple]
    public let securityWarningColor = Color.red
    public let hasDiamondTexture = false
    public let cornerRadius: CGFloat = 6.0
    public let balanceFont = Font.system(size: 32, design: .monospaced)
    public let addressFont = Font.system(size: 12)
    public func font(style: Font.TextStyle) -> Font { .system(style, design: .monospaced) }
    public let iconSend = "arrow.up"
    public let iconReceive = "arrow.down"
    public let iconSwap = "arrow.left.and.right"
    public let iconSettings = "gear"
    public let iconShield = "shield"
}

public struct GoldenEraTheme: ThemeProtocolV2 {
    public let id = "golden_era"
    public let name = "Golden Era"
    public let backgroundMain = Color(red: 0.95, green: 0.9, blue: 0.8)
    public let backgroundSecondary = Color(red: 0.9, green: 0.85, blue: 0.75)
    public let textPrimary = Color(red: 0.4, green: 0.3, blue: 0.1)
    public let textSecondary = Color(red: 0.6, green: 0.5, blue: 0.3)
    public let accentColor = Color(red: 0.8, green: 0.6, blue: 0.2)
    public let successColor = Color.green
    public let errorColor = Color.red
    public let warningColor = Color.orange
    public let cardBackground = Color.white.opacity(0.8)
    public let borderColor = Color(red: 0.8, green: 0.6, blue: 0.2)
    public let glassEffectOpacity = 0.8
    public let chartGradientColors = [Color.orange, Color.yellow]
    public let securityWarningColor = Color.red
    public let hasDiamondTexture = true
    public let cornerRadius: CGFloat = 14.0
    public let balanceFont = Font.system(size: 32, design: .serif)
    public let addressFont = Font.system(size: 12)
    public func font(style: Font.TextStyle) -> Font { .system(style, design: .serif) }
    public let iconSend = "arrow.up"
    public let iconReceive = "arrow.down"
    public let iconSwap = "arrow.left.and.right"
    public let iconSettings = "gear"
    public let iconShield = "shield"
}

public struct MatrixCodeTheme: ThemeProtocolV2 {
    public let id = "matrix_code"
    public let name = "Matrix Code"
    public let backgroundMain = Color.black
    public let backgroundSecondary = Color(red: 0.0, green: 0.1, blue: 0.0)
    public let textPrimary = Color.green
    public let textSecondary = Color(red: 0.0, green: 0.5, blue: 0.0)
    public let accentColor = Color.green
    public let successColor = Color.green
    public let errorColor = Color.red
    public let warningColor = Color.orange
    public let cardBackground = Color.black.opacity(0.9)
    public let borderColor = Color.green
    public let glassEffectOpacity = 0.9
    public let chartGradientColors = [Color.green, Color(red: 0.0, green: 0.3, blue: 0.0)]
    public let securityWarningColor = Color.red
    public let hasDiamondTexture = false
    public let cornerRadius: CGFloat = 0.0
    public let balanceFont = Font.system(size: 32, design: .monospaced)
    public let addressFont = Font.system(size: 12)
    public func font(style: Font.TextStyle) -> Font { .system(style, design: .monospaced) }
    public let iconSend = "arrow.up"
    public let iconReceive = "arrow.down"
    public let iconSwap = "arrow.left.and.right"
    public let iconSettings = "gear"
    public let iconShield = "shield"
}
