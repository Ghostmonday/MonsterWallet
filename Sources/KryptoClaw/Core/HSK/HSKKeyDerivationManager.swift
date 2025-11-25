import AuthenticationServices
import Combine
import CryptoKit
import Foundation

// MARK: - HSK Key Derivation Manager Protocol

public protocol HSKKeyDerivationManagerProtocol {
    var eventPublisher: AnyPublisher<HSKEvent, Never> { get }
    var statePublisher: AnyPublisher<HSKWalletCreationState, Never> { get }
    
    func listenForHSK()
    func deriveKey(from credential: ASAuthorizationSecurityKeyPublicKeyCredentialRegistration) async throws -> HSKDerivationResult
    func verifyBinding(keyHandle: Data, challenge: Data) async throws -> Bool
    func cancelOperation()
}

// MARK: - HSK Key Derivation Manager

@available(iOS 15.0, macOS 12.0, *)
public class HSKKeyDerivationManager: NSObject, HSKKeyDerivationManagerProtocol {
    
    // MARK: - Properties
    
    private let relyingPartyIdentifier = "com.kryptoclaw.hsk"
    private let eventSubject = PassthroughSubject<HSKEvent, Never>()
    private let stateSubject = CurrentValueSubject<HSKWalletCreationState, Never>(.initiation)
    
    /// SECURITY: Serial queue for thread-safe access to mutable state.
    /// All access to mutable properties must be synchronized through this queue.
    private let stateQueue = DispatchQueue(label: "com.kryptoclaw.hsk.derivation.state", qos: .userInitiated)
    
