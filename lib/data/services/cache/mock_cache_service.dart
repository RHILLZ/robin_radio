import 'dart:async';

import '../../exceptions/cache_service_exception.dart';
import 'cache_service_interface.dart';

/// Mock implementation of cache service for testing purposes.
///
/// This implementation stores all data in memory and simulates
/// cache behavior without any actual persistence.
class MockCacheService implements ICacheService {
  // Mock storage
  final Map<String, _MockCacheItem> _cache = {};
  final StreamController<CacheEvent> _eventController =
      StreamController<CacheEvent>.broadcast();

  // Mock statistics
  int _totalRequests = 0;
  int _hits = 0;
  int _misses = 0;
  int _evictions = 0;
  int _expiredItems = 0;

  // Configuration
  int _maxCacheSize = 50 * 1024 * 1024; // 50MB for testing
  final Duration _defaultExpiry = const Duration(hours: 1);

  @override
  Future<T?> get<T>(String key, {bool fromMemoryOnly = false}) async {
    _totalRequests++;

    if (_cache.containsKey(key)) {
      final item = _cache[key]!;

      if (item.isExpired) {
        _cache.remove(key);
        _expiredItems++;
        _misses++;
        _eventController.add(CacheEvent.miss(key));
        return null;
      }

      _hits++;
      _eventController.add(CacheEvent.hit(key));
      return item.value as T?;
    }

    _misses++;
    _eventController.add(CacheEvent.miss(key));
    return null;
  }

  @override
  Future<void> set<T>(
    String key,
    T value, {
    Duration? expiry,
    bool memoryOnly = false,
  }) async {
    final effectiveExpiry = expiry ?? _defaultExpiry;

    final item = _MockCacheItem(
      value: value,
      expiry: DateTime.now().add(effectiveExpiry),
      size: _estimateSize(value),
    );

    _cache[key] = item;
    _eventController.add(CacheEvent.set(key, expiry: effectiveExpiry));

    // Simulate size management
    await _enforceSizeLimit();
  }

