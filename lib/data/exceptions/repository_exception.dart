import 'app_exception.dart';

/// Base exception class for repository operations and data access errors.
///
/// Serves as the parent class for all repository-related exceptions in the app.
/// Provides common behavior for data layer errors including recovery capabilities
/// and categorization for proper error handling and diagnostics.
abstract class RepositoryException extends AppException {
  /// Creates a new RepositoryException with the specified message and error code.
  ///
  /// [message] Description of the repository error.
  /// [errorCode] Machine-readable error code for programmatic handling.
  /// [cause] Optional underlying cause of the repository error.
  const RepositoryException(super.message, super.errorCode, [super.cause]);

  @override
  String get category => 'repository';

  @override
  bool get isRecoverable => true; // Most repository errors can be retried
}

/// Exception thrown when network operations fail in repository layer.
///
/// Handles network-related errors that occur during data fetching and
/// synchronization operations including connection failures, timeouts,
/// and server errors. These errors typically affect remote data access.
class NetworkRepositoryException extends RepositoryException {
  /// Creates a new NetworkRepositoryException with the specified message and error code.
  ///
  /// [message] Description of the network repository error.
  /// [errorCode] Machine-readable error code for programmatic handling.
  const NetworkRepositoryException(super.message, super.errorCode);

  /// Creates a network exception for connection failures.
  ///
  /// Used when the repository cannot establish a connection to remote
  /// data sources due to network connectivity or server availability issues.
  const NetworkRepositoryException.connectionFailed()
      : super(
          'Unable to connect to the server. Please check your internet connection.',
          'NETWORK_CONNECTION_FAILED',
        );

  /// Creates a network exception for timeout errors.
  ///
  /// Used when network requests take longer than the configured timeout
  /// duration, indicating slow network conditions or server performance issues.
  const NetworkRepositoryException.timeout()
      : super(
          'The request timed out. Please try again.',
          'NETWORK_TIMEOUT',
        );

  /// Creates a network exception for server errors.
  ///
  /// Used when the remote server returns error responses (5xx status codes)
  /// or encounters internal problems while processing repository requests.
  const NetworkRepositoryException.serverError()
      : super(
          'Server error occurred. Please try again later.',
          'NETWORK_SERVER_ERROR',
        );
}

/// Exception thrown when cache operations fail in repository layer.
///
/// Handles cache-related errors that occur during local data storage
/// and retrieval operations including read/write failures and data
/// corruption. These errors typically affect local data access.
class CacheRepositoryException extends RepositoryException {
  /// Creates a new CacheRepositoryException with the specified message and error code.
  ///
  /// [message] Description of the cache repository error.
  /// [errorCode] Machine-readable error code for programmatic handling.
  const CacheRepositoryException(super.message, super.errorCode);

  /// Creates a cache exception for read failures.
  ///
  /// Used when the repository cannot read cached data due to file system
  /// errors, permission issues, or corrupted cache storage.
  const CacheRepositoryException.readFailed()
      : super(
          'Failed to read from cache.',
          'CACHE_READ_FAILED',
        );

  /// Creates a cache exception for write failures.
  ///
  /// Used when the repository cannot write data to cache due to disk space
  /// limitations, permission issues, or file system errors.
  const CacheRepositoryException.writeFailed()
      : super(
          'Failed to write to cache.',
          'CACHE_WRITE_FAILED',
        );

  /// Creates a cache exception for corruption issues.
  ///
  /// Used when cached data has been detected as corrupted and cannot be
  /// used reliably, requiring cache invalidation and data refresh.
  const CacheRepositoryException.corrupted()
      : super(
          'Cache data is corrupted and needs to be refreshed.',
          'CACHE_CORRUPTED',
        );
}

/// Exception thrown when data parsing fails in repository layer.
///
/// Handles data processing errors that occur during parsing, validation,
/// and transformation operations including format issues, missing data,
/// and invalid structures. These errors typically affect data integrity.
class DataRepositoryException extends RepositoryException {
  /// Creates a new DataRepositoryException with the specified message and error code.
  ///
  /// [message] Description of the data repository error.
  /// [errorCode] Machine-readable error code for programmatic handling.
  const DataRepositoryException(super.message, super.errorCode);

  /// Creates a data exception for parsing failures.
  ///
  /// Used when repository data cannot be properly parsed or deserialized
  /// due to format changes, invalid JSON, or schema mismatches.
  const DataRepositoryException.parsingFailed()
      : super(
          'Failed to parse music data. Please try refreshing.',
          'DATA_PARSING_FAILED',
        );

  /// Creates a data exception for missing data.
  ///
  /// Used when requested data entities are not found in the repository,
  /// either locally or remotely, requiring error handling or fallbacks.
  const DataRepositoryException.notFound()
      : super(
          'The requested music data was not found.',
          'DATA_NOT_FOUND',
        );

  /// Creates a data exception for invalid data format.
  ///
  /// Used when data exists but is in an unexpected or invalid format
  /// that prevents proper processing and use by the application.
  const DataRepositoryException.invalidFormat()
      : super(
          'Music data is in an invalid format.',
          'DATA_INVALID_FORMAT',
        );
}

/// Exception thrown when Firebase operations fail in repository layer.
///
/// Handles Firebase-specific errors that occur during cloud data operations
/// including authentication failures, permission issues, and storage errors.
/// These errors typically affect Firebase backend integration.
class FirebaseRepositoryException extends RepositoryException {
  /// Creates a new FirebaseRepositoryException with the specified message and error code.
  ///
  /// [message] Description of the Firebase repository error.
  /// [errorCode] Machine-readable error code for programmatic handling.
  const FirebaseRepositoryException(super.message, super.errorCode);

  /// Creates a Firebase exception for authentication failures.
  ///
  /// Used when Firebase authentication fails due to invalid credentials,
  /// expired tokens, or authentication service unavailability.
  const FirebaseRepositoryException.authenticationFailed()
      : super(
          'Authentication failed. Please try again.',
          'FIREBASE_AUTH_FAILED',
        );

  /// Creates a Firebase exception for permission denied errors.
  ///
  /// Used when the current user lacks sufficient permissions to access
  /// or modify Firebase resources based on security rules.
  const FirebaseRepositoryException.permissionDenied()
      : super(
          'Permission denied. Please check your access rights.',
          'FIREBASE_PERMISSION_DENIED',
        );

  /// Creates a Firebase exception for storage errors.
  ///
  /// Used when Firebase Storage operations fail due to network issues,
  /// storage quotas, or service availability problems.
  const FirebaseRepositoryException.storageError()
      : super(
          'Storage operation failed. Please try again.',
          'FIREBASE_STORAGE_ERROR',
        );
}
