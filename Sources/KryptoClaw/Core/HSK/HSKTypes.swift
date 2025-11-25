import CryptoKit
import Foundation

// MARK: - HSK Error Types

/// Errors that can occur during HSK-bound wallet operations
public enum HSKError: Error, Equatable {
    case detectionFailed(String)
    case derivationFailed(String)
    case verificationFailed(String)
    case bindingFailed(String)
    case keyNotFound
    case userCancelled
    case unsupportedDevice
    case enclaveNotAvailable
    case invalidCredential
    case timeout
    
    public var localizedDescription: String {
        switch self {
        case .detectionFailed(let reason):
            return "Hardware key detection failed: \(reason)"
        case .derivationFailed(let reason):
            return "Key derivation failed: \(reason)"
        case .verificationFailed(let reason):
            return "Verification failed: \(reason)"
        case .bindingFailed(let reason):
            return "Wallet binding failed: \(reason)"
        case .keyNotFound:
            return "Hardware security key not found"
        case .userCancelled:
            return "Operation cancelled by user"
        case .unsupportedDevice:
            return "This device does not support hardware security keys"
        case .enclaveNotAvailable:
            return "Secure Enclave is not available"
        case .invalidCredential:
            return "Invalid credential received from hardware key"
        case .timeout:
            return "Operation timed out waiting for hardware key"
        }
    }
}

// MARK: - HSK Wallet Creation State Machine

/// State machine for HSK-bound wallet creation flow
public enum HSKWalletCreationState: Equatable {
    case initiation
    case awaitingInsertion
    case derivingKey
    case verifying
    case complete
    case error(HSKError)
    
    public var displayTitle: String {
        switch self {
        case .initiation:
            return "Initialize Hardware Key"
        case .awaitingInsertion:
            return "Insert Security Key"
        case .derivingKey:
            return "Deriving Wallet Key"
        case .verifying:
            return "Verifying Binding"
        case .complete:
            return "Wallet Created"
        case .error:
            return "Error Occurred"
        }
    }
    
    public var displaySubtitle: String {
        switch self {
        case .initiation:
            return "Prepare your hardware security key"
        case .awaitingInsertion:
            return "Insert or tap your security key"
        case .derivingKey:
            return "Generating secure wallet keys..."
        case .verifying:
            return "Confirming hardware binding..."
        case .complete:
            return "Your HSK-bound wallet is ready"
        case .error(let error):
            return error.localizedDescription
        }
    }
    
    public var isTerminal: Bool {
        switch self {
        case .complete, .error:
            return true
        default:
            return false
        }
    }
}

// MARK: - HSK Bound Wallet

/// Represents a wallet that is bound to a hardware security key.
/// SECURITY: The derivedKeyHandle is explicitly excluded from Codable serialization.
/// It is stored ONLY in the Secure Enclave via SecureEnclaveInterface.
/// When persisted to disk, only non-sensitive metadata is saved.
public struct HSKBoundWallet: Identifiable, Equatable {
    public let id: UUID
    public let hskId: String
    /// SECURITY: This key handle is NEVER persisted to disk.
    /// It is stored exclusively in the Secure Enclave.
    /// Access requires biometric authentication.
    internal let derivedKeyHandle: Data
    public let address: String
    public let createdAt: Date
    public let lastUsedAt: Date?
    
    /// SECURITY: Hash of credentialID, NOT the raw value
    /// The raw credentialID should NEVER be stored as it can be used to derive keys
    public let credentialIdHash: Data?
    
    /// The derivation strategy used to create this wallet's keys
    /// SECURITY: Required to correctly re-derive keys for signing operations
    public let derivationStrategy: HSKDerivationStrategy
    
    /// SECURITY: Encrypted derivation salt stored in Keychain
    /// This salt is required for signature-based derivation
    public let derivationSaltId: String?
    
    /// DEPRECATED: Raw credentialId - kept for migration only
    /// New wallets should use credentialIdHash instead
    @available(*, deprecated, message: "Use credentialIdHash instead")
    public var credentialId: Data? { nil }
    
    public init(
        id: UUID = UUID(),
        hskId: String,
        derivedKeyHandle: Data,
        address: String,
        createdAt: Date = Date(),
        lastUsedAt: Date? = nil,
        credentialIdHash: Data? = nil,
        derivationStrategy: HSKDerivationStrategy = .signatureBased,
        derivationSaltId: String? = nil
    ) {
        self.id = id
        self.hskId = hskId
        self.derivedKeyHandle = derivedKeyHandle
        self.address = address
        self.createdAt = createdAt
        self.lastUsedAt = lastUsedAt
        self.credentialIdHash = credentialIdHash
        self.derivationStrategy = derivationStrategy
        self.derivationSaltId = derivationSaltId
    }
    
    /// MIGRATION: Create from legacy wallet data
    /// SECURITY: This initializer should only be used during migration from v1 wallets
    @available(*, deprecated, message: "For migration only - use primary initializer for new wallets")
    public init(
        id: UUID = UUID(),
        hskId: String,
        derivedKeyHandle: Data,
        address: String,
        createdAt: Date = Date(),
        lastUsedAt: Date? = nil,
        legacyCredentialId: Data?
    ) {
        self.id = id
        self.hskId = hskId
        self.derivedKeyHandle = derivedKeyHandle
        self.address = address
        self.createdAt = createdAt
        self.lastUsedAt = lastUsedAt
        // SECURITY: Hash the legacy credentialId if provided
        if let credId = legacyCredentialId {
            self.credentialIdHash = Data(SHA256.hash(data: credId))
        } else {
            self.credentialIdHash = nil
        }
        self.derivationStrategy = .legacyCredentialID
        self.derivationSaltId = nil
    }
}

