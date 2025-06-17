import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../exceptions/audio_service_exception.dart';
import '../../models/song.dart';
import '../performance_service.dart';
import 'audio_service_interface.dart';

/// Enhanced audio service implementing comprehensive audio management
///
/// Provides full-featured audio playback with queue management, background
/// playback, advanced controls, and proper error handling.
class EnhancedAudioService implements IAudioService {
  factory EnhancedAudioService() => _instance;
  EnhancedAudioService._internal();
  static final EnhancedAudioService _instance =
      EnhancedAudioService._internal();

  // Core audio player
  AudioPlayer? _player;
  AudioPlayer get player => _player ??= _createPlayer();

  // State management
  bool _isInitialized = false;
  bool _isDisposed = false;
  AppLifecycleState? _lastLifecycleState;

  // Playback state
  PlaybackState _currentState = PlaybackState.stopped;
  Song? _currentSong;
  Duration _currentPosition = Duration.zero;
  Duration _trackDuration = Duration.zero;
  double _currentVolume = 1;
  double _currentSpeed = 1;
  PlaybackMode _currentMode = PlaybackMode.normal;
  bool _backgroundPlaybackEnabled = false;
  final double _bufferingProgress = 0;

  // Queue management
  final List<Song> _queue = <Song>[];
  int _currentIndex = -1;

  // Stream controllers
  final StreamController<PlaybackState> _stateController =
      StreamController<PlaybackState>.broadcast();
  final StreamController<Song?> _trackController =
      StreamController<Song?>.broadcast();
  final StreamController<Duration> _positionController =
      StreamController<Duration>.broadcast();
  final StreamController<Duration> _durationController =
      StreamController<Duration>.broadcast();
  final StreamController<double> _volumeController =
      StreamController<double>.broadcast();
  final StreamController<double> _speedController =
      StreamController<double>.broadcast();
  final StreamController<PlaybackMode> _modeController =
      StreamController<PlaybackMode>.broadcast();
  final StreamController<List<Song>> _queueController =
      StreamController<List<Song>>.broadcast();
  final StreamController<double> _bufferingController =
      StreamController<double>.broadcast();

  // Public streams
  @override
  Stream<PlaybackState> get playbackState => _stateController.stream;

  @override
  Stream<Song?> get currentTrack => _trackController.stream;

  @override
  Stream<Duration> get position => _positionController.stream;

  @override
  Stream<Duration> get duration => _durationController.stream;

  @override
  Stream<double> get volume => _volumeController.stream;

  @override
  Stream<double> get playbackSpeed => _speedController.stream;

  @override
  Stream<PlaybackMode> get playbackMode => _modeController.stream;

  @override
  Stream<List<Song>> get queueStream => _queueController.stream;

  @override
  Stream<double> get bufferingProgress => _bufferingController.stream;

  // Public getters
  @override
  PlaybackState get currentState => _currentState;

  @override
  Song? get currentSong => _currentSong;

  @override
  Duration get currentPosition => _currentPosition;

  @override
  Duration get trackDuration => _trackDuration;

  @override
  double get currentVolume => _currentVolume;

  @override
  double get currentSpeed => _currentSpeed;

  @override
  PlaybackMode get currentMode => _currentMode;

  @override
  List<Song> get queue => List.unmodifiable(_queue);

  @override
  bool get isPlaying => _currentState == PlaybackState.playing;

  @override
  bool get isPaused => _currentState == PlaybackState.paused;

  @override
  bool get isStopped => _currentState == PlaybackState.stopped;

  @override
  bool get isBuffering => _currentState == PlaybackState.buffering;

  @override
  double get progress {
    if (_trackDuration.inMilliseconds <= 0) return 0;
    return _currentPosition.inMilliseconds / _trackDuration.inMilliseconds;
  }

  @override
  String get formattedPosition => formatDuration(_currentPosition);

  @override
  String get formattedDuration => formatDuration(_trackDuration);

  @override
  Future<void> initialize() async {
    if (_isInitialized || _isDisposed) return;

    try {
      // Note: Lifecycle management can be handled by the calling app

      // Initialize player
      _createPlayer();

      // Start performance trace
      final performanceService = PerformanceService();
      await performanceService.startPlayerInitTrace();

      // Load saved queue and settings
      await _loadSavedState();

      _isInitialized = true;

      await performanceService.stopPlayerInitTrace(
        playerMode: 'enhanced_service',
      );

      if (kDebugMode) {
        print('EnhancedAudioService initialized successfully');
      }
    } on Exception catch (e) {
      throw const AudioInitializationException.initFailed();
    }
  }

