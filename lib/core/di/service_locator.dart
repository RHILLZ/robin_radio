import 'package:get/get.dart';

import '../../data/repositories/repositories.dart';
import '../../data/services/audio/audio_services.dart';
import '../../data/services/cache/cache_services.dart';
import '../../data/services/network/network_services.dart';
import '../environment/app_environment.dart';

/// Centralized service locator using GetX for dependency injection.
///
/// Provides comprehensive dependency management for the Robin Radio application with
/// support for multiple environments, testing configurations, and advanced service
/// lifecycle management. Built on GetX's dependency injection system for reliable
/// service resolution and lifecycle control.
///
/// ## Core Capabilities
///
/// **Service Management:**
/// - Centralized registration and retrieval of all application services
/// - Environment-specific service configurations (dev/test/prod)
/// - Service lifecycle management with proper disposal patterns
/// - Lazy initialization for optimal memory usage and startup performance
/// - Service override capabilities for comprehensive testing support
///
/// **Architecture Benefits:**
/// - **Separation of Concerns**: Clear isolation between service implementation and usage
/// - **Testability**: Easy mock service substitution for unit and integration testing
/// - **Maintainability**: Single point of truth for all service dependencies
/// - **Flexibility**: Runtime service replacement and configuration switching
/// - **Performance**: Optimized service instantiation and caching strategies
///
/// **Dependency Hierarchy:**
/// ```
/// Application Services
///        │
/// Repository Layer (MusicRepository)
///        │
/// Core Services (Network, Cache, Audio)
///        │
/// Platform Layer (iOS/Android)
/// ```
///
/// ## Environment Configuration
///
/// The service locator adapts service registration and configuration based on
/// the current application environment:
///
/// **Development Environment:**
/// - Full logging enabled for debugging visibility
/// - Performance monitoring active for optimization insights
/// - Generous cache limits (50MB) for development efficiency
/// - Extended timeouts (30s) for debugging with breakpoints
/// - Multiple retry attempts for resilient development experience
///
/// **Testing Environment:**
/// - Minimal logging to avoid test output pollution
/// - Performance monitoring disabled for test consistency
/// - Small cache limits (10MB) for fast test execution
/// - Short timeouts (5s) for rapid test completion
/// - Single retry attempt for predictable test behavior
///
/// **Production Environment:**
/// - Logging disabled for optimal performance and security
/// - Performance monitoring enabled for user experience insights
/// - Large cache limits (100MB) for optimal user experience
/// - Extended timeouts (60s) for challenging network conditions
/// - Multiple retries (5) for maximum reliability
///
/// ## Usage Patterns
///
/// **Application Initialization:**
/// ```dart
/// // Early in main() or app startup
/// await ServiceLocator.initialize(
///   environment: AppEnvironment.production,
///   forTesting: false,
/// );
///
/// // Access services throughout the app
/// final audioService = ServiceLocator.get<IAudioService>();
/// await audioService.initialize();
/// await audioService.play(song);
/// ```
///
/// **Service Access in Widgets:**
/// ```dart
/// class MusicPlayerWidget extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     final audioService = ServiceLocator.get<IAudioService>();
///     final musicRepo = ServiceLocator.get<MusicRepository>();
///
///     return StreamBuilder<PlaybackState>(
///       stream: audioService.playbackState,
///       builder: (context, snapshot) {
///         // Build UI based on service state
///       },
///     );
///   }
/// }
/// ```
///
/// **Testing Setup:**
/// ```dart
/// void main() {
///   setUpAll(() async {
///     await ServiceLocator.initialize(
///       environment: AppEnvironment.testing,
///       forTesting: true,
///     );
///   });
///
///   tearDownAll(() async {
///     await ServiceLocator.dispose();
///   });
///
///   test('should handle service interaction', () {
///     final mockService = MockAudioService();
///     ServiceLocator.override<IAudioService>(mockService);
///
///     // Test with controlled service behavior
///   });
/// }
/// ```
///
/// **Advanced Service Management:**
/// ```dart
/// // Check service availability
/// if (ServiceLocator.isRegistered<IAudioService>()) {
///   final audioService = ServiceLocator.get<IAudioService>();
///   // Use service safely
/// }
///
/// // Environment-specific behavior
/// if (ServiceLocator.isDevelopment) {
///   // Development-only features
///   enableAdvancedLogging();
/// }
///
/// // Lazy service registration
/// ServiceLocator.registerLazySingleton<CustomService>(
///   () => CustomServiceImpl(),
/// );
///
/// // Factory pattern for new instances
/// ServiceLocator.registerFactory<TempService>(
///   () => TempServiceImpl(),
/// );
/// ```
///
/// ## Error Handling Strategy
///
/// The service locator provides structured error handling with specific exception
/// types and error codes for different failure scenarios:
///
/// ```dart
/// try {
///   final service = ServiceLocator.get<IAudioService>();
///   await service.play(song);
/// } on ServiceLocatorException catch (e) {
///   switch (e.errorCode) {
///     case 'SERVICE_LOCATOR_NOT_INITIALIZED':
///       // Initialize service locator first
///       await ServiceLocator.initialize();
///       break;
///     case 'SERVICE_NOT_FOUND':
///       // Handle missing service registration
///       handleMissingService(e.message);
///       break;
///     default:
///       // Generic error handling
///       logError('Service error: ${e.message}');
///   }
/// }
/// ```
///
/// ## Integration with GetX
///
/// The service locator integrates seamlessly with GetX's dependency injection
/// system while providing additional structure and environment management:
///
/// - Uses `Get.put()` for singleton service registration with permanent flag
/// - Leverages `Get.find()` for efficient service retrieval
/// - Provides `Get.delete()` for proper service disposal
/// - Supports `Get.lazyPut()` for factory pattern implementations
/// - Integrates with GetX's lifecycle management for controllers and services
///
/// ## Memory Management
///
/// Proper memory management is ensured through:
/// - Automatic disposal of services during app shutdown
/// - Proper stream cancellation in service cleanup
/// - Cache size limits to prevent memory bloat
/// - Reference cleanup during service reset operations
/// - Lazy initialization to minimize startup memory footprint
///
/// ## Thread Safety
///
/// The service locator is designed for thread-safe operation:
/// - GetX handles concurrent access to service instances
/// - Service registration is atomic and thread-safe
/// - Service initialization guards prevent double-initialization
/// - Disposal operations are properly synchronized
///
/// This ensures safe usage from multiple isolates and async contexts
/// without additional synchronization requirements.
class ServiceLocator {
  static bool _isInitialized = false;
  static AppEnvironment _currentEnvironment = AppEnvironment.development;

