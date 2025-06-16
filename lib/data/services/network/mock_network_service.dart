import 'dart:async';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';

import 'network_service_interface.dart';
import '../../exceptions/network_service_exception.dart';

/// Mock implementation of network service for testing purposes.
///
/// This implementation simulates all network operations and provides
/// controllable responses for testing different network scenarios.
class MockNetworkService implements INetworkService {
  // Stream controllers for reactive updates
  final StreamController<ConnectivityResult> _connectivityController =
      StreamController<ConnectivityResult>.broadcast();
  final StreamController<NetworkState> _networkStateController =
      StreamController<NetworkState>.broadcast();

  // Mock state management
  ConnectivityResult _currentConnectivity = ConnectivityResult.wifi;
  NetworkQuality _currentQuality = NetworkQuality.good;
  bool _isConnected = true;
  int? _latencyMs = 100;
  bool _isMonitoringQuality = false;
  bool _isDisposed = false;

  // Mock usage statistics
  int _bytesSent = 0;
  int _bytesReceived = 0;
  DateTime _usageStatsStartTime = DateTime.now();
  double? _estimatedBandwidth = 1024 * 1024; // 1MB/s default

  // State change listeners
  final List<void Function(NetworkState state)> _networkStateListeners = [];

  // Mock configuration
  Duration _simulatedLatency = const Duration(milliseconds: 100);
  bool _simulateNetworkFailures = false;
  double _failureRate = 0; // 0.0 = no failures, 1.0 = always fail

  @override
  Stream<ConnectivityResult> get connectivityStream =>
      _connectivityController.stream;

  @override
  Stream<NetworkState> get networkStateStream => _networkStateController.stream;

  @override
  Future<bool> get isConnected async {
    await Future.delayed(_simulatedLatency);
    return _isConnected;
  }

  @override
  Future<ConnectivityResult> checkConnectivity() async {
    await Future.delayed(_simulatedLatency);
    if (_simulateNetworkFailures && Random().nextDouble() < _failureRate) {
      throw const NetworkConnectivityException(
        'Mock connectivity check failed',
        'MOCK_CONNECTIVITY_FAILED',
      );
    }
    return _currentConnectivity;
  }

  @override
  Future<NetworkState> getNetworkState() async {
    await Future.delayed(_simulatedLatency);

    if (_simulateNetworkFailures && Random().nextDouble() < _failureRate) {
      throw const NetworkConnectivityException(
        'Mock network state retrieval failed',
        'MOCK_NETWORK_STATE_FAILED',
      );
    }

    // Update quality based on connectivity
    final quality = _isConnected ? _currentQuality : NetworkQuality.none;

    return NetworkState(
      connectivity: _currentConnectivity,
      quality: quality,
      isConnected: _isConnected,
      latencyMs: _latencyMs,
      timestamp: DateTime.now(),
    );
  }

  @override
  Future<NetworkQuality> assessNetworkQuality() async {
    await Future.delayed(_simulatedLatency);

    if (_simulateNetworkFailures && Random().nextDouble() < _failureRate) {
      throw const NetworkQualityException(
        'Mock quality assessment failed',
        'MOCK_QUALITY_ASSESSMENT_FAILED',
      );
    }

    return _isConnected ? _currentQuality : NetworkQuality.none;
  }

  @override
  Future<NetworkUsageStats> getUsageStats() async {
    await Future.delayed(_simulatedLatency);

    return NetworkUsageStats(
      bytesSent: _bytesSent,
      bytesReceived: _bytesReceived,
      lastUpdated: DateTime.now(),
      connectionType: _currentConnectivity,
      estimatedBandwidth: _estimatedBandwidth,
    );
  }

  @override
  Future<void> resetUsageStats() async {
    await Future.delayed(_simulatedLatency);
    _bytesSent = 0;
    _bytesReceived = 0;
    _usageStatsStartTime = DateTime.now();
    _estimatedBandwidth = 1024 * 1024; // Reset to 1MB/s
  }

