import 'package:get/get.dart';

import '../../data/repositories/repositories.dart';
import '../../data/services/audio/audio_services.dart';
import '../../data/services/cache/cache_services.dart';
import '../../data/services/network/network_services.dart';
import '../environment/app_environment.dart';

/// Centralized service locator using GetX for dependency injection.
///
/// Provides:
/// - Lazy initialization of services
/// - Environment-specific configurations
/// - Service override capability for testing
/// - Singleton and factory service registration
/// - Cleanup and disposal management
class ServiceLocator {
  static bool _isInitialized = false;
  static AppEnvironment _currentEnvironment = AppEnvironment.development;

  /// Initialize all services and repositories.
  ///
  /// [environment] - The app environment (development, testing, production)
  /// [forTesting] - Whether to use mock implementations for testing
  static Future<void> initialize({
    AppEnvironment environment = AppEnvironment.development,
    bool forTesting = false,
  }) async {
    if (_isInitialized) {
      return;
    }

    _currentEnvironment = environment;

    // Register core services first (order matters for dependencies)
    await _registerCoreServices(forTesting: forTesting);

    // Register repositories that depend on services
    await _registerRepositories(forTesting: forTesting);

    // Register higher-level services that depend on repositories
    await _registerApplicationServices(forTesting: forTesting);

    _isInitialized = true;
  }

  /// Register core foundational services.
  static Future<void> _registerCoreServices({required bool forTesting}) async {
    // Network Service - foundational for all network operations
    if (forTesting) {
      Get.put<INetworkService>(
        MockNetworkService(),
        permanent: true,
      );
    } else {
      Get.put<INetworkService>(
        EnhancedNetworkService.instance,
        permanent: true,
      );
    }

    // Cache Service - foundational for data persistence
    if (forTesting) {
      Get.put<ICacheService>(
        MockCacheService(),
        permanent: true,
      );
    } else {
      Get.put<ICacheService>(
        EnhancedCacheService.instance,
        permanent: true,
      );
    }

    // Audio Service - media playback management
    if (forTesting) {
      Get.put<IAudioService>(
        MockAudioService(),
        permanent: true,
      );
    } else {
      Get.put<IAudioService>(
        EnhancedAudioService(),
        permanent: true,
      );
    }
  }

  /// Register repository layer services.
  static Future<void> _registerRepositories({required bool forTesting}) async {
    // Music Repository - uses singleton pattern
    if (forTesting) {
      Get.put<MusicRepository>(
        const MockMusicRepository(),
        permanent: true,
      );
    } else {
      Get.put<MusicRepository>(
        FirebaseMusicRepository(),
        permanent: true,
      );
    }
  }

  /// Register application-level services.
  static Future<void> _registerApplicationServices({
    required bool forTesting,
  }) async {
    // Performance Service - if needed for monitoring
    // Additional application services can be added here
  }

  /// Get a service instance by type.
  ///
  /// Throws an exception if the service is not registered.
  static T get<T>() {
    if (!_isInitialized) {
      throw const ServiceLocatorException(
        'ServiceLocator not initialized. Call ServiceLocator.initialize() first.',
        'SERVICE_LOCATOR_NOT_INITIALIZED',
      );
    }

    try {
      return Get.find<T>();
    } catch (e) {
      throw ServiceLocatorException(
        "Service of type $T not found. Make sure it's registered in ServiceLocator.",
        'SERVICE_NOT_FOUND',
        e,
      );
    }
  }

  /// Get a service instance asynchronously by type.
  ///
  /// This is useful for services that might not be immediately available.
  static Future<T> getAsync<T>() async {
    if (!_isInitialized) {
      throw const ServiceLocatorException(
        'ServiceLocator not initialized. Call ServiceLocator.initialize() first.',
        'SERVICE_LOCATOR_NOT_INITIALIZED',
      );
    }

    try {
      return Get.find<T>();
    } catch (e) {
      throw ServiceLocatorException(
        "Service of type $T not found. Make sure it's registered in ServiceLocator.",
        'SERVICE_NOT_FOUND_ASYNC',
        e,
      );
    }
  }

