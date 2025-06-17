import 'app_exception.dart';

/// Base exception class for audio service operations and playback errors.
///
/// Serves as the parent class for all audio-related exceptions in the app.
/// Provides common behavior for audio errors including recovery capabilities
/// and categorization for proper error handling.
abstract class AudioServiceException extends AppException {
  /// Creates a new AudioServiceException with the specified message and error code.
  ///
  /// [message] Description of the audio service error.
  /// [errorCode] Machine-readable error code for programmatic handling.
  /// [cause] Optional underlying cause of the audio service error.
  const AudioServiceException(super.message, super.errorCode, [super.cause]);

  @override
  String get category => 'audio';

  @override
  bool get isRecoverable => true; // Most audio errors can be retried
}

/// Exception thrown when audio playback operations fail.
///
/// Handles various playback-related errors including file loading failures,
/// network issues, unsupported formats, and general playback problems.
/// These errors typically occur during audio streaming or file playback.
class AudioPlaybackException extends AudioServiceException {
  /// Creates a new AudioPlaybackException with the specified message and error code.
  ///
  /// [message] Description of the playback error.
  /// [errorCode] Machine-readable error code for programmatic handling.
  /// [cause] Optional underlying cause of the playback error.
  const AudioPlaybackException(super.message, super.errorCode, [super.cause]);

  /// Creates a playback exception for file loading failures.
  ///
  /// Used when an audio file cannot be loaded from the specified URL,
  /// whether due to file corruption, missing files, or access issues.
  ///
  /// [url] The URL or path of the audio file that failed to load.
  const AudioPlaybackException.loadFailed(String url)
      : super(
          'Failed to load audio from: $url',
          'LOAD_FAILED',
        );

  /// Creates a playback exception for network issues.
  ///
  /// Used when network connectivity problems prevent audio streaming
  /// or when remote audio resources are unreachable.
  const AudioPlaybackException.networkError()
      : super(
          'Network error occurred while loading audio',
          'NETWORK_ERROR',
        );

  /// Creates a playback exception for unsupported formats.
  ///
  /// Used when the audio player encounters a file format that is not
  /// supported by the current audio engine or device capabilities.
  ///
  /// [format] The unsupported audio format that was encountered.
  const AudioPlaybackException.unsupportedFormat(String format)
      : super(
          'Unsupported audio format: $format',
          'UNSUPPORTED_FORMAT',
        );

  /// Creates a playback exception for general playback failures.
  ///
  /// Used for various playback errors that don't fit into specific categories,
  /// such as codec errors, audio buffer issues, or player state problems.
  ///
  /// [reason] Description of the specific playback failure.
  const AudioPlaybackException.playbackFailed(String reason)
      : super(
          'Playback failed: $reason',
          'PLAYBACK_FAILED',
        );

  @override
  ExceptionSeverity get severity => ExceptionSeverity.medium;
}

/// Exception thrown when audio service initialization fails.
///
/// Handles errors that occur during audio service startup, including
/// permission issues, device availability problems, and service
/// configuration failures. These are typically critical errors.
class AudioInitializationException extends AudioServiceException {
  /// Creates a new AudioInitializationException with the specified message and error code.
  ///
  /// [message] Description of the initialization error.
  /// [errorCode] Machine-readable error code for programmatic handling.
  /// [cause] Optional underlying cause of the initialization error.
  const AudioInitializationException(
    super.message,
    super.errorCode, [
    super.cause,
  ]);

  /// Creates an initialization exception for service startup failures.
  ///
  /// Used when the audio service fails to start properly, preventing
  /// any audio functionality from working in the application.
  const AudioInitializationException.initFailed()
      : super(
          'Failed to initialize audio service',
          'INIT_FAILED',
        );

  /// Creates an initialization exception for permission issues.
  ///
  /// Used when the user has denied audio permissions or when the app
  /// lacks necessary permissions to access audio hardware.
  const AudioInitializationException.permissionDenied()
      : super(
          'Audio permissions denied by user',
          'PERMISSION_DENIED',
        );

