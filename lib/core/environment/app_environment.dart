/// App environment configurations for different deployment contexts.
///
/// Supports different configurations for:
/// - Development: Local development with debug features
/// - Testing: Unit and integration testing environment
/// - Production: Live app deployment
enum AppEnvironment {
  /// Development environment with debug features enabled
  development,

  /// Testing environment with mocked services
  testing,

  /// Production environment with optimized settings
  production,
}

/// Extension for AppEnvironment to provide utility methods.
extension AppEnvironmentExtension on AppEnvironment {
  /// Get a human-readable name for the environment.
  String get name {
    switch (this) {
      case AppEnvironment.development:
        return 'Development';
      case AppEnvironment.testing:
        return 'Testing';
      case AppEnvironment.production:
        return 'Production';
    }
  }

  /// Check if this is a debug environment.
  bool get isDebug =>
      this == AppEnvironment.development || this == AppEnvironment.testing;

  /// Check if this is the production environment.
  bool get isProduction => this == AppEnvironment.production;

  /// Get the configuration suffix for this environment.
  String get configSuffix {
    switch (this) {
      case AppEnvironment.development:
        return 'dev';
      case AppEnvironment.testing:
        return 'test';
      case AppEnvironment.production:
        return 'prod';
    }
  }
}
