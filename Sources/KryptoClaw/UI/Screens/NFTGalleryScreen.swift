// KRYPTOCLAW NFT GALLERY
// Your digital collection. Beautifully presented.
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

import SwiftUI

public struct NFTGalleryScreen: View {
    @EnvironmentObject var walletState: WalletStateManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedNFT: NFTMetadata?
    @State private var viewMode: ViewMode = .grid
    
    enum ViewMode {
        case grid, list
    }
    
    private let columns = [
        GridItem(.flexible(), spacing: KC.Space.md),
        GridItem(.flexible(), spacing: KC.Space.md)
    ]
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                KC.Color.bg.ignoresSafeArea()
                
                if walletState.nfts.isEmpty {
                    emptyState
                } else {
                    galleryView
                }
            }
            .navigationTitle("Collectibles")
            .kcNavigationLarge()
            .toolbar {
                ToolbarItem(placement: .kcLeading) {
                    Button(action: toggleViewMode) {
                        Image(systemName: viewMode == .grid ? "square.grid.2x2" : "list.bullet")
                            .foregroundColor(KC.Color.textSecondary)
                    }
                }
                ToolbarItem(placement: .kcTrailing) {
                    KCCloseButton { dismiss() }
                }
            }
            .sheet(item: $selectedNFT) { nft in
                NFTDetailSheet(nft: nft)
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        KCEmptyState(
            icon: "photo.stack",
            title: "No NFTs Yet",
            message: "Your NFT collection will appear here. Start collecting to see them displayed.",
            actionTitle: nil,
            action: nil
        )
    }
    
    // MARK: - Gallery
    
    private var galleryView: some View {
        ScrollView {
            if viewMode == .grid {
                LazyVGrid(columns: columns, spacing: KC.Space.md) {
                    ForEach(walletState.nfts, id: \.id) { nft in
                        NFTGridItem(nft: nft)
                            .onTapGesture {
                                HapticEngine.shared.play(.selection)
                                selectedNFT = nft
                            }
                    }
                }
                .kcPadding()
                .padding(.top, KC.Space.md)
                .padding(.bottom, KC.Space.xxxl)
            } else {
                LazyVStack(spacing: KC.Space.md) {
                    ForEach(walletState.nfts, id: \.id) { nft in
                        NFTListItem(nft: nft)
                            .onTapGesture {
                                HapticEngine.shared.play(.selection)
                                selectedNFT = nft
                            }
                    }
                }
                .kcPadding()
                .padding(.top, KC.Space.md)
                .padding(.bottom, KC.Space.xxxl)
            }
        }
    }
    
    private func toggleViewMode() {
        HapticEngine.shared.play(.selection)
        withAnimation(KC.Anim.quick) {
            viewMode = viewMode == .grid ? .list : .grid
        }
    }
}

// MARK: - NFT Grid Item

private struct NFTGridItem: View {
    let nft: NFTMetadata
    
    var body: some View {
        VStack(alignment: .leading, spacing: KC.Space.sm) {
            // Image
            ZStack {
                AsyncImage(url: nft.imageURL) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(KC.Color.cardElevated)
                            .overlay(
                                ProgressView()
                                    .tint(KC.Color.gold)
                            )
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(1, contentMode: .fill)
                    case .failure:
                        Rectangle()
                            .fill(KC.Color.cardElevated)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(KC.Color.textMuted)
                            )
                    @unknown default:
                        Rectangle()
                            .fill(KC.Color.cardElevated)
                    }
                }
                .aspectRatio(1, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: KC.Radius.md))
            }
            
            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(nft.name)
                    .font(KC.Font.body)
                    .foregroundColor(KC.Color.textPrimary)
                    .lineLimit(1)
                
                Text(nft.collectionName)
                    .font(KC.Font.caption)
                    .foregroundColor(KC.Color.textTertiary)
                    .lineLimit(1)
            }
        }
        .padding(KC.Space.sm)
        .background(KC.Color.card)
        .clipShape(RoundedRectangle(cornerRadius: KC.Radius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: KC.Radius.lg)
                .stroke(KC.Color.border, lineWidth: 1)
        )
    }
}

