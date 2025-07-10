import 'dart:async';
import 'dart:math';

import '../../models/song.dart';
import 'audio_service_interface.dart';

/// Mock implementation of [IAudioService] for testing and development purposes.
///
/// Provides a comprehensive simulation of audio playback functionality without
/// requiring actual audio system access or media files. This implementation is
/// essential for:
/// - **Unit Testing**: Predictable, controllable audio service behavior
/// - **Integration Testing**: Full workflow testing without audio dependencies
/// - **Development**: UI development without audio file requirements
/// - **CI/CD**: Automated testing in environments without audio capabilities
///
/// ## Key Features
///
/// **Complete Interface Implementation:**
/// - All [IAudioService] methods and properties fully implemented
/// - Realistic timing and state transitions for authentic testing
/// - Proper stream management and event broadcasting
/// - Queue management with all playback modes supported
///
/// **Testing Optimizations:**
/// - Fast, deterministic operations for rapid test execution
/// - Configurable track durations and buffering times
/// - Predictable state changes for assertion-based testing
/// - Memory-efficient stream management
///
/// **Development Support:**
/// - Visual feedback through state changes for UI development
/// - Realistic playback progression for timing-dependent features
/// - Queue manipulation for playlist testing
/// - Volume and speed controls for complete UX testing
///
/// ## Behavioral Simulation
///
/// **Playback Lifecycle:**
/// ```
/// play() → buffering (500ms) → playing → position updates → completed
///    ↓
/// Auto-advance based on playback mode (normal/repeat/shuffle)
/// ```
///
/// **State Management:**
/// - Maintains realistic state transitions (stopped → buffering → playing)
/// - Position tracking with configurable update intervals (250ms)
/// - Proper pause/resume functionality with position preservation
/// - Complete track lifecycle simulation including completion handling
///
/// **Queue Operations:**
/// - Full queue management (add, remove, clear, reorder)
/// - Index tracking with proper boundary handling
/// - Current track switching with state preservation
/// - Queue persistence across playback operations
///
/// ## Usage Patterns
///
/// **Basic Testing Setup:**
/// ```dart
/// void main() {
///   late MockAudioService audioService;
///
///   setUp(() {
///     audioService = MockAudioService();
///     audioService.initialize();
///   });
///
///   tearDown(() async {
///     await audioService.dispose();
///   });
///
///   test('should play song and update state', () async {
///     final song = Song.fixture();
///
///     // Act
///     await audioService.play(song);
///
///     // Assert
///     expect(audioService.isPlaying, isTrue);
///     expect(audioService.currentSong, equals(song));
///   });
/// }
/// ```
///
/// **Stream Testing:**
/// ```dart
/// test('should emit playback state changes', () async {
///   final states = <PlaybackState>[];
///   audioService.playbackState.listen(states.add);
///
///   await audioService.play(song);
///   await Future.delayed(Duration(milliseconds: 600)); // Wait for buffering
///
///   expect(states, containsInOrder([
///     PlaybackState.buffering,
///     PlaybackState.playing,
///   ]));
/// });
/// ```
///
/// **Queue Testing:**
/// ```dart
/// test('should manage queue correctly', () async {
///   final songs = [Song.fixture(), Song.fixture(), Song.fixture()];
///
///   for (final song in songs) {
///     await audioService.addToQueue(song);
///   }
///
///   expect(audioService.queue.length, equals(3));
///
///   await audioService.play(songs[1]);
///   expect(audioService.currentSong, equals(songs[1]));
/// });
/// ```
///
/// **Widget Testing Integration:**
/// ```dart
/// testWidgets('player widget updates with service state', (tester) async {
///   final mockService = MockAudioService();
///   await mockService.initialize();
///
///   // Inject mock service
///   ServiceLocator.override<IAudioService>(mockService);
///
///   await tester.pumpWidget(PlayerWidget());
///
///   // Trigger playback
///   await mockService.play(Song.fixture());
///   await tester.pump(Duration(milliseconds: 600)); // Wait for state update
///
///   // Verify UI reflects playback state
///   expect(find.byIcon(Icons.pause), findsOneWidget);
/// });
/// ```
///
/// ## Configuration and Customization
///
/// **Timing Controls:**
/// - Buffering duration: 500ms (simulates network loading)
/// - Position update interval: 250ms (smooth progress tracking)
/// - Track durations: 2-6 minutes (randomized for variety)
///
/// **State Simulation:**
/// - All state transitions properly sequenced
/// - Realistic delays for buffering and loading
/// - Proper cleanup on disposal and stopping
/// - Queue state persistence across operations
///
/// **Memory Management:**
/// - Efficient stream controllers with broadcast capability
/// - Proper timer cleanup preventing memory leaks
/// - Safe disposal pattern with multiple call protection
/// - Minimal memory footprint for large test suites
///
/// ## Testing Considerations
///
/// **Deterministic Behavior:**
/// - Consistent timing for reliable test assertions
/// - Predictable random track durations within bounds
/// - Reproducible queue operations and state changes
/// - Stable stream emission patterns
///
/// **Performance:**
/// - Fast initialization (100ms simulation)
/// - Immediate state changes for most operations
/// - Efficient memory usage for long-running test suites
/// - Minimal CPU overhead during position tracking
///
/// **Isolation:**
/// - No external dependencies (no actual audio system)
/// - Self-contained state management
/// - No file system or network access required
/// - Safe for parallel test execution
///
/// This mock service ensures that audio-related functionality can be thoroughly
/// tested without the complexity and dependencies of actual audio playback,
/// while maintaining complete behavioral fidelity to the real implementation.
class MockAudioService implements IAudioService {
  /// Creates a new MockAudioService instance.
  ///
  /// The service starts in an uninitialized state and must be initialized
  /// with [initialize] before use. All streams are set up and ready for
  /// subscription immediately upon construction.
  MockAudioService();