  @override
  Future<void> play(Song track, {Duration? startPosition}) async {
    if (_isDisposed) {
      throw const AudioOperationException.serviceDisposed();
    }

    try {
      await _ensureInitialized();

      // Add to queue if not already present
      if (!_queue.contains(track)) {
        await addToQueue(track);
      }

      // Find track in queue
      final index = _queue.indexOf(track);
      if (index == -1) {
        throw AudioQueueException.invalidIndex(index, _queue.length);
      }

      _currentIndex = index;
      _currentSong = track;

      _setState(PlaybackState.buffering);

      final source = UrlSource(track.songUrl);
      await player.play(source, position: startPosition);

      _trackController.add(_currentSong);
      await _saveCurrentState();

      if (kDebugMode) {
        print('Playing: ${track.songName} by ${track.artist}');
      }
    } on AudioServiceException {
      _setState(PlaybackState.error);
      rethrow;
    } on Exception catch (e) {
      _setState(PlaybackState.error);
      throw AudioPlaybackException.playbackFailed(e.toString());
    }
  }

  @override
  Future<void> pause() async {
    if (_isDisposed) {
      throw const AudioOperationException.serviceDisposed();
    }

    if (!isPlaying) {
      throw AudioOperationException.invalidState('pause', _currentState.name);
    }

    try {
      await _ensureInitialized();
      await player.pause();
    } on Exception catch (e) {
      throw AudioPlaybackException.playbackFailed('Pause failed: $e');
    }
  }

  @override
  Future<void> resume() async {
    if (_isDisposed) {
      throw const AudioOperationException.serviceDisposed();
    }

    if (!isPaused) {
      throw AudioOperationException.invalidState('resume', _currentState.name);
    }

    try {
      await _ensureInitialized();
      await player.resume();
    } on Exception catch (e) {
      throw AudioPlaybackException.playbackFailed('Resume failed: $e');
    }
  }

  @override
  Future<void> stop() async {
    if (_isDisposed) {
      throw const AudioOperationException.serviceDisposed();
    }

    try {
      await _ensureInitialized();
      await player.stop();
      _currentSong = null;
      _currentIndex = -1;
      _currentPosition = Duration.zero;
      _trackController.add(null);
      await _saveCurrentState();
    } on Exception catch (e) {
      throw AudioPlaybackException.playbackFailed('Stop failed: $e');
    }
  }

  @override
  Future<void> seek(Duration position) async {
    if (_isDisposed) {
      throw const AudioOperationException.serviceDisposed();
    }

    if (position.isNegative || position > _trackDuration) {
      throw AudioOperationException.invalidParameter(
        'position',
        position.toString(),
      );
    }

    try {
      await _ensureInitialized();
      await player.seek(position);
    } on Exception catch (e) {
      throw AudioPlaybackException.playbackFailed('Seek failed: $e');
    }
  }

  @override
  Future<void> setVolume(double volume) async {
    if (_isDisposed) {
      throw const AudioOperationException.serviceDisposed();
    }

    if (volume < 0.0 || volume > 1.0) {
      throw AudioOperationException.invalidParameter(
        'volume',
        volume.toString(),
      );
    }

    try {
      await _ensureInitialized();
      _currentVolume = volume;
      await player.setVolume(volume);
      _volumeController.add(volume);
      await _saveCurrentState();
    } on Exception catch (e) {
      throw AudioPlaybackException.playbackFailed('Volume change failed: $e');
    }
  }

  @override
  Future<void> setPlaybackSpeed(double speed) async {
    if (_isDisposed) {
      throw const AudioOperationException.serviceDisposed();
    }

    if (speed <= 0.0 || speed > 3.0) {
      throw AudioOperationException.invalidParameter(
        'speed',
        speed.toString(),
      );
    }

    try {
      await _ensureInitialized();
      _currentSpeed = speed;
      await player.setPlaybackRate(speed);
      _speedController.add(speed);
      await _saveCurrentState();
    } on Exception catch (e) {
      throw AudioPlaybackException.playbackFailed('Speed change failed: $e');
    }
  }

