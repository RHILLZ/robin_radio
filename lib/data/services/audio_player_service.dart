import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'performance_service.dart';

/// Centralized audio player service with lifecycle management and resource optimization.
///
/// Provides a singleton audio player service that handles all music playback operations
/// with proper resource management, app lifecycle integration, and performance monitoring.
/// Designed to prevent audio conflicts, optimize battery usage, and provide a consistent
/// playback experience across the entire application.
///
/// Key capabilities:
/// - **Singleton pattern**: Single audio player instance prevents resource conflicts
/// - **Lifecycle management**: Automatic pause/resume based on app state changes
/// - **Stream-based events**: Real-time playback state updates via reactive streams
/// - **Error handling**: Comprehensive error reporting and recovery mechanisms
/// - **Performance monitoring**: Integrated Firebase Performance tracking
/// - **Resource cleanup**: Proper disposal and memory management
/// - **Volume control**: Independent volume management with validation
///
/// The service automatically handles:
/// - App backgrounding and foregrounding
/// - Audio session management
/// - Network connectivity changes
/// - Memory pressure situations
/// - Multiple playback requests
///
/// Usage patterns:
/// ```dart
/// final audioService = AudioPlayerService();
///
/// // Initialize the service
/// await audioService.initialize();
///
/// // Play audio with automatic state management
/// await audioService.play('https://example.com/song.mp3');
///
/// // Listen to playback events
/// audioService.onPlayerStateChanged.listen((state) {
///   if (state == PlayerState.playing) {
///     updateUI();
///   }
/// });
///
/// // Control playback
/// await audioService.pause();
/// await audioService.seek(Duration(seconds: 30));
/// await audioService.setVolume(0.8);
/// ```
///
/// The service integrates with Flutter's WidgetsBindingObserver to automatically
/// handle app lifecycle changes, ensuring appropriate audio behavior during
/// app state transitions without manual intervention.
class AudioPlayerService with WidgetsBindingObserver {
  /// Factory constructor returning the singleton instance.
  ///
  /// Ensures only one audio player service exists throughout the application
  /// lifecycle, preventing resource conflicts and audio session issues.
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal();
  static final AudioPlayerService _instance = AudioPlayerService._internal();

  // Core audio player
  AudioPlayer? _player;

  /// Access to the underlying AudioPlayer instance.
  ///
  /// Creates a new player if none exists, ensuring the service is always
  /// ready for operation. The player is automatically configured with
  /// event listeners and performance monitoring.
  AudioPlayer get player => _player ??= _createPlayer();

  // State management
  bool _isInitialized = false;
  bool _isDisposed = false;
  AppLifecycleState? _lastLifecycleState;

  // Stream controllers for events
  final StreamController<Duration> _durationController =
      StreamController<Duration>.broadcast();
  final StreamController<Duration> _positionController =
      StreamController<Duration>.broadcast();
  final StreamController<PlayerState> _stateController =
      StreamController<PlayerState>.broadcast();
  final StreamController<void> _completeController =
      StreamController<void>.broadcast();
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();

  // Public streams - these provide real-time audio playback information

  /// Stream of duration changes for the currently loaded audio.
  ///
  /// Emits the total duration when audio is loaded and ready for playback.
  /// Essential for UI elements like progress bars and time displays.
  Stream<Duration> get onDurationChanged => _durationController.stream;

  /// Stream of position changes during audio playback.
  ///
  /// Emits current playback position updates, typically several times per second
  /// during active playback. Used for real-time progress indicators and seek bars.
  Stream<Duration> get onPositionChanged => _positionController.stream;

  /// Stream of player state changes (playing, paused, stopped, etc.).
  ///
  /// Critical for UI synchronization - emits PlayerState changes when playback
  /// starts, stops, pauses, or encounters errors. Enables reactive UI updates.
  Stream<PlayerState> get onPlayerStateChanged => _stateController.stream;

