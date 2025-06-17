import 'app_exception.dart';

/// Base exception class for network service errors and connectivity issues.
///
/// Serves as the parent class for all network-related exceptions in the app.
/// Provides common behavior for network errors including recovery capabilities
/// and categorization for proper error handling and diagnostics.
abstract class NetworkServiceException extends AppException {
  /// Creates a new NetworkServiceException with the specified message and error code.
  ///
  /// [message] Description of the network service error.
  /// [errorCode] Machine-readable error code for programmatic handling.
  /// [cause] Optional underlying cause of the network service error.
  const NetworkServiceException(super.message, super.errorCode, [super.cause]);

  @override
  String get category => 'network';

  @override
  bool get isRecoverable => true; // Most network errors can be retried
}

/// Exception thrown when network connectivity operations fail.
///
/// Handles various connectivity-related errors including no internet connection,
/// unstable connections, and airplane mode detection. These errors typically
/// occur when the device cannot establish or maintain network connections.
class NetworkConnectivityException extends NetworkServiceException {
  /// Creates a new NetworkConnectivityException with the specified message and error code.
  ///
  /// [message] Description of the connectivity error.
  /// [errorCode] Machine-readable error code for programmatic handling.
  /// [cause] Optional underlying cause of the connectivity error.
  const NetworkConnectivityException(
    super.message,
    super.errorCode, [
    super.cause,
  ]);

  /// Creates a connectivity exception for no internet connection.
  ///
  /// Used when the device has no active internet connection available,
  /// requiring user intervention to enable network connectivity.
  const NetworkConnectivityException.noConnection()
      : super(
          'No internet connection available. Please check your network settings.',
          'NETWORK_NO_CONNECTION',
        );

  /// Creates a connectivity exception for unstable connection.
  ///
  /// Used when the network connection is intermittent or weak,
  /// causing frequent disconnections or slow data transfer.
  const NetworkConnectivityException.unstableConnection()
      : super(
          'Network connection is unstable. Please check your signal strength.',
          'NETWORK_UNSTABLE_CONNECTION',
        );

  /// Creates a connectivity exception for airplane mode.
  ///
  /// Used when the device is in airplane mode, preventing all
  /// network connectivity until airplane mode is disabled.
  const NetworkConnectivityException.airplaneMode()
      : super(
          'Device is in airplane mode. Please disable airplane mode to connect.',
          'NETWORK_AIRPLANE_MODE',
        );
}

/// Exception thrown when network quality assessment fails.
///
/// Handles errors related to measuring and evaluating network performance
/// including speed tests, latency measurements, and quality analysis.
/// These errors typically occur during network diagnostics.
class NetworkQualityException extends NetworkServiceException {
  /// Creates a new NetworkQualityException with the specified message and error code.
  ///
  /// [message] Description of the network quality error.
  /// [errorCode] Machine-readable error code for programmatic handling.
  /// [cause] Optional underlying cause of the network quality error.
  const NetworkQualityException(super.message, super.errorCode, [super.cause]);

  /// Creates a quality exception for timeout during assessment.
  ///
  /// Used when network quality assessment takes longer than expected,
  /// potentially indicating poor network conditions or system issues.
  ///
  /// [timeout] The timeout duration that was exceeded during assessment.
  NetworkQualityException.assessmentTimeout(Duration timeout)
      : super(
          'Network quality assessment timed out after ${timeout.inSeconds}s',
          'NETWORK_QUALITY_TIMEOUT',
        );

  /// Creates a quality exception for failed speed test.
  ///
  /// Used when network speed tests fail to complete properly,
  /// preventing accurate bandwidth measurement and quality assessment.
  const NetworkQualityException.speedTestFailed()
      : super(
          'Unable to determine network speed due to test failure',
          'NETWORK_QUALITY_SPEED_TEST_FAILED',
        );

  /// Creates a quality exception for insufficient data.
  ///
  /// Used when there is not enough data collected to make an
  /// accurate assessment of network quality and performance.
  const NetworkQualityException.insufficientData()
      : super(
          'Insufficient data to assess network quality accurately',
          'NETWORK_QUALITY_INSUFFICIENT_DATA',
        );
}