// MARK: - HSKBoundWallet Codable Conformance
// SECURITY: Custom Codable implementation that EXCLUDES derivedKeyHandle from serialization.
// The key handle is stored separately in the Secure Enclave, not in plain JSON.

extension HSKBoundWallet: Codable {
    private enum CodingKeys: String, CodingKey {
        case id
        case hskId
        case address
        case createdAt
        case lastUsedAt
        case credentialIdHash
        case derivationStrategy
        case derivationSaltId
        // Legacy field for migration
        case credentialId
        // NOTE: derivedKeyHandle is intentionally EXCLUDED
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        hskId = try container.decode(String.self, forKey: .hskId)
        address = try container.decode(String.self, forKey: .address)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        lastUsedAt = try container.decodeIfPresent(Date.self, forKey: .lastUsedAt)
        
        // SECURITY: Handle migration from legacy credentialId to credentialIdHash
        if let hash = try container.decodeIfPresent(Data.self, forKey: .credentialIdHash) {
            credentialIdHash = hash
            derivationStrategy = try container.decodeIfPresent(HSKDerivationStrategy.self, forKey: .derivationStrategy) ?? .signatureBased
        } else if let legacyCredentialId = try container.decodeIfPresent(Data.self, forKey: .credentialId) {
            // MIGRATION: Convert legacy credentialId to hash
            credentialIdHash = Data(SHA256.hash(data: legacyCredentialId))
            derivationStrategy = .legacyCredentialID
            KryptoLogger.shared.log(
                level: .warning,
                category: .security,
                message: "Migrating legacy HSK binding to secure format"
            )
        } else {
            credentialIdHash = nil
            derivationStrategy = try container.decodeIfPresent(HSKDerivationStrategy.self, forKey: .derivationStrategy) ?? .signatureBased
        }
        
        derivationSaltId = try container.decodeIfPresent(String.self, forKey: .derivationSaltId)
        
        // SECURITY: derivedKeyHandle is set to empty Data.
        // The actual key must be retrieved from Secure Enclave using the address as identifier.
        derivedKeyHandle = Data()
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(hskId, forKey: .hskId)
        try container.encode(address, forKey: .address)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(lastUsedAt, forKey: .lastUsedAt)
        try container.encodeIfPresent(credentialIdHash, forKey: .credentialIdHash)
        try container.encode(derivationStrategy, forKey: .derivationStrategy)
        try container.encodeIfPresent(derivationSaltId, forKey: .derivationSaltId)
        // SECURITY: derivedKeyHandle is NEVER encoded to disk
        // SECURITY: Raw credentialId is NEVER encoded (only hash is stored)
    }
}

// MARK: - HSK Detection Result

/// Result of HSK detection operation
public enum HSKDetectionResult: Equatable {
    case detected(credentialId: Data, publicKey: Data)
    case notFound
    case error(HSKError)
    
    public var isSuccess: Bool {
        if case .detected = self {
            return true
        }
        return false
    }
}

// MARK: - HSK Derivation Result

/// Result of key derivation from HSK
/// SECURITY: Contains cryptographic material derived from hardware security key.
/// The keyHandle is the derived wallet private key and must be stored in Secure Enclave.
public struct HSKDerivationResult: Equatable {
    /// The derived wallet private key (32 bytes)
    /// SECURITY: This must be stored ONLY in the Secure Enclave, never in plaintext
    public let keyHandle: Data
    
    /// Hash of the credentialID for lookup purposes
    /// SECURITY: We store a HASH of credentialID, not the raw value, to prevent
    /// attackers from using it to derive keys
    public let publicKey: Data
    
    /// Cryptographic signature for verification
    public let signature: Data
    
    /// Raw attestation object from the HSK (CBOR-encoded)
    public let attestation: Data?
    
    /// The derivation strategy used to create this key
    /// SECURITY: Must be stored with the binding to ensure correct re-derivation
    public let derivationStrategy: HSKDerivationStrategy
    
    /// The salt used for HKDF derivation
    /// SECURITY: Must be stored encrypted alongside the binding
    public let derivationSalt: Data?
    
    public init(
        keyHandle: Data,
        publicKey: Data,
        signature: Data,
        attestation: Data? = nil,
        derivationStrategy: HSKDerivationStrategy = .signatureBased,
        derivationSalt: Data? = nil
    ) {
        self.keyHandle = keyHandle
        self.publicKey = publicKey
        self.signature = signature
        self.attestation = attestation
        self.derivationStrategy = derivationStrategy
        self.derivationSalt = derivationSalt
    }
}

// MARK: - HSK Derivation Strategy (Defined in HSKKeyDerivationManager.swift)
// Note: HSKDerivationStrategy is defined in HSKKeyDerivationManager.swift to keep
// the security-critical derivation logic together.

// MARK: - HSK Events

/// Events emitted during HSK operations
public enum HSKEvent {
    case hskDetected(credentialId: Data)
    case keyDerivationStarted
    case keyDerivationComplete(keyData: Data)
    case walletCreated(address: String)
    case derivationError(error: HSKError)
    case verificationComplete
    case verificationFailed(error: HSKError)
}

// MARK: - HSK Flow Mode

/// Determines the mode of the HSK flow
public enum HSKFlowMode: Equatable {
    case createNewWallet
    case bindToExistingWallet(walletId: String)
    
    public var isBinding: Bool {
        if case .bindToExistingWallet = self {
            return true
        }
        return false
    }
}

// MARK: - Persistence Keys

public extension PersistenceService {
    static let hskBindingsFile = "hsk_bindings.json"
}