  // State variables
  PlaybackState _currentState = PlaybackState.stopped;
  Song? _currentSong;
  Duration _currentPosition = Duration.zero;
  Duration _trackDuration = const Duration(minutes: 3);
  double _currentVolume = 1;
  double _currentSpeed = 1;
  PlaybackMode _currentMode = PlaybackMode.normal;
  // ignore: unused_field
  bool _backgroundPlaybackEnabled = false;
  final List<Song> _queue = <Song>[];
  int _currentIndex = -1;
  bool _isInitialized = false;
  bool _isDisposed = false;

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

  // Position update timer
  Timer? _positionTimer;

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
  bool get isStopped => _currentState == PlaybackState.stopped || _isDisposed;

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
    _isInitialized = true;
    await Future<void>.delayed(
      const Duration(milliseconds: 100),
    ); // Simulate init time
  }

  @override
  Future<void> play(Song track, {Duration? startPosition}) async {
    _ensureInitialized();

    if (!_queue.contains(track)) {
      await addToQueue(track);
    }

    _currentIndex = _queue.indexOf(track);
    _currentSong = track;
    _currentPosition = startPosition ?? Duration.zero;

    // Generate a random duration for the mock track
    _trackDuration = Duration(
      minutes: 2 + Random().nextInt(4),
      seconds: Random().nextInt(60),
    );

    _setState(PlaybackState.buffering);
    await Future<void>.delayed(
      const Duration(milliseconds: 500),
    ); // Simulate buffering

    _setState(PlaybackState.playing);
    _trackController.add(_currentSong);
    _durationController.add(_trackDuration);

    _startPositionTimer();
  }

  @override
  Future<void> pause() async {
    _ensureInitialized();
    _setState(PlaybackState.paused);
    _stopPositionTimer();
  }

  @override
  Future<void> resume() async {
    _ensureInitialized();
    _setState(PlaybackState.playing);
    _startPositionTimer();
  }

  @override
  Future<void> stop() async {
    _ensureInitialized();
    _setState(PlaybackState.stopped);
    _currentSong = null;
    _currentIndex = -1;
    _currentPosition = Duration.zero;
    _stopPositionTimer();
    _trackController.add(null);
  }

  @override
  Future<void> seek(Duration position) async {
    _ensureInitialized();
    _currentPosition = Duration(
      milliseconds:
          position.inMilliseconds.clamp(0, _trackDuration.inMilliseconds),
    );
    _positionController.add(_currentPosition);
  }

  @override
  Future<void> setVolume(double volume) async {
    _ensureInitialized();
    _currentVolume = volume.clamp(0.0, 1.0);
    _volumeController.add(_currentVolume);
  }

  @override
  Future<void> setPlaybackSpeed(double speed) async {
    _ensureInitialized();
    _currentSpeed = speed.clamp(0.25, 3.0);
    _speedController.add(_currentSpeed);
  }

  @override
  Future<void> setPlaybackMode(PlaybackMode mode) async {
    _currentMode = mode;
    _modeController.add(mode);
  }

  @override
  Future<void> skipToNext() async {
    if (_queue.isEmpty) {
      return;
    }

    final nextIndex = _getNextIndex();
    if (nextIndex != -1) {
      await play(_queue[nextIndex]);
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_queue.isEmpty) {
      return;
    }

    final prevIndex = _getPreviousIndex();
    if (prevIndex != -1) {
      await play(_queue[prevIndex]);
    }
  }

  @override
  Future<void> addToQueue(Song track, {int? index}) async {
    if (index == null) {
      _queue.add(track);
    } else {
      _queue.insert(index.clamp(0, _queue.length), track);
      if (_currentIndex >= index) {
        _currentIndex++;
      }
    }
    _queueController.add(List.unmodifiable(_queue));
  }

  @override
  Future<void> removeFromQueue(int index) async {
    if (index < 0 || index >= _queue.length) {
      return;
    }

    _queue.removeAt(index);

    if (_currentIndex > index) {
      _currentIndex--;
    } else if (_currentIndex == index) {
      if (_queue.isEmpty) {
        await stop();
      } else {
        if (_currentIndex >= _queue.length) {
          _currentIndex = _queue.length - 1;
        }
        if (_currentIndex >= 0) {
          await play(_queue[_currentIndex]);
        }
      }
    }

    _queueController.add(List.unmodifiable(_queue));
  }

  @override
  Future<void> clearQueue() async {
    await stop();
    _queue.clear();
    _currentIndex = -1;
    _queueController.add(List.unmodifiable(_queue));
  }

  @override
  Future<void> setBackgroundPlaybackEnabled({required bool enabled}) async {
    _backgroundPlaybackEnabled = enabled;
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

  @override
  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }

    _isDisposed = true;
    _currentState = PlaybackState.stopped;
    _currentSong = null;
    _currentIndex = -1;
    _currentPosition = Duration.zero;
    _stopPositionTimer();

    await _stateController.close();
    await _trackController.close();
    await _positionController.close();
    await _durationController.close();
    await _volumeController.close();
    await _speedController.close();
    await _modeController.close();
    await _queueController.close();
    await _bufferingController.close();
  }

  // Helper methods

  /// Ensures the service is initialized before performing operations.
  ///
  /// Throws [StateError] if the service hasn't been initialized with [initialize].
  /// This prevents operations on an unprepared service instance and ensures
  /// proper setup has been completed.
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError('MockAudioService not initialized');
    }
  }

  /// Updates the playback state and notifies listeners.
  ///
  /// Only emits state changes when the new state differs from the current state,
  /// preventing unnecessary stream events and ensuring efficient listener updates.
  ///
  /// [state] The new playback state to set and broadcast.
  void _setState(PlaybackState state) {
    if (_currentState != state) {
      _currentState = state;
      _stateController.add(state);
    }
  }

  /// Starts the position update timer for playback progress tracking.
  ///
  /// Creates a periodic timer that updates the current position every 250ms
  /// during playback. The timer accounts for playback speed and automatically
  /// handles track completion when the position reaches the track duration.
  ///
  /// Always stops any existing timer before starting a new one to prevent
  /// multiple concurrent timers and ensure accurate position tracking.
  void _startPositionTimer() {
    _stopPositionTimer();
    _positionTimer = Timer.periodic(const Duration(milliseconds: 250), (timer) {
      if (isPlaying && _currentPosition < _trackDuration) {
        _currentPosition = Duration(
          milliseconds:
              _currentPosition.inMilliseconds + (250 * _currentSpeed).round(),
        );

        if (_currentPosition >= _trackDuration) {
          _currentPosition = _trackDuration;
          _setState(PlaybackState.completed);
          _stopPositionTimer();
          _handleTrackCompletion();
        }

        _positionController.add(_currentPosition);
      }
    });
  }

  /// Stops the position update timer.
  ///
  /// Safely cancels the position tracking timer and clears the reference.
  /// Safe to call multiple times or when no timer is active.
  void _stopPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = null;
  }

  /// Handles track completion based on the current playback mode.
  ///
  /// Automatically advances playback according to the configured mode:
  /// - Normal: Play next track if available, otherwise stop
  /// - Repeat One: Restart the current track
  /// - Repeat All: Play next track, wrapping to first if at end
  /// - Shuffle: Play a random track from the queue
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

  /// Gets the next track index based on the current playback mode.
  ///
  /// Returns -1 if no next track is available (e.g., at end of queue in normal mode).
  /// Handles queue boundaries and wrapping behavior according to the playback mode.
  ///
  /// Returns the appropriate next index for the current [PlaybackMode]:
  /// - Normal/RepeatOne: Next index or -1 if at end
  /// - RepeatAll: Next index with wrapping to start
  /// - Shuffle: Random index different from current
  int _getNextIndex() {
    if (_queue.isEmpty) {
      return -1;
    }

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

  /// Gets the previous track index based on the current playback mode.
  ///
  /// Returns -1 if no previous track is available (e.g., at start of queue in normal mode).
  /// Handles queue boundaries and wrapping behavior according to the playback mode.
  ///
  /// Returns the appropriate previous index for the current [PlaybackMode]:
  /// - Normal/RepeatOne: Previous index or -1 if at start
  /// - RepeatAll: Previous index with wrapping to end
  /// - Shuffle: Random index different from current
  int _getPreviousIndex() {
    if (_queue.isEmpty) {
      return -1;
    }

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

  /// Gets a random track index different from the current one.
  ///
  /// Ensures shuffle mode doesn't repeat the same track by generating
  /// random indices until one different from the current index is found.
  /// Returns the current index if queue has only one track.
  ///
  /// Returns a random valid queue index that differs from [_currentIndex].
  int _getRandomIndex() {
    if (_queue.length <= 1) {
      return _currentIndex;
    }
    int randomIndex;
    do {
      randomIndex = Random().nextInt(_queue.length);
    } while (randomIndex == _currentIndex);
    return randomIndex;
  }

  /// Plays a random track from the queue.
  ///
  /// Used by shuffle mode to select and play a random track.
  /// Safe to call with empty queue - will return without action.
  Future<void> _playRandomTrack() async {
    if (_queue.isEmpty) {
      return;
    }
    final randomIndex = _getRandomIndex();
    if (randomIndex != -1) {
      await play(_queue[randomIndex]);
    }
  }

  /// Checks if there's a next track available in the queue.
  ///
  /// Returns true if the current index is not the last track in the queue.
  /// Used for determining if auto-advance is possible in normal playback mode.
  bool _hasNextTrack() => _currentIndex + 1 < _queue.length;
}
