import Foundation

public struct WalletInfo: Codable, Identifiable, Equatable {
    public let id: String          // KeyStore ID
    public let name: String
    public let colorTheme: String  // Hex or Theme ID
    public let isWatchOnly: Bool
    
    public init(id: String, name: String, colorTheme: String, isWatchOnly: Bool = false) {
        self.id = id
        self.name = name
        self.colorTheme = colorTheme
        self.isWatchOnly = isWatchOnly
    }
}
