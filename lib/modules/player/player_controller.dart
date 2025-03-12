import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:robin_radio/data/models/song.dart';
import 'package:robin_radio/data/models/album.dart';
import 'package:robin_radio/modules/app/app_controller.dart';
import 'dart:math';

enum PlayerMode { radio, album }

enum PlayerRepeatMode { none, all, one }

enum PlayerShuffleMode { off, on }

class PlayerController extends GetxController {
  // Core player components
  final player = AudioPlayer();
  final appController = Get.find<AppController>();

  // Observable state variables
  final _playerState = PlayerState.stopped.obs;
  final _playerDuration = const Duration().obs;
  final _playerPosition = const Duration().obs;
  final _currentSong = Rx<Song?>(null);
  final _currentAlbum = Rx<Album?>(null);
  final _tracks = <Song>[].obs;
  final _trackIndex = 0.obs;
  final _isBuffering = false.obs;
  final _volume = 1.0.obs;
  final _repeatMode = PlayerRepeatMode.none.obs;
  final _shuffleMode = PlayerShuffleMode.off.obs;

  // Player mode and UI state
  final _playerMode = PlayerMode.radio.obs;
  final _coverURL = Rx<String?>(null);
  final _currentRadioSong = Rx<Song?>(null);
  final _playbackError = Rx<String?>(null);
  final _hidePlayerInRadioView = false.obs;

  // Queue management
  final _originalQueue = <Song>[].obs;
  final _shuffledQueue = <Song>[].obs;

  // Getters
  Song? get currentSong => _currentSong.value;
  Album? get currentAlbum => _currentAlbum.value;
  List<Song> get tracks => _tracks;
  int get trackIndex => _trackIndex.value;
  String? get coverURL => _coverURL.value;
  PlayerState get playerState => _playerState.value;
  String get playerStateString => _playerState.value.toString();
  String get playerDurationFormatted => formatDuration(_playerDuration.value);
  String get playerPositionFormatted => formatDuration(_playerPosition.value);
  Duration get playerDuration => _playerDuration.value;
  Duration get playerPosition => _playerPosition.value;
  double get durationAsDouble => _playerDuration.value.inSeconds.toDouble();
  double get positionAsDouble => _playerPosition.value.inSeconds.toDouble();
  bool get isPlaying => _playerState.value == PlayerState.playing;
  bool get isPaused => _playerState.value == PlayerState.paused;
  bool get isStopped => _playerState.value == PlayerState.stopped;
  bool get isBuffering => _isBuffering.value;
  double get volume => _volume.value;
  PlayerMode get playerMode => _playerMode.value;
  Song? get currentRadioSong => _currentRadioSong.value;
  String? get playbackError => _playbackError.value;
  PlayerRepeatMode get repeatMode => _repeatMode.value;
  PlayerShuffleMode get shuffleMode => _shuffleMode.value;
  bool get isShuffleOn => _shuffleMode.value == PlayerShuffleMode.on;
  bool get isRepeatOne => _repeatMode.value == PlayerRepeatMode.one;
  bool get isRepeatAll => _repeatMode.value == PlayerRepeatMode.all;
  bool get hidePlayerInRadioView => _hidePlayerInRadioView.value;

  // Setters
  set currentSong(Song? value) => _currentSong.value = value;
  set currentAlbum(Album? value) => _currentAlbum.value = value;
  set tracks(List<Song> value) {
    _tracks.value = value;
    _originalQueue.value = List.from(value);
    if (isShuffleOn) {
      _shuffleQueue();
    }
  }

  set trackIndex(int value) => _trackIndex.value = value;
  set coverURL(String? value) => _coverURL.value = value;
  set volume(double value) {
    _volume.value = value;
    player.setVolume(value);
  }

  set playerMode(PlayerMode value) => _playerMode.value = value;
  set hidePlayerInRadioView(bool value) => _hidePlayerInRadioView.value = value;

  @override
  void onInit() {
    super.onInit();
    _initializePlayer();
  }