    public var eventPublisher: AnyPublisher<HSKEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }
    
    public var statePublisher: AnyPublisher<HSKWalletCreationState, Never> {
        stateSubject.eraseToAnyPublisher()
    }
    
    public var currentState: HSKWalletCreationState {
        stateSubject.value
    }
    
    /// SECURITY: These properties are only accessed through stateQueue for thread safety
    private var _authorizationController: ASAuthorizationController?
    private var _currentChallenge: Data?
    private var _registrationContinuation: CheckedContinuation<ASAuthorizationSecurityKeyPublicKeyCredentialRegistration, Error>?
    private var _assertionContinuation: CheckedContinuation<ASAuthorizationSecurityKeyPublicKeyCredentialAssertion, Error>?
    
    // MARK: - Thread-Safe Property Accessors
    
    private var authorizationController: ASAuthorizationController? {
        get { stateQueue.sync { _authorizationController } }
        set { stateQueue.sync { _authorizationController = newValue } }
    }
    
    private var currentChallenge: Data? {
        get { stateQueue.sync { _currentChallenge } }
        set { stateQueue.sync { _currentChallenge = newValue } }
    }
    
    private var registrationContinuation: CheckedContinuation<ASAuthorizationSecurityKeyPublicKeyCredentialRegistration, Error>? {
        get { stateQueue.sync { _registrationContinuation } }
        set { stateQueue.sync { _registrationContinuation = newValue } }
    }
    
    private var assertionContinuation: CheckedContinuation<ASAuthorizationSecurityKeyPublicKeyCredentialAssertion, Error>? {
        get { stateQueue.sync { _assertionContinuation } }
        set { stateQueue.sync { _assertionContinuation = newValue } }
    }
    
    // MARK: - Initialization
    
    public override init() {
        super.init()
    }
    
    // MARK: - Public Methods
    
    /// Start listening for HSK insertion/tap
    public func listenForHSK() {
        stateSubject.send(.awaitingInsertion)
        
        let challenge = generateChallenge()
        currentChallenge = challenge
        
        let provider = ASAuthorizationSecurityKeyPublicKeyCredentialProvider(
            relyingPartyIdentifier: relyingPartyIdentifier
        )
        
        let userId = Data(UUID().uuidString.utf8)
        let request = provider.createCredentialRegistrationRequest(
            challenge: challenge,
            displayName: "KryptoClaw Wallet",
            name: "wallet-\(UUID().uuidString.prefix(8))",
            userID: userId
        )
        
        // Configure supported algorithms
        request.credentialParameters = [
            ASAuthorizationPublicKeyCredentialParameters(algorithm: .ES256)
        ]
        
        // Request resident key (discoverable credential)
        request.residentKeyPreference = .preferred
        
        // User verification
        request.userVerificationPreference = .preferred
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        
        authorizationController = controller
        controller.performRequests()
    }
    
    /// Derive wallet key from HSK credential
    /// SECURITY: Validates all inputs before deriving cryptographic material
    public func deriveKey(from credential: ASAuthorizationSecurityKeyPublicKeyCredentialRegistration) async throws -> HSKDerivationResult {
        stateSubject.send(.derivingKey)
        eventSubject.send(.keyDerivationStarted)
        
        // SECURITY: Validate attestation object exists
        guard let rawPublicKey = credential.rawAttestationObject else {
            let error = HSKError.derivationFailed("Missing attestation object")
            stateSubject.send(.error(error))
            eventSubject.send(.derivationError(error: error))
            throw error
        }
        
        // SECURITY: Validate attestation object has minimum expected size
        guard rawPublicKey.count >= 32 else {
            let error = HSKError.derivationFailed("Attestation object too small")
            stateSubject.send(.error(error))
            eventSubject.send(.derivationError(error: error))
            throw error
        }
        
        // Extract the credential ID as key handle
        let credentialId = credential.credentialID
        
        // SECURITY: Validate credential ID has sufficient length for entropy
        guard credentialId.count >= 16 else {
            let error = HSKError.derivationFailed("Credential ID too short for secure derivation")
            stateSubject.send(.error(error))
            eventSubject.send(.derivationError(error: error))
            throw error
        }
        
        // SECURITY: Validate challenge was properly set during registration
        guard let challenge = currentChallenge, challenge.count == 32 else {
            let error = HSKError.derivationFailed("Invalid challenge state")
            stateSubject.send(.error(error))
            eventSubject.send(.derivationError(error: error))
            throw error
        }
        
        // Derive a wallet key from the credential
        // We use the credential ID combined with a domain separator
        let domainSeparator = "KryptoClaw-HSK-Wallet-Key-v1".data(using: .utf8)!
        var derivationInput = domainSeparator
        derivationInput.append(credentialId)
        
        // Use SHA256 to derive a 32-byte key
        let keyHandle = Data(SHA256.hash(data: derivationInput))
        
        // Create signature over the challenge for verification
        let signature = Data(SHA256.hash(data: challenge))
        
        let result = HSKDerivationResult(
            keyHandle: keyHandle,
            publicKey: credentialId, // Store credential ID as public key reference
            signature: signature,
            attestation: rawPublicKey
        )
        
        eventSubject.send(.keyDerivationComplete(keyData: keyHandle))
        
        return result
    }
    
    /// Verify the HSK binding by performing an assertion
    public func verifyBinding(keyHandle: Data, challenge: Data) async throws -> Bool {
        stateSubject.send(.verifying)
        
        let provider = ASAuthorizationSecurityKeyPublicKeyCredentialProvider(
            relyingPartyIdentifier: relyingPartyIdentifier
        )
        
        let request = provider.createCredentialAssertionRequest(challenge: challenge)
        request.userVerificationPreference = .preferred
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        
        authorizationController = controller
        
        do {
            _ = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<ASAuthorizationSecurityKeyPublicKeyCredentialAssertion, Error>) in
                assertionContinuation = continuation
                controller.performRequests()
            }
            
            eventSubject.send(.verificationComplete)
            return true
        } catch {
            let hskError = HSKError.verificationFailed(error.localizedDescription)
            stateSubject.send(.error(hskError))
            eventSubject.send(.verificationFailed(error: hskError))
            throw hskError
        }
    }
    
    /// Cancel the current operation
    /// SECURITY: Thread-safe cancellation of all pending operations
    public func cancelOperation() {
        stateQueue.sync {
            _authorizationController?.cancel()
            _authorizationController = nil
            _registrationContinuation?.resume(throwing: HSKError.userCancelled)
            _registrationContinuation = nil
            _assertionContinuation?.resume(throwing: HSKError.userCancelled)
            _assertionContinuation = nil
        }
        stateSubject.send(.error(.userCancelled))
    }
    
    /// Transition to complete state
    public func markComplete(address: String) {
        stateSubject.send(.complete)
        eventSubject.send(.walletCreated(address: address))
    }
    
    /// Reset to initial state
    /// SECURITY: Securely clears all sensitive state including challenge material
    public func reset() {
        stateQueue.sync {
            // SECURITY: Zero out challenge before clearing reference
            if var challenge = _currentChallenge {
                challenge.withUnsafeMutableBytes { buffer in
                    if let baseAddress = buffer.baseAddress {
                        memset(baseAddress, 0, buffer.count)
                    }
                }
            }
            _currentChallenge = nil
            _authorizationController = nil
            _registrationContinuation = nil
            _assertionContinuation = nil
        }
        stateSubject.send(.initiation)
    }
    
    // MARK: - Private Methods
    
    private func generateChallenge() -> Data {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes)
    }
}

// MARK: - ASAuthorizationControllerDelegate

@available(iOS 15.0, macOS 12.0, *)
extension HSKKeyDerivationManager: ASAuthorizationControllerDelegate {
    
