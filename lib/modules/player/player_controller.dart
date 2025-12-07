import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/di/service_locator.dart';
import '../../data/models/album.dart';
import '../../data/models/song.dart';
import '../../data/services/audio/audio_service_interface.dart';
import '../../data/services/performance_service.dart';
import '../app/app_controller.dart';

/// Defines the current playback mode of the audio player.
///
/// Determines how tracks are selected and managed in the player queue.
enum PlayerMode {
  /// Radio mode: Continuous playback of radio-style stream
  radio,

  /// Album mode: Playback from a specific album with track navigation
  album
}

/// Defines the repeat behavior for track playback.
///
/// Controls how the player handles track repetition when reaching the end of the queue.
enum PlayerRepeatMode {
  /// No repeat: Stop playback when queue ends
  none,

  /// Repeat all: Loop through all tracks in the queue
  all,

  /// Repeat one: Loop the current track indefinitely
  one
}

/// Defines the shuffle behavior for track playback.
///
/// Controls whether tracks are played in order or randomly shuffled.
enum PlayerShuffleMode {
  /// Sequential playback: Play tracks in original order
  off,

  /// Shuffled playback: Play tracks in randomized order
  on
}

/// Controller for managing audio playback, queue management, and player state.
///
/// Provides comprehensive audio player functionality including:
/// - **Dual playback modes**: Radio streaming and album-based playback
/// - **Queue management**: Track ordering, shuffling, and repeat modes
/// - **Playback control**: Play, pause, seek, volume, and navigation
/// - **State management**: Real-time updates for UI components
/// - **Performance monitoring**: Integration with Firebase Performance
///
/// The controller integrates with [IAudioService] for actual audio playback
/// and maintains reactive state using GetX observables for real-time UI updates.
///
/// Usage:
/// ```dart
/// final controller = Get.find<PlayerController>();
/// await controller.playAlbum(album);
/// controller.togglePlayPause();
/// ```
class PlayerController extends GetxController {
  // Core player components - using centralized background audio service
  late final IAudioService _audioService;

  /// Reference to the main app controller for global state management.
  final appController = Get.find<AppController>();

  // Observable state variables
  final _playerState = PlayerState.stopped.obs;
  final _playerDuration = Duration.zero.obs;
  final _playerPosition = Duration.zero.obs;
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

  // Getters - Current playback content
  /// The currently playing or selected song, null if none.
  Song? get currentSong => _currentSong.value;

  /// The current album being played, null if in radio mode or none selected.
  Album? get currentAlbum => _currentAlbum.value;

  /// List of all tracks in the current playback queue.
  List<Song> get tracks => _tracks;

  /// Zero-based index of the current track in the queue.
  int get trackIndex => _trackIndex.value;

  /// URL of the current song's cover art image, null if none available.
  String? get coverURL => _coverURL.value;

  /// Current state of the audio player (playing, paused, stopped).
  PlayerState get playerState => _playerState.value;

  /// String representation of the current player state for debugging.
  String get playerStateString => _playerState.value.toString();

  /// Formatted duration string (e.g., "3:45") of the current track.
  String get playerDurationFormatted => formatDuration(_playerDuration.value);

  /// Formatted position string (e.g., "1:23") of current playback position.
  String get playerPositionFormatted => formatDuration(_playerPosition.value);

  /// Total duration of the current track.
  Duration get playerDuration => _playerDuration.value;

  /// Current playback position within the track.
  Duration get playerPosition => _playerPosition.value;

  /// Total duration in seconds as a double for slider widgets.
  double get durationAsDouble => _playerDuration.value.inSeconds.toDouble();

  /// Current position in seconds as a double for slider widgets.
  double get positionAsDouble => _playerPosition.value.inSeconds.toDouble();

  /// Whether the player is currently playing audio.
  bool get isPlaying => _playerState.value == PlayerState.playing;

  /// Whether the player is currently paused.
  bool get isPaused => _playerState.value == PlayerState.paused;

  /// Whether the player is stopped (no track loaded).
  bool get isStopped => _playerState.value == PlayerState.stopped;

  /// Whether the player is currently buffering content.
  bool get isBuffering => _isBuffering.value;

  /// Current volume level (0.0 to 1.0).
  double get volume => _volume.value;