  void _initializePlayer() {
    // Set up player event listeners
    player.onDurationChanged.listen(_onDurationChanged);
    player.onPositionChanged.listen(_onPositionChanged);
    player.onPlayerStateChanged.listen(_onPlayerStateChanged);
    player.onPlayerComplete.listen(_onPlayerComplete);

    // Set up error handling
    player.onLog.listen((String message) {
      debugPrint('AudioPlayer log: $message');
    });

    // Set initial volume
    player.setVolume(_volume.value);
  }

  void _onDurationChanged(Duration duration) {
    _playerDuration.value = duration;
  }

  void _onPositionChanged(Duration position) {
    _playerPosition.value = position;
  }

  void _onPlayerStateChanged(PlayerState state) {
    _playerState.value = state;
    _isBuffering.value = state == PlayerState.playing &&
        _playerPosition.value.inMilliseconds == 0;
  }

  void _onPlayerComplete(void _) async {
    if (playerMode == PlayerMode.radio) {
      await playRadio();
      return;
    }

    // Handle repeat modes
    if (repeatMode == PlayerRepeatMode.one) {
      await playTrack();
      return;
    }

    // Move to next track
    if (trackIndex < _tracks.length - 1) {
      _trackIndex.value++;
      await playTrack();
    } else if (repeatMode == PlayerRepeatMode.all) {
      _trackIndex.value = 0;
      await playTrack();
    } else {
      // End of playlist
      Get.back();
      await closePlayer();
    }
  }

  double getProgressValue() {
    if (durationAsDouble <= 0.0) {
      return 0.0;
    }
    return positionAsDouble / durationAsDouble;
  }

