import 'dart:async';

/// Comprehensive cache service interface for data persistence and performance optimization.
///
/// Provides a unified, type-safe interface for caching data with advanced features including:
/// - **Multi-layer caching**: Fast memory cache with persistent disk cache fallback
/// - **Generic type support**: Type-safe storage and retrieval of any serializable data
/// - **Expiration policies**: Automatic cleanup of expired entries with customizable TTL
/// - **Size management**: LRU eviction when cache size limits are exceeded
/// - **Performance monitoring**: Real-time statistics and event streams for optimization
/// - **Selective operations**: Memory-only operations for temporary high-speed caching
///
/// The service automatically manages cache layers, preferring memory cache for speed
/// and falling back to disk cache for persistence. Data is automatically serialized
/// for disk storage and deserialized on retrieval.
///
/// Usage patterns:
/// ```dart
/// // Store data with automatic expiration
/// await cache.set('user:123', userData, expiry: Duration(hours: 1));
///
/// // Retrieve with type safety
/// final user = await cache.get<UserData>('user:123');
///
/// // Fast memory-only operations
/// await cache.set('temp:data', tempData, memoryOnly: true);
///
/// // Monitor cache performance
/// cache.events.listen((event) => print('Cache ${event.type}: ${event.key}'));
/// ```
///
/// Thread-safe operations are guaranteed, and the service handles concurrent
/// access gracefully. All methods return [Future]s for asynchronous operation.
abstract class ICacheService {
  /// Retrieves a cached value by key with type safety.
  ///
  /// Searches for data in the cache hierarchy: memory cache first for speed,
  /// then disk cache for persistence. Returns null if the key doesn't exist,
  /// has expired, or cannot be deserialized to the expected type.
  ///
  /// Type parameter [T] ensures compile-time type safety and automatic
  /// deserialization to the expected data structure.
  ///
  /// [key] The unique identifier for the cached item. Should be a valid
  ///      string that can be used as a file name for disk cache.
  /// [fromMemoryOnly] If true, only checks memory cache, skipping disk cache.
  ///                 Useful for performance-critical operations where disk
  ///                 I/O latency is unacceptable.
  ///
  /// Returns the cached data of type [T], or null if not found or expired.
  ///
  /// Example:
  /// ```dart
  /// final albumData = await cache.get<List<Album>>('albums:recent');
  /// if (albumData != null) {
  ///   // Use cached data
  /// } else {
  ///   // Data not cached, fetch from source
  /// }
  /// ```
  Future<T?> get<T>(String key, {bool fromMemoryOnly = false});

  /// Stores a value in the cache with optional expiration and layer selection.
  ///
  /// Persists data in the cache system with automatic serialization for disk
  /// storage. Data is stored in both memory and disk cache layers unless
  /// [memoryOnly] is specified. Expired entries are automatically cleaned up.
  ///
  /// Type parameter [T] enables type-safe storage of any serializable data
  /// structure. Complex objects should implement proper JSON serialization.
  ///
  /// [key] The unique identifier for the cached item. Must be non-empty and
  ///      should be a valid filename for disk cache storage.
  /// [value] The data to cache. Must be JSON serializable for persistent
  ///        cache storage. Primitives, Maps, Lists, and JSON-serializable
  ///        objects are supported.
  /// [expiry] Optional expiration duration from now. If null, uses the default
  ///         cache policy. Expired items are automatically removed during
  ///         cleanup operations.
  /// [memoryOnly] If true, only stores in memory cache for temporary data
  ///             that doesn't need persistence across app restarts.
  ///
  /// Example:
  /// ```dart
  /// // Cache with 1-hour expiration
  /// await cache.set('user:profile', userProfile, expiry: Duration(hours: 1));
  ///
  /// // Temporary memory-only cache
  /// await cache.set('ui:state', uiState, memoryOnly: true);
  /// ```
  Future<void> set<T>(
    String key,
    T value, {
    Duration? expiry,
    bool memoryOnly = false,
  });