  /// Override a service for testing purposes.
  ///
  /// [service] - The mock or test implementation to use
  /// [permanent] - Whether the override should persist across tests
  static void override<T>(T service, {bool permanent = false}) {
    // Remove existing registration if present
    if (Get.isRegistered<T>()) {
      Get.delete<T>();
    }

    // Register the override
    Get.put<T>(service, permanent: permanent);
  }

  /// Check if a service is registered.
  static bool isRegistered<T>() => Get.isRegistered<T>();

  /// Get the current environment.
  static AppEnvironment get environment => _currentEnvironment;

  /// Check if running in test mode.
  static bool get isTestMode => _currentEnvironment == AppEnvironment.testing;

  /// Check if running in development mode.
  static bool get isDevelopment =>
      _currentEnvironment == AppEnvironment.development;

  /// Check if running in production mode.
  static bool get isProduction =>
      _currentEnvironment == AppEnvironment.production;

  /// Reset and dispose all services.
  ///
  /// This should be called when the app is shutting down or between tests.
  static Future<void> dispose() async {
    if (!_isInitialized) {
      return;
    }

    // Dispose services in reverse order of initialization
    try {
      // Dispose audio service
      if (Get.isRegistered<IAudioService>()) {
        final audioService = Get.find<IAudioService>();
        await audioService.dispose();
        Get.delete<IAudioService>();
      }

      // Clear cache service
      if (Get.isRegistered<ICacheService>()) {
        final cacheService = Get.find<ICacheService>();
        await cacheService.clear();
        Get.delete<ICacheService>();
      }

      // Dispose network service
      if (Get.isRegistered<INetworkService>()) {
        final networkService = Get.find<INetworkService>();
        await networkService.dispose();
        Get.delete<INetworkService>();
      }

      // Dispose repositories
      if (Get.isRegistered<MusicRepository>()) {
        Get.delete<MusicRepository>();
      }
    } catch (e) {
      // Log disposal errors but don't throw
      print('Error during ServiceLocator disposal: $e');
    } finally {
      _isInitialized = false;
    }
  }

  /// Reset all services (useful for testing).
  ///
  /// This disposes current services and allows re-initialization.
  static Future<void> reset() async {
    await dispose();
    Get.reset();
  }

  /// Factory method for creating configured instances.
  ///
  /// Useful for creating instances with specific configurations.
  static T factory<T>(T Function() factory) => factory();

  /// Register a lazy singleton that will be created on first access.
  static void registerLazySingleton<T>(T Function() factory) {
    Get.put<T>(factory(), permanent: true);
  }

  /// Register a factory that creates new instances on each access.
  static void registerFactory<T>(T Function() factory) {
    Get.lazyPut<T>(() => factory());
  }

  /// Get configuration for the current environment.
  static Map<String, dynamic> getEnvironmentConfig() {
    switch (_currentEnvironment) {
      case AppEnvironment.development:
        return {
          'enableLogging': true,
          'enablePerformanceMonitoring': true,
          'cacheMaxSize': 50 * 1024 * 1024, // 50MB
          'networkTimeout': 30000, // 30 seconds
          'retryAttempts': 3,
        };
      case AppEnvironment.testing:
        return {
          'enableLogging': false,
          'enablePerformanceMonitoring': false,
          'cacheMaxSize': 10 * 1024 * 1024, // 10MB
          'networkTimeout': 5000, // 5 seconds
          'retryAttempts': 1,
        };
      case AppEnvironment.production:
        return {
          'enableLogging': false,
          'enablePerformanceMonitoring': true,
          'cacheMaxSize': 100 * 1024 * 1024, // 100MB
          'networkTimeout': 60000, // 60 seconds
          'retryAttempts': 5,
        };
    }
  }
}

/// Exception thrown by ServiceLocator operations.
class ServiceLocatorException implements Exception {
  const ServiceLocatorException(this.message, this.errorCode, [this.cause]);
  final String message;
  final String errorCode;
  final dynamic cause;

  @override
  String toString() => 'ServiceLocatorException: $message (Code: $errorCode)';
}
