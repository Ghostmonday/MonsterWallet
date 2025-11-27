// KRYPTOCLAW HSK SCREENS
// Hardware Security Key flows. Military-grade.
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

import SwiftUI

// MARK: - HSK Setup Sheet (Onboarding)

public struct HSKSetupSheet: View {
    let onComplete: () -> Void
    
    @EnvironmentObject var walletState: WalletStateManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var step: HSKStep = .intro
    @State private var isScanning = false
    @State private var hskDetected = false
    @State private var isCreatingWallet = false
    @State private var showSuccess = false
    
    enum HSKStep {
        case intro
        case insert
        case authenticate
        case creating
        case success
    }
    
    public init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                KC.Color.bg.ignoresSafeArea()
                
                switch step {
                case .intro: introView
                case .insert: insertView
                case .authenticate: authenticateView
                case .creating: creatingView
                case .success: successView
                }
            }
            .kcNavigationInline()
            .toolbar {
                ToolbarItem(placement: .kcLeading) {
                    if step != .intro && step != .success && step != .creating {
                        KCBackButton {
                            withAnimation { step = previousStep }
                        }
                    }
                }
                ToolbarItem(placement: .kcTrailing) {
                    if step != .success && step != .creating {
                        KCCloseButton { dismiss() }
                    }
                }
            }
        }
    }
    
    // MARK: - Intro View
    
    private var introView: some View {
        VStack(spacing: KC.Space.xxl) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(KC.Color.goldGhost)
                    .frame(width: 120, height: 120)
                
                Image(systemName: "key.horizontal.fill")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundColor(KC.Color.gold)
            }
            
            VStack(spacing: KC.Space.md) {
                Text("Hardware Security Key")
                    .font(KC.Font.title2)
                    .foregroundColor(KC.Color.textPrimary)
                
                Text("Use a hardware security key (FIDO2/WebAuthn) for maximum wallet security. Your key never leaves the device.")
                    .font(KC.Font.body)
                    .foregroundColor(KC.Color.textTertiary)
                    .multilineTextAlignment(.center)
            }
            .kcPadding()
            
            // Features
            VStack(spacing: KC.Space.lg) {
                FeatureRow(icon: "lock.shield", title: "Phishing Resistant", subtitle: "Keys are bound to device")
                FeatureRow(icon: "cpu", title: "Hardware Protected", subtitle: "Private key never exposed")
                FeatureRow(icon: "checkmark.seal", title: "FIDO2 Certified", subtitle: "Industry standard security")
            }
            .kcPadding()
            
            Spacer()
            
            KCButton("Get Started", icon: "arrow.right") {
                withAnimation { step = .insert }
            }
            .kcPadding()
            .padding(.bottom, KC.Space.xxxl)
        }
    }
    
    // MARK: - Insert View
    
    private var insertView: some View {
        VStack(spacing: KC.Space.xxl) {
            Spacer()
            
            // Animation
            ZStack {
                Circle()
                    .stroke(KC.Color.gold.opacity(0.3), lineWidth: 2)
                    .frame(width: 140, height: 140)
                
                Circle()
                    .fill(hskDetected ? KC.Color.positive.opacity(0.15) : KC.Color.card)
                    .frame(width: 120, height: 120)
                
                if isScanning {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(KC.Color.gold)
                } else if hskDetected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(KC.Color.positive)
                } else {
                    Image(systemName: "key.horizontal")
                        .font(.system(size: 40, weight: .medium))
                        .foregroundColor(KC.Color.gold)
                }
            }
            
            VStack(spacing: KC.Space.md) {
                Text(hskDetected ? "Key Detected" : "Insert Security Key")
                    .font(KC.Font.title2)
                    .foregroundColor(KC.Color.textPrimary)
                
                Text(hskDetected ? "Your hardware key has been recognized" : "Insert your hardware security key into the device port or tap it against NFC reader")
                    .font(KC.Font.body)
                    .foregroundColor(KC.Color.textTertiary)
                    .multilineTextAlignment(.center)
            }
            .kcPadding()
            
            Spacer()
            
            if hskDetected {
                KCButton("Continue") {
                    withAnimation { step = .authenticate }
                }
                .kcPadding()
                .padding(.bottom, KC.Space.xxxl)
            } else {
                KCButton("Scan for Key", icon: "antenna.radiowaves.left.and.right", isLoading: isScanning) {
                    scanForKey()
                }
                .kcPadding()
                .padding(.bottom, KC.Space.xxxl)
            }
        }
    }
    
    // MARK: - Authenticate View
    
    private var authenticateView: some View {
        VStack(spacing: KC.Space.xxl) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(KC.Color.goldGhost)
                    .frame(width: 120, height: 120)
                
                Image(systemName: "touchid")
                    .font(.system(size: 56, weight: .light))
                    .foregroundColor(KC.Color.gold)
            }
            
            VStack(spacing: KC.Space.md) {
                Text("Authenticate")
                    .font(KC.Font.title2)
                    .foregroundColor(KC.Color.textPrimary)
                
                Text("Touch the key or enter your PIN to verify ownership")
                    .font(KC.Font.body)
                    .foregroundColor(KC.Color.textTertiary)
                    .multilineTextAlignment(.center)
            }
            .kcPadding()
            
            Spacer()
            
            KCButton("Authenticate", icon: "faceid") {
                authenticateWithKey()
            }
            .kcPadding()
            .padding(.bottom, KC.Space.xxxl)
        }
    }
    
    // MARK: - Creating View
    
    private var creatingView: some View {
        VStack(spacing: KC.Space.xxl) {
            Spacer()
            
            ZStack {
                Circle()
                    .stroke(KC.Color.gold.opacity(0.3), lineWidth: 3)
                    .frame(width: 100, height: 100)
                
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(KC.Color.gold)
            }
            
            VStack(spacing: KC.Space.md) {
                Text("Creating Wallet")
                    .font(KC.Font.title2)
                    .foregroundColor(KC.Color.textPrimary)
                
                Text("Deriving keys from your hardware security module...")
                    .font(KC.Font.body)
                    .foregroundColor(KC.Color.textTertiary)
                    .multilineTextAlignment(.center)
            }
            .kcPadding()
            
            Spacer()
        }
    }
    
    // MARK: - Success View
    
    private var successView: some View {
        VStack(spacing: KC.Space.xxl) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(KC.Color.positive.opacity(0.15))
                    .frame(width: 140, height: 140)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 60, weight: .bold))
                    .foregroundColor(KC.Color.positive)
            }
            
            VStack(spacing: KC.Space.md) {
                Text("HSK Wallet Created")
                    .font(KC.Font.title2)
                    .foregroundColor(KC.Color.textPrimary)
                
                Text("Your hardware-secured wallet is ready to use")
                    .font(KC.Font.body)
                    .foregroundColor(KC.Color.textTertiary)
            }
            
            // Security badge
            HStack(spacing: KC.Space.sm) {
                Image(systemName: "key.horizontal.fill")
                    .foregroundColor(KC.Color.gold)
                Text("HSK Protected")
                    .font(KC.Font.caption)
                    .foregroundColor(KC.Color.gold)
            }
            .padding(.horizontal, KC.Space.lg)
            .padding(.vertical, KC.Space.sm)
            .background(KC.Color.goldGhost)
            .clipShape(Capsule())
            
            Spacer()
            
            KCButton("Enter Wallet") {
                HapticEngine.shared.play(.success)
                onComplete()
            }
            .kcPadding()
            .padding(.bottom, KC.Space.xxxl)
        }
    }
    
    // MARK: - Helpers
    
    private var previousStep: HSKStep {
        switch step {
        case .intro: return .intro
        case .insert: return .intro
        case .authenticate: return .insert
        case .creating: return .authenticate
        case .success: return .success
        }
    }
    
    private func scanForKey() {
        isScanning = true
        // Simulate key detection
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isScanning = false
            withAnimation {
                hskDetected = true
            }
            HapticEngine.shared.play(.success)
        }
    }
    
    private func authenticateWithKey() {
        withAnimation { step = .creating }
        
        // Simulate wallet creation with HSK
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            HapticEngine.shared.play(.success)
            withAnimation { step = .success }
        }
    }
}

