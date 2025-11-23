import XCTest
@testable import KryptoClaw

final class ModelsTests: XCTestCase {
    
    // MARK: - Contact Tests
    
    func testContactCodableRoundtrip() throws {
        let contact = Contact(name: "Alice", address: "0x123", note: "Friend")
        let data = try JSONEncoder().encode(contact)
        let decoded = try JSONDecoder().decode(Contact.self, from: data)
        
        XCTAssertEqual(contact, decoded)
        XCTAssertEqual(decoded.name, "Alice")
    }
    
    func testContactValidation() {
        let validAddress = "0x742d35Cc6634C0532925a3b844Bc454e4438f44e"
        let validContact = Contact(name: "Bob Smith", address: validAddress)
        XCTAssertNoThrow(try validContact.validate())
        
        let invalidNameContact = Contact(name: "Bob 🚀", address: validAddress)
        XCTAssertThrowsError(try invalidNameContact.validate())
        
        let longNameContact = Contact(name: String(repeating: "A", count: 51), address: validAddress)
        XCTAssertThrowsError(try longNameContact.validate())
    }
    
    // MARK: - WalletInfo Tests
    
    func testWalletInfoCodableRoundtrip() throws {
        let wallet = WalletInfo(id: "w1", name: "Main Vault", colorTheme: "blue", isWatchOnly: false)
        let data = try JSONEncoder().encode(wallet)
        let decoded = try JSONDecoder().decode(WalletInfo.self, from: data)
        
        XCTAssertEqual(wallet, decoded)
        XCTAssertFalse(decoded.isWatchOnly)
    }
    
    // MARK: - NFTMetadata Tests
    
    func testNFTMetadataCodableRoundtrip() throws {
        let url = URL(string: "https://example.com/image.png")!
        let nft = NFTMetadata(id: "0xABC:1", name: "Cool Cat #1", imageURL: url, collectionName: "Cool Cats", isSpam: false)
        
        let data = try JSONEncoder().encode(nft)
        let decoded = try JSONDecoder().decode(NFTMetadata.self, from: data)
        
        XCTAssertEqual(nft, decoded)
        XCTAssertEqual(decoded.collectionName, "Cool Cats")
    }
}