// MARK: - NFT List Item

private struct NFTListItem: View {
    let nft: NFTMetadata
    
    var body: some View {
        HStack(spacing: KC.Space.lg) {
            // Thumbnail
            AsyncImage(url: nft.imageURL) { phase in
                switch phase {
                case .empty, .failure:
                    Rectangle()
                        .fill(KC.Color.cardElevated)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(1, contentMode: .fill)
                @unknown default:
                    Rectangle()
                        .fill(KC.Color.cardElevated)
                }
            }
            .frame(width: 64, height: 64)
            .clipShape(RoundedRectangle(cornerRadius: KC.Radius.sm))
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(nft.name)
                    .font(KC.Font.body)
                    .foregroundColor(KC.Color.textPrimary)
                    .lineLimit(1)
                
                Text(nft.collectionName)
                    .font(KC.Font.caption)
                    .foregroundColor(KC.Color.textTertiary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(KC.Color.textMuted)
        }
        .padding(KC.Space.lg)
        .background(KC.Color.card)
        .clipShape(RoundedRectangle(cornerRadius: KC.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: KC.Radius.md)
                .stroke(KC.Color.border, lineWidth: 1)
        )
    }
}

// MARK: - NFT Detail Sheet

struct NFTDetailSheet: View {
    let nft: NFTMetadata
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                KC.Color.bg.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: KC.Space.xl) {
                        // Image
                        AsyncImage(url: nft.imageURL) { phase in
                            switch phase {
                            case .empty:
                                Rectangle()
                                    .fill(KC.Color.cardElevated)
                                    .aspectRatio(1, contentMode: .fit)
                                    .overlay(ProgressView().tint(KC.Color.gold))
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            case .failure:
                                Rectangle()
                                    .fill(KC.Color.cardElevated)
                                    .aspectRatio(1, contentMode: .fit)
                                    .overlay(
                                        Image(systemName: "photo")
                                            .font(.system(size: 40))
                                            .foregroundColor(KC.Color.textMuted)
                                    )
                            @unknown default:
                                Rectangle()
                                    .fill(KC.Color.cardElevated)
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: KC.Radius.xl))
                        .kcPadding()
                        
                        // Info
                        VStack(alignment: .leading, spacing: KC.Space.lg) {
                            VStack(alignment: .leading, spacing: KC.Space.sm) {
                                Text(nft.name)
                                    .font(KC.Font.title2)
                                    .foregroundColor(KC.Color.textPrimary)
                                
                                HStack(spacing: KC.Space.sm) {
                                    Circle()
                                        .fill(KC.Color.gold.opacity(0.2))
                                        .frame(width: 24, height: 24)
                                        .overlay(
                                            Text(String(nft.collectionName.prefix(1)))
                                                .font(KC.Font.micro)
                                                .foregroundColor(KC.Color.gold)
                                        )
                                    
                                    Text(nft.collectionName)
                                        .font(KC.Font.body)
                                        .foregroundColor(KC.Color.textTertiary)
                                }
                            }
                            
                            // Spam warning if applicable
                            if nft.isSpam {
                                KCBanner("This NFT has been flagged as potential spam", type: .warning)
                            }
                        }
                        .kcPadding()
                    }
                    .padding(.bottom, KC.Space.xxxl)
                }
            }
            #if os(iOS)
            .kcNavigationInline()
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .kcTrailing) {
                    KCCloseButton { dismiss() }
                }
                #else
                ToolbarItem(placement: .automatic) {
                    KCCloseButton { dismiss() }
                }
                #endif
            }
        }
    }
}

// NFTMetadata is already Identifiable from Core

#Preview {
    NFTGalleryScreen()
}

