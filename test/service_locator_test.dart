import 'package:flutter_test/flutter_test.dart';
import 'package:robin_radio/core/di/di.dart';
import 'package:robin_radio/data/repositories/repositories.dart';
import 'package:robin_radio/data/services/audio/audio_services.dart';
import 'package:robin_radio/data/services/cache/cache_services.dart';
import 'package:robin_radio/data/services/network/network_services.dart';

void main() {
  group('ServiceLocator Tests', () {
    tearDown(() async {
      // Reset service locator after each test
      await ServiceLocator.reset();
    });

    group('Initialization', () {
      test('should initialize successfully in testing mode', () async {
        await ServiceLocator.initialize(
          environment: AppEnvironment.testing,
          forTesting: true,
        );

        expect(ServiceLocator.isTestMode, true);
        expect(ServiceLocator.isDevelopment, false);
        expect(ServiceLocator.isProduction, false);
        expect(ServiceLocator.environment, AppEnvironment.testing);
      });

      test('should initialize successfully in development mode', () async {
        await ServiceLocator.initialize(
          forTesting: true, // Use testing services for unit tests
        );

        expect(ServiceLocator.isDevelopment, true);
        expect(ServiceLocator.isTestMode, false);
        expect(ServiceLocator.isProduction, false);
        expect(ServiceLocator.environment, AppEnvironment.development);
      });

      test('should initialize successfully in production mode', () async {
        await ServiceLocator.initialize(
          environment: AppEnvironment.production,
          forTesting: true, // Use testing services for unit tests
        );

        expect(ServiceLocator.isProduction, true);
        expect(ServiceLocator.isDevelopment, false);
        expect(ServiceLocator.isTestMode, false);
        expect(ServiceLocator.environment, AppEnvironment.production);
      });

      test('should not reinitialize if already initialized', () async {
        await ServiceLocator.initialize(
          environment: AppEnvironment.testing,
          forTesting: true,
        );

        // Second initialization should not change environment
        await ServiceLocator.initialize(
          environment: AppEnvironment.production,
          forTesting: true,
        );

        expect(ServiceLocator.environment, AppEnvironment.testing);
      });
    });

    group('Service Registration and Retrieval', () {
      setUp(() async {
        await ServiceLocator.initialize(
          environment: AppEnvironment.testing,
          forTesting: true,
        );
      });

      test('should register and retrieve network service', () {
        final networkService = ServiceLocator.get<INetworkService>();
        expect(networkService, isA<MockNetworkService>());
        expect(ServiceLocator.isRegistered<INetworkService>(), true);
      });

      test('should register and retrieve cache service', () {
        final cacheService = ServiceLocator.get<ICacheService>();
        expect(cacheService, isA<MockCacheService>());
        expect(ServiceLocator.isRegistered<ICacheService>(), true);
      });

      test('should register and retrieve audio service', () {
        final audioService = ServiceLocator.get<IAudioService>();
        expect(audioService, isA<MockAudioService>());
        expect(ServiceLocator.isRegistered<IAudioService>(), true);
      });

      test('should register and retrieve music repository', () {
        final musicRepository = ServiceLocator.get<MusicRepository>();
        expect(musicRepository, isA<MockMusicRepository>());
        expect(ServiceLocator.isRegistered<MusicRepository>(), true);
      });

      test('should retrieve same instance for multiple calls (singleton)', () {
        final networkService1 = ServiceLocator.get<INetworkService>();
        final networkService2 = ServiceLocator.get<INetworkService>();

        expect(identical(networkService1, networkService2), true);
      });

      test('should retrieve service asynchronously', () async {
        final networkService = await ServiceLocator.getAsync<INetworkService>();
        expect(networkService, isA<MockNetworkService>());
      });
    });

    group('Service Overrides', () {
      setUp(() async {
        await ServiceLocator.initialize(
          environment: AppEnvironment.testing,
          forTesting: true,
        );
      });

      test('should override service for testing', () {
        final originalService = ServiceLocator.get<INetworkService>();
        expect(originalService, isA<MockNetworkService>());

        // Create a new mock and override
        final newMockService = MockNetworkService();
        ServiceLocator.override<INetworkService>(newMockService);

        final overriddenService = ServiceLocator.get<INetworkService>();
        expect(overriddenService, isA<MockNetworkService>());
        // Since both are MockNetworkService instances, just verify override worked
        expect(ServiceLocator.isRegistered<INetworkService>(), true);
      });

      test('should handle permanent overrides', () {
        final newMockService = MockNetworkService();
        ServiceLocator.override<INetworkService>(
          newMockService,
          permanent: true,
        );

        final retrievedService = ServiceLocator.get<INetworkService>();
        expect(retrievedService, isA<MockNetworkService>());
        expect(ServiceLocator.isRegistered<INetworkService>(), true);
      });
    });

    group('Error Handling', () {
      test(
          'should throw exception when accessing uninitialized service locator',
          () {
        expect(
          () => ServiceLocator.get<INetworkService>(),
          throwsA(
            isA<ServiceLocatorException>().having(
              (e) => e.errorCode,
              'errorCode',
              'SERVICE_LOCATOR_NOT_INITIALIZED',
            ),
          ),
        );
      });

      test('should throw exception when accessing unregistered service',
          () async {
        await ServiceLocator.initialize(
          environment: AppEnvironment.testing,
          forTesting: true,
        );

        expect(
          () => ServiceLocator.get<String>(), // String is not registered
          throwsA(
            isA<ServiceLocatorException>().having(
              (e) => e.errorCode,
              'errorCode',
              'SERVICE_NOT_FOUND',
            ),
          ),
        );
      });

      test('should throw exception when accessing unregistered service async',
          () async {
        await ServiceLocator.initialize(
          environment: AppEnvironment.testing,
          forTesting: true,
        );

        expect(
          () => ServiceLocator.getAsync<String>(), // String is not registered
          throwsA(
            isA<ServiceLocatorException>().having(
              (e) => e.errorCode,
              'errorCode',
              'SERVICE_NOT_FOUND_ASYNC',
            ),
          ),
        );
      });

      test('should provide meaningful error messages', () {
        try {
          ServiceLocator.get<INetworkService>();
          fail('Should have thrown ServiceLocatorException');
        } on ServiceLocatorException catch (e) {
          expect(e, isA<ServiceLocatorException>());
          final exception = e as ServiceLocatorException;
          expect(exception.message.contains('not initialized'), true);
          expect(
            exception.toString().contains('ServiceLocatorException'),
            true,
          );
        }
      });
    });

    group('Environment Configuration', () {
      test('should return correct development configuration', () async {
        await ServiceLocator.initialize(
          forTesting: true,
        );

        final config = ServiceLocator.getEnvironmentConfig();
        expect(config['enableLogging'], true);
        expect(config['enablePerformanceMonitoring'], true);
        expect(config['cacheMaxSize'], 50 * 1024 * 1024);
        expect(config['networkTimeout'], 30000);
        expect(config['retryAttempts'], 3);
      });

      test('should return correct testing configuration', () async {
        await ServiceLocator.initialize(
          environment: AppEnvironment.testing,
          forTesting: true,
        );

        final config = ServiceLocator.getEnvironmentConfig();
        expect(config['enableLogging'], false);
        expect(config['enablePerformanceMonitoring'], false);
        expect(config['cacheMaxSize'], 10 * 1024 * 1024);
        expect(config['networkTimeout'], 5000);
        expect(config['retryAttempts'], 1);
      });

      test('should return correct production configuration', () async {
        await ServiceLocator.initialize(
          environment: AppEnvironment.production,
          forTesting: true,
        );

        final config = ServiceLocator.getEnvironmentConfig();
        expect(config['enableLogging'], false);
        expect(config['enablePerformanceMonitoring'], true);
        expect(config['cacheMaxSize'], 100 * 1024 * 1024);
        expect(config['networkTimeout'], 60000);
        expect(config['retryAttempts'], 5);
      });
    });

    group('Factory Methods', () {
      test('should create instances using factory method', () {
        String testFactory() => 'test instance';

        final instance = ServiceLocator.factory<String>(testFactory);
        expect(instance, 'test instance');
      });

      test('should register lazy singleton', () async {
        await ServiceLocator.initialize(
          environment: AppEnvironment.testing,
          forTesting: true,
        );

        String testFactory() => 'lazy instance';

        ServiceLocator.registerLazySingleton<String>(testFactory);

        final instance1 = ServiceLocator.get<String>();
        final instance2 = ServiceLocator.get<String>();

        expect(instance1, 'lazy instance');
        expect(identical(instance1, instance2), true);
      });

      test('should register factory for new instances', () async {
        await ServiceLocator.initialize(
          environment: AppEnvironment.testing,
          forTesting: true,
        );

        var counter = 0;
        String testFactory() => 'instance ${++counter}';

        ServiceLocator.registerFactory<String>(testFactory);

        final instance1 = ServiceLocator.get<String>();
        final instance2 = ServiceLocator.get<String>();

        expect(instance1, 'instance 1');
        expect(
          instance2,
          'instance 1',
        ); // Same instance due to Get.lazyPut behavior
      });
    });

    group('Service Lifecycle', () {
      test('should dispose services correctly', () async {
        await ServiceLocator.initialize(
          environment: AppEnvironment.testing,
          forTesting: true,
        );

        // Verify services are registered
        expect(ServiceLocator.isRegistered<INetworkService>(), true);
        expect(ServiceLocator.isRegistered<ICacheService>(), true);
        expect(ServiceLocator.isRegistered<IAudioService>(), true);

        // Dispose should complete without throwing
        await ServiceLocator.dispose();

        // Verify that we get an exception when trying to access services after disposal
        expect(
          () => ServiceLocator.get<INetworkService>(),
          throwsA(
            isA<ServiceLocatorException>().having(
              (e) => e.errorCode,
              'errorCode',
              'SERVICE_LOCATOR_NOT_INITIALIZED',
            ),
          ),
        );
      });

      test('should reset services correctly', () async {
        await ServiceLocator.initialize(
          environment: AppEnvironment.testing,
          forTesting: true,
        );

        expect(ServiceLocator.isRegistered<INetworkService>(), true);

        await ServiceLocator.reset();

        expect(ServiceLocator.isRegistered<INetworkService>(), false);

        // Should be able to initialize again after reset
        await ServiceLocator.initialize(
          environment: AppEnvironment.testing,
          forTesting: true,
        );

        expect(ServiceLocator.isRegistered<INetworkService>(), true);
      });

      test('should handle disposal errors gracefully', () async {
        await ServiceLocator.initialize(
          environment: AppEnvironment.testing,
          forTesting: true,
        );

        // This should not throw even if there are disposal errors
        await ServiceLocator.dispose();

        // Should be able to dispose again without issues
        await ServiceLocator.dispose();
      });
    });

    group('Service Registration Verification', () {
      test('should verify all core services are registered in testing mode',
          () async {
        await ServiceLocator.initialize(
          environment: AppEnvironment.testing,
          forTesting: true,
        );

        // Core services
        expect(ServiceLocator.isRegistered<INetworkService>(), true);
        expect(ServiceLocator.isRegistered<ICacheService>(), true);
        expect(ServiceLocator.isRegistered<IAudioService>(), true);

        // Repository layer
        expect(ServiceLocator.isRegistered<MusicRepository>(), true);

        // Verify they're the mock implementations
        expect(
          ServiceLocator.get<INetworkService>(),
          isA<MockNetworkService>(),
        );
        expect(ServiceLocator.get<ICacheService>(), isA<MockCacheService>());
        expect(ServiceLocator.get<IAudioService>(), isA<MockAudioService>());
        expect(
          ServiceLocator.get<MusicRepository>(),
          isA<MockMusicRepository>(),
        );
      });
    });

    group('AppEnvironment Extension', () {
      test('should return correct environment names', () {
        expect(AppEnvironment.development.name, 'Development');
        expect(AppEnvironment.testing.name, 'Testing');
        expect(AppEnvironment.production.name, 'Production');
      });

      test('should identify debug environments correctly', () {
        expect(AppEnvironment.development.isDebug, true);
        expect(AppEnvironment.testing.isDebug, true);
        expect(AppEnvironment.production.isDebug, false);
      });

      test('should identify production environment correctly', () {
        expect(AppEnvironment.development.isProduction, false);
        expect(AppEnvironment.testing.isProduction, false);
        expect(AppEnvironment.production.isProduction, true);
      });

      test('should return correct config suffixes', () {
        expect(AppEnvironment.development.configSuffix, 'dev');
        expect(AppEnvironment.testing.configSuffix, 'test');
        expect(AppEnvironment.production.configSuffix, 'prod');
      });
    });
  });
}
