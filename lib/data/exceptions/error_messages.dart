/// Utility class for standardized error messages throughout the app
class ErrorMessages {
  ErrorMessages._();

  /// Audio-related error messages
  static const Map<String, String> audio = {
    'LOAD_FAILED': 'Unable to load this track. Please try another song.',
    'NETWORK_ERROR':
        'Connection lost while playing. Check your internet connection.',
    'UNSUPPORTED_FORMAT': 'This audio format is not supported on your device.',
    'PLAYBACK_FAILED': 'Playback failed. Please try again.',
    'INIT_FAILED': 'Audio system could not start. Please restart the app.',
    'PERMISSION_DENIED': 'Audio permissions are required to play music.',
    'DEVICE_ERROR':
        'Audio device is not available. Check your headphones or speakers.',
    'INVALID_STATE': 'Cannot perform this action right now. Please try again.',
    'SERVICE_DISPOSED':
        'Audio service needs to restart. Please reopen the app.',
    'INVALID_PARAMETER': 'Invalid audio settings detected.',
    'EMPTY_QUEUE': 'No songs in your playlist. Add some music to continue.',
    'INVALID_INDEX': 'Song not found in playlist.',
    'QUEUE_FULL': 'Your playlist is full. Remove some songs to add more.',
  };

  /// Network-related error messages
  static const Map<String, String> network = {
    'NETWORK_NO_CONNECTION':
        'No internet connection. Connect to Wi-Fi or cellular data.',
    'NETWORK_UNSTABLE_CONNECTION':
        'Your connection is unstable. Find a stronger signal.',
    'NETWORK_AIRPLANE_MODE':
        'Airplane mode is on. Turn off airplane mode to connect.',
    'NETWORK_QUALITY_TIMEOUT':
        'Connection test timed out. Check your internet speed.',
    'NETWORK_QUALITY_SPEED_TEST_FAILED': 'Unable to test connection speed.',
    'NETWORK_QUALITY_INSUFFICIENT_DATA':
        'Not enough data to assess connection quality.',
    'NETWORK_RETRY_MAX_ATTEMPTS_EXCEEDED':
        'Connection failed after multiple attempts.',
    'NETWORK_RETRY_TIMEOUT': 'Connection timeout. Please try again.',
    'NETWORK_RETRY_INVALID_CONFIG': 'Network configuration error.',
    'NETWORK_MONITORING_START_FAILED': 'Unable to monitor network status.',
    'NETWORK_MONITORING_ALREADY_ACTIVE':
        'Network monitoring is already running.',
    'NETWORK_MONITORING_PLATFORM_NOT_SUPPORTED':
        'Network monitoring not supported on this device.',
    'NETWORK_HOST_UNREACHABLE': 'Music server is not reachable.',
    'NETWORK_DNS_RESOLUTION_FAILED': 'Cannot resolve server address.',
    'NETWORK_CONNECTION_TIMEOUT': 'Connection to music server timed out.',
    'NETWORK_SERVICE_PLATFORM_NOT_SUPPORTED':
        'Network features not supported on this device.',
    'NETWORK_SERVICE_PERMISSIONS_DENIED':
        'Network permissions required for streaming.',
    'NETWORK_SERVICE_ALREADY_INITIALIZED': 'Network service already started.',
    'NETWORK_USAGE_TRACKING_NOT_AVAILABLE':
        'Data usage tracking not available.',
    'NETWORK_USAGE_INSUFFICIENT_PERMISSIONS':
        'Permissions needed to track data usage.',
    'NETWORK_USAGE_DATA_COLLECTION_FAILED':
        'Cannot collect data usage statistics.',
  };

  /// Cache-related error messages
  static const Map<String, String> cache = {
    'CACHE_READ_KEY_ACCESS_FAILED': 'Unable to access cached data.',
    'CACHE_READ_DESERIALIZATION_FAILED':
        'Cached data is corrupted. Please refresh.',
    'CACHE_READ_CORRUPTED_DATA': 'Some data is corrupted. Refreshing content.',
    'CACHE_READ_DISK_ACCESS_FAILED':
        'Cannot access storage. Check device storage.',
    'CACHE_WRITE_KEY_FAILED': 'Unable to save data. Check available storage.',
    'CACHE_WRITE_SERIALIZATION_FAILED': 'Failed to save data.',
    'CACHE_WRITE_DISK_SPACE_FULL':
        'Storage is full. Free up space to continue.',
    'CACHE_WRITE_DISK_ACCESS_FAILED': 'Cannot access storage for saving.',
    'CACHE_WRITE_SIZE_LIMIT_EXCEEDED':
        'Cache is full. Some content may be refreshed.',
    'CACHE_MANAGEMENT_CLEAR_FAILED': 'Failed to clear cached data.',
    'CACHE_MANAGEMENT_INITIALIZATION_FAILED': 'Cache system failed to start.',
    'CACHE_MANAGEMENT_CLEANUP_FAILED': 'Unable to clean up old cache files.',
    'CACHE_MANAGEMENT_STATISTICS_FAILED': 'Cannot collect cache statistics.',
    'CACHE_MANAGEMENT_SIZE_FAILED': 'Unable to determine cache size.',
    'CACHE_CONFIG_INVALID_SIZE': 'Invalid cache configuration.',
    'CACHE_CONFIG_INVALID_EXPIRY': 'Invalid cache expiry settings.',
    'CACHE_CONFIG_INVALID_KEY': 'Invalid cache key format.',
    'CACHE_CONFIG_UNSUPPORTED_TYPE': 'Unsupported data type for caching.',
    'CACHE_TIMEOUT_READ': 'Reading cached data timed out.',
    'CACHE_TIMEOUT_WRITE': 'Saving data timed out.',
    'CACHE_TIMEOUT_CLEANUP': 'Cache cleanup timed out.',
  };