  /// Removes a specific item from the cache by key.
  ///
  /// Deletes the cached item from the specified cache layer(s). The removal
  /// is immediate and cannot be undone. If the key doesn't exist, the
  /// operation completes successfully without error.
  ///
  /// [key] The unique identifier for the cached item to remove.
  /// [fromMemoryOnly] If true, only removes from memory cache, leaving any
  ///                 disk cache entry intact. Useful for selective cleanup
  ///                 while preserving persistent data.
  ///
  /// Example:
  /// ```dart
  /// // Remove from all cache layers
  /// await cache.remove('user:temp');
  ///
  /// // Remove only from memory, keep disk cache
  /// await cache.remove('large:dataset', fromMemoryOnly: true);
  /// ```
  Future<void> remove(String key, {bool fromMemoryOnly = false});

  /// Clears all cached data from specified cache layers.
  ///
  /// Performs a complete cache reset, removing all stored items. This is
  /// a destructive operation that cannot be undone. Use with caution as
  /// it will remove all cached application data.
  ///
  /// [memoryOnly] If true, only clears memory cache, preserving disk cache
  ///             entries. Useful for memory pressure relief while maintaining
  ///             persistent cache data across app sessions.
  ///
  /// Example:
  /// ```dart
  /// // Clear all cache data
  /// await cache.clear();
  ///
  /// // Clear only memory cache
  /// await cache.clear(memoryOnly: true);
  /// ```
  Future<void> clear({bool memoryOnly = false});

  /// Checks if a key exists in the cache and hasn't expired.
  ///
  /// Verifies the presence of a cache entry without retrieving the actual
  /// data. This is more efficient than calling [get] when you only need
  /// to check existence. Expired entries return false.
  ///
  /// [key] The unique identifier to check for existence.
  /// [checkMemoryOnly] If true, only checks memory cache, ignoring disk
  ///                  cache entries. Useful for verifying fast-access data.
  ///
  /// Returns true if the key exists and is not expired, false otherwise.
  ///
  /// Example:
  /// ```dart
  /// if (await cache.has('user:settings')) {
  ///   // Settings are cached, safe to retrieve
  ///   final settings = await cache.get<UserSettings>('user:settings');
  /// }
  /// ```
  Future<bool> has(String key, {bool checkMemoryOnly = false});

  /// Gets the total size of cached data in bytes across all cache layers.
  ///
  /// Calculates the storage space consumed by cache data including both
  /// memory and disk cache layers. This includes metadata overhead and
  /// serialization overhead for disk storage.
  ///
  /// Returns the total cache size in bytes. Useful for cache size monitoring
  /// and storage management decisions.
  ///
  /// Example:
  /// ```dart
  /// final sizeBytes = await cache.getCacheSize();
  /// final sizeMB = sizeBytes / (1024 * 1024);
  /// print('Cache size: ${sizeMB.toStringAsFixed(1)} MB');
  /// ```
  Future<int> getCacheSize();

  /// Gets comprehensive cache statistics for monitoring and optimization.
  ///
  /// Provides detailed performance metrics including hit/miss ratios,
  /// cache sizes, item counts, and eviction statistics. Essential for
  /// cache performance tuning and application optimization.
  ///
  /// Returns [CacheStatistics] object containing current cache metrics.
  /// Statistics are calculated at the time of the call and reflect the
  /// current state of the cache system.
  ///
  /// Example:
  /// ```dart
  /// final stats = await cache.getStatistics();
  /// print('Hit ratio: ${(stats.hitRatio * 100).toStringAsFixed(1)}%');
  /// print('Total items: ${stats.totalItemCount}');
  /// ```
  Future<CacheStatistics> getStatistics();

  /// Clears expired entries from the cache manually.
  ///
  /// Performs immediate cleanup of expired cache entries across all cache
  /// layers. While the cache service automatically performs periodic cleanup,
  /// this method allows manual triggering for immediate memory/disk recovery.
  ///
  /// This operation scans all cache entries and removes those past their
  /// expiration time. It's safe to call frequently but may impact performance
  /// during execution on large caches.
  ///
  /// Example:
  /// ```dart
  /// // Manual cleanup before memory-intensive operations
  /// await cache.clearExpired();
  /// ```
  Future<void> clearExpired();