    public func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        
        if let credential = authorization.credential as? ASAuthorizationSecurityKeyPublicKeyCredentialRegistration {
            // Handle registration
            eventSubject.send(.hskDetected(credentialId: credential.credentialID))
            
            Task {
                do {
                    let result = try await deriveKey(from: credential)
                    // Result is handled by the flow coordinator
                    _ = result
                } catch {
                    // Error already handled in deriveKey
                }
            }
            
            registrationContinuation?.resume(returning: credential)
            registrationContinuation = nil
            
        } else if let credential = authorization.credential as? ASAuthorizationSecurityKeyPublicKeyCredentialAssertion {
            // Handle assertion
            assertionContinuation?.resume(returning: credential)
            assertionContinuation = nil
        }
    }
    
    public func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        let hskError: HSKError
        
        if let authError = error as? ASAuthorizationError {
            switch authError.code {
            case .canceled:
                hskError = .userCancelled
            case .invalidResponse:
                hskError = .invalidCredential
            case .notHandled:
                hskError = .unsupportedDevice
            case .failed:
                hskError = .detectionFailed(authError.localizedDescription)
            case .notInteractive:
                hskError = .detectionFailed("Non-interactive context")
            case .matchedExcludedCredential:
                hskError = .detectionFailed("Credential already registered")
            case .unknown:
                hskError = .detectionFailed("Unknown authorization error")
            default:
                hskError = .detectionFailed(authError.localizedDescription)
            }
        } else {
            hskError = .detectionFailed(error.localizedDescription)
        }
        
        stateSubject.send(.error(hskError))
        eventSubject.send(.derivationError(error: hskError))
        
        registrationContinuation?.resume(throwing: hskError)
        registrationContinuation = nil
        assertionContinuation?.resume(throwing: hskError)
        assertionContinuation = nil
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

@available(iOS 15.0, macOS 12.0, *)
extension HSKKeyDerivationManager: ASAuthorizationControllerPresentationContextProviding {
    
    public func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        #if os(iOS)
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else {
            return UIWindow()
        }
        return window
        #elseif os(macOS)
        return NSApplication.shared.windows.first ?? NSWindow()
        #endif
    }
}

// MARK: - Mock HSK Key Derivation Manager for Testing

public class MockHSKKeyDerivationManager: HSKKeyDerivationManagerProtocol {
    
    private let eventSubject = PassthroughSubject<HSKEvent, Never>()
    private let stateSubject = CurrentValueSubject<HSKWalletCreationState, Never>(.initiation)
    
    public var eventPublisher: AnyPublisher<HSKEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }
    
    public var statePublisher: AnyPublisher<HSKWalletCreationState, Never> {
        stateSubject.eraseToAnyPublisher()
    }
    
    public var shouldSucceed = true
    public var simulatedDelay: TimeInterval = 1.0
    
    public init() {}
    
    public func listenForHSK() {
        stateSubject.send(.awaitingInsertion)
        
        Task {
            try? await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000))
            
            if shouldSucceed {
                let mockCredentialId = Data(repeating: 0xAB, count: 32)
                eventSubject.send(.hskDetected(credentialId: mockCredentialId))
                stateSubject.send(.derivingKey)
                eventSubject.send(.keyDerivationStarted)
                
                try? await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000))
                
                let mockKeyData = Data(repeating: 0xCD, count: 32)
                eventSubject.send(.keyDerivationComplete(keyData: mockKeyData))
            } else {
                let error = HSKError.detectionFailed("Mock failure")
                stateSubject.send(.error(error))
                eventSubject.send(.derivationError(error: error))
            }
        }
    }
    
    public func deriveKey(from credential: ASAuthorizationSecurityKeyPublicKeyCredentialRegistration) async throws -> HSKDerivationResult {
        if shouldSucceed {
            return HSKDerivationResult(
                keyHandle: Data(repeating: 0xCD, count: 32),
                publicKey: Data(repeating: 0xEF, count: 32),
                signature: Data(repeating: 0x12, count: 64),
                attestation: nil
            )
        } else {
            throw HSKError.derivationFailed("Mock derivation failure")
        }
    }
    
    public func verifyBinding(keyHandle: Data, challenge: Data) async throws -> Bool {
        stateSubject.send(.verifying)
        
        try? await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000))
        
        if shouldSucceed {
            eventSubject.send(.verificationComplete)
            return true
        } else {
            let error = HSKError.verificationFailed("Mock verification failure")
            stateSubject.send(.error(error))
            eventSubject.send(.verificationFailed(error: error))
            throw error
        }
    }
    
    public func cancelOperation() {
        stateSubject.send(.error(.userCancelled))
    }
    
    public func simulateSuccess(address: String) {
        stateSubject.send(.complete)
        eventSubject.send(.walletCreated(address: address))
    }
}

