// MODULE: EarnCache
// VERSION: 1.0.0
// PURPOSE: Actor-based disk persistence for yield data with instant load policy

import Foundation

// MARK: - Earn Cache

/// Actor providing disk-based caching for earn data with "Instant Load" policy.
///
/// **Flow:**
/// 1. `loadFromDisk()` → Returns cached data immediately (0ms)
/// 2. Background: `fetchFromNetwork()` → Update disk → Publish new data
///
/// **Features:**
/// - JSON persistence via FileManager
/// - Automatic staleness detection
/// - Cache versioning for migrations
/// - Thread-safe via actor isolation
@available(iOS 15.0, macOS 12.0, *)
public actor EarnCache {
    
    // MARK: - Constants
    
    private struct CacheConfig {
        static let opportunitiesFileName = "earn_opportunities.json"
        static let positionsFileName = "earn_positions.json"
        static let metadataFileName = "earn_metadata.json"
        static let cacheVersion = 1
        static let staleThreshold: TimeInterval = 300 // 5 minutes
        static let expiredThreshold: TimeInterval = 86400 // 24 hours
    }
    
    // MARK: - State
    
    /// In-memory cache
    private var cachedOpportunities: [YieldOpportunity] = []
    private var cachedPositions: [StakingPosition] = []
    private var lastLoadTime: Date?
    private var lastNetworkFetchTime: Date?
    
    /// File manager for disk operations
    private let fileManager = FileManager.default
    
    /// Cache directory URL
    private let cacheDirectory: URL
    
    // MARK: - Initialization
    
    public init() {
        // Get caches directory
        let cachesURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        self.cacheDirectory = cachesURL.appendingPathComponent("EarnData", isDirectory: true)
        
        // Create directory if needed
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    /// Initialize with custom cache directory (for testing)
    public init(cacheDirectory: URL) {
        self.cacheDirectory = cacheDirectory
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    // MARK: - Public Interface: Instant Load
    
    /// Load opportunities from disk (instant, 0ms target)
    /// Returns nil if no cache exists
    public func loadOpportunitiesFromDisk() -> [YieldOpportunity]? {
        // Return in-memory cache if available
        if !cachedOpportunities.isEmpty {
            return cachedOpportunities
        }
        
        // Load from disk
        let fileURL = cacheDirectory.appendingPathComponent(CacheConfig.opportunitiesFileName)
        
        guard let data = try? Data(contentsOf: fileURL) else {
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let opportunities = try decoder.decode([YieldOpportunity].self, from: data)
            
            // Update in-memory cache
            cachedOpportunities = opportunities
            lastLoadTime = Date()
            
            return opportunities
        } catch {
            print("[EarnCache] Failed to decode opportunities: \(error)")
            return nil
        }
    }
    
    /// Load positions from disk (instant)
    public func loadPositionsFromDisk() -> [StakingPosition]? {
        // Return in-memory cache if available
        if !cachedPositions.isEmpty {
            return cachedPositions
        }
        
        let fileURL = cacheDirectory.appendingPathComponent(CacheConfig.positionsFileName)
        
        guard let data = try? Data(contentsOf: fileURL) else {
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let positions = try decoder.decode([StakingPosition].self, from: data)
            
            cachedPositions = positions
            return positions
        } catch {
            print("[EarnCache] Failed to decode positions: \(error)")
            return nil
        }
    }
    
    /// Load all cached data (instant)
    public func loadAllFromDisk() -> EarnCacheData? {
        guard let opportunities = loadOpportunitiesFromDisk() else {
            return nil
        }
        
        let positions = loadPositionsFromDisk() ?? []
        
        return EarnCacheData(
            opportunities: opportunities,
            positions: positions,
            lastUpdated: lastLoadTime ?? Date()
        )
    }
    
    // MARK: - Public Interface: Persistence
    
    /// Save opportunities to disk
    public func saveOpportunities(_ opportunities: [YieldOpportunity]) async throws {
        let fileURL = cacheDirectory.appendingPathComponent(CacheConfig.opportunitiesFileName)
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        let data = try encoder.encode(opportunities)
        try data.write(to: fileURL, options: .atomic)
        
        // Update in-memory cache
        cachedOpportunities = opportunities
        lastNetworkFetchTime = Date()
        
        // Update metadata
        try await saveMetadata()
    }
    
    /// Save positions to disk
    public func savePositions(_ positions: [StakingPosition]) async throws {
        let fileURL = cacheDirectory.appendingPathComponent(CacheConfig.positionsFileName)
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        let data = try encoder.encode(positions)
        try data.write(to: fileURL, options: .atomic)
        
        // Update in-memory cache
        cachedPositions = positions
    }
    
    /// Save all data to disk
    public func saveAll(_ cacheData: EarnCacheData) async throws {
        try await saveOpportunities(cacheData.opportunities)
        try await savePositions(cacheData.positions)
    }
    
    // MARK: - Cache Status
    
    /// Check if cache exists
    public var hasCache: Bool {
        !cachedOpportunities.isEmpty || fileExists(CacheConfig.opportunitiesFileName)
    }
    
    /// Check if cache is stale (older than threshold)
    public func isCacheStale() -> Bool {
        guard let lastFetch = lastNetworkFetchTime else {
            // Check file modification date
            let fileURL = cacheDirectory.appendingPathComponent(CacheConfig.opportunitiesFileName)
            guard let attrs = try? fileManager.attributesOfItem(atPath: fileURL.path),
                  let modDate = attrs[.modificationDate] as? Date else {
                return true
            }
            return Date().timeIntervalSince(modDate) > CacheConfig.staleThreshold
        }
        
        return Date().timeIntervalSince(lastFetch) > CacheConfig.staleThreshold
    }
    
    /// Check if cache is expired (too old to use)
    public func isCacheExpired() -> Bool {
        guard let lastFetch = lastNetworkFetchTime else {
            let fileURL = cacheDirectory.appendingPathComponent(CacheConfig.opportunitiesFileName)
            guard let attrs = try? fileManager.attributesOfItem(atPath: fileURL.path),
                  let modDate = attrs[.modificationDate] as? Date else {
                return true
            }
            return Date().timeIntervalSince(modDate) > CacheConfig.expiredThreshold
        }
        
        return Date().timeIntervalSince(lastFetch) > CacheConfig.expiredThreshold
    }
    
    /// Get last network fetch time
    public func getLastFetchTime() -> Date? {
        lastNetworkFetchTime
    }
    
    /// Get cached opportunities count
    public func getOpportunitiesCount() -> Int {
        cachedOpportunities.count
    }
    
    /// Get cached positions count
    public func getPositionsCount() -> Int {
        cachedPositions.count
    }
    
    // MARK: - Cache Maintenance
    
    /// Clear all cached data
    public func clearCache() throws {
        // Remove files
        let opportunitiesURL = cacheDirectory.appendingPathComponent(CacheConfig.opportunitiesFileName)
        let positionsURL = cacheDirectory.appendingPathComponent(CacheConfig.positionsFileName)
        let metadataURL = cacheDirectory.appendingPathComponent(CacheConfig.metadataFileName)
        
        try? fileManager.removeItem(at: opportunitiesURL)
        try? fileManager.removeItem(at: positionsURL)
        try? fileManager.removeItem(at: metadataURL)
        
        // Clear in-memory cache
        cachedOpportunities = []
        cachedPositions = []
        lastLoadTime = nil
        lastNetworkFetchTime = nil
    }
    
    /// Update single opportunity in cache
    public func updateOpportunity(_ opportunity: YieldOpportunity) async throws {
        var opportunities = cachedOpportunities
        
        if let index = opportunities.firstIndex(where: { $0.id == opportunity.id }) {
            opportunities[index] = opportunity
        } else {
            opportunities.append(opportunity)
        }
        
        try await saveOpportunities(opportunities)
    }
    
    /// Update single position in cache
    public func updatePosition(_ position: StakingPosition) async throws {
        var positions = cachedPositions
        
        if let index = positions.firstIndex(where: { $0.id == position.id }) {
            positions[index] = position
        } else {
            positions.append(position)
        }
        
        try await savePositions(positions)
    }
    
    /// Remove position from cache
    public func removePosition(id: String) async throws {
        cachedPositions.removeAll { $0.id == id }
        try await savePositions(cachedPositions)
    }
    
    // MARK: - Private Helpers
    
    private func fileExists(_ fileName: String) -> Bool {
        let fileURL = cacheDirectory.appendingPathComponent(fileName)
        return fileManager.fileExists(atPath: fileURL.path)
    }
    
    private func saveMetadata() async throws {
        let metadata = CacheMetadata(
            version: CacheConfig.cacheVersion,
            lastFetchTime: lastNetworkFetchTime ?? Date(),
            opportunitiesCount: cachedOpportunities.count,
            positionsCount: cachedPositions.count
        )
        
        let fileURL = cacheDirectory.appendingPathComponent(CacheConfig.metadataFileName)
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        let data = try encoder.encode(metadata)
        try data.write(to: fileURL, options: .atomic)
    }
    
    private func loadMetadata() -> CacheMetadata? {
        let fileURL = cacheDirectory.appendingPathComponent(CacheConfig.metadataFileName)
        
        guard let data = try? Data(contentsOf: fileURL) else {
            return nil
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try? decoder.decode(CacheMetadata.self, from: data)
    }
}

// MARK: - Cache Metadata

/// Metadata about the cache state
private struct CacheMetadata: Codable {
    let version: Int
    let lastFetchTime: Date
    let opportunitiesCount: Int
    let positionsCount: Int
}


