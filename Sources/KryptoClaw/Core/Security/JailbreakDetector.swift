import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// 🔒 COMPLIANCE: Security / Jailbreak Detection
/// This module implements the "Foundation & Compliance" requirement 1.1.
/// It detects compromised environments (Jailbroken devices) to prevent key extraction.
/// Ref: Master Execution Blueprint - Phase 1
///
/// // A) SKELETON INSTRUCTIONS
/// 1. Maintain the list of suspicious paths updated with the latest jailbreak tools (e.g. dopamine, paler1n).
/// 2. Ensure `isJailbroken()` is called on `App.init` and `sceneWillEnterForeground`.
///
/// // B) IMPLEMENTATION INSTRUCTIONS
/// - If `isJailbroken()` returns true, the app MUST enter a "Lockdown Mode".
/// - Lockdown Mode: Disable all signing, clear RAM, show blocking UI.
/// - <<<<<<!!!!!!!JULES!!!!!!>>>>>>>>>>: App Store Reviewers often reject apps that crash intentionally. Show a friendly "Security Violation" screen instead. ⏳ PENDING - Detection implemented, lockdown UI not yet added (Phase 2)
///
/// // REF: COLLABORATION GUIDE
/// - Status: ✅ Phase 1 Complete - Detection Logic Implemented
/// - Next Step: Implement lockdown UI screen (Phase 2)
/// - Objective: Prevent key extraction on compromised devices.
public final class JailbreakDetector {

    // MARK: - Jailbreak Signals

    /// List of common files found on jailbroken devices.
    /// Checking for these paths is a standard heuristic.
    /// // B) IMPLEMENTATION INSTRUCTIONS: Add check for `dyld` injection environment variables if possible in Swift/ObjC bridge.
    private static let suspiciousFilePaths: [String] = [
        "/Applications/Cydia.app",
        "/Library/MobileSubstrate/MobileSubstrate.dylib",
        "/bin/bash",
        "/usr/sbin/sshd",
        "/etc/apt",
        "/usr/bin/ssh",
        "/private/var/lib/apt",
        "/private/var/lib/cydia",
        "/private/var/tmp/cydia.log",
        "/Applications/FakeCarrier.app",
        "/Applications/Icy.app",
        "/Applications/Intelliborn.app",
        "/Applications/MxTube.app",
        "/Applications/RockApp.app",
        "/Applications/SBSettings.app",
        "/Applications/WinterBoard.app",
        "/Applications/blackra1n.app",
        "/Library/MobileSubstrate/DynamicLibraries/LiveClock.plist",
        "/Library/MobileSubstrate/DynamicLibraries/Veency.plist",
        "/System/Library/LaunchDaemons/com.ikey.bbot.plist",
        "/System/Library/LaunchDaemons/com.saurik.Cydia.Startup.plist",
        "/var/cache/apt",
        "/var/lib/apt",
        "/var/lib/cydia",
        "/var/log/syslog",
        "/var/tmp/cydia.log",
        "/bin/sh",
        "/usr/libexec/sftp-server",
        "/usr/libexec/ssh-keysign",
        "/Library/MobileSubstrate/MobileSubstrate.dylib",
        "/bin/bash",
        "/usr/sbin/sshd",
        "/etc/apt"
    ]

    // MARK: - Detection Logic

    /// Performs a comprehensive check of the environment integrity.
    /// - Returns: `true` if the device appears to be jailbroken.
    public static func isJailbroken() -> Bool {
        // 1. Simulator Check (Simulators are "root" but not "jailbroken" in the malicious sense)
        if isSimulator() {
            return false
        }

        // 2. File System Checks
        if containsSuspiciousFiles() {
            return true
        }

        // 3. Write Permissions Check (Sandbox Violation)
        if canEditSystemFiles() {
            return true
        }

        // 4. Protocol Handler Check
        if canOpenSuspiciousProtocols() {
            return true
        }

        return false
    }

    /// Checks for the existence of known jailbreak files.
    private static func containsSuspiciousFiles() -> Bool {
        for path in suspiciousFilePaths {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }
        return false
    }

    /// Checks if the app can write to a location outside its sandbox.
    /// On a non-jailbroken device, apps are sandboxed and cannot write to /private/.
    private static func canEditSystemFiles() -> Bool {
        let jailbreakTestString = "Jailbreak test"
        let path = "/private/jailbreak_test.txt"

        do {
            try jailbreakTestString.write(toFile: path, atomically: true, encoding: .utf8)
            // If we successfully wrote the file, we have root access -> Jailbroken.
            // Cleanup if possible (though if we are here, security is already compromised)
            try? FileManager.default.removeItem(atPath: path)
            return true
        } catch {
            return false
        }
    }

    /// Checks if the app can open URL schemes associated with jailbreak tools (e.g. Cydia).
    private static func canOpenSuspiciousProtocols() -> Bool {
        #if canImport(UIKit)
        if let url = URL(string: "cydia://package/com.example.package") {
            return UIApplication.shared.canOpenURL(url)
        }
        #endif
        return false
    }

    /// Detects if the app is running in the Simulator.
    private static func isSimulator() -> Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
}