  /// Current playback mode (radio or album).
  PlayerMode get playerMode => _playerMode.value;

  /// Current song in radio mode, may differ from album tracks.
  Song? get currentRadioSong => _currentRadioSong.value;

  /// Last playback error message, null if no error.
  String? get playbackError => _playbackError.value;

  /// Current repeat mode setting (none, all, one).
  PlayerRepeatMode get repeatMode => _repeatMode.value;

  /// Current shuffle mode setting (off, on).
  PlayerShuffleMode get shuffleMode => _shuffleMode.value;

  /// Whether shuffle mode is currently enabled.
  bool get isShuffleOn => _shuffleMode.value == PlayerShuffleMode.on;

  /// Whether repeat one track mode is enabled.
  bool get isRepeatOne => _repeatMode.value == PlayerRepeatMode.one;

  /// Whether repeat all tracks mode is enabled.
  bool get isRepeatAll => _repeatMode.value == PlayerRepeatMode.all;

  /// Whether to hide the mini player in radio view.
  bool get hidePlayerInRadioView => _hidePlayerInRadioView.value;

  // Setters - Playback content updates
  /// Sets the currently playing song.
  set currentSong(Song? value) => _currentSong.value = value;

  /// Sets the current album being played.
  set currentAlbum(Album? value) => _currentAlbum.value = value;

  /// Sets the track queue and updates shuffle if enabled.
  ///
  /// Automatically preserves the original order and applies shuffle if active.
  set tracks(List<Song> value) {
    _tracks.value = value;
    _originalQueue.value = List.from(value);
    if (isShuffleOn) {
      _shuffleQueue();
    }
  }

  /// Sets the current track index in the queue.
  set trackIndex(int value) => _trackIndex.value = value;

  /// Sets the cover art URL for the current track.
  set coverURL(String? value) => _coverURL.value = value;

  /// Sets the playback volume (0.0 to 1.0) and applies it to the audio service.
  set volume(double value) {
    _volume.value = value;
    _audioService.setVolume(value);
  }

  /// Sets the playback mode (radio or album).
  set playerMode(PlayerMode value) => _playerMode.value = value;

  /// Sets whether to hide the mini player in radio view.
  set hidePlayerInRadioView(bool value) => _hidePlayerInRadioView.value = value;

  @override
  void onInit() {
    super.onInit();
    // Get the audio service from service locator
    _audioService = ServiceLocator.get<IAudioService>();
    // Hide player by default when app starts
    _hidePlayerInRadioView.value = true;
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    // Start player initialization performance trace
    final performanceService = PerformanceService();
    await performanceService.startPlayerInitTrace();

    // Initialize the audio service
    await _audioService.initialize();

    // Set up player event listeners using the IAudioService streams
    _audioService.duration.listen(_onDurationChanged);
    _audioService.position.listen(_onPositionChanged);
    _audioService.playbackState.listen(_onPlaybackStateChanged);
    _audioService.currentTrack.listen((song) {
      if (song == null) {
        _onPlayerComplete(null);
      }
    });

    // Set initial volume
    await _audioService.setVolume(_volume.value);

    // Stop player initialization trace
    await performanceService.stopPlayerInitTrace(
      playerMode: 'background_audio_service',
    );
  }

  // ignore: use_setters_to_change_properties
  void _onDurationChanged(Duration duration) {
    _playerDuration.value = duration;
  }

  // ignore: use_setters_to_change_properties
  void _onPositionChanged(Duration position) {
    _playerPosition.value = position;
  }

  void _onPlaybackStateChanged(PlaybackState state) {
    // Map PlaybackState to PlayerState
    final playerState = _mapPlaybackStateToPlayerState(state);
    _playerState.value = playerState;
    _isBuffering.value = state == PlaybackState.buffering;
  }

  PlayerState _mapPlaybackStateToPlayerState(PlaybackState state) {
    switch (state) {
      case PlaybackState.playing:
        return PlayerState.playing;
      case PlaybackState.paused:
        return PlayerState.paused;
      case PlaybackState.stopped:
        return PlayerState.stopped;
      case PlaybackState.completed:
        return PlayerState.completed;
      case PlaybackState.buffering:
        return PlayerState.playing; // Treat buffering as playing for UI
      case PlaybackState.error:
        return PlayerState.stopped;
    }
  }

