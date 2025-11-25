import SwiftUI

/// Entry screen for HSK-bound wallet creation flow
public struct HSKWalletInitiationView: View {
    
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var coordinator: HSKFlowCoordinator
    
    @State private var isArming = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    public init(coordinator: HSKFlowCoordinator) {
        self.coordinator = coordinator
    }
    
    public var body: some View {
        ZStack {
            // Background
            Color.clear
                .themedContainer(theme: themeManager.currentTheme, showPattern: true, applyAnimation: true)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Icon & Title
                VStack(spacing: 32) {
                    // HSK Icon with glow effect
                    ZStack {
                        Circle()
                            .fill(themeManager.currentTheme.accentColor.opacity(0.15))
                            .frame(width: 140, height: 140)
                        
                        Circle()
                            .stroke(themeManager.currentTheme.accentColor.opacity(0.3), lineWidth: 2)
                            .frame(width: 140, height: 140)
                        
                        Image(systemName: "key.horizontal.fill")
                            .font(.system(size: 56, weight: .medium))
                            .foregroundColor(themeManager.currentTheme.accentColor)
                    }
                    .shadow(color: themeManager.currentTheme.accentColor.opacity(0.3), radius: 20, x: 0, y: 0)
                    
                    VStack(spacing: 12) {
                        Text("HARDWARE KEY WALLET")
                            .font(themeManager.currentTheme.font(style: .title2))
                            .tracking(2)
                            .foregroundColor(themeManager.currentTheme.textPrimary)
                        
                        Text("Create a wallet secured by your\nhardware security key")
                            .font(themeManager.currentTheme.font(style: .body))
                            .foregroundColor(themeManager.currentTheme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                }
                
                Spacer()
                
                // Features list
                VStack(spacing: 16) {
                    FeatureRow(
                        icon: "shield.checkered",
                        title: "FIDO2 Security",
                        subtitle: "Industry-standard hardware authentication"
                    )
                    
                    FeatureRow(
                        icon: "lock.shield.fill",
                        title: "Phishing Resistant",
                        subtitle: "Keys bound to device, not copyable"
                    )
                    
                    FeatureRow(
                        icon: "cpu.fill",
                        title: "Secure Enclave",
                        subtitle: "Protected by device hardware"
                    )
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 16) {
                    KryptoButton(
                        title: isArming ? "PREPARING..." : "BEGIN SETUP",
                        icon: isArming ? "hourglass" : "arrow.right.circle.fill",
                        action: beginSetup,
                        isPrimary: true
                    )
                    .disabled(isArming)
                    
                    Button(action: { coordinator.cancel() }) {
                        Text("Cancel")
                            .font(themeManager.currentTheme.font(style: .body))
                            .foregroundColor(themeManager.currentTheme.textSecondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .alert("Setup Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func beginSetup() {
        isArming = true
        
        Task {
            do {
                try await coordinator.armSecureEnclave()
                await MainActor.run {
                    coordinator.transitionToInsertion()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isArming = false
                }
            }
        }
    }
}

// MARK: - Feature Row Component

private struct FeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(themeManager.currentTheme.accentColor)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(themeManager.currentTheme.font(style: .subheadline))
                    .foregroundColor(themeManager.currentTheme.textPrimary)
                
                Text(subtitle)
                    .font(themeManager.currentTheme.font(style: .caption))
                    .foregroundColor(themeManager.currentTheme.textSecondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

