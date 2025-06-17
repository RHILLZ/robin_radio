import 'app_exception.dart';

/// Base exception class for cache service errors and storage operations.
///
/// Serves as the parent class for all cache-related exceptions in the app.
/// Provides common behavior for cache errors including recovery capabilities
/// and categorization for proper error handling and diagnostics.
abstract class CacheServiceException extends AppException {
  /// Creates a new CacheServiceException with the specified message and error code.
  ///
  /// [message] Description of the cache service error.
  /// [errorCode] Machine-readable error code for programmatic handling.
  /// [cause] Optional underlying cause of the cache service error.
  const CacheServiceException(super.message, super.errorCode, [super.cause]);

  @override
  String get category => 'cache';

  @override
  bool get isRecoverable => true; // Most cache errors can be retried
}

/// Exception thrown when cache read operations fail.
///
/// Handles various read-related errors including key access failures,
/// data corruption, deserialization problems, and disk access issues.
/// These errors typically occur when retrieving cached data.
class CacheReadException extends CacheServiceException {
  /// Creates a new CacheReadException with the specified message and error code.
  ///
  /// [message] Description of the cache read error.
  /// [errorCode] Machine-readable error code for programmatic handling.
  /// [cause] Optional underlying cause of the cache read error.
  const CacheReadException(super.message, super.errorCode, [super.cause]);

  /// Creates a read exception for when a cache key cannot be accessed.
  ///
  /// Used when attempting to read from a cache key that exists but
  /// cannot be accessed due to permission or file system issues.
  ///
  /// [key] The cache key that could not be accessed.
  const CacheReadException.keyAccessFailed(String key)
      : super(
          'Failed to read cache data for key: $key',
          'CACHE_READ_KEY_ACCESS_FAILED',
        );

  /// Creates a read exception for serialization failures.
  ///
  /// Used when cached data exists but cannot be properly deserialized
  /// back into the expected object type due to format changes or corruption.
  ///
  /// [key] The cache key that failed deserialization.
  /// [cause] The underlying deserialization error.
  const CacheReadException.deserializationFailed(String key, cause)
      : super(
          'Failed to deserialize cached data for key: $key',
          'CACHE_READ_DESERIALIZATION_FAILED',
          cause,
        );

  /// Creates a read exception for corrupted cache data.
  ///
  /// Used when cache data has been detected as corrupted or invalid,
  /// requiring the data to be discarded and re-fetched from source.
  ///
  /// [key] The cache key containing corrupted data.
  const CacheReadException.corruptedData(String key)
      : super(
          'Cache data is corrupted for key: $key',
          'CACHE_READ_CORRUPTED_DATA',
        );

  /// Creates a read exception for disk access failures.
  ///
  /// Used when the cache storage system cannot be accessed due to
  /// file system errors, permission issues, or hardware problems.
  ///
  /// [cause] Optional underlying disk access error.
  const CacheReadException.diskAccessFailed([cause])
      : super(
          'Failed to access disk cache storage',
          'CACHE_READ_DISK_ACCESS_FAILED',
          cause,
        );
}

/// Exception thrown when cache write operations fail.
///
/// Handles various write-related errors including key write failures,
/// serialization problems, disk space issues, and storage access problems.
/// These errors typically occur when storing data to cache.
class CacheWriteException extends CacheServiceException {
  /// Creates a new CacheWriteException with the specified message and error code.
  ///
  /// [message] Description of the cache write error.
  /// [errorCode] Machine-readable error code for programmatic handling.
  /// [cause] Optional underlying cause of the cache write error.
  const CacheWriteException(super.message, super.errorCode, [super.cause]);

  /// Creates a write exception for when a cache key cannot be written.
  ///
  /// Used when attempting to write data to a cache key fails due to
  /// storage issues, permission problems, or file system errors.
  ///
  /// [key] The cache key that could not be written.
  /// [cause] Optional underlying write error.
  const CacheWriteException.keyWriteFailed(String key, [cause])
      : super(
          'Failed to write cache data for key: $key',
          'CACHE_WRITE_KEY_FAILED',
          cause,
        );

  /// Creates a write exception for serialization failures.
  ///
  /// Used when data cannot be properly serialized for storage in the cache,
  /// preventing the data from being saved for future retrieval.
  ///
  /// [key] The cache key that failed serialization.
  /// [cause] The underlying serialization error.
  const CacheWriteException.serializationFailed(String key, cause)
      : super(
          'Failed to serialize data for cache key: $key',
          'CACHE_WRITE_SERIALIZATION_FAILED',
          cause,
        );

