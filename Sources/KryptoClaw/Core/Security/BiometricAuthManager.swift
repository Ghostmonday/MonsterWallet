// MODULE: BiometricAuthManager
// VERSION: 1.0.0
// PURPOSE: Hardware-backed biometric authentication with Secure Enclave P-256 signing

import Foundation
import LocalAuthentication
import CryptoKit
import Security

// MARK: - Error Types

/// Comprehensive error types for biometric authentication failures
public enum BiometricError: Error, LocalizedError, Sendable {
    case notAvailable
    case notEnrolled
    case lockout(permanent: Bool)
    case canceled
    case passcodeNotSet
    case invalidated
    case systemCancel
    case appCancel
    case biometryChanged
    case keyGenerationFailed(underlying: Error?)
    case signingFailed(underlying: Error?)
    case keyNotFound
    case accessControlFailed
    case unknown(underlying: Error?)
    
    public var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "Biometric authentication is not available on this device."
        case .notEnrolled:
            return "No biometric authentication is enrolled. Please set up Face ID or Touch ID in Settings."
        case .lockout(let permanent):
            return permanent 
                ? "Biometrics are permanently disabled. Please use your device passcode."
                : "Too many failed attempts. Please try again later or use your passcode."
        case .canceled:
            return "Authentication was canceled."
        case .passcodeNotSet:
            return "A device passcode is required for secure authentication."
        case .invalidated:
            return "The authentication context has been invalidated."
        case .systemCancel:
            return "Authentication was interrupted by the system."
        case .appCancel:
            return "Authentication was canceled by the application."
        case .biometryChanged:
            return "Biometric enrollment has changed. Please re-authenticate with your passcode."
        case .keyGenerationFailed(let error):
            return "Failed to generate secure key: \(error?.localizedDescription ?? "Unknown error")"
        case .signingFailed(let error):
            return "Failed to sign data: \(error?.localizedDescription ?? "Unknown error")"
        case .keyNotFound:
            return "Secure signing key not found. Please set up authentication again."
        case .accessControlFailed:
            return "Failed to configure access control for secure operations."
        case .unknown(let error):
            return "An unknown error occurred: \(error?.localizedDescription ?? "Unknown")"
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .notEnrolled, .passcodeNotSet:
            return "Open Settings > Face ID & Passcode to configure."
        case .lockout(let permanent):
            return permanent 
                ? "Enter your device passcode to reset biometric authentication."
                : "Wait a moment before trying again, or use your passcode."
        case .biometryChanged:
            return "Your biometric data has changed. Re-verify your identity."
        default:
            return nil
        }
    }
    
    public var canFallbackToPasscode: Bool {
        switch self {
        case .lockout, .biometryChanged, .notEnrolled:
            return true
        default:
            return false
        }
    }
}

/// Result of a biometric authentication attempt
public struct BiometricResult: Sendable {
    public let success: Bool
    public let didFallbackToPasscode: Bool
    public let evaluatedBiometryType: LABiometryType
    
    public init(success: Bool, didFallbackToPasscode: Bool = false, evaluatedBiometryType: LABiometryType = .none) {
        self.success = success
        self.didFallbackToPasscode = didFallbackToPasscode
        self.evaluatedBiometryType = evaluatedBiometryType
    }
}

/// ECDSA Signature wrapper with DER encoding support
public struct ECDSASignature: Sendable {
    public let rawSignature: Data
    public let derEncoded: Data
    
    public init(rawSignature: Data, derEncoded: Data) {
        self.rawSignature = rawSignature
        self.derEncoded = derEncoded
    }
    
