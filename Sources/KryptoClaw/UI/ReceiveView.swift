import SwiftUI
#if canImport(UIKit)
    import UIKit
#endif
import CoreImage.CIFilterBuiltins

struct ReceiveView: View {
    let chain: Chain
    @EnvironmentObject var wsm: WalletStateManager
    @EnvironmentObject var themeManager: ThemeManager
    @State private var copied: Bool = false
    
    init(chain: Chain = .ethereum) {
        self.chain = chain
    }

    var body: some View {
        let theme = themeManager.currentTheme
        
        ZStack {
            Color.clear
                .themedContainer(theme: theme, showPattern: true, applyAnimation: true)
                .ignoresSafeArea()

            VStack(spacing: theme.spacing2XL) {
                Text("Receive \(chain.displayName)")
                    .font(theme.font(style: .title2))
                    .foregroundColor(theme.textPrimary)
                    .padding(.top, theme.spacing2XL + theme.spacingS)

                if let address = wsm.currentAddress {
                    VStack(spacing: theme.spacingXL) {
                        #if canImport(UIKit)
                            Image(uiImage: generateQRCode(from: address))
                                .resizable()
                                .interpolation(.none)
                                .scaledToFit()
                                .frame(width: 200, height: 200)
                                .padding()
                                .background(theme.qrBackgroundColor)
                                .cornerRadius(theme.cornerRadius)
                        #else
                            Image(systemName: "qrcode")
                                .font(.system(size: 200))
                                .padding()
                                .background(theme.qrBackgroundColor)
                                .cornerRadius(theme.cornerRadius)
                        #endif

                        Text("Scan to send \(chain.nativeCurrency)")
                            .font(theme.font(style: .caption))
                            .foregroundColor(theme.textSecondary)
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
                                .font(theme.addressFont)
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .foregroundColor(theme.textPrimary)

                            Image(systemName: copied ? "checkmark" : "doc.on.doc")
                                .foregroundColor(copied ? theme.successColor : theme.accentColor)
                        }
                        .padding()
                        .background(theme.backgroundSecondary)
                        .cornerRadius(theme.cornerRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: theme.cornerRadius)
                                .stroke(theme.borderColor, lineWidth: 1)
                        )
                    }
                    .padding(.horizontal)

                    ShareLink(item: address, subject: Text("My Wallet Address"), message: Text("Here is my wallet address: \(address)")) {
                        Label("Share Address", systemImage: "square.and.arrow.up")
                    }
                    .foregroundColor(theme.accentColor)
                } else {
                    Text("No Wallet Loaded")
                        .foregroundColor(theme.errorColor)
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
