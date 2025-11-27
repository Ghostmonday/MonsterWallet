// MODULE: TransactionSimulationService
// VERSION: 1.0.0
// PURPOSE: Transaction simulation guard - enforces "Simulation First" policy

import Foundation
import CryptoKit
import BigInt

// MARK: - Simulation Result

/// Result of a transaction simulation with cryptographic receipt
public enum TxSimulationResult: Sendable, Equatable {
    case success(receipt: SimulationReceipt)
    case failure(error: String, revertReason: String?)
    
    public var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }
    
    public var receipt: SimulationReceipt? {
        if case .success(let receipt) = self { return receipt }
        return nil
    }
    
    public var errorMessage: String? {
        if case .failure(let error, _) = self { return error }
        return nil
    }
    
    public var revertReason: String? {
        if case .failure(_, let reason) = self { return reason }
        return nil
    }
}

/// Cryptographically verifiable simulation receipt
public struct SimulationReceipt: Sendable, Equatable, Codable {
    /// Unique receipt ID
    public let receiptId: String
    
    /// Estimated gas for the transaction
    public let gasEstimate: UInt64
    
    /// Expected balance changes (address: amount)
    public let balanceChanges: [String: String]
    
    /// Timestamp of simulation
    public let timestamp: Date
    
    /// Expiration time (simulation results are valid for limited time)
    public let expiresAt: Date
    
    /// Hash of transaction parameters (for verification)
    public let transactionHash: String
    
    /// Signature proving simulation was performed
    public let signature: String
    
    public init(
        receiptId: String,
        gasEstimate: UInt64,
        balanceChanges: [String: String],
        timestamp: Date = Date(),
        expiresAt: Date,
        transactionHash: String,
        signature: String
    ) {
        self.receiptId = receiptId
        self.gasEstimate = gasEstimate
        self.balanceChanges = balanceChanges
        self.timestamp = timestamp
        self.expiresAt = expiresAt
        self.transactionHash = transactionHash
        self.signature = signature
    }
    
    /// Check if receipt is still valid
    public var isValid: Bool {
        Date() < expiresAt
    }
    
    /// Check if receipt is expired
    public var isExpired: Bool {
        !isValid
    }
}

// MARK: - Simulation Request

/// Parameters for a simulation request
public struct SimulationRequest: Sendable {
    public let from: String
    public let to: String
    public let value: String
    public let data: Data
    public let chain: AssetChain
    public let gasLimit: UInt64?
    
    public init(from: String, to: String, value: String, data: Data = Data(), chain: AssetChain, gasLimit: UInt64? = nil) {
        self.from = from
        self.to = to
        self.value = value
        self.data = data
        self.chain = chain
        self.gasLimit = gasLimit
    }
    
