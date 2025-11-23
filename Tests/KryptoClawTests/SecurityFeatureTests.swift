import XCTest
@testable import KryptoClaw

final class SecurityFeatureTests: XCTestCase {

    var poisoningDetector: AddressPoisoningDetector!
    var clipboardGuard: ClipboardGuard!

    override func setUp() {
        super.setUp()
        poisoningDetector = AddressPoisoningDetector()
        clipboardGuard = ClipboardGuard()
    }

    // MARK: - Address Poisoning Tests

    func testAddressPoisoningDetection() {
        let trustedAddress = "0x1234abcd...5678" // Shortened for test logic simplicity if detector supports it, or full
        // The detector logic uses strings. Let's use full strings for accuracy.
        let legitimate = "0x1234567890abcdef1234567890abcdef5678"
        let legitimateHistory = [legitimate]

        // 1. Exact match -> Safe
        let statusSafe = poisoningDetector.analyze(targetAddress: legitimate, safeHistory: legitimateHistory)
        if case .safe = statusSafe {
            // Pass
        } else {
            XCTFail("Legitimate address flagged as poison")
        }

        // 2. Poison Match (Same start/end, different middle) -> Warning
        // Start: 0x1234, End: 5678
        let poison = "0x123400000000000000000000000000005678"
        let statusPoison = poisoningDetector.analyze(targetAddress: poison, safeHistory: legitimateHistory)

        if case .potentialPoison(let reason) = statusPoison {
            XCTAssertTrue(reason.contains("looks similar"), "Warning message should explain the risk")
        } else {
            XCTFail("Poison address NOT flagged! Security failure.")
        }

        // 3. Totally different -> Safe (Unknown but not spoofing)
        let stranger = "0x9999............................9999"
        let statusStranger = poisoningDetector.analyze(targetAddress: stranger, safeHistory: legitimateHistory)
        if case .safe = statusStranger {
            // Pass
        } else {
            XCTFail("Unrelated address flagged as poison")
        }
    }

    // MARK: - Clipboard Guard Tests

    func testClipboardClearing() {
        let sensitive = "SEED PHRASE DETECTED"

        // 1. Set Clipboard
        clipboardGuard.protectClipboard(content: sensitive, timeout: 0.1, isSensitive: true)
        XCTAssertEqual(clipboardGuard.getClipboardContent(), sensitive)

        // 2. Wait for timeout
        let expectation = XCTestExpectation(description: "Clipboard Cleared")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            if self.clipboardGuard.getClipboardContent() == nil {
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 1.0)
    }
}
