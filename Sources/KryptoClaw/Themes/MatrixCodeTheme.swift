import SwiftUI

public struct MatrixCodeTheme: ThemeProtocolV2 {
    public let id = "matrix_code"
    public let name = "Matrix Code"

    public var backgroundMain: Color { Color.black }
    public var backgroundSecondary: Color { Color(red: 0.0, green: 0.1, blue: 0.0) }
    public var textPrimary: Color { Color(red: 0.0, green: 1.0, blue: 0.0) } // Matrix Green
    public var textSecondary: Color { Color(red: 0.0, green: 0.6, blue: 0.0) }
    public var accentColor: Color { Color(red: 0.0, green: 1.0, blue: 0.0) }
    public var successColor: Color { Color(red: 0.0, green: 1.0, blue: 0.0) }
    public var errorColor: Color { Color(red: 1.0, green: 0.0, blue: 0.0) }
    public var warningColor: Color { Color.yellow }
    public var cardBackground: Color { Color(red: 0.0, green: 0.05, blue: 0.0) }
    public var borderColor: Color { Color(red: 0.0, green: 0.4, blue: 0.0) }

    // V2 Properties
    public var glassEffectOpacity: Double { 0.9 }
    public var chartGradientColors: [Color] { [Color.green, Color.black] }
    public var securityWarningColor: Color { Color.red }
    public var cornerRadius: CGFloat { 0.0 } // Terminal style

    public var balanceFont: Font { .system(size: 40, weight: .regular, design: .monospaced) }
    public var addressFont: Font { .system(.body, design: .monospaced) }

    public func font(style: Font.TextStyle) -> Font {
        .system(style, design: .monospaced)
    }

    public var iconSend: String { "chevron.right.2" }
    public var iconReceive: String { "chevron.left.2" }
    public var iconSwap: String { "arrow.triangle.2.circlepath" }
    public var iconSettings: String { "terminal.fill" }
    public var iconShield: String { "lock.fill" }

    public init() {}
}
