import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Network quality assessment levels for connection performance evaluation.
///
/// Provides a standardized way to categorize network connection quality
/// based on factors like latency, bandwidth, and reliability. These ratings
/// help the application adapt its behavior to current network conditions.
enum NetworkQuality {
  /// No network connection available to any interface.
  ///
  /// Device is completely offline with no internet access through WiFi,
  /// cellular, or any other network interface. All network operations
  /// will fail immediately.
  none,

  /// Poor connection with high latency and very low bandwidth.
  ///
  /// Connection exists but is unreliable or very slow (e.g., 2G cellular).
  /// Only essential network operations should be attempted, with aggressive
  /// timeouts and retry policies. Consider offline-first approaches.
  poor,

  /// Fair connection with moderate speed and acceptable latency.
  ///
  /// Usable connection that supports basic operations but may struggle
  /// with large data transfers (e.g., slow 3G or congested WiFi).
  /// Optimize for efficiency and consider progressive loading.
  fair,

  /// Good connection with reliable speed and low latency.
  ///
  /// Solid connection suitable for most application features including
  /// streaming content and real-time updates (e.g., 4G or good WiFi).
  /// Standard operation modes can be used.
  good,

  /// Excellent connection with high speed and minimal latency.
  ///
  /// High-quality connection supporting all features including HD streaming,
  /// real-time collaboration, and large file transfers (e.g., 5G or fiber).
  /// Enable all performance features.
  excellent,

  /// Unknown connection quality due to insufficient data or testing failure.
  ///
  /// Quality assessment couldn't be completed due to errors, timeouts,
  /// or insufficient historical data. Use conservative defaults until
  /// quality can be properly determined.
  unknown,
}

/// Comprehensive network usage statistics for bandwidth monitoring and optimization.
///
/// Tracks network consumption patterns to help optimize data usage, identify
/// performance issues, and provide user feedback about bandwidth consumption.
/// All statistics are cumulative since the last reset or app restart.
class NetworkUsageStats {
  /// Creates network usage statistics with the specified metrics.
  ///
  /// [bytesSent] Total bytes transmitted by the application.
  /// [bytesReceived] Total bytes received by the application.
  /// [lastUpdated] When these statistics were last calculated.
  /// [connectionType] Current network connection type.
  /// [estimatedBandwidth] Optional bandwidth estimation in bytes per second.
  const NetworkUsageStats({
    required this.bytesSent,
    required this.bytesReceived,
    required this.lastUpdated,
    required this.connectionType,
    this.estimatedBandwidth,
  });

  /// Total bytes sent by the application since statistics reset.
  ///
  /// Includes all outbound network traffic including HTTP requests,
  /// WebSocket messages, and any other network protocol usage.
  /// Used for upload bandwidth analysis and data usage monitoring.
  final int bytesSent;

  /// Total bytes received by the application since statistics reset.
  ///
  /// Includes all inbound network traffic including HTTP responses,
  /// streaming media, and background data synchronization.
  /// Primary metric for download bandwidth analysis.
  final int bytesReceived;

  /// Timestamp when these statistics were last updated.
  ///
  /// Indicates the freshness of the data and can be used to calculate
  /// rates and trends in network usage patterns.
  final DateTime lastUpdated;

  /// Current network connection type being monitored.
  ///
  /// Helps correlate usage patterns with connection types for
  /// adaptive behavior and user guidance about data costs.
  final ConnectivityResult connectionType;

  /// Estimated current bandwidth in bytes per second.
  ///
  /// Optional real-time bandwidth estimation based on recent transfers.
  /// May be null if bandwidth testing is disabled or insufficient data
  /// is available for accurate estimation.
  final double? estimatedBandwidth;

  /// Combined total of bytes sent and received.
  ///
  /// Represents total network usage for overall bandwidth consumption
  /// analysis and quota monitoring.
  int get totalBytes => bytesSent + bytesReceived;

