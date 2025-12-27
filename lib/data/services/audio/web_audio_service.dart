import 'dart:async';

import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

import '../../exceptions/audio_service_exception.dart';
import '../../models/song.dart';
import 'audio_service_interface.dart';
import 'audio_service_mixin.dart';
import 'audio_state.dart';

/// Web-optimized audio service using just_audio directly.
///
/// This service provides audio playback for web browsers without the
/// audio_service package which is not supported on web. It uses just_audio
/// directly for simpler browser-based playback.
///
/// Key differences from BackgroundAudioService:
/// - No system media notifications (not available on web)
/// - No lock screen controls (not available on web)
/// - Background playback depends on browser tab staying open
/// - Uses Media Session API where supported for basic browser controls
///
/// ## State Management Optimization
///
/// This implementation now uses a single [BehaviorSubject<AudioState>] instead
/// of 9 separate StreamControllers, matching the BackgroundAudioService pattern.
/// Benefits include:
/// - **Reduced memory overhead**: Single subject vs 9 StreamControllers
/// - **Atomic state updates**: Related state changes emit together
/// - **Simplified disposal**: One subscription to manage
/// - **Code consistency**: Same pattern as BackgroundAudioService
class WebAudioService with AudioServiceMixin implements IAudioService {
  /// Creates a new web audio service instance
  factory WebAudioService() => _instance;
  WebAudioService._internal();
  static final WebAudioService _instance = WebAudioService._internal();

  /// The audio player instance
  final AudioPlayer _player = AudioPlayer();

  /// Whether the service has been initialized
  bool _isInitialized = false;

  /// Whether the service has been disposed
  bool _isDisposed = false;

  /// Unified audio state using BehaviorSubject for efficient state management.
  final BehaviorSubject<AudioState> _audioState =
      BehaviorSubject<AudioState>.seeded(AudioState.initial);

  /// Internal mutable queue for efficient queue operations.
  final List<Song> _mutableQueue = <Song>[];

  /// Current queue index
  int _currentIndex = 0;

  /// Player state subscription
  StreamSubscription<PlayerState>? _playerStateSubscription;

  /// Position subscription
  StreamSubscription<Duration>? _positionSubscription;

  /// Duration subscription
  StreamSubscription<Duration?>? _durationSubscription;

  /// Buffered position subscription
  StreamSubscription<Duration>? _bufferedPositionSubscription;

  // ============================================================
  // AudioServiceMixin required getters
  // ============================================================

  @override
  bool get isServiceInitialized => _isInitialized;

  @override
  bool get isServiceDisposed => _isDisposed;

  @override
  PlaybackMode get currentPlaybackMode => state.mode;

  @override
  List<Song> get currentQueue => _mutableQueue;

  @override
  int get currentQueueIndex => _currentIndex;

  // ============================================================
  // Public stream getters - derived from unified AudioState stream
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
      // Set up stream subscriptions
      _setupStreamSubscriptions();

      _isInitialized = true;

