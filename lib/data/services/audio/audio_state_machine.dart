import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

import '../../models/song.dart';
import 'audio_service_interface.dart';

/// Represents a discrete state in the audio playback state machine.
///
/// Each state encapsulates all the information needed to render the UI
/// and determine valid state transitions.
///
/// Subclasses:
/// - [IdleState]: No track loaded, player inactive
/// - [LoadingState]: Preparing to play a track
/// - [BufferingState]: Track is buffering during playback
/// - [PlayingState]: Actively playing audio
/// - [PausedState]: Playback suspended but resumable
/// - [ErrorState]: Playback failed with recoverable error
/// - [CompletedState]: Track finished playing
abstract class AudioPlayerState extends Equatable {
  /// Creates an audio player state
  const AudioPlayerState();

  /// Whether playback is active (playing or buffering)
  bool get isActive => false;

  /// Whether user controls should be enabled
  bool get controlsEnabled => true;

  /// Human-readable state name for debugging
  String get stateName;
}

/// Initial idle state - no track loaded, player inactive.
class IdleState extends AudioPlayerState {
  /// Creates an idle state
  const IdleState();

  @override
  String get stateName => 'idle';

  @override
  List<Object?> get props => [];
}

/// Loading state - preparing to play a track.
class LoadingState extends AudioPlayerState {
  /// Creates a loading state for the given track
  const LoadingState({required this.track});

  /// The track being loaded
  final Song track;

  @override
  bool get controlsEnabled => false;

  @override
  String get stateName => 'loading';

  @override
  List<Object?> get props => [track];
}

/// Buffering state - track is buffering during playback.
class BufferingState extends AudioPlayerState {
  /// Creates a buffering state
  const BufferingState({
    required this.track,
    required this.position,
    required this.duration,
    this.bufferProgress = 0.0,
  });

  /// The track being buffered
  final Song track;

  /// Current playback position
  final Duration position;

  /// Total track duration
  final Duration duration;

  /// Buffering progress (0.0 to 1.0)
  final double bufferProgress;

  @override
  bool get isActive => true;

  @override
  String get stateName => 'buffering';

  @override
  List<Object?> get props => [track, position, duration, bufferProgress];
}

/// Playing state - actively playing audio.
class PlayingState extends AudioPlayerState {
  /// Creates a playing state
  const PlayingState({
    required this.track,
    required this.position,
    required this.duration,
    this.volume = 1.0,
    this.speed = 1.0,
  });

  /// The track being played
  final Song track;

  /// Current playback position
  final Duration position;

  /// Total track duration
  final Duration duration;

  /// Current volume (0.0 to 1.0)
  final double volume;

  /// Current playback speed
  final double speed;

  @override
  bool get isActive => true;

  @override
  String get stateName => 'playing';

  /// Playback progress as percentage (0.0 to 1.0)
  double get progress {
    if (duration.inMilliseconds == 0) return 0.0;
    return position.inMilliseconds / duration.inMilliseconds;
  }

  @override
  List<Object?> get props => [track, position, duration, volume, speed];
}

/// Paused state - playback suspended but resumable.
class PausedState extends AudioPlayerState {
  /// Creates a paused state
  const PausedState({
    required this.track,
    required this.position,
    required this.duration,
  });

  /// The track that was playing
  final Song track;

  /// Position where playback was paused
  final Duration position;

  /// Total track duration
  final Duration duration;

  /// Playback progress as percentage (0.0 to 1.0)
  double get progress {
    if (duration.inMilliseconds == 0) return 0.0;
    return position.inMilliseconds / duration.inMilliseconds;
  }

  @override
  String get stateName => 'paused';

  @override
  List<Object?> get props => [track, position, duration];
}

/// Error state - playback failed with recoverable error.
class ErrorState extends AudioPlayerState {
  /// Creates an error state
  const ErrorState({
    required this.message,
    required this.errorCode,
    this.lastTrack,
  });

  /// Error message describing what went wrong
  final String message;

  /// Error code for programmatic handling
  final String errorCode;

  /// The last track that was playing before the error
  final Song? lastTrack;

  @override
  String get stateName => 'error';

  @override
  List<Object?> get props => [message, errorCode, lastTrack];
}

/// Completed state - track finished playing.
class CompletedState extends AudioPlayerState {
  /// Creates a completed state
  const CompletedState({
    required this.track,
    required this.duration,
  });

