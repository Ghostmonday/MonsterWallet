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

    public var id: String { rawValue }

    public var name: String {
        switch self {
        case .eliteDark: return "Elite Dark"
        case .cyberPunk: return "Cyberpunk"
        case .pureWhite: return "Pure White"
        }
    }
}

public class ThemeFactory {
    public static func create(type: ThemeType) -> ThemeProtocolV2 {
        switch type {
        case .eliteDark: return EliteDarkTheme()
        case .cyberPunk: return CyberPunkTheme()
        case .pureWhite: return PureWhiteTheme()
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
