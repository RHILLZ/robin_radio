import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../exceptions/cache_service_exception.dart';
import 'cache_service_interface.dart';

/// Enhanced cache service implementation with memory and disk caching.
///
/// Features:
/// - Two-tier caching (memory + disk)
/// - Automatic expiration and cleanup
/// - Size management and LRU eviction
/// - Performance monitoring and statistics
/// - JSON serialization support
/// - Event streaming for debugging
class EnhancedCacheService implements ICacheService {
  /// Private constructor for singleton pattern
  EnhancedCacheService._();

  /// Singleton instance
  static EnhancedCacheService? _instance;

  /// Gets the singleton instance of the cache service
  static EnhancedCacheService get instance {
    _instance ??= EnhancedCacheService._();
    return _instance!;
  }

  // Cache configuration
  static const String _keyPrefix = 'robin_radio_cache_';
  static const String _metadataPrefix = '${_keyPrefix}meta_';
  static const Duration _defaultExpiry = Duration(hours: 24);
  static const int _defaultMaxCacheSize = 100 * 1024 * 1024; // 100MB
  static const int _memoryMaxItems = 1000;

  // Cache managers
  late final CacheManager _fileCacheManager;
  late final SharedPreferences _prefs;

  // Memory cache
  final Map<String, _CacheItem> _memoryCache = {};
  final List<String> _accessOrder = []; // For LRU eviction

  // Statistics
  int _totalRequests = 0;
  int _hits = 0;
  int _misses = 0;
  int _evictions = 0;
  int _expiredItems = 0;

  // Event stream
  final StreamController<CacheEvent> _eventController =
      StreamController<CacheEvent>.broadcast();

  // Configuration
  int _maxCacheSize = _defaultMaxCacheSize;
  bool _isInitialized = false;

  // Cleanup timer
  Timer? _cleanupTimer;

  /// Initialize the cache service.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize SharedPreferences
      _prefs = await SharedPreferences.getInstance();

      // Initialize file cache manager
      _fileCacheManager = CacheManager(
        Config(
          'robin_radio_cache',
          stalePeriod: _defaultExpiry,
          maxNrOfCacheObjects: 1000,
          repo: JsonCacheInfoRepository(databaseName: 'robin_radio_cache'),
          fileService: HttpFileService(),
        ),
      );

      // Start periodic cleanup
      _startPeriodicCleanup();