    /// Hex string representation of the raw signature
    public var hexString: String {
        rawSignature.map { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - BiometricAuthManager Actor

/// Thread-safe actor for managing biometric authentication and Secure Enclave signing.
/// 
/// This actor provides:
/// - Hardware-backed P-256 key generation in the Secure Enclave
/// - Biometric-protected signing operations
/// - Automatic FaceID/TouchID prompts during signing
/// - Comprehensive error handling for all edge cases
///
/// The private key is generated inside the Secure Enclave and is **never exportable**.
@available(iOS 15.0, macOS 12.0, *)
public actor BiometricAuthManager {
    
    // MARK: - Properties
    
    /// Tag for the Secure Enclave signing key
    private let signingKeyTag: String
    
    /// Cached LAContext for policy evaluation
    private var cachedContext: LAContext?
    
    /// Last known biometry type
    private var lastBiometryType: LABiometryType = .none
    
    /// Whether the Secure Enclave is available
    public var isSecureEnclaveAvailable: Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        return true
        #endif
    }
    
    // MARK: - Initialization
    
    /// Initialize the BiometricAuthManager with a unique key tag
    /// - Parameter signingKeyTag: Unique identifier for the signing key (default: com.kryptoclaw.signing.biometric)
    public init(signingKeyTag: String = "com.kryptoclaw.signing.biometric") {
        self.signingKeyTag = signingKeyTag
    }
    
    // MARK: - Biometry Availability
    
    /// Check if biometric authentication is available
    /// - Returns: Tuple of availability status and biometry type
    public func checkAvailability() async throws -> (available: Bool, type: LABiometryType) {
        let context = LAContext()
        var error: NSError?
        
        let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        lastBiometryType = context.biometryType
        
        if canEvaluate {
            return (true, context.biometryType)
        }
        
        // Map LAError to BiometricError
        if let laError = error as? LAError {
            throw mapLAError(laError)
        }
        
        return (false, .none)
    }
    
    /// Get a human-readable name for the current biometry type
    public func biometryTypeName() async -> String {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        
        switch context.biometryType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .opticID:
            return "Optic ID"
        case .none:
            return "None"
        @unknown default:
            return "Biometric"
        }
    }
    
    // MARK: - Simple Authentication
    
    /// Authenticate the user with biometrics
    /// - Parameters:
    ///   - reason: The localized reason string shown to the user
    ///   - allowFallback: Whether to allow device passcode as fallback
    /// - Returns: BiometricResult indicating success/failure and method used
    public func authenticate(
        reason: String,
        allowFallback: Bool = true
    ) async throws -> BiometricResult {
        let context = LAContext()
        context.localizedFallbackTitle = allowFallback ? "Use Passcode" : ""
        context.localizedCancelTitle = "Cancel"
        
        let policy: LAPolicy = allowFallback 
            ? .deviceOwnerAuthentication 
            : .deviceOwnerAuthenticationWithBiometrics
        
        var authError: NSError?
        guard context.canEvaluatePolicy(policy, error: &authError) else {
            if let laError = authError as? LAError {
                throw mapLAError(laError)
            }
            throw BiometricError.notAvailable
        }
        
        do {
            let success = try await context.evaluatePolicy(policy, localizedReason: reason)
            
            // Determine if fallback was used (heuristic based on context state)
            let usedFallback = context.evaluatedPolicyDomainState == nil && allowFallback
            
            return BiometricResult(
                success: success,
                didFallbackToPasscode: usedFallback,
                evaluatedBiometryType: context.biometryType
            )
        } catch let error as LAError {
            throw mapLAError(error)
        } catch {
            throw BiometricError.unknown(underlying: error)
        }
    }
    
    // MARK: - Secure Enclave Key Management
    
    /// Generate a new P-256 key pair in the Secure Enclave
    /// - Parameter requireBiometry: Require biometric authentication for key usage
    /// - Returns: The public key data
    /// - Throws: BiometricError if key generation fails
    public func generateSecureEnclaveKey(requireBiometry: Bool = true) async throws -> Data {
        // Delete any existing key first
        try? await deleteSecureEnclaveKey()
        
        // Create access control flags
        var accessFlags: SecAccessControlCreateFlags = [.privateKeyUsage]
        if requireBiometry {
            #if !targetEnvironment(simulator)
            accessFlags.insert(.biometryCurrentSet)
            #endif
        }
        
        var accessControlError: Unmanaged<CFError>?
        guard let accessControl = SecAccessControlCreateWithFlags(
            kCFAllocatorDefault,
            kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
            accessFlags,
            &accessControlError
        ) else {
            throw BiometricError.accessControlFailed
        }
        
        // Build key generation attributes
        var attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits as String: 256,
            kSecPrivateKeyAttrs as String: [
                kSecAttrIsPermanent as String: true,
                kSecAttrApplicationTag as String: signingKeyTag.data(using: .utf8)!,
                kSecAttrAccessControl as String: accessControl
            ]
        ]
        
        #if !targetEnvironment(simulator)
        // Use Secure Enclave on real devices
        attributes[kSecAttrTokenID as String] = kSecAttrTokenIDSecureEnclave
        #endif
        
        var keyError: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &keyError) else {
            let error = keyError?.takeRetainedValue() as Error?
            throw BiometricError.keyGenerationFailed(underlying: error)
        }
        
