import Foundation

public struct NFTMetadata: Codable, Equatable, Identifiable {
    public let id: String // "0xContract:TokenID"
    public let name: String // Validation: No nil, default "Unknown"
    public let imageURL: URL
    public let collectionName: String
    public let isSpam: Bool // Default false

    public init(id: String, name: String, imageURL: URL, collectionName: String, isSpam: Bool = false) {
        self.id = id
        self.name = name
        self.imageURL = imageURL
        self.collectionName = collectionName
        self.isSpam = isSpam
    }
}