      _isInitialized = true;
      debugPrint('CacheService: Initialized successfully');
    } catch (e) {
      throw CacheManagementException.initializationFailed(e);
    }
  }

  @override
  Future<T?> get<T>(String key, {bool fromMemoryOnly = false}) async {
    if (!_isInitialized) await initialize();

    _validateKey(key);
    _totalRequests++;

    try {
      // Check memory cache first
      final memoryResult = _getFromMemory<T>(key);
      if (memoryResult != null) {
        _hits++;
        _eventController.add(CacheEvent.hit(key));
        return memoryResult;
      }

      // If memory-only requested, return null
      if (fromMemoryOnly) {
        _misses++;
        _eventController.add(CacheEvent.miss(key));
        return null;
      }

      // Check disk cache
      final diskResult = await _getFromDisk<T>(key);
      if (diskResult != null) {
        // Store in memory for faster future access
        _setInMemory(key, diskResult, null);
        _hits++;
        _eventController.add(CacheEvent.hit(key));
        return diskResult;
      }

      _misses++;
      _eventController.add(CacheEvent.miss(key));
      return null;
    } catch (e) {
      throw CacheReadException.keyAccessFailed(key);
    }
  }

  @override
  Future<void> set<T>(
    String key,
    T value, {
    Duration? expiry,
    bool memoryOnly = false,
  }) async {
    if (!_isInitialized) await initialize();

    _validateKey(key);
    _validateValue(value);

    final effectiveExpiry = expiry ?? _defaultExpiry;
    if (effectiveExpiry.inSeconds <= 0) {
      throw CacheConfigurationException.invalidExpiry(effectiveExpiry);
    }

    try {
      // Always store in memory cache
      _setInMemory(key, value, effectiveExpiry);

      // Store in disk cache unless memory-only
      if (!memoryOnly) {
        await _setOnDisk(key, value, effectiveExpiry);
      }

      _eventController.add(CacheEvent.set(key, expiry: effectiveExpiry));

      // Check cache size and cleanup if needed
      await _enforceMaxCacheSize();
    } catch (e) {
      throw CacheWriteException.keyWriteFailed(key, e);
    }
  }

  @override
  Future<void> remove(String key, {bool fromMemoryOnly = false}) async {
    if (!_isInitialized) await initialize();

    _validateKey(key);

    try {
      // Remove from memory cache
      _removeFromMemory(key);

      // Remove from disk cache unless memory-only
      if (!fromMemoryOnly) {
        await _removeFromDisk(key);
      }

      _eventController.add(
        CacheEvent(
          type: CacheEventType.remove,
          key: key,
          timestamp: DateTime.now(),
        ),
      );
    } catch (e) {
      throw CacheWriteException.keyWriteFailed(key, e);
    }
  }

  @override
  Future<void> clear({bool memoryOnly = false}) async {
    if (!_isInitialized) await initialize();

    try {
      // Clear memory cache
      _memoryCache.clear();
      _accessOrder.clear();

      // Clear disk cache unless memory-only
      if (!memoryOnly) {
        await _clearDiskCache();
      }

      _eventController.add(
        CacheEvent(
          type: CacheEventType.clear,
          key: 'all',
          timestamp: DateTime.now(),
        ),
      );
    } catch (e) {
      throw CacheManagementException.clearFailed(e);
    }
  }

  @override
  Future<bool> has(String key, {bool checkMemoryOnly = false}) async {
    if (!_isInitialized) await initialize();

    _validateKey(key);

    // Check memory cache
    if (_memoryCache.containsKey(key)) {
      final item = _memoryCache[key]!;
      if (!item.isExpired) {
        return true;
      } else {
        _removeFromMemory(key);
      }
    }

    // Check disk cache unless memory-only
    if (!checkMemoryOnly) {
      return _hasOnDisk(key);
    }

    return false;
  }

  @override
  Future<int> getCacheSize() async {
    if (!_isInitialized) await initialize();

    try {
      var totalSize = 0;

      // Calculate memory cache size
      for (final item in _memoryCache.values) {
        totalSize += item.estimatedSize;
      }

      // Add disk cache size
      totalSize += await _getDiskCacheSize();

      return totalSize;
    } catch (e) {
      throw CacheManagementException.sizeFailed(e);
    }
  }

  @override
  Future<CacheStatistics> getStatistics() async {
    if (!_isInitialized) await initialize();

    try {
      final diskSize = await _getDiskCacheSize();
      final diskItemCount = await _getDiskItemCount();

      return CacheStatistics(
        totalRequests: _totalRequests,
        hits: _hits,
        misses: _misses,
        memoryCacheSize: _getMemoryCacheSize(),
        diskCacheSize: diskSize,
        memoryItemCount: _memoryCache.length,
        diskItemCount: diskItemCount,
        evictions: _evictions,
        expiredItems: _expiredItems,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      throw CacheManagementException.statisticsFailed(e);
    }
  }

  @override
  Future<void> clearExpired() async {
    if (!_isInitialized) await initialize();

    try {
      var expiredCount = 0;

      // Clear expired memory cache items
      final keysToRemove = <String>[];
      for (final entry in _memoryCache.entries) {
        if (entry.value.isExpired) {
          keysToRemove.add(entry.key);
        }
      }

      for (final key in keysToRemove) {
        _removeFromMemory(key);
        expiredCount++;
      }

      // Clear expired disk cache items
      expiredCount += await _clearExpiredDiskItems();

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
    } catch (e) {
      throw CacheManagementException.cleanupFailed(e);
    }
  }

  @override
  Future<void> setMaxCacheSize(int sizeInBytes) async {
    if (sizeInBytes <= 0) {
      throw CacheConfigurationException.invalidCacheSize(sizeInBytes);
    }

    _maxCacheSize = sizeInBytes;
    await _enforceMaxCacheSize();
  }

  @override
  Future<void> preload(List<String> keys) async {
    if (!_isInitialized) await initialize();

    for (final key in keys) {
      if (!_memoryCache.containsKey(key)) {
        await get<Object?>(key); // This will load into memory if found on disk
      }
    }
  }

  @override
  Stream<CacheEvent> get events => _eventController.stream;

  /// Disposes the cache service and cleans up resources.
  Future<void> dispose() async {
    _cleanupTimer?.cancel();
    await _eventController.close();
    _memoryCache.clear();
    _accessOrder.clear();
  }

  // Private helper methods

  void _validateKey(String key) {
    if (key.isEmpty || key.contains(RegExp(r'[^\w\-_.]'))) {
      throw CacheConfigurationException.invalidKey(key);
    }
  }

  void _validateValue<T>(T value) {
    if (value == null) return;

    try {
      // Test if value can be JSON encoded
      jsonEncode(value);
    } catch (e) {
      throw CacheConfigurationException.unsupportedType(T);
    }
  }

  T? _getFromMemory<T>(String key) {
    final item = _memoryCache[key];
    if (item == null) return null;

    if (item.isExpired) {
      _removeFromMemory(key);
      return null;
    }

    // Update access order for LRU
    _updateAccessOrder(key);
    return item.value as T?;
  }

  void _setInMemory<T>(String key, T value, Duration? expiry) {
    final item = _CacheItem(
      value: value,
      expiry: expiry != null ? DateTime.now().add(expiry) : null,
    );

    _memoryCache[key] = item;
    _updateAccessOrder(key);
    _enforceLRULimit();
  }

  void _removeFromMemory(String key) {
    _memoryCache.remove(key);
    _accessOrder.remove(key);
  }

  void _updateAccessOrder(String key) {
    _accessOrder.remove(key);
    _accessOrder.add(key);
  }

  void _enforceLRULimit() {
    while (_memoryCache.length > _memoryMaxItems) {
      final oldestKey = _accessOrder.removeAt(0);
      _memoryCache.remove(oldestKey);
      _evictions++;

      _eventController.add(CacheEvent.eviction(oldestKey, 'LRU eviction'));
    }
  }

  Future<T?> _getFromDisk<T>(String key) async {
    try {
      // Get metadata
      final metadataKey = '$_metadataPrefix$key';
      final metadataJson = _prefs.getString(metadataKey);
      if (metadataJson == null) return null;

      final metadata = jsonDecode(metadataJson) as Map<String, dynamic>;
      final expiryMillis = metadata['expiry'] as int?;

      // Check expiry
      if (expiryMillis != null) {
        final expiry = DateTime.fromMillisecondsSinceEpoch(expiryMillis);
        if (DateTime.now().isAfter(expiry)) {
          await _removeFromDisk(key);
          return null;
        }
      }

      // Get data
      final dataKey = '$_keyPrefix$key';
      final dataJson = _prefs.getString(dataKey);
      if (dataJson == null) return null;

      final data = jsonDecode(dataJson);
      return data as T;
    } catch (e) {
      throw CacheReadException.deserializationFailed(key, e);
    }
  }

  Future<void> _setOnDisk<T>(String key, T value, Duration expiry) async {
    try {
      final dataKey = '$_keyPrefix$key';
      final metadataKey = '$_metadataPrefix$key';

      // Store data
      final dataJson = jsonEncode(value);
      await _prefs.setString(dataKey, dataJson);

      // Store metadata
      final metadata = {
        'expiry': DateTime.now().add(expiry).millisecondsSinceEpoch,
        'created': DateTime.now().millisecondsSinceEpoch,
        'size': dataJson.length,
      };
      await _prefs.setString(metadataKey, jsonEncode(metadata));
    } catch (e) {
      throw CacheWriteException.serializationFailed(key, e);
    }
  }

  Future<void> _removeFromDisk(String key) async {
    final dataKey = '$_keyPrefix$key';
    final metadataKey = '$_metadataPrefix$key';

    await _prefs.remove(dataKey);
    await _prefs.remove(metadataKey);
  }

  Future<bool> _hasOnDisk(String key) async {
    final metadataKey = '$_metadataPrefix$key';
    final metadataJson = _prefs.getString(metadataKey);
    if (metadataJson == null) return false;

    try {
      final metadata = jsonDecode(metadataJson) as Map<String, dynamic>;
      final expiryMillis = metadata['expiry'] as int?;

      if (expiryMillis != null) {
        final expiry = DateTime.fromMillisecondsSinceEpoch(expiryMillis);
        if (DateTime.now().isAfter(expiry)) {
          await _removeFromDisk(key);
          return false;
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _clearDiskCache() async {
    final keys = _prefs.getKeys().where(
          (key) =>
              key.startsWith(_keyPrefix) || key.startsWith(_metadataPrefix),
        );

    for (final key in keys) {
      await _prefs.remove(key);
    }
  }

  Future<int> _getDiskCacheSize() async {
    var totalSize = 0;
    final keys =
        _prefs.getKeys().where((key) => key.startsWith(_metadataPrefix));

    for (final key in keys) {
      final metadataJson = _prefs.getString(key);
      if (metadataJson != null) {
        try {
          final metadata = jsonDecode(metadataJson) as Map<String, dynamic>;
          totalSize += metadata['size'] as int? ?? 0;
        } catch (e) {
          // Skip corrupted metadata
        }
      }
    }

    return totalSize;
  }

  Future<int> _getDiskItemCount() async =>
      _prefs.getKeys().where((key) => key.startsWith(_keyPrefix)).length;

  int _getMemoryCacheSize() {
    var totalSize = 0;
    for (final item in _memoryCache.values) {
      totalSize += item.estimatedSize;
    }
    return totalSize;
  }

  Future<int> _clearExpiredDiskItems() async {
    var expiredCount = 0;
    final metadataKeys = _prefs
        .getKeys()
        .where((key) => key.startsWith(_metadataPrefix))
        .toList();

    for (final metadataKey in metadataKeys) {
      final metadataJson = _prefs.getString(metadataKey);
      if (metadataJson != null) {
        try {
          final metadata = jsonDecode(metadataJson) as Map<String, dynamic>;
          final expiryMillis = metadata['expiry'] as int?;

          if (expiryMillis != null) {
            final expiry = DateTime.fromMillisecondsSinceEpoch(expiryMillis);
            if (DateTime.now().isAfter(expiry)) {
              final key = metadataKey.substring(_metadataPrefix.length);
              await _removeFromDisk(key);
              expiredCount++;
            }
          }
        } catch (e) {
          // Remove corrupted metadata
          await _prefs.remove(metadataKey);
          expiredCount++;
        }
      }
    }

    return expiredCount;
  }

  Future<void> _enforceMaxCacheSize() async {
    final currentSize = await getCacheSize();
    if (currentSize > _maxCacheSize) {
      // Implement size-based eviction
      await _evictOldestItems(currentSize - _maxCacheSize);
    }
  }

  Future<void> _evictOldestItems(int bytesToEvict) async {
    var evictedBytes = 0;
    final metadataKeys = _prefs
        .getKeys()
        .where((key) => key.startsWith(_metadataPrefix))
        .toList();

    // Sort by creation time (oldest first)
    final items = <String, int>{};
    for (final metadataKey in metadataKeys) {
      final metadataJson = _prefs.getString(metadataKey);
      if (metadataJson != null) {
        try {
          final metadata = jsonDecode(metadataJson) as Map<String, dynamic>;
          final created = metadata['created'] as int? ?? 0;
          items[metadataKey] = created;
        } catch (e) {
          // Skip corrupted metadata
        }
      }
    }

    final sortedKeys = items.keys.toList()
      ..sort((a, b) => items[a]!.compareTo(items[b]!));

    for (final metadataKey in sortedKeys) {
      if (evictedBytes >= bytesToEvict) break;

      final metadataJson = _prefs.getString(metadataKey);
      if (metadataJson != null) {
        try {
          final metadata = jsonDecode(metadataJson) as Map<String, dynamic>;
          final size = metadata['size'] as int? ?? 0;
          final key = metadataKey.substring(_metadataPrefix.length);

          await _removeFromDisk(key);
          _removeFromMemory(key);

          evictedBytes += size;
          _evictions++;

          _eventController.add(CacheEvent.eviction(key, 'Size limit eviction'));
        } catch (e) {
          // Skip corrupted items
        }
      }
    }
  }

  void _startPeriodicCleanup() {
    _cleanupTimer = Timer.periodic(const Duration(hours: 1), (_) {
      clearExpired().catchError((Object e) {
        debugPrint('CacheService: Periodic cleanup failed: $e');
      });
    });
  }

  int _estimateSize(Object? value) {
    if (value == null) return 0;

    try {
      final serialized = value.toString();
      return serialized.length * 2; // Approximate UTF-16 size
    } catch (e) {
      return 100; // Default estimate
    }
  }
}

/// Internal cache item representation for memory cache.
class _CacheItem {
  _CacheItem({
    required this.value,
    this.expiry,
  }) : created = DateTime.now();
  final dynamic value;
  final DateTime? expiry;
  final DateTime created;

  bool get isExpired => expiry != null && DateTime.now().isAfter(expiry!);

  int get estimatedSize {
    try {
      final json = jsonEncode(value);
      return json.length * 2; // Approximate UTF-16 size
    } catch (e) {
      return 100; // Default estimate for non-serializable objects
    }
  }
}
