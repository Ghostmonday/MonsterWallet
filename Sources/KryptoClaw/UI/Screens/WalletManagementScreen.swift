// KRYPTOCLAW WALLET MANAGEMENT
// Your vaults. Full control.
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

import SwiftUI

public struct WalletManagementScreen: View {
    @EnvironmentObject var walletState: WalletStateManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingCreateWallet = false
    @State private var showingImportWallet = false
    @State private var selectedWallet: WalletInfo?
    @State private var showDeleteConfirm = false
    @State private var walletToDelete: WalletInfo?
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                KC.Color.bg.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: KC.Space.xl) {
                        // Active wallet
                        if let current = currentWallet {
                            VStack(alignment: .leading, spacing: KC.Space.md) {
                                Text("ACTIVE WALLET")
                                    .font(KC.Font.label)
                                    .tracking(1.5)
                                    .foregroundColor(KC.Color.textMuted)
                                
                                ActiveWalletCard(wallet: current, isHSKBound: walletState.isWalletHSKBound(current.id))
                            }
                        }
                        
                        // All wallets
                        VStack(alignment: .leading, spacing: KC.Space.md) {
                            Text("ALL WALLETS")
                                .font(KC.Font.label)
                                .tracking(1.5)
                                .foregroundColor(KC.Color.textMuted)
                            
                            VStack(spacing: KC.Space.sm) {
                                ForEach(walletState.wallets, id: \.id) { wallet in
                                    WalletRow(
                                        wallet: wallet,
                                        isActive: wallet.id == walletState.currentAddress,
                                        isHSKBound: walletState.isWalletHSKBound(wallet.id)
                                    )
                                    .onTapGesture {
                                        switchWallet(wallet)
                                    }
                                    .contextMenu {
                                        Button(action: {
                                            switchWallet(wallet)
                                        }) {
                                            Label("Switch to Wallet", systemImage: "arrow.right.circle")
                                        }
                                        
                                        if walletState.wallets.count > 1 {
                                            Button(role: .destructive, action: {
                                                walletToDelete = wallet
                                                showDeleteConfirm = true
                                            }) {
                                                Label("Delete Wallet", systemImage: "trash")
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Add wallet buttons
                        VStack(spacing: KC.Space.md) {
                            KCButton("Create New Wallet", icon: "plus.circle", style: .secondary) {
                                showingCreateWallet = true
                            }
                            
                            KCButton("Import Wallet", icon: "arrow.down.doc", style: .secondary) {
                                showingImportWallet = true
                            }
                        }
                        .padding(.top, KC.Space.lg)
                    }
                    .kcPadding()
                    .padding(.top, KC.Space.lg)
                    .padding(.bottom, KC.Space.xxxl)
                }
            }
            .navigationTitle("Wallets")
            .kcNavigationLarge()
            .toolbar {
                ToolbarItem(placement: .kcTrailing) {
                    KCCloseButton { dismiss() }
                }
            }
            .sheet(isPresented: $showingCreateWallet) {
                QuickCreateWalletSheet()
                    .environmentObject(walletState)
            }
            .sheet(isPresented: $showingImportWallet) {
                ImportWalletSheet(onComplete: {})
                    .environmentObject(walletState)
            }
            .alert("Delete Wallet", isPresented: $showDeleteConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let wallet = walletToDelete {
                        deleteWallet(wallet)
                    }
                }
            } message: {
                Text("Are you sure you want to delete this wallet? This action cannot be undone.")
            }
        }
    }
    
    private var currentWallet: WalletInfo? {
        walletState.wallets.first { $0.id == walletState.currentAddress }
    }
    
    private func switchWallet(_ wallet: WalletInfo) {
        guard wallet.id != walletState.currentAddress else { return }
        HapticEngine.shared.play(.selection)
        Task {
            await walletState.switchWallet(id: wallet.id)
        }
    }
    
    private func deleteWallet(_ wallet: WalletInfo) {
        HapticEngine.shared.play(.error)
        Task {
            await walletState.deleteWallet(id: wallet.id)
        }
    }
}

// MARK: - Active Wallet Card

private struct ActiveWalletCard: View {
    let wallet: WalletInfo
    let isHSKBound: Bool
    
    var body: some View {
        VStack(spacing: KC.Space.lg) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: KC.Space.sm) {
                        Text(wallet.name)
                            .font(KC.Font.title3)
                            .foregroundColor(KC.Color.textPrimary)
                        
                        if isHSKBound {
                            Image(systemName: "key.horizontal.fill")
                                .font(.system(size: 12))
                                .foregroundColor(KC.Color.gold)
                        }
                    }
                    
                    Text(truncateAddress(wallet.id))
                        .font(KC.Font.mono)
                        .foregroundColor(KC.Color.textTertiary)
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(KC.Color.positive.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(KC.Color.positive)
                }
            }
            
            Divider().background(KC.Color.divider)
            
            // Quick stats
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Created")
                        .font(KC.Font.caption)
                        .foregroundColor(KC.Color.textMuted)
                    Text("Today")
                        .font(KC.Font.body)
                        .foregroundColor(KC.Color.textSecondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Security")
                        .font(KC.Font.caption)
                        .foregroundColor(KC.Color.textMuted)
                    Text(isHSKBound ? "HSK Protected" : "Standard")
                        .font(KC.Font.body)
                        .foregroundColor(isHSKBound ? KC.Color.gold : KC.Color.textSecondary)
                }
            }
        }
        .padding(KC.Space.xl)
        .background(KC.Color.card)
        .clipShape(RoundedRectangle(cornerRadius: KC.Radius.xl))
        .overlay(
            RoundedRectangle(cornerRadius: KC.Radius.xl)
                .stroke(KC.Color.gold.opacity(0.3), lineWidth: 1)
        )
    }
    
    private func truncateAddress(_ address: String) -> String {
        guard address.count > 16 else { return address }
        return "\(address.prefix(8))...\(address.suffix(6))"
    }
}

