import SwiftUI

public struct CrimsonTideTheme: ThemeProtocol {
    public let id = "crimson_tide"
    public let name = "Crimson Tide"
    
    public var backgroundMain: Color { Color.black }
    public var backgroundSecondary: Color { Color(red: 0.15, green: 0.0, blue: 0.0) } // Slightly lighter for contrast
    public var textPrimary: Color { Color.white }
    public var textSecondary: Color { Color(red: 1.0, green: 0.4, blue: 0.4) } // Lighter red for readability
    public var accentColor: Color { Color(red: 1.0, green: 0.0, blue: 0.0) } // Pure Red
    public var successColor: Color { Color(red: 0.2, green: 1.0, blue: 0.2) } // Bright Green for visibility
    public var errorColor: Color { Color(red: 1.0, green: 0.2, blue: 0.2) }
    public var warningColor: Color { Color.orange }
    public var cardBackground: Color { Color(red: 0.08, green: 0.0, blue: 0.0) }
    public var borderColor: Color { Color(red: 0.8, green: 0.0, blue: 0.0) } // Brighter border
    
    public var balanceFont: Font { .system(size: 40, weight: .bold, design: .serif) }
    public var addressFont: Font { .system(.body, design: .monospaced) }
    
    public func font(style: Font.TextStyle) -> Font {
        return .system(style, design: .serif).weight(.bold)
    }
    
    public var iconSend: String { "flame.fill" }
    public var iconReceive: String { "square.and.arrow.down.fill" }
    public var iconSettings: String { "gearshape.2.fill" }
    public var iconShield: String { "checkmark.shield.fill" }
    
    public init() {}
}
