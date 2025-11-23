import SwiftUI

struct ReceiveView: View {
    @EnvironmentObject var wsm: WalletStateManager
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        ZStack {
            themeManager.currentTheme.backgroundMain.ignoresSafeArea()

            VStack {
                Text("Receive")
                    .font(themeManager.currentTheme.font(style: .largeTitle))
                    .foregroundColor(themeManager.currentTheme.textPrimary)

                // <<<<<<!!!!!JULES!!!!!!>>>>>>>>
                // [MISSING FEATURE - CRITICAL]
                // 1. Functionality: This view is entirely missing.
                //    - Must generate a QR Code for the current address (`wsm.currentAddress`).
                //    - "Copy to Clipboard" button (with the ClipboardGuard check).
                //    - Share Sheet integration (iOS standard).
                // 2. UI/UX:
                //    - The QR code should be scannable but styled (e.g., custom colors if possible, or standard black/white for reliability).
                //    - Should display the network clearly (e.g., "Send only ERC-20 tokens to this address").
                Text("FEATURE NOT IMPLEMENTED")
                    .foregroundColor(.red)
            }
        }
    }
}
