/// Base exception class for network service errors.
abstract class NetworkServiceException implements Exception {
  const NetworkServiceException(this.message, this.errorCode, [this.cause]);

  /// Human-readable error message
  final String message;

  /// Machine-readable error code for programmatic handling
  final String errorCode;

  /// Optional underlying cause of the exception
  final dynamic cause;

  @override
  String toString() => 'NetworkServiceException: $message (Code: $errorCode)';
}

/// Exception thrown when network connectivity operations fail.
class NetworkConnectivityException extends NetworkServiceException {
  const NetworkConnectivityException(super.message, super.errorCode,
      [super.cause]);

  /// Creates a connectivity exception for no internet connection.
  const NetworkConnectivityException.noConnection()
      : super(
          'No internet connection available. Please check your network settings.',
          'NETWORK_NO_CONNECTION',
        );

  /// Creates a connectivity exception for unstable connection.
  const NetworkConnectivityException.unstableConnection()
      : super(
          'Network connection is unstable. Please check your signal strength.',
          'NETWORK_UNSTABLE_CONNECTION',
        );

  /// Creates a connectivity exception for airplane mode.
  const NetworkConnectivityException.airplaneMode()
      : super(
          'Device is in airplane mode. Please disable airplane mode to connect.',
          'NETWORK_AIRPLANE_MODE',
        );
}

/// Exception thrown when network quality assessment fails.
class NetworkQualityException extends NetworkServiceException {
  const NetworkQualityException(super.message, super.errorCode, [super.cause]);

  /// Creates a quality exception for timeout during assessment.
  NetworkQualityException.assessmentTimeout(Duration timeout)
      : super(
          'Network quality assessment timed out after ${timeout.inSeconds}s',
          'NETWORK_QUALITY_TIMEOUT',
        );

  /// Creates a quality exception for failed speed test.
  const NetworkQualityException.speedTestFailed()
      : super(
          'Unable to determine network speed due to test failure',
          'NETWORK_QUALITY_SPEED_TEST_FAILED',
        );

  /// Creates a quality exception for insufficient data.
  const NetworkQualityException.insufficientData()
      : super(
          'Insufficient data to assess network quality accurately',
          'NETWORK_QUALITY_INSUFFICIENT_DATA',
        );
}

/// Exception thrown when network retry operations fail.
class NetworkRetryException extends NetworkServiceException {
  const NetworkRetryException(super.message, super.errorCode, [super.cause]);

  /// Creates a retry exception for maximum attempts exceeded.
  NetworkRetryException.maxAttemptsExceeded(int attempts)
      : super(
          'Network operation failed after $attempts retry attempts',
          'NETWORK_RETRY_MAX_ATTEMPTS_EXCEEDED',
        );

  /// Creates a retry exception for timeout during retry operation.
  NetworkRetryException.retryTimeout(Duration timeout)
      : super(
          'Retry operation timed out after ${timeout.inSeconds}s',
          'NETWORK_RETRY_TIMEOUT',
        );

  /// Creates a retry exception for invalid retry configuration.
  const NetworkRetryException.invalidConfig()
      : super(
          'Invalid retry configuration provided',
          'NETWORK_RETRY_INVALID_CONFIG',
        );
}

/// Exception thrown when network monitoring operations fail.
class NetworkMonitoringException extends NetworkServiceException {
  const NetworkMonitoringException(super.message, super.errorCode,
      [super.cause]);

  /// Creates a monitoring exception for failed to start monitoring.
  const NetworkMonitoringException.startFailed()
      : super(
          'Failed to start network quality monitoring',
          'NETWORK_MONITORING_START_FAILED',
        );

  /// Creates a monitoring exception for monitoring already active.
  const NetworkMonitoringException.alreadyActive()
      : super(
          'Network quality monitoring is already active',
          'NETWORK_MONITORING_ALREADY_ACTIVE',
        );

  /// Creates a monitoring exception for platform not supported.
  const NetworkMonitoringException.platformNotSupported()
      : super(
          'Network monitoring is not supported on this platform',
          'NETWORK_MONITORING_PLATFORM_NOT_SUPPORTED',
        );
}

/// Exception thrown when host reachability tests fail.
class NetworkReachabilityException extends NetworkServiceException {
  const NetworkReachabilityException(super.message, super.errorCode,
      [super.cause]);

  /// Creates a reachability exception for host unreachable.
  NetworkReachabilityException.hostUnreachable(String host, int port)
      : super(
          'Host $host:$port is not reachable',
          'NETWORK_HOST_UNREACHABLE',
        );

  /// Creates a reachability exception for DNS resolution failure.
  NetworkReachabilityException.dnsResolutionFailed(String host)
      : super(
          'DNS resolution failed for host: $host',
          'NETWORK_DNS_RESOLUTION_FAILED',
        );

  /// Creates a reachability exception for connection timeout.
  NetworkReachabilityException.connectionTimeout(String host, Duration timeout)
      : super(
          'Connection to $host timed out after ${timeout.inSeconds}s',
          'NETWORK_CONNECTION_TIMEOUT',
        );
}

/// Exception thrown when network service initialization fails.
class NetworkServiceInitializationException extends NetworkServiceException {
  const NetworkServiceInitializationException(super.message, super.errorCode,
      [super.cause]);

  /// Creates an initialization exception for platform not supported.
  const NetworkServiceInitializationException.platformNotSupported()
      : super(
          'Network service is not supported on this platform',
          'NETWORK_SERVICE_PLATFORM_NOT_SUPPORTED',
        );

  /// Creates an initialization exception for permissions not granted.
  const NetworkServiceInitializationException.permissionsDenied()
      : super(
          'Network permissions not granted. Please enable network access.',
          'NETWORK_SERVICE_PERMISSIONS_DENIED',
        );

  /// Creates an initialization exception for service already initialized.
  const NetworkServiceInitializationException.alreadyInitialized()
      : super(
          'Network service has already been initialized',
          'NETWORK_SERVICE_ALREADY_INITIALIZED',
        );
}

/// Exception thrown when network usage tracking fails.
class NetworkUsageException extends NetworkServiceException {
  const NetworkUsageException(super.message, super.errorCode, [super.cause]);

  /// Creates a usage exception for tracking not available.
  const NetworkUsageException.trackingNotAvailable()
      : super(
          'Network usage tracking is not available on this platform',
          'NETWORK_USAGE_TRACKING_NOT_AVAILABLE',
        );

  /// Creates a usage exception for insufficient permissions.
  const NetworkUsageException.insufficientPermissions()
      : super(
          'Insufficient permissions to track network usage',
          'NETWORK_USAGE_INSUFFICIENT_PERMISSIONS',
        );

  /// Creates a usage exception for data collection failed.
  const NetworkUsageException.dataCollectionFailed()
      : super(
          'Failed to collect network usage statistics',
          'NETWORK_USAGE_DATA_COLLECTION_FAILED',
        );
}
