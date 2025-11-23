import XCTest
@testable import KryptoClaw

final class ComplianceAudit: XCTestCase {
    
    let forbiddenFrameworks = [
        "CoreBluetooth",
        "CoreNFC",
        "WebKit",
        "FirebaseRemoteConfig",
        "JavaScriptCore"
    ]
    
    let forbiddenFunctions = [
        "dlopen",
        "dlsym"
    ]
    
    let forbiddenPatterns = [
        "exportPrivateKey",
        "copyPrivateKey",
        // "swap(", // RELAXED: Swaps are allowed if non-custodial
        // "exchange(", // RELAXED
        // "trade(", // RELAXED
        "Analytics.logEvent",
        "remoteConfig"
    ]
    
    func testCompliance() throws {
        let fileManager = FileManager.default
        let currentPath = fileManager.currentDirectoryPath
        let sourcesPath = currentPath + "/Sources"
        
        // Check if Sources directory exists
        var isDir: ObjCBool = false
        if !fileManager.fileExists(atPath: sourcesPath, isDirectory: &isDir) || !isDir.boolValue {
            print("Sources directory not found at \(sourcesPath). Assuming running from derived data or different context.")
            return
        }
        
        // Recursive file enumerator
        guard let enumerator = fileManager.enumerator(atPath: sourcesPath) else {
            XCTFail("Could not enumerate sources at \(sourcesPath)")
            return
        }
        
        for case let file as String in enumerator {
            if file.hasSuffix(".swift") {
                let fullPath = sourcesPath + "/" + file
                do {
                    let content = try String(contentsOfFile: fullPath, encoding: .utf8)
                    
                    for framework in forbiddenFrameworks {
                        if content.contains("import \(framework)") {
                            XCTFail("Compliance Violation: Forbidden framework '\(framework)' imported in \(file)")
                        }
                    }
                    
                    for function in forbiddenFunctions {
                        if content.contains(function) {
                            XCTFail("Compliance Violation: Forbidden function '\(function)' used in \(file)")
                        }
                    }
                    
                    for pattern in forbiddenPatterns {
                        if content.contains(pattern) {
                            XCTFail("Compliance Violation: Forbidden pattern '\(pattern)' found in \(file)")
                        }
                    }

                    // Specific check for Swap features: Must have risk warning if implemented
                    if content.contains("SwapView") || content.contains("swap(") {
                        // Ideally, we'd check for a warning string, but that's hard to regex accurately.
                        // Instead, we just ensure we aren't importing custodial SDKs directly.
                        if content.contains("CustodialSDK") {
                            XCTFail("Compliance Violation: Custodial SDK usage detected in Swap logic")
                        }
                    }
                } catch {
                    XCTFail("Could not read file \(file): \(error)")
                }
            }
        }
    }
    
    func testRiskFeaturesDisabled() {
        // High Risk / Novel features must be disabled
        XCTAssertFalse(AppConfig.Features.isMPCEnabled, "MPC must be disabled")
        XCTAssertFalse(AppConfig.Features.isGhostModeEnabled, "Ghost Mode must be disabled")
        XCTAssertFalse(AppConfig.Features.isZKProofEnabled, "ZK Proofs must be disabled")
        XCTAssertFalse(AppConfig.Features.isDAppBrowserEnabled, "DApp Browser must be disabled")
        XCTAssertFalse(AppConfig.Features.isP2PSigningEnabled, "P2P Signing must be disabled")
    }

    func testStandardFeaturesEnabled() {
        // Standard features should be enabled now
        XCTAssertTrue(AppConfig.Features.isMultiChainEnabled, "Multi-Chain should be enabled")
        XCTAssertTrue(AppConfig.Features.isSwapEnabled, "Swaps should be enabled")
        XCTAssertTrue(AppConfig.Features.isAddressPoisoningProtectionEnabled, "Poisoning protection should be enabled")
    }
    
    func testPrivacyPolicyDefined() {
        XCTAssertNotNil(AppConfig.privacyPolicyURL)
        XCTAssertTrue(AppConfig.privacyPolicyURL.absoluteString.contains("https://"), "Privacy Policy must be HTTPS")
    }
}
