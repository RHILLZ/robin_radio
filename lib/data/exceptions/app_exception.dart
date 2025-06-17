import 'error_messages.dart';

/// Base exception class for all Robin Radio app exceptions.
///
/// This serves as the common interface for all custom exceptions
/// throughout the application, providing standardized error handling.
abstract class AppException implements Exception {
  const AppException(this.message, this.errorCode, [this.cause]);

  /// Human-readable error message suitable for logging and debugging
  final String message;

  /// Machine-readable error code for programmatic handling and categorization
  final String errorCode;

  /// Optional underlying cause or original exception that triggered this error
  final dynamic cause;

  /// Returns a user-friendly message suitable for display in the UI
  String get userMessage => ErrorMessages.getUserMessage(errorCode, category);

  /// Returns true if this is a recoverable error that can be retried
  bool get isRecoverable => false;

  /// Returns the category of this exception for grouping similar errors
  String get category => 'general';

  /// Returns the severity level of this exception
  ExceptionSeverity get severity => ExceptionSeverity.medium;

  /// Returns true if this error requires user action to resolve
  bool get isUserActionable =>
      ErrorMessages.isUserActionable(errorCode, category);

  /// Returns suggested actions the user can take to resolve this error
  List<String> get suggestedActions =>
      ErrorMessages.getSuggestedActions(errorCode, category);

  @override
  String toString() => 'AppException($errorCode): $message';

  /// Returns a map representation for logging and analytics
  Map<String, dynamic> toMap() => {
        'type': runtimeType.toString(),
        'errorCode': errorCode,
        'technicalMessage': message,
        'userMessage': userMessage,
        'category': category,
        'severity': severity.name,
        'isRecoverable': isRecoverable,
        'isUserActionable': isUserActionable,
        'suggestedActions': suggestedActions,
        'cause': cause?.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
}

/// Severity levels for exceptions
enum ExceptionSeverity { low, medium, high, critical }

/// Authentication-related exception
class AuthException extends AppException {
  const AuthException(super.message, super.errorCode, [super.cause]);

  /// Creates an auth exception for user not authenticated
  const AuthException.notAuthenticated()
      : super(
          'User is not authenticated. Please sign in.',
          'AUTH_NOT_AUTHENTICATED',
        );

  /// Creates an auth exception for invalid credentials
  const AuthException.invalidCredentials()
      : super(
          'Invalid credentials provided.',
          'AUTH_INVALID_CREDENTIALS',
        );

  /// Creates an auth exception for expired session
  const AuthException.sessionExpired()
      : super(
          'Session has expired. Please sign in again.',
          'AUTH_SESSION_EXPIRED',
        );

  /// Creates an auth exception for permission denied
  const AuthException.permissionDenied([String? resource])
      : super(
          'Permission denied${resource != null ? ' for $resource' : ''}.',
          'AUTH_PERMISSION_DENIED',
        );

  @override
  String get category => 'authentication';

  @override
  ExceptionSeverity get severity => ExceptionSeverity.high;
}

/// General application error for unexpected conditions
class AppError extends AppException {
  const AppError(super.message, super.errorCode, [super.cause]);

  /// Creates an app error for unexpected conditions
  const AppError.unexpected([String? details])
      : super(
          'An unexpected error occurred${details != null ? ': $details' : '.'}',
          'APP_UNEXPECTED_ERROR',
        );

  /// Creates an app error for initialization failures
  const AppError.initializationFailed(String component)
      : super(
          'Failed to initialize $component',
          'APP_INITIALIZATION_FAILED',
        );

  /// Creates an app error for configuration issues
  const AppError.configurationError(String setting)
      : super(
          'Configuration error: $setting',
          'APP_CONFIGURATION_ERROR',
        );

  @override
  String get category => 'application';
}
