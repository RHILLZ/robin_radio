import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/exceptions/app_exception.dart';
import '../../data/exceptions/audio_service_exception.dart';
import '../../data/exceptions/repository_exception.dart';

// Re-export repository exceptions for convenience
export '../../data/exceptions/repository_exception.dart';

/// Centralized error handler for the Robin Radio application.
///
/// Provides unified error handling with:
/// - Categorized error handling (network, audio, parsing, general)
/// - User-friendly error messages
/// - Optional Firebase Crashlytics integration
/// - Logging and debugging support
/// - Retry mechanism for recoverable errors
///
/// ## Usage
///
/// ```dart
/// // Initialize at app startup
/// ErrorHandler.initialize();
///
/// // Handle errors
/// try {
///   await someOperation();
/// } catch (e, stackTrace) {
///   ErrorHandler.handleError(e, stackTrace);
/// }
///
/// // Show user-friendly error
/// ErrorHandler.showErrorSnackbar(exception);
/// ```
class ErrorHandler {
  ErrorHandler._();

  static ErrorHandler? _instance;
  static bool _isInitialized = false;

  /// Crashlytics callback for external integration.
  /// Set this to enable Firebase Crashlytics reporting.
  static Future<void> Function(Object error, StackTrace? stackTrace)?
      onCrashlyticsReport;

  /// Callback for custom error logging (e.g., analytics).
  static void Function(ErrorReport report)? onErrorLogged;

  /// Get the singleton instance.
  static ErrorHandler get instance {
    _instance ??= ErrorHandler._();
    return _instance!;
  }

  /// Initialize the error handler.
  ///
  /// Should be called once at app startup, typically in main().
  /// Sets up Flutter error handling and zone error catching.
  static void initialize({
    Future<void> Function(Object error, StackTrace? stackTrace)?
        crashlyticsCallback,
    void Function(ErrorReport report)? errorLogCallback,
  }) {
    if (_isInitialized) {
      return;
    }

    onCrashlyticsReport = crashlyticsCallback;
    onErrorLogged = errorLogCallback;

    // Set up Flutter framework error handling
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      _reportError(
        details.exception,
        details.stack,
        context: 'FlutterError',
        isFatal: true,
      );
    };

    // Handle errors outside of Flutter framework
    PlatformDispatcher.instance.onError = (error, stack) {
      _reportError(error, stack, context: 'PlatformDispatcher', isFatal: true);
      return true;
    };

    _isInitialized = true;

