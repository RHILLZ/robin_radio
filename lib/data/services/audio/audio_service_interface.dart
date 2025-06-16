import 'dart:async';
import '../../exceptions/audio_service_exception.dart'
    show AudioServiceException;
import '../../models/song.dart';
import 'audio_services.dart' show AudioServiceException;

/// Playback state enumeration for audio service
enum PlaybackState {
  /// Audio is currently playing
  playing,

  /// Audio is paused
  paused,

  /// Audio is stopped
  stopped,

  /// Audio is buffering/loading
  buffering,

  /// Audio playback completed
  completed,

  /// Audio service has encountered an error
  error,
}

/// Playback mode for repeat and shuffle functionality
enum PlaybackMode {
  /// No repeat, play once
  normal,

  /// Repeat current track
  repeatOne,

  /// Repeat all tracks in queue
  repeatAll,

  /// Shuffle mode enabled
  shuffle,
}

/// Comprehensive audio service interface for centralized audio management
abstract class IAudioService {
  /// Play a specific track
  ///
  /// [track] The song to play
  /// [startPosition] Optional starting position (default: beginning)
  ///
  /// Throws [AudioServiceException] if playback fails
  Future<void> play(Song track, {Duration? startPosition});

  /// Pause current playback
  ///
  /// Throws [AudioServiceException] if pause fails
  Future<void> pause();

  /// Resume paused playback
  ///
  /// Throws [AudioServiceException] if resume fails
  Future<void> resume();

  /// Stop current playback and reset position
  ///
  /// Throws [AudioServiceException] if stop fails
  Future<void> stop();

  /// Seek to a specific position in the current track
  ///
  /// [position] The position to seek to
  ///
  /// Throws [AudioServiceException] if seek fails
  Future<void> seek(Duration position);

  /// Set playback volume
  ///
  /// [volume] Volume level between 0.0 (mute) and 1.0 (max)
  ///
  /// Throws [AudioServiceException] if volume change fails
  Future<void> setVolume(double volume);

  /// Set playback speed
  ///
  /// [speed] Playback speed multiplier (0.5 = half speed, 2.0 = double speed)
  ///
  /// Throws [AudioServiceException] if speed change fails
  Future<void> setPlaybackSpeed(double speed);

  /// Set playback mode (repeat, shuffle)
  ///
  /// [mode] The playback mode to set
  Future<void> setPlaybackMode(PlaybackMode mode);

  /// Skip to next track in queue
  ///
  /// Throws [AudioServiceException] if skip fails
  Future<void> skipToNext();

  /// Skip to previous track in queue
  ///
  /// Throws [AudioServiceException] if skip fails
  Future<void> skipToPrevious();

  /// Add track to playback queue
  ///
  /// [track] The track to add
  /// [index] Optional index to insert at (default: end of queue)
  Future<void> addToQueue(Song track, {int? index});

  /// Remove track from playback queue
  ///
  /// [index] Index of track to remove
  Future<void> removeFromQueue(int index);

  /// Clear the entire playback queue
  Future<void> clearQueue();

  /// Get current playback queue
  List<Song> get queue;

  /// Stream of current playback state
  Stream<PlaybackState> get playbackState;

  /// Stream of currently playing track
  Stream<Song?> get currentTrack;

  /// Stream of playback position updates
  Stream<Duration> get position;

  /// Stream of track duration
  Stream<Duration> get duration;

  /// Stream of volume changes
  Stream<double> get volume;

  /// Stream of playback speed changes
  Stream<double> get playbackSpeed;

  /// Stream of playback mode changes
  Stream<PlaybackMode> get playbackMode;

  /// Stream of queue changes
  Stream<List<Song>> get queueStream;

  /// Stream of buffering progress (0.0 to 1.0)
  Stream<double> get bufferingProgress;

  /// Current playback state
  PlaybackState get currentState;

  /// Currently playing track (null if none)
  Song? get currentSong;

  /// Current playback position
  Duration get currentPosition;

  /// Current track duration
  Duration get trackDuration;

  /// Current volume level (0.0 to 1.0)
  double get currentVolume;

  /// Current playback speed
  double get currentSpeed;

  /// Current playback mode
  PlaybackMode get currentMode;

  /// Whether audio is currently playing
  bool get isPlaying;

  /// Whether audio is currently paused
  bool get isPaused;

  /// Whether audio is currently stopped
  bool get isStopped;

  /// Whether audio is currently buffering
  bool get isBuffering;

  /// Progress percentage (0.0 to 1.0)
  double get progress;

  /// Initialize the audio service
  ///
  /// Should be called before using any other methods
  Future<void> initialize();

  /// Dispose of the audio service and clean up resources
  ///
  /// Should be called when the service is no longer needed
  Future<void> dispose();

  /// Enable/disable background playback
  ///
  /// [enabled] Whether background playback should be enabled
  Future<void> setBackgroundPlaybackEnabled(bool enabled);

  /// Get formatted string for current position (e.g., "02:30")
  String get formattedPosition;

  /// Get formatted string for current duration (e.g., "03:45")
  String get formattedDuration;

  /// Format a duration as a string (e.g., "02:30")
  String formatDuration(Duration duration);
}
