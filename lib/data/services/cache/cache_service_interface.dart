import 'dart:async';

/// Interface for cache service operations.
///
/// This service provides a unified interface for caching data with support for:
/// - Generic type handling
/// - Cache expiration policies
/// - Memory and disk cache layers
/// - Cache size management
/// - Performance monitoring
abstract class ICacheService {
  /// Retrieves a cached value by key.
  ///
  /// Returns `null` if the key doesn't exist or has expired.
  ///
  /// [key] - The unique identifier for the cached item
  /// [fromMemoryOnly] - If true, only checks memory cache (for performance-critical operations)
  Future<T?> get<T>(String key, {bool fromMemoryOnly = false});

  /// Stores a value in the cache with optional expiration.
  ///
  /// [key] - The unique identifier for the cached item
  /// [value] - The data to cache (must be JSON serializable for persistent cache)
  /// [expiry] - Optional expiration duration. If null, uses default cache policy
  /// [memoryOnly] - If true, only stores in memory cache (for temporary data)
  Future<void> set<T>(
    String key,
    T value, {
    Duration? expiry,
    bool memoryOnly = false,
  });

  /// Removes a specific item from the cache.
  ///
  /// [key] - The unique identifier for the cached item to remove
  /// [fromMemoryOnly] - If true, only removes from memory cache
  Future<void> remove(String key, {bool fromMemoryOnly = false});

  /// Clears all cached data.
  ///
  /// [memoryOnly] - If true, only clears memory cache
  Future<void> clear({bool memoryOnly = false});

  /// Checks if a key exists in the cache and hasn't expired.
  ///
  /// [key] - The unique identifier to check
  /// [checkMemoryOnly] - If true, only checks memory cache
  Future<bool> has(String key, {bool checkMemoryOnly = false});

  /// Gets the size of cached data in bytes.
  ///
  /// Returns the total size of both memory and disk cache.
  Future<int> getCacheSize();

  /// Gets cache statistics for monitoring and optimization.
  ///
  /// Returns information about cache hits, misses, and memory usage.
  Future<CacheStatistics> getStatistics();

  /// Clears expired entries from the cache.
  ///
  /// This is typically called automatically but can be triggered manually.
  Future<void> clearExpired();

  /// Sets the maximum cache size in bytes.
  ///
  /// When the cache exceeds this size, least recently used items are evicted.
  Future<void> setMaxCacheSize(int sizeInBytes);

  /// Preloads frequently accessed items into memory cache.
  ///
  /// [keys] - List of cache keys to preload
  Future<void> preload(List<String> keys);

  /// Stream of cache events for monitoring and debugging.
  ///
  /// Emits events for cache hits, misses, evictions, etc.
  Stream<CacheEvent> get events;
}

/// Statistics about cache performance and usage.
class CacheStatistics {
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

  /// Total number of cache requests
  final int totalRequests;

  /// Number of cache hits (data found in cache)
  final int hits;

  /// Number of cache misses (data not found in cache)
  final int misses;

  /// Cache hit ratio (0.0 to 1.0)
  double get hitRatio => totalRequests > 0 ? hits / totalRequests : 0.0;

  /// Current memory cache size in bytes
  final int memoryCacheSize;

  /// Current disk cache size in bytes
  final int diskCacheSize;

  /// Total cache size in bytes
  int get totalCacheSize => memoryCacheSize + diskCacheSize;

  /// Number of items in memory cache
  final int memoryItemCount;

  /// Number of items in disk cache
  final int diskItemCount;

  /// Total number of cached items
  int get totalItemCount => memoryItemCount + diskItemCount;

  /// Number of items evicted due to size constraints
  final int evictions;

  /// Number of expired items cleared
  final int expiredItems;

  /// When these statistics were last updated
  final DateTime lastUpdated;

  @override
  String toString() => 'CacheStatistics('
      'requests: $totalRequests, '
      'hitRatio: ${(hitRatio * 100).toStringAsFixed(1)}%, '
      'totalSize: ${(totalCacheSize / 1024).toStringAsFixed(1)}KB, '
      'items: $totalItemCount'
      ')';
}

/// Events emitted by the cache service for monitoring.
class CacheEvent {
  const CacheEvent({
    required this.type,
    required this.key,
    required this.timestamp,
    this.data,
  });

  factory CacheEvent.hit(String key) => CacheEvent(
        type: CacheEventType.hit,
        key: key,
        timestamp: DateTime.now(),
      );

  factory CacheEvent.miss(String key) => CacheEvent(
        type: CacheEventType.miss,
        key: key,
        timestamp: DateTime.now(),
      );

  factory CacheEvent.set(String key, {Duration? expiry}) => CacheEvent(
        type: CacheEventType.set,
        key: key,
        data: expiry != null ? {'expiry': expiry.inSeconds} : null,
        timestamp: DateTime.now(),
      );

  factory CacheEvent.eviction(String key, String reason) => CacheEvent(
        type: CacheEventType.eviction,
        key: key,
        data: {'reason': reason},
        timestamp: DateTime.now(),
      );

  /// Type of cache event
  final CacheEventType type;

  /// The cache key involved in the event
  final String key;

  /// Optional additional data about the event
  final Map<String, dynamic>? data;

  /// When the event occurred
  final DateTime timestamp;

  @override
  String toString() =>
      'CacheEvent(${type.name}: $key at ${timestamp.toIso8601String()})';
}

/// Types of cache events.
enum CacheEventType {
  /// Data was found in cache
  hit,

  /// Data was not found in cache
  miss,

  /// Data was stored in cache
  set,

  /// Data was removed from cache
  remove,

  /// Data was evicted due to size or age constraints
  eviction,

  /// Cache was cleared
  clear,

  /// Expired items were cleaned up
  cleanup,
}
