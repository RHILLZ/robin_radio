import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../exceptions/audio_service_exception.dart';
import '../../models/song.dart';
import 'audio_service_interface.dart';

/// Mixin providing shared functionality for audio service implementations.
///
/// This mixin consolidates common logic between BackgroundAudioService and
/// WebAudioService to reduce code duplication and ensure consistent behavior
/// across platforms.
///
/// ## Shared Functionality
///
/// - **Duration formatting**: Common time string generation
/// - **Queue management helpers**: Index calculation and validation
/// - **State validation**: Service lifecycle checks
/// - **Error handling**: Consistent exception patterns
///
/// ## Usage
///
/// ```dart
/// class MyAudioService with AudioServiceMixin implements IAudioService {
///   // Implement platform-specific methods
///   // Use mixin methods for common functionality
/// }
/// ```
mixin AudioServiceMixin {
  /// Whether the service has been initialized
  bool get isServiceInitialized;

  /// Whether the service has been disposed
  bool get isServiceDisposed;

  /// Current playback mode
  PlaybackMode get currentPlaybackMode;

  /// Current queue of songs
  List<Song> get currentQueue;

  /// Current index in the queue
  int get currentQueueIndex;

  /// Format a duration as a human-readable time string.
  ///
  /// Returns formatted string in MM:SS or HH:MM:SS format depending
  /// on whether the duration exceeds one hour.
  ///
  /// Examples:
  /// - Duration(seconds: 90) -> "01:30"
  /// - Duration(hours: 1, minutes: 5) -> "01:05:00"
  String formatDurationValue(Duration duration) {
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

  /// Ensure the service is in a valid state for operations.
  ///
  /// Throws [AudioOperationException] if disposed.
  void ensureNotDisposed() {
    if (isServiceDisposed) {
      throw const AudioOperationException.serviceDisposed();
    }
  }

  /// Validate a position value for seeking.
  ///
  /// Throws [AudioOperationException] if position is invalid.
  void validatePosition(Duration position, Duration trackDuration) {
    if (position.isNegative || position > trackDuration) {
      throw AudioOperationException.invalidParameter(
        'position',
        position.toString(),
      );
    }
  }

  /// Validate a volume value.
  ///
  /// Throws [AudioOperationException] if volume is out of range.
  void validateVolume(double volume) {
    if (volume < 0.0 || volume > 1.0) {
      throw AudioOperationException.invalidParameter(
        'volume',
        volume.toString(),
      );
    }
  }

  /// Validate a playback speed value.
  ///
  /// Throws [AudioOperationException] if speed is out of range.
  void validateSpeed(double speed) {
    if (speed <= 0.0 || speed > 3.0) {
      throw AudioOperationException.invalidParameter(
        'speed',
        speed.toString(),
      );
    }
  }

  /// Validate a queue index value.
  ///
  /// Throws [AudioQueueException] if index is out of bounds.
  void validateQueueIndex(int index, int queueLength) {
    if (index < 0 || index >= queueLength) {
      throw AudioQueueException.invalidIndex(index, queueLength);
    }
  }

  /// Calculate the next track index based on playback mode.
  ///
  /// Returns -1 if no next track is available (end of queue in normal mode).
  int calculateNextIndex() {
    if (currentQueue.isEmpty) {
      return -1;
    }

    switch (currentPlaybackMode) {
      case PlaybackMode.normal:
        return currentQueueIndex + 1 < currentQueue.length
            ? currentQueueIndex + 1
            : -1;
      case PlaybackMode.repeatOne:
        return currentQueueIndex;
      case PlaybackMode.repeatAll:
        return currentQueueIndex + 1 < currentQueue.length
            ? currentQueueIndex + 1
            : 0;
      case PlaybackMode.shuffle:
        return _getRandomIndex(currentQueueIndex, currentQueue.length);
    }
  }

  /// Calculate the previous track index based on playback mode.
  ///
  /// Returns -1 if no previous track is available.
  int calculatePreviousIndex() {
    if (currentQueue.isEmpty) {
      return -1;
    }

    switch (currentPlaybackMode) {
      case PlaybackMode.normal:
      case PlaybackMode.repeatOne:
        return currentQueueIndex > 0 ? currentQueueIndex - 1 : -1;
      case PlaybackMode.repeatAll:
        return currentQueueIndex > 0
            ? currentQueueIndex - 1
            : currentQueue.length - 1;
      case PlaybackMode.shuffle:
        return _getRandomIndex(currentQueueIndex, currentQueue.length);
    }
  }

  /// Generate a random index different from the current one.
  int _getRandomIndex(int currentIndex, int queueLength) {
    if (queueLength <= 1) {
      return currentIndex;
    }

    int randomIndex;
    do {
      randomIndex = DateTime.now().millisecondsSinceEpoch % queueLength;
    } while (randomIndex == currentIndex);
    return randomIndex;
  }

  /// Log a debug message if in debug mode.
  void logDebug(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  /// Safely cancel a stream subscription.
  Future<void> cancelSubscription(StreamSubscription<dynamic>? subscription) async {
    await subscription?.cancel();
  }
}

/// Extension on Duration for convenient formatting.
extension DurationFormatting on Duration {
  /// Format as MM:SS or HH:MM:SS string.
  String toFormattedString() {
    final hours = inHours;
    final minutes = inMinutes.remainder(60);
    final seconds = inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
  }
}
