import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../data/repositories/repositories.dart';
import '../../data/services/audio/audio_services.dart';
import '../../data/services/performance_service.dart';
import '../environment/app_environment.dart';

/// Centralized service locator using GetX for dependency injection.
///
/// Provides dependency management for the Robin Radio application with
/// support for multiple environments and testing configurations.
///
/// ## Initialization Strategy
///
/// Services are categorized into critical and non-critical:
///
/// **Critical Services** (eagerly initialized):
/// - Audio Service: Required immediately for playback functionality
/// - Music Repository: Required for loading initial content
///
/// **Non-Critical Services** (lazily initialized):
/// - Performance Service: Can be initialized after app launch
///
/// This optimization reduces app startup time by deferring non-essential
/// service initialization until first use.
///
/// ## Usage
///
/// ```dart
/// // Initialize in main()
/// await ServiceLocator.initialize();
///
/// // Access services
/// final audioService = ServiceLocator.get<IAudioService>();
/// final musicRepo = ServiceLocator.get<MusicRepository>();
/// ```
class ServiceLocator {
  ServiceLocator._();
  static bool _isInitialized = false;
  static AppEnvironment _currentEnvironment = AppEnvironment.development;

  /// Initialize all services and repositories.
  ///
  /// Critical services are eagerly initialized for immediate availability.
  /// Non-critical services use lazy initialization for faster startup.
  ///
  /// [environment] The target application environment.
  /// [forTesting] Whether to use mock implementations.
  static Future<void> initialize({
    AppEnvironment environment = AppEnvironment.development,
    bool forTesting = false,
  }) async {
    if (_isInitialized) {
      return;
    }

    _currentEnvironment = environment;

    // Register non-critical services with lazy initialization
    _registerLazyServices(forTesting: forTesting);

    // Register critical services (eagerly initialized)
    await _registerCriticalServices(forTesting: forTesting);

    // Register repositories
    await _registerRepositories(forTesting: forTesting);

    _isInitialized = true;
  }

  /// Register non-critical services with lazy initialization.
  ///
  /// These services are deferred until first access to reduce startup time.
  /// Uses Get.lazyPut() which only creates the instance when first requested.
  static void _registerLazyServices({required bool forTesting}) {
    if (!forTesting) {
      // Performance Service - Firebase Performance monitoring
      // Lazily initialized since it's not required for initial app functionality
      Get.lazyPut<PerformanceService>(
        PerformanceService.new,
        fenix: true, // Recreate if disposed and accessed again
      );
    }
  }

  /// Register critical services that must be available immediately.
  ///
  /// These services are eagerly initialized because they are required
  /// for core app functionality at startup.
  static Future<void> _registerCriticalServices({
    required bool forTesting,
  }) async {
    // Audio Service - media playback management (critical for music app)
    // Uses factory to select platform-appropriate implementation
    if (forTesting) {
      Get.put<IAudioService>(
        MockAudioService(),
        permanent: true,
      );
    } else {
      // Factory automatically selects:
      // - WebAudioService for web (no system media controls)
      // - BackgroundAudioService for mobile/desktop (full media integration)
      Get.put<IAudioService>(
        AudioServiceFactory.create(),
        permanent: true,
      );
    }
  }

  /// Register repository layer services.
  static Future<void> _registerRepositories({required bool forTesting}) async {
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

  /// Get a service instance by type.
  ///
  /// Throws [ServiceLocatorException] if not initialized or service not found.
  static T get<T>() {
    if (!_isInitialized) {
      throw const ServiceLocatorException(
        'ServiceLocator not initialized. Call ServiceLocator.initialize() first.',
        'SERVICE_LOCATOR_NOT_INITIALIZED',
      );
    }

    try {
      return Get.find<T>();
    } on Exception catch (e) {
      throw ServiceLocatorException(
        "Service of type $T not found. Make sure it's registered.",
        'SERVICE_NOT_FOUND',
        e,
      );
    }
  }

  /// Override a service for testing purposes.
  static void override<T>(T service, {bool permanent = false}) {
    if (Get.isRegistered<T>()) {
      Get.delete<T>();
    }
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

  /// Check if the service locator has been initialized.
  static bool get isInitialized => _isInitialized;

  /// Reset and dispose all services.
  static Future<void> dispose() async {
    if (!_isInitialized) {
      return;
    }

    try {
      // Dispose audio service
      if (Get.isRegistered<IAudioService>()) {
        final audioService = Get.find<IAudioService>();
        await audioService.dispose();
        await Get.delete<IAudioService>();
      }

      // Dispose repositories
      if (Get.isRegistered<MusicRepository>()) {
        await Get.delete<MusicRepository>();
      }

      // Dispose performance service
      if (Get.isRegistered<PerformanceService>()) {
        await Get.delete<PerformanceService>();
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        debugPrint('Error during ServiceLocator disposal: $e');
      }
    } finally {
      _isInitialized = false;
    }
  }

  /// Reset all services (useful for testing).
  static Future<void> reset() async {
    await dispose();
    Get.reset();
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