  /// Returns a detailed string representation of network usage statistics.
  ///
  /// Includes all key metrics formatted for logging and debugging purposes.
  @override
  String toString() =>
      'NetworkUsageStats(sent: ${bytesSent}B, received: ${bytesReceived}B, '
      'total: ${totalBytes}B, type: $connectionType, bandwidth: ${estimatedBandwidth?.toStringAsFixed(2)}B/s, '
      'updated: $lastUpdated)';
}

/// Comprehensive network state information combining connectivity and performance data.
///
/// Represents the complete network status at a specific point in time, including
/// connection type, quality assessment, and performance metrics. Used throughout
/// the application to make intelligent decisions about network operations.
class NetworkState {
  /// Creates a network state with the specified connectivity and quality information.
  ///
  /// [connectivity] The type of network connection currently active.
  /// [quality] Assessed quality rating for the current connection.
  /// [isConnected] Whether internet connectivity is available.
  /// [timestamp] When this state information was determined.
  /// [latencyMs] Optional round-trip time measurement in milliseconds.
  const NetworkState({
    required this.connectivity,
    required this.quality,
    required this.isConnected,
    required this.timestamp,
    this.latencyMs,
  });

  /// Creates a network state representing complete disconnection.
  ///
  /// Used when no network interfaces are available or when the device
  /// is in airplane mode. All network operations should be deferred.
  factory NetworkState.disconnected() => NetworkState(
        connectivity: ConnectivityResult.none,
        quality: NetworkQuality.none,
        isConnected: false,
        timestamp: DateTime.now(),
      );

  /// Creates a network state for a connected but untested connection.
  ///
  /// Used when connectivity is detected but quality assessment hasn't
  /// been performed yet. Applications should use conservative defaults
  /// until quality is determined.
  ///
  /// [connectivity] The detected connection type (WiFi, mobile, etc.).
  factory NetworkState.connected(ConnectivityResult connectivity) =>
      NetworkState(
        connectivity: connectivity,
        quality: NetworkQuality.unknown,
        isConnected: true,
        timestamp: DateTime.now(),
      );

  /// Current network connectivity type detected by the system.
  ///
  /// Indicates the physical connection method (WiFi, cellular, ethernet)
  /// but doesn't guarantee internet access or connection quality.
  final ConnectivityResult connectivity;

  /// Assessed quality rating for the current network connection.
  ///
  /// Based on performance testing including latency, throughput, and
  /// reliability measurements. Used to adapt application behavior
  /// to current network conditions.
  final NetworkQuality quality;

  /// Whether the device currently has working internet connectivity.
  ///
  /// True indicates that network requests can be attempted, though
  /// success depends on the quality rating and specific endpoints.
  final bool isConnected;

  /// Round-trip time for network requests in milliseconds.
  ///
  /// Optional latency measurement from recent network tests. Null if
  /// latency testing is disabled or no recent measurements are available.
  /// Values under 50ms are excellent, over 200ms may impact user experience.
  final int? latencyMs;

  /// Timestamp when this network state was determined.
  ///
  /// Indicates the freshness of the state information. Network conditions
  /// can change rapidly, so recent timestamps are preferred for decisions.
  final DateTime timestamp;

  /// Returns a detailed string representation of the network state.
  ///
  /// Includes all state information formatted for logging and debugging.
  @override
  String toString() =>
      'NetworkState(connectivity: $connectivity, quality: $quality, '
      'connected: $isConnected, latency: ${latencyMs}ms, at: $timestamp)';
}

/// Configuration parameters for network retry mechanisms and backoff strategies.
///
/// Defines how failed network operations should be retried, including timing,
/// limits, and backoff behavior. Different retry strategies can be applied
/// based on operation criticality and expected failure patterns.
class RetryConfig {
  /// Creates retry configuration with the specified parameters.
  ///
  /// [maxAttempts] Maximum number of retry attempts before giving up.
  /// [initialDelay] Starting delay before the first retry attempt.
  /// [backoffMultiplier] Factor by which delay increases each retry.
  /// [maxDelay] Upper limit for retry delays to prevent excessive waiting.
  /// [useJitter] Whether to randomize delays to prevent thundering herds.
  const RetryConfig({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.backoffMultiplier = 2.0,
    this.maxDelay = const Duration(seconds: 30),
    this.useJitter = true,
  });