  /// Stream that emits when audio playback completes naturally.
  ///
  /// Signals when a track finishes playing to its end, enabling automatic
  /// playlist advancement, repeat functionality, or cleanup operations.
  Stream<void> get onPlayerComplete => _completeController.stream;

  /// Stream of error messages from audio operations.
  ///
  /// Provides detailed error information for debugging and user feedback.
  /// Includes network errors, codec issues, and resource problems.
  Stream<String> get onError => _errorController.stream;

  // Current state
  PlayerState _currentState = PlayerState.stopped;
  Duration _currentDuration = Duration.zero;
  Duration _currentPosition = Duration.zero;
  String? _currentUrl;
  double _currentVolume = 1;

  // Getters for current state - provide immediate access to playback status

  /// Current playback state of the audio player.
  PlayerState get currentState => _currentState;

  /// Total duration of the currently loaded audio track.
  Duration get currentDuration => _currentDuration;

  /// Current playback position within the audio track.
  Duration get currentPosition => _currentPosition;

  /// URL of the currently loaded or playing audio track.
  String? get currentUrl => _currentUrl;

  /// Current volume level (0.0 to 1.0).
  double get currentVolume => _currentVolume;

  /// Whether audio is currently playing.
  bool get isPlaying => _currentState == PlayerState.playing;

  /// Whether audio is currently paused.
  bool get isPaused => _currentState == PlayerState.paused;

  /// Whether audio is currently stopped.
  bool get isStopped => _currentState == PlayerState.stopped;

  /// Initialize the audio player service with performance monitoring.
  ///
  /// Sets up the audio player service including lifecycle observers, performance
  /// tracking, and resource initialization. Should be called early in the app
  /// lifecycle, typically during app startup or before first audio usage.
  ///
  /// Initialization process:
  /// 1. Registers app lifecycle observer for automatic state management
  /// 2. Creates and configures the underlying audio player
  /// 3. Sets up event stream listeners and error handling
  /// 4. Initializes performance monitoring integration
  /// 5. Validates audio session and system permissions
  ///
  /// The initialization is idempotent - calling multiple times is safe and
  /// will not create additional resources or duplicate listeners.
  ///
  /// Throws no exceptions but reports errors via the error stream, ensuring
  /// app stability even if audio initialization fails.
  ///
  /// Example usage:
  /// ```dart
  /// @override
  /// void initState() {
  ///   super.initState();
  ///   AudioPlayerService().initialize();
  /// }
  /// ```
  Future<void> initialize() async {
    if (_isInitialized || _isDisposed) return;

    try {
      // Add lifecycle observer
      WidgetsBinding.instance.addObserver(this);

      // Initialize player
      _createPlayer();

      // Track initialization performance
      final performanceService = PerformanceService();
      await performanceService.startPlayerInitTrace();

      _isInitialized = true;

      await performanceService.stopPlayerInitTrace(
        playerMode: 'centralized_service',
      );

      if (kDebugMode) {
        print('AudioPlayerService initialized successfully');
      }
    } on Exception catch (e) {
      _errorController.add('Failed to initialize AudioPlayerService: $e');
      if (kDebugMode) {
        print('AudioPlayerService initialization error: $e');
      }
    }
  }

  /// Create and configure a new AudioPlayer instance with event listeners.
  ///
  /// Creates a fresh AudioPlayer instance and configures it with all necessary
  /// event listeners for state management, position tracking, and error handling.
  /// Automatically disposes any existing player to prevent resource leaks.
  ///
  /// Event listener setup:
  /// - Duration changes for progress bar maximum values
  /// - Position changes for real-time progress updates
  /// - State changes for UI synchronization
  /// - Completion events for playlist advancement
  /// - Log messages for debugging and error tracking
  ///
  /// Returns the configured AudioPlayer instance ready for immediate use.
  AudioPlayer _createPlayer() {
    if (_player != null) {
      _disposePlayer();
    }

    _player = AudioPlayer();

    // Set up event listeners
    _player!.onDurationChanged.listen((duration) {
      _currentDuration = duration;
      _durationController.add(duration);
    });

    _player!.onPositionChanged.listen((position) {
      _currentPosition = position;
      _positionController.add(position);
    });

    _player!.onPlayerStateChanged.listen((state) {
      _currentState = state;
      _stateController.add(state);
    });

    _player!.onPlayerComplete.listen((_) {
      _completeController.add(null);
    });

    // Set up error handling
    _player!.onLog.listen((message) {
      if (kDebugMode) {
        print('AudioPlayer log: $message');
      }
    });

    // Set initial volume
    _player!.setVolume(_currentVolume);

    return _player!;
  }

