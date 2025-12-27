import 'package:flutter/foundation.dart' show kIsWeb;

import 'audio_service_interface.dart';
import 'background_audio_service.dart';
import 'web_audio_service.dart';

/// Factory for creating platform-appropriate audio service instances.
///
/// This factory automatically selects the correct audio service implementation
/// based on the target platform:
///
/// - **Web**: Uses [WebAudioService] which provides direct just_audio playback
///   without system-level media controls (not supported on web).
///
/// - **Mobile/Desktop**: Uses [BackgroundAudioService] which provides full
///   audio_service integration with system media notifications, lock screen
///   controls, and background playback capabilities.
///
/// ## Usage
///
/// ```dart
/// // Get the appropriate service for current platform
/// final audioService = AudioServiceFactory.create();
///
/// // Initialize and use
/// await audioService.initialize();
/// await audioService.play(song);
/// ```
///
/// ## Platform Differences
///
/// | Feature | Mobile/Desktop | Web |
/// |---------|----------------|-----|
/// | Background playback | Yes | Tab must stay open |
/// | System notifications | Yes | No |
/// | Lock screen controls | Yes | No |
/// | Media button handling | Yes | Limited |
/// | Volume control | Yes | Yes |
/// | Seek/Skip | Yes | Yes |
abstract class AudioServiceFactory {
  AudioServiceFactory._();

  /// Create the appropriate audio service for the current platform.
  ///
  /// Returns [WebAudioService] on web platforms, [BackgroundAudioService]
  /// on mobile and desktop platforms.
  static IAudioService create() {
    if (kIsWeb) {
      return WebAudioService();
    } else {
      return BackgroundAudioService();
    }
  }

  /// Check if the current platform supports full background audio features.
  ///
  /// Returns true on mobile/desktop platforms that support:
  /// - System media notifications
  /// - Lock screen controls
  /// - True background playback
  ///
  /// Returns false on web where these features are not available.
  static bool get supportsBackgroundAudio => !kIsWeb;

  /// Check if the current platform supports system media notifications.
  ///
  /// Returns true on mobile/desktop, false on web.
  static bool get supportsMediaNotifications => !kIsWeb;

  /// Check if the current platform supports lock screen controls.
  ///
  /// Returns true on mobile/desktop, false on web.
  static bool get supportsLockScreenControls => !kIsWeb;

  /// Check if running on web platform.
  static bool get isWeb => kIsWeb;
}
