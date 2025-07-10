import 'dart:async';
import '../../exceptions/audio_service_exception.dart'
    show AudioServiceException;
import '../../models/song.dart';
import 'audio_services.dart' show AudioServiceException;

/// Represents the current state of audio playback in the service.
///
/// Used to track and communicate the current status of audio operations
/// throughout the application. Consumers can listen to state changes
/// to update UI elements and handle different playback scenarios.
enum PlaybackState {
  /// Audio is currently playing and outputting sound.
  ///
  /// The audio player is actively playing a track and the user
  /// can hear audio output. Position updates are being emitted.
  playing,

  /// Audio playback is temporarily paused.
  ///
  /// The audio player has stopped playback but maintains the current
  /// position. Playback can be resumed from the same position.
  paused,

  /// Audio playback is completely stopped.
  ///
  /// The audio player has stopped playback and reset to the beginning.
  /// No audio is playing and position is typically at zero.
  stopped,

  /// Audio is buffering or loading content.
  ///
  /// The audio player is downloading or processing audio data before
  /// playback can begin. This is common with streaming audio.
  buffering,

  /// Audio playback has reached the end and completed.
  ///
  /// The current track has finished playing completely. The player
  /// may automatically advance to the next track depending on mode.
  completed,

  /// Audio service has encountered an error during operation.
  ///
  /// An error occurred that prevents normal audio playback. The specific
  /// error details should be available through exception handling.
  error,
}

/// Defines different playback behaviors for track progression and repetition.
///
/// Controls how the audio service handles track transitions, repetition,
/// and randomization during playback sessions. This affects the overall
/// listening experience and user control over audio flow.
enum PlaybackMode {
  /// Standard sequential playback with no repetition.
  ///
  /// Tracks play in order once through the queue, then stop.
  /// This is the default mode for most audio applications.
  normal,

  /// Continuously repeat the current track.
  ///
  /// The currently playing track will restart automatically when
  /// it completes, creating an infinite loop of the same song.
  repeatOne,

  /// Repeat the entire queue continuously.
  ///
  /// When the last track in the queue completes, playback returns
  /// to the first track and continues cycling through all tracks.
  repeatAll,

  /// Randomize track order during playback.
  ///
  /// Tracks are selected randomly from the queue rather than
  /// playing in sequential order, providing variety in listening.
  shuffle,
}