  @override
  Future<T> executeWithRetry<T>(
    Future<T> Function() operation, {
    RetryConfig? config,
    bool Function(dynamic exception)? shouldRetry,
  }) async {
    final retryConfig = config ?? RetryConfig.defaultConfig;

    for (var attempt = 0; attempt <= retryConfig.maxAttempts; attempt++) {
      try {
        return await operation();
      } catch (exception) {
        // Check if we should retry this exception
        if (shouldRetry != null && !shouldRetry(exception)) {
          rethrow;
        }

        // If this is the last attempt, don't wait
        if (attempt == retryConfig.maxAttempts) {
          break;
        }

        // Simulate retry delay
        final baseDelay = retryConfig.initialDelay.inMilliseconds *
            pow(retryConfig.backoffMultiplier, attempt);
        var delayMs =
            min(baseDelay, retryConfig.maxDelay.inMilliseconds.toDouble());

        if (retryConfig.useJitter) {
          final jitter = Random().nextDouble() * 0.1;
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

    _isMonitoringQuality = true;

    // Simulate periodic quality monitoring
    Timer.periodic(interval, (_) async {
      if (!_isMonitoringQuality || _isDisposed) return;

      try {
        final networkState = await getNetworkState();
        _networkStateController.add(networkState);

        // Notify listeners
        for (final listener in _networkStateListeners) {
          try {
            listener(networkState);
          } catch (e) {
            // Ignore listener errors
          }
        }
      } catch (e) {
        // Ignore monitoring errors in mock
      }
    });
  }

  @override
  Future<void> stopQualityMonitoring() async {
    _isMonitoringQuality = false;
  }

  @override
  Future<bool> isHostReachable(
    String host, {
    int port = 80,
    Duration? timeout,
  }) async {
    await Future.delayed(_simulatedLatency);

    if (_simulateNetworkFailures && Random().nextDouble() < _failureRate) {
      return false;
    }

    // Simulate host reachability based on connection state
    return _isConnected;
  }

  @override
  Future<double?> estimateDownloadSpeed({Duration? timeout}) async {
    await Future.delayed(_simulatedLatency);

    if (!_isConnected) {
      return null;
    }

    if (_simulateNetworkFailures && Random().nextDouble() < _failureRate) {
      return null;
    }

    // Simulate bandwidth measurement
    _bytesReceived += 1024; // Simulate 1KB download for test
    return _estimatedBandwidth;
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
  }

  // Mock-specific methods for testing control

  /// Set the mock connectivity state for testing
  void setMockConnectivity(ConnectivityResult connectivity) {
    _currentConnectivity = connectivity;
    _isConnected = connectivity != ConnectivityResult.none;
    _connectivityController.add(connectivity);
  }

  /// Set the mock network quality for testing
  void setMockQuality(NetworkQuality quality) {
    _currentQuality = quality;
  }

  /// Set mock latency for testing
  void setMockLatency(int? latencyMs) {
    _latencyMs = latencyMs;
  }

  /// Set mock bandwidth for testing
  void setMockBandwidth(double? bandwidth) {
    _estimatedBandwidth = bandwidth;
  }

  /// Enable/disable network failure simulation
  void setSimulateNetworkFailures(bool simulate, {double failureRate = 0.1}) {
    _simulateNetworkFailures = simulate;
    _failureRate = failureRate.clamp(0.0, 1.0);
  }

  /// Set simulated network latency
  void setSimulatedLatency(Duration latency) {
    _simulatedLatency = latency;
  }

  /// Simulate connectivity change for testing
  Future<void> simulateConnectivityChange(
    ConnectivityResult newConnectivity,
  ) async {
    setMockConnectivity(newConnectivity);

    final networkState = await getNetworkState();
    _networkStateController.add(networkState);

    // Notify listeners
    for (final listener in _networkStateListeners) {
      try {
        listener(networkState);
      } catch (e) {
        // Ignore listener errors
      }
    }
  }

  /// Simulate disconnection for testing
  Future<void> simulateDisconnection() async {
    await simulateConnectivityChange(ConnectivityResult.none);
  }

  /// Simulate reconnection for testing
  Future<void> simulateReconnection({ConnectivityResult? connectivity}) async {
    await simulateConnectivityChange(connectivity ?? ConnectivityResult.wifi);
  }

  /// Add mock bytes to usage statistics
  void addMockUsage({int bytesSent = 0, int bytesReceived = 0}) {
    _bytesSent += bytesSent;
    _bytesReceived += bytesReceived;
  }

  /// Reset all mock state to defaults
  void resetMockState() {
    _currentConnectivity = ConnectivityResult.wifi;
    _currentQuality = NetworkQuality.good;
    _isConnected = true;
    _latencyMs = 100;
    _estimatedBandwidth = 1024 * 1024;
    _simulateNetworkFailures = false;
    _failureRate = 0.0;
    _simulatedLatency = const Duration(milliseconds: 100);
    resetUsageStats();
  }
}
