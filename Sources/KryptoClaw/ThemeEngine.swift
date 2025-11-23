import SwiftUI

public protocol ThemeProtocol {
    var id: String { get }
    var name: String { get }
    
    // Colors
    var backgroundMain: Color { get }
    var backgroundSecondary: Color { get }
    var textPrimary: Color { get }
    var textSecondary: Color { get }
    var accentColor: Color { get }
    var successColor: Color { get }
    var errorColor: Color { get }
    var warningColor: Color { get }
    var cardBackground: Color { get }
    var borderColor: Color { get }
    
    // Typography - Strict
    var balanceFont: Font { get }
    var addressFont: Font { get }
    func font(style: Font.TextStyle) -> Font // Fallback for other text
    
    // Assets
    var iconSend: String { get }
    var iconReceive: String { get }
    var iconSettings: String { get }
    var iconShield: String { get }
}

// MARK: - Color Constants
public enum KryptoColors {
    public static let pitchBlack = Color.black
    public static let weaponizedPurple = Color(red: 0.6, green: 0.0, blue: 1.0) // Sharp purple
    public static let neonRed = Color(red: 1.0, green: 0.1, blue: 0.1)
    public static let neonGreen = Color(red: 0.1, green: 1.0, blue: 0.1)
    public static let bunkerGray = Color(white: 0.1)
    public static let white = Color.white
}

// MARK: - Theme Manager

public class ThemeManager: ObservableObject {
    @Published public var currentTheme: ThemeProtocol
    
    public init(theme: ThemeProtocol = AppleDefaultTheme()) {
        self.currentTheme = theme
    }
    
    public func setTheme(_ theme: ThemeProtocol) {
        self.currentTheme = theme
    }
}