/// Comprehensive audio service interface for centralized audio management.
///
/// Provides a complete audio playback solution with support for queue management,
/// background playback, state monitoring, and advanced playback controls.
/// Implementations should handle platform-specific audio requirements while
/// maintaining this consistent interface for application-wide audio operations.
///
/// ## Core Capabilities
///
/// **Playback Control:**
/// - Full media control (play, pause, stop, seek, skip)
/// - Variable speed playback with pitch preservation
/// - Volume control with system integration
/// - Precise position seeking with validation
///
/// **Queue Management:**
/// - Dynamic queue manipulation (add, remove, reorder)
/// - Multiple playback modes (repeat, shuffle, normal)
/// - Track progression with dependency resolution
/// - Queue persistence across app sessions
///
/// **State Management:**
/// - Real-time state broadcasting via reactive streams
/// - Comprehensive error handling with recovery strategies
/// - Position and duration tracking with high precision
/// - Background/foreground state coordination
///
/// **Advanced Features:**
/// - Background playback with media session integration
/// - Buffering progress monitoring for streaming content
/// - Format string utilities for time display
/// - Performance optimization with resource management
///
/// ## Architecture Pattern
///
/// This interface follows the Repository pattern, providing a clean abstraction
/// over audio implementation details. Implementations can use any underlying
/// audio library (AudioPlayers, Just Audio, etc.) while maintaining API consistency.
///
/// ```dart
/// // Dependency injection setup
/// abstract class AudioModule {
///   static void configure() {
///     GetIt.instance.registerSingleton<IAudioService>(
///       EnhancedAudioService(), // or MockAudioService for testing
///     );
///   }
/// }
/// ```
///
/// ## Usage Patterns
///
/// **Basic Playback:**
/// ```dart
/// final audioService = GetIt.instance<IAudioService>();
/// await audioService.initialize();
///
/// // Play a single track
/// await audioService.play(song);
///
/// // Control playback
/// await audioService.pause();
/// await audioService.seek(Duration(seconds: 30));
/// await audioService.setVolume(0.8);
/// ```
///
/// **Queue Management:**
/// ```dart
/// // Build a playlist
/// for (final song in playlist.songs) {
///   await audioService.addToQueue(song);
/// }
///
/// // Configure playback mode
/// await audioService.setPlaybackMode(PlaybackMode.shuffle);
///
/// // Navigate through queue
/// await audioService.skipToNext();
/// await audioService.skipToPrevious();
/// ```
///
/// **Reactive UI Updates:**
/// ```dart
/// class AudioControlsWidget extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return StreamBuilder<PlaybackState>(
///       stream: audioService.playbackState,
///       builder: (context, snapshot) {
///         final state = snapshot.data ?? PlaybackState.stopped;
///         return PlayButton(
///           isPlaying: state == PlaybackState.playing,
///           onPressed: () => state == PlaybackState.playing
///               ? audioService.pause()
///               : audioService.resume(),
///         );
///       },
///     );
///   }
/// }
/// ```
///
/// ## Error Handling Strategy
///
/// All methods throw [AudioServiceException] subclasses for structured error handling:
///
/// ```dart
/// try {
///   await audioService.play(song);
/// } on AudioPlaybackException catch (e) {
///   showErrorSnackbar('Playback failed: ${e.message}');
/// } on AudioOperationException catch (e) {
///   logError('Invalid operation: ${e.errorCode}');
/// }
/// ```
///
/// ## Implementation Requirements
///
/// Implementations must:
/// - Handle platform-specific audio session configuration
/// - Provide proper resource cleanup in [dispose]
/// - Maintain thread-safe operation for concurrent calls
/// - Emit stream events for all state changes
/// - Validate parameters and throw appropriate exceptions
/// - Support background playback where platform-appropriate
///
/// ## Platform Considerations
///
/// **iOS:**
/// - Configure AVAudioSession for background playback
/// - Handle Control Center and lock screen integration
/// - Respect silent mode and audio routing preferences
///
/// **Android:**
/// - Implement MediaSession for system integration
/// - Handle audio focus changes appropriately
/// - Configure foreground service for background playback
///
/// The interface abstracts these platform differences while ensuring
/// consistent behavior across all target platforms.
abstract class IAudioService {
  /// Play a specific track with optional starting position.
  ///
  /// Begins playback of the specified track, replacing any currently
  /// playing audio. The track is automatically added to the current
  /// playback session and position tracking begins.
  ///
  /// [track] The song to play - must have a valid audio URL.
  /// [startPosition] Optional starting position within the track.
  ///                If null, playback starts from the beginning.
  ///
  /// Throws [AudioServiceException] if:
  /// - The track URL is invalid or inaccessible
  /// - Audio initialization fails
  /// - Platform audio permissions are denied
  /// - Network connectivity issues prevent streaming
  Future<void> play(Song track, {Duration? startPosition});

  /// Pause current playback while maintaining position.
  ///
  /// Temporarily stops audio output while preserving the current
  /// playback position. The track can be resumed from the same
  /// position using [resume()].
  ///
  /// Throws [AudioServiceException] if:
  /// - No track is currently playing
  /// - Audio service is in an invalid state
  /// - Platform audio system errors occur
  Future<void> pause();

  /// Resume paused playback from the current position.
  ///
  /// Continues audio playback from where it was previously paused.
  /// This has no effect if audio is already playing or if no track
  /// is loaded.
  ///
  /// Throws [AudioServiceException] if:
  /// - No track is loaded for resumption
  /// - Audio service is in an invalid state
  /// - Platform audio system errors occur
  Future<void> resume();

  /// Stop current playback and reset position to beginning.
  ///
  /// Completely stops audio playback and resets the position to
  /// the beginning of the track. This is different from pause
  /// in that the position is not maintained.
  ///
  /// Throws [AudioServiceException] if:
  /// - Audio service is in an invalid state
  /// - Platform audio system errors occur
  Future<void> stop();

  /// Seek to a specific position in the current track.
  ///
  /// Changes the playback position to the specified time within
  /// the currently loaded track. Position changes are reflected
  /// immediately in position streams.
  ///
  /// [position] The target position within the track. Should be
  ///           between Duration.zero and the track duration.
  ///
  /// Throws [AudioServiceException] if:
  /// - No track is currently loaded
  /// - The specified position is invalid (negative or beyond track length)
  /// - Seeking is not supported for the current audio format
  Future<void> seek(Duration position);

  /// Set playback volume level.
  ///
  /// Adjusts the audio output volume for the current playback session.
  /// Volume changes take effect immediately and are reflected in
  /// volume streams.
  ///
  /// [volume] Volume level between 0.0 (completely muted) and 1.0 (maximum).
  ///         Values outside this range will be clamped.
  ///
  /// Throws [AudioServiceException] if:
  /// - Audio service is not initialized
  /// - Platform volume control is not available
  Future<void> setVolume(double volume);

