import 'app_exception.dart';

/// Base exception class for cache service errors.
abstract class CacheServiceException extends AppException {
  const CacheServiceException(super.message, super.errorCode, [super.cause]);

  @override
  String get category => 'cache';

  @override
  bool get isRecoverable => true; // Most cache errors can be retried
}

/// Exception thrown when cache read operations fail.
class CacheReadException extends CacheServiceException {
  const CacheReadException(super.message, super.errorCode, [super.cause]);

  /// Creates a read exception for when a cache key cannot be accessed.
  const CacheReadException.keyAccessFailed(String key)
      : super(
          'Failed to read cache data for key: $key',
          'CACHE_READ_KEY_ACCESS_FAILED',
        );

  /// Creates a read exception for serialization failures.
  const CacheReadException.deserializationFailed(String key, cause)
      : super(
          'Failed to deserialize cached data for key: $key',
          'CACHE_READ_DESERIALIZATION_FAILED',
          cause,
        );

  /// Creates a read exception for corrupted cache data.
  const CacheReadException.corruptedData(String key)
      : super(
          'Cache data is corrupted for key: $key',
          'CACHE_READ_CORRUPTED_DATA',
        );

  /// Creates a read exception for disk access failures.
  const CacheReadException.diskAccessFailed([cause])
      : super(
          'Failed to access disk cache storage',
          'CACHE_READ_DISK_ACCESS_FAILED',
          cause,
        );
}

/// Exception thrown when cache write operations fail.
class CacheWriteException extends CacheServiceException {
  const CacheWriteException(super.message, super.errorCode, [super.cause]);

  /// Creates a write exception for when a cache key cannot be written.
  const CacheWriteException.keyWriteFailed(String key, [cause])
      : super(
          'Failed to write cache data for key: $key',
          'CACHE_WRITE_KEY_FAILED',
          cause,
        );

  /// Creates a write exception for serialization failures.
  const CacheWriteException.serializationFailed(String key, cause)
      : super(
          'Failed to serialize data for cache key: $key',
          'CACHE_WRITE_SERIALIZATION_FAILED',
          cause,
        );

  /// Creates a write exception for disk space issues.
  const CacheWriteException.diskSpaceFull()
      : super(
          'Insufficient disk space for cache operation',
          'CACHE_WRITE_DISK_SPACE_FULL',
        );

  /// Creates a write exception for disk access failures.
  const CacheWriteException.diskAccessFailed([cause])
      : super(
          'Failed to access disk cache storage for writing',
          'CACHE_WRITE_DISK_ACCESS_FAILED',
          cause,
        );

  /// Creates a write exception for cache size limit exceeded.
  CacheWriteException.sizeLimitExceeded(int currentSize, int maxSize)
      : super(
          'Cache size limit exceeded: ${currentSize}B > ${maxSize}B',
          'CACHE_WRITE_SIZE_LIMIT_EXCEEDED',
        );
}

/// Exception thrown when cache management operations fail.
class CacheManagementException extends CacheServiceException {
  const CacheManagementException(super.message, super.errorCode, [super.cause]);

  /// Creates a management exception for clear operations.
  const CacheManagementException.clearFailed([cause])
      : super(
          'Failed to clear cache',
          'CACHE_MANAGEMENT_CLEAR_FAILED',
          cause,
        );

  /// Creates a management exception for initialization failures.
  const CacheManagementException.initializationFailed([cause])
      : super(
          'Failed to initialize cache service',
          'CACHE_MANAGEMENT_INITIALIZATION_FAILED',
          cause,
        );

  /// Creates a management exception for cleanup operations.
  const CacheManagementException.cleanupFailed([cause])
      : super(
          'Failed to cleanup expired cache entries',
          'CACHE_MANAGEMENT_CLEANUP_FAILED',
          cause,
        );

  /// Creates a management exception for statistics collection.
  const CacheManagementException.statisticsFailed([cause])
      : super(
          'Failed to collect cache statistics',
          'CACHE_MANAGEMENT_STATISTICS_FAILED',
          cause,
        );

  /// Creates a management exception for cache size calculation.
  const CacheManagementException.sizeFailed([cause])
      : super(
          'Failed to calculate cache size',
          'CACHE_MANAGEMENT_SIZE_FAILED',
          cause,
        );
}

/// Exception thrown when cache configuration is invalid.
class CacheConfigurationException extends CacheServiceException {
  const CacheConfigurationException(
    super.message,
    super.errorCode, [
    super.cause,
  ]);

  /// Creates a configuration exception for invalid cache size.
  CacheConfigurationException.invalidCacheSize(int size)
      : super(
          'Invalid cache size specified: ${size}B (must be positive)',
          'CACHE_CONFIG_INVALID_SIZE',
        );

  /// Creates a configuration exception for invalid expiry duration.
  CacheConfigurationException.invalidExpiry(Duration expiry)
      : super(
          'Invalid cache expiry duration: ${expiry.inSeconds}s (must be positive)',
          'CACHE_CONFIG_INVALID_EXPIRY',
        );

  /// Creates a configuration exception for invalid cache key.
  const CacheConfigurationException.invalidKey(String key)
      : super(
          'Invalid cache key: "$key" (must be non-empty and contain valid characters)',
          'CACHE_CONFIG_INVALID_KEY',
        );

  /// Creates a configuration exception for unsupported data type.
  const CacheConfigurationException.unsupportedType(Type type)
      : super(
          'Unsupported data type for caching: $type',
          'CACHE_CONFIG_UNSUPPORTED_TYPE',
        );
}

/// Exception thrown when cache operations timeout.
class CacheTimeoutException extends CacheServiceException {
  const CacheTimeoutException(super.message, super.errorCode, [super.cause]);

  /// Creates a timeout exception for read operations.
  CacheTimeoutException.readTimeout(String key, Duration timeout)
      : super(
          'Cache read operation timed out for key: $key (timeout: ${timeout.inSeconds}s)',
          'CACHE_TIMEOUT_READ',
        );

  /// Creates a timeout exception for write operations.
  CacheTimeoutException.writeTimeout(String key, Duration timeout)
      : super(
          'Cache write operation timed out for key: $key (timeout: ${timeout.inSeconds}s)',
          'CACHE_TIMEOUT_WRITE',
        );

  /// Creates a timeout exception for cleanup operations.
  CacheTimeoutException.cleanupTimeout(Duration timeout)
      : super(
          'Cache cleanup operation timed out (timeout: ${timeout.inSeconds}s)',
          'CACHE_TIMEOUT_CLEANUP',
        );
}
