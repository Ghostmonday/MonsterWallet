import SwiftUI

public struct ObsidianStealthTheme: ThemeProtocol {
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
    
    public var balanceFont: Font { .system(size: 40, weight: .bold, design: .default) }
    public var addressFont: Font { .system(.body, design: .monospaced) }
    
    public func font(style: Font.TextStyle) -> Font {
        switch style {
        case .largeTitle, .title, .title2, .title3:
            return .system(style, design: .default).weight(.bold)
        case .headline, .subheadline:
            return .system(style, design: .default).weight(.semibold)
        default:
            return .system(style, design: .default)
        }
    }
    
    public var iconSend: String { "arrow.up.forward" }
    public var iconReceive: String { "arrow.down.left" }
    public var iconSettings: String { "gearshape.fill" }
    public var iconShield: String { "shield.fill" }
    
    public init() {}
}
