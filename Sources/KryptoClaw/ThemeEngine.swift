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
    public let name = "Krypto Classic"
    
    // Methods
    func font(style: Font.TextStyle, weight: Font.Weight) -> Font
}

// MARK: - Concrete Themes

public struct ElectricCrayonTheme: ThemeProtocol {
    public var backgroundMain: Color = KryptoColors.paperWhite
    public var textPrimary: Color = KryptoColors.inkBlack
    public var textSecondary: Color = KryptoColors.inkBlack.opacity(0.6)
    public var accentColor: Color = KryptoColors.electricPurple
    public var cardBackground: Color = .white
    public var borderColor: Color = KryptoColors.inkBlack
    
    public var iconSend: String = "paperplane.fill"
    public var iconReceive: String = "arrow.down.circle.fill"
    public var iconSettings: String = "gearshape.fill"
    
    public func font(style: Font.TextStyle, weight: Font.Weight) -> Font {
        switch style {
        case .largeTitle, .title, .title2, .title3:
            return .system(style, design: .rounded).weight(weight)
        case .headline, .subheadline:
            return .system(style, design: .rounded).weight(weight)
        default:
            return .system(style, design: .default).weight(weight)
        }
    }
}

public struct DarkModeTheme: ThemeProtocol {
    public var backgroundMain: Color = KryptoColors.inkBlack
    public var textPrimary: Color = .white
    public var textSecondary: Color = .white.opacity(0.7)
    public var accentColor: Color = KryptoColors.electricPurple
    public var cardBackground: Color = Color(white: 0.1)
    public var borderColor: Color = .white.opacity(0.2)
    
    public var iconSend: String = "paperplane.fill"
    public var iconReceive: String = "arrow.down.circle.fill"
    public var iconSettings: String = "gearshape.fill"
    
    public func font(style: Font.TextStyle, weight: Font.Weight) -> Font {
        switch style {
        case .largeTitle, .title, .title2, .title3:
            return .system(style, design: .rounded).weight(weight)
        case .headline, .subheadline:
            return .system(style, design: .rounded).weight(weight)
        default:
            return .system(style, design: .default).weight(weight)
        }
    }
}

// MARK: - Theme Manager

public class ThemeManager: ObservableObject {
        self.currentTheme = theme
    }
}
