import 'app_exception.dart';

/// Base exception class for repository operations.
abstract class RepositoryException extends AppException {
  const RepositoryException(super.message, super.errorCode, [super.cause]);

  @override
  String get category => 'repository';

  @override
  bool get isRecoverable => true; // Most repository errors can be retried
}

/// Exception thrown when network operations fail.
class NetworkRepositoryException extends RepositoryException {
  const NetworkRepositoryException(super.message, super.errorCode);

  /// Creates a network exception for connection failures.
  const NetworkRepositoryException.connectionFailed()
      : super(
          'Unable to connect to the server. Please check your internet connection.',
          'NETWORK_CONNECTION_FAILED',
        );

  /// Creates a network exception for timeout errors.
  const NetworkRepositoryException.timeout()
      : super(
          'The request timed out. Please try again.',
          'NETWORK_TIMEOUT',
        );

  /// Creates a network exception for server errors.
  const NetworkRepositoryException.serverError()
      : super(
          'Server error occurred. Please try again later.',
          'NETWORK_SERVER_ERROR',
        );
}

/// Exception thrown when cache operations fail.
class CacheRepositoryException extends RepositoryException {
  const CacheRepositoryException(super.message, super.errorCode);

  /// Creates a cache exception for read failures.
  const CacheRepositoryException.readFailed()
      : super(
          'Failed to read from cache.',
          'CACHE_READ_FAILED',
        );

  /// Creates a cache exception for write failures.
  const CacheRepositoryException.writeFailed()
      : super(
          'Failed to write to cache.',
          'CACHE_WRITE_FAILED',
        );

  /// Creates a cache exception for corruption issues.
  const CacheRepositoryException.corrupted()
      : super(
          'Cache data is corrupted and needs to be refreshed.',
          'CACHE_CORRUPTED',
        );
}

/// Exception thrown when data parsing fails.
class DataRepositoryException extends RepositoryException {
  const DataRepositoryException(super.message, super.errorCode);

  /// Creates a data exception for parsing failures.
  const DataRepositoryException.parsingFailed()
      : super(
          'Failed to parse music data. Please try refreshing.',
          'DATA_PARSING_FAILED',
        );

  /// Creates a data exception for missing data.
  const DataRepositoryException.notFound()
      : super(
          'The requested music data was not found.',
          'DATA_NOT_FOUND',
        );

  /// Creates a data exception for invalid data format.
  const DataRepositoryException.invalidFormat()
      : super(
          'Music data is in an invalid format.',
          'DATA_INVALID_FORMAT',
        );
}

/// Exception thrown when Firebase operations fail.
class FirebaseRepositoryException extends RepositoryException {
  const FirebaseRepositoryException(super.message, super.errorCode);

  /// Creates a Firebase exception for authentication failures.
  const FirebaseRepositoryException.authenticationFailed()
      : super(
          'Authentication failed. Please try again.',
          'FIREBASE_AUTH_FAILED',
        );

  /// Creates a Firebase exception for permission denied errors.
  const FirebaseRepositoryException.permissionDenied()
      : super(
          'Permission denied. Please check your access rights.',
          'FIREBASE_PERMISSION_DENIED',
        );

  /// Creates a Firebase exception for storage errors.
  const FirebaseRepositoryException.storageError()
      : super(
          'Storage operation failed. Please try again.',
          'FIREBASE_STORAGE_ERROR',
        );
}
