import Foundation

public struct Contact: Codable, Equatable, Identifiable {
    public let id: UUID
    public let name: String        // Validation: No emojis, max 50 chars
    public let address: String     // Validation: Must pass BlockchainProvider validation
    public let note: String?
    
    public init(id: UUID = UUID(), name: String, address: String, note: String? = nil) {
        self.id = id
        self.name = name
        self.address = address
        self.note = note
    }
}