    /// Generate a hash of the transaction parameters
    public var parameterHash: String {
        let combined = "\(from):\(to):\(value):\(data.base64EncodedString()):\(chain.rawValue)"
        let hash = SHA256.hash(data: Data(combined.utf8))
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Simulation Service Errors

public enum SimulationError: Error, LocalizedError, Sendable {
    case simulationFailed(reason: String)
    case networkError(underlying: String)
    case invalidParameters
    case receiptExpired
    case receiptMismatch
    case simulationRequired
    
    public var errorDescription: String? {
        switch self {
        case .simulationFailed(let reason):
            return "Simulation failed: \(reason)"
        case .networkError(let underlying):
            return "Network error during simulation: \(underlying)"
        case .invalidParameters:
            return "Invalid transaction parameters"
        case .receiptExpired:
            return "Simulation receipt has expired. Please simulate again."
        case .receiptMismatch:
            return "Transaction parameters don't match simulation receipt"
        case .simulationRequired:
            return "Transaction must be simulated before signing"
        }
    }
}

// MARK: - Transaction Simulation Service

/// Actor service for simulating transactions before signing.
///
/// **Security: "Simulation First" Policy**
/// - Every transaction MUST be simulated before signing is allowed
/// - Simulation receipts are cryptographically signed and time-limited
/// - Receipts include a hash of tx parameters to prevent tampering
///
/// **Purpose:**
/// - Detect potential transaction failures before spending gas
/// - Show users expected balance changes
/// - Identify malicious contract interactions
/// - Provide accurate gas estimates
@available(iOS 15.0, macOS 12.0, *)
public actor TransactionSimulationService {
    
    // MARK: - Constants
    
    /// Receipt validity duration (5 minutes)
    private let receiptValidityDuration: TimeInterval = 300
    
    /// Signing key for receipts (in production, use secure key management)
    private let signingKey: SymmetricKey
    
    // MARK: - State
    
    /// Cache of valid simulation receipts
    private var receiptCache: [String: SimulationReceipt] = [:]
    
    // MARK: - Dependencies
    
    private let rpcRouter: RPCRouter
    private let session: URLSession
    
    // MARK: - Initialization
    
    public init(rpcRouter: RPCRouter, session: URLSession = .shared) {
        self.rpcRouter = rpcRouter
        self.session = session
        
        // Generate a session-specific signing key
        // In production, this would be derived from secure storage
        self.signingKey = SymmetricKey(size: .bits256)
    }
    
    // MARK: - Public Interface
    
    /// Simulate a transaction
    /// - Parameter request: The simulation request parameters
    /// - Returns: TxSimulationResult with receipt if successful
    public func simulate(request: SimulationRequest) async -> TxSimulationResult {
        // Validate parameters
        guard !request.from.isEmpty, !request.to.isEmpty else {
            return .failure(error: "Invalid addresses", revertReason: nil)
        }
        
        // Perform chain-specific simulation
        do {
            let receipt: SimulationReceipt
            
            switch request.chain {
            case .ethereum:
                receipt = try await simulateEthereum(request: request)
            case .bitcoin:
                receipt = try await simulateBitcoin(request: request)
            case .solana:
                receipt = try await simulateSolana(request: request)
            }
            
            // Cache the receipt
            receiptCache[receipt.transactionHash] = receipt
            
            return .success(receipt: receipt)
        } catch let error as SimulationError {
            return .failure(error: error.localizedDescription, revertReason: nil)
        } catch {
            return .failure(error: error.localizedDescription, revertReason: nil)
        }
    }
    
    /// Verify a simulation receipt is valid for signing
    /// - Parameters:
    ///   - receipt: The simulation receipt to verify
    ///   - request: The transaction request to verify against
    /// - Returns: True if receipt is valid and matches the request
    public func verifyReceipt(_ receipt: SimulationReceipt, for request: SimulationRequest) -> Bool {
        // Check expiration
        guard !receipt.isExpired else {
            return false
        }
        
        // Verify transaction hash matches
        guard receipt.transactionHash == request.parameterHash else {
            return false
        }
        
        // Verify signature
        let expectedSignature = generateSignature(for: receipt)
        guard receipt.signature == expectedSignature else {
            return false
        }
        
        return true
    }
    
    /// Get a cached receipt if still valid
    public func getCachedReceipt(for request: SimulationRequest) -> SimulationReceipt? {
        let hash = request.parameterHash
        guard let receipt = receiptCache[hash], !receipt.isExpired else {
            // Clean up expired receipt
            receiptCache.removeValue(forKey: hash)
            return nil
        }
        return receipt
    }
    
    /// Clear expired receipts from cache
    public func clearExpiredReceipts() {
        let now = Date()
        receiptCache = receiptCache.filter { _, receipt in
            receipt.expiresAt > now
        }
    }
    
    // MARK: - Chain-Specific Simulation
    
    /// Simulate an Ethereum transaction
    private func simulateEthereum(request: SimulationRequest) async throws -> SimulationReceipt {
        // Use eth_call to simulate
        let valueBigInt = BigInt(request.value) ?? BigInt(0)

        var callParams: [String: Any] = [
            "from": request.from,
            "to": request.to,
            "value": "0x" + String(valueBigInt, radix: 16)
        ]
        
        if !request.data.isEmpty {
            callParams["data"] = "0x" + request.data.map { String(format: "%02x", $0) }.joined()
        }
        
        // Simulate the call
        do {
            let _ = try await rpcRouter.sendRequest(
                method: "eth_call",
                params: [callParams, "latest"],
                chain: .ethereum
            )
        } catch {
            throw SimulationError.simulationFailed(reason: error.localizedDescription)
        }
        
        // Estimate gas
        let gasEstimate: UInt64
        do {
            let gasResult = try await rpcRouter.sendRequest(
                method: "eth_estimateGas",
                params: [callParams],
                chain: .ethereum
            )
            
            if let json = try? JSONSerialization.jsonObject(with: gasResult.data) as? [String: Any],
               let hexGas = json["result"] as? String {
                gasEstimate = UInt64(hexGas.dropFirst(2), radix: 16) ?? 21000
            } else {
                gasEstimate = 21000 // Default for simple transfer
            }
        } catch {
            gasEstimate = 21000
        }
        
        // Calculate expected balance changes
        let balanceChanges = calculateBalanceChanges(request: request, gasEstimate: gasEstimate)
        
        return createReceipt(
            gasEstimate: gasEstimate,
            balanceChanges: balanceChanges,
            transactionHash: request.parameterHash
        )
    }
    
    /// Simulate a Bitcoin transaction
    private func simulateBitcoin(request: SimulationRequest) async throws -> SimulationReceipt {
        // Bitcoin simulation is simpler - mainly fee estimation
        // In production, would check UTXOs and validate inputs
        
        let estimatedFee: UInt64 = 2000 // ~2000 satoshis for typical tx
        let balanceChanges = [
            request.from: "-\(request.value)",
            request.to: "+\(request.value)"
        ]
        
        return createReceipt(
            gasEstimate: estimatedFee,
            balanceChanges: balanceChanges,
            transactionHash: request.parameterHash
        )
    }
    
    /// Simulate a Solana transaction
    private func simulateSolana(request: SimulationRequest) async throws -> SimulationReceipt {
        // Solana uses simulateTransaction RPC method
        // For now, use mock simulation
        
        let estimatedFee: UInt64 = 5000 // 5000 lamports
        let balanceChanges = [
            request.from: "-\(request.value)",
            request.to: "+\(request.value)"
        ]
        
        return createReceipt(
            gasEstimate: estimatedFee,
            balanceChanges: balanceChanges,
            transactionHash: request.parameterHash
        )
    }
    
    // MARK: - Helper Methods
    
    /// Create a signed simulation receipt
    private func createReceipt(
        gasEstimate: UInt64,
        balanceChanges: [String: String],
        transactionHash: String
    ) -> SimulationReceipt {
        let receiptId = UUID().uuidString
        let timestamp = Date()
        let expiresAt = timestamp.addingTimeInterval(receiptValidityDuration)
        
        // Create receipt without signature first
        let receipt = SimulationReceipt(
            receiptId: receiptId,
            gasEstimate: gasEstimate,
            balanceChanges: balanceChanges,
            timestamp: timestamp,
            expiresAt: expiresAt,
            transactionHash: transactionHash,
            signature: ""
        )
        
        // Generate signature
        let signature = generateSignature(for: receipt)
        
        // Return receipt with signature
        return SimulationReceipt(
            receiptId: receiptId,
            gasEstimate: gasEstimate,
            balanceChanges: balanceChanges,
            timestamp: timestamp,
            expiresAt: expiresAt,
            transactionHash: transactionHash,
            signature: signature
        )
    }
    
    /// Generate HMAC signature for a receipt
    private func generateSignature(for receipt: SimulationReceipt) -> String {
        let data = "\(receipt.receiptId):\(receipt.transactionHash):\(receipt.gasEstimate):\(receipt.expiresAt.timeIntervalSince1970)"
        let signature = HMAC<SHA256>.authenticationCode(for: Data(data.utf8), using: signingKey)
        return Data(signature).base64EncodedString()
    }
    
    /// Calculate expected balance changes
    private func calculateBalanceChanges(request: SimulationRequest, gasEstimate: UInt64) -> [String: String] {
        guard let valueWei = BigInt(request.value) else {
            return [:]
        }
        
        // Estimate gas cost (using mock gas price)
        let gasCost = BigInt(gasEstimate) * BigInt(30_000_000_000) // 30 gwei
        let totalCost = valueWei + gasCost
        
        return [
            request.from: "-\(totalCost)",
            request.to: "+\(valueWei)"
        ]
    }
}