  String formatDuration(Duration dur) {
    String minutes = dur.inMinutes.remainder(60).toString().padLeft(2, '0');
    String seconds = dur.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  Future<void> play() async {
    if (playerMode == PlayerMode.radio) {
      await playRadio();
    } else if (playerMode == PlayerMode.album) {
      await playTrack();
    }
  }

  Future<void> playRadio() async {
    try {
      _playbackError.value = null;
      playerMode = PlayerMode.radio;
      // Set flag to hide player in radio view
      _hidePlayerInRadioView.value = true;

      // Get a random album from the available albums
      final albums = appController.albums;
      if (albums.isEmpty) {
        _playbackError.value = "No music available for radio mode";
        return;
      }

      final randomAlbum = albums[Random().nextInt(albums.length)];
      if (randomAlbum.tracks.isEmpty) {
        _playbackError.value = "Selected album has no tracks";
        return;
      }

      // Get a random track from the album
      final randomTrack =
          randomAlbum.tracks[Random().nextInt(randomAlbum.tracks.length)];
      _currentRadioSong.value = randomTrack;
      _coverURL.value = randomAlbum.albumCover;

      // Play the track
      final url = UrlSource(randomTrack.songUrl);
      await player.play(url);
    } catch (e) {
      _playbackError.value = "Error playing radio: $e";
      debugPrint("Radio playback error: $e");
    }
  }

  Future<void> playTrack() async {
    try {
      _playbackError.value = null;
      playerMode = PlayerMode.album;

      if (_tracks.isEmpty) {
        _playbackError.value = "No tracks available to play";
        return;
      }

      if (_trackIndex.value < 0 || _trackIndex.value >= _tracks.length) {
        _playbackError.value = "Track index out of bounds";
        return;
      }

      final currentTrack = _tracks[_trackIndex.value];
      _currentSong.value = currentTrack;

      final url = UrlSource(currentTrack.songUrl);
      await player.play(url);

      if (kDebugMode) {
        print('TRACK INDEX: ${_trackIndex.value}');
        print('TRACKS LENGTH: ${_tracks.length}');
      }
    } catch (e) {
      _playbackError.value = "Error playing track: $e";
      debugPrint("Track playback error: $e");
    }
  }

  Future<void> playAlbum(Album album, {int startIndex = 0}) async {
    _currentAlbum.value = album;
    _coverURL.value = album.albumCover;
    tracks = album.tracks;
    _trackIndex.value = startIndex.clamp(0, _tracks.length - 1);
    // Reset flag to show player in album mode
    _hidePlayerInRadioView.value = false;
    await playTrack();
  }

  Future<void> next() async {
    if (playerMode == PlayerMode.radio) {
      await playRadio();
      return;
    }

    if (_trackIndex.value < _tracks.length - 1) {
      _trackIndex.value++;
      await playTrack();
    } else if (repeatMode == PlayerRepeatMode.all) {
      _trackIndex.value = 0;
      await playTrack();
    } else {
      Get.back();
      await closePlayer();
    }
  }

  Future<void> previous() async {
    // If we're more than 3 seconds into the song, restart it instead of going to previous
    if (_playerPosition.value.inSeconds > 3) {
      await seek(0);
      return;
    }

    if (_trackIndex.value > 0) {
      _trackIndex.value--;
      await playTrack();
    } else if (repeatMode == PlayerRepeatMode.all) {
      _trackIndex.value = _tracks.length - 1;
      await playTrack();
    }
  }

  Future<void> pause() async {
    await player.pause();
  }

  Future<void> resume() async {
    await player.resume();
  }

  Future<void> stop() async {
    await player.stop();
  }

  Future<void> seek(double seconds) async {
    await player.seek(Duration(seconds: seconds.toInt()));
  }

  Future<void> closePlayer() async {
    await player.release();
    _tracks.clear();
    _trackIndex.value = 0;
    _currentSong.value = null;
    _currentRadioSong.value = null;
    _currentAlbum.value = null;
    _coverURL.value = null;
  }

  void togglePlayPause() {
    if (isPlaying) {
      pause();
    } else {
      resume();
    }
  }

  void toggleRepeatMode() {
    switch (_repeatMode.value) {
      case PlayerRepeatMode.none:
        _repeatMode.value = PlayerRepeatMode.all;
        break;
      case PlayerRepeatMode.all:
        _repeatMode.value = PlayerRepeatMode.one;
        break;
      case PlayerRepeatMode.one:
        _repeatMode.value = PlayerRepeatMode.none;
        break;
    }
  }

  void toggleShuffleMode() {
    if (_shuffleMode.value == PlayerShuffleMode.off) {
      _shuffleMode.value = PlayerShuffleMode.on;
      _shuffleQueue();
    } else {
      _shuffleMode.value = PlayerShuffleMode.off;
      // Restore original queue but keep current track index
      final currentTrack =
          _tracks.isNotEmpty ? _tracks[_trackIndex.value] : null;
      _tracks.value = List.from(_originalQueue);
      if (currentTrack != null) {
        _trackIndex.value = _tracks.indexOf(currentTrack);
        if (_trackIndex.value == -1) _trackIndex.value = 0;
      }
    }
  }

  void _shuffleQueue() {
    if (_tracks.isEmpty) return;

    // Save current track
    final currentTrack = _tracks.isNotEmpty ? _tracks[_trackIndex.value] : null;

    // Create shuffled queue
    _shuffledQueue.value = List.from(_tracks)..shuffle();

    // If we have a current track, move it to the current position
    if (currentTrack != null) {
      final currentIndex = _shuffledQueue.indexOf(currentTrack);
      if (currentIndex != -1 && currentIndex != _trackIndex.value) {
        final temp = _shuffledQueue[_trackIndex.value];
        _shuffledQueue[_trackIndex.value] = currentTrack;
        _shuffledQueue[currentIndex] = temp;
      }
    }

    _tracks.value = _shuffledQueue;
  }

  IconButton playerIcon({double size = 24.0, Color? color}) {
    // Only show loading indicator when buffering and not yet playing
    if (isBuffering && _playerPosition.value.inMilliseconds == 0) {
      return IconButton(
        onPressed: () => pause(),
        iconSize: size,
        icon: SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: 2.0,
            color: color ?? Colors.white,
          ),
        ),
      );
    }

    if (isPlaying) {
      return IconButton(
        onPressed: () => pause(),
        iconSize: size,
        icon: Icon(
          Icons.pause,
          color: color ?? Colors.white,
        ),
      );
    }

    return IconButton(
      onPressed: isPaused ? () => resume() : () => play(),
      iconSize: size,
      icon: Icon(
        Icons.play_arrow,
        color: color ?? Colors.white,
      ),
    );
  }

  @override
  void onClose() {
    player.dispose();
    super.onClose();
  }
}