  /// Set playback speed multiplier.
  ///
  /// Changes the playback speed while maintaining pitch (where supported).
  /// Speed changes affect position calculation and duration estimates.
  ///
  /// [speed] Playback speed multiplier where:
  ///        - 0.5 = half speed (slower)
  ///        - 1.0 = normal speed
  ///        - 2.0 = double speed (faster)
  ///        Typical range is 0.25 to 4.0.
  ///
  /// Throws [AudioServiceException] if:
  /// - The specified speed is not supported by the platform
  /// - Speed control is not available for the current audio format
  Future<void> setPlaybackSpeed(double speed);

  /// Set playback mode for queue handling and repetition.
  ///
  /// Changes how the audio service handles track progression when
  /// the current track completes. Mode changes take effect on the
  /// next track transition.
  ///
  /// [mode] The desired playback behavior from [PlaybackMode] enum.
  Future<void> setPlaybackMode(PlaybackMode mode);

  /// Skip to the next track in the playback queue.
  ///
  /// Advances to the next track based on the current playback mode.
  /// In shuffle mode, selects a random track. In normal mode, selects
  /// the next sequential track.
  ///
  /// Throws [AudioServiceException] if:
  /// - The queue is empty
  /// - Already at the last track (in normal mode)
  /// - Track loading fails
  Future<void> skipToNext();

  /// Skip to the previous track in the playback queue.
  ///
  /// Returns to the previous track or restarts the current track
  /// if already near the beginning. Behavior depends on current
  /// position and platform conventions.
  ///
  /// Throws [AudioServiceException] if:
  /// - The queue is empty
  /// - Already at the first track
  /// - Track loading fails
  Future<void> skipToPrevious();

  /// Add a track to the playback queue.
  ///
  /// Inserts a track into the queue at the specified position or
  /// at the end if no index is provided. The queue is used for
  /// track progression during playback.
  ///
  /// [track] The song to add to the queue.
  /// [index] Optional insertion index. If null, adds to the end.
  ///        If negative or beyond queue length, behavior is platform-dependent.
  Future<void> addToQueue(Song track, {int? index});

  /// Remove a track from the playback queue by index.
  ///
  /// Removes the track at the specified index from the queue.
  /// If the removed track is currently playing, behavior depends
  /// on the implementation (may skip to next or stop).
  ///
  /// [index] Zero-based index of the track to remove.
  ///
  /// Throws [AudioServiceException] if:
  /// - The index is out of bounds
  /// - The queue is empty
  Future<void> removeFromQueue(int index);

  /// Clear the entire playback queue.
  ///
  /// Removes all tracks from the queue. The currently playing
  /// track may continue playing but no automatic progression
  /// will occur when it completes.
  Future<void> clearQueue();

  /// Get a copy of the current playback queue.
  ///
  /// Returns an immutable list of tracks currently in the queue.
  /// This represents the order tracks will play in normal mode.
  List<Song> get queue;

  /// Stream of playback state changes.
  ///
  /// Emits [PlaybackState] values whenever the audio service
  /// state changes (playing, paused, stopped, etc.). Subscribe
  /// to this stream to update UI elements in real-time.
  Stream<PlaybackState> get playbackState;

  /// Stream of currently playing track changes.
  ///
  /// Emits the current [Song] whenever a new track begins playing,
  /// or null when no track is loaded. Useful for updating track
  /// information displays.
  Stream<Song?> get currentTrack;

  /// Stream of playback position updates.
  ///
  /// Emits [Duration] values representing the current position
  /// within the playing track. Updates are typically emitted
  /// every 100-500 milliseconds during playback.
  Stream<Duration> get position;

  /// Stream of track duration information.
  ///
  /// Emits the total [Duration] of the currently loaded track.
  /// May emit multiple times as duration information becomes
  /// available (especially for streaming content).
  Stream<Duration> get duration;

  /// Stream of volume level changes.
  ///
  /// Emits volume values (0.0 to 1.0) whenever the playback
  /// volume is modified through [setVolume] or system controls.
  Stream<double> get volume;

  /// Stream of playback speed changes.
  ///
  /// Emits speed multiplier values whenever the playback speed
  /// is modified through [setPlaybackSpeed]. Default is 1.0.
  Stream<double> get playbackSpeed;

  /// Stream of playback mode changes.
  ///
  /// Emits [PlaybackMode] values whenever the mode is changed
  /// through [setPlaybackMode]. Useful for updating mode
  /// indicators in the UI.
  Stream<PlaybackMode> get playbackMode;

  /// Stream of queue modification events.
  ///
  /// Emits the complete queue list whenever tracks are added,
  /// removed, or reordered. Subscribe to update queue displays
  /// and track lists.
  Stream<List<Song>> get queueStream;

  /// Stream of buffering progress for streaming content.
  ///
  /// Emits values from 0.0 to 1.0 representing how much of the
  /// current track has been buffered. Useful for showing
  /// buffering indicators during streaming playback.
  Stream<double> get bufferingProgress;

