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
        XCTAssertEqual(theme.id, "apple_default")
        // XCTAssertFalse(theme.isPremium) // Removed as not in protocol
        XCTAssertEqual(theme.name, "Default")
    }
    
    func testThemeSwitching() {
        struct PremiumTheme: ThemeProtocol {
            let id = "premium_gold"
            let name = "Gold Standard"
            // let isPremium = true // Removed
            
            var backgroundMain: Color { .black }
            var backgroundSecondary: Color { .gray }
            var textPrimary: Color { .yellow }
            var textSecondary: Color { .white }
            var accentColor: Color { .yellow }
            var successColor: Color { .green }
            var errorColor: Color { .red }
            var warningColor: Color { .orange }
            var cardBackground: Color { .gray }
            var borderColor: Color { .yellow }
            
            var balanceFont: Font { .system(.title) }
            var addressFont: Font { .system(.body) }
            
            func font(style: Font.TextStyle) -> Font { .system(style) }
            
            var iconSend: String { "arrow.up" }
            var iconReceive: String { "arrow.down" }
            var iconSettings: String { "gear" }
            var iconShield: String { "shield" }
        }
        
        let newTheme = PremiumTheme()
        themeManager.setTheme(newTheme)
        
        XCTAssertEqual(themeManager.currentTheme.id, "premium_gold")
        // XCTAssertTrue(themeManager.currentTheme.isPremium) // Removed
    }
}