  /// Maximum number of retry attempts before giving up.
  ///
  /// Includes the initial attempt, so maxAttempts=3 means 1 initial try
  /// plus 2 retries. Setting to 1 disables retries entirely.
  final int maxAttempts;

  /// Initial delay before the first retry attempt.
  ///
  /// Should be long enough to allow transient issues to resolve but
  /// short enough for responsive user experience. Consider network
  /// quality when setting this value.
  final Duration initialDelay;

  /// Multiplier for exponential backoff between retry attempts.
  ///
  /// Each subsequent retry delay is calculated as:
  /// delay = previous_delay * backoffMultiplier (up to maxDelay).
  /// Values between 1.5 and 2.0 are typical for network operations.
  final double backoffMultiplier;

  /// Maximum delay between retry attempts.
  ///
  /// Prevents exponential backoff from creating excessively long delays.
  /// Should balance user experience with server load considerations.
  final Duration maxDelay;

  /// Whether to add random jitter to retry delays.
  ///
  /// Jitter helps prevent synchronized retries from multiple clients
  /// (thundering herd problem) by adding randomness to delays.
  /// Recommended for production applications.
  final bool useJitter;

  /// Standard retry configuration suitable for most network operations.
  ///
  /// Provides balanced retry behavior with 3 attempts, exponential backoff,
  /// and jitter to handle typical network transient failures.
  static const defaultConfig = RetryConfig();

  /// Aggressive retry configuration for critical operations.
  ///
  /// Uses more retry attempts with shorter initial delays for operations
  /// that must succeed, such as authentication or critical data submission.
  static const aggressive = RetryConfig(
    maxAttempts: 5,
    initialDelay: Duration(milliseconds: 500),
    backoffMultiplier: 1.5,
    maxDelay: Duration(seconds: 15),
  );
}

/// Comprehensive network service interface for connectivity management and monitoring.
///
/// Provides a unified, reactive interface for all network-related operations including
/// connectivity monitoring, quality assessment, usage tracking, and intelligent retry
/// mechanisms. Designed to help applications adapt their behavior to current network
/// conditions and provide optimal user experiences across varying connection quality.
///
/// Key features:
/// - **Real-time connectivity monitoring**: Reactive streams for connection changes
/// - **Quality assessment**: Automatic testing and rating of network performance
/// - **Usage tracking**: Detailed bandwidth consumption monitoring and analytics
/// - **Intelligent retries**: Configurable retry mechanisms with exponential backoff
/// - **Performance optimization**: Bandwidth estimation and adaptive behavior
/// - **Host-specific testing**: Targeted connectivity tests for specific endpoints
///
/// The service automatically handles platform differences and provides consistent
/// behavior across iOS, Android, and other supported platforms. All operations
/// are designed to be lightweight and efficient to minimize impact on device
/// battery and network usage.
///
/// Usage example:
/// ```dart
/// final networkService = GetIt.instance<INetworkService>();
///
/// // Monitor network state changes
/// networkService.networkStateStream.listen((state) {
///   if (state.quality == NetworkQuality.poor) {
///     // Switch to offline mode or reduce data usage
///   }
/// });
///
/// // Execute operation with automatic retries
/// await networkService.executeWithRetry(() => apiCall());
/// ```
abstract class INetworkService {
  /// Stream of network connectivity type changes.
  ///
  /// Emits [ConnectivityResult] values whenever the device's physical
  /// network connectivity changes (WiFi, cellular, ethernet, none).
  /// Subscribe to this stream for immediate notification of connection
  /// type changes, but note that connectivity doesn't guarantee internet access.
  ///
  /// This stream remains active for the lifetime of the service and
  /// should be managed appropriately to prevent memory leaks.
  Stream<ConnectivityResult> get connectivityStream;