  /// Creates a write exception for disk space issues.
  ///
  /// Used when there is insufficient disk space available to store
  /// new cache data, requiring cache cleanup or storage management.
  const CacheWriteException.diskSpaceFull()
      : super(
          'Insufficient disk space for cache operation',
          'CACHE_WRITE_DISK_SPACE_FULL',
        );

  /// Creates a write exception for disk access failures.
  ///
  /// Used when the cache storage system cannot be accessed for writing
  /// due to file system errors, permission issues, or hardware problems.
  ///
  /// [cause] Optional underlying disk access error.
  const CacheWriteException.diskAccessFailed([cause])
      : super(
          'Failed to access disk cache storage for writing',
          'CACHE_WRITE_DISK_ACCESS_FAILED',
          cause,
        );

  /// Creates a write exception for cache size limit exceeded.
  ///
  /// Used when attempting to store data would exceed the configured
  /// maximum cache size limit, requiring cache eviction or cleanup.
  ///
  /// [currentSize] The current cache size in bytes.
  /// [maxSize] The maximum allowed cache size in bytes.
  CacheWriteException.sizeLimitExceeded(int currentSize, int maxSize)
      : super(
          'Cache size limit exceeded: ${currentSize}B > ${maxSize}B',
          'CACHE_WRITE_SIZE_LIMIT_EXCEEDED',
        );
}

/// Exception thrown when cache management operations fail.
///
/// Handles errors related to cache maintenance including clear operations,
/// initialization failures, cleanup processes, and statistics collection.
/// These errors typically occur during cache administration tasks.
class CacheManagementException extends CacheServiceException {
  /// Creates a new CacheManagementException with the specified message and error code.
  ///
  /// [message] Description of the cache management error.
  /// [errorCode] Machine-readable error code for programmatic handling.
  /// [cause] Optional underlying cause of the cache management error.
  const CacheManagementException(super.message, super.errorCode, [super.cause]);

  /// Creates a management exception for clear operations.
  ///
  /// Used when cache clear operations fail to remove all cached data,
  /// potentially leaving the cache in an inconsistent state.
  ///
  /// [cause] Optional underlying clear operation error.
  const CacheManagementException.clearFailed([cause])
      : super(
          'Failed to clear cache',
          'CACHE_MANAGEMENT_CLEAR_FAILED',
          cause,
        );

  /// Creates a management exception for initialization failures.
  ///
  /// Used when the cache service fails to initialize properly,
  /// preventing any cache operations from functioning correctly.
  ///
  /// [cause] Optional underlying initialization error.
  const CacheManagementException.initializationFailed([cause])
      : super(
          'Failed to initialize cache service',
          'CACHE_MANAGEMENT_INITIALIZATION_FAILED',
          cause,
        );

  /// Creates a management exception for cleanup operations.
  ///
  /// Used when automatic cache cleanup processes fail to remove
  /// expired entries, potentially causing storage or performance issues.
  ///
  /// [cause] Optional underlying cleanup operation error.
  const CacheManagementException.cleanupFailed([cause])
      : super(
          'Failed to cleanup expired cache entries',
          'CACHE_MANAGEMENT_CLEANUP_FAILED',
          cause,
        );

  /// Creates a management exception for statistics collection.
  ///
  /// Used when cache statistics cannot be collected or calculated,
  /// affecting monitoring and performance analysis capabilities.
  ///
  /// [cause] Optional underlying statistics collection error.
  const CacheManagementException.statisticsFailed([cause])
      : super(
          'Failed to collect cache statistics',
          'CACHE_MANAGEMENT_STATISTICS_FAILED',
          cause,
        );

  /// Creates a management exception for cache size calculation.
  ///
  /// Used when the total cache size cannot be determined accurately,
  /// affecting cache management and eviction policies.
  ///
  /// [cause] Optional underlying size calculation error.
  const CacheManagementException.sizeFailed([cause])
      : super(
          'Failed to calculate cache size',
          'CACHE_MANAGEMENT_SIZE_FAILED',
          cause,
        );
}

