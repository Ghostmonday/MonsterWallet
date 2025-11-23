import SwiftUI

public struct NeonTokyoTheme: ThemeProtocolV2 {
    public let id = "neon_tokyo"
    public let name = "Neon Tokyo"
    
    public var backgroundMain: Color { Color(red: 0.1, green: 0.0, blue: 0.2) } // Deep Purple
    public var backgroundSecondary: Color { Color(red: 0.2, green: 0.0, blue: 0.3) }
    public var textPrimary: Color { Color.white }
    public var textSecondary: Color { Color(red: 1.0, green: 0.0, blue: 1.0) } // Magenta
    public var accentColor: Color { Color(red: 0.0, green: 1.0, blue: 1.0) } // Cyan
    public var successColor: Color { Color.green }
    public var errorColor: Color { Color(red: 1.0, green: 0.0, blue: 0.5) } // Hot Pink
    public var warningColor: Color { Color.yellow }
    public var cardBackground: Color { Color(red: 0.15, green: 0.05, blue: 0.25) }
    public var borderColor: Color { Color(red: 0.0, green: 1.0, blue: 1.0) }
    
    // V2 Properties
    public var glassEffectOpacity: Double { 0.8 }
    public var chartGradientColors: [Color] { [Color.purple, Color.cyan] }
    public var securityWarningColor: Color { Color.red }
    public var cornerRadius: CGFloat { 16.0 }
    
    public var balanceFont: Font { .system(size: 40, weight: .black, design: .rounded) }
    public var addressFont: Font { .system(.body, design: .monospaced) }
    
    public func font(style: Font.TextStyle) -> Font {
        return .system(style, design: .rounded).weight(.bold)
    }
    
    public var iconSend: String { "bolt.fill" }
    public var iconReceive: String { "arrow.down.circle.fill" }
    public var iconSwap: String { "arrow.triangle.2.circlepath" }
    public var iconSettings: String { "gearshape.fill" }
    public var iconShield: String { "shield.fill" }
    
    public init() {}
}
