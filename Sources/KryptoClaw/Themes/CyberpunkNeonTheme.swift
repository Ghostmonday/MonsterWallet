import SwiftUI

public struct CyberpunkNeonTheme: ThemeProtocol {
    public let id = "cyberpunk_neon"
    public let name = "Cyberpunk Neon"
    
    public var backgroundMain: Color { Color(red: 0.02, green: 0.02, blue: 0.05) } // Darker void
    public var backgroundSecondary: Color { Color(red: 0.05, green: 0.05, blue: 0.1) }
    public var textPrimary: Color { Color(red: 0.0, green: 0.9, blue: 0.9) } // Electric Cyan
    public var textSecondary: Color { Color(red: 1.0, green: 0.0, blue: 0.8) } // Hot Pink
    public var accentColor: Color { Color(red: 1.0, green: 0.9, blue: 0.0) } // Acid Yellow
    public var successColor: Color { Color(red: 0.0, green: 1.0, blue: 0.0) } // Neon Green
    public var errorColor: Color { Color(red: 1.0, green: 0.0, blue: 0.2) } // Neon Red
    public var warningColor: Color { Color.orange }
    public var cardBackground: Color { Color(red: 0.03, green: 0.03, blue: 0.08) }
    public var borderColor: Color { Color(red: 0.0, green: 0.8, blue: 0.8).opacity(0.8) } // Sharp Cyan Border
    
    public var balanceFont: Font { .system(size: 40, weight: .black, design: .monospaced) }
    public var addressFont: Font { .system(.body, design: .monospaced) }
    
    public func font(style: Font.TextStyle) -> Font {
        return .system(style, design: .monospaced).weight(.bold)
    }
    
    public var iconSend: String { "bolt.horizontal.fill" }
    public var iconReceive: String { "arrow.down.to.line.compact" }
    public var iconSettings: String { "gearshape.2.fill" }
    public var iconShield: String { "lock.square.fill" }
    
    public init() {}
}