/// Exception thrown when cache configuration is invalid.
///
/// Handles errors related to invalid cache settings including size limits,
/// expiry durations, key formats, and unsupported data types.
/// These errors typically occur during cache service setup.
class CacheConfigurationException extends CacheServiceException {
  /// Creates a new CacheConfigurationException with the specified message and error code.
  ///
  /// [message] Description of the cache configuration error.
  /// [errorCode] Machine-readable error code for programmatic handling.
  /// [cause] Optional underlying cause of the cache configuration error.
  const CacheConfigurationException(
    super.message,
    super.errorCode, [
    super.cause,
  ]);

  /// Creates a configuration exception for invalid cache size.
  ///
  /// Used when the specified cache size is invalid (negative or zero),
  /// preventing proper cache initialization and operation.
  ///
  /// [size] The invalid cache size that was specified.
  CacheConfigurationException.invalidCacheSize(int size)
      : super(
          'Invalid cache size specified: ${size}B (must be positive)',
          'CACHE_CONFIG_INVALID_SIZE',
        );

  /// Creates a configuration exception for invalid expiry duration.
  ///
  /// Used when the specified cache expiry duration is invalid
  /// (negative or zero), affecting cache eviction policies.
  ///
  /// [expiry] The invalid expiry duration that was specified.
  CacheConfigurationException.invalidExpiry(Duration expiry)
      : super(
          'Invalid cache expiry duration: ${expiry.inSeconds}s (must be positive)',
          'CACHE_CONFIG_INVALID_EXPIRY',
        );

  /// Creates a configuration exception for invalid cache key.
  ///
  /// Used when a cache key contains invalid characters or is empty,
  /// preventing proper cache key generation and lookup.
  ///
  /// [key] The invalid cache key that was provided.
  const CacheConfigurationException.invalidKey(String key)
      : super(
          'Invalid cache key: "$key" (must be non-empty and contain valid characters)',
          'CACHE_CONFIG_INVALID_KEY',
        );

  /// Creates a configuration exception for unsupported data type.
  ///
  /// Used when attempting to cache data of a type that is not
  /// supported by the current cache serialization implementation.
  ///
  /// [type] The unsupported data type that was attempted.
  const CacheConfigurationException.unsupportedType(Type type)
      : super(
          'Unsupported data type for caching: $type',
          'CACHE_CONFIG_UNSUPPORTED_TYPE',
        );
}

/// Exception thrown when cache operations timeout.
///
/// Handles timeout errors for various cache operations including reads,
/// writes, and cleanup processes. These errors typically occur when
/// operations take longer than expected due to system performance issues.
class CacheTimeoutException extends CacheServiceException {
  /// Creates a new CacheTimeoutException with the specified message and error code.
  ///
  /// [message] Description of the cache timeout error.
  /// [errorCode] Machine-readable error code for programmatic handling.
  /// [cause] Optional underlying cause of the cache timeout error.
  const CacheTimeoutException(super.message, super.errorCode, [super.cause]);

  /// Creates a timeout exception for read operations.
  ///
  /// Used when cache read operations take longer than the specified
  /// timeout duration, potentially indicating system performance issues.
  ///
  /// [key] The cache key that timed out during read.
  /// [timeout] The timeout duration that was exceeded.
  CacheTimeoutException.readTimeout(String key, Duration timeout)
      : super(
          'Cache read operation timed out for key: $key (timeout: ${timeout.inSeconds}s)',
          'CACHE_TIMEOUT_READ',
        );

  /// Creates a timeout exception for write operations.
  ///
  /// Used when cache write operations take longer than the specified
  /// timeout duration, potentially indicating disk or serialization issues.
  ///
  /// [key] The cache key that timed out during write.
  /// [timeout] The timeout duration that was exceeded.
  CacheTimeoutException.writeTimeout(String key, Duration timeout)
      : super(
          'Cache write operation timed out for key: $key (timeout: ${timeout.inSeconds}s)',
          'CACHE_TIMEOUT_WRITE',
        );

  /// Creates a timeout exception for cleanup operations.
  ///
  /// Used when cache cleanup operations take longer than expected,
  /// potentially indicating large cache sizes or system performance issues.
  ///
  /// [timeout] The timeout duration that was exceeded during cleanup.
  CacheTimeoutException.cleanupTimeout(Duration timeout)
      : super(
          'Cache cleanup operation timed out (timeout: ${timeout.inSeconds}s)',
          'CACHE_TIMEOUT_CLEANUP',
        );
}
