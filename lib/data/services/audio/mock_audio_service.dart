import 'dart:async';
import 'dart:math';

import '../../models/song.dart';
import 'audio_service_interface.dart';

/// Mock implementation of IAudioService for testing purposes
class MockAudioService implements IAudioService {
  MockAudioService();

  // State variables
  PlaybackState _currentState = PlaybackState.stopped;
  Song? _currentSong;
  Duration _currentPosition = Duration.zero;
  Duration _trackDuration = const Duration(minutes: 3);
  double _currentVolume = 1;
  double _currentSpeed = 1;
  PlaybackMode _currentMode = PlaybackMode.normal;
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
    if (_trackDuration.inMilliseconds <= 0) return 0;
    return _currentPosition.inMilliseconds / _trackDuration.inMilliseconds;
  }

  @override
  String get formattedPosition => formatDuration(_currentPosition);

  @override
  String get formattedDuration => formatDuration(_trackDuration);

  @override
  Future<void> initialize() async {
    _isInitialized = true;
    await Future.delayed(
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
    await Future.delayed(
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
    if (_queue.isEmpty) return;

    final nextIndex = _getNextIndex();
    if (nextIndex != -1) {
      await play(_queue[nextIndex]);
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_queue.isEmpty) return;

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
    if (index < 0 || index >= _queue.length) return;

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
  Future<void> setBackgroundPlaybackEnabled(bool enabled) async {
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
    if (_isDisposed) return;

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
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError('MockAudioService not initialized');
    }
  }

  void _setState(PlaybackState state) {
    if (_currentState != state) {
      _currentState = state;
      _stateController.add(state);
    }
  }

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

  void _stopPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = null;
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
}
