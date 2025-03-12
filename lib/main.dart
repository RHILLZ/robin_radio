import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:json_theme/json_theme.dart';
import 'package:robin_radio/firebase_options.dart';
import 'package:robin_radio/modules/app/app_view.dart';
import 'package:robin_radio/routes/views.dart';
import 'package:sizer/sizer.dart';

import 'modules/app/main_bindings.dart';

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
    ).catchError((error) {
      debugPrint('Failed to initialize Firebase: $error');
      // Return the result of a new initialization attempt with default options
      return Firebase.app();
    });

    // Configure audio context
    final AudioContext audioContext = AudioContext(
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playAndRecord,
        options: {
          AVAudioSessionOptions.defaultToSpeaker,
          AVAudioSessionOptions.allowBluetoothA2DP,
          AVAudioSessionOptions.allowAirPlay
        },
      ),
      android: AudioContextAndroid(
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

    runApp(MyApp(theme: theme));
  } catch (e, stackTrace) {
    debugPrint('Error during initialization: $e\n$stackTrace');
    // You might want to show a user-friendly error screen here
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Failed to initialize app: $e'),
        ),
      ),
    ));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required ThemeData theme}) : _theme = theme;

  final ThemeData _theme;

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return GetMaterialApp(
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
                textScaler: TextScaler.linear(1.0),
              ),
              child: child ?? const SizedBox(),
            );
          },
          home: const AppView(),
        );
      },
    );
  }
}