  @override
  Future<void> remove(String key, {bool fromMemoryOnly = false}) async {
    if (_cache.containsKey(key)) {
      _cache.remove(key);
      _eventController.add(
        CacheEvent(
          type: CacheEventType.remove,
          key: key,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  @override
  Future<void> clear({bool memoryOnly = false}) async {
    _cache.clear();
    _eventController.add(
      CacheEvent(
        type: CacheEventType.clear,
        key: 'all',
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  Future<bool> has(String key, {bool checkMemoryOnly = false}) async {
    if (_cache.containsKey(key)) {
      final item = _cache[key]!;
      if (item.isExpired) {
        _cache.remove(key);
        _expiredItems++;
        return false;
      }
      return true;
    }
    return false;
  }

  @override
  Future<int> getCacheSize() async {
    var totalSize = 0;
    for (final item in _cache.values) {
      totalSize += item.size;
    }
    return totalSize;
  }

  @override
  Future<CacheStatistics> getStatistics() async {
    final cacheSize = await getCacheSize();

    return CacheStatistics(
      totalRequests: _totalRequests,
      hits: _hits,
      misses: _misses,
      memoryCacheSize: cacheSize,
      diskCacheSize: 0, // Mock has no disk cache
      memoryItemCount: _cache.length,
      diskItemCount: 0,
      evictions: _evictions,
      expiredItems: _expiredItems,
      lastUpdated: DateTime.now(),
    );
  }

  @override
  Future<void> clearExpired() async {
    final keysToRemove = <String>[];
    var expiredCount = 0;

    for (final entry in _cache.entries) {
      if (entry.value.isExpired) {
        keysToRemove.add(entry.key);
        expiredCount++;
      }
    }

    for (final key in keysToRemove) {
      _cache.remove(key);
    }

    _expiredItems += expiredCount;

    if (expiredCount > 0) {
      _eventController.add(
        CacheEvent(
          type: CacheEventType.cleanup,
          key: 'expired',
          data: {'count': expiredCount},
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  @override
  Future<void> setMaxCacheSize(int sizeInBytes) async {
    if (sizeInBytes <= 0) {
      throw CacheConfigurationException.invalidCacheSize(sizeInBytes);
    }
    _maxCacheSize = sizeInBytes;
    await _enforceSizeLimit();
  }

  @override
  Future<void> preload(List<String> keys) async {
    // Mock implementation - just check if keys exist
    for (final key in keys) {
      await get<Object?>(key);
    }
  }

  @override
  Stream<CacheEvent> get events => _eventController.stream;

  /// Dispose the mock cache service.
  Future<void> dispose() async {
    _cache.clear();
    await _eventController.close();
  }

  /// Reset all statistics and cache data (useful for testing).
  void reset() {
    _cache.clear();
    _totalRequests = 0;
    _hits = 0;
    _misses = 0;
    _evictions = 0;
    _expiredItems = 0;
  }

  /// Manually expire items (useful for testing expiration behavior).
  void expireItem(String key) {
    if (_cache.containsKey(key)) {
      final item = _cache[key]!;
      _cache[key] = _MockCacheItem(
        value: item.value,
        expiry: DateTime.now().subtract(const Duration(seconds: 1)),
        size: item.size,
      );
    }
  }

  /// Add multiple test items at once.
  Future<void> addTestItems(Map<String, dynamic> items) async {
    for (final entry in items.entries) {
      await set(entry.key, entry.value);
    }
  }

  /// Get current cache contents (for testing/debugging).
  Map<String, dynamic> getCacheContents() {
    final result = <String, dynamic>{};
    for (final entry in _cache.entries) {
      if (!entry.value.isExpired) {
        result[entry.key] = entry.value.value;
      }
    }
    return result;
  }

  /// Simulate cache errors for testing error handling.
  bool _shouldSimulateError = false;
  String _errorType = '';

  /// Simulates cache errors for testing purposes.
  ///
  /// [errorType] The type of error to simulate (e.g., 'read_failure', 'write_failure').
  void simulateError(String errorType) {
    _shouldSimulateError = true;
    _errorType = errorType;
  }

  /// Stops simulating cache errors and returns to normal operation.
  void stopSimulatingErrors() {
    _shouldSimulateError = false;
    _errorType = '';
  }

  // ignore: unused_element
  void _checkForSimulatedErrors() {
    if (!_shouldSimulateError) {
      return;
    }

    switch (_errorType) {
      case 'read':
        throw const CacheReadException.diskAccessFailed('Simulated read error');
      case 'write':
        throw const CacheWriteException.diskAccessFailed(
          'Simulated write error',
        );
      case 'management':
        throw const CacheManagementException.clearFailed(
          'Simulated management error',
        );
      default:
        throw CacheManagementException.initializationFailed(
          'Simulated error: $_errorType',
        );
    }
  }

  // Private helper methods

  Future<void> _enforceSizeLimit() async {
    final currentSize = await getCacheSize();
    if (currentSize <= _maxCacheSize) {
      return;
    }

    // Sort items by creation time (oldest first)
    final sortedEntries = _cache.entries.toList()
      ..sort((a, b) => a.value.created.compareTo(b.value.created));

    var evictedSize = 0;
    final targetReduction = currentSize - _maxCacheSize;

    for (final entry in sortedEntries) {
      if (evictedSize >= targetReduction) {
        break;
      }

      evictedSize += entry.value.size;
      _cache.remove(entry.key);
      _evictions++;

      _eventController
          .add(CacheEvent.eviction(entry.key, 'Size limit eviction'));
    }
  }

  int _estimateSize(Object? value) {
    if (value == null) {
      return 0;
    }

    try {
      final serialized = value.toString();
      return serialized.length * 2; // Approximate UTF-16 size
    } on Exception {
      return 100; // Default estimate
    }
  }
}

/// Internal cache item for mock implementation.
class _MockCacheItem {
  _MockCacheItem({
    required this.value,
    required this.expiry,
    required this.size,
  }) : created = DateTime.now();
  final dynamic value;
  final DateTime expiry;
  final DateTime created;
  final int size;

  bool get isExpired => DateTime.now().isAfter(expiry);
}
