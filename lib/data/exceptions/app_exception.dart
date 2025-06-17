import 'error_messages.dart';

/// Base exception class for all Robin Radio app exceptions.
///
/// This serves as the common interface for all custom exceptions
/// throughout the application, providing standardized error handling.
abstract class AppException implements Exception {
  /// Creates a new AppException with the specified message and error code.
  ///
  /// [message] A human-readable error message for logging and debugging.
  /// [errorCode] A machine-readable error code for programmatic handling.
  /// [cause] Optional underlying cause or original exception.
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

/// Severity levels for exceptions to categorize error importance.
///
/// Used for filtering, alerting, and prioritizing error handling.
/// - [low]: Minor issues that don't affect core functionality
/// - [medium]: Standard errors that may impact user experience
/// - [high]: Serious errors that significantly impact functionality
/// - [critical]: Severe errors that may crash the app or lose data
enum ExceptionSeverity { low, medium, high, critical }

/// Authentication-related exception for user access and security issues.
///
/// Handles scenarios where user authentication fails, sessions expire,
/// or permission is denied for specific resources or actions.
class AuthException extends AppException {
  /// Creates a new AuthException with the specified message and error code.
  ///
  /// [message] Description of the authentication error.
  /// [errorCode] Machine-readable error code for programmatic handling.
  /// [cause] Optional underlying cause of the authentication failure.
  const AuthException(super.message, super.errorCode, [super.cause]);

  /// Creates an auth exception for user not authenticated.
  ///
  /// Used when attempting to access protected resources without authentication.
  const AuthException.notAuthenticated()
      : super(
          'User is not authenticated. Please sign in.',
          'AUTH_NOT_AUTHENTICATED',
        );

  /// Creates an auth exception for invalid credentials.
  ///
  /// Used when login fails due to incorrect username/password combination.
  const AuthException.invalidCredentials()
      : super(
          'Invalid credentials provided.',
          'AUTH_INVALID_CREDENTIALS',
        );

  /// Creates an auth exception for expired session.
  ///
  /// Used when user session has timed out and requires re-authentication.
  const AuthException.sessionExpired()
      : super(
          'Session has expired. Please sign in again.',
          'AUTH_SESSION_EXPIRED',
        );

  /// Creates an auth exception for permission denied.
  ///
  /// Used when user lacks permission to access specific resources or features.
  ///
  /// [resource] Optional name of the resource that was denied access.
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

/// General application error for unexpected conditions and system failures.
///
/// Handles scenarios where the app encounters unexpected errors, fails to
/// initialize properly, or encounters configuration problems that prevent
/// normal operation.
class AppError extends AppException {
  /// Creates a new AppError with the specified message and error code.
  ///
  /// [message] Description of the application error.
  /// [errorCode] Machine-readable error code for programmatic handling.
  /// [cause] Optional underlying cause of the application error.
  const AppError(super.message, super.errorCode, [super.cause]);

  /// Creates an app error for unexpected conditions.
  ///
  /// Used for catching and wrapping unexpected exceptions that don't fit
  /// into other specific error categories.
  ///
  /// [details] Optional additional details about the unexpected error.
  const AppError.unexpected([String? details])
      : super(
          'An unexpected error occurred${details != null ? ': $details' : '.'}',
          'APP_UNEXPECTED_ERROR',
        );

  /// Creates an app error for initialization failures.
  ///
  /// Used when critical app components fail to initialize properly during
  /// startup, preventing the app from functioning normally.
  ///
  /// [component] Name of the component that failed to initialize.
  const AppError.initializationFailed(String component)
      : super(
          'Failed to initialize $component',
          'APP_INITIALIZATION_FAILED',
        );

  /// Creates an app error for configuration issues.
  ///
  /// Used when the app encounters invalid or missing configuration settings
  /// that prevent proper operation.
  ///
  /// [setting] Name of the configuration setting that has an issue.
  const AppError.configurationError(String setting)
      : super(
          'Configuration error: $setting',
          'APP_CONFIGURATION_ERROR',
        );

  @override
  String get category => 'application';
}
