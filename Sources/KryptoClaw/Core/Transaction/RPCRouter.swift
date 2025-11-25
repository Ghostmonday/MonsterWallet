// MODULE: RPCRouter
// VERSION: 1.0.0
// PURPOSE: Actor-based RPC routing with MEV protection via Flashbots and failover logic

import Foundation

// MARK: - RPC Endpoint Configuration

/// Configuration for an RPC endpoint
public struct RPCEndpoint: Sendable {
    public let url: URL
    public let name: String
    public let chainId: Int?
    public let isMEVProtected: Bool
    public let priority: Int // Lower = higher priority
    
    public init(url: URL, name: String, chainId: Int? = nil, isMEVProtected: Bool = false, priority: Int = 0) {
        self.url = url
        self.name = name
        self.chainId = chainId
        self.isMEVProtected = isMEVProtected
        self.priority = priority
    }
}

/// MEV Protection status for transactions
public enum MEVProtectionStatus: Sendable, Equatable {
    case enabled(provider: String)
    case disabled(reason: String)
    case unavailable
    
    public var isProtected: Bool {
        if case .enabled = self { return true }
        return false
    }
    
    public var description: String {
        switch self {
        case .enabled(let provider):
            return "MEV Protected via \(provider)"
        case .disabled(let reason):
            return "MEV Protection Disabled: \(reason)"
        case .unavailable:
            return "MEV Protection Not Available"
        }
    }
}

/// Result of an RPC call
public struct RPCResult: Sendable {
    public let data: Data
    public let endpoint: RPCEndpoint
    public let protectionStatus: MEVProtectionStatus
    public let latencyMs: Int
    
    public init(data: Data, endpoint: RPCEndpoint, protectionStatus: MEVProtectionStatus, latencyMs: Int) {
        self.data = data
        self.endpoint = endpoint
        self.protectionStatus = protectionStatus
        self.latencyMs = latencyMs
    }
}

// MARK: - RPC Router Errors

public enum RPCRouterError: Error, LocalizedError, Sendable {
    case noEndpointsAvailable(chain: String)
    case allEndpointsFailed(chain: String, errors: [String])
    case timeout(endpoint: String)
    case invalidResponse(endpoint: String)
    case networkError(underlying: String)
    case unsupportedChain(String)
    
    public var errorDescription: String? {
        switch self {
        case .noEndpointsAvailable(let chain):
            return "No RPC endpoints available for \(chain)"
        case .allEndpointsFailed(let chain, let errors):
            return "All \(chain) endpoints failed: \(errors.joined(separator: ", "))"
        case .timeout(let endpoint):
            return "Request to \(endpoint) timed out"
        case .invalidResponse(let endpoint):
            return "Invalid response from \(endpoint)"
        case .networkError(let underlying):
            return "Network error: \(underlying)"
        case .unsupportedChain(let chain):
            return "Unsupported chain: \(chain)"
        }
    }
}

// MARK: - RPC Router Actor

