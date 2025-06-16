import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Network quality levels for connection assessment.
enum NetworkQuality {
  /// No network connection available
  none,

  /// Poor connection with high latency and low bandwidth
  poor,

  /// Fair connection with moderate speed
  fair,

  /// Good connection with reliable speed
  good,

  /// Excellent connection with high speed and low latency
  excellent,

  /// Unknown connection quality (unable to determine)
  unknown,
}

/// Network usage statistics for monitoring bandwidth consumption.
class NetworkUsageStats {
  const NetworkUsageStats({
    required this.bytesSent,
    required this.bytesReceived,
    required this.lastUpdated,
    required this.connectionType,
    this.estimatedBandwidth,
  });

  /// Total bytes sent since app start
  final int bytesSent;

  /// Total bytes received since app start
  final int bytesReceived;

  /// Timestamp when stats were last updated
  final DateTime lastUpdated;

  /// Current connection type
  final ConnectivityResult connectionType;

  /// Estimated bandwidth in bytes per second
  final double? estimatedBandwidth;

  /// Total bytes transferred (sent + received)
  int get totalBytes => bytesSent + bytesReceived;

  @override
  String toString() =>
      'NetworkUsageStats(sent: ${bytesSent}B, received: ${bytesReceived}B, '
      'total: ${totalBytes}B, type: $connectionType, bandwidth: ${estimatedBandwidth?.toStringAsFixed(2)}B/s, '
      'updated: $lastUpdated)';
}

/// Network state information combining connectivity and quality data.
class NetworkState {
  const NetworkState({
    required this.connectivity,
    required this.quality,
    required this.isConnected,
    required this.timestamp,
    this.latencyMs,
  });

  /// Creates a disconnected network state
  factory NetworkState.disconnected() => NetworkState(
        connectivity: ConnectivityResult.none,
        quality: NetworkQuality.none,
        isConnected: false,
        timestamp: DateTime.now(),
      );

  /// Creates a connected network state with unknown quality
  factory NetworkState.connected(ConnectivityResult connectivity) =>
      NetworkState(
        connectivity: connectivity,
        quality: NetworkQuality.unknown,
        isConnected: true,
        timestamp: DateTime.now(),
      );

  /// Current connectivity result
  final ConnectivityResult connectivity;

  /// Assessed network quality
  final NetworkQuality quality;

  /// Whether the device is connected to the internet
  final bool isConnected;

  /// Round-trip time for network requests in milliseconds
  final int? latencyMs;

  /// Timestamp when the state was determined
  final DateTime timestamp;

  @override
  String toString() =>
      'NetworkState(connectivity: $connectivity, quality: $quality, '
      'connected: $isConnected, latency: ${latencyMs}ms, at: $timestamp)';
}

/// Configuration for network retry mechanisms.
class RetryConfig {
  const RetryConfig({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.backoffMultiplier = 2.0,
    this.maxDelay = const Duration(seconds: 30),
    this.useJitter = true,
  });

  /// Maximum number of retry attempts
  final int maxAttempts;

  /// Initial delay before first retry
  final Duration initialDelay;

  /// Multiplier for exponential backoff
  final double backoffMultiplier;

  /// Maximum delay between retries
  final Duration maxDelay;

  /// Whether to use jitter to randomize delays
  final bool useJitter;

  /// Default retry configuration for network operations
  static const defaultConfig = RetryConfig();

  /// More aggressive retry configuration for critical operations
  static const aggressive = RetryConfig(
    maxAttempts: 5,
    initialDelay: Duration(milliseconds: 500),
    backoffMultiplier: 1.5,
    maxDelay: Duration(seconds: 15),
  );
}

/// Abstract interface for network service operations.
///
/// This service provides a unified interface for:
/// - Network connectivity monitoring
/// - Connection quality assessment
/// - Bandwidth usage tracking
/// - Retry mechanisms for failed requests
/// - Network state change notifications
abstract class INetworkService {
  /// Stream of connectivity changes.
  ///
  /// Emits [ConnectivityResult] values whenever the device's
  /// network connectivity changes.
  Stream<ConnectivityResult> get connectivityStream;

  /// Stream of detailed network state changes.
  ///
  /// Provides comprehensive information including connectivity type,
  /// quality assessment, and performance metrics.
  Stream<NetworkState> get networkStateStream;

  /// Current connection status.
  ///
  /// Returns `true` if the device has internet connectivity,
  /// `false` otherwise.
  Future<bool> get isConnected;

  /// Current connectivity type.
  ///
  /// Checks the device's network connectivity and returns the
  /// current connection type (WiFi, mobile, none, etc.).
  Future<ConnectivityResult> checkConnectivity();

  /// Detailed network state information.
  ///
  /// Provides comprehensive network state including connectivity type,
  /// quality assessment, latency measurements, and connection status.
  Future<NetworkState> getNetworkState();

  /// Assess current network quality.
  ///
  /// Performs network quality tests to determine connection speed
  /// and reliability. Returns [NetworkQuality] rating.
  Future<NetworkQuality> assessNetworkQuality();

  /// Get current network usage statistics.
  ///
  /// Returns bandwidth consumption data including bytes sent/received
  /// and estimated connection speed.
  Future<NetworkUsageStats> getUsageStats();

  /// Reset network usage statistics.
  ///
  /// Clears accumulated bandwidth usage data and starts fresh tracking.
  Future<void> resetUsageStats();

  /// Execute a function with retry logic.
  ///
  /// Automatically retries the provided [operation] if it fails due to
  /// network issues. Uses exponential backoff with jitter.
  ///
  /// [operation] - The async function to execute
  /// [config] - Retry configuration (optional, uses default if not provided)
  /// [shouldRetry] - Custom predicate to determine if an exception should trigger a retry
  Future<T> executeWithRetry<T>(
    Future<T> Function() operation, {
    RetryConfig? config,
    bool Function(dynamic exception)? shouldRetry,
  });

  /// Start network quality monitoring.
  ///
  /// Begins periodic assessment of network quality and updates
  /// the network state stream with current measurements.
  Future<void> startQualityMonitoring({
    Duration interval = const Duration(minutes: 1),
  });

  /// Stop network quality monitoring.
  ///
  /// Stops periodic quality assessments to conserve battery and bandwidth.
  Future<void> stopQualityMonitoring();

  /// Check if specific host is reachable.
  ///
  /// Tests connectivity to a specific [host] and [port].
  /// Useful for testing server-specific connectivity.
  Future<bool> isHostReachable(String host, {int port = 80, Duration? timeout});

  /// Estimate download speed.
  ///
  /// Performs a download test to estimate current connection speed.
  /// Returns speed in bytes per second.
  Future<double?> estimateDownloadSpeed({Duration? timeout});

  /// Register a listener for network state changes.
  ///
  /// Allows components to register callbacks that are triggered
  /// when network state changes occur.
  void addNetworkStateListener(void Function(NetworkState state) listener);

  /// Remove a network state change listener.
  ///
  /// Removes a previously registered listener to prevent memory leaks.
  void removeNetworkStateListener(void Function(NetworkState state) listener);

  /// Dispose of network service resources.
  ///
  /// Cleans up streams, listeners, and other resources.
  /// Should be called when the service is no longer needed.
  Future<void> dispose();
}