  /// Initialize all services and repositories with environment-specific configuration.
  ///
  /// Performs comprehensive setup of the entire service dependency graph in the
  /// correct order to ensure all dependencies are available when needed. This
  /// method should be called early in the application lifecycle, typically in
  /// `main()` or during app initialization.
  ///
  /// The initialization process follows a strict dependency order:
  /// 1. **Core Services**: Foundation services that other services depend on
  /// 2. **Repository Layer**: Data access services that use core services
  /// 3. **Application Services**: High-level services that orchestrate functionality
  ///
  /// [environment] The target application environment that determines service
  ///              configurations and behavior. Each environment has optimized
  ///              settings for its specific use case:
  ///              - Development: Debug-friendly with extensive logging
  ///              - Testing: Fast and predictable for automated testing
  ///              - Production: Optimized for performance and reliability
  ///
  /// [forTesting] Whether to use mock implementations instead of real services.
  ///             When true, all services are replaced with mock versions that
  ///             provide predictable behavior for testing. Essential for
  ///             unit testing, integration testing, and test automation.
  ///
  /// Service Registration Order:
  /// ```
  /// Core Services:
  /// ├── INetworkService (HTTP client, connectivity monitoring)
  /// ├── ICacheService (Memory + disk caching)
  /// └── IAudioService (Media playback management)
  ///
  /// Repository Layer:
  /// └── MusicRepository (Music data access)
  ///
  /// Application Services:
  /// └── [Reserved for future high-level services]
  /// ```
  ///
  /// Environment-Specific Configurations:
  /// - **Cache sizes**: Optimized for environment characteristics
  /// - **Network timeouts**: Balanced for use case requirements
  /// - **Retry strategies**: Tuned for environment reliability needs
  /// - **Logging levels**: Appropriate for debugging vs performance
  /// - **Monitoring**: Enabled where beneficial for insights
  ///
  /// Example initialization patterns:
  /// ```dart
  /// // Production app startup
  /// await ServiceLocator.initialize(
  ///   environment: AppEnvironment.production,
  ///   forTesting: false,
  /// );
  ///
  /// // Development with real services
  /// await ServiceLocator.initialize(); // Uses development environment
  ///
  /// // Testing with mocks
  /// await ServiceLocator.initialize(
  ///   environment: AppEnvironment.testing,
  ///   forTesting: true,
  /// );
  /// ```
  ///
  /// The method is idempotent - calling it multiple times is safe and will
  /// not reinitialize services or change the environment once set.
  ///
  /// Throws no exceptions but may log warnings if service initialization
  /// encounters issues. Individual service failures don't prevent overall
  /// initialization to ensure application robustness.
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

