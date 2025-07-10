import 'dart:async';

import 'package:audio_service/audio_service.dart' as audio_service;
import 'package:flutter/foundation.dart';

import '../../exceptions/audio_service_exception.dart';
import '../../models/song.dart';
import 'audio_service_interface.dart';
import 'background_audio_handler.dart';

/// Enhanced audio service with background playback and media notifications
///
/// This service integrates the existing audio functionality with the
/// audio_service package to provide:
/// - Background playback capabilities
/// - Media notifications with controls
/// - Lock screen controls
/// - System media session integration
/// - Media button handling
class BackgroundAudioService implements IAudioService {
  /// Creates a new background audio service instance
  factory BackgroundAudioService() => _instance;
  BackgroundAudioService._internal();
  static final BackgroundAudioService _instance =
      BackgroundAudioService._internal();

  /// Background audio handler for system integration
  BackgroundAudioHandler? _handler;

  /// Whether the service has been initialized
  bool _isInitialized = false;

  /// Whether the service has been disposed
  bool _isDisposed = false;

  /// Current playback state
  PlaybackState _currentState = PlaybackState.stopped;

  /// Current song
  Song? _currentSong;

  /// Current position
  Duration _currentPosition = Duration.zero;

  /// Track duration
  Duration _trackDuration = Duration.zero;

  /// Current volume
  double _currentVolume = 1;

  /// Current playback speed
  double _currentSpeed = 1;

  /// Current playback mode
  PlaybackMode _currentMode = PlaybackMode.normal;

  /// Current queue
  final List<Song> _queue = <Song>[];

  /// Stream controllers for reactive state management
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

  /// Audio service subscriptions
  StreamSubscription<audio_service.PlaybackState>? _playbackStateSubscription;
  StreamSubscription<audio_service.MediaItem?>? _mediaItemSubscription;

  // Public stream getters
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

