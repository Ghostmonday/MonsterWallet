import SwiftUI

struct NFTGalleryView: View {
    @EnvironmentObject var wsm: WalletStateManager
    @EnvironmentObject var themeManager: ThemeManager

    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
    ]

    var body: some View {
        let theme = themeManager.currentTheme
        
        VStack {
            if wsm.nfts.isEmpty {
                KryptoEmptyState(
                    icon: "photo.on.rectangle.angled",
                    title: "No NFTs",
                    message: "Your NFT collection will appear here"
                )
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: theme.spacingL) {
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
        let theme = themeManager.currentTheme
        
        VStack(alignment: .leading, spacing: 0) {
            AsyncImage(url: nft.imageURL) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else if phase.error != nil {
                    theme.backgroundSecondary.opacity(0.5)
                        .overlay(
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(theme.textSecondary)
                        )
                } else {
                    theme.backgroundSecondary.opacity(0.5)
                        .overlay(ProgressView())
                }
            }
            .frame(height: 150)
            .clipped()

            VStack(alignment: .leading, spacing: theme.spacingXS) {
                Text(nft.collectionName)
                    .font(theme.font(style: .caption))
                    .foregroundColor(theme.textSecondary)
                    .lineLimit(1)

                Text(nft.name)
                    .font(theme.font(style: .headline))
                    .foregroundColor(theme.textPrimary)
                    .lineLimit(1)
            }
            .padding(theme.spacingM)
        }
        .background(theme.cardBackground)
        .cornerRadius(theme.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .stroke(theme.borderColor, lineWidth: 1)
        )
    }
}
