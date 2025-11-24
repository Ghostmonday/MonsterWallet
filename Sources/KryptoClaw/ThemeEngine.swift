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
        case .obsidianStealth: EliteDarkTheme()
        case .stealthBomber: EliteDarkTheme()
        case .goldenEra: LuxuryMonogramTheme()
        case .crimsonTide: FireAshTheme()
        case .quantumFrost: WaterIceTheme()
        case .neonTokyo: CyberPunkTheme()
        case .cyberpunkNeon: CyberPunkTheme()
        case .matrixCode: CyberPunkTheme()
        case .bunkerGray: EliteDarkTheme()
        case .appleDefault: PureWhiteTheme()
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
    public let materialStyle: Material = .ultraThin
    public let showDiamondPattern = true
    public let backgroundAnimation: BackgroundAnimationType = .liquidRefraction
    public let chartGradientColors = [KryptoColors.cyberBlue, KryptoColors.weaponizedPurple]
    public let securityWarningColor = KryptoColors.neonRed

    public let cornerRadius: CGFloat = 20.0

    public let balanceFont = Font.system(size: 36, weight: .bold, design: .rounded)
    public let addressFont = Font.system(size: 14, weight: .medium, design: .monospaced)

    public func font(style: Font.TextStyle) -> Font {
        Font.system(style, design: .default)
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
    public let materialStyle: Material = .regular
    public let showDiamondPattern = false
    public let backgroundAnimation: BackgroundAnimationType = .none
    public let chartGradientColors = [Color.pink, Color.yellow]
    public let securityWarningColor = Color.red
    public let hasDiamondTexture = false

    public let cornerRadius: CGFloat = 4.0

    public let balanceFont = Font.system(size: 36, weight: .heavy, design: .monospaced)
    public let addressFont = Font.system(size: 14, weight: .regular, design: .monospaced)

    public func font(style: Font.TextStyle) -> Font {
        Font.system(style, design: .monospaced)
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
    public let materialStyle: Material = .thick
    public let showDiamondPattern = false
    public let backgroundAnimation: BackgroundAnimationType = .none
    public let chartGradientColors = [Color.blue, Color.purple]
    public let securityWarningColor = Color.orange
    public let hasDiamondTexture = false

    public let cornerRadius: CGFloat = 16.0

    public let balanceFont = Font.system(size: 36, weight: .medium, design: .serif)
    public let addressFont = Font.system(size: 14, weight: .regular, design: .default)

    public func font(style: Font.TextStyle) -> Font {
        Font.system(style, design: .serif)
    }

    public let iconSend = "arrow.up"
    public let iconReceive = "arrow.down"
    public let iconSwap = "arrow.left.and.right"
    public let iconSettings = "gear"
    public let iconShield = "shield"
}

public struct LuxuryMonogramTheme: ThemeProtocolV2 {
    public let id = "luxury_monogram"
    public let name = "Luxury Monogram"

    public let backgroundMain = KryptoColors.luxuryBrown
    public let backgroundSecondary = Color.black
    public let textPrimary = KryptoColors.luxuryGold
    public let textSecondary = Color(white: 0.8)
    public let accentColor = KryptoColors.luxuryGold
    public let successColor = Color.green
    public let errorColor = Color.red
    public let warningColor = Color.orange
    public let cardBackground = KryptoColors.luxuryBrown.opacity(0.8)
    public let borderColor = KryptoColors.luxuryGold.opacity(0.5)

    public let glassEffectOpacity = 0.9
    public let materialStyle: Material = .ultraThin
    public let showDiamondPattern = true // Reusing diamond pattern as monogram base for now
    public let backgroundAnimation: BackgroundAnimationType = .none
    public let chartGradientColors = [KryptoColors.luxuryGold, Color.white]
    public let securityWarningColor = Color.red

    public let cornerRadius: CGFloat = 12.0

    public let balanceFont = Font.system(size: 36, weight: .medium, design: .serif)
    public let addressFont = Font.system(size: 14, weight: .regular, design: .serif)

    public func font(style: Font.TextStyle) -> Font {
        Font.system(style, design: .serif)
    }

    public let iconSend = "arrow.up.circle"
    public let iconReceive = "arrow.down.circle"
    public let iconSwap = "arrow.triangle.2.circlepath.circle"
    public let iconSettings = "gearshape"
    public let iconShield = "shield"
}

public struct FireAshTheme: ThemeProtocolV2 {
    public let id = "fire_ash"
    public let name = "Fire & Ash"

    public let backgroundMain = KryptoColors.ashGray
    public let backgroundSecondary = Color.black
    public let textPrimary = KryptoColors.emberOrange
    public let textSecondary = Color(white: 0.7)
    public let accentColor = Color.red
    public let successColor = Color.green
    public let errorColor = Color.red
    public let warningColor = KryptoColors.emberOrange
    public let cardBackground = Color.black.opacity(0.7)
    public let borderColor = KryptoColors.emberOrange.opacity(0.3)

    public let glassEffectOpacity = 0.5
    public let materialStyle: Material = .thin
    public let showDiamondPattern = false
    public let backgroundAnimation: BackgroundAnimationType = .fireParticles
    public let chartGradientColors = [KryptoColors.emberOrange, Color.red]
    public let securityWarningColor = Color.red

    public let cornerRadius: CGFloat = 8.0

    public let balanceFont = Font.system(size: 36, weight: .bold, design: .default)
    public let addressFont = Font.system(size: 14, weight: .medium, design: .monospaced)

    public func font(style: Font.TextStyle) -> Font {
        Font.system(style, design: .rounded)
    }

    public let iconSend = "flame.fill"
    public let iconReceive = "arrow.down.to.line.compact"
    public let iconSwap = "arrow.triangle.swap"
    public let iconSettings = "gear"
    public let iconShield = "shield.fill"
}

public struct WaterIceTheme: ThemeProtocolV2 {
    public let id = "water_ice"
    public let name = "Water & Ice"

    public let backgroundMain = KryptoColors.deepOcean
    public let backgroundSecondary = KryptoColors.icyBlue.opacity(0.1)
    public let textPrimary = KryptoColors.icyBlue
    public let textSecondary = Color.white.opacity(0.7)
    public let accentColor = Color.blue
    public let successColor = Color.cyan
    public let errorColor = Color.purple
    public let warningColor = Color.yellow
    public let cardBackground = KryptoColors.deepOcean.opacity(0.6)
    public let borderColor = KryptoColors.icyBlue.opacity(0.3)

    public let glassEffectOpacity = 0.7
    public let materialStyle: Material = .ultraThin
    public let showDiamondPattern = false
    public let backgroundAnimation: BackgroundAnimationType = .waterWave
    public let chartGradientColors = [KryptoColors.icyBlue, Color.blue]
    public let securityWarningColor = Color.purple

    public let cornerRadius: CGFloat = 24.0

    public let balanceFont = Font.system(size: 36, weight: .light, design: .rounded)
    public let addressFont = Font.system(size: 14, weight: .light, design: .default)

    public func font(style: Font.TextStyle) -> Font {
        Font.system(style, design: .default)
    }

    public let iconSend = "drop.fill"
    public let iconReceive = "cloud.rain.fill"
    public let iconSwap = "arrow.triangle.2.circlepath"
    public let iconSettings = "gearshape"
    public let iconShield = "lock.shield"
}
