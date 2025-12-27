import 'dart:async';

import 'package:audio_service/audio_service.dart' as audio_service;
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

import '../../exceptions/audio_service_exception.dart';
import '../../models/song.dart';
import 'audio_service_interface.dart';
import 'audio_state.dart';
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
///
/// ## State Management Optimization
///
/// This implementation uses a single [BehaviorSubject<AudioState>] instead of
/// 9 separate StreamControllers. Benefits include:
/// - **Reduced memory overhead**: Single subject vs 9 StreamControllers
/// - **Atomic state updates**: Related state changes emit together
/// - **Simplified disposal**: One subscription to manage
/// - **Better debugging**: Complete state snapshot available at any point
///
/// Individual streams are derived using `.map()` and `.distinct()` operators
/// for interface compatibility while maintaining consolidated state benefits.
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

  /// Unified audio state using BehaviorSubject for efficient state management.
  ///
  /// Consolidates 9 separate StreamControllers into a single reactive stream,
  /// reducing memory overhead and enabling atomic state updates.
  final BehaviorSubject<AudioState> _audioState =
      BehaviorSubject<AudioState>.seeded(AudioState.initial);

  /// Internal mutable queue for efficient queue operations.
  /// The immutable queue in AudioState is updated when this changes.
  final List<Song> _mutableQueue = <Song>[];

  /// Audio service subscriptions
  StreamSubscription<audio_service.PlaybackState>? _playbackStateSubscription;
  StreamSubscription<audio_service.MediaItem?>? _mediaItemSubscription;

  // ============================================================
  // Public stream getters - derived from unified AudioState stream
  // Using .map() and .distinct() for efficient, deduplicated streams
  // ============================================================

  @override
  Stream<PlaybackState> get playbackState =>
      _audioState.stream.map((s) => s.playbackState).distinct();

  @override
  Stream<Song?> get currentTrack =>
      _audioState.stream.map((s) => s.currentTrack).distinct();

  @override
  Stream<Duration> get position =>
      _audioState.stream.map((s) => s.position).distinct();

  @override
  Stream<Duration> get duration =>
      _audioState.stream.map((s) => s.duration).distinct();

  @override
  Stream<double> get volume =>
      _audioState.stream.map((s) => s.volume).distinct();

  @override
  Stream<double> get playbackSpeed =>
      _audioState.stream.map((s) => s.speed).distinct();

  @override
  Stream<PlaybackMode> get playbackMode =>
      _audioState.stream.map((s) => s.mode).distinct();

  @override
  Stream<List<Song>> get queueStream =>
      _audioState.stream.map((s) => s.queue).distinct();

  @override
  Stream<double> get bufferingProgress =>
      _audioState.stream.map((s) => s.bufferingProgress).distinct();

  // ============================================================
  // Public property getters - derived from current AudioState value
  // ============================================================

  /// Current audio state snapshot
  AudioState get state => _audioState.value;

  @override
  PlaybackState get currentState => state.playbackState;

  @override
  Song? get currentSong => state.currentTrack;

  @override
  Duration get currentPosition => state.position;

  @override
  Duration get trackDuration => state.duration;

  @override
  double get currentVolume => state.volume;

  @override
  double get currentSpeed => state.speed;

  @override
  PlaybackMode get currentMode => state.mode;

  @override
  List<Song> get queue => List.unmodifiable(_mutableQueue);

  @override
  bool get isPlaying => state.isPlaying;

  @override
  bool get isPaused => state.isPaused;

  @override
  bool get isStopped => state.isStopped;

  @override
  bool get isBuffering => state.isBuffering;

  @override
  double get progress => state.progress;

  @override
  String get formattedPosition => state.formattedPosition;

  @override
  String get formattedDuration => state.formattedDuration;

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

  /// Update internal playback state from audio service state.
  ///
  /// Performs atomic state update combining playback state, position, and speed.
  void _updatePlaybackState(audio_service.PlaybackState serviceState) {
    final newPlaybackState =
        _mapAudioServiceState(serviceState.processingState, serviceState.playing);

    // Atomic update: combine state, position, and speed changes
    _audioState.add(
      state.copyWith(
        playbackState: newPlaybackState,
        position: serviceState.position,
        speed: serviceState.speed,
      ),
    );
  }

  /// Update current song from media item.
  ///
  /// Performs atomic state update combining track and duration changes.
  void _updateCurrentSong(audio_service.MediaItem mediaItem) {
    final song = Song(
      id: mediaItem.id,
      songName: mediaItem.title,
      artist: mediaItem.artist ?? '',
      albumName: mediaItem.album,
      songUrl: mediaItem.extras?['songUrl'] as String? ?? '',
      duration: mediaItem.duration,
    );

    // Atomic update: combine track and duration changes
    _audioState.add(
      state.copyWith(
        currentTrack: song,
        duration: mediaItem.duration ?? state.duration,
      ),
    );
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

      // CRITICAL FIX: Clear existing queue before playing new content
      // This prevents queue state mismatch when switching between radio/album modes
      _mutableQueue.clear();
      _audioState.add(state.copyWith(queue: const <Song>[]));

      // Add the new track to the fresh queue
      _mutableQueue.add(track);
      _audioState.add(state.copyWith(queue: List.unmodifiable(_mutableQueue)));

      // Play through background handler (will set up new audio source)
      await _handler!.playSong(track, playlist: _mutableQueue);

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
      throw AudioOperationException.invalidState('pause', currentState.name);
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
      throw AudioOperationException.invalidState('resume', currentState.name);
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

      // Atomic update: clear track and reset position
      _audioState.add(
        state.copyWith(
          clearCurrentTrack: true,
          position: Duration.zero,
        ),
      );
    } on Exception catch (e) {
      throw AudioPlaybackException.playbackFailed('Stop failed: $e');
    }
  }

  @override
  Future<void> seek(Duration position) async {
    if (_isDisposed) {
      throw const AudioOperationException.serviceDisposed();
    }

    if (position.isNegative || position > trackDuration) {
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

    _audioState.add(state.copyWith(volume: volume));

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
      _audioState.add(state.copyWith(speed: speed));

      // Note: Speed control through audio_service would require custom implementation
      // The handler should handle this internally
    } on Exception catch (e) {
      throw AudioPlaybackException.playbackFailed('Speed change failed: $e');
    }
  }

  @override
  Future<void> setPlaybackMode(PlaybackMode mode) async {
    _audioState.add(state.copyWith(mode: mode));

    // Update handler's playback mode
    if (_handler != null) {
      await _handler!.setPlaybackMode(mode);
    }
  }

  @override
  Future<void> skipToNext() async {
    if (_mutableQueue.isEmpty) {
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
    if (_mutableQueue.isEmpty) {
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
    if (index != null && (index < 0 || index > _mutableQueue.length)) {
      throw AudioQueueException.invalidIndex(index, _mutableQueue.length);
    }

    if (index == null) {
      _mutableQueue.add(track);
    } else {
      _mutableQueue.insert(index, track);
    }

    // Update immutable queue in AudioState
    _audioState.add(state.copyWith(queue: List.unmodifiable(_mutableQueue)));

    // Add to audio service queue
    if (_isInitialized && _handler != null) {
      final mediaItem = _songToMediaItem(track);
      await _handler!.addQueueItem(mediaItem);
    }
  }

  @override
  Future<void> removeFromQueue(int index) async {
    if (index < 0 || index >= _mutableQueue.length) {
      throw AudioQueueException.invalidIndex(index, _mutableQueue.length);
    }

    _mutableQueue.removeAt(index);

    // Update immutable queue in AudioState
    _audioState.add(state.copyWith(queue: List.unmodifiable(_mutableQueue)));

    // Remove from audio service queue
    if (_isInitialized) {
      await _handler!.removeQueueItemAt(index);
    }
  }

  @override
  Future<void> clearQueue() async {
    _mutableQueue.clear();

    // Update immutable queue in AudioState
    _audioState.add(state.copyWith(queue: const <Song>[]));

    // Clear the handler's queue (including just_audio playlist)
    if (_isInitialized && _handler != null) {
      await _handler!.clearQueue();
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

      // Close the single BehaviorSubject (replaces 9 StreamController closes)
      await _audioState.close();

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
