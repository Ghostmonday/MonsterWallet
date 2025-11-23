import XCTest
@testable import KryptoClaw

final class ModelTests: XCTestCase {
    
    // MARK: - NFTMetadata Tests
    
    func testNFTMetadataCodable() throws {
        let original = NFTMetadata(
            id: "0x123:456",
            name: "Cool NFT",
            imageURL: URL(string: "https://example.com/nft.png")!,
            collectionName: "Cool Collection",
            isSpam: false
        )
        
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(NFTMetadata.self, from: data)
        
        XCTAssertEqual(original, decoded)
        XCTAssertEqual(decoded.name, "Cool NFT")
        XCTAssertFalse(decoded.isSpam)
    }
    
    // MARK: - Contact Tests
    
    func testContactCodable() throws {
        let id = UUID()
        let original = Contact(
            id: id,
            name: "Alice",
            address: "0xAliceAddress",
            note: "Friend"
        )
        
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Contact.self, from: data)
        
        XCTAssertEqual(original, decoded)
        XCTAssertEqual(decoded.id, id)
        XCTAssertEqual(decoded.note, "Friend")
    }
    
    // MARK: - WalletInfo Tests
    
    func testWalletInfoCodable() throws {
        let original = WalletInfo(
            id: "wallet_1",
            name: "Main Wallet",
            colorTheme: "#FF0000",
            isWatchOnly: false
        )
        
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(WalletInfo.self, from: data)
        
        XCTAssertEqual(original, decoded)
        XCTAssertEqual(decoded.id, "wallet_1")
        XCTAssertFalse(decoded.isWatchOnly)
    }
}
