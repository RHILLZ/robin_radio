/// Base exception class for audio service operations
abstract class AudioServiceException implements Exception {
  const AudioServiceException(this.message, this.errorCode);

  /// Human-readable error message
  final String message;

  /// Machine-readable error code for programmatic handling
  final String errorCode;

  @override
  String toString() => 'AudioServiceException($errorCode): $message';
}

/// Exception thrown when audio playback fails
class AudioPlaybackException extends AudioServiceException {
  const AudioPlaybackException(super.message, super.errorCode);

  /// Creates a playback exception for file loading failures
  const AudioPlaybackException.loadFailed(String url)
      : super(
          'Failed to load audio from: $url',
          'LOAD_FAILED',
        );

  /// Creates a playback exception for network issues
  const AudioPlaybackException.networkError()
      : super(
          'Network error occurred while loading audio',
          'NETWORK_ERROR',
        );

  /// Creates a playback exception for unsupported formats
  const AudioPlaybackException.unsupportedFormat(String format)
      : super(
          'Unsupported audio format: $format',
          'UNSUPPORTED_FORMAT',
        );

  /// Creates a playback exception for general playback failures
  const AudioPlaybackException.playbackFailed(String reason)
      : super(
          'Playback failed: $reason',
          'PLAYBACK_FAILED',
        );
}

/// Exception thrown when audio service initialization fails
class AudioInitializationException extends AudioServiceException {
  const AudioInitializationException(super.message, super.errorCode);

  /// Creates an initialization exception for service startup failures
  const AudioInitializationException.initFailed()
      : super(
          'Failed to initialize audio service',
          'INIT_FAILED',
        );

  /// Creates an initialization exception for permission issues
  const AudioInitializationException.permissionDenied()
      : super(
          'Audio permissions denied by user',
          'PERMISSION_DENIED',
        );

  /// Creates an initialization exception for device issues
  const AudioInitializationException.deviceError()
      : super(
          'Audio device is not available or has errors',
          'DEVICE_ERROR',
        );
}

/// Exception thrown when audio operations are invalid
class AudioOperationException extends AudioServiceException {
  const AudioOperationException(super.message, super.errorCode);

  /// Creates an operation exception for invalid state
  const AudioOperationException.invalidState(String operation, String state)
      : super(
          'Cannot $operation in current state: $state',
          'INVALID_STATE',
        );

  /// Creates an operation exception for disposed service
  const AudioOperationException.serviceDisposed()
      : super(
          'Audio service has been disposed and cannot perform operations',
          'SERVICE_DISPOSED',
        );

  /// Creates an operation exception for invalid parameters
  const AudioOperationException.invalidParameter(String parameter, String value)
      : super(
          'Invalid parameter $parameter: $value',
          'INVALID_PARAMETER',
        );
}

/// Exception thrown when queue operations fail
class AudioQueueException extends AudioServiceException {
  const AudioQueueException(super.message, super.errorCode);

  /// Creates a queue exception for empty queue operations
  const AudioQueueException.emptyQueue()
      : super(
          'Cannot perform operation on empty queue',
          'EMPTY_QUEUE',
        );

  /// Creates a queue exception for invalid index
  const AudioQueueException.invalidIndex(int index, int queueSize)
      : super(
          'Invalid queue index $index for queue of size $queueSize',
          'INVALID_INDEX',
        );

  /// Creates a queue exception for queue limit exceeded
  const AudioQueueException.queueFull(int maxSize)
      : super(
          'Queue is full (maximum size: $maxSize)',
          'QUEUE_FULL',
        );
}
