import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:robin_radio/data/services/performance_service.dart';

/// Centralized audio player service with proper lifecycle management and resource cleanup
class AudioPlayerService with WidgetsBindingObserver {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal();

  // Core audio player
  AudioPlayer? _player;
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

  // Public streams
  Stream<Duration> get onDurationChanged => _durationController.stream;
  Stream<Duration> get onPositionChanged => _positionController.stream;
  Stream<PlayerState> get onPlayerStateChanged => _stateController.stream;
  Stream<void> get onPlayerComplete => _completeController.stream;
  Stream<String> get onError => _errorController.stream;

  // Current state
  PlayerState _currentState = PlayerState.stopped;
  Duration _currentDuration = Duration.zero;
  Duration _currentPosition = Duration.zero;
  String? _currentUrl;
  double _currentVolume = 1.0;

  // Getters for current state
  PlayerState get currentState => _currentState;
  Duration get currentDuration => _currentDuration;
  Duration get currentPosition => _currentPosition;
  String? get currentUrl => _currentUrl;
  double get currentVolume => _currentVolume;
  bool get isPlaying => _currentState == PlayerState.playing;
  bool get isPaused => _currentState == PlayerState.paused;
  bool get isStopped => _currentState == PlayerState.stopped;

  /// Initialize the audio player service
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
          playerMode: 'centralized_service');

      if (kDebugMode) {
        print('AudioPlayerService initialized successfully');
      }
    } catch (e) {
      _errorController.add('Failed to initialize AudioPlayerService: $e');
      if (kDebugMode) {
        print('AudioPlayerService initialization error: $e');
      }
    }
  }

  /// Create and configure a new AudioPlayer instance
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

  /// Play audio from URL
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
    } catch (e) {
      final errorMessage = 'Failed to play audio: $e';
      _errorController.add(errorMessage);
      if (kDebugMode) {
        print(errorMessage);
      }
    }
  }

  /// Resume playback
  Future<void> resume() async {
    if (_isDisposed) return;

    try {
      await _ensureInitialized();
      await player.resume();
    } catch (e) {
      _errorController.add('Failed to resume: $e');
    }
  }

  /// Pause playback
  Future<void> pause() async {
    if (_isDisposed) return;

    try {
      await _ensureInitialized();
      await player.pause();
    } catch (e) {
      _errorController.add('Failed to pause: $e');
    }
  }

  /// Stop playback
  Future<void> stop() async {
    if (_isDisposed) return;

    try {
      await _ensureInitialized();
      await player.stop();
      _currentUrl = null;
    } catch (e) {
      _errorController.add('Failed to stop: $e');
    }
  }

  /// Seek to position
  Future<void> seek(Duration position) async {
    if (_isDisposed) return;

    try {
      await _ensureInitialized();
      await player.seek(position);
    } catch (e) {
      _errorController.add('Failed to seek: $e');
    }
  }

  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    if (_isDisposed) return;

    try {
      await _ensureInitialized();
      _currentVolume = volume.clamp(0.0, 1.0);
      await player.setVolume(_currentVolume);
    } catch (e) {
      _errorController.add('Failed to set volume: $e');
    }
  }

  /// Release current audio resources
  Future<void> release() async {
    if (_isDisposed) return;

    try {
      await _ensureInitialized();
      await player.release();
      _currentUrl = null;
      _currentState = PlayerState.stopped;
      _currentDuration = Duration.zero;
      _currentPosition = Duration.zero;
    } catch (e) {
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
    } catch (e) {
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
    } catch (e) {
      if (kDebugMode) {
        print('Error during AudioPlayerService disposal: $e');
      }
    }
  }

  /// Get current playback progress (0.0 to 1.0)
  double get progress {
    if (_currentDuration.inMilliseconds <= 0) return 0.0;
    return _currentPosition.inMilliseconds / _currentDuration.inMilliseconds;
  }

  /// Format duration as MM:SS
  String formatDuration(Duration duration) {
    String minutes =
        duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    String seconds =
        duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  /// Get formatted current position
  String get formattedPosition => formatDuration(_currentPosition);

  /// Get formatted current duration
  String get formattedDuration => formatDuration(_currentDuration);
}