/// Exception thrown when network retry operations fail.
///
/// Handles errors related to automatic retry mechanisms including
/// maximum attempts exceeded, retry timeouts, and configuration issues.
/// These errors typically occur during network operation recovery.
class NetworkRetryException extends NetworkServiceException {
  /// Creates a new NetworkRetryException with the specified message and error code.
  ///
  /// [message] Description of the network retry error.
  /// [errorCode] Machine-readable error code for programmatic handling.
  /// [cause] Optional underlying cause of the network retry error.
  const NetworkRetryException(super.message, super.errorCode, [super.cause]);

  /// Creates a retry exception for maximum attempts exceeded.
  ///
  /// Used when network operations have failed repeatedly and the
  /// maximum number of retry attempts has been reached.
  ///
  /// [attempts] The number of retry attempts that were made.
  NetworkRetryException.maxAttemptsExceeded(int attempts)
      : super(
          'Network operation failed after $attempts retry attempts',
          'NETWORK_RETRY_MAX_ATTEMPTS_EXCEEDED',
        );

  /// Creates a retry exception for timeout during retry operation.
  ///
  /// Used when retry operations take longer than the configured
  /// timeout duration, indicating persistent network issues.
  ///
  /// [timeout] The timeout duration that was exceeded during retry.
  NetworkRetryException.retryTimeout(Duration timeout)
      : super(
          'Retry operation timed out after ${timeout.inSeconds}s',
          'NETWORK_RETRY_TIMEOUT',
        );

  /// Creates a retry exception for invalid retry configuration.
  ///
  /// Used when retry configuration parameters are invalid or
  /// incompatible, preventing proper retry mechanism operation.
  const NetworkRetryException.invalidConfig()
      : super(
          'Invalid retry configuration provided',
          'NETWORK_RETRY_INVALID_CONFIG',
        );
}

/// Exception thrown when network monitoring operations fail.
///
/// Handles errors related to network quality monitoring including
/// startup failures, duplicate monitoring instances, and platform
/// compatibility issues. These errors typically occur during monitoring setup.
class NetworkMonitoringException extends NetworkServiceException {
  /// Creates a new NetworkMonitoringException with the specified message and error code.
  ///
  /// [message] Description of the network monitoring error.
  /// [errorCode] Machine-readable error code for programmatic handling.
  /// [cause] Optional underlying cause of the network monitoring error.
  const NetworkMonitoringException(
    super.message,
    super.errorCode, [
    super.cause,
  ]);

  /// Creates a monitoring exception for failed to start monitoring.
  ///
  /// Used when network quality monitoring cannot be started due to
  /// system limitations, permission issues, or resource constraints.
  const NetworkMonitoringException.startFailed()
      : super(
          'Failed to start network quality monitoring',
          'NETWORK_MONITORING_START_FAILED',
        );

  /// Creates a monitoring exception for monitoring already active.
  ///
  /// Used when attempting to start network monitoring while a
  /// monitoring session is already running and active.
  const NetworkMonitoringException.alreadyActive()
      : super(
          'Network quality monitoring is already active',
          'NETWORK_MONITORING_ALREADY_ACTIVE',
        );

  /// Creates a monitoring exception for platform not supported.
  ///
  /// Used when network monitoring features are not available or
  /// supported on the current platform or device.
  const NetworkMonitoringException.platformNotSupported()
      : super(
          'Network monitoring is not supported on this platform',
          'NETWORK_MONITORING_PLATFORM_NOT_SUPPORTED',
        );
}

/// Exception thrown when host reachability tests fail.
///
/// Handles errors related to testing connectivity to specific hosts
/// including unreachable hosts, DNS resolution failures, and connection
/// timeouts. These errors typically occur during connectivity diagnostics.
class NetworkReachabilityException extends NetworkServiceException {
  /// Creates a new NetworkReachabilityException with the specified message and error code.
  ///
  /// [message] Description of the network reachability error.
  /// [errorCode] Machine-readable error code for programmatic handling.
  /// [cause] Optional underlying cause of the network reachability error.
  const NetworkReachabilityException(
    super.message,
    super.errorCode, [
    super.cause,
  ]);

  /// Creates a reachability exception for host unreachable.
  ///
  /// Used when a specific host and port combination cannot be reached,
  /// indicating network routing issues or service unavailability.
  ///
  /// [host] The hostname or IP address that is unreachable.
  /// [port] The port number that could not be connected to.
  NetworkReachabilityException.hostUnreachable(String host, int port)
      : super(
          'Host $host:$port is not reachable',
          'NETWORK_HOST_UNREACHABLE',
        );