  @override
  Future<void> setPlaybackMode(PlaybackMode mode) async {
    _currentMode = mode;
    _modeController.add(mode);
    await _saveCurrentState();
  }

  @override
  Future<void> skipToNext() async {
    if (_queue.isEmpty) {
      throw const AudioQueueException.emptyQueue();
    }

    final nextIndex = _getNextIndex();
    if (nextIndex == -1) return; // No next track available

    final nextTrack = _queue[nextIndex];
    await play(nextTrack);
  }

  @override
  Future<void> skipToPrevious() async {
    if (_queue.isEmpty) {
      throw const AudioQueueException.emptyQueue();
    }

    final prevIndex = _getPreviousIndex();
    if (prevIndex == -1) return; // No previous track available

    final prevTrack = _queue[prevIndex];
    await play(prevTrack);
  }

  @override
  Future<void> addToQueue(Song track, {int? index}) async {
    if (index != null && (index < 0 || index > _queue.length)) {
      throw AudioQueueException.invalidIndex(index, _queue.length);
    }

    if (index == null) {
      _queue.add(track);
    } else {
      _queue.insert(index, track);
      // Adjust current index if necessary
      if (_currentIndex >= index) {
        _currentIndex++;
      }
    }

    _queueController.add(List.unmodifiable(_queue));
    await _saveCurrentState();
  }

  @override
  Future<void> removeFromQueue(int index) async {
    if (index < 0 || index >= _queue.length) {
      throw AudioQueueException.invalidIndex(index, _queue.length);
    }

    _queue.removeAt(index);

    // Adjust current index if necessary
    if (_currentIndex > index) {
      _currentIndex--;
    } else if (_currentIndex == index) {
      // Currently playing track was removed
      if (_queue.isEmpty) {
        await stop();
      } else {
        // Play next track or adjust index
        if (_currentIndex >= _queue.length) {
          _currentIndex = _queue.length - 1;
        }
        if (_currentIndex >= 0) {
          await play(_queue[_currentIndex]);
        }
      }
    }

    _queueController.add(List.unmodifiable(_queue));
    await _saveCurrentState();
  }

  @override
  Future<void> clearQueue() async {
    await stop();
    _queue.clear();
    _currentIndex = -1;
    _queueController.add(List.unmodifiable(_queue));
    await _saveCurrentState();
  }

  @override
  Future<void> setBackgroundPlaybackEnabled(bool enabled) async {
    _backgroundPlaybackEnabled = enabled;
    // Note: Full background playback implementation would require
    // additional platform-specific configuration and possibly
    // audio_service package for complete background support
    await _saveCurrentState();
  }