  /// Sets the maximum cache size in bytes with automatic LRU eviction.
  ///
  /// Configures cache size limits to prevent unbounded growth. When the cache
  /// exceeds this size, least recently used (LRU) items are automatically
  /// evicted to maintain the size constraint.
  ///
  /// [sizeInBytes] Maximum allowed cache size in bytes. Must be positive.
  ///              Setting a very small size may cause excessive eviction.
  ///              Recommended minimum is 1MB for normal operation.
  ///
  /// Size limit applies to the total cache footprint including metadata.
  /// Memory and disk caches may have separate internal limits.
  ///
  /// Example:
  /// ```dart
  /// // Set 50MB cache limit
  /// await cache.setMaxCacheSize(50 * 1024 * 1024);
  /// ```
  Future<void> setMaxCacheSize(int sizeInBytes);

  /// Preloads frequently accessed items into memory cache for optimal performance.
  ///
  /// Moves specified cache entries from disk to memory cache to eliminate
  /// disk I/O latency for subsequent access. This is a performance optimization
  /// technique for predictable access patterns.
  ///
  /// [keys] List of cache keys to preload into memory. Non-existent keys
  ///       are silently ignored. Keys already in memory cache are skipped.
  ///
  /// Preloading is performed asynchronously and completes when all available
  /// items have been loaded into memory cache.
  ///
  /// Example:
  /// ```dart
  /// // Preload critical data at app startup
  /// await cache.preload(['user:profile', 'app:settings', 'recent:albums']);
  /// ```
  Future<void> preload(List<String> keys);

  /// Stream of cache events for real-time monitoring and debugging.
  ///
  /// Provides a continuous stream of cache operation events including hits,
  /// misses, sets, evictions, and cleanup operations. Essential for cache
  /// behavior analysis, performance debugging, and usage analytics.
  ///
  /// Events are emitted in real-time as operations occur. The stream remains
  /// active for the lifetime of the cache service and should be managed
  /// appropriately to prevent memory leaks.
  ///
  /// Event types include:
  /// - **Hit**: Data found in cache
  /// - **Miss**: Data not found in cache
  /// - **Set**: Data stored in cache
  /// - **Eviction**: Data removed due to size/age constraints
  /// - **Clear**: Cache cleared
  /// - **Cleanup**: Expired items removed
  ///
  /// Example:
  /// ```dart
  /// cache.events.listen((event) {
  ///   switch (event.type) {
  ///     case CacheEventType.hit:
  ///       print('Cache hit: ${event.key}');
  ///       break;
  ///     case CacheEventType.miss:
  ///       print('Cache miss: ${event.key}');
  ///       break;
  ///   }
  /// });
  /// ```
  Stream<CacheEvent> get events;
}

/// Comprehensive statistics about cache performance and resource usage.
///
/// Provides detailed metrics for cache performance analysis, optimization
/// decisions, and resource management. All statistics represent the current
/// state of the cache system at the time of collection.
///
/// Use these metrics to:
/// - Monitor cache effectiveness through hit ratios
/// - Track resource usage and plan capacity
/// - Identify performance bottlenecks
/// - Optimize cache configuration and size limits
class CacheStatistics {
  /// Creates a new CacheStatistics instance with the specified metrics.
  ///
  /// All parameters represent current cache state and should be collected
  /// atomically to ensure consistency across related metrics.
  const CacheStatistics({
    required this.totalRequests,
    required this.hits,
    required this.misses,
    required this.memoryCacheSize,
    required this.diskCacheSize,
    required this.memoryItemCount,
    required this.diskItemCount,
    required this.evictions,
    required this.expiredItems,
    required this.lastUpdated,
  });

  /// Total number of cache requests since service initialization.
  ///
  /// Includes both successful hits and misses. Used as the denominator
  /// for calculating hit ratios and cache effectiveness metrics.
  final int totalRequests;

