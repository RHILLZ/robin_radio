import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:json_theme/json_theme.dart';
import 'data/services/audio_player_service.dart';
import 'data/services/performance_service.dart';
import 'firebase_options.dart';
import 'modules/app/app_view.dart';
import 'routes/views.dart';
import 'package:sizer/sizer.dart';

import 'modules/app/main_bindings.dart';

/// Application entry point that initializes all core services and dependencies.
///
/// Handles Firebase initialization, performance monitoring setup, audio configuration,
/// theme loading, and dependency injection before launching the main application.
/// Includes comprehensive error handling for initialization failures.
void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Load and decode theme
    final themeStr = await rootBundle.loadString('assets/appainter_theme.json');
    final themeJson = jsonDecode(themeStr);
    final theme = ThemeDecoder.decodeThemeData(themeJson, validate: false) ??
        ThemeData.light(); // Fallback theme

    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).catchError((Object error) {
      debugPrint('Failed to initialize Firebase: $error');
      // Return the result of a new initialization attempt with default options
      return Firebase.app();
    });

    // Start app startup performance trace
    final performanceService = PerformanceService();
    await performanceService.startAppStartTrace();

    // Initialize Performance Monitoring
    await performanceService.initialize();

    // Initialize centralized AudioPlayerService
    final audioPlayerService = AudioPlayerService();
    await audioPlayerService.initialize();

    // Configure audio context
    final audioContext = AudioContext(
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playAndRecord,
        options: const {
          AVAudioSessionOptions.defaultToSpeaker,
          AVAudioSessionOptions.allowBluetoothA2DP,
          AVAudioSessionOptions.allowAirPlay,
        },
      ),
      android: const AudioContextAndroid(
        isSpeakerphoneOn: true,
        stayAwake: true,
        contentType: AndroidContentType.sonification,
        usageType: AndroidUsageType.assistanceSonification,
        audioFocus: AndroidAudioFocus.none,
      ),
    );
    AudioPlayer.global.setAudioContext(audioContext);

    // Initialize dependencies
    MainBindings().dependencies();

    // Stop app startup trace before running the app
    await performanceService.stopAppStartTrace();

    runApp(MyApp(theme: theme));
  } catch (e, stackTrace) {
    debugPrint('Error during initialization: $e\n$stackTrace');
    // You might want to show a user-friendly error screen here
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Failed to initialize app: $e'),
          ),
        ),
      ),
    );
  }
}

/// Main application widget that configures the app theme, routing, and global settings.
///
/// Provides a GetMaterialApp with custom theming loaded from JSON configuration,
/// responsive design support via Sizer, and centralized navigation management.
/// Includes text scaling prevention and smooth page transitions.
class MyApp extends StatelessWidget {
  /// Creates the main application widget.
  ///
  /// [theme] The ThemeData loaded from the app's theme configuration file.
  const MyApp({required ThemeData theme, super.key}) : _theme = theme;

  /// The application theme loaded from the JSON theme configuration.
  final ThemeData _theme;

  @override
  Widget build(BuildContext context) => Sizer(
        builder: (context, orientation, deviceType) => GetMaterialApp(
          title: 'Robin Radio',
          debugShowCheckedModeBanner: false,
          getPages: Views.routes,
          theme: _theme,
          initialRoute: Routes.appViewRoute,
          defaultTransition: Transition.fade, // Smooth transitions
          builder: (context, child) {
            // Prevent text scaling
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                platformBrightness: Theme.of(context).brightness,
                textScaler: const TextScaler.linear(1),
              ),
              child: child ?? const SizedBox(),
            );
          },
          home: const AppView(),
        ),
      );
}