/// Actor managing RPC endpoint routing with MEV protection and automatic failover.
///
/// **MEV Protection:**
/// - Ethereum transactions are routed through Flashbots by default
/// - Prevents front-running and sandwich attacks
///
/// **Failover Logic:**
/// - 3 second timeout per endpoint
/// - Automatic fallback to public nodes if protected endpoints fail
/// - Returns protection status with each response
@available(iOS 15.0, macOS 12.0, *)
public actor RPCRouter {
    
    // MARK: - Constants
    
    /// Timeout for RPC requests in seconds
    private let requestTimeout: TimeInterval = 3.0
    
    // MARK: - Endpoint Configuration
    
    /// Ethereum endpoints (Flashbots primary for MEV protection)
    private let ethereumEndpoints: [RPCEndpoint] = [
        RPCEndpoint(
            url: URL(string: "https://rpc.flashbots.net")!,
            name: "Flashbots",
            chainId: 1,
            isMEVProtected: true,
            priority: 0
        ),
        RPCEndpoint(
            url: URL(string: "https://cloudflare-eth.com")!,
            name: "Cloudflare",
            chainId: 1,
            isMEVProtected: false,
            priority: 1
        ),
        RPCEndpoint(
            url: URL(string: "https://eth.llamarpc.com")!,
            name: "LlamaRPC",
            chainId: 1,
            isMEVProtected: false,
            priority: 2
        )
    ]
    
    /// Bitcoin endpoints
    private let bitcoinEndpoints: [RPCEndpoint] = [
        RPCEndpoint(
            url: URL(string: "https://mempool.space/api")!,
            name: "Mempool.space",
            chainId: nil,
            isMEVProtected: false,
            priority: 0
        ),
        RPCEndpoint(
            url: URL(string: "https://blockstream.info/api")!,
            name: "Blockstream",
            chainId: nil,
            isMEVProtected: false,
            priority: 1
        )
    ]
    
    /// Solana endpoints
    private let solanaEndpoints: [RPCEndpoint] = [
        RPCEndpoint(
            url: URL(string: "https://api.mainnet-beta.solana.com")!,
            name: "Solana Mainnet",
            chainId: nil,
            isMEVProtected: false,
            priority: 0
        ),
        RPCEndpoint(
            url: URL(string: "https://solana-api.projectserum.com")!,
            name: "Project Serum",
            chainId: nil,
            isMEVProtected: false,
            priority: 1
        )
    ]
    
    // MARK: - State
    
    /// Track endpoint health
    private var endpointHealth: [String: Bool] = [:]
    
    /// Last successful endpoint per chain
    private var lastSuccessfulEndpoint: [AssetChain: RPCEndpoint] = [:]
    
    // MARK: - Dependencies
    
    private let session: URLSession
    
    // MARK: - Initialization
    
    public init(session: URLSession = .shared) {
        self.session = session
    }
    
    // MARK: - Public Interface
    
    /// Get endpoints for a specific chain
    public func getEndpoints(for chain: AssetChain) -> [RPCEndpoint] {
        switch chain {
        case .ethereum:
            return ethereumEndpoints.sorted { $0.priority < $1.priority }
        case .bitcoin:
            return bitcoinEndpoints.sorted { $0.priority < $1.priority }
        case .solana:
            return solanaEndpoints.sorted { $0.priority < $1.priority }
        }
    }
    
    /// Send a JSON-RPC request with automatic failover
    public func sendRequest(
        method: String,
        params: [Any],
        chain: AssetChain
    ) async throws -> RPCResult {
        let endpoints = getEndpoints(for: chain)
        guard !endpoints.isEmpty else {
            throw RPCRouterError.noEndpointsAvailable(chain: chain.displayName)
        }
        
        var errors: [String] = []
        
        for endpoint in endpoints {
            do {
                let result = try await executeRequest(
                    method: method,
                    params: params,
                    endpoint: endpoint
                )
                
                // Mark endpoint as healthy
                endpointHealth[endpoint.url.absoluteString] = true
                lastSuccessfulEndpoint[chain] = endpoint
                
                return result
            } catch {
                // Mark endpoint as unhealthy
                endpointHealth[endpoint.url.absoluteString] = false
                errors.append("\(endpoint.name): \(error.localizedDescription)")
                
                // Continue to next endpoint
                continue
            }
        }
        
        throw RPCRouterError.allEndpointsFailed(chain: chain.displayName, errors: errors)
    }
    
    /// Send a raw transaction (broadcast)
    public func sendRawTransaction(
        signedTx: Data,
        chain: AssetChain
    ) async throws -> RPCResult {
        switch chain {
        case .ethereum:
            let hexTx = "0x" + signedTx.map { String(format: "%02x", $0) }.joined()
            return try await sendRequest(
                method: "eth_sendRawTransaction",
                params: [hexTx],
                chain: chain
            )
            
        case .bitcoin:
            // Bitcoin uses different broadcast mechanism
            return try await broadcastBitcoinTransaction(signedTx: signedTx)
            
        case .solana:
            let base64Tx = signedTx.base64EncodedString()
            return try await sendRequest(
                method: "sendTransaction",
                params: [base64Tx, ["encoding": "base64"]],
                chain: chain
            )
        }
    }
    
    /// Get current MEV protection status for a chain
    public func getMEVProtectionStatus(for chain: AssetChain) -> MEVProtectionStatus {
        guard chain == .ethereum else {
            return .unavailable
        }
        
        // Check if Flashbots is healthy
        let flashbotsEndpoint = ethereumEndpoints.first { $0.isMEVProtected }
        if let endpoint = flashbotsEndpoint,
           endpointHealth[endpoint.url.absoluteString] != false {
            return .enabled(provider: "Flashbots")
        }
        
        return .disabled(reason: "Flashbots unavailable, using public RPC")
    }
    
    /// Get the best available endpoint for a chain
    public func getBestEndpoint(for chain: AssetChain) -> RPCEndpoint? {
        // Prefer last successful endpoint
        if let last = lastSuccessfulEndpoint[chain],
           endpointHealth[last.url.absoluteString] != false {
            return last
        }
        
        // Otherwise return first healthy endpoint
        let endpoints = getEndpoints(for: chain)
        return endpoints.first { endpointHealth[$0.url.absoluteString] != false }
            ?? endpoints.first
    }
    
    /// Reset endpoint health status
    public func resetHealthStatus() {
        endpointHealth.removeAll()
        lastSuccessfulEndpoint.removeAll()
    }
    
    // MARK: - Private Methods
    
    /// Execute a single RPC request with timeout
    private func executeRequest(
        method: String,
        params: [Any],
        endpoint: RPCEndpoint
    ) async throws -> RPCResult {
        let startTime = Date()
        
        // Build JSON-RPC payload
        let payload: [String: Any] = [
            "jsonrpc": "2.0",
            "id": Int(Date().timeIntervalSince1970 * 1000),
            "method": method,
            "params": params
        ]
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: payload) else {
            throw RPCRouterError.invalidResponse(endpoint: endpoint.name)
        }
        
        var request = URLRequest(url: endpoint.url)
        request.httpMethod = "POST"
        request.httpBody = httpBody
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = requestTimeout
        
        // Execute with timeout
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError where error.code == .timedOut {
            throw RPCRouterError.timeout(endpoint: endpoint.name)
        } catch {
            throw RPCRouterError.networkError(underlying: error.localizedDescription)
        }
        
        // Validate response
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw RPCRouterError.invalidResponse(endpoint: endpoint.name)
        }
        
        // Check for JSON-RPC error
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let error = json["error"] as? [String: Any],
           let message = error["message"] as? String {
            throw RPCRouterError.networkError(underlying: message)
        }
        
        let latency = Int(Date().timeIntervalSince(startTime) * 1000)
        let protectionStatus: MEVProtectionStatus = endpoint.isMEVProtected
            ? .enabled(provider: endpoint.name)
            : .disabled(reason: "Using public RPC")
        
        return RPCResult(
            data: data,
            endpoint: endpoint,
            protectionStatus: protectionStatus,
            latencyMs: latency
        )
    }
    
    /// Broadcast Bitcoin transaction
    private func broadcastBitcoinTransaction(signedTx: Data) async throws -> RPCResult {
        let startTime = Date()
        let endpoint = bitcoinEndpoints[0]
        
        let hexTx = signedTx.map { String(format: "%02x", $0) }.joined()
        let url = URL(string: "\(endpoint.url.absoluteString)/tx")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = hexTx.data(using: .utf8)
        request.setValue("text/plain", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = requestTimeout
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw RPCRouterError.invalidResponse(endpoint: endpoint.name)
        }
        
        let latency = Int(Date().timeIntervalSince(startTime) * 1000)
        
        return RPCResult(
            data: data,
            endpoint: endpoint,
            protectionStatus: .unavailable,
            latencyMs: latency
        )
    }
}

