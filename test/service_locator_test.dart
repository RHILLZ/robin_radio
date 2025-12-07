import 'package:flutter_test/flutter_test.dart';
import 'package:robin_radio/core/di/di.dart';
import 'package:robin_radio/data/repositories/repositories.dart';
import 'package:robin_radio/data/services/audio/audio_services.dart';

void main() {
  group('ServiceLocator Tests', () {
    tearDown(() async {
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
          forTesting: true,
        );

        expect(ServiceLocator.isDevelopment, true);
        expect(ServiceLocator.isTestMode, false);
        expect(ServiceLocator.isProduction, false);
        expect(ServiceLocator.environment, AppEnvironment.development);
      });

      test('should initialize successfully in production mode', () async {
        await ServiceLocator.initialize(
          environment: AppEnvironment.production,
          forTesting: true,
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
        final audioService1 = ServiceLocator.get<IAudioService>();
        final audioService2 = ServiceLocator.get<IAudioService>();

        expect(identical(audioService1, audioService2), true);
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
        final originalService = ServiceLocator.get<IAudioService>();
        expect(originalService, isA<MockAudioService>());

        final newMockService = MockAudioService();
        ServiceLocator.override<IAudioService>(newMockService);

        final overriddenService = ServiceLocator.get<IAudioService>();
        expect(overriddenService, isA<MockAudioService>());
        expect(ServiceLocator.isRegistered<IAudioService>(), true);
      });
    });

    group('Error Handling', () {
      test(
          'should throw exception when accessing uninitialized service locator',
          () {
        expect(
          () => ServiceLocator.get<IAudioService>(),
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
          () => ServiceLocator.get<String>(),
          throwsA(
            isA<ServiceLocatorException>().having(
              (e) => e.errorCode,
              'errorCode',
              'SERVICE_NOT_FOUND',
            ),
          ),
        );
      });

      test('should provide meaningful error messages', () {
        try {
          ServiceLocator.get<IAudioService>();
          fail('Should have thrown ServiceLocatorException');
        } on ServiceLocatorException catch (e) {
          expect(e.message.contains('not initialized'), true);
          expect(e.toString().contains('ServiceLocatorException'), true);
        }
      });
    });

    group('Service Lifecycle', () {
      test('should dispose services correctly', () async {
        await ServiceLocator.initialize(
          environment: AppEnvironment.testing,
          forTesting: true,
        );

        expect(ServiceLocator.isRegistered<IAudioService>(), true);

        await ServiceLocator.dispose();

        expect(
          () => ServiceLocator.get<IAudioService>(),
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

        expect(ServiceLocator.isRegistered<IAudioService>(), true);

        await ServiceLocator.reset();

        expect(ServiceLocator.isRegistered<IAudioService>(), false);

        await ServiceLocator.initialize(
          environment: AppEnvironment.testing,
          forTesting: true,
        );

        expect(ServiceLocator.isRegistered<IAudioService>(), true);
      });
    });

    group('Service Registration Verification', () {
      test('should verify all core services are registered in testing mode',
          () async {
        await ServiceLocator.initialize(
          environment: AppEnvironment.testing,
          forTesting: true,
        );

        expect(ServiceLocator.isRegistered<IAudioService>(), true);
        expect(ServiceLocator.isRegistered<MusicRepository>(), true);

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