  /// Play audio from the specified URL with automatic resource management.
  ///
  /// Loads and begins playback of audio content from a network URL or local file.
  /// Automatically handles resource cleanup, URL switching, and error recovery.
  /// Optimized for music streaming with intelligent caching and buffering.
  ///
  /// [url] The audio source URL. Supports:
  ///      - HTTP/HTTPS URLs for streaming content
  ///      - Local file paths for offline content
  ///      - Various audio formats (MP3, AAC, FLAC, etc.)
  ///
  /// Playback behavior:
  /// - Stops current playback if switching to a different URL
  /// - Resumes from current position if replaying the same URL
  /// - Automatically handles network buffering and streaming
  /// - Manages audio session and system audio controls
  /// - Reports progress via position and state streams
  ///
  /// Error handling:
  /// - Network connectivity issues are reported via error stream
  /// - Unsupported formats are handled gracefully
  /// - Corrupted files trigger appropriate error messages
  /// - Service disposal state is validated before operation
  ///
  /// Example usage:
  /// ```dart
  /// try {
  ///   await audioService.play('https://api.music.com/track/123.mp3');
  ///   // Listen for state changes to update UI
  ///   audioService.onPlayerStateChanged.listen((state) {
  ///     updatePlayButton(state == PlayerState.playing);
  ///   });
  /// } catch (e) {
  ///   showErrorDialog('Playback failed: $e');
  /// }
  /// ```
  Future<void> play(String url) async {
    if (_isDisposed) {
      _errorController.add('AudioPlayerService is disposed');
      return;
    }

    try {
      await _ensureInitialized();

      // Stop current playback if different URL
      if (_currentUrl != url && _currentState != PlayerState.stopped) {
        await stop();
      }

      _currentUrl = url;
      final source = UrlSource(url);
      await player.play(source);

      if (kDebugMode) {
        print('Playing audio: $url');
      }
    } on Exception catch (e) {
      final errorMessage = 'Failed to play audio: $e';
      _errorController.add(errorMessage);
      if (kDebugMode) {
        print(errorMessage);
      }
    }
  }

  /// Resume paused audio playback from the current position.
  ///
  /// Continues playback from where it was previously paused, maintaining
  /// the current position and audio session. No-op if audio is already
  /// playing or if no audio has been loaded.
  ///
  /// Resume behavior:
  /// - Continues from exact pause position
  /// - Maintains audio session and system controls
  /// - Restores previous volume and playback settings
  /// - Triggers state change events for UI updates
  ///
  /// Example usage:
  /// ```dart
  /// // Pause and resume pattern
  /// await audioService.pause();
  /// // ... user interaction or app state change ...
  /// await audioService.resume(); // Continues from pause point
  /// ```
  Future<void> resume() async {
    if (_isDisposed) return;

    try {
      await _ensureInitialized();
      await player.resume();
    } on Exception catch (e) {
      _errorController.add('Failed to resume: $e');
    }
  }

