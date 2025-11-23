import SwiftUI

public struct BunkerGrayTheme: ThemeProtocol {
    public let id = "bunker_gray"
    public let name = "Bunker Gray"
    
    public var backgroundMain: Color { Color(white: 0.12) }
    public var backgroundSecondary: Color { Color(white: 0.18) }
    public var textPrimary: Color { Color(white: 0.95) }
    public var textSecondary: Color { Color(white: 0.6) }
    public var accentColor: Color { Color(white: 0.85) } // Concrete White
    public var successColor: Color { Color(red: 0.4, green: 0.6, blue: 0.4) } // Muted Green
    public var errorColor: Color { Color(red: 0.6, green: 0.3, blue: 0.3) } // Muted Red
    public var warningColor: Color { Color(white: 0.7) }
    public var cardBackground: Color { Color(white: 0.15) }
    public var borderColor: Color { Color(white: 0.3) } // Stronger border definition
    
    public var balanceFont: Font { .system(size: 40, weight: .heavy, design: .default) }
    public var addressFont: Font { .system(.body, design: .monospaced) }
    
    public func font(style: Font.TextStyle) -> Font {
        return .system(style, design: .default).weight(.semibold)
    }
    
    public var iconSend: String { "arrow.up.circle" }
    public var iconReceive: String { "arrow.down.circle" }
    public var iconSettings: String { "gearshape" }
    public var iconShield: String { "shield.lefthalf.filled" }
    
    public init() {}
}
