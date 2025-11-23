import Foundation

public enum NFTError: Error {
    case invalidContract
    case fetchFailed(Error)
    case timeout
}

public protocol NFTProviderProtocol {
    func fetchNFTs(address: String) async throws -> [NFTMetadata]
}

// MARK: - Mock Implementation for Previews/Testing
public class MockNFTProvider: NFTProviderProtocol {
    public init() {}
    
    public func fetchNFTs(address: String) async throws -> [NFTMetadata] {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
        
        return [
            NFTMetadata(id: "0x1:1", name: "CryptoPunk #1", imageURL: URL(string: "https://example.com/punk1.png")!, collectionName: "CryptoPunks"),
            NFTMetadata(id: "0x1:2", name: "Bored Ape #100", imageURL: URL(string: "https://example.com/bayc100.png")!, collectionName: "Bored Ape Yacht Club"),
            NFTMetadata(id: "0x1:3", name: "Spam Token", imageURL: URL(string: "https://example.com/spam.png")!, collectionName: "Free Money", isSpam: true)
        ]
    }
}