  /// Stream of comprehensive network state changes.
  ///
  /// Provides detailed [NetworkState] information including connectivity type,
  /// assessed quality rating, latency measurements, and internet availability.
  /// This is the primary stream for making network-related UI and behavior
  /// decisions throughout the application.
  ///
  /// State updates are emitted when:
  /// - Physical connectivity changes (WiFi ↔ cellular)
  /// - Internet access is gained or lost
  /// - Network quality assessment completes
  /// - Significant latency changes are detected
  ///
  /// Example usage:
  /// ```dart
  /// networkService.networkStateStream.listen((state) {
  ///   switch (state.quality) {
  ///     case NetworkQuality.excellent:
  ///       enableHDStreaming();
  ///       break;
  ///     case NetworkQuality.poor:
  ///       enableOfflineMode();
  ///       break;
  ///   }
  /// });
  /// ```
  Stream<NetworkState> get networkStateStream;

  /// Current internet connection availability status.
  ///
  /// Returns true if the device has working internet connectivity that can
  /// reach external hosts. This is more reliable than checking connectivity
  /// type alone, as it verifies actual internet access rather than just
  /// network interface availability.
  ///
  /// This is an async getter that performs actual connectivity testing,
  /// so results may not be immediate. For reactive updates, use
  /// [networkStateStream] instead.
  Future<bool> get isConnected;

  /// Current network connectivity type detection.
  ///
  /// Checks the device's network connectivity and returns the current
  /// connection type (WiFi, mobile data, ethernet, etc.). This reflects
  /// the physical network interface in use but doesn't guarantee internet
  /// access or connection quality.
  ///
  /// Results are obtained from the platform's connectivity APIs and
  /// represent the immediate state at the time of the call.
  ///
  /// Returns [ConnectivityResult.none] when no network interfaces are
  /// available (airplane mode, no signal, etc.).
  Future<ConnectivityResult> checkConnectivity();

  /// Comprehensive network state assessment with quality rating.
  ///
  /// Provides complete network status information including connectivity type,
  /// internet accessibility, quality assessment, and performance metrics.
  /// This method performs active testing to determine actual network
  /// capabilities beyond basic connectivity detection.
  ///
  /// The returned [NetworkState] includes:
  /// - Physical connectivity type (WiFi, cellular, etc.)
  /// - Internet access verification
  /// - Network quality rating based on performance tests
  /// - Latency measurements (if available)
  /// - Timestamp of assessment
  ///
  /// This operation may take several seconds to complete as it performs
  /// actual network tests. For immediate results, use cached state from
  /// [networkStateStream] when available.
  Future<NetworkState> getNetworkState();

  /// Active network quality assessment and performance testing.
  ///
  /// Performs comprehensive network quality tests including latency measurement,
  /// bandwidth estimation, and reliability testing to determine current
  /// connection performance. Results are used to classify the connection
  /// into quality categories for adaptive application behavior.
  ///
  /// Quality assessment includes:
  /// - Latency testing to measure round-trip times
  /// - Small data transfer tests for responsiveness
  /// - Connection stability verification
  /// - Historical performance analysis
  ///
  /// Returns [NetworkQuality] rating from none to excellent based on
  /// measured performance. May return [NetworkQuality.unknown] if
  /// testing fails or insufficient data is available.
  ///
  /// This operation consumes small amounts of bandwidth and may take
  /// several seconds to complete. Results are cached and used to
  /// update the network state stream.
  Future<NetworkQuality> assessNetworkQuality();

