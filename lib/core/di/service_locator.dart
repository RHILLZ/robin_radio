import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../data/repositories/repositories.dart';
import '../../data/services/audio/audio_services.dart';
import '../environment/app_environment.dart';

/// Centralized service locator using GetX for dependency injection.
///
/// Provides dependency management for the Robin Radio application with
/// support for multiple environments and testing configurations.
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

    // Register core services
    await _registerCoreServices(forTesting: forTesting);

    // Register repositories
    await _registerRepositories(forTesting: forTesting);

    _isInitialized = true;
  }

  /// Register core foundational services.
  static Future<void> _registerCoreServices({required bool forTesting}) async {
    // Audio Service - media playback management
    if (forTesting) {
      Get.put<IAudioService>(
        MockAudioService(),
        permanent: true,
      );
    } else {
      Get.put<IAudioService>(
        BackgroundAudioService(),
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
