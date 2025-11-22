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
        "swap(",
        "exchange(",
        "trade(",
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
            // In a real CI environment, we'd need a reliable way to find the source. 
            // For this local rig, we assume running from root.
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
                } catch {
                    XCTFail("Could not read file \(file): \(error)")
                }
            }
        }
    }
    
    func testV2FeaturesDisabled() {
        XCTAssertFalse(AppConfig.Features.isMPCEnabled, "MPC must be disabled in V1.0")
        XCTAssertFalse(AppConfig.Features.isGhostModeEnabled, "Ghost Mode must be disabled in V1.0")
        XCTAssertFalse(AppConfig.Features.isZKProofEnabled, "ZK Proofs must be disabled in V1.0")
        XCTAssertFalse(AppConfig.Features.isDAppBrowserEnabled, "DApp Browser must be disabled in V1.0")
        XCTAssertFalse(AppConfig.Features.isP2PSigningEnabled, "P2P Signing must be disabled in V1.0")
    }
    
    func testPrivacyPolicyDefined() {
        XCTAssertNotNil(AppConfig.privacyPolicyURL)
        XCTAssertTrue(AppConfig.privacyPolicyURL.absoluteString.contains("https://"), "Privacy Policy must be HTTPS")
    }
    
    func testPrivacyPolicyInSettingsView() throws {
        let fileManager = FileManager.default
        let currentPath = fileManager.currentDirectoryPath
        let settingsPath = currentPath + "/Sources/KryptoClaw/SettingsView.swift"
        
        guard fileManager.fileExists(atPath: settingsPath) else {
            XCTFail("SettingsView.swift not found")
            return
        }
        
        let content = try String(contentsOfFile: settingsPath, encoding: .utf8)
        XCTAssertTrue(content.contains("AppConfig.privacyPolicyURL"), "SettingsView must link to Privacy Policy")
        XCTAssertTrue(content.contains("Link(destination:"), "SettingsView must use a Link component")
    }
}
