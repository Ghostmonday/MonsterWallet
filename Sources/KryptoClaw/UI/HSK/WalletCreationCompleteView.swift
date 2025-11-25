import SwiftUI

/// Success screen after HSK-bound wallet creation
public struct WalletCreationCompleteView: View {
    
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var coordinator: HSKFlowCoordinator
    
    @State private var showContent = false
    @State private var showButtons = false
    @State private var confettiScale: CGFloat = 0
    
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
                
                // Success animation
                ZStack {
                    // Celebration rings
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .stroke(
                                themeManager.currentTheme.successColor.opacity(0.3 - Double(index) * 0.1),
                                lineWidth: 2
                            )
                            .frame(
                                width: 160 + CGFloat(index) * 40,
                                height: 160 + CGFloat(index) * 40
                            )
                            .scaleEffect(confettiScale)
                    }
                    
                    // Main success circle
                    Circle()
                        .fill(themeManager.currentTheme.successColor.opacity(0.15))
                        .frame(width: 140, height: 140)
                    
                    Circle()
                        .stroke(themeManager.currentTheme.successColor, lineWidth: 3)
                        .frame(width: 140, height: 140)
                    
                    // Checkmark with key
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 56, weight: .medium))
                            .foregroundColor(themeManager.currentTheme.successColor)
                        
                        Image(systemName: "key.horizontal.fill")
                            .font(.system(size: 20))
                            .foregroundColor(themeManager.currentTheme.successColor.opacity(0.7))
                    }
                }
                .scaleEffect(showContent ? 1.0 : 0.5)
                .opacity(showContent ? 1.0 : 0)
                
                Spacer().frame(height: 48)
                
                // Success message
                VStack(spacing: 16) {
                    Text("WALLET SECURED")
                        .font(themeManager.currentTheme.font(style: .title))
                        .tracking(3)
                        .foregroundColor(themeManager.currentTheme.successColor)
                    
                    Text("Your hardware key wallet is ready")
                        .font(themeManager.currentTheme.font(style: .body))
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                }
                .opacity(showContent ? 1.0 : 0)
                .offset(y: showContent ? 0 : 20)
                
                Spacer().frame(height: 40)
                
                // Wallet details card
                if let address = coordinator.derivedAddress {
                    VStack(spacing: 16) {
                        DetailRow(label: "Wallet Address", value: formatAddress(address))
                        
                        Divider()
                            .background(themeManager.currentTheme.borderColor)
                        
                        DetailRow(label: "Security", value: "Hardware Key Protected")
                        
                        Divider()
                            .background(themeManager.currentTheme.borderColor)
                        
                        DetailRow(label: "Binding", value: "FIDO2 / WebAuthn")
                    }
                    .padding(20)
                    .background(themeManager.currentTheme.cardBackground)
                    .cornerRadius(themeManager.currentTheme.cornerRadius)
                    .overlay(
                        RoundedRectangle(cornerRadius: themeManager.currentTheme.cornerRadius)
                            .stroke(themeManager.currentTheme.borderColor, lineWidth: 1)
                    )
                    .padding(.horizontal, 24)
                    .opacity(showContent ? 1.0 : 0)
                    .offset(y: showContent ? 0 : 30)
                }
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 16) {
                    KryptoButton(
                        title: "CONTINUE TO WALLET",
                        icon: "arrow.right.circle.fill",
                        action: { coordinator.complete() },
                        isPrimary: true
                    )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .opacity(showButtons ? 1.0 : 0)
                .offset(y: showButtons ? 0 : 20)
            }
        }
        .onAppear {
            animateIn()
        }
    }
    
    private func animateIn() {
        // Staggered animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            showContent = true
            confettiScale = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                showButtons = true
            }
        }
    }
    
    private func formatAddress(_ address: String) -> String {
        guard address.count > 16 else { return address }
        let prefix = String(address.prefix(10))
        let suffix = String(address.suffix(8))
        return "\(prefix)...\(suffix)"
    }
}

// MARK: - Detail Row Component

private struct DetailRow: View {
    let label: String
    let value: String
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack {
            Text(label)
                .font(themeManager.currentTheme.font(style: .caption))
                .foregroundColor(themeManager.currentTheme.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(themeManager.currentTheme.addressFont)
                .foregroundColor(themeManager.currentTheme.textPrimary)
                .lineLimit(1)
        }
    }
}

