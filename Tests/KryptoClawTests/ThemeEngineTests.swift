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
        XCTAssertEqual(theme.id, "elite_dark")
        // XCTAssertFalse(theme.isPremium) // Removed as not in protocol
        XCTAssertEqual(theme.name, "Elite Dark")
    }
    
    func testThemeSwitching() {
        // Test switching to a different theme
        themeManager.setTheme(type: .crimsonTide)
        
        XCTAssertEqual(themeManager.currentTheme.id, "crimson_tide")
        XCTAssertEqual(themeManager.currentTheme.name, "Crimson Tide")
    }
}
