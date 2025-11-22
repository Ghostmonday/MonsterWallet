import XCTest
import SwiftUI
@testable import KryptoClaw

final class ThemeEngineTests: XCTestCase {
    
    var themeManager: ThemeManager!
    
    override func setUp() {
        super.setUp()
        themeManager = ThemeManager()
    }
    
    func testDefaultThemeProperties() {
        let theme = themeManager.currentTheme
        XCTAssertEqual(theme.id, "default")
        XCTAssertFalse(theme.isPremium)
        XCTAssertEqual(theme.name, "Krypto Classic")
    }
    
    func testThemeSwitching() {
        struct PremiumTheme: ThemeProtocol {
            let id = "premium_gold"
            let name = "Gold Standard"
            let isPremium = true
            
            var backgroundMain: Color { .black }
            var backgroundSecondary: Color { .gray }
            var textPrimary: Color { .yellow }
            var textSecondary: Color { .white }
            var accentColor: Color { .yellow }
            var successColor: Color { .green }
            var errorColor: Color { .red }
            var warningColor: Color { .orange }
            
            func font(style: Font.TextStyle, weight: Font.Weight) -> Font { .system(style) }
            
            var iconSend: String { "arrow.up" }
            var iconReceive: String { "arrow.down" }
            var iconSettings: String { "gear" }
            var iconShield: String { "shield" }
        }
        
        let newTheme = PremiumTheme()
        themeManager.applyTheme(newTheme)
        
        XCTAssertEqual(themeManager.currentTheme.id, "premium_gold")
        XCTAssertTrue(themeManager.currentTheme.isPremium)
    }
}
