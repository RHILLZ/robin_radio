import 'package:get/get.dart';

import '../player/player_controller.dart';
import 'app_controller.dart';

/// Main dependency injection bindings for the application.
///
/// Implements GetX Bindings interface to register and configure all core
/// controllers and services when the app starts. This ensures proper
/// dependency injection and lifecycle management throughout the application.
class MainBindings implements Bindings {
  /// Initializes all application dependencies and services.
  ///
  /// Called by GetX when the app starts or when navigating to routes
  /// that require these bindings. Sets up controllers and services
  /// in the proper order to ensure dependencies are available.
  @override
  void dependencies() {
    _injectDependencies();
    _injectServices();
  }

  /// Registers core application controllers with GetX dependency injection.
  ///
  /// Creates and puts singleton instances of essential controllers that
  /// manage global app state and functionality.
  void _injectDependencies() {
    Get
      ..put<AppController>(AppController())
      ..put<PlayerController>(PlayerController());
  }

  /// Registers additional services with GetX dependency injection.
  ///
  /// Services are already initialized by ServiceLocator in main.dart,
  /// this method ensures they are properly accessible via GetX.
  void _injectServices() {
    // Services are managed by ServiceLocator - no manual registration needed
    // GetX will resolve services through ServiceLocator when requested
  }
}