// MARK: - HSK Management Screen

public struct HSKManagementScreen: View {
    @EnvironmentObject var walletState: WalletStateManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingAddKey = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                KC.Color.bg.ignoresSafeArea()
                
                if walletState.hskBoundWallets.isEmpty {
                    emptyState
                } else {
                    keysList
                }
            }
            .navigationTitle("Hardware Keys")
            .kcNavigationLarge()
            .toolbar {
                ToolbarItem(placement: .kcLeading) {
                    Button(action: { showingAddKey = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(KC.Color.gold)
                    }
                }
                ToolbarItem(placement: .kcTrailing) {
                    KCCloseButton { dismiss() }
                }
            }
            .sheet(isPresented: $showingAddKey) {
                HSKSetupSheet(onComplete: { showingAddKey = false })
                    .environmentObject(walletState)
            }
        }
    }
    
    private var emptyState: some View {
        KCEmptyState(
            icon: "key.horizontal",
            title: "No Hardware Keys",
            message: "Add a hardware security key for enhanced wallet protection.",
            actionTitle: "Add Security Key",
            action: { showingAddKey = true }
        )
    }
    
    private var keysList: some View {
        ScrollView {
            VStack(spacing: KC.Space.md) {
                ForEach(walletState.hskBoundWallets, id: \.address) { binding in
                    HSKBoundWalletRow(binding: binding)
                }
            }
            .kcPadding()
            .padding(.top, KC.Space.lg)
            .padding(.bottom, KC.Space.xxxl)
        }
    }
}