// MARK: - Convenience Extensions

@available(iOS 15.0, macOS 12.0, *)
extension RPCRouter {
    
    /// Fetch current gas price for Ethereum
    public func fetchGasPrice() async throws -> (baseFee: UInt64, priorityFee: UInt64) {
        let result = try await sendRequest(
            method: "eth_gasPrice",
            params: [],
            chain: .ethereum
        )
        
        guard let json = try? JSONSerialization.jsonObject(with: result.data) as? [String: Any],
              let hexPrice = json["result"] as? String else {
            throw RPCRouterError.invalidResponse(endpoint: result.endpoint.name)
        }
        
        let gasPrice = UInt64(hexPrice.dropFirst(2), radix: 16) ?? 0
        
        // Estimate priority fee as 10% of base
        let priorityFee = gasPrice / 10
        
        return (baseFee: gasPrice, priorityFee: priorityFee)
    }
    
    /// Get transaction count (nonce) for an address
    public func getTransactionCount(address: String) async throws -> UInt64 {
        let result = try await sendRequest(
            method: "eth_getTransactionCount",
            params: [address, "pending"],
            chain: .ethereum
        )
        
        guard let json = try? JSONSerialization.jsonObject(with: result.data) as? [String: Any],
              let hexCount = json["result"] as? String else {
            throw RPCRouterError.invalidResponse(endpoint: result.endpoint.name)
        }
        
        return UInt64(hexCount.dropFirst(2), radix: 16) ?? 0
    }
}

