import Foundation

public struct Contact: Codable, Equatable, Identifiable {
    public let id: UUID
    public let name: String
    public let address: String
    public let note: String?

    public init(id: UUID = UUID(), name: String, address: String, note: String? = nil) {
        self.id = id
        self.name = name
        self.address = address
        self.note = note
    }

    public func validate() throws {
        guard !name.isEmpty else {
            throw ValidationError.invalidName("Name cannot be empty")
        }

        guard name.count <= 50 else {
            throw ValidationError.invalidName("Name too long (max 50 chars)")
        }

        if name.unicodeScalars.contains(where: \.properties.isEmojiPresentation) {
            throw ValidationError.invalidName("Name contains emojis")
        }

        let addressRegex = "^0x[a-fA-F0-9]{40}$"
        guard address.range(of: addressRegex, options: .regularExpression) != nil else {
            throw ValidationError.invalidAddress
        }
    }

    public enum ValidationError: Error {
        case invalidName(String)
        case invalidAddress
    }
}