      logDebug('WebAudioService initialized successfully');
    } on Exception {
      throw const AudioInitializationException.initFailed();
    }
  }

  /// Set up stream subscriptions for player events
  void _setupStreamSubscriptions() {
    // Listen to player state changes
    _playerStateSubscription = _player.playerStateStream.listen((playerState) {
      _updatePlaybackState(playerState);

      // Handle track completion
      if (playerState.processingState == ProcessingState.completed) {
        _handleTrackCompletion();
      }
    });

    // Listen to position changes
    _positionSubscription = _player.positionStream.listen((position) {
      _audioState.add(state.copyWith(position: position));
    });

    // Listen to duration changes
    _durationSubscription = _player.durationStream.listen((duration) {
      if (duration != null) {
        _audioState.add(state.copyWith(duration: duration));
      }
    });

    // Listen to buffered position for progress indicator
    _bufferedPositionSubscription =
        _player.bufferedPositionStream.listen((buffered) {
      if (state.duration.inMilliseconds > 0) {
        final bufferProgress =
            buffered.inMilliseconds / state.duration.inMilliseconds;
        _audioState.add(
          state.copyWith(bufferingProgress: bufferProgress.clamp(0.0, 1.0)),
        );
      }
    });
  }

  /// Update internal playback state from player state
  void _updatePlaybackState(PlayerState playerState) {
    PlaybackState newState;

    if (playerState.playing) {
      newState = PlaybackState.playing;
    } else {
      switch (playerState.processingState) {
        case ProcessingState.idle:
          newState = PlaybackState.stopped;
          break;
        case ProcessingState.loading:
        case ProcessingState.buffering:
          newState = PlaybackState.buffering;
          break;
        case ProcessingState.ready:
          newState = PlaybackState.paused;
          break;
        case ProcessingState.completed:
          newState = PlaybackState.completed;
          break;
      }
    }

    if (state.playbackState != newState) {
      _audioState.add(state.copyWith(playbackState: newState));
    }
  }

  /// Handle track completion and auto-advance
  Future<void> _handleTrackCompletion() async {
    switch (state.mode) {
      case PlaybackMode.normal:
        // Advance to next track if available
        if (_currentIndex < _mutableQueue.length - 1) {
          await skipToNext();
        } else {
          _audioState.add(
            state.copyWith(playbackState: PlaybackState.completed),
          );
        }
        break;
      case PlaybackMode.repeatOne:
        // Replay current track
        await seek(Duration.zero);
        await _player.play();
        break;
      case PlaybackMode.repeatAll:
        // Advance to next or wrap to first
        if (_currentIndex < _mutableQueue.length - 1) {
          await skipToNext();
        } else if (_mutableQueue.isNotEmpty) {
          _currentIndex = 0;
          await _playCurrentTrack();
        }
        break;
      case PlaybackMode.shuffle:
        // Play random track using mixin helper
        final nextIndex = calculateNextIndex();
        if (nextIndex != -1) {
          _currentIndex = nextIndex;
          await _playCurrentTrack();
        }
        break;
    }
  }

  /// Play the track at the current queue index
  Future<void> _playCurrentTrack() async {
    if (_currentIndex >= 0 && _currentIndex < _mutableQueue.length) {
      final track = _mutableQueue[_currentIndex];
      await _loadAndPlay(track);
    }
  }

  /// Load and play a specific track
  Future<void> _loadAndPlay(Song track) async {
    try {
      // Atomic update: set track and reset position
      _audioState.add(
        state.copyWith(
          currentTrack: track,
          position: Duration.zero,
        ),
      );

      await _player.setUrl(track.songUrl);
      await _player.play();

      logDebug('WebAudioService: Playing ${track.songName}');
    } on Exception catch (e) {
      logDebug('WebAudioService: Error loading track: $e');
      _audioState.add(state.copyWith(playbackState: PlaybackState.error));
    }
  }

  @override
  Future<void> play(Song track, {Duration? startPosition}) async {
    ensureNotDisposed();

    try {
      await _ensureInitialized();

      // Add to queue if not already present
      final existingIndex = _mutableQueue.indexWhere((s) => s.id == track.id);
      if (existingIndex >= 0) {
        _currentIndex = existingIndex;
      } else {
        _mutableQueue.add(track);
        _currentIndex = _mutableQueue.length - 1;
        _audioState.add(state.copyWith(queue: List.unmodifiable(_mutableQueue)));
      }

      await _loadAndPlay(track);

      if (startPosition != null) {
        await seek(startPosition);
      }

      logDebug('Playing: ${track.songName} by ${track.artist}');
    } on AudioServiceException {
      rethrow;
    } on Exception catch (e) {
      throw AudioPlaybackException.playbackFailed(e.toString());
    }
  }

  @override
  Future<void> pause() async {
    ensureNotDisposed();

    if (!isPlaying) {
      throw AudioOperationException.invalidState('pause', currentState.name);
    }

    try {
      await _player.pause();
    } on Exception catch (e) {
      throw AudioPlaybackException.playbackFailed('Pause failed: $e');
    }
  }

  @override
  Future<void> resume() async {
    ensureNotDisposed();

    if (!isPaused) {
      throw AudioOperationException.invalidState('resume', currentState.name);
    }

    try {
      await _player.play();
    } on Exception catch (e) {
      throw AudioPlaybackException.playbackFailed('Resume failed: $e');
    }
  }

  @override
  Future<void> stop() async {
    ensureNotDisposed();

    try {
      await _player.stop();
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
    ensureNotDisposed();

    if (position.isNegative) {
      throw AudioOperationException.invalidParameter(
        'position',
        position.toString(),
      );
    }

    try {
      await _player.seek(position);
    } on Exception catch (e) {
      throw AudioPlaybackException.playbackFailed('Seek failed: $e');
    }
  }

  @override
  Future<void> setVolume(double volume) async {
    ensureNotDisposed();
    validateVolume(volume);

    try {
      await _player.setVolume(volume);
      _audioState.add(state.copyWith(volume: volume));
    } on Exception catch (e) {
      throw AudioPlaybackException.playbackFailed('Volume change failed: $e');
    }
  }

  @override
  Future<void> setPlaybackSpeed(double speed) async {
    ensureNotDisposed();
    validateSpeed(speed);

    try {
      await _player.setSpeed(speed);
      _audioState.add(state.copyWith(speed: speed));
    } on Exception catch (e) {
      throw AudioPlaybackException.playbackFailed('Speed change failed: $e');
    }
  }

  @override
  Future<void> setPlaybackMode(PlaybackMode mode) async {
    _audioState.add(state.copyWith(mode: mode));

    // Configure loop mode on player
    switch (mode) {
      case PlaybackMode.repeatOne:
        await _player.setLoopMode(LoopMode.one);
        break;
      case PlaybackMode.repeatAll:
        await _player.setLoopMode(LoopMode.all);
        break;
      case PlaybackMode.normal:
      case PlaybackMode.shuffle:
        await _player.setLoopMode(LoopMode.off);
        break;
    }
  }

  @override
  Future<void> skipToNext() async {
    if (_mutableQueue.isEmpty) {
      throw const AudioQueueException.emptyQueue();
    }

    try {
      final nextIndex = calculateNextIndex();
      if (nextIndex == -1) {
        return; // At end, no repeat
      }

      _currentIndex = nextIndex;
      await _playCurrentTrack();
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
      // If more than 3 seconds into track, restart current track
      if (state.position.inSeconds > 3) {
        await seek(Duration.zero);
        return;
      }

      final prevIndex = calculatePreviousIndex();
      if (prevIndex == -1) {
        await seek(Duration.zero);
        return;
      }

      _currentIndex = prevIndex;
      await _playCurrentTrack();
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
      // Adjust current index if inserting before current track
      if (index <= _currentIndex) {
        _currentIndex++;
      }
    }

    _audioState.add(state.copyWith(queue: List.unmodifiable(_mutableQueue)));
  }

  @override
  Future<void> removeFromQueue(int index) async {
    if (index < 0 || index >= _mutableQueue.length) {
      throw AudioQueueException.invalidIndex(index, _mutableQueue.length);
    }

    _mutableQueue.removeAt(index);

    // Adjust current index
    if (index < _currentIndex) {
      _currentIndex--;
    } else if (index == _currentIndex && _mutableQueue.isNotEmpty) {
      if (_currentIndex >= _mutableQueue.length) {
        _currentIndex = _mutableQueue.length - 1;
      }
    }

    _audioState.add(state.copyWith(queue: List.unmodifiable(_mutableQueue)));
  }

  @override
  Future<void> clearQueue() async {
    _mutableQueue.clear();
    _currentIndex = 0;
    _audioState.add(state.copyWith(queue: const <Song>[]));
    await stop();
  }

  @override
  Future<void> setBackgroundPlaybackEnabled({required bool enabled}) async {
    // Web doesn't support true background playback
    // Audio will pause if browser tab loses focus in most browsers
    logDebug(
      'WebAudioService: Background playback setting ignored on web platform',
    );
  }

  @override
  String formatDuration(Duration duration) => formatDurationValue(duration);

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
      // Cancel subscriptions using mixin helper
      await cancelSubscription(_playerStateSubscription);
      await cancelSubscription(_positionSubscription);
      await cancelSubscription(_durationSubscription);
      await cancelSubscription(_bufferedPositionSubscription);

      // Dispose player
      await _player.dispose();

      // Close the single BehaviorSubject (replaces 9 StreamController closes)
      await _audioState.close();

      _isInitialized = false;

      logDebug('WebAudioService disposed');
    } on Exception catch (e) {
      logDebug('Error during WebAudioService disposal: $e');
    }
  }
}