  /// The track that finished playing
  final Song track;

  /// The total duration of the completed track
  final Duration duration;

  @override
  String get stateName => 'completed';

  @override
  List<Object?> get props => [track, duration];
}

/// State machine for managing audio playback state transitions.
///
/// Provides a structured approach to state management with:
/// - **Type-safe states**: Using abstract classes for pattern matching
/// - **Atomic transitions**: State changes are validated before emission
/// - **Reactive streams**: Derived streams for specific state properties
/// - **Debug logging**: Optional logging for development debugging
///
/// ## State Transitions
///
/// ```
/// IdleState
///    |
///    v (play)
/// LoadingState
///    |
///    v (loaded)
/// BufferingState <---> PlayingState
///    |                    |
///    |                    v (pause)
///    |                 PausedState
///    |                    |
///    v                    v
/// ErrorState          CompletedState
///    |                    |
///    +-----> IdleState <--+
/// ```
///
/// ## Usage
///
/// ```dart
/// final stateMachine = AudioStateMachine();
///
/// // Listen to state changes
/// stateMachine.stateStream.listen((state) {
///   if (state is PlayingState) {
///     print('Now playing: ${state.track.songName}');
///   } else if (state is ErrorState) {
///     print('Error: ${state.message}');
///   }
/// });
///
/// // Transition states
/// stateMachine.transitionTo(LoadingState(track: song));
/// stateMachine.transitionTo(PlayingState(
///   track: song,
///   position: Duration.zero,
///   duration: song.duration,
/// ));
/// ```
class AudioStateMachine {
  /// Creates a new AudioStateMachine with an optional initial state.
  AudioStateMachine({
    AudioPlayerState initialState = const IdleState(),
    this.enableDebugLogging = false,
  }) : _stateSubject = BehaviorSubject<AudioPlayerState>.seeded(initialState);

  /// Whether to log state transitions in debug mode
  final bool enableDebugLogging;

  /// Internal state subject for reactive state management
  final BehaviorSubject<AudioPlayerState> _stateSubject;

  /// Stream of state changes for reactive UI updates
  Stream<AudioPlayerState> get stateStream => _stateSubject.stream;

  /// Current state snapshot
  AudioPlayerState get currentState => _stateSubject.value;

  /// Stream of playing state changes
  Stream<bool> get isPlayingStream =>
      stateStream.map((s) => s is PlayingState).distinct();

  /// Stream of current track changes
  Stream<Song?> get currentTrackStream => stateStream.map((state) {
        if (state is LoadingState) return state.track;
        if (state is BufferingState) return state.track;
        if (state is PlayingState) return state.track;
        if (state is PausedState) return state.track;
        if (state is CompletedState) return state.track;
        if (state is ErrorState) return state.lastTrack;
        return null;
      }).distinct();

  /// Stream of position updates
  Stream<Duration> get positionStream => stateStream.map((state) {
        if (state is BufferingState) return state.position;
        if (state is PlayingState) return state.position;
        if (state is PausedState) return state.position;
        return Duration.zero;
      }).distinct();

  /// Stream of duration updates
  Stream<Duration> get durationStream => stateStream.map((state) {
        if (state is BufferingState) return state.duration;
        if (state is PlayingState) return state.duration;
        if (state is PausedState) return state.duration;
        if (state is CompletedState) return state.duration;
        return Duration.zero;
      }).distinct();

  /// Whether the player is currently active (playing or buffering)
  bool get isActive => currentState.isActive;

  /// Whether controls are enabled for the current state
  bool get controlsEnabled => currentState.controlsEnabled;

  /// Transition to a new state with validation.
  ///
  /// Returns true if the transition was valid and applied, false otherwise.
  bool transitionTo(AudioPlayerState newState) {
    final oldState = currentState;

    // Validate the transition
    if (!_isValidTransition(oldState, newState)) {
      if (enableDebugLogging && kDebugMode) {
        debugPrint(
          'AudioStateMachine: Invalid transition from '
          '${oldState.stateName} to ${newState.stateName}',
        );
      }
      return false;
    }

    // Emit the new state
    _stateSubject.add(newState);

    if (enableDebugLogging && kDebugMode) {
      debugPrint(
        'AudioStateMachine: ${oldState.stateName} -> ${newState.stateName}',
      );
    }

    return true;
  }

