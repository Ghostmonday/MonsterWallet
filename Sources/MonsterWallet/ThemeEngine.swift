import SwiftUI

public protocol ThemeProtocol {
    var id: String { get }
    var name: String { get }
    var isPremium: Bool { get }
    
    // Colors
    var backgroundMain: Color { get }
    var backgroundSecondary: Color { get }
    var textPrimary: Color { get }
    var textSecondary: Color { get }
    var accentColor: Color { get }
    var successColor: Color { get }
    var errorColor: Color { get }
    var warningColor: Color { get }
    
    // Typography (Scalable)
    func font(style: Font.TextStyle, weight: Font.Weight) -> Font
    
    // Assets (System Names for SF Symbols)
    var iconSend: String { get }
    var iconReceive: String { get }
    var iconSettings: String { get }
    var iconShield: String { get }
}

public struct DefaultTheme: ThemeProtocol {
    public let id = "default"
    public let name = "Monster Classic"
    public let isPremium = false
    
    public init() {}
    
    public var backgroundMain: Color { Color(red: 0.1, green: 0.1, blue: 0.12) } // Dark Neutral
    public var backgroundSecondary: Color { Color(red: 0.15, green: 0.15, blue: 0.18) }
    public var textPrimary: Color { Color.white }
    public var textSecondary: Color { Color.gray }
    public var accentColor: Color { Color.blue } // Neutral Blue
    public var successColor: Color { Color.green }
    public var errorColor: Color { Color.red }
    public var warningColor: Color { Color.orange }
    
    public func font(style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        return Font.system(style).weight(weight)
    }
    
    public var iconSend: String { "arrow.up.circle.fill" }
    public var iconReceive: String { "arrow.down.circle.fill" }
    public var iconSettings: String { "gearshape.fill" }
    public var iconShield: String { "shield.fill" }
}

public class ThemeManager: ObservableObject {
    @Published public var currentTheme: any ThemeProtocol
    
    public init(initialTheme: any ThemeProtocol = DefaultTheme()) {
        self.currentTheme = initialTheme
    }
    
    public func applyTheme(_ theme: any ThemeProtocol) {
        // In V1.0, we just switch the state. 
        // In a real app with monetization, we would check `if theme.isPremium && !userHasPurchased { return }`
        self.currentTheme = theme
    }
}