// MARK: - HSK Bound Wallet Row

private struct HSKBoundWalletRow: View {
    let binding: HSKBoundWallet
    
    var body: some View {
        HStack(spacing: KC.Space.lg) {
            // Icon
            ZStack {
                Circle()
                    .fill(KC.Color.gold.opacity(0.15))
                    .frame(width: KC.Size.avatarMD, height: KC.Size.avatarMD)
                
                Image(systemName: "key.horizontal.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(KC.Color.gold)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text("HSK Wallet")
                    .font(KC.Font.body)
                    .foregroundColor(KC.Color.textPrimary)
                
                Text(truncateAddress(binding.address))
                    .font(KC.Font.monoSmall)
                    .foregroundColor(KC.Color.textTertiary)
            }
            
            Spacer()
            
            // Status
            Text("Active")
                .font(KC.Font.caption)
                .foregroundColor(KC.Color.positive)
                .padding(.horizontal, KC.Space.sm)
                .padding(.vertical, 4)
                .background(KC.Color.positive.opacity(0.15))
                .clipShape(Capsule())
        }
        .padding(KC.Space.lg)
        .background(KC.Color.card)
        .clipShape(RoundedRectangle(cornerRadius: KC.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: KC.Radius.md)
                .stroke(KC.Color.gold.opacity(0.3), lineWidth: 1)
        )
    }
    
    private func truncateAddress(_ address: String) -> String {
        guard address.count > 16 else { return address }
        return "\(address.prefix(8))...\(address.suffix(6))"
    }
}

// MARK: - Feature Row

private struct FeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: KC.Space.lg) {
            ZStack {
                Circle()
                    .fill(KC.Color.cardElevated)
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(KC.Color.gold)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(KC.Font.body)
                    .foregroundColor(KC.Color.textPrimary)
                
                Text(subtitle)
                    .font(KC.Font.caption)
                    .foregroundColor(KC.Color.textTertiary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    HSKSetupSheet(onComplete: {})
}

