import Combine
import Foundation
#if canImport(UIKit)
    import UIKit
#endif

/// A utility to enhance security by automatically clearing the clipboard
/// if it contains sensitive data or addresses after a short timeout.
/// Note: On iOS, background clipboard access is restricted, so this logic mostly applies
/// while the app is active or when returning to foreground.
public class ClipboardGuard: ObservableObject {
    private var timer: Timer?
    private var mockClipboardContent: String?

    public init() {}

    /// Call this when the user copies an address or sensitive data
    public func protectClipboard(content: String, timeout: TimeInterval = 60.0, isSensitive: Bool = false) {
        #if os(iOS)
            UIPasteboard.general.string = content
        #else
            mockClipboardContent = content
        #endif

        // Security policy: Sensitive data (seeds/keys) cleared in 10s, addresses in 60s
        timer?.invalidate()

        let clearTime = isSensitive ? 10.0 : timeout // Clear sensitive info in 10s

        timer = Timer.scheduledTimer(withTimeInterval: clearTime, repeats: false) { [weak self] _ in
            self?.clearClipboard()
        }
    }

    public func clearClipboard() {
        #if os(iOS)
            UIPasteboard.general.string = ""
        #else
            mockClipboardContent = nil
        #endif
        KryptoLogger.shared.log(level: .info, category: .boundary, message: "Clipboard wiped for security", metadata: ["module": "ClipboardGuard"])
    }

    // Test Helper
    public func getClipboardContent() -> String? {
        #if os(iOS)
            return UIPasteboard.general.string
        #else
            return mockClipboardContent
        #endif
    }
}
