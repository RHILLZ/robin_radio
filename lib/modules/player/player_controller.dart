import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:robin_radio/data/models/song.dart';
import 'package:robin_radio/modules/app/app_controller.dart';
import 'dart:math';

enum Mode { radio, album }

class PlayerController extends GetxController {
  final player = AudioPlayer();
  final music = Get.find<AppController>().robinsMusic;
  final _playerState = ''.obs;
  final _playerDuration = const Duration().obs;
  final _playerPosition = const Duration().obs;
  final _song = Song(songName: '', songUrl: '', artist: '').obs;
  final _tracks = [].obs;
  final Rx<int> _trackIndex = 0.obs;
  String? _coverURL;
  final _currentRadioSong = Song(songName: '', songUrl: '', artist: '').obs;
  Mode mode = Mode.radio;

  set song(value) => _song.value = value;
  set coverURL(value) => _coverURL = value;
  set tracks(value) => _tracks.value = value;
  set trackIndex(value) => _trackIndex.value = value;

  get currentRadioSong => _currentRadioSong.value;
  get song => _song.value;
  get trackIndex => _trackIndex.value;
  get tracks => _tracks;
  get coverURL => _coverURL;
  get playerState => _playerState.value;
  get playerDuration => formatDuration(_playerDuration.value);
  get playerPosition => formatDuration(_playerPosition.value);
  get durationAsDouble => _playerDuration.value.inSeconds.toDouble();
  get positionAsDouble => _playerPosition.value.inSeconds.toDouble();

  @override
  void onReady() {
    super.onReady();
    player.onDurationChanged
        .listen((Duration dur) => _playerDuration.value = dur);
    player.onPositionChanged
        .listen((Duration pos) => _playerPosition.value = pos);
    player.onPlayerStateChanged
        .listen((PlayerState state) => _playerState.value = state.toString());
    player.onPlayerComplete.listen((event) async {
      if (mode == Mode.radio) {
        await playRadio();
        return;
      }
      _trackIndex.value = _trackIndex.value + 1;
      if (trackIndex > _tracks.length - 1) {
        Get.back();
        closePlayer();
        return;
      }
      playTrack();
    });
  }

  double linearProgressValue() {
    if (durationAsDouble == 0.0) {
      return positionAsDouble / 0.1;
    }

    return positionAsDouble / durationAsDouble;
  }

  String formatDuration(Duration dur) {
    String minutes = dur.inMinutes.remainder(60).toString().padLeft(2, '0');
    String seconds = dur.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  play() async {
    if (mode == Mode.radio) {
      await playRadio();
    }

    if (mode == Mode.album) {
      await playTrack();
    }
  }

  playRadio() async {
    mode = Mode.radio;
    final tracks = music[Random().nextInt(music.length)].tracks;
    final url = UrlSource(tracks[Random().nextInt(tracks.length)].songUrl);
    _currentRadioSong.value = tracks[Random().nextInt(tracks.length)];
    await player.play(url);
  }

  playTrack() async {
    mode = Mode.album;
    final url = UrlSource(_tracks[trackIndex].songUrl);
    await player.play(url);
    if (kDebugMode) {
      print('TRACK INDEX: $trackIndex');
    }
    if (kDebugMode) {
      print('TRACKS LENGTH: ${tracks.length}');
    }
  }

  next() async {
    if (mode == Mode.radio) {
      await playRadio();
      return;
    }
    _trackIndex.value = _trackIndex.value + 1;
    if (trackIndex > _tracks.length - 1) {
      Get.back();
      await closePlayer();
      return;
    }
    await playTrack();
  }

  previous() async {
    _trackIndex.value = _trackIndex.value - 1;
    if (trackIndex < 0) return;
    await playTrack();
  }

  pause() async {
    await player.pause();
  }

  resume() async {
    await player.resume();
  }

  stop() async {
    await player.stop();
  }

  seek(double val) async {
    await player.seek(Duration(seconds: val.toInt()));
  }

  closePlayer() async {
    await player.release();
    _tracks.value = [];
    _trackIndex.value = 0;
    _song.value = Song(songName: '', songUrl: '', artist: '');
    _currentRadioSong.value = Song(songName: '', songUrl: '', artist: '');
  }

  IconButton playerIcon(double size, Color? color) {
    IconButton icon = IconButton(
        onPressed: () => playTrack(),
        iconSize: size,
        icon: Icon(
          Icons.play_arrow,
          color: color ?? Colors.white,
        ));
    if (_playerState.value == 'PlayerState.playing') {
      icon = IconButton(
          onPressed: () => pause(),
          iconSize: size,
          icon: Icon(
            Icons.pause,
            color: color ?? Colors.white,
          ));
    }
    if (_playerState.value == 'PlayerState.paused') {
      icon = IconButton(
          onPressed: () => resume(),
          iconSize: size,
          icon: Icon(
            Icons.play_arrow,
            color: color ?? Colors.white,
          ));
    }

    return icon;
  }
}
