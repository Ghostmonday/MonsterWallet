import Foundation

public class HTTPNFTProvider: NFTProviderProtocol {
    private let session: URLSession
    private let apiKey: String?

    public init(session: URLSession = .shared, apiKey: String? = nil) {
        self.session = session
        self.apiKey = apiKey
    }

    public func fetchNFTs(address: String) async throws -> [NFTMetadata] {
        guard let key = apiKey, !key.isEmpty else {
            KryptoLogger.shared.log(level: .info, category: .protocolCall, message: "No API Key provided. Returning empty list.", metadata: ["module": "HTTPNFTProvider"])
            return []
        }

        let urlString = "https://api.opensea.io/api/v2/chain/ethereum/account/\(address)/nfts"
        guard let url = URL(string: urlString) else {
            throw NFTError.invalidContract
        }

        var request = URLRequest(url: url)
        request.setValue(key, forHTTPHeaderField: "X-API-KEY")
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
