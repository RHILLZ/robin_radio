import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../../exceptions/network_service_exception.dart';
import 'network_service_interface.dart';

/// Enhanced network service implementation with comprehensive connectivity management.
///
/// Features:
/// - Real-time connectivity monitoring using connectivity_plus
/// - Network quality assessment with latency and speed testing
/// - Bandwidth usage tracking and statistics
/// - Retry mechanisms with exponential backoff and jitter
/// - Host reachability testing
/// - Performance monitoring and event streaming
/// - Cross-platform support (iOS, Android, Web, Desktop)
class EnhancedNetworkService implements INetworkService {
  // Private constructor for singleton
  EnhancedNetworkService._();
  static EnhancedNetworkService? _instance;

  /// Singleton instance of the network service
  static EnhancedNetworkService get instance =>
      _instance ??= EnhancedNetworkService._();

  // Core dependencies
  final Connectivity _connectivity = Connectivity();

  // Stream controllers for reactive updates
  final StreamController<ConnectivityResult> _connectivityController =
      StreamController<ConnectivityResult>.broadcast();
  final StreamController<NetworkState> _networkStateController =
      StreamController<NetworkState>.broadcast();

  // Internal state management
  ConnectivityResult? _lastConnectivity;
  NetworkState? _lastNetworkState;
  Timer? _qualityMonitoringTimer;
  bool _isMonitoringQuality = false;
  bool _isDisposed = false;

  // Network usage tracking
  int _bytesSent = 0;
  int _bytesReceived = 0;
  DateTime _usageStatsStartTime = DateTime.now();
  double? _lastEstimatedBandwidth;

  // State change listeners
  final List<void Function(NetworkState)> _networkStateListeners = [];

  // Quality assessment settings
  static const Duration _defaultQualityTestTimeout = Duration(seconds: 10);
  static const String _defaultSpeedTestUrl =
      'https://httpbin.org/bytes/1024'; // 1KB test
  static const int _qualityTestSampleSize = 1024; // 1KB for speed test

  @override
  Stream<ConnectivityResult> get connectivityStream =>
      _connectivityController.stream;

  @override
  Stream<NetworkState> get networkStateStream => _networkStateController.stream;

  /// Initialize the network service
  Future<void> initialize() async {
    if (_isDisposed) {
      throw const NetworkServiceInitializationException.alreadyInitialized();
    }

    try {
      // Set up connectivity monitoring
      _connectivity.onConnectivityChanged.listen(_handleConnectivityChange);

      // Get initial connectivity state
      final initialConnectivity = await _connectivity.checkConnectivity();
      await _handleConnectivityChange(initialConnectivity);
    } on Exception catch (e) {
      throw NetworkServiceInitializationException(
        'Failed to initialize network service: $e',
        'NETWORK_SERVICE_INIT_FAILED',
        e,
      );
    }
  }

  @override
  Future<bool> get isConnected async {
    try {
      final connectivity = await checkConnectivity();
      return connectivity != ConnectivityResult.none;
    } on Exception {
      return false; // Assume disconnected on error
    }
  }

  @override
  Future<ConnectivityResult> checkConnectivity() async {
    try {
      return await _connectivity.checkConnectivity();
    } on Exception catch (e) {
      throw NetworkConnectivityException(
        'Failed to check connectivity: $e',
        'NETWORK_CONNECTIVITY_CHECK_FAILED',
        e,
      );
    }
  }

  @override
  Future<NetworkState> getNetworkState() async {
    try {
      final connectivity = await checkConnectivity();
      final isConnected = connectivity != ConnectivityResult.none;

      if (!isConnected) {
        return NetworkState.disconnected();
      }

      // Perform quality assessment if connected
      final quality = await assessNetworkQuality();
      final latency = await _measureLatency();

      final networkState = NetworkState(
        connectivity: connectivity,
        quality: quality,
        isConnected: isConnected,
        latencyMs: latency,
        timestamp: DateTime.now(),
      );

      _lastNetworkState = networkState;
      return networkState;
    } on Exception catch (e) {
      throw NetworkConnectivityException(
        'Failed to get network state: $e',
        'NETWORK_STATE_RETRIEVAL_FAILED',
        e,
      );
    }
  }