  /// Current network bandwidth usage statistics and monitoring data.
  ///
  /// Returns comprehensive [NetworkUsageStats] including total bytes
  /// transmitted and received, current connection type, bandwidth
  /// estimation, and tracking timestamps. Essential for data usage
  /// monitoring, performance optimization, and user transparency.
  ///
  /// Statistics include:
  /// - Cumulative bytes sent since last reset
  /// - Cumulative bytes received since last reset
  /// - Current connection type correlation
  /// - Real-time bandwidth estimation (if available)
  /// - Last update timestamp for freshness validation
  ///
  /// Data is tracked automatically for all network operations performed
  /// through the service and participating components.
  Future<NetworkUsageStats> getUsageStats();

  /// Reset network usage statistics to zero.
  ///
  /// Clears all accumulated bandwidth usage data and restarts tracking
  /// from zero. Useful for periodic reporting, user-initiated resets,
  /// or billing cycle boundaries.
  ///
  /// After reset, [getUsageStats] will return zero values for sent/received
  /// bytes with a new tracking start timestamp. This operation doesn't
  /// affect ongoing network monitoring or quality assessment.
  Future<void> resetUsageStats();

  /// Execute an operation with intelligent retry logic and exponential backoff.
  ///
  /// Automatically retries the provided [operation] if it fails due to
  /// network-related issues, using configurable retry strategies with
  /// exponential backoff and jitter to handle transient failures gracefully.
  ///
  /// Retry behavior includes:
  /// - Exponential backoff with configurable multipliers
  /// - Jitter to prevent thundering herd problems
  /// - Maximum attempt limits to prevent infinite retries
  /// - Custom retry predicate for operation-specific logic
  ///
  /// [operation] The async function to execute with retry protection.
  ///            Should be idempotent as it may be called multiple times.
  /// [config] Optional retry configuration. Uses [RetryConfig.defaultConfig]
  ///         if not specified. Different configs can be used for different
  ///         operation criticality levels.
  /// [shouldRetry] Optional predicate to determine if a specific exception
  ///              should trigger a retry. By default, retries network-related
  ///              exceptions and timeouts.
  ///
  /// Returns the successful result of [operation] or throws the final
  /// exception if all retry attempts are exhausted.
  ///
  /// Example usage:
  /// ```dart
  /// final result = await networkService.executeWithRetry(
  ///   () => httpClient.get(url),
  ///   config: RetryConfig.aggressive,
  ///   shouldRetry: (e) => e is SocketException || e is TimeoutException,
  /// );
  /// ```
  Future<T> executeWithRetry<T>(
    Future<T> Function() operation, {
    RetryConfig? config,
    bool Function(Object)? shouldRetry,
  });

  /// Start continuous network quality monitoring with configurable intervals.
  ///
  /// Begins periodic network quality assessment that automatically updates
  /// the [networkStateStream] with current performance measurements.
  /// Essential for applications that need to adapt behavior based on
  /// changing network conditions.
  ///
  /// Monitoring includes:
  /// - Periodic quality assessment tests
  /// - Automatic state stream updates
  /// - Performance trend analysis
  /// - Adaptive testing frequency based on detected changes
  ///
  /// [interval] How frequently to perform quality assessments. Shorter
  ///           intervals provide more responsive updates but consume more
  ///           battery and bandwidth. Default is 1 minute for balanced
  ///           monitoring.
  ///
  /// Quality monitoring continues until explicitly stopped with
  /// [stopQualityMonitoring] or the service is disposed. Consider
  /// battery and bandwidth implications for mobile applications.
  Future<void> startQualityMonitoring({
    Duration interval = const Duration(minutes: 1),
  });

  /// Stop continuous network quality monitoring to conserve resources.
  ///
  /// Stops periodic quality assessments initiated by [startQualityMonitoring].
  /// The [networkStateStream] will continue to emit connectivity changes
  /// but won't include updated quality ratings until monitoring is restarted.
  ///
  /// Recommended when the application is backgrounded or when detailed
  /// quality information isn't needed to conserve battery and bandwidth.
  Future<void> stopQualityMonitoring();