  /// Creates an initialization exception for device issues.
  ///
  /// Used when audio hardware is unavailable, in use by another app,
  /// or has hardware-level problems that prevent audio operation.
  const AudioInitializationException.deviceError()
      : super(
          'Audio device is not available or has errors',
          'DEVICE_ERROR',
        );

  @override
  ExceptionSeverity get severity => ExceptionSeverity.high;
}

/// Exception thrown when audio operations are invalid or inappropriate.
///
/// Handles errors related to calling audio methods in wrong states,
/// with invalid parameters, or on disposed services. These are typically
/// programming errors that indicate incorrect API usage.
class AudioOperationException extends AudioServiceException {
  /// Creates a new AudioOperationException with the specified message and error code.
  ///
  /// [message] Description of the operation error.
  /// [errorCode] Machine-readable error code for programmatic handling.
  /// [cause] Optional underlying cause of the operation error.
  const AudioOperationException(super.message, super.errorCode, [super.cause]);

  /// Creates an operation exception for invalid state.
  ///
  /// Used when attempting to perform an operation that is not valid
  /// in the current audio service state (e.g., playing when stopped).
  ///
  /// [operation] The operation that was attempted.
  /// [state] The current state that prevents the operation.
  const AudioOperationException.invalidState(String operation, String state)
      : super(
          'Cannot $operation in current state: $state',
          'INVALID_STATE',
        );

  /// Creates an operation exception for disposed service.
  ///
  /// Used when attempting to use an audio service that has already
  /// been disposed and is no longer available for operations.
  const AudioOperationException.serviceDisposed()
      : super(
          'Audio service has been disposed and cannot perform operations',
          'SERVICE_DISPOSED',
        );

  /// Creates an operation exception for invalid parameters.
  ///
  /// Used when method parameters are outside acceptable ranges or
  /// have invalid values that prevent proper operation.
  ///
  /// [parameter] The name of the invalid parameter.
  /// [value] The invalid value that was provided.
  const AudioOperationException.invalidParameter(String parameter, String value)
      : super(
          'Invalid parameter $parameter: $value',
          'INVALID_PARAMETER',
        );

  @override
  ExceptionSeverity get severity => ExceptionSeverity.low;
}

/// Exception thrown when audio queue operations fail.
///
/// Handles errors related to playlist/queue management including
/// empty queue operations, invalid indices, and queue capacity issues.
/// These errors typically occur during playlist manipulation.
class AudioQueueException extends AudioServiceException {
  /// Creates a new AudioQueueException with the specified message and error code.
  ///
  /// [message] Description of the queue operation error.
  /// [errorCode] Machine-readable error code for programmatic handling.
  /// [cause] Optional underlying cause of the queue operation error.
  const AudioQueueException(super.message, super.errorCode, [super.cause]);

  /// Creates a queue exception for empty queue operations.
  ///
  /// Used when attempting to perform operations that require items
  /// in the queue (like next/previous) when the queue is empty.
  const AudioQueueException.emptyQueue()
      : super(
          'Cannot perform operation on empty queue',
          'EMPTY_QUEUE',
        );

  /// Creates a queue exception for invalid index.
  ///
  /// Used when attempting to access queue items with an index that
  /// is out of bounds for the current queue size.
  ///
  /// [index] The invalid index that was requested.
  /// [queueSize] The actual size of the queue.
  const AudioQueueException.invalidIndex(int index, int queueSize)
      : super(
          'Invalid queue index $index for queue of size $queueSize',
          'INVALID_INDEX',
        );

  /// Creates a queue exception for queue limit exceeded.
  ///
  /// Used when attempting to add items to a queue that has reached
  /// its maximum capacity limit.
  ///
  /// [maxSize] The maximum allowed size of the queue.
  const AudioQueueException.queueFull(int maxSize)
      : super(
          'Queue is full (maximum size: $maxSize)',
          'QUEUE_FULL',
        );

  @override
  ExceptionSeverity get severity => ExceptionSeverity.low;
}