  /// Creates a reachability exception for DNS resolution failure.
  ///
  /// Used when domain name resolution fails, preventing the conversion
  /// of hostnames to IP addresses for network connections.
  ///
  /// [host] The hostname that failed DNS resolution.
  NetworkReachabilityException.dnsResolutionFailed(String host)
      : super(
          'DNS resolution failed for host: $host',
          'NETWORK_DNS_RESOLUTION_FAILED',
        );

  /// Creates a reachability exception for connection timeout.
  ///
  /// Used when connection attempts to a host take longer than the
  /// specified timeout duration, indicating network or server issues.
  ///
  /// [host] The hostname that timed out during connection.
  /// [timeout] The timeout duration that was exceeded.
  NetworkReachabilityException.connectionTimeout(String host, Duration timeout)
      : super(
          'Connection to $host timed out after ${timeout.inSeconds}s',
          'NETWORK_CONNECTION_TIMEOUT',
        );
}

/// Exception thrown when network service initialization fails.
///
/// Handles errors that occur during network service startup including
/// platform compatibility issues, permission problems, and duplicate
/// initialization attempts. These are typically critical system errors.
class NetworkServiceInitializationException extends NetworkServiceException {
  /// Creates a new NetworkServiceInitializationException with the specified message and error code.
  ///
  /// [message] Description of the network service initialization error.
  /// [errorCode] Machine-readable error code for programmatic handling.
  /// [cause] Optional underlying cause of the network service initialization error.
  const NetworkServiceInitializationException(
    super.message,
    super.errorCode, [
    super.cause,
  ]);

  /// Creates an initialization exception for platform not supported.
  ///
  /// Used when network service features are not available or compatible
  /// with the current platform, preventing service initialization.
  const NetworkServiceInitializationException.platformNotSupported()
      : super(
          'Network service is not supported on this platform',
          'NETWORK_SERVICE_PLATFORM_NOT_SUPPORTED',
        );

  /// Creates an initialization exception for permissions not granted.
  ///
  /// Used when the application lacks necessary network permissions,
  /// preventing network service initialization and operation.
  const NetworkServiceInitializationException.permissionsDenied()
      : super(
          'Network permissions not granted. Please enable network access.',
          'NETWORK_SERVICE_PERMISSIONS_DENIED',
        );

  /// Creates an initialization exception for service already initialized.
  ///
  /// Used when attempting to initialize the network service multiple times,
  /// indicating incorrect service lifecycle management.
  const NetworkServiceInitializationException.alreadyInitialized()
      : super(
          'Network service has already been initialized',
          'NETWORK_SERVICE_ALREADY_INITIALIZED',
        );
}

/// Exception thrown when network usage tracking fails.
///
/// Handles errors related to monitoring and measuring network data usage
/// including platform limitations, permission issues, and data collection
/// failures. These errors typically occur during usage analytics.
class NetworkUsageException extends NetworkServiceException {
  /// Creates a new NetworkUsageException with the specified message and error code.
  ///
  /// [message] Description of the network usage error.
  /// [errorCode] Machine-readable error code for programmatic handling.
  /// [cause] Optional underlying cause of the network usage error.
  const NetworkUsageException(super.message, super.errorCode, [super.cause]);

  /// Creates a usage exception for tracking not available.
  ///
  /// Used when network usage tracking features are not supported
  /// or available on the current platform or device.
  const NetworkUsageException.trackingNotAvailable()
      : super(
          'Network usage tracking is not available on this platform',
          'NETWORK_USAGE_TRACKING_NOT_AVAILABLE',
        );

  /// Creates a usage exception for insufficient permissions.
  ///
  /// Used when the application lacks necessary permissions to
  /// monitor and track network data usage statistics.
  const NetworkUsageException.insufficientPermissions()
      : super(
          'Insufficient permissions to track network usage',
          'NETWORK_USAGE_INSUFFICIENT_PERMISSIONS',
        );

  /// Creates a usage exception for data collection failed.
  ///
  /// Used when network usage statistics cannot be collected or
  /// calculated due to system errors or data access issues.
  const NetworkUsageException.dataCollectionFailed()
      : super(
          'Failed to collect network usage statistics',
          'NETWORK_USAGE_DATA_COLLECTION_FAILED',
        );
}
