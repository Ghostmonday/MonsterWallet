import SwiftUI

public struct ObsidianStealthTheme: ThemeProtocolV2 {
    public let id = "obsidian_stealth"
    public let name = "Obsidian Stealth"

    public var backgroundMain: Color { KryptoColors.pitchBlack }
    public var backgroundSecondary: Color { KryptoColors.bunkerGray }
    public var textPrimary: Color { KryptoColors.white }
    public var textSecondary: Color { Color(white: 0.6) }
    public var accentColor: Color { KryptoColors.weaponizedPurple }
    public var successColor: Color { KryptoColors.neonGreen }
    public var errorColor: Color { KryptoColors.neonRed }
    public var warningColor: Color { Color.yellow }
    public var cardBackground: Color { Color(white: 0.05) }
    public var borderColor: Color { Color(white: 0.15) }

    // V2 Properties
    public var glassEffectOpacity: Double { 0.95 }
    public var chartGradientColors: [Color] { [KryptoColors.weaponizedPurple, Color.black] }
    public var securityWarningColor: Color { KryptoColors.neonRed }
    public var cornerRadius: CGFloat { 8.0 }

    public var balanceFont: Font { .system(size: 40, weight: .bold, design: .default) }
    public var addressFont: Font { .system(.body, design: .monospaced) }

    public func font(style: Font.TextStyle) -> Font {
        switch style {
        case .largeTitle, .title, .title2, .title3:
            .system(style, design: .default).weight(.bold)
        case .headline, .subheadline:
            .system(style, design: .default).weight(.semibold)
        default:
            .system(style, design: .default)
        }
    }

    public var iconSend: String { "arrow.up.forward" }
    public var iconReceive: String { "arrow.down.left" }
    public var iconSwap: String { "arrow.triangle.2.circlepath" }
    public var iconSettings: String { "gearshape.fill" }
    public var iconShield: String { "shield.fill" }

    public init() {}
}