  @override
  Future<NetworkQuality> assessNetworkQuality() async {
    try {
      final isConnected = await this.isConnected;
      if (!isConnected) {
        return NetworkQuality.none;
      }

      // Measure latency
      final latency = await _measureLatency();
      if (latency == null) {
        return NetworkQuality.unknown;
      }

      // Estimate bandwidth
      final bandwidth = await estimateDownloadSpeed();

      // Determine quality based on latency and bandwidth
      return _determineQualityFromMetrics(latency, bandwidth);
    } on Exception catch (e) {
      throw NetworkQualityException(
        'Failed to assess network quality: $e',
        'NETWORK_QUALITY_ASSESSMENT_FAILED',
        e,
      );
    }
  }

  @override
  Future<NetworkUsageStats> getUsageStats() async {
    try {
      final connectivity = await checkConnectivity();

      return NetworkUsageStats(
        bytesSent: _bytesSent,
        bytesReceived: _bytesReceived,
        lastUpdated: DateTime.now(),
        connectionType: connectivity,
        estimatedBandwidth: _lastEstimatedBandwidth,
      );
    } on Exception catch (e) {
      throw NetworkUsageException(
        'Failed to get usage statistics: $e',
        'NETWORK_USAGE_STATS_FAILED',
        e,
      );
    }
  }

  @override
  Future<void> resetUsageStats() async {
    _bytesSent = 0;
    _bytesReceived = 0;
    _usageStatsStartTime = DateTime.now();
    _lastEstimatedBandwidth = null;
  }

  @override
  Future<T> executeWithRetry<T>(
    Future<T> Function() operation, {
    RetryConfig? config,
    bool Function(Exception)? shouldRetry,
  }) async {
    final retryConfig = config ?? RetryConfig.defaultConfig;

    for (var attempt = 0; attempt <= retryConfig.maxAttempts; attempt++) {
      try {
        return await operation();
      } on Exception catch (exception) {
        // Check if we should retry this exception
        if (shouldRetry != null && !shouldRetry(exception)) {
          rethrow;
        }

        // If this is the last attempt, don't wait
        if (attempt == retryConfig.maxAttempts) {
          break;
        }

        // Calculate delay with exponential backoff and optional jitter
        final baseDelay = retryConfig.initialDelay.inMilliseconds *
            pow(retryConfig.backoffMultiplier, attempt);

        var delayMs =
            min(baseDelay, retryConfig.maxDelay.inMilliseconds.toDouble());

        // Add jitter if enabled
        if (retryConfig.useJitter) {
          final jitter = Random().nextDouble() * 0.1; // Up to 10% jitter
          delayMs *= 1.0 + jitter;
        }

        await Future.delayed(Duration(milliseconds: delayMs.round()));
      }
    }

    throw NetworkRetryException.maxAttemptsExceeded(retryConfig.maxAttempts);
  }

  @override
  Future<void> startQualityMonitoring({
    Duration interval = const Duration(minutes: 1),
  }) async {
    if (_isMonitoringQuality) {
      throw const NetworkMonitoringException.alreadyActive();
    }

    try {
      _isMonitoringQuality = true;
      _qualityMonitoringTimer = Timer.periodic(interval, (_) async {
        try {
          final networkState = await getNetworkState();
          _networkStateController.add(networkState);

          // Notify all listeners
          for (final listener in _networkStateListeners) {
            try {
              listener(networkState);
            } on Exception catch (e) {
              // Ignore listener errors to prevent one bad listener from affecting others
              if (kDebugMode) {
                print('Network state listener error: $e');
              }
            }
          }
        } on Exception catch (e) {
          if (kDebugMode) {
            print('Quality monitoring error: $e');
          }
        }
      });
    } on Exception catch (e) {
      _isMonitoringQuality = false;
      throw NetworkMonitoringException(
        'Failed to start quality monitoring: $e',
        'NETWORK_MONITORING_START_FAILED',
        e,
      );
    }
  }