  // Public property getters
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
    if (_trackDuration.inMilliseconds <= 0) {
      return 0;
    }
    return _currentPosition.inMilliseconds / _trackDuration.inMilliseconds;
  }

  @override
  String get formattedPosition => formatDuration(_currentPosition);

  @override
  String get formattedDuration => formatDuration(_trackDuration);

  @override
  Future<void> initialize() async {
    if (_isInitialized || _isDisposed) {
      return;
    }

    try {
      // Initialize audio service
      _handler = await audio_service.AudioService.init(
        builder: BackgroundAudioHandler.new,
        config: const audio_service.AudioServiceConfig(
          androidNotificationChannelId: 'com.example.robin_radio.channel.audio',
          androidNotificationChannelName: 'Robin Radio Audio',
          androidNotificationOngoing: true,
          androidShowNotificationBadge: true,
          androidNotificationIcon: 'drawable/ic_notification',
        ),
      );

      // Set up stream subscriptions
      _setupStreamSubscriptions();

      _isInitialized = true;

      if (kDebugMode) {
        print('BackgroundAudioService initialized successfully');
      }
    } on Exception {
      throw const AudioInitializationException.initFailed();
    }
  }

  /// Set up stream subscriptions for audio service events
  void _setupStreamSubscriptions() {
    // Listen to playback state changes
    _playbackStateSubscription =
        _handler!.playbackState.listen(_updatePlaybackState);

    // Listen to media item changes
    _mediaItemSubscription = _handler!.mediaItem.listen((mediaItem) {
      if (mediaItem != null) {
        _updateCurrentSong(mediaItem);
      }
    });
  }

  /// Update internal playback state from audio service state
  void _updatePlaybackState(audio_service.PlaybackState state) {
    // Map audio service state to internal state
    final newState =
        _mapAudioServiceState(state.processingState, state.playing);
    _setState(newState);

    // Update position
    _currentPosition = state.position;
    _positionController.add(_currentPosition);

    // Update speed if changed
    if (_currentSpeed != state.speed) {
      _currentSpeed = state.speed;
      _speedController.add(_currentSpeed);
    }
  }

  /// Update current song from media item
  void _updateCurrentSong(audio_service.MediaItem mediaItem) {
    final song = Song(
      id: mediaItem.id,
      songName: mediaItem.title,
      artist: mediaItem.artist ?? '',
      albumName: mediaItem.album,
      songUrl: mediaItem.extras?['songUrl'] as String? ?? '',
      duration: mediaItem.duration,
    );

    _currentSong = song;
    _trackController.add(_currentSong);

    if (mediaItem.duration != null) {
      _trackDuration = mediaItem.duration!;
      _durationController.add(_trackDuration);
    }
  }

  /// Map audio service processing state to internal state
  PlaybackState _mapAudioServiceState(
    audio_service.AudioProcessingState processingState,
    bool playing,
  ) {
    if (playing) {
      return PlaybackState.playing;
    }

    switch (processingState) {
      case audio_service.AudioProcessingState.idle:
        return PlaybackState.stopped;
      case audio_service.AudioProcessingState.loading:
      case audio_service.AudioProcessingState.buffering:
        return PlaybackState.buffering;
      case audio_service.AudioProcessingState.ready:
        return PlaybackState.paused;
      case audio_service.AudioProcessingState.completed:
        return PlaybackState.completed;
      case audio_service.AudioProcessingState.error:
        return PlaybackState.error;
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

      // Play through background handler
      await _handler!.playSong(track, playlist: _queue);

      if (startPosition != null) {
        await seek(startPosition);
      }

      if (kDebugMode) {
        print('Playing: ${track.songName} by ${track.artist}');
      }
    } on AudioServiceException {
      rethrow;
    } on Exception catch (e) {
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
      await _handler!.pause();
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
      await _handler!.play();
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
      await _handler!.stop();
      _currentSong = null;
      _currentPosition = Duration.zero;
      _trackController.add(null);
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
      await _handler!.seek(position);
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

    _currentVolume = volume;
    _volumeController.add(volume);

    // Note: Volume control through audio_service would require custom implementation
    // For now, we just track the value
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
      _speedController.add(speed);

      // Note: Speed control through audio_service would require custom implementation
      // The handler should handle this internally
    } on Exception catch (e) {
      throw AudioPlaybackException.playbackFailed('Speed change failed: $e');
    }
  }

  @override
  Future<void> setPlaybackMode(PlaybackMode mode) async {
    _currentMode = mode;
    _modeController.add(mode);

    // Update handler's playback mode
    if (_handler != null) {
      await _handler!.setPlaybackMode(mode);
    }
  }

  @override
  Future<void> skipToNext() async {
    if (_queue.isEmpty) {
      throw const AudioQueueException.emptyQueue();
    }

    try {
      await _ensureInitialized();
      await _handler!.skipToNext();
    } on Exception catch (e) {
      throw AudioPlaybackException.playbackFailed('Skip to next failed: $e');
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_queue.isEmpty) {
      throw const AudioQueueException.emptyQueue();
    }

    try {
      await _ensureInitialized();
      await _handler!.skipToPrevious();
    } on Exception catch (e) {
      throw AudioPlaybackException.playbackFailed(
        'Skip to previous failed: $e',
      );
    }
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
    }

    _queueController.add(List.unmodifiable(_queue));

    // Add to audio service queue
    if (_isInitialized && _handler != null) {
      final mediaItem = _songToMediaItem(track);
      await _handler!.addQueueItem(mediaItem);
    }
  }

  @override
  Future<void> removeFromQueue(int index) async {
    if (index < 0 || index >= _queue.length) {
      throw AudioQueueException.invalidIndex(index, _queue.length);
    }

    _queue.removeAt(index);
    _queueController.add(List.unmodifiable(_queue));

    // Remove from audio service queue
    if (_isInitialized) {
      await _handler!.removeQueueItemAt(index);
    }
  }

  @override
  Future<void> clearQueue() async {
    _queue.clear();
    _queueController.add(List.unmodifiable(_queue));

    if (_isInitialized) {
      await stop();
      // Clear audio service queue would require custom implementation
    }
  }

  @override
  Future<void> setBackgroundPlaybackEnabled({required bool enabled}) async {
    // Background playback is enabled by default with audio_service
    // This method is maintained for interface compatibility
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

  /// Convert Song to MediaItem for audio service
  audio_service.MediaItem _songToMediaItem(Song song) =>
      audio_service.MediaItem(
        id: song.id ?? '',
        album: song.albumName ?? '',
        title: song.songName,
        artist: song.artist,
        duration: song.duration,
        extras: {
          'songUrl': song.songUrl,
          'albumName': song.albumName,
          'duration': song.duration?.inSeconds,
        },
      );

  /// Set internal state and notify listeners
  void _setState(PlaybackState state) {
    if (_currentState != state) {
      _currentState = state;
      _stateController.add(state);
    }
  }

  /// Ensure the service is initialized
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  @override
  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }

    _isDisposed = true;

    try {
      // Cancel subscriptions
      await _playbackStateSubscription?.cancel();
      await _mediaItemSubscription?.cancel();

      // Clean up handler
      if (_handler != null) {
        await _handler!.cleanUp();
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
        print('BackgroundAudioService disposed');
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Error during BackgroundAudioService disposal: $e');
      }
    }
  }
}
