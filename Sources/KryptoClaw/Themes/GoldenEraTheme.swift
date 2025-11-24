import SwiftUI

public struct GoldenEraTheme: ThemeProtocolV2 {
    public let id = "golden_era"
    public let name = "Golden Era"

    public var backgroundMain: Color { Color.black }
    public var backgroundSecondary: Color { Color(white: 0.1) }
    public var textPrimary: Color { Color(red: 0.9, green: 0.8, blue: 0.6) } // Gold
    public var textSecondary: Color { Color(white: 0.5) }
    public var accentColor: Color { Color(red: 1.0, green: 0.84, blue: 0.0) } // Gold
    public var successColor: Color { Color.green }
    public var errorColor: Color { Color.red }
    public var warningColor: Color { Color.orange }
    public var cardBackground: Color { Color(white: 0.08) }
    public var borderColor: Color { Color(red: 0.6, green: 0.5, blue: 0.2) } // Dark Gold

    // V2 Properties
    public var glassEffectOpacity: Double { 0.8 }
    public var chartGradientColors: [Color] { [Color.yellow, Color.orange] }
    public var securityWarningColor: Color { Color.red }
    public var cornerRadius: CGFloat { 12.0 }

    public var balanceFont: Font { .system(size: 40, weight: .bold, design: .serif) }
    public var addressFont: Font { .system(.body, design: .monospaced) }

    public func font(style: Font.TextStyle) -> Font {
        .system(style, design: .serif)
    }

    public var iconSend: String { "arrow.up.right.circle.fill" }
    public var iconReceive: String { "arrow.down.left.circle.fill" }
    public var iconSwap: String { "arrow.triangle.2.circlepath" }
    public var iconSettings: String { "gear" }
    public var iconShield: String { "shield.checkerboard" }

    public init() {}
}
