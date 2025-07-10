import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:robin_radio/data/services/network/network_services.dart';

void main() {
  group('Network Service Tests', () {
    late MockNetworkService mockNetwork;
    late INetworkService networkService;

    setUp(() {
      mockNetwork = MockNetworkService();
      networkService = mockNetwork;
      mockNetwork.resetMockState();
    });

    tearDown(() async {
      await mockNetwork.dispose();
    });

    group('Basic Connectivity Operations', () {
      test('should check connectivity and return current state', () async {
        mockNetwork.setMockConnectivity(ConnectivityResult.wifi);

        final connectivity = await networkService.checkConnectivity();
        expect(connectivity, ConnectivityResult.wifi);
      });

      test('should return connected status when on WiFi', () async {
        mockNetwork.setMockConnectivity(ConnectivityResult.wifi);

        final isConnected = await networkService.isConnected;
        expect(isConnected, true);
      });

      test('should return disconnected status when no connection', () async {
        mockNetwork.setMockConnectivity(ConnectivityResult.none);

        final isConnected = await networkService.isConnected;
        expect(isConnected, false);
      });

      test('should return connected status when on mobile', () async {
        mockNetwork.setMockConnectivity(ConnectivityResult.mobile);

        final isConnected = await networkService.isConnected;
        expect(isConnected, true);
      });
    });

    group('Network State Management', () {
      test('should return complete network state when connected', () async {
        mockNetwork
          ..setMockConnectivity(ConnectivityResult.wifi)
          ..setMockQuality(NetworkQuality.excellent)
          ..setMockLatency(50);

        final networkState = await networkService.getNetworkState();

        expect(networkState.connectivity, ConnectivityResult.wifi);
        expect(networkState.quality, NetworkQuality.excellent);
        expect(networkState.isConnected, true);
        expect(networkState.latencyMs, 50);
        expect(networkState.timestamp, isA<DateTime>());
      });

      test('should return disconnected network state when no connection',
          () async {
        mockNetwork.setMockConnectivity(ConnectivityResult.none);

        final networkState = await networkService.getNetworkState();

        expect(networkState.connectivity, ConnectivityResult.none);
        expect(networkState.quality, NetworkQuality.none);
        expect(networkState.isConnected, false);
      });

      test('should create network state with factory constructors', () {
        final disconnectedState = NetworkState.disconnected();
        expect(disconnectedState.connectivity, ConnectivityResult.none);
        expect(disconnectedState.quality, NetworkQuality.none);
        expect(disconnectedState.isConnected, false);

        final connectedState = NetworkState.connected(ConnectivityResult.wifi);
        expect(connectedState.connectivity, ConnectivityResult.wifi);
        expect(connectedState.quality, NetworkQuality.unknown);
        expect(connectedState.isConnected, true);
      });
    });

    group('Network Quality Assessment', () {
      test('should assess quality as excellent for good metrics', () async {
        mockNetwork
          ..setMockConnectivity(ConnectivityResult.wifi)
          ..setMockQuality(NetworkQuality.excellent);

        final quality = await networkService.assessNetworkQuality();
        expect(quality, NetworkQuality.excellent);
      });

      test('should assess quality as none when disconnected', () async {
        mockNetwork.setMockConnectivity(ConnectivityResult.none);

        final quality = await networkService.assessNetworkQuality();
        expect(quality, NetworkQuality.none);
      });

      test('should assess quality as poor for bad metrics', () async {
        mockNetwork
          ..setMockConnectivity(ConnectivityResult.mobile)
          ..setMockQuality(NetworkQuality.poor);

        final quality = await networkService.assessNetworkQuality();
        expect(quality, NetworkQuality.poor);
      });
    });

    group('Network Usage Statistics', () {
      test('should return initial usage statistics', () async {
        final stats = await networkService.getUsageStats();

        expect(stats.bytesSent, 0);
        expect(stats.bytesReceived, 0);
        expect(stats.totalBytes, 0);
        expect(stats.connectionType, isA<ConnectivityResult>());
        expect(stats.lastUpdated, isA<DateTime>());
      });

      test('should track usage statistics correctly', () async {
        mockNetwork.addMockUsage(bytesSent: 1024, bytesReceived: 2048);

        final stats = await networkService.getUsageStats();

        expect(stats.bytesSent, 1024);
        expect(stats.bytesReceived, 2048);
        expect(stats.totalBytes, 3072);
      });

      test('should reset usage statistics', () async {
        mockNetwork.addMockUsage(bytesSent: 1024, bytesReceived: 2048);

        await networkService.resetUsageStats();
        final stats = await networkService.getUsageStats();

        expect(stats.bytesSent, 0);
        expect(stats.bytesReceived, 0);
        expect(stats.totalBytes, 0);
      });

      test('should include bandwidth estimation in statistics', () async {
        mockNetwork.setMockBandwidth(1024 * 1024); // 1MB/s

        final stats = await networkService.getUsageStats();
        expect(stats.estimatedBandwidth, 1024 * 1024);
      });
    });

    group('Retry Mechanisms', () {
      test('should succeed on first attempt', () async {
        var attempts = 0;

        final result = await networkService.executeWithRetry(() async {
          attempts++;
          return 'success';
        });

        expect(result, 'success');
        expect(attempts, 1);
      });

      test('should retry on failure and eventually succeed', () async {
        var attempts = 0;

        final result = await networkService.executeWithRetry(() async {
          attempts++;
          if (attempts < 3) {
            throw Exception('Temporary failure');
          }
          return 'success after retries';
        });

        expect(result, 'success after retries');
        expect(attempts, 3);
      });

      test('should fail after max attempts exceeded', () async {
        var attempts = 0;

        expect(
          () => networkService.executeWithRetry(
            () async {
              attempts++;
              throw Exception('Always fails');
            },
            config: const RetryConfig(maxAttempts: 2),
          ),
          throwsA(isA<NetworkRetryException>()),
        );

        expect(attempts, 3); // Initial attempt + 2 retries
      });

      test('should respect custom shouldRetry predicate', () async {
        var attempts = 0;

        expect(
          () => networkService.executeWithRetry(
            () async {
              attempts++;
              throw ArgumentError('Non-retryable error');
            },
            shouldRetry: (error) => error is! ArgumentError,
          ),
          throwsA(isA<ArgumentError>()),
        );

        expect(attempts, 1); // Should not retry ArgumentError
      });

      test('should use custom retry configuration', () async {
        var attempts = 0;
        const customConfig = RetryConfig(
          maxAttempts: 5,
          initialDelay: Duration(milliseconds: 10),
          backoffMultiplier: 1.5,
        );

        expect(
          () => networkService.executeWithRetry(
            () async {
              attempts++;
              throw Exception('Always fails');
            },
            config: customConfig,
          ),
          throwsA(isA<NetworkRetryException>()),
        );

        expect(attempts, 6); // Initial attempt + 5 retries
      });
    });

    group('Quality Monitoring', () {
      test('should start quality monitoring successfully', () async {
        await networkService.startQualityMonitoring(
          interval: const Duration(milliseconds: 100),
        );

        // Should not throw, monitoring started
        expect(true, true);

        await networkService.stopQualityMonitoring();
      });

      test('should throw exception when starting monitoring twice', () async {
        await networkService.startQualityMonitoring();

        expect(
          () => networkService.startQualityMonitoring(),
          throwsA(isA<NetworkMonitoringException>()),
        );

        await networkService.stopQualityMonitoring();
      });

      test('should stop quality monitoring successfully', () async {
        await networkService.startQualityMonitoring();
        await networkService.stopQualityMonitoring();

        // Should be able to start again after stopping
        await networkService.startQualityMonitoring();
        await networkService.stopQualityMonitoring();
      });

      test('should emit network state updates during monitoring', () async {
        final stateUpdates = <NetworkState>[];
        final subscription =
            networkService.networkStateStream.listen(stateUpdates.add);

        await networkService.startQualityMonitoring(
          interval: const Duration(milliseconds: 50),
        );

        // Wait for a few updates
        await Future<void>.delayed(const Duration(milliseconds: 150));

        await networkService.stopQualityMonitoring();
        await subscription.cancel();

        expect(stateUpdates.length, greaterThan(0));
      });
    });

    group('Host Reachability', () {
      test('should return true when host is reachable and connected', () async {
        mockNetwork.setMockConnectivity(ConnectivityResult.wifi);

        final isReachable = await networkService.isHostReachable('google.com');
        expect(isReachable, true);
      });

      test('should return false when disconnected', () async {
        mockNetwork.setMockConnectivity(ConnectivityResult.none);

        final isReachable = await networkService.isHostReachable('google.com');
        expect(isReachable, false);
      });

      test('should test custom port and timeout', () async {
        mockNetwork.setMockConnectivity(ConnectivityResult.wifi);

        final isReachable = await networkService.isHostReachable(
          'example.com',
          port: 443,
          timeout: const Duration(seconds: 2),
        );
        expect(isReachable, true);
      });
    });

    group('Download Speed Estimation', () {
      test('should estimate download speed when connected', () async {
        mockNetwork
          ..setMockConnectivity(ConnectivityResult.wifi)
          ..setMockBandwidth(1024 * 1024); // 1MB/s

        final speed = await networkService.estimateDownloadSpeed();
        expect(speed, 1024 * 1024);
      });

      test('should return null when disconnected', () async {
        mockNetwork.setMockConnectivity(ConnectivityResult.none);

        final speed = await networkService.estimateDownloadSpeed();
        expect(speed, null);
      });

      test('should respect timeout parameter', () async {
        mockNetwork.setMockConnectivity(ConnectivityResult.wifi);

        final speed = await networkService.estimateDownloadSpeed(
          timeout: const Duration(seconds: 5),
        );
        expect(speed, isA<double>());
      });
    });

    group('State Change Listeners', () {
      test('should add and notify state change listeners', () async {
        final stateChanges = <NetworkState>[];

        void listener(NetworkState state) {
          stateChanges.add(state);
        }

        networkService.addNetworkStateListener(listener);

        // Simulate connectivity change
        await mockNetwork.simulateConnectivityChange(ConnectivityResult.mobile);

        // Give time for async operations
        await Future<void>.delayed(const Duration(milliseconds: 200));

        expect(stateChanges.length, greaterThan(0));
        expect(stateChanges.last.connectivity, ConnectivityResult.mobile);

        networkService.removeNetworkStateListener(listener);
      });

      test('should remove state change listeners correctly', () async {
        final stateChanges = <NetworkState>[];

        void listener(NetworkState state) {
          stateChanges.add(state);
        }

        networkService
          ..addNetworkStateListener(listener)
          ..removeNetworkStateListener(listener);

        // Simulate connectivity change after removing listener
        await mockNetwork.simulateConnectivityChange(ConnectivityResult.mobile);
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // Should not receive updates after removal
        expect(stateChanges.length, 0);
      });
    });

    group('Stream Connectivity Monitoring', () {
      test('should emit connectivity changes through stream', () async {
        final connectivityChanges = <ConnectivityResult>[];
        final subscription =
            networkService.connectivityStream.listen(connectivityChanges.add);

        await mockNetwork.simulateConnectivityChange(ConnectivityResult.mobile);
        await mockNetwork.simulateConnectivityChange(ConnectivityResult.wifi);
        await mockNetwork.simulateConnectivityChange(ConnectivityResult.none);

        await Future<void>.delayed(const Duration(milliseconds: 100));
        await subscription.cancel();

        expect(connectivityChanges, contains(ConnectivityResult.mobile));
        expect(connectivityChanges, contains(ConnectivityResult.wifi));
        expect(connectivityChanges, contains(ConnectivityResult.none));
      });

      test('should emit network state changes through stream', () async {
        final networkStateChanges = <NetworkState>[];
        final subscription =
            networkService.networkStateStream.listen(networkStateChanges.add);

        await mockNetwork.simulateConnectivityChange(ConnectivityResult.wifi);
        await mockNetwork.simulateDisconnection();
        await mockNetwork.simulateReconnection();

        await Future<void>.delayed(const Duration(milliseconds: 100));
        await subscription.cancel();

        expect(networkStateChanges.length, greaterThan(0));

        // Should have both connected and disconnected states
        final hasConnected =
            networkStateChanges.any((state) => state.isConnected);
        final hasDisconnected =
            networkStateChanges.any((state) => !state.isConnected);

        expect(hasConnected, true);
        expect(hasDisconnected, true);
      });
    });

    group('Network Failure Simulation', () {
      test('should simulate network failures when enabled', () async {
        mockNetwork.setSimulateNetworkFailures(
          simulate: true,
          failureRate: 1,
        ); // Always fail

        expect(
          () => networkService.checkConnectivity(),
          throwsA(isA<NetworkConnectivityException>()),
        );
      });

      test('should work normally when failure simulation disabled', () async {
        mockNetwork
          ..setSimulateNetworkFailures(simulate: false)
          ..setMockConnectivity(ConnectivityResult.wifi);

        final connectivity = await networkService.checkConnectivity();
        expect(connectivity, ConnectivityResult.wifi);
      });
    });

    group('Retry Configuration', () {
      test('should use default retry configuration', () {
        const defaultConfig = RetryConfig.defaultConfig;

        expect(defaultConfig.maxAttempts, 3);
        expect(defaultConfig.initialDelay, const Duration(seconds: 1));
        expect(defaultConfig.backoffMultiplier, 2.0);
        expect(defaultConfig.maxDelay, const Duration(seconds: 30));
        expect(defaultConfig.useJitter, true);
      });

      test('should use aggressive retry configuration', () {
        const aggressiveConfig = RetryConfig.aggressive;

        expect(aggressiveConfig.maxAttempts, 5);
        expect(
          aggressiveConfig.initialDelay,
          const Duration(milliseconds: 500),
        );
        expect(aggressiveConfig.backoffMultiplier, 1.5);
        expect(aggressiveConfig.maxDelay, const Duration(seconds: 15));
      });
    });

    group('Dispose and Cleanup', () {
      test('should dispose properly and clean up resources', () async {
        final service = MockNetworkService();

        await service.startQualityMonitoring();
        await service.dispose();

        // Should not throw even if disposing twice
        await service.dispose();
      });

      test('should close streams when disposing', () async {
        final service = MockNetworkService();
        var connectivityStreamClosed = false;
        var networkStateStreamClosed = false;

        service.connectivityStream.listen(
          (_) {},
          onDone: () => connectivityStreamClosed = true,
        );

        service.networkStateStream.listen(
          (_) {},
          onDone: () => networkStateStreamClosed = true,
        );

        await service.dispose();
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(connectivityStreamClosed, true);
        expect(networkStateStreamClosed, true);
      });
    });

    group('Mock Specific Features', () {
      test('should reset mock state correctly', () async {
        mockNetwork
          ..setMockConnectivity(ConnectivityResult.mobile)
          ..setMockQuality(NetworkQuality.poor)
          ..setMockLatency(2000)
          ..addMockUsage(bytesSent: 1000, bytesReceived: 2000)
          ..resetMockState();

        final connectivity = await networkService.checkConnectivity();
        final quality = await networkService.assessNetworkQuality();
        final stats = await networkService.getUsageStats();

        expect(connectivity, ConnectivityResult.wifi);
        expect(quality, NetworkQuality.good);
        expect(stats.bytesSent, 0);
        expect(stats.bytesReceived, 0);
      });

      test('should simulate different latency values', () async {
        mockNetwork.setSimulatedLatency(const Duration(milliseconds: 500));

        final stopwatch = Stopwatch()..start();
        await networkService.checkConnectivity();
        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(450));
      });
    });
  });
}