  /// Number of cache hits where data was found in cache.
  ///
  /// Represents successful cache retrievals that avoided expensive
  /// data source operations. Higher values indicate better cache effectiveness.
  final int hits;

  /// Number of cache misses where data was not found in cache.
  ///
  /// Represents cache requests that required fallback to data sources.
  /// High miss rates may indicate poor cache configuration or usage patterns.
  final int misses;

  /// Cache hit ratio as a value between 0.0 and 1.0.
  ///
  /// Calculated as hits / totalRequests. Values closer to 1.0 indicate
  /// more effective caching. A ratio below 0.5 suggests cache optimization
  /// opportunities.
  ///
  /// Returns 0.0 if no requests have been made yet.
  double get hitRatio => totalRequests > 0 ? hits / totalRequests : 0.0;

  /// Current memory cache size in bytes.
  ///
  /// Represents the RAM usage of cached data including object overhead.
  /// Memory cache provides fastest access but is limited by available RAM.
  final int memoryCacheSize;

  /// Current disk cache size in bytes.
  ///
  /// Represents the disk storage used by cached data including serialization
  /// overhead and metadata. Disk cache provides persistence but slower access.
  final int diskCacheSize;

  /// Total cache size across all storage layers in bytes.
  ///
  /// Sum of memory and disk cache sizes. Useful for overall storage
  /// usage monitoring and capacity planning.
  int get totalCacheSize => memoryCacheSize + diskCacheSize;

  /// Number of items currently stored in memory cache.
  ///
  /// Represents the count of cached objects in RAM. Memory cache typically
  /// holds frequently accessed items for optimal performance.
  final int memoryItemCount;

  /// Number of items currently stored in disk cache.
  ///
  /// Represents the count of cached objects on disk. Disk cache provides
  /// persistence and larger capacity than memory cache.
  final int diskItemCount;

  /// Total number of cached items across all storage layers.
  ///
  /// Sum of memory and disk cache item counts. Note that items may exist
  /// in both layers, so this represents unique cache entries.
  int get totalItemCount => memoryItemCount + diskItemCount;

  /// Number of items evicted due to size or policy constraints.
  ///
  /// Represents cache entries removed to make space for new data when
  /// cache size limits are exceeded. High eviction rates may indicate
  /// insufficient cache size allocation.
  final int evictions;

  /// Number of expired items automatically removed from cache.
  ///
  /// Represents cache entries removed due to TTL expiration. Normal
  /// operation for time-sensitive data, but unexpected expiration
  /// may indicate incorrect TTL configuration.
  final int expiredItems;

  /// Timestamp when these statistics were last collected.
  ///
  /// Indicates the freshness of the statistics data. Cache statistics
  /// should be refreshed periodically for accurate monitoring.
  final DateTime lastUpdated;

  /// Returns a human-readable summary of cache statistics.
  ///
  /// Provides a concise overview of cache performance including hit ratio,
  /// total size in KB, and item count. Useful for logging and debugging.
  @override
  String toString() => 'CacheStatistics('
      'requests: $totalRequests, '
      'hitRatio: ${(hitRatio * 100).toStringAsFixed(1)}%, '
      'totalSize: ${(totalCacheSize / 1024).toStringAsFixed(1)}KB, '
      'items: $totalItemCount'
      ')';
}

/// Represents a cache operation event for monitoring and debugging.
///
/// Cache events provide real-time insight into cache behavior, enabling
/// performance monitoring, debugging, and usage analytics. Events are
/// emitted for all significant cache operations.
///
/// Events include contextual data such as timestamps, cache keys, and
/// operation-specific metadata for comprehensive analysis.
class CacheEvent {
  /// Creates a new cache event with the specified details.
  ///
  /// [type] The type of cache operation that occurred.
  /// [key] The cache key involved in the operation.
  /// [timestamp] When the event occurred.
  /// [data] Optional additional context about the operation.
  const CacheEvent({
    required this.type,
    required this.key,
    required this.timestamp,
    this.data,
  });