        // Extract public key
        guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
            throw BiometricError.keyGenerationFailed(underlying: nil)
        }
        
        var publicKeyError: Unmanaged<CFError>?
        guard let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, &publicKeyError) as Data? else {
            let error = publicKeyError?.takeRetainedValue() as Error?
            throw BiometricError.keyGenerationFailed(underlying: error)
        }
        
        return publicKeyData
    }
    
    /// Delete the Secure Enclave signing key
    public func deleteSecureEnclaveKey() async throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: signingKeyTag.data(using: .utf8)!,
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw BiometricError.unknown(underlying: NSError(domain: NSOSStatusErrorDomain, code: Int(status)))
        }
    }
    
    /// Check if a signing key exists
    public func hasSigningKey() async -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: signingKeyTag.data(using: .utf8)!,
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecReturnRef as String: false
        ]
        
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    // MARK: - Signing Operations
    
    /// Sign data using the Secure Enclave key with biometric authentication
    /// 
    /// This method will automatically trigger a FaceID/TouchID prompt.
    /// The private key never leaves the Secure Enclave.
    ///
    /// - Parameter data: The data to sign
    /// - Returns: ECDSA signature
    /// - Throws: BiometricError if signing fails or authentication is denied
    public func sign(data: Data) async throws -> ECDSASignature {
        // Retrieve the private key (will trigger biometric auth due to access control)
        let privateKey = try await retrieveSigningKey()
        
        // Verify the key can sign
        guard SecKeyIsAlgorithmSupported(privateKey, .sign, .ecdsaSignatureMessageX962SHA256) else {
            throw BiometricError.signingFailed(underlying: nil)
        }
        
        // Create the signature
        var signingError: Unmanaged<CFError>?
        guard let signature = SecKeyCreateSignature(
            privateKey,
            .ecdsaSignatureMessageX962SHA256,
            data as CFData,
            &signingError
        ) as Data? else {
            let error = signingError?.takeRetainedValue()
            
            // Check if it's a biometric failure
            if let error = error {
                let nsError = error as Error as NSError
                if nsError.domain == LAErrorDomain {
                    throw mapLAError(LAError(_nsError: nsError))
                }
            }
            
            throw BiometricError.signingFailed(underlying: error as Error?)
        }
        
        // The signature is in DER format, also extract raw for convenience
        let rawSignature = extractRawSignature(from: signature)
        
        return ECDSASignature(rawSignature: rawSignature, derEncoded: signature)
    }
    
    /// Sign a message hash (pre-hashed data)
    /// - Parameter hash: The 32-byte SHA256 hash to sign
    /// - Returns: ECDSA signature
    public func signHash(_ hash: Data) async throws -> ECDSASignature {
        guard hash.count == 32 else {
            throw BiometricError.signingFailed(underlying: NSError(
                domain: "BiometricAuthManager",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Hash must be exactly 32 bytes"]
            ))
        }
        
        let privateKey = try await retrieveSigningKey()
        
        var signingError: Unmanaged<CFError>?
        guard let signature = SecKeyCreateSignature(
            privateKey,
            .ecdsaSignatureDigestX962SHA256,
            hash as CFData,
            &signingError
        ) as Data? else {
            let error = signingError?.takeRetainedValue() as Error?
            throw BiometricError.signingFailed(underlying: error)
        }
        
        let rawSignature = extractRawSignature(from: signature)
        return ECDSASignature(rawSignature: rawSignature, derEncoded: signature)
    }
    
    // MARK: - Private Helpers
    
    /// Retrieve the signing key from keychain (triggers biometric auth)
    private func retrieveSigningKey() async throws -> SecKey {
        // Create a context with prompt
        let context = LAContext()
        context.localizedReason = "Authorize transaction signing"
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: signingKeyTag.data(using: .utf8)!,
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecReturnRef as String: true,
            kSecUseAuthenticationContext as String: context
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        switch status {
        case errSecSuccess:
            guard let key = item else {
                throw BiometricError.keyNotFound
            }
            // swiftlint:disable:next force_cast
            return (key as! SecKey)
            
        case errSecItemNotFound:
            throw BiometricError.keyNotFound
            
        case errSecUserCanceled:
            throw BiometricError.canceled
            
        case errSecAuthFailed:
            throw BiometricError.lockout(permanent: false)
            
        default:
            throw BiometricError.unknown(underlying: NSError(domain: NSOSStatusErrorDomain, code: Int(status)))
        }
    }
    
    /// Extract raw R||S signature from DER encoding
    private func extractRawSignature(from derSignature: Data) -> Data {
        // DER signature format: 0x30 [length] 0x02 [r_length] [r] 0x02 [s_length] [s]
        var signature = derSignature
        
        guard signature.count > 6,
              signature.removeFirst() == 0x30 else {
            return derSignature
        }
        
        // Skip length byte(s)
        let seqLength = signature.removeFirst()
        if seqLength > 0x80 {
            let lenBytes = Int(seqLength & 0x7F)
            signature = signature.dropFirst(lenBytes)
        }
        
        guard signature.removeFirst() == 0x02 else {
            return derSignature
        }
        
        var rLength = Int(signature.removeFirst())
        // Skip leading zero if present (for positive number representation)
        if signature.first == 0x00 && rLength > 32 {
            signature = signature.dropFirst()
            rLength -= 1
        }
        
        let r = signature.prefix(rLength)
        signature = signature.dropFirst(rLength)
        
        guard signature.removeFirst() == 0x02 else {
            return derSignature
        }
        
        var sLength = Int(signature.removeFirst())
        if signature.first == 0x00 && sLength > 32 {
            signature = signature.dropFirst()
            sLength -= 1
        }
        
        let s = signature.prefix(sLength)
        
        // Pad R and S to 32 bytes each
        var raw = Data(count: 64)
        let rPadded = Data(count: 32 - r.count) + r
        let sPadded = Data(count: 32 - s.count) + s
        
        raw.replaceSubrange(0..<32, with: rPadded)
        raw.replaceSubrange(32..<64, with: sPadded)
        
        return raw
    }
    
    /// Map LAError to BiometricError
    private func mapLAError(_ error: LAError) -> BiometricError {
        switch error.code {
        case .biometryNotAvailable, .touchIDNotAvailable:
            return .notAvailable
        case .biometryNotEnrolled, .touchIDNotEnrolled:
            return .notEnrolled
        case .biometryLockout, .touchIDLockout:
            return .lockout(permanent: false)
        case .userCancel:
            return .canceled
        case .passcodeNotSet:
            return .passcodeNotSet
        case .invalidContext:
            return .invalidated
        case .systemCancel:
            return .systemCancel
        case .appCancel:
            return .appCancel
        case .authenticationFailed:
            return .lockout(permanent: false)
        case .userFallback:
            return .canceled
        case .notInteractive:
            return .unknown(underlying: error)
        #if os(iOS)
        case .biometryNotPaired, .biometryDisconnected, .invalidDimensions:
            return .notAvailable
        #elseif os(macOS)
        case .watchNotAvailable, .biometryNotPaired, .biometryDisconnected, .invalidDimensions:
            return .notAvailable
        #endif
        @unknown default:
            return .unknown(underlying: error)
        }
    }
}

// MARK: - Convenience Extensions

@available(iOS 15.0, macOS 12.0, *)
extension BiometricAuthManager {
    
    /// Quick authentication with default settings
    public func quickAuth() async throws -> Bool {
        let result = try await authenticate(reason: "Authenticate to continue", allowFallback: true)
        return result.success
    }
    
    /// Sign a string message
    public func sign(message: String) async throws -> ECDSASignature {
        guard let data = message.data(using: .utf8) else {
            throw BiometricError.signingFailed(underlying: nil)
        }
        return try await sign(data: data)
    }
    
    /// Get the public key if it exists
    public func getPublicKey() async throws -> Data? {
        guard await hasSigningKey() else { return nil }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: signingKeyTag.data(using: .utf8)!,
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecReturnRef as String: true
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status == errSecSuccess, let privateKey = item else {
            return nil
        }
        
        // swiftlint:disable:next force_cast
        guard let publicKey = SecKeyCopyPublicKey(privateKey as! SecKey) else {
            return nil
        }
        
        var error: Unmanaged<CFError>?
        guard let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, &error) as Data? else {
            return nil
        }
        
        return publicKeyData
    }
}

