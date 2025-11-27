// KRYPTOCLAW RECEIVE SCREEN
// Clean QR. Easy copy.
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

import SwiftUI
import CoreImage.CIFilterBuiltins
#if canImport(UIKit)
import UIKit
#endif

public struct ReceiveScreen: View {
    @EnvironmentObject var walletState: WalletStateManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedChain: Chain = .ethereum
    @State private var copied = false
    @State private var showChainPicker = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                KC.Color.bg.ignoresSafeArea()
                
                VStack(spacing: KC.Space.xxl) {
                    // Header
                    VStack(spacing: KC.Space.sm) {
                        Text("Receive")
                            .font(KC.Font.title2)
                            .foregroundColor(KC.Color.textPrimary)
                        
                        Text("Scan QR code or copy address")
                            .font(KC.Font.body)
                            .foregroundColor(KC.Color.textTertiary)
                    }
                    .padding(.top, KC.Space.xl)
                    
                    // Chain selector
                    Button(action: { showChainPicker = true }) {
                        HStack(spacing: KC.Space.sm) {
                            KCTokenIcon(selectedChain.nativeCurrency, size: 28)
                            Text(selectedChain.displayName)
                                .font(KC.Font.bodyLarge)
                                .foregroundColor(KC.Color.textPrimary)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(KC.Color.textTertiary)
                        }
                        .padding(.horizontal, KC.Space.lg)
                        .padding(.vertical, KC.Space.md)
                        .background(KC.Color.card)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(KC.Color.border, lineWidth: 1))
                    }
                    
                    Spacer()
                    
                    // QR Code
                    VStack(spacing: KC.Space.xl) {
                        ZStack {
                            // White background for QR contrast
                            RoundedRectangle(cornerRadius: KC.Radius.xl)
                                .fill(.white)
                                .frame(width: 240, height: 240)
                            
                            // QR Code
                            #if canImport(UIKit)
                            if let address = walletState.currentAddress {
                                Image(uiImage: generateQRCode(from: address))
                                    .interpolation(.none)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 200, height: 200)
                            }
                            #else
                            Text("QR Code")
                                .font(KC.Font.title3)
                                .foregroundColor(KC.Color.textMuted)
                            #endif
                            
                            // Center logo
                            ZStack {
                                Circle()
                                    .fill(KC.Color.bg)
                                    .frame(width: 44, height: 44)
                                
                                Image(systemName: "shield.checkered")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(KC.Color.gold)
                            }
                        }
                        
                        // Warning
                        HStack(spacing: KC.Space.sm) {
                            Image(systemName: "info.circle")
                                .foregroundColor(KC.Color.info)
                            Text("Only send \(selectedChain.nativeCurrency) on \(selectedChain.displayName)")
                                .font(KC.Font.caption)
                                .foregroundColor(KC.Color.textTertiary)
                        }
                    }
                    
                    Spacer()
                    
                    // Address card
                    VStack(spacing: KC.Space.md) {
                        Text("WALLET ADDRESS")
                            .font(KC.Font.label)
                            .tracking(1.5)
                            .foregroundColor(KC.Color.textMuted)
                        
                        if let address = walletState.currentAddress {
                            Text(address)
                                .font(KC.Font.monoSmall)
                                .foregroundColor(KC.Color.textSecondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                    }
                    .padding(KC.Space.lg)
                    .frame(maxWidth: .infinity)
                    .background(KC.Color.card)
                    .clipShape(RoundedRectangle(cornerRadius: KC.Radius.lg))
                    .overlay(
                        RoundedRectangle(cornerRadius: KC.Radius.lg)
                            .stroke(KC.Color.border, lineWidth: 1)
                    )
                    .kcPadding()
                    
                    // Copy button
                    KCButton(copied ? "Copied!" : "Copy Address", icon: copied ? "checkmark" : "doc.on.doc") {
                        copyAddress()
                    }
                    .kcPadding()
                    .padding(.bottom, KC.Space.xxxl)
                }
            }
            .kcNavigationInline()
            .toolbar {
                ToolbarItem(placement: .kcTrailing) {
                    KCCloseButton { dismiss() }
                }
            }
            .sheet(isPresented: $showChainPicker) {
                ChainPickerSheet(selected: $selectedChain)
            }
        }
    }
    
    private func copyAddress() {
        guard let address = walletState.currentAddress else { return }
        walletState.copyCurrentAddress()
        HapticEngine.shared.play(.success)
        withAnimation {
            copied = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                copied = false
            }
        }
    }
    
    #if canImport(UIKit)
    private func generateQRCode(from string: String) -> UIImage {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"
        
        if let outputImage = filter.outputImage {
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledImage = outputImage.transformed(by: transform)
            
            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }
        
        return UIImage(systemName: "xmark.circle") ?? UIImage()
    }
    #endif
}

// MARK: - Chain Picker

struct ChainPickerSheet: View {
    @Binding var selected: Chain
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                KC.Color.bg.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: KC.Space.sm) {
                        ForEach(Chain.allCases, id: \.self) { chain in
                            Button(action: {
                                HapticEngine.shared.play(.selection)
                                selected = chain
                                dismiss()
                            }) {
                                HStack(spacing: KC.Space.lg) {
                                    KCTokenIcon(chain.nativeCurrency)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(chain.displayName)
                                            .font(KC.Font.body)
                                            .foregroundColor(KC.Color.textPrimary)
                                        
                                        Text(chain.nativeCurrency)
                                            .font(KC.Font.caption)
                                            .foregroundColor(KC.Color.textTertiary)
                                    }
                                    
                                    Spacer()
                                    
                                    if chain == selected {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(KC.Color.gold)
                                    }
                                }
                                .padding(KC.Space.lg)
                                .background(chain == selected ? KC.Color.goldGhost : KC.Color.card)
                                .clipShape(RoundedRectangle(cornerRadius: KC.Radius.md))
                                .overlay(
                                    RoundedRectangle(cornerRadius: KC.Radius.md)
                                        .stroke(chain == selected ? KC.Color.gold.opacity(0.3) : KC.Color.border, lineWidth: 1)
                                )
                            }
                        }
                    }
                    .kcPadding()
                    .padding(.top, KC.Space.lg)
                }
            }
            .navigationTitle("Select Network")
            .kcNavigationInline()
            .toolbar {
                ToolbarItem(placement: .kcTrailing) {
                    KCCloseButton { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    ReceiveScreen()
}