  /// Update position for active playback states.
  ///
  /// This is a convenience method for frequent position updates that
  /// preserves other state properties.
  void updatePosition(Duration position) {
    final state = currentState;

    if (state is PlayingState) {
      _stateSubject.add(
        PlayingState(
          track: state.track,
          position: position,
          duration: state.duration,
          volume: state.volume,
          speed: state.speed,
        ),
      );
    } else if (state is BufferingState) {
      _stateSubject.add(
        BufferingState(
          track: state.track,
          position: position,
          duration: state.duration,
          bufferProgress: state.bufferProgress,
        ),
      );
    } else if (state is PausedState) {
      _stateSubject.add(
        PausedState(
          track: state.track,
          position: position,
          duration: state.duration,
        ),
      );
    }
  }

  /// Update duration for active playback states.
  void updateDuration(Duration duration) {
    final state = currentState;

    if (state is PlayingState) {
      _stateSubject.add(
        PlayingState(
          track: state.track,
          position: state.position,
          duration: duration,
          volume: state.volume,
          speed: state.speed,
        ),
      );
    } else if (state is BufferingState) {
      _stateSubject.add(
        BufferingState(
          track: state.track,
          position: state.position,
          duration: duration,
          bufferProgress: state.bufferProgress,
        ),
      );
    } else if (state is PausedState) {
      _stateSubject.add(
        PausedState(
          track: state.track,
          position: state.position,
          duration: duration,
        ),
      );
    }
  }

  /// Reset the state machine to idle state.
  void reset() {
    _stateSubject.add(const IdleState());
    if (enableDebugLogging && kDebugMode) {
      debugPrint('AudioStateMachine: Reset to idle');
    }
  }

  /// Dispose of the state machine and clean up resources.
  Future<void> dispose() async {
    await _stateSubject.close();
  }

  /// Validate state transitions based on the state diagram.
  bool _isValidTransition(
    AudioPlayerState from,
    AudioPlayerState to,
  ) {
    // Allow any state to transition to ErrorState or IdleState
    if (to is ErrorState || to is IdleState) return true;

    if (from is IdleState) {
      return to is LoadingState;
    }
    if (from is LoadingState) {
      return to is BufferingState || to is PlayingState;
    }
    if (from is BufferingState) {
      return to is PlayingState || to is PausedState;
    }
    if (from is PlayingState) {
      return to is PausedState ||
          to is BufferingState ||
          to is CompletedState ||
          to is PlayingState;
    }
    if (from is PausedState) {
      return to is PlayingState || to is BufferingState || to is LoadingState;
    }
    if (from is CompletedState) {
      return to is LoadingState || to is PlayingState;
    }
    if (from is ErrorState) {
      return to is LoadingState;
    }

    return false;
  }
}

/// Extension for mapping PlaybackState to AudioPlayerState.
extension PlaybackStateMapper on PlaybackState {
  /// Convert a PlaybackState enum to the appropriate AudioPlayerState.
  ///
  /// Requires context about the current track and playback position.
  AudioPlayerState toPlayerState({
    Song? track,
    Duration position = Duration.zero,
    Duration duration = Duration.zero,
    double volume = 1.0,
    double speed = 1.0,
    double bufferProgress = 0.0,
    String? errorMessage,
  }) {
    switch (this) {
      case PlaybackState.stopped:
        return const IdleState();
      case PlaybackState.buffering:
        if (track != null) {
          return BufferingState(
            track: track,
            position: position,
            duration: duration,
            bufferProgress: bufferProgress,
          );
        }
        return const IdleState();
      case PlaybackState.playing:
        if (track != null) {
          return PlayingState(
            track: track,
            position: position,
            duration: duration,
            volume: volume,
            speed: speed,
          );
        }
        return const IdleState();
      case PlaybackState.paused:
        if (track != null) {
          return PausedState(
            track: track,
            position: position,
            duration: duration,
          );
        }
        return const IdleState();
      case PlaybackState.completed:
        if (track != null) {
          return CompletedState(
            track: track,
            duration: duration,
          );
        }
        return const IdleState();
      case PlaybackState.error:
        return ErrorState(
          message: errorMessage ?? 'Playback error',
          errorCode: 'PLAYBACK_ERROR',
          lastTrack: track,
        );
    }
  }
}