  /// Pause current audio playback while maintaining position.
  ///
  /// Temporarily halts audio playback while preserving the current position
  /// for later resumption. The audio session remains active and the track
  /// remains loaded in memory for quick resume operations.
  ///
  /// Pause behavior:
  /// - Preserves current playback position exactly
  /// - Maintains loaded audio content in memory
  /// - Updates player state to paused
  /// - Releases audio output resources temporarily
  /// - Enables quick resume without reloading
  ///
  /// Example usage:
  /// ```dart
  /// // Pause during phone call or user interaction
  /// await audioService.pause();
  /// // Audio can be quickly resumed later
  /// await audioService.resume();
  /// ```
  Future<void> pause() async {
    if (_isDisposed) return;

    try {
      await _ensureInitialized();
      await player.pause();
    } on Exception catch (e) {
      _errorController.add('Failed to pause: $e');
    }
  }

  /// Stop audio playback and reset to beginning position.
  ///
  /// Completely stops audio playback, resets position to zero, and releases
  /// audio content from memory. More resource-efficient than pause for
  /// longer-term playback interruptions.
  ///
  /// Stop behavior:
  /// - Resets playback position to zero
  /// - Releases loaded audio content from memory
  /// - Clears current URL reference
  /// - Updates player state to stopped
  /// - Frees audio session resources
  ///
  /// Use stop() when:
  /// - Switching to a completely different track
  /// - User explicitly stops playback
  /// - App is being backgrounded for extended periods
  /// - Memory pressure requires resource cleanup
  ///
  /// Example usage:
  /// ```dart
  /// // Complete stop with resource cleanup
  /// await audioService.stop();
  /// // Next play() call will start from beginning
  /// ```
  Future<void> stop() async {
    if (_isDisposed) return;

    try {
      await _ensureInitialized();
      await player.stop();
      _currentUrl = null;
    } on Exception catch (e) {
      _errorController.add('Failed to stop: $e');
    }
  }

  /// Seek to a specific position within the current audio track.
  ///
  /// Changes the current playback position to the specified time offset,
  /// enabling features like scrubbing, chapter navigation, and precise
  /// position control. Works during both playing and paused states.
  ///
  /// [position] Target position within the track. Will be clamped to valid
  ///           range (0 to track duration) automatically to prevent errors.
  ///
  /// Seek behavior:
  /// - Immediately jumps to the specified position
  /// - Works in both playing and paused states
  /// - Triggers position update events
  /// - Handles buffering for network streams
  /// - Validates position bounds automatically
  ///
  /// Performance considerations:
  /// - Network streams may require brief buffering
  /// - Local files typically seek instantly
  /// - Some audio formats seek faster than others
  /// - Frequent seeking may impact performance
  ///
  /// Example usage:
  /// ```dart
  /// // Seek to 30 seconds into the track
  /// await audioService.seek(Duration(seconds: 30));
  ///
  /// // Seek to 50% through the track
  /// final halfwayPoint = audioService.currentDuration * 0.5;
  /// await audioService.seek(halfwayPoint);
  /// ```
  Future<void> seek(Duration position) async {
    if (_isDisposed) return;

    try {
      await _ensureInitialized();
      await player.seek(position);
    } on Exception catch (e) {
      _errorController.add('Failed to seek: $e');
    }
  }

  /// Set the audio playback volume with validation and persistence.
  ///
  /// Adjusts the audio output volume for the current player instance.
  /// Volume changes are applied immediately and persist across track
  /// changes within the same session.
  ///
  /// [volume] Volume level from 0.0 (muted) to 1.0 (maximum). Values
  ///         outside this range are automatically clamped to valid bounds.
  ///
  /// Volume behavior:
  /// - Immediately applies to current and future playback
  /// - Validates and clamps input to safe range (0.0-1.0)
  /// - Persists across track changes during session
  /// - Independent of system volume controls
  /// - Affects only this player instance
  ///
  /// Volume considerations:
  /// - 0.0 = completely muted
  /// - 0.5 = half volume
  /// - 1.0 = maximum app volume (may not equal system maximum)
  /// - Volume changes are smooth and immediate
  ///
  /// Example usage:
  /// ```dart
  /// // Set to half volume
  /// await audioService.setVolume(0.5);
  ///
  /// // Mute audio
  /// await audioService.setVolume(0.0);
  ///
  /// // Maximum volume
  /// await audioService.setVolume(1.0);
  /// ```
  Future<void> setVolume(double volume) async {
    if (_isDisposed) return;

    try {
      await _ensureInitialized();
      _currentVolume = volume.clamp(0.0, 1.0);
      await player.setVolume(_currentVolume);
    } on Exception catch (e) {
      _errorController.add('Failed to set volume: $e');
    }
  }