  @override
  Future<void> stopQualityMonitoring() async {
    _isMonitoringQuality = false;
    _qualityMonitoringTimer?.cancel();
    _qualityMonitoringTimer = null;
  }

  @override
  Future<bool> isHostReachable(
    String host, {
    int port = 80,
    Duration? timeout,
  }) async {
    try {
      final socket = await Socket.connect(
        host,
        port,
        timeout: timeout ?? const Duration(seconds: 5),
      );
      await socket.close();
      return true;
    } on Exception {
      return false;
    }
  }

  @override
  Future<double?> estimateDownloadSpeed({Duration? timeout}) async {
    try {
      final testTimeout = timeout ?? _defaultQualityTestTimeout;
      final stopwatch = Stopwatch()..start();

      // Use HTTP client to download test data
      final client = HttpClient();
      client.connectionTimeout = testTimeout;

      try {
        final request = await client.getUrl(Uri.parse(_defaultSpeedTestUrl));
        final response = await request.close();

        if (response.statusCode == 200) {
          final bytes = await response.fold<List<int>>(
            [],
            (previous, element) => previous..addAll(element),
          );

          stopwatch.stop();
          final bytesDownloaded = bytes.length;
          final timeSeconds = stopwatch.elapsedMicroseconds / 1000000.0;

          // Calculate speed in bytes per second
          final speed = bytesDownloaded / timeSeconds;
          _lastEstimatedBandwidth = speed;

          // Update usage stats
          _bytesReceived += bytesDownloaded;

          return speed;
        }
      } finally {
        client.close();
      }

      return null;
    } on Exception {
      return null;
    }
  }

  @override
  void addNetworkStateListener(void Function(NetworkState state) listener) {
    _networkStateListeners.add(listener);
  }

  @override
  void removeNetworkStateListener(void Function(NetworkState state) listener) {
    _networkStateListeners.remove(listener);
  }

  @override
  Future<void> dispose() async {
    if (_isDisposed) return;

    _isDisposed = true;
    await stopQualityMonitoring();

    await _connectivityController.close();
    await _networkStateController.close();

    _networkStateListeners.clear();
    _instance = null;
  }

  // Private helper methods

  Future<void> _handleConnectivityChange(ConnectivityResult result) async {
    if (_lastConnectivity != result) {
      _lastConnectivity = result;
      _connectivityController.add(result);

      // Update network state
      try {
        final networkState = await getNetworkState();
        _networkStateController.add(networkState);

        // Notify listeners
        for (final listener in _networkStateListeners) {
          try {
            listener(networkState);
          } on Exception catch (e) {
            // Ignore listener errors
            if (kDebugMode) {
              print('Network state listener error: $e');
            }
          }
        }
      } on Exception catch (e) {
        // Handle error silently in background connectivity monitoring
        if (kDebugMode) {
          print('Error updating network state: $e');
        }
      }
    }
  }

  Future<int?> _measureLatency() async {
    try {
      final stopwatch = Stopwatch()..start();

      // Ping a reliable host (Google DNS)
      final socket = await Socket.connect(
        '8.8.8.8',
        53,
        timeout: const Duration(seconds: 5),
      );
      stopwatch.stop();
      await socket.close();

      return stopwatch.elapsedMilliseconds;
    } on Exception {
      return null;
    }
  }

  NetworkQuality _determineQualityFromMetrics(
    int latencyMs,
    double? bandwidthBps,
  ) {
    // Quality assessment based on latency and bandwidth
    if (latencyMs > 2000) {
      return NetworkQuality.poor;
    } else if (latencyMs > 1000) {
      return NetworkQuality.fair;
    } else if (latencyMs > 500) {
      return NetworkQuality.good;
    } else if (latencyMs <= 500) {
      // Consider bandwidth for excellent rating
      if (bandwidthBps != null && bandwidthBps > 1024 * 1024) {
        // > 1MB/s
        return NetworkQuality.excellent;
      } else {
        return NetworkQuality.good;
      }
    } else {
      return NetworkQuality.unknown;
    }
  }
}