  /// Creates a cache hit event indicating successful data retrieval.
  ///
  /// [key] The cache key that was successfully found.
  factory CacheEvent.hit(String key) => CacheEvent(
        type: CacheEventType.hit,
        key: key,
        timestamp: DateTime.now(),
      );

  /// Creates a cache miss event indicating data was not found.
  ///
  /// [key] The cache key that was not found in the cache.
  factory CacheEvent.miss(String key) => CacheEvent(
        type: CacheEventType.miss,
        key: key,
        timestamp: DateTime.now(),
      );

  /// Creates a cache set event indicating data was stored.
  ///
  /// [key] The cache key where data was stored.
  /// [expiry] Optional expiration duration for the cached data.
  factory CacheEvent.set(String key, {Duration? expiry}) => CacheEvent(
        type: CacheEventType.set,
        key: key,
        data: expiry != null ? {'expiry': expiry.inSeconds} : null,
        timestamp: DateTime.now(),
      );

  /// Creates a cache eviction event indicating data was removed.
  ///
  /// [key] The cache key that was evicted.
  /// [reason] The reason for eviction (e.g., "size_limit", "lru_policy").
  factory CacheEvent.eviction(String key, String reason) => CacheEvent(
        type: CacheEventType.eviction,
        key: key,
        data: {'reason': reason},
        timestamp: DateTime.now(),
      );

  /// The type of cache operation that occurred.
  ///
  /// Categorizes the event for filtering and analysis. Different event
  /// types may include different contextual data in the [data] field.
  final CacheEventType type;

  /// The cache key involved in the operation.
  ///
  /// Identifies which cached item was affected by the operation.
  /// Useful for tracking access patterns and debugging specific keys.
  final String key;

  /// Optional additional context data about the event.
  ///
  /// Contains operation-specific information such as expiration times,
  /// eviction reasons, or other relevant metadata. The structure depends
  /// on the event type.
  final Map<String, dynamic>? data;

  /// Timestamp when the cache event occurred.
  ///
  /// Enables temporal analysis of cache behavior and performance tracking
  /// over time. Events are timestamped when they occur, not when observed.
  final DateTime timestamp;

  /// Returns a human-readable representation of the cache event.
  ///
  /// Includes event type, cache key, and timestamp in ISO format.
  /// Useful for logging and debugging cache behavior.
  @override
  String toString() =>
      'CacheEvent(${type.name}: $key at ${timestamp.toIso8601String()})';
}

/// Enumeration of cache event types for operation categorization.
///
/// Defines all possible cache operations that generate events. Used for
/// filtering, analysis, and handling specific types of cache behavior.
enum CacheEventType {
  /// Data was successfully found in cache during a get operation.
  ///
  /// Indicates effective cache usage and good performance. High hit
  /// rates suggest optimal cache configuration and usage patterns.
  hit,

  /// Data was not found in cache during a get operation.
  ///
  /// Requires fallback to data source, indicating cache miss. High miss
  /// rates may suggest cache size, TTL, or usage pattern issues.
  miss,

  /// Data was successfully stored in cache during a set operation.
  ///
  /// Normal cache population operation. Frequent sets may indicate
  /// high data turnover or insufficient cache hit rates.
  set,

  /// Data was manually removed from cache during a remove operation.
  ///
  /// Explicit cache invalidation, typically triggered by application
  /// logic when data becomes stale or invalid.
  remove,

  /// Data was automatically removed due to size or age constraints.
  ///
  /// Automatic cache management operation. High eviction rates may
  /// indicate insufficient cache size or aggressive TTL policies.
  eviction,

  /// Cache was completely cleared of all data.
  ///
  /// Bulk cache invalidation operation, typically during app reset,
  /// user logout, or cache corruption recovery.
  clear,

  /// Expired items were automatically removed during cleanup.
  ///
  /// Normal cache maintenance operation removing time-expired entries.
  /// Regular cleanup events indicate healthy TTL policy enforcement.
  cleanup,
}
