import 'package:equatable/equatable.dart';

import '../../models/song.dart';
import 'audio_service_interface.dart';

/// Unified immutable state class for audio playback.
///
/// Consolidates 9 separate state values into a single immutable object,
/// enabling efficient state management with BehaviorSubject and reducing
/// the overhead of multiple StreamControllers.
///
/// ## Optimization Rationale
///
/// Previously, BackgroundAudioService maintained 9 separate StreamControllers:
/// - stateController, trackController, positionController, durationController
/// - volumeController, speedController, modeController, queueController
/// - bufferingController
///
/// This unified state approach provides:
/// - **Reduced memory overhead**: Single BehaviorSubject vs 9 StreamControllers
/// - **Atomic state updates**: All related state changes emit together
/// - **Simplified disposal**: One subscription to manage instead of 9
/// - **Better debugging**: Complete state snapshot available at any point
/// - **Immutable by design**: Prevents accidental state mutations
///
/// Individual streams can be derived using `.map()` operators on the
/// unified stream, maintaining backward compatibility with the IAudioService
/// interface while gaining the benefits of consolidated state.
class AudioState extends Equatable {
  /// Creates an AudioState with the given values.
  ///
  /// All parameters have sensible defaults matching the initial state
  /// of a fresh audio player instance.
  const AudioState({
    this.playbackState = PlaybackState.stopped,
    this.currentTrack,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.volume = 1.0,
    this.speed = 1.0,
    this.mode = PlaybackMode.normal,
    this.queue = const <Song>[],
    this.bufferingProgress = 0.0,
  });

  /// The current playback state (playing, paused, stopped, etc.)
  final PlaybackState playbackState;

  /// The currently loaded track, or null if no track is loaded
  final Song? currentTrack;

  /// Current playback position within the track
  final Duration position;

  /// Total duration of the current track
  final Duration duration;

  /// Current volume level (0.0 to 1.0)
  final double volume;

  /// Current playback speed multiplier (0.5 to 2.0 typically)
  final double speed;

  /// Current playback mode (normal, repeat, shuffle, etc.)
  final PlaybackMode mode;

  /// The current playback queue
  final List<Song> queue;

  /// Current buffering progress (0.0 to 1.0)
  final double bufferingProgress;

  /// Creates a copy of this state with the given fields replaced.
  ///
  /// This is the primary method for creating new state instances.
  /// Since AudioState is immutable, all modifications create new instances.
  ///
  /// Example:
  /// ```dart
  /// final newState = currentState.copyWith(
  ///   playbackState: PlaybackState.playing,
  ///   position: Duration(seconds: 30),
  /// );
  /// ```
  AudioState copyWith({
    PlaybackState? playbackState,
    Song? currentTrack,
    bool clearCurrentTrack = false,
    Duration? position,
    Duration? duration,
    double? volume,
    double? speed,
    PlaybackMode? mode,
    List<Song>? queue,
    double? bufferingProgress,
  }) =>
      AudioState(
        playbackState: playbackState ?? this.playbackState,
        currentTrack:
            clearCurrentTrack ? null : (currentTrack ?? this.currentTrack),
        position: position ?? this.position,
        duration: duration ?? this.duration,
        volume: volume ?? this.volume,
        speed: speed ?? this.speed,
        mode: mode ?? this.mode,
        queue: queue ?? this.queue,
        bufferingProgress: bufferingProgress ?? this.bufferingProgress,
      );

  /// Initial state with all default values.
  ///
  /// Use this as the seed value for BehaviorSubject initialization.
  static const AudioState initial = AudioState();

  /// Convenience getter: Returns true if currently playing
  bool get isPlaying => playbackState == PlaybackState.playing;

  /// Convenience getter: Returns true if currently paused
  bool get isPaused => playbackState == PlaybackState.paused;

  /// Convenience getter: Returns true if stopped
  bool get isStopped => playbackState == PlaybackState.stopped;

  /// Convenience getter: Returns true if buffering
  bool get isBuffering => playbackState == PlaybackState.buffering;

  /// Convenience getter: Returns true if completed
  bool get isCompleted => playbackState == PlaybackState.completed;

  /// Convenience getter: Returns true if in error state
  bool get hasError => playbackState == PlaybackState.error;

  /// Calculates playback progress as a value between 0.0 and 1.0.
  ///
  /// Returns 0.0 if duration is zero to avoid division by zero.
  double get progress {
    if (duration.inMilliseconds == 0) {
      return 0.0;
    }
    return position.inMilliseconds / duration.inMilliseconds;
  }

  /// Formats the current position as a human-readable string (MM:SS or HH:MM:SS).
  String get formattedPosition => _formatDuration(position);

  /// Formats the total duration as a human-readable string (MM:SS or HH:MM:SS).
  String get formattedDuration => _formatDuration(duration);

  /// Formats a duration as MM:SS or HH:MM:SS if over an hour.
  static String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  @override
  List<Object?> get props => [
        playbackState,
        currentTrack,
        position,
        duration,
        volume,
        speed,
        mode,
        queue,
        bufferingProgress,
      ];

  @override
  String toString() => 'AudioState('
      'playbackState: $playbackState, '
      'currentTrack: ${currentTrack?.songName ?? 'null'}, '
      'position: $formattedPosition, '
      'duration: $formattedDuration, '
      'volume: $volume, '
      'speed: $speed, '
      'mode: $mode, '
      'queueLength: ${queue.length}, '
      'bufferingProgress: $bufferingProgress'
      ')';
}