    if (kDebugMode) {
      debugPrint('ErrorHandler initialized');
    }
  }

  /// Main error handling method.
  ///
  /// Categorizes the error, logs it appropriately, and optionally
  /// reports to Crashlytics. Returns an [ErrorReport] for further handling.
  static ErrorReport handleError(
    Object error, [
    StackTrace? stackTrace,
    String? context,
  ]) {
    final report = _createErrorReport(error, stackTrace, context);

    // Log to console in debug mode
    if (kDebugMode) {
      _logErrorToConsole(report);
    }

    // Report to Crashlytics if configured
    _reportError(error, stackTrace, context: context);

    // Notify custom logger if configured
    onErrorLogged?.call(report);

    return report;
  }

  /// Handle network-related errors.
  ///
  /// Provides specific handling for connection failures, timeouts,
  /// and server errors with appropriate user messaging.
  static ErrorReport handleNetworkError(
    Object error, [
    StackTrace? stackTrace,
  ]) {
    final report = handleError(error, stackTrace, 'Network');

    if (kDebugMode) {
      debugPrint('Network error: ${report.userMessage}');
    }

    return report;
  }

  /// Handle audio playback errors.
  ///
  /// Provides specific handling for audio loading, playback,
  /// and codec-related errors.
  static ErrorReport handleAudioError(
    Object error, [
    StackTrace? stackTrace,
  ]) {
    final report = handleError(error, stackTrace, 'Audio');

    if (kDebugMode) {
      debugPrint('Audio error: ${report.userMessage}');
    }

    return report;
  }

  /// Handle data parsing errors.
  ///
  /// Provides specific handling for JSON parsing, data validation,
  /// and format-related errors.
  static ErrorReport handleParsingError(
    Object error, [
    StackTrace? stackTrace,
  ]) {
    final report = handleError(error, stackTrace, 'Parsing');

    if (kDebugMode) {
      debugPrint('Parsing error: ${report.userMessage}');
    }

    return report;
  }

  /// Show a user-friendly error message as a snackbar.
  ///
  /// Automatically determines the appropriate message based on
  /// the error type and severity.
  static void showErrorSnackbar(
    Object error, {
    Duration duration = const Duration(seconds: 4),
    SnackPosition position = SnackPosition.BOTTOM,
    bool showRetry = false,
    VoidCallback? onRetry,
  }) {
    final report = error is ErrorReport
        ? error
        : _createErrorReport(error, null, null);

    Get.snackbar(
      _getErrorTitle(report.category),
      report.userMessage,
      snackPosition: position,
      duration: duration,
      backgroundColor: _getErrorColor(report.severity),
      colorText: Colors.white,
      icon: Icon(
        _getErrorIcon(report.category),
        color: Colors.white,
      ),
      mainButton: showRetry && onRetry != null
          ? TextButton(
              onPressed: () {
                Get.closeCurrentSnackbar();
                onRetry();
              },
              child: const Text(
                'Retry',
                style: TextStyle(color: Colors.white),
              ),
            )
          : null,
    );
  }

  /// Show an error dialog for critical errors.
  ///
  /// Use for errors that require user acknowledgment before proceeding.
  static Future<void> showErrorDialog(
    Object error, {
    String? title,
    bool showDetails = false,
    VoidCallback? onDismiss,
  }) async {
    final report = error is ErrorReport
        ? error
        : _createErrorReport(error, null, null);

    await Get.dialog<void>(
      AlertDialog(
        title: Text(title ?? _getErrorTitle(report.category)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(report.userMessage),
            if (showDetails && report.suggestedActions.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Suggested actions:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...report.suggestedActions.map(
                (action) => Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('- '),
                      Expanded(child: Text(action)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back<void>();
              onDismiss?.call();
            },
            child: const Text('OK'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  /// Execute an operation with automatic error handling.
  ///
  /// Wraps the operation in try-catch and provides consistent
  /// error handling with optional retry support.
  static Future<T?> tryOperation<T>(
    Future<T> Function() operation, {
    String? context,
    bool showError = true,
    bool allowRetry = false,
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 1),
  }) async {
    var attempts = 0;

    while (attempts < maxRetries) {
      try {
        return await operation();
      } catch (e, stackTrace) {
        attempts++;
        final report = handleError(e, stackTrace, context);

        // Check if we should retry
        if (allowRetry && report.isRecoverable && attempts < maxRetries) {
          if (kDebugMode) {
            debugPrint(
              'Retrying operation (attempt $attempts/$maxRetries)...',
            );
          }
          await Future<void>.delayed(retryDelay * attempts);
          continue;
        }

        // Show error if requested
        if (showError) {
          showErrorSnackbar(
            report,
            showRetry: allowRetry && report.isRecoverable,
            onRetry: allowRetry
                ? () => tryOperation(
                      operation,
                      context: context,
                      showError: showError,
                      allowRetry: allowRetry,
                      maxRetries: maxRetries,
                      retryDelay: retryDelay,
                    )
                : null,
          );
        }

        return null;
      }
    }

    return null;
  }

  /// Create an error report from the given error.
  static ErrorReport _createErrorReport(
    Object error,
    StackTrace? stackTrace,
    String? context,
  ) {
    if (error is AppException) {
      return ErrorReport(
        error: error,
        stackTrace: stackTrace,
        context: context,
        category: _categorizeAppException(error),
        severity: error.severity,
        userMessage: error.userMessage,
        technicalMessage: error.message,
        errorCode: error.errorCode,
        isRecoverable: error.isRecoverable,
        suggestedActions: error.suggestedActions,
      );
    }

    // Handle generic errors
    return ErrorReport(
      error: error,
      stackTrace: stackTrace,
      context: context,
      category: ErrorCategory.unknown,
      severity: ExceptionSeverity.medium,
      userMessage: 'Something went wrong. Please try again.',
      technicalMessage: error.toString(),
      errorCode: 'UNKNOWN_ERROR',
      isRecoverable: true,
      suggestedActions: ['Try again in a moment'],
    );
  }

  /// Categorize an AppException into an ErrorCategory.
  static ErrorCategory _categorizeAppException(AppException exception) {
    if (exception is AudioServiceException) {
      return ErrorCategory.audio;
    }
    if (exception is NetworkRepositoryException) {
      return ErrorCategory.network;
    }
    if (exception is CacheRepositoryException) {
      return ErrorCategory.cache;
    }
    if (exception is DataRepositoryException) {
      return ErrorCategory.data;
    }
    if (exception is FirebaseRepositoryException) {
      // Firebase errors could be network, auth, or data related
      if (exception.errorCode == 'FIREBASE_AUTH_FAILED') {
        return ErrorCategory.authentication;
      }
      return ErrorCategory.network;
    }
    if (exception is RepositoryException) {
      return ErrorCategory.data;
    }
    if (exception is AuthException) {
      return ErrorCategory.authentication;
    }
    return ErrorCategory.unknown;
  }

  /// Report error to Crashlytics if configured.
  static void _reportError(
    Object error,
    StackTrace? stackTrace, {
    String? context,
    bool isFatal = false,
  }) {
    if (onCrashlyticsReport != null) {
      // Wrap in try-catch to prevent errors in error handling
      try {
        onCrashlyticsReport!(error, stackTrace ?? StackTrace.current);
      } on Exception catch (e) {
        if (kDebugMode) {
          debugPrint('Failed to report error to Crashlytics: $e');
        }
      }
    }
  }

  /// Log error to console in debug mode.
  static void _logErrorToConsole(ErrorReport report) {
    debugPrint('');
    debugPrint('=== ERROR REPORT ===');
    debugPrint('Category: ${report.category.name}');
    debugPrint('Severity: ${report.severity.name}');
    debugPrint('Code: ${report.errorCode}');
    debugPrint('Context: ${report.context ?? 'N/A'}');
    debugPrint('Technical: ${report.technicalMessage}');
    debugPrint('User Message: ${report.userMessage}');
    debugPrint('Recoverable: ${report.isRecoverable}');
    if (report.stackTrace != null) {
      debugPrint('Stack Trace:');
      debugPrint(report.stackTrace.toString());
    }
    debugPrint('====================');
    debugPrint('');
  }

  /// Get appropriate title for error category.
  static String _getErrorTitle(ErrorCategory category) {
    switch (category) {
      case ErrorCategory.network:
        return 'Connection Error';
      case ErrorCategory.audio:
        return 'Playback Error';
      case ErrorCategory.cache:
        return 'Storage Error';
      case ErrorCategory.data:
        return 'Data Error';
      case ErrorCategory.authentication:
        return 'Authentication Error';
      case ErrorCategory.unknown:
        return 'Error';
    }
  }

  /// Get appropriate color for error severity.
  static Color _getErrorColor(ExceptionSeverity severity) {
    switch (severity) {
      case ExceptionSeverity.low:
        return Colors.orange.shade700;
      case ExceptionSeverity.medium:
        return Colors.deepOrange.shade700;
      case ExceptionSeverity.high:
        return Colors.red.shade700;
      case ExceptionSeverity.critical:
        return Colors.red.shade900;
    }
  }

  /// Get appropriate icon for error category.
  static IconData _getErrorIcon(ErrorCategory category) {
    switch (category) {
      case ErrorCategory.network:
        return Icons.wifi_off;
      case ErrorCategory.audio:
        return Icons.music_off;
      case ErrorCategory.cache:
        return Icons.storage;
      case ErrorCategory.data:
        return Icons.error_outline;
      case ErrorCategory.authentication:
        return Icons.lock_outline;
      case ErrorCategory.unknown:
        return Icons.warning_amber;
    }
  }
}

/// Categories of errors for appropriate handling.
enum ErrorCategory {
  /// Network-related errors (connection, timeout, server)
  network,

  /// Audio playback errors (loading, codec, device)
  audio,

  /// Cache/storage errors (read, write, corruption)
  cache,

  /// Data errors (parsing, validation, format)
  data,

  /// Authentication errors (login, session, permission)
  authentication,

  /// Unknown or uncategorized errors
  unknown,
}

/// Comprehensive error report with all relevant information.
///
/// Contains both user-facing and technical information for proper
/// error handling, logging, and recovery.
class ErrorReport {
  /// Creates an error report.
  const ErrorReport({
    required this.error,
    required this.category,
    required this.severity,
    required this.userMessage,
    required this.technicalMessage,
    required this.errorCode,
    required this.isRecoverable,
    required this.suggestedActions,
    this.stackTrace,
    this.context,
  });

  /// The original error object.
  final Object error;

  /// Stack trace at the point of error.
  final StackTrace? stackTrace;

  /// Context where the error occurred.
  final String? context;

  /// Category of the error for handling.
  final ErrorCategory category;

  /// Severity level for prioritization.
  final ExceptionSeverity severity;

  /// User-friendly message for display.
  final String userMessage;

  /// Technical message for logging.
  final String technicalMessage;

  /// Machine-readable error code.
  final String errorCode;

  /// Whether the error can be recovered from.
  final bool isRecoverable;

  /// Suggested actions for the user.
  final List<String> suggestedActions;

  /// Convert to map for logging/analytics.
  Map<String, dynamic> toMap() => {
        'category': category.name,
        'severity': severity.name,
        'errorCode': errorCode,
        'context': context,
        'userMessage': userMessage,
        'technicalMessage': technicalMessage,
        'isRecoverable': isRecoverable,
        'suggestedActions': suggestedActions,
        'timestamp': DateTime.now().toIso8601String(),
      };

  @override
  String toString() => 'ErrorReport($errorCode: $technicalMessage)';
}