  Future<void> _onPlayerComplete(void _) async {
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
      Get.back<void>();
      await closePlayer();
    }
  }

  /// Calculates the current playback progress as a value between 0.0 and 1.0.
  ///
  /// Returns 0.0 if duration is zero or invalid, otherwise returns position/duration.
  /// Used for progress bars and sliders.
  double getProgressValue() {
    if (durationAsDouble <= 0.0) {
      return 0;
    }
    return positionAsDouble / durationAsDouble;
  }

  /// Formats a duration as a string in MM:SS format.
  ///
  /// Pads minutes and seconds with leading zeros for consistent display.
  /// Example: Duration(minutes: 3, seconds: 45) → "03:45"
  String formatDuration(Duration dur) {
    final minutes = dur.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = dur.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Starts playback based on the current player mode.
  ///
  /// Automatically chooses between radio streaming or album track playback
  /// depending on the current [playerMode] setting.
  Future<void> play() async {
    if (playerMode == PlayerMode.radio) {
      await playRadio();
    } else if (playerMode == PlayerMode.album) {
      await playTrack();
    }
  }

  /// Starts radio mode playback with continuous streaming.
  ///
  /// Sets the player to radio mode and hides the mini player in radio view.
  /// Handles stream connectivity and updates UI state accordingly.
  Future<void> playRadio() async {
    try {
      _playbackError.value = null;
      playerMode = PlayerMode.radio;
      // Set flag to hide player in radio view
      _hidePlayerInRadioView.value = true;

      // Get a random album from the available albums
      final albums = appController.albums;
      if (albums.isEmpty) {
        _playbackError.value = 'No music available for radio mode';
        return;
      }

      final randomAlbum = albums[Random().nextInt(albums.length)];
      if (randomAlbum.tracks.isEmpty) {
        _playbackError.value = 'Selected album has no tracks';
        return;
      }

      // Get a random track from the album
      final randomTrack =
          randomAlbum.tracks[Random().nextInt(randomAlbum.tracks.length)];
      _currentRadioSong.value = randomTrack;
      _coverURL.value = randomAlbum.albumCover;

      // Play the track
      await _audioService.play(randomTrack);
    } on Exception catch (e) {
      _playbackError.value = 'Error playing radio: $e';
      debugPrint('Radio playback error: $e');
    }
  }

  /// Plays the current track in album mode.
  ///
  /// Validates track availability and index bounds before starting playback.
  /// Sets the player to album mode and updates the current song state.
  /// Handles errors gracefully by setting appropriate error messages.
  Future<void> playTrack() async {
    try {
      _playbackError.value = null;
      playerMode = PlayerMode.album;

      if (_tracks.isEmpty) {
        _playbackError.value = 'No tracks available to play';
        return;
      }

      if (_trackIndex.value < 0 || _trackIndex.value >= _tracks.length) {
        _playbackError.value = 'Track index out of bounds';
        return;
      }

      final currentTrack = _tracks[_trackIndex.value];
      _currentSong.value = currentTrack;

      await _audioService.play(currentTrack);

      if (kDebugMode) {
        print('TRACK INDEX: ${_trackIndex.value}');
        print('TRACKS LENGTH: ${_tracks.length}');
      }
    } on Exception catch (e) {
      _playbackError.value = 'Error playing track: $e';
      debugPrint('Track playback error: $e');
    }
  }

  /// Starts playing an album from the specified track index.
  ///
  /// Sets up the complete album for playback, including track queue and cover art.
  /// Shows the mini player in album mode and starts playback.
  ///
  /// [album] The album to play.
  /// [startIndex] Zero-based index of the track to start with (default: 0).
  Future<void> playAlbum(Album album, {int startIndex = 0}) async {
    _currentAlbum.value = album;
    _coverURL.value = album.albumCover;
    tracks = album.tracks;
    _trackIndex.value = startIndex.clamp(0, _tracks.length - 1);
    // Show player in album mode
    _hidePlayerInRadioView.value = false;
    await playTrack();
  }

  /// Advances to the next track in the queue.
  ///
  /// Behavior depends on current mode and repeat settings:
  /// - **Radio mode**: Restarts radio stream
  /// - **Album mode**: Moves to next track, handles end-of-queue based on repeat mode
  /// - **Repeat all**: Loops back to first track when reaching the end
  /// - **No repeat**: Closes player when reaching the end
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
      Get.back<void>();
      await closePlayer();
    }
  }

  /// Goes to the previous track or restarts the current track.
  ///
  /// If more than 3 seconds into the current track, restarts from the beginning.
  /// Otherwise, moves to the previous track in the queue.
  /// Handles beginning-of-queue by staying on the first track.
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

  /// Pauses the current playback.
  Future<void> pause() async {
    await _audioService.pause();
  }

  /// Resumes paused playback.
  Future<void> resume() async {
    await _audioService.resume();
  }

  /// Stops playback completely.
  Future<void> stop() async {
    await _audioService.stop();
  }

  /// Seeks to a specific position in the current track.
  ///
  /// [seconds] The position to seek to in seconds.
  Future<void> seek(double seconds) async {
    await _audioService.seek(Duration(seconds: seconds.toInt()));
  }

  /// Closes the player and clears all playback state.
  ///
  /// Releases audio resources and resets all player state to default values.
  /// Should be called when the player is no longer needed.
  Future<void> closePlayer() async {
    // FIRST: Dismiss the mini player UI immediately to prevent freeze
    // This avoids UI blocking while state changes occur
    try {
      final appController = Get.find<AppController>();
      // Use height 0 to fully close the mini player
      appController.miniPlayerController.animateToHeight(
        height: 0,
      );
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Error dismissing mini player: $e');
      }
      // Continue with cleanup even if mini player dismissal fails
    }

    // SECOND: Clear all UI state atomically to prevent multiple Obx rebuilds
    // This prevents the mini player from trying to rebuild during state changes
    _tracks.clear();
    _trackIndex.value = 0;
    _currentSong.value = null;
    _currentRadioSong.value = null;
    _currentAlbum.value = null;
    _coverURL.value = null;
    _playerState.value = PlayerState.stopped;

    // THIRD: Stop the audio service
    try {
      await _audioService.stop();
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Error stopping audio service: $e');
      }
    }
  }

  /// Toggles between play and pause states.
  ///
  /// If currently playing, pauses playback. If paused or stopped, resumes playback.
  void togglePlayPause() {
    if (isPlaying) {
      pause();
    } else {
      resume();
    }
  }

  /// Cycles through repeat modes: none → all → one → none.
  ///
  /// Updates the repeat mode and handles queue reshuffling if shuffle is active.
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

  /// Toggles shuffle mode on/off and updates the queue accordingly.
  ///
  /// When enabling shuffle, creates a randomized queue while preserving the current track.
  /// When disabling shuffle, restores the original queue order and maintains the current track position.
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
        if (_trackIndex.value == -1) {
          _trackIndex.value = 0;
        }
      }
    }
  }

  void _shuffleQueue() {
    if (_tracks.isEmpty) {
      return;
    }

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

  /// Creates an appropriate play/pause icon button based on current player state.
  ///
  /// Returns a loading indicator when buffering, pause icon when playing,
  /// or play icon when paused/stopped.
  ///
  /// [size] The size of the icon (default: 24.0).
  /// [color] The color of the icon (default: Colors.white).
  IconButton playerIcon({double size = 24.0, Color? color}) {
    // Only show loading indicator when buffering and not yet playing
    if (isBuffering && _playerPosition.value.inMilliseconds == 0) {
      return IconButton(
        onPressed: pause,
        iconSize: size,
        icon: SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: color ?? Colors.white,
          ),
        ),
      );
    }

    if (isPlaying) {
      return IconButton(
        onPressed: pause,
        iconSize: size,
        icon: Icon(
          Icons.pause,
          color: color ?? Colors.white,
        ),
      );
    }

    return IconButton(
      onPressed: isPaused ? resume : play,
      iconSize: size,
      icon: Icon(
        Icons.play_arrow,
        color: color ?? Colors.white,
      ),
    );
  }

  /// Explicitly shows the mini player in all views.
  void showPlayer() {
    _hidePlayerInRadioView.value = false;
  }

  /// Explicitly hides the mini player in radio view.
  void hidePlayer() {
    _hidePlayerInRadioView.value = true;
  }

  @override
  void onClose() {
    // Don't dispose the audio service since it's managed by ServiceLocator
    super.onClose();
  }
}
