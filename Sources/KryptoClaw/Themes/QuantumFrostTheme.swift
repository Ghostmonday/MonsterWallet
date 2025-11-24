import SwiftUI

public struct QuantumFrostTheme: ThemeProtocolV2 {
    public let id = "quantum_frost"
    public let name = "Quantum Frost"

    public var backgroundMain: Color { Color(red: 0.05, green: 0.1, blue: 0.15) } // Deep Ice Blue
    public var backgroundSecondary: Color { Color(red: 0.1, green: 0.15, blue: 0.2) }
    public var textPrimary: Color { Color.white }
    public var textSecondary: Color { Color(red: 0.6, green: 0.8, blue: 0.9) } // Icy Cyan
    public var accentColor: Color { Color(red: 0.0, green: 0.8, blue: 1.0) } // Cyan
    public var successColor: Color { Color(red: 0.0, green: 1.0, blue: 0.8) }
    public var errorColor: Color { Color(red: 1.0, green: 0.2, blue: 0.4) }
    public var warningColor: Color { Color.yellow }
    public var cardBackground: Color { Color(red: 0.08, green: 0.12, blue: 0.18) }
    public var borderColor: Color { Color(red: 0.2, green: 0.4, blue: 0.5) }

    // V2 Properties
    public var glassEffectOpacity: Double { 0.7 }
    public var chartGradientColors: [Color] { [Color.cyan, Color.blue] }
    public var securityWarningColor: Color { Color.red }
    public var cornerRadius: CGFloat { 20.0 }

    public var balanceFont: Font { .system(size: 40, weight: .light, design: .default) }
    public var addressFont: Font { .system(.body, design: .monospaced) }

    public func font(style: Font.TextStyle) -> Font {
        .system(style, design: .default)
    }

    public var iconSend: String { "paperplane.fill" }
    public var iconReceive: String { "tray.and.arrow.down.fill" }
    public var iconSwap: String { "arrow.triangle.2.circlepath" }
    public var iconSettings: String { "gearshape" }
    public var iconShield: String { "snowflake" }

    public init() {}
}
