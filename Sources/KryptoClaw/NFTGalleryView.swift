import SwiftUI

struct NFTGalleryView: View {
    @EnvironmentObject var wsm: WalletStateManager
    @EnvironmentObject var themeManager: ThemeManager

    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
    ]

    var body: some View {
        VStack {
            if wsm.nfts.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 48))
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                    Text("No NFTs found")
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(wsm.nfts) { nft in
                            NFTCard(nft: nft)
                                .onTapGesture {
                                    KryptoLogger.shared.log(level: .info, category: .boundary, message: "NFT Tapped", metadata: ["nftId": nft.id, "view": "NFTGallery"])
                                }
                        }
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            KryptoLogger.shared.log(level: .info, category: .lifecycle, message: "ViewDidAppear", metadata: ["view": "NFTGallery"])
        }
    }
}

struct NFTCard: View {
    let nft: NFTMetadata
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            AsyncImage(url: nft.imageURL) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else if phase.error != nil {
                    Color.gray.opacity(0.3)
                        .overlay(Image(systemName: "exclamationmark.triangle").foregroundColor(.white))
                } else {
                    Color.gray.opacity(0.3)
                        .overlay(ProgressView())
                }
            }
            .frame(height: 150)
            .clipped()

            VStack(alignment: .leading, spacing: 4) {
                Text(nft.collectionName)
                    .font(themeManager.currentTheme.font(style: .caption))
                    .foregroundColor(themeManager.currentTheme.textSecondary)
                    .lineLimit(1)

                Text(nft.name)
                    .font(themeManager.currentTheme.font(style: .headline))
                    .foregroundColor(themeManager.currentTheme.textPrimary)
                    .lineLimit(1)
            }
            .padding(12)
        }
        .background(themeManager.currentTheme.cardBackground)
        .cornerRadius(2)
        .overlay(
            RoundedRectangle(cornerRadius: 2)
                .stroke(themeManager.currentTheme.borderColor, lineWidth: 1)
        )
    }
}