  /// Test connectivity to a specific host and port combination.
  ///
  /// Performs targeted connectivity testing to determine if a specific
  /// [host] and [port] combination is reachable from the current network.
  /// More specific than general internet connectivity testing and useful
  /// for validating access to particular services or APIs.
  ///
  /// [host] The hostname or IP address to test connectivity to.
  /// [port] The port number to test. Defaults to 80 (HTTP) if not specified.
  /// [timeout] Maximum time to wait for connection. Uses system defaults
  ///          if not specified.
  ///
  /// Returns true if the host is reachable within the timeout period,
  /// false if connection fails or times out. Note that some hosts may
  /// block connectivity tests while still being accessible for normal
  /// application traffic.
  ///
  /// Example usage:
  /// ```dart
  /// final canReachAPI = await networkService.isHostReachable(
  ///   'api.example.com',
  ///   port: 443,
  ///   timeout: Duration(seconds: 5),
  /// );
  /// ```
  Future<bool> isHostReachable(String host, {int port = 80, Duration? timeout});

  /// Estimate current download bandwidth through active testing.
  ///
  /// Performs a download speed test to estimate the current connection's
  /// bandwidth capabilities. Results can be used for adaptive streaming,
  /// progressive loading, and user feedback about connection quality.
  ///
  /// The test downloads a small amount of data and measures transfer
  /// rates to estimate bandwidth. Results may vary based on server
  /// performance, network congestion, and other factors.
  ///
  /// [timeout] Maximum time to spend on bandwidth testing. Longer timeouts
  ///          may provide more accurate results but delay other operations.
  ///
  /// Returns estimated download speed in bytes per second, or null if
  /// the test fails or times out. Results should be considered approximate
  /// and may not reflect performance for all types of network operations.
  ///
  /// Note: This operation consumes bandwidth and may incur data charges
  /// on metered connections. Use judiciously and consider user preferences.
  Future<double?> estimateDownloadSpeed({Duration? timeout});

  /// Register a callback for network state change notifications.
  ///
  /// Allows components to register custom [listener] functions that are
  /// triggered whenever network state changes occur. Provides an alternative
  /// to stream subscriptions for components that prefer callback-based
  /// notification patterns.
  ///
  /// [listener] Function that receives [NetworkState] updates when network
  ///           conditions change. Should be lightweight to avoid blocking
  ///           other listeners.
  ///
  /// Registered listeners are called in addition to stream emissions,
  /// so components can choose the notification mechanism that best fits
  /// their architecture. Remember to remove listeners when components
  /// are disposed to prevent memory leaks.
  void addNetworkStateListener(void Function(NetworkState state) listener);

  /// Remove a previously registered network state change listener.
  ///
  /// Removes the specified [listener] function from network state change
  /// notifications. Essential for preventing memory leaks when components
  /// that registered listeners are disposed or no longer need updates.
  ///
  /// [listener] The exact function reference that was previously registered
  ///           with [addNetworkStateListener]. Must be the same function
  ///           instance for successful removal.
  ///
  /// If the listener wasn't previously registered, this operation completes
  /// successfully without error. It's safe to call multiple times with
  /// the same listener reference.
  void removeNetworkStateListener(void Function(NetworkState state) listener);

  /// Clean up network service resources and stop all monitoring.
  ///
  /// Releases all network monitoring resources, cancels active streams,
  /// stops quality monitoring, clears listeners, and performs platform-specific
  /// cleanup. Should be called when the service is no longer needed to
  /// prevent memory leaks and unnecessary background activity.
  ///
  /// After disposal:
  /// - All streams will be closed and stop emitting events
  /// - Quality monitoring will be stopped
  /// - All registered listeners will be cleared
  /// - Future method calls may throw exceptions
  ///
  /// This is typically called during application shutdown or when
  /// transitioning to a different network service implementation.
  Future<void> dispose();
}