  @override
  String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
  }

  // Private methods

  AudioPlayer _createPlayer() {
    if (_player != null) {
      _disposePlayer();
    }

    _player = AudioPlayer();

    // Set up event listeners
    _player!.onDurationChanged.listen((duration) {
      _trackDuration = duration;
      _durationController.add(duration);
    });

    _player!.onPositionChanged.listen((position) {
      _currentPosition = position;
      _positionController.add(position);
    });

    _player!.onPlayerStateChanged.listen((state) {
      final playbackState = _mapPlayerState(state);
      _setState(playbackState);
    });

    _player!.onPlayerComplete.listen((_) {
      _setState(PlaybackState.completed);
      _handleTrackCompletion();
    });

    // Set initial configuration
    _player!.setVolume(_currentVolume);
    _player!.setPlaybackRate(_currentSpeed);

    return _player!;
  }

  void _setState(PlaybackState state) {
    if (_currentState != state) {
      _currentState = state;
      _stateController.add(state);
    }
  }

  PlaybackState _mapPlayerState(PlayerState state) {
    switch (state) {
      case PlayerState.playing:
        return PlaybackState.playing;
      case PlayerState.paused:
        return PlaybackState.paused;
      case PlayerState.stopped:
        return PlaybackState.stopped;
      case PlayerState.completed:
        return PlaybackState.completed;
      case PlayerState.disposed:
        return PlaybackState.stopped;
    }
  }

  Future<void> _handleTrackCompletion() async {
    switch (_currentMode) {
      case PlaybackMode.normal:
        if (_hasNextTrack()) {
          await skipToNext();
        }
        break;
      case PlaybackMode.repeatOne:
        if (_currentSong != null) {
          await play(_currentSong!);
        }
        break;
      case PlaybackMode.repeatAll:
        await skipToNext();
        break;
      case PlaybackMode.shuffle:
        await _playRandomTrack();
        break;
    }
  }

  int _getNextIndex() {
    if (_queue.isEmpty) return -1;

    switch (_currentMode) {
      case PlaybackMode.normal:
      case PlaybackMode.repeatOne:
        return _currentIndex + 1 < _queue.length ? _currentIndex + 1 : -1;
      case PlaybackMode.repeatAll:
        return _currentIndex + 1 < _queue.length ? _currentIndex + 1 : 0;
      case PlaybackMode.shuffle:
        return _getRandomIndex();
    }
  }

  int _getPreviousIndex() {
    if (_queue.isEmpty) return -1;

    switch (_currentMode) {
      case PlaybackMode.normal:
      case PlaybackMode.repeatOne:
        return _currentIndex > 0 ? _currentIndex - 1 : -1;
      case PlaybackMode.repeatAll:
        return _currentIndex > 0 ? _currentIndex - 1 : _queue.length - 1;
      case PlaybackMode.shuffle:
        return _getRandomIndex();
    }
  }

  int _getRandomIndex() {
    if (_queue.length <= 1) return _currentIndex;
    int randomIndex;
    do {
      randomIndex = Random().nextInt(_queue.length);
    } while (randomIndex == _currentIndex);
    return randomIndex;
  }

  Future<void> _playRandomTrack() async {
    if (_queue.isEmpty) return;
    final randomIndex = _getRandomIndex();
    if (randomIndex != -1) {
      await play(_queue[randomIndex]);
    }
  }

  bool _hasNextTrack() => _currentIndex + 1 < _queue.length;

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  Future<void> _loadSavedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load volume and speed
      _currentVolume = prefs.getDouble('audio_volume') ?? 1.0;
      _currentSpeed = prefs.getDouble('audio_speed') ?? 1.0;

      // Load playback mode
      final modeIndex = prefs.getInt('audio_mode') ?? 0;
      _currentMode = PlaybackMode
          .values[modeIndex.clamp(0, PlaybackMode.values.length - 1)];

      // Load background playback setting
      _backgroundPlaybackEnabled =
          prefs.getBool('background_playback') ?? false;

      // Note: Queue restoration could be implemented here by saving/loading track IDs
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Error loading saved audio state: $e');
      }
    }
  }

  Future<void> _saveCurrentState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setDouble('audio_volume', _currentVolume);
      await prefs.setDouble('audio_speed', _currentSpeed);
      await prefs.setInt('audio_mode', _currentMode.index);
      await prefs.setBool('background_playback', _backgroundPlaybackEnabled);

      // Note: Queue persistence could be implemented here by saving track IDs
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Error saving audio state: $e');
      }
    }
  }

  void _disposePlayer() {
    try {
      _player?.dispose();
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Error disposing player: $e');
      }
    } finally {
      _player = null;
    }
  }

  /// Handle app lifecycle changes manually when called by the app
  /// This method can be called by the app to handle lifecycle events
  void handleAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        if (isPlaying && !_backgroundPlaybackEnabled) {
          pause();
        }
        break;
      case AppLifecycleState.detached:
        dispose();
        break;
      case AppLifecycleState.resumed:
        // App resumed - no automatic action
        break;
      case AppLifecycleState.hidden:
        if (isPlaying && !_backgroundPlaybackEnabled) {
          pause();
        }
        break;
    }

    _lastLifecycleState = state;
  }

  @override
  Future<void> dispose() async {
    if (_isDisposed) return;

    _isDisposed = true;

    try {
      // Note: No lifecycle observer to remove

      // Stop and dispose player
      if (_player != null) {
        await stop();
        _disposePlayer();
      }

      // Close stream controllers
      await _stateController.close();
      await _trackController.close();
      await _positionController.close();
      await _durationController.close();
      await _volumeController.close();
      await _speedController.close();
      await _modeController.close();
      await _queueController.close();
      await _bufferingController.close();

      _isInitialized = false;

      if (kDebugMode) {
        print('EnhancedAudioService disposed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error during EnhancedAudioService disposal: $e');
      }
    }
  }
}