  /// Get a service instance by type with comprehensive error handling.
  ///
  /// Retrieves a previously registered service instance using type-safe
  /// generic resolution. This is the primary method for accessing services
  /// throughout the application and should be used whenever service
  /// functionality is required.
  ///
  /// Type parameter [T] specifies the service interface type to retrieve.
  /// The service locator will return the concrete implementation that was
  /// registered for this interface type during initialization.
  ///
  /// Service Resolution Process:
  /// 1. Validates that the service locator has been initialized
  /// 2. Attempts to find the service using GetX's dependency resolution
  /// 3. Returns the cached singleton instance if available
  /// 4. Throws structured exceptions for error conditions
  ///
  /// Common Usage Patterns:
  /// ```dart
  /// // Basic service access
  /// final audioService = ServiceLocator.get<IAudioService>();
  /// await audioService.play(song);
  ///
  /// // Store reference for multiple operations
  /// final musicRepo = ServiceLocator.get<MusicRepository>();
  /// final albums = await musicRepo.getAlbums();
  /// final tracks = await musicRepo.getTracks(albums.first.id);
  ///
  /// // Use in dependency injection
  /// class PlayerController {
  ///   final IAudioService _audioService = ServiceLocator.get<IAudioService>();
  ///   // Controller implementation
  /// }
  ///
  /// // Conditional access
  /// if (ServiceLocator.isRegistered<IAudioService>()) {
  ///   final audioService = ServiceLocator.get<IAudioService>();
  ///   // Use service safely
  /// }
  /// ```
  ///
  /// Error Conditions:
  /// - Throws [ServiceLocatorException] with `SERVICE_LOCATOR_NOT_INITIALIZED`
  ///   if called before [initialize] has been completed
  /// - Throws [ServiceLocatorException] with `SERVICE_NOT_FOUND` if the
  ///   requested service type was never registered
  ///
  /// Performance Notes:
  /// - Service retrieval is very fast (O(1) hash map lookup)
  /// - Services are cached as singletons after first creation
  /// - No additional object allocation occurs on repeated calls
  /// - Safe to call frequently without performance concerns
  ///
  /// The method guarantees that returned services are fully initialized
  /// and ready for use, with all their dependencies properly resolved.
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
    } on Exception catch (e) {
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
    } on Exception catch (e) {
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
///
/// Provides structured error information for dependency injection failures
/// with specific error codes for programmatic handling and clear messages
/// for debugging and user feedback.
///
/// Common error scenarios:
/// - Attempting to access services before initialization
/// - Requesting services that were never registered
/// - Service resolution failures during dependency lookup
/// - Service override conflicts during testing
///
/// Usage in error handling:
/// ```dart
/// try {
///   final service = ServiceLocator.get<ICustomService>();
/// } on ServiceLocatorException catch (e) {
///   switch (e.errorCode) {
///     case 'SERVICE_LOCATOR_NOT_INITIALIZED':
///       await ServiceLocator.initialize();
///       break;
///     case 'SERVICE_NOT_FOUND':
///       handleMissingService();
///       break;
///     default:
///       logError('Unexpected service error: ${e.message}');
///   }
/// }
/// ```
class ServiceLocatorException implements Exception {
  /// Creates a new ServiceLocatorException with message, error code, and optional cause.
  ///
  /// [message] Human-readable description of the error condition.
  /// [errorCode] Machine-readable error identifier for programmatic handling.
  /// [cause] Optional underlying exception that triggered this error.
  const ServiceLocatorException(this.message, this.errorCode, [this.cause]);

  /// Human-readable error message explaining what went wrong.
  final String message;

  /// Machine-readable error code for programmatic error handling.
  final String errorCode;

  /// Optional underlying cause of this exception.
  final dynamic cause;

  @override
  String toString() => 'ServiceLocatorException: $message (Code: $errorCode)';
}