// MARK: - Wallet Row

private struct WalletRow: View {
    let wallet: WalletInfo
    let isActive: Bool
    let isHSKBound: Bool
    
    var body: some View {
        HStack(spacing: KC.Space.lg) {
            // Icon
            ZStack {
                Circle()
                    .fill(walletColor.opacity(0.15))
                    .frame(width: KC.Size.avatarMD, height: KC.Size.avatarMD)
                
                Image(systemName: isHSKBound ? "key.horizontal" : "wallet.pass")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(walletColor)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: KC.Space.sm) {
                    Text(wallet.name)
                        .font(KC.Font.body)
                        .foregroundColor(KC.Color.textPrimary)
                    
                    if isHSKBound {
                        Image(systemName: "key.horizontal.fill")
                            .font(.system(size: 10))
                            .foregroundColor(KC.Color.gold)
                    }
                }
                
                Text(truncateAddress(wallet.id))
                    .font(KC.Font.monoSmall)
                    .foregroundColor(KC.Color.textTertiary)
            }
            
            Spacer()
            
            // Status
            if isActive {
                Text("Active")
                    .font(KC.Font.caption)
                    .foregroundColor(KC.Color.positive)
                    .padding(.horizontal, KC.Space.sm)
                    .padding(.vertical, 4)
                    .background(KC.Color.positive.opacity(0.15))
                    .clipShape(Capsule())
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(KC.Color.textMuted)
            }
        }
        .padding(KC.Space.lg)
        .background(isActive ? KC.Color.goldGhost : KC.Color.card)
        .clipShape(RoundedRectangle(cornerRadius: KC.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: KC.Radius.md)
                .stroke(isActive ? KC.Color.gold.opacity(0.3) : KC.Color.border, lineWidth: 1)
        )
    }
    
    private var walletColor: Color {
        switch wallet.colorTheme {
        case "gold": return KC.Color.gold
        case "blue": return KC.Color.info
        case "purple": return .purple
        default: return KC.Color.gold
        }
    }
    
    private func truncateAddress(_ address: String) -> String {
        guard address.count > 16 else { return address }
        return "\(address.prefix(6))...\(address.suffix(4))"
    }
}

// MARK: - Quick Create Wallet Sheet

struct QuickCreateWalletSheet: View {
    @EnvironmentObject var walletState: WalletStateManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var walletName = ""
    @State private var isCreating = false
    @State private var mnemonic: String?
    @State private var showMnemonic = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                KC.Color.bg.ignoresSafeArea()
                
                if showMnemonic, let mnemonic = mnemonic {
                    backupView(mnemonic: mnemonic)
                } else {
                    createView
                }
            }
            .navigationTitle(showMnemonic ? "Backup Phrase" : "Create Wallet")
            .kcNavigationInline()
            .toolbar {
                ToolbarItem(placement: .kcTrailing) {
                    if !showMnemonic {
                        KCCloseButton { dismiss() }
                    }
                }
            }
        }
    }
    
    private var createView: some View {
        VStack(spacing: KC.Space.xl) {
            VStack(alignment: .leading, spacing: KC.Space.sm) {
                Text("WALLET NAME")
                    .font(KC.Font.label)
                    .tracking(1.5)
                    .foregroundColor(KC.Color.textMuted)
                
                KCInput("My Wallet", text: $walletName, icon: "wallet.pass")
            }
            .padding(.top, KC.Space.xl)
            
            Spacer()
            
            KCButton("Create Wallet", icon: "plus", isLoading: isCreating) {
                createWallet()
            }
            .disabled(walletName.isEmpty)
            .padding(.bottom, KC.Space.xxxl)
        }
        .kcPadding()
    }
    
    private func backupView(mnemonic: String) -> some View {
        VStack(spacing: KC.Space.xl) {
            Text("Write down these 12 words in order. This is your wallet's recovery phrase.")
                .font(KC.Font.body)
                .foregroundColor(KC.Color.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.top, KC.Space.xl)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: KC.Space.sm) {
                ForEach(Array(mnemonic.split(separator: " ").enumerated()), id: \.offset) { index, word in
                    WordPill(index: index + 1, word: String(word))
                }
            }
            
            KCBanner("Store this phrase securely. Anyone with these words can access your wallet.", type: .warning)
            
            Spacer()
            
            KCButton("I've Saved It", icon: "checkmark") {
                HapticEngine.shared.play(.success)
                dismiss()
            }
            .padding(.bottom, KC.Space.xxxl)
        }
        .kcPadding()
    }
    
    private func createWallet() {
        isCreating = true
        Task {
            if let phrase = await walletState.createWallet(name: walletName) {
                mnemonic = phrase
                withAnimation {
                    showMnemonic = true
                }
            }
            isCreating = false
        }
    }
}

#Preview {
    WalletManagementScreen()
}

