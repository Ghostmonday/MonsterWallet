import Foundation
import Combine

/// A utility to enhance security by automatically clearing the clipboard
/// if it contains sensitive data or addresses after a short timeout.
/// Note: On iOS, background clipboard access is restricted, so this logic mostly applies
/// while the app is active or when returning to foreground.
public class ClipboardGuard: ObservableObject {

    private var timer: Timer?
    // In a real iOS app, we'd use UIPasteboard.general. Here we mock for logic testing.
    private var mockClipboardContent: String?

    public init() {}

    /// Call this when the user copies an address or sensitive data
    public func protectClipboard(content: String, timeout: TimeInterval = 60.0, isSensitive: Bool = false) {
        // In real app: UIPasteboard.general.string = content
        self.mockClipboardContent = content

        // If it's highly sensitive (like a seed phrase or private key - which we should NEVER copy anyway),
        // we clear it much faster or immediately.
        // Standard policy: Don't allow copying seeds.
        // If it's an address, clear after 60s to prevent accidental pasting later.

        timer?.invalidate()

        let clearTime = isSensitive ? 10.0 : timeout // Clear sensitive info in 10s

        timer = Timer.scheduledTimer(withTimeInterval: clearTime, repeats: false) { [weak self] _ in
            self?.clearClipboard()
        }
    }

    public func clearClipboard() {
        // In real app: UIPasteboard.general.string = ""
        print("[ClipboardGuard] Clipboard wiped for security.")
        self.mockClipboardContent = nil
    }

    // Test Helper
    public func getClipboardContent() -> String? {
        return mockClipboardContent
    }
}
