import SwiftUI

public struct AppleDefaultTheme: ThemeProtocolV2 {
    public let id = "apple_default"
    public let name = "Default"
    
    // System Colors adapt to Light/Dark mode automatically in standard SwiftUI,
    // but here we enforce a "Light Mode" Apple look for the default to contrast with the dark premium themes.
    // Or we can use system colors if we want it to be truly native.
    // Let's go with a clean, high-quality "Apple Light" aesthetic as the base.
    
    public var backgroundMain: Color { Color(red: 0.95, green: 0.95, blue: 0.97) } // System Grouped Background
    public var backgroundSecondary: Color { Color.white }
    public var textPrimary: Color { Color.black }
    public var textSecondary: Color { Color.gray }
    public var accentColor: Color { Color.blue } // System Blue
    public var successColor: Color { Color.green }
    public var errorColor: Color { Color.red }
    public var warningColor: Color { Color.orange }
    public var cardBackground: Color { Color.white }
    public var borderColor: Color { Color(white: 0.9) } // Subtle separator
    
    // V2 Properties
    public var glassEffectOpacity: Double { 0.95 }
    public var chartGradientColors: [Color] { [Color.blue, Color.cyan] }
    public var securityWarningColor: Color { Color.orange }
    public var cornerRadius: CGFloat { 12.0 }
    
    public var balanceFont: Font { .system(size: 40, weight: .bold, design: .default) }
    public var addressFont: Font { .system(.body, design: .monospaced) }
    
    public func font(style: Font.TextStyle) -> Font {
        return .system(style, design: .default)
    }
    
    public var iconSend: String { "arrow.up.circle.fill" }
    public var iconReceive: String { "arrow.down.circle.fill" }
    public var iconSwap: String { "arrow.triangle.2.circlepath" }
    public var iconSettings: String { "gear" }
    public var iconShield: String { "shield.fill" }
    
    public init() {}
}