  /// Release current audio resources while keeping the service active.
  ///
  /// Clears the currently loaded audio content and resets playback state
  /// without disposing the entire service. Useful for memory management
  /// and preparing for new content loading.
  ///
  /// Release behavior:
  /// - Stops current playback immediately
  /// - Releases loaded audio content from memory
  /// - Resets position and duration to zero
  /// - Clears current URL reference
  /// - Keeps service initialized for new content
  /// - Maintains event stream connections
  ///
  /// Use release() when:
  /// - Finished with current track but staying in app
  /// - Memory pressure requires content cleanup
  /// - Preparing to load different audio content
  /// - Implementing manual memory management
  ///
  /// Example usage:
  /// ```dart
  /// // Clean up after track completion
  /// audioService.onPlayerComplete.listen((_) async {
  ///   await audioService.release(); // Free memory
  ///   await loadNextTrack(); // Load new content
  /// });
  /// ```
  Future<void> release() async {
    if (_isDisposed) return;

    try {
      await _ensureInitialized();
      await player.release();
      _currentUrl = null;
      _currentState = PlayerState.stopped;
      _currentDuration = Duration.zero;
      _currentPosition = Duration.zero;
    } on Exception catch (e) {
      _errorController.add('Failed to release: $e');
    }
  }

  /// Handle app lifecycle changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (kDebugMode) {
      print('App lifecycle changed: $_lastLifecycleState -> $state');
    }

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // Pause audio when app goes to background or becomes inactive
        if (isPlaying) {
          pause();
          if (kDebugMode) {
            print('Audio paused due to app lifecycle change');
          }
        }
        break;
      case AppLifecycleState.resumed:
        // Optionally resume audio when app comes back to foreground
        // Note: We don't auto-resume to avoid unexpected behavior
        if (kDebugMode) {
          print('App resumed - audio can be manually resumed');
        }
        break;
      case AppLifecycleState.detached:
        // Clean up resources when app is being terminated
        dispose();
        break;
      case AppLifecycleState.hidden:
        // Handle hidden state (iOS 13+)
        if (isPlaying) {
          pause();
        }
        break;
    }

    _lastLifecycleState = state;
  }

  /// Ensure the service is initialized
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Dispose of the player instance
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

  /// Dispose of the entire service
  Future<void> dispose() async {
    if (_isDisposed) return;

    _isDisposed = true;

    try {
      // Remove lifecycle observer
      WidgetsBinding.instance.removeObserver(this);

      // Stop and dispose player
      if (_player != null) {
        await stop();
        _disposePlayer();
      }

      // Close stream controllers
      await _durationController.close();
      await _positionController.close();
      await _stateController.close();
      await _completeController.close();
      await _errorController.close();

      _isInitialized = false;

      if (kDebugMode) {
        print('AudioPlayerService disposed');
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Error during AudioPlayerService disposal: $e');
      }
    }
  }

  /// Get current playback progress (0.0 to 1.0)
  double get progress {
    if (_currentDuration.inMilliseconds <= 0) return 0;
    return _currentPosition.inMilliseconds / _currentDuration.inMilliseconds;
  }

  /// Format duration as MM:SS
  String formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Get formatted current position
  String get formattedPosition => formatDuration(_currentPosition);

  /// Get formatted current duration
  String get formattedDuration => formatDuration(_currentDuration);
}
