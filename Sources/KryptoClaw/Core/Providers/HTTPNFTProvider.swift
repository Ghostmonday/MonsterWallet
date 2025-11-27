import Foundation

public class HTTPNFTProvider: NFTProviderProtocol {
    private let session: URLSession
    private let apiKey: String?

    public init(session: URLSession = .shared, apiKey: String? = nil) {
        self.session = session
        self.apiKey = apiKey
    }

    public func fetchNFTs(address: String) async throws -> [NFTMetadata] {
        // Check for OpenSea API key
        let key = apiKey ?? AppConfig.openSeaAPIKey
        
        guard let apiKey = key, !apiKey.isEmpty else {
            KryptoLogger.shared.log(level: .info, category: .protocolCall, message: "No OpenSea API Key. Returning sample NFTs.", metadata: ["module": "HTTPNFTProvider"])
            // Return sample NFTs for demo
            return [
                NFTMetadata(
                    id: "1",
                    name: "CryptoPunk #3100",
                    imageURL: URL(string: "https://i.seadn.io/gae/ZWEV7BBCssLj4I2XD9zlPjbPTMcmR6gM9dSl96WqFHS02tBn-Uy9VgnvmUl0Zd8E_t4HVQGYIaJg6X5j6K9wJPZMVdXTYBwXpZ8X?w=500")!,
                    collectionName: "CryptoPunks"
                ),
                NFTMetadata(
                    id: "2",
                    name: "Bored Ape #8817",
                    imageURL: URL(string: "https://i.seadn.io/gae/C-7myYp8ITrj4FGYs_6j5hYj7K56bNblzO_x1GJqJ3K7lTOdBTVjVXZy3fqPxAVcT6zV9Q?w=500")!,
                    collectionName: "Bored Ape Yacht Club"
                ),
                NFTMetadata(
                    id: "3", 
                    name: "Azuki #9605",
                    imageURL: URL(string: "https://i.seadn.io/gcs/files/cd81aa5fb0cd22e8f9fe8a8cf5c4d4c3.png?w=500")!,
                    collectionName: "Azuki"
                )
            ]
        }

        let urlString = "https://api.opensea.io/api/v2/chain/ethereum/account/\(address)/nfts"
        guard let url = URL(string: urlString) else {
            throw NFTError.invalidContract
        }

        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "X-API-KEY")
        request.setValue("application/json", forHTTPHeaderField: "accept")
        request.timeoutInterval = 30.0

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, (200 ... 299).contains(httpResponse.statusCode) else {
            throw NFTError.fetchFailed(NSError(domain: "HTTP", code: (response as? HTTPURLResponse)?.statusCode ?? 500))
        }

        struct OpenSeaResponse: Decodable {
            struct NFT: Decodable {
                let identifier: String
                let collection: String
                let name: String?
                let image_url: String?
            }

            let nfts: [NFT]
        }

        // TODO: Verify exact OpenSea API response structure and update decoding if needed
        do {
            let result = try JSONDecoder().decode(OpenSeaResponse.self, from: data)
            return result.nfts.map { nft in
                NFTMetadata(
                    id: nft.identifier,
                    name: nft.name ?? "Unknown NFT",
                    imageURL: URL(string: nft.image_url ?? "") ?? URL(string: "https://via.placeholder.com/150")!,
                    collectionName: nft.collection
                )
            }
        } catch {
            KryptoLogger.shared.logError(module: "HTTPNFTProvider", error: error)
            throw NFTError.fetchFailed(error)
        }
    }
}