  /// Current playback state as a snapshot value.
  ///
  /// Returns the immediate state without subscribing to changes.
  /// For reactive updates, use [playbackState] stream instead.
  PlaybackState get currentState;

  /// Currently playing track as a snapshot value.
  ///
  /// Returns the current track or null if none is loaded.
  /// For reactive updates, use [currentTrack] stream instead.
  Song? get currentSong;

  /// Current playback position as a snapshot value.
  ///
  /// Returns the immediate position within the current track.
  /// For continuous updates, use [position] stream instead.
  Duration get currentPosition;

  /// Current track duration as a snapshot value.
  ///
  /// Returns the total length of the current track, or Duration.zero
  /// if no track is loaded or duration is unknown.
  Duration get trackDuration;

  /// Current volume level as a snapshot value.
  ///
  /// Returns the current volume (0.0 to 1.0) without subscribing
  /// to changes. For reactive updates, use [volume] stream instead.
  double get currentVolume;

  /// Current playback speed as a snapshot value.
  ///
  /// Returns the current speed multiplier (typically 1.0) without
  /// subscribing to changes. For reactive updates, use [playbackSpeed] stream.
  double get currentSpeed;

  /// Current playback mode as a snapshot value.
  ///
  /// Returns the current mode without subscribing to changes.
  /// For reactive updates, use [playbackMode] stream instead.
  PlaybackMode get currentMode;

  /// Whether audio is currently playing.
  ///
  /// Convenience getter that returns true when [currentState] is
  /// [PlaybackState.playing]. Useful for simple play/pause UI logic.
  bool get isPlaying;

  /// Whether audio is currently paused.
  ///
  /// Convenience getter that returns true when [currentState] is
  /// [PlaybackState.paused]. Useful for pause-specific UI states.
  bool get isPaused;

  /// Whether audio is completely stopped.
  ///
  /// Convenience getter that returns true when [currentState] is
  /// [PlaybackState.stopped]. Indicates no active playback session.
  bool get isStopped;

  /// Whether audio is currently buffering.
  ///
  /// Convenience getter that returns true when [currentState] is
  /// [PlaybackState.buffering]. Useful for showing loading indicators.
  bool get isBuffering;

  /// Playback progress as a percentage (0.0 to 1.0).
  ///
  /// Calculated as currentPosition / trackDuration. Returns 0.0
  /// if no track is loaded or duration is unknown. Useful for
  /// progress bars and seek controls.
  double get progress;

  /// Initialize the audio service and platform-specific components.
  ///
  /// Must be called before using any other audio service methods.
  /// Sets up audio session, requests permissions, and prepares
  /// the underlying audio engine for playback operations.
  ///
  /// Throws [AudioServiceException] if:
  /// - Platform audio permissions are denied
  /// - Audio system is unavailable
  /// - Service is already initialized
  Future<void> initialize();

  /// Dispose of the audio service and clean up all resources.
  ///
  /// Releases audio resources, cancels active streams, and performs
  /// platform-specific cleanup. Should be called when the service
  /// is no longer needed to prevent memory leaks.
  ///
  /// After calling dispose, the service must be reinitialized
  /// before use. This is typically called during app shutdown.
  Future<void> dispose();

  /// Enable or disable background playback capability.
  ///
  /// Controls whether audio continues playing when the app moves
  /// to the background. Background playback requires appropriate
  /// platform permissions and capabilities.
  ///
  /// [enabled] True to enable background playback, false to disable.
  ///          When disabled, audio pauses when app backgrounds.
  ///
  /// Throws [AudioServiceException] if:
  /// - Background audio is not supported on the platform
  /// - Required permissions are not granted
  Future<void> setBackgroundPlaybackEnabled({required bool enabled});

  /// Get formatted string representation of current position.
  ///
  /// Returns the current playback position formatted as a readable
  /// time string (e.g., "02:30" for 2 minutes and 30 seconds).
  /// Useful for displaying position in UI elements.
  String get formattedPosition;

  /// Get formatted string representation of current track duration.
  ///
  /// Returns the total track duration formatted as a readable
  /// time string (e.g., "03:45" for 3 minutes and 45 seconds).
  /// Useful for displaying total time in UI elements.
  String get formattedDuration;

  /// Format a duration as a human-readable time string.
  ///
  /// Converts a [Duration] object into a formatted string suitable
  /// for display in user interfaces. Handles various time formats
  /// based on the duration length.
  ///
  /// [duration] The duration to format.
  ///
  /// Returns formatted string like:
  /// - "01:23" for 1 minute 23 seconds
  /// - "12:34" for 12 minutes 34 seconds
  /// - "1:02:34" for 1 hour 2 minutes 34 seconds
  String formatDuration(Duration duration);
}