  /// Repository-related error messages
  static const Map<String, String> repository = {
    'NETWORK_CONNECTION_FAILED':
        'Cannot connect to music library. Check your connection.',
    'NETWORK_TIMEOUT': 'Music library request timed out. Please try again.',
    'NETWORK_SERVER_ERROR': 'Music library server error. Try again later.',
    'CACHE_READ_FAILED': 'Cannot read saved music data.',
    'CACHE_WRITE_FAILED': 'Cannot save music data to device.',
    'CACHE_CORRUPTED': 'Saved music data is corrupted. Refreshing library.',
    'DATA_PARSING_FAILED':
        'Music data format error. Please refresh your library.',
    'DATA_NOT_FOUND': 'Music data not found. Check your library.',
    'DATA_INVALID_FORMAT': 'Invalid music data format.',
    'FIREBASE_AUTH_FAILED': 'Authentication failed. Please sign in again.',
    'FIREBASE_PERMISSION_DENIED':
        "You don't have permission to access this content.",
    'FIREBASE_STORAGE_ERROR': 'Cloud storage error. Please try again.',
  };

  /// Authentication-related error messages
  static const Map<String, String> auth = {
    'AUTH_NOT_AUTHENTICATED': 'Please sign in to access your music.',
    'AUTH_INVALID_CREDENTIALS': 'Invalid username or password.',
    'AUTH_SESSION_EXPIRED': 'Your session has expired. Please sign in again.',
    'AUTH_PERMISSION_DENIED':
        "You don't have permission to access this feature.",
  };

  /// Application-level error messages
  static const Map<String, String> app = {
    'APP_UNEXPECTED_ERROR': 'Something went wrong. Please try again.',
    'APP_INITIALIZATION_FAILED':
        'App failed to start properly. Please restart.',
    'APP_CONFIGURATION_ERROR': 'App configuration error. Please reinstall.',
  };

  /// Get user-friendly message for an error code and category
  static String getUserMessage(String errorCode, String category) {
    final categoryMessages = _getCategoryMessages(category);
    return categoryMessages[errorCode] ??
        'An unexpected error occurred. Please try again.';
  }

  /// Get technical message for logging (same as original message)
  static String getTechnicalMessage(String message) => message;

  /// Check if an error is user-actionable (user can do something about it)
  static bool isUserActionable(String errorCode, String category) {
    // Define which error codes the user can potentially fix
    const userActionableErrors = {
      'NETWORK_NO_CONNECTION',
      'NETWORK_AIRPLANE_MODE',
      'CACHE_WRITE_DISK_SPACE_FULL',
      'AUTH_NOT_AUTHENTICATED',
      'AUTH_INVALID_CREDENTIALS',
      'AUTH_SESSION_EXPIRED',
      'PERMISSION_DENIED',
      'AUDIO_PERMISSION_DENIED',
    };

    return userActionableErrors.contains(errorCode);
  }

  /// Get suggested user actions for specific errors
  static List<String> getSuggestedActions(String errorCode, String category) {
    final actions = <String>[];

    switch (errorCode) {
      case 'NETWORK_NO_CONNECTION':
        actions.addAll([
          'Check your Wi-Fi connection',
          'Try using cellular data',
          'Move to an area with better signal',
        ]);
        break;
      case 'NETWORK_AIRPLANE_MODE':
        actions.add('Turn off airplane mode in Settings');
        break;
      case 'CACHE_WRITE_DISK_SPACE_FULL':
        actions.addAll([
          'Free up storage space',
          'Delete unused apps or files',
          'Clear app cache in Settings',
        ]);
        break;
      case 'AUTH_NOT_AUTHENTICATED':
      case 'AUTH_SESSION_EXPIRED':
        actions.add('Sign in with your account');
        break;
      case 'AUTH_INVALID_CREDENTIALS':
        actions.addAll([
          'Check your username and password',
          'Try resetting your password',
        ]);
        break;
      case 'PERMISSION_DENIED':
      case 'AUDIO_PERMISSION_DENIED':
        actions.add('Grant permissions in Settings');
        break;
      default:
        actions.add('Try again in a moment');
        break;
    }

    return actions;
  }

  static Map<String, String> _getCategoryMessages(String category) {
    switch (category) {
      case 'audio':
        return audio;
      case 'network':
        return network;
      case 'cache':
        return cache;
      case 'repository':
        return repository;
      case 'authentication':
        return auth;
      case 'application':
        return app;
      default:
        return const {};
    }
  }
}
