import SwiftUI

public struct StealthBomberTheme: ThemeProtocolV2 {
    public let id = "stealth_bomber"
    public let name = "Stealth Bomber"

    public var backgroundMain: Color { Color(white: 0.15) }
    public var backgroundSecondary: Color { Color(white: 0.2) }
    public var textPrimary: Color { Color(white: 0.9) }
    public var textSecondary: Color { Color(white: 0.5) }
    public var accentColor: Color { Color(white: 0.5) } // Gray Accent
    public var successColor: Color { Color(white: 0.7) }
    public var errorColor: Color { Color(white: 0.3) }
    public var warningColor: Color { Color(white: 0.6) }
    public var cardBackground: Color { Color(white: 0.18) }
    public var borderColor: Color { Color.black }

    // V2 Properties
    public var glassEffectOpacity: Double { 0.9 }
    public var chartGradientColors: [Color] { [Color.gray, Color.black] }
    public var securityWarningColor: Color { Color.red }
    public var cornerRadius: CGFloat { 2.0 } // Sharp/Stealth

    public var balanceFont: Font { .system(size: 40, weight: .bold, design: .default) }
    public var addressFont: Font { .system(.body, design: .monospaced) }

    public func font(style: Font.TextStyle) -> Font {
        .system(style, design: .default).weight(.medium)
    }

    public var iconSend: String { "airplane" }
    public var iconReceive: String { "arrow.down.square" }
    public var iconSwap: String { "arrow.triangle.2.circlepath" }
    public var iconSettings: String { "gear" }
    public var iconShield: String { "shield" }

    public init() {}
}
