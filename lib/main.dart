import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:json_theme/json_theme.dart';
import 'package:robin_radio/modules/app/app_view.dart';
import 'package:robin_radio/routes/views.dart';
import 'package:sizer/sizer.dart';

import 'modules/app/main_bindings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final themeStr = await rootBundle.loadString('assets/appainter_theme.json');
  final themeJson = jsonDecode(themeStr);
  final theme = ThemeDecoder.decodeThemeData(themeJson)!;
  await Firebase.initializeApp();
  final AudioContext audioContext = AudioContext(
    iOS: AudioContextIOS(
      defaultToSpeaker: true,
      category: AVAudioSessionCategory.ambient,
      options: [
        AVAudioSessionOptions.defaultToSpeaker,
        AVAudioSessionOptions.mixWithOthers,
        AVAudioSessionOptions.allowBluetooth,
        AVAudioSessionOptions.allowBluetoothA2DP,
        AVAudioSessionOptions.allowAirPlay
      ],
    ),
    android: AudioContextAndroid(
      isSpeakerphoneOn: true,
      stayAwake: true,
      contentType: AndroidContentType.sonification,
      usageType: AndroidUsageType.assistanceSonification,
      audioFocus: AndroidAudioFocus.none,
    ),
  );
  AudioPlayer.global.setGlobalAudioContext(audioContext);
  MainBindings().dependencies();
  runApp(MyApp(
    theme: theme,
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required ThemeData theme}) : _theme = theme;

  // This widget is the root of your application.
  final ThemeData _theme;
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
        title: 'Robin Radio',
        debugShowCheckedModeBanner: false,
        getPages: Views.routes,
        theme: _theme,
        initialRoute: Routes.appViewRoute,
        builder: (context, _) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
            child: Sizer(
                builder: (BuildContext contextxx, Orientation orientation,
                        DeviceType deviceType) =>
                    const AppView())));
  }
}
