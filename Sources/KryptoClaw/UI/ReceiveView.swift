import SwiftUI
#if canImport(UIKit)
    import UIKit
#endif
import CoreImage.CIFilterBuiltins

struct ReceiveView: View {
    @EnvironmentObject var wsm: WalletStateManager
    @EnvironmentObject var themeManager: ThemeManager
    @State private var copied: Bool = false

    var body: some View {
        ZStack {
            themeManager.currentTheme.backgroundMain.ignoresSafeArea()

            VStack(spacing: 30) {
                Text("Receive Assets")
                    .font(themeManager.currentTheme.font(style: .title2))
                    .foregroundColor(themeManager.currentTheme.textPrimary)
                    .padding(.top, 40)

                if let address = wsm.currentAddress {
                    VStack(spacing: 20) {
                        #if canImport(UIKit)
                            Image(uiImage: generateQRCode(from: address))
                                .resizable()
                                .interpolation(.none)
                                .scaledToFit()
                                .frame(width: 200, height: 200)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                        #else
                            Image(systemName: "qrcode")
                                .font(.system(size: 200))
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                        #endif

                        Text("Scan to send ETH or ERC-20 tokens")
                            .font(themeManager.currentTheme.font(style: .caption))
                            .foregroundColor(themeManager.currentTheme.textSecondary)
                    }

                    Button(action: {
                        wsm.copyCurrentAddress()
                        withAnimation {
                            copied = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation { copied = false }
                        }
                    }) {
                        HStack {
                            Text(address)
                                .font(themeManager.currentTheme.addressFont)
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .foregroundColor(themeManager.currentTheme.textPrimary)

                            Image(systemName: copied ? "checkmark" : "doc.on.doc")
                                .foregroundColor(copied ? .green : themeManager.currentTheme.accentColor)
                        }
                        .padding()
                        .background(themeManager.currentTheme.backgroundSecondary)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(themeManager.currentTheme.borderColor, lineWidth: 1)
                        )
                    }
                    .padding(.horizontal)

                    ShareLink(item: address, subject: Text("My Wallet Address"), message: Text("Here is my wallet address: \(address)")) {
                        Label("Share Address", systemImage: "square.and.arrow.up")
                    }
                    .foregroundColor(themeManager.currentTheme.accentColor)
                } else {
                    Text("No Wallet Loaded")
                        .foregroundColor(.red)
                }

                Spacer()
            }
        }
    }

    #if canImport(UIKit)
        func generateQRCode(from string: String) -> UIImage {
            let context = CIContext()
            let filter = CIFilter.qrCodeGenerator()
            filter.message = Data(string.utf8)

            if let outputImage = filter.outputImage {
                if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
                    return UIImage(cgImage: cgimg)
                }
            }
            return UIImage(systemName: "xmark.circle") ?? UIImage()
        }
    #else
        func generateQRCode(from _: String) -> some View {
            Image(systemName: "qrcode")
        }
    #endif
}
