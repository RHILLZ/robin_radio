import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';

/// Whether Firebase Performance tracing is supported on the current platform.
///
/// On web, Firebase Performance has a known issue where calling newTrace()
/// multiple times causes "initializePerformance() already called" errors.
/// We disable tracing on web to avoid these errors until the SDK is fixed.
bool get _isTracingSupported => !kIsWeb;

/// Comprehensive performance monitoring service for application analytics and optimization.
///
/// Provides Firebase Performance Monitoring integration for tracking key application
/// performance metrics, user flows, and bottlenecks. Enables data-driven optimization
/// by measuring real-world performance characteristics across different devices and
/// network conditions.
///
/// Key capabilities:
/// - **Custom trace monitoring**: Track specific user flows and operations
/// - **Automatic metric collection**: Firebase's built-in network and startup metrics
/// - **Custom attributes**: Add contextual information to performance traces
/// - **Debug logging**: Development-time visibility into performance tracking
/// - **Graceful error handling**: Continues operation even if Firebase services fail
/// - **Production optimization**: Minimal overhead in release builds
///
/// The service automatically handles Firebase Performance initialization and provides
/// convenient methods for tracking common application flows like music loading,
/// player initialization, and album browsing.
///
/// Usage patterns:
/// ```dart
/// final perf = PerformanceService();
///
/// // Track app startup
/// await perf.startAppStartTrace();
/// // ... initialization logic ...
/// await perf.stopAppStartTrace();
///
/// // Track music loading with metrics
/// await perf.startMusicLoadTrace();
/// final albums = await loadMusic();
/// await perf.stopMusicLoadTrace(
///   albumCount: albums.length,
///   fromCache: true,
/// );
/// ```
///
/// All methods are designed to be safe to call even if Firebase Performance
/// is not properly configured, ensuring the service doesn't break application
/// functionality in development or edge-case deployment scenarios.
class PerformanceService {
  /// Creates a new instance of [PerformanceService].
  ///
  /// Lifecycle is managed by ServiceLocator via GetX dependency injection.

  final FirebasePerformance _performance = FirebasePerformance.instance;

  // Custom traces for key user flows
  Trace? _appStartTrace;
  Trace? _musicLoadTrace;
  Trace? _albumLoadTrace;
  Trace? _playerInitTrace;
  Trace? _imageLoadTrace;
  Trace? _audioBufferTrace;
  Trace? _searchTrace;
  Trace? _navigationTrace;

  /// Initialize performance monitoring and enable data collection.
  ///
  /// Sets up Firebase Performance Monitoring for the application, enabling
  /// automatic collection of network requests, app startup metrics, and
  /// custom trace data. This method should be called early in the app
  /// lifecycle, typically during app initialization.
  ///
  /// Initialization includes:
  /// - Enabling Firebase Performance data collection
  /// - Configuring automatic network request monitoring
  /// - Setting up crash-safe trace management
  /// - Enabling debug logging in development builds
  ///
  /// The method handles initialization failures gracefully, logging errors
  /// in debug mode but not throwing exceptions that could break app startup.
  /// Performance monitoring will simply be disabled if initialization fails.
  ///
  /// Example usage:
  /// ```dart
  /// @override
  /// void initState() {
  ///   super.initState();
  ///   PerformanceService().initialize();
  /// }
  /// ```
  Future<void> initialize() async {
    try {
      // Enable performance collection (no-op for web)
      await _performance.setPerformanceCollectionEnabled(true);

      if (kDebugMode) {
        print('Performance monitoring initialized');
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Error initializing performance monitoring: $e');
      }
    }
  }

  /// Start tracking application startup performance.
  ///
  /// Begins monitoring the app startup sequence to measure initialization
  /// time and identify potential bottlenecks in the launch process. This
  /// trace should be started as early as possible in the main() function
  /// or app initialization sequence.
  ///
  /// The app start trace measures:
  /// - Time from trace start to stop
  /// - Device and platform characteristics
  /// - Network conditions during startup
  /// - Any custom attributes added during the startup process
  ///
  /// Best practices:
  /// - Start immediately in main() or early widget initialization
  /// - Stop after critical UI components are ready for user interaction
  /// - Add relevant attributes like user authentication status
  /// - Measure different startup paths (cold start, warm start, etc.)
  ///
  /// Example usage:
  /// ```dart
  /// void main() async {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///   await PerformanceService().startAppStartTrace();
  ///
  ///   // App initialization...
  ///   runApp(MyApp());
  /// }
  /// ```
  Future<void> startAppStartTrace() async {
    if (!_isTracingSupported) {
      if (kDebugMode) {
        print('App start trace skipped (web platform)');
      }
      return;
    }

    try {
      _appStartTrace = _performance.newTrace('app_start');
      await _appStartTrace?.start();

      if (kDebugMode) {
        print('App start trace started');
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Error starting app start trace: $e');
      }
    }
  }

  /// Stop the application startup performance trace.
  ///
  /// Completes measurement of the app startup sequence and submits the
  /// performance data to Firebase. Should be called when the app has
  /// finished its critical initialization and is ready for user interaction.
  ///
  /// The stopped trace will include:
  /// - Total startup duration
  /// - Device performance characteristics
  /// - Network conditions during startup
  /// - Any custom attributes or metrics added
  ///
  /// Timing considerations:
  /// - Call after UI is fully rendered and interactive
  /// - Include time for essential data loading (user profile, settings)
  /// - Exclude time for non-critical background operations
  /// - Consider different definition of "ready" for different user flows
  ///
  /// Example usage:
  /// ```dart
  /// @override
  /// void initState() {
  ///   super.initState();
  ///   // After critical components are loaded
  ///   WidgetsBinding.instance.addPostFrameCallback((_) {
  ///     PerformanceService().stopAppStartTrace();
  ///   });
  /// }
  /// ```
  Future<void> stopAppStartTrace() async {
    try {
      await _appStartTrace?.stop();
      _appStartTrace = null;

      if (kDebugMode) {
        print('App start trace stopped');
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Error stopping app start trace: $e');
      }
    }
  }

  /// Start tracking music library loading performance.
  ///
  /// Begins monitoring the process of loading music content from various
  /// sources including remote APIs, local cache, and offline storage.
  /// Essential for optimizing the music discovery and browsing experience.
  ///
  /// The music load trace captures:
  /// - Time to load album and track listings
  /// - Network vs. cache performance differences
  /// - Data source reliability and speed
  /// - Content volume impact on loading times
  ///
  /// This trace should encompass the complete music loading flow from
  /// initiation to when content is ready for display. It pairs with
  /// [stopMusicLoadTrace] which accepts metrics about the loaded content.
  ///
  /// Use cases:
  /// - Loading the main music library view
  /// - Refreshing content from remote sources
  /// - Loading search results
  /// - Restoring cached content on app startup
  ///
  /// Example usage:
  /// ```dart
  /// Future<List<Album>> loadMusicLibrary() async {
  ///   await PerformanceService().startMusicLoadTrace();
  ///
  ///   try {
  ///     final albums = await musicRepository.getAlbums();
  ///     await PerformanceService().stopMusicLoadTrace(
  ///       albumCount: albums.length,
  ///       fromCache: false,
  ///     );
  ///     return albums;
  ///   } catch (e) {
  ///     await PerformanceService().stopMusicLoadTrace();
  ///     rethrow;
  ///   }
  /// }
  /// ```
  Future<void> startMusicLoadTrace() async {
    if (!_isTracingSupported) {
      if (kDebugMode) {
        print('Music load trace skipped (web platform)');
      }
      return;
    }

    try {
      _musicLoadTrace = _performance.newTrace('music_load');
      await _musicLoadTrace?.start();

      if (kDebugMode) {
        print('Music load trace started');
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Error starting music load trace: $e');
      }
    }
  }

  /// Stop music loading trace and record performance metrics.
  ///
  /// Completes the music loading performance measurement and enriches the
  /// trace with contextual information about the loaded content. The metrics
  /// help identify patterns in loading performance based on content volume
  /// and data sources.
  ///
  /// [albumCount] Number of albums loaded in this operation. Helps correlate
  ///              performance with content volume. Higher counts may indicate
  ///              longer loading times or more efficient batch operations.
  ///
  /// [songCount] Total number of individual tracks loaded. Useful for
  ///            understanding the granularity of content and its impact
  ///            on loading performance.
  ///
  /// [fromCache] Whether the content was loaded from local cache rather
  ///            than remote sources. Critical for understanding cache
  ///            effectiveness and network dependency patterns.
  ///
  /// Metrics analysis:
  /// - Compare cache vs. network loading times
  /// - Identify content volume performance thresholds
  /// - Track loading time trends over different network conditions
  /// - Optimize based on content type and volume patterns
  ///
  /// Example usage:
  /// ```dart
  /// final result = await musicApi.loadLibrary();
  /// await PerformanceService().stopMusicLoadTrace(
  ///   albumCount: result.albums.length,
  ///   songCount: result.albums.fold(0, (sum, album) => sum + album.trackCount),
  ///   fromCache: result.source == DataSource.cache,
  /// );
  /// ```
  Future<void> stopMusicLoadTrace({
    int? albumCount,
    int? songCount,
    bool? fromCache,
  }) async {
    try {
      if (_musicLoadTrace != null) {
        // Add custom metrics
        if (albumCount != null) {
          _musicLoadTrace!.setMetric('album_count', albumCount);
        }
        if (songCount != null) {
          _musicLoadTrace!.setMetric('song_count', songCount);
        }

        // Add custom attributes
        if (fromCache != null) {
          _musicLoadTrace!.putAttribute('from_cache', fromCache.toString());
        }

        await _musicLoadTrace?.stop();
        _musicLoadTrace = null;

        if (kDebugMode) {
          print('Music load trace stopped with metrics');
        }
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Error stopping music load trace: $e');
      }
    }
  }

  /// Start tracking individual album loading performance.
  ///
  /// Begins monitoring the process of loading detailed information for a
  /// specific album, including track listings, metadata, and artwork.
  /// Essential for optimizing the album detail view experience.
  ///
  /// [albumId] The unique identifier of the album being loaded. This ID
  ///          is recorded as a trace attribute to enable analysis of
  ///          performance patterns for specific albums or album types.
  ///
  /// The album load trace measures:
  /// - Time to load complete album details
  /// - Track listing retrieval performance
  /// - Artwork and metadata loading efficiency
  /// - Cache hit rates for individual albums
  ///
  /// Album loading patterns to monitor:
  /// - Popular albums may have better cache performance
  /// - New releases might show slower loading from remote sources
  /// - Large albums (many tracks) may have different performance characteristics
  /// - Album artwork size and format impact on loading times
  ///
  /// Example usage:
  /// ```dart
  /// Future<Album> loadAlbumDetails(String albumId) async {
  ///   await PerformanceService().startAlbumLoadTrace(albumId);
  ///
  ///   try {
  ///     final album = await musicRepository.getAlbumDetails(albumId);
  ///     await PerformanceService().stopAlbumLoadTrace(
  ///       trackCount: album.tracks.length,
  ///     );
  ///     return album;
  ///   } catch (e) {
  ///     await PerformanceService().stopAlbumLoadTrace();
  ///     rethrow;
  ///   }
  /// }
  /// ```
  Future<void> startAlbumLoadTrace(String albumId) async {
    if (!_isTracingSupported) {
      if (kDebugMode) {
        print('Album load trace skipped (web platform)');
      }
      return;
    }

    try {
      _albumLoadTrace = _performance.newTrace('album_load');
      _albumLoadTrace?.putAttribute('album_id', albumId);
      await _albumLoadTrace?.start();

      if (kDebugMode) {
        print('Album load trace started for: $albumId');
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Error starting album load trace: $e');
      }
    }
  }

  /// Stop album loading trace and record track count metrics.
  ///
  /// Completes the album loading performance measurement and records
  /// the number of tracks loaded, which helps correlate album size
  /// with loading performance.
  ///
  /// [trackCount] Number of tracks in the loaded album. This metric
  ///             helps identify whether albums with more tracks take
  ///             proportionally longer to load or if there are
  ///             optimization opportunities for large albums.
  ///
  /// Performance insights from track count:
  /// - Linear relationship between tracks and loading time
  /// - Batch loading efficiency for large albums
  /// - Cache effectiveness for different album sizes
  /// - Optimal loading strategies based on album complexity
  ///
  /// Example usage:
  /// ```dart
  /// final albumDetails = await albumApi.getDetails(albumId);
  /// await PerformanceService().stopAlbumLoadTrace(
  ///   trackCount: albumDetails.tracks.length,
  /// );
  /// ```
  Future<void> stopAlbumLoadTrace({int? trackCount}) async {
    try {
      if (_albumLoadTrace != null) {
        if (trackCount != null) {
          _albumLoadTrace!.setMetric('track_count', trackCount);
        }

        await _albumLoadTrace?.stop();
        _albumLoadTrace = null;

        if (kDebugMode) {
          print('Album load trace stopped');
        }
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Error stopping album load trace: $e');
      }
    }
  }

  /// Start tracking audio player initialization performance.
  ///
  /// Begins monitoring the process of initializing the audio player system,
  /// including codec initialization, audio session setup, and player state
  /// preparation. Critical for optimizing the music playback experience.
  ///
  /// Player initialization includes:
  /// - Audio system initialization and permissions
  /// - Codec and format support detection
  /// - Audio session configuration
  /// - Player state management setup
  /// - Integration with system audio controls
  ///
  /// This trace is particularly important for:
  /// - First-time app launches where audio systems need full initialization
  /// - Platform-specific audio system variations
  /// - Device-specific performance characteristics
  /// - Background/foreground player state transitions
  ///
  /// Example usage:
  /// ```dart
  /// Future<void> initializeAudioPlayer() async {
  ///   await PerformanceService().startPlayerInitTrace();
  ///
  ///   try {
  ///     await audioPlayer.initialize();
  ///     await setupAudioSession();
  ///     await PerformanceService().stopPlayerInitTrace(
  ///       playerMode: 'foreground',
  ///     );
  ///   } catch (e) {
  ///     await PerformanceService().stopPlayerInitTrace();
  ///     rethrow;
  ///   }
  /// }
  /// ```
  Future<void> startPlayerInitTrace() async {
    if (!_isTracingSupported) {
      if (kDebugMode) {
        print('Player init trace skipped (web platform)');
      }
      return;
    }

    try {
      _playerInitTrace = _performance.newTrace('player_init');
      await _playerInitTrace?.start();

      if (kDebugMode) {
        print('Player init trace started');
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Error starting player init trace: $e');
      }
    }
  }

  /// Stop player initialization trace with context about player mode.
  ///
  /// Completes the audio player initialization performance measurement
  /// and records contextual information about the initialization scenario.
  ///
  /// [playerMode] The mode or context in which the player was initialized.
  ///             Examples include 'foreground', 'background', 'radio',
  ///             'playlist', etc. This helps identify performance patterns
  ///             based on different usage scenarios.
  ///
  /// Player mode insights:
  /// - Background initialization may be faster due to reduced UI overhead
  /// - Radio mode might require different codec preparation
  /// - Playlist mode could involve additional metadata loading
  /// - Different modes may have varying audio session requirements
  ///
  /// Example usage:
  /// ```dart
  /// await audioPlayer.initializeForRadio();
  /// await PerformanceService().stopPlayerInitTrace(
  ///   playerMode: 'radio',
  /// );
  /// ```
  Future<void> stopPlayerInitTrace({String? playerMode}) async {
    try {
      if (_playerInitTrace != null) {
        if (playerMode != null) {
          _playerInitTrace!.putAttribute('player_mode', playerMode);
        }

        await _playerInitTrace?.stop();
        _playerInitTrace = null;

        if (kDebugMode) {
          print('Player init trace stopped');
        }
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Error stopping player init trace: $e');
      }
    }
  }

  /// Create a custom trace for monitoring any application operation.
  ///
  /// Provides a flexible way to create custom performance traces for
  /// specific operations that aren't covered by the predefined trace
  /// methods. The trace is automatically started and ready for use.
  ///
  /// [name] A descriptive name for the custom trace. Should be descriptive
  ///       and consistent across similar operations. Examples: 'search_query',
  ///       'image_upload', 'user_login', 'data_sync'.
  ///
  /// Returns a [Trace] object that can be used to:
  /// - Add custom metrics with `setMetric()`
  /// - Add custom attributes with `putAttribute()`
  /// - Stop the trace with `stop()`
  ///
  /// Best practices for custom traces:
  /// - Use consistent naming conventions
  /// - Add relevant attributes and metrics
  /// - Stop traces in finally blocks to ensure completion
  /// - Keep trace names under 100 characters
  /// - Use snake_case for trace names
  ///
  /// Example usage:
  /// ```dart
  /// Future<SearchResults> performSearch(String query) async {
  ///   final trace = await PerformanceService().createCustomTrace('search_query');
  ///   trace.putAttribute('query_length', query.length.toString());
  ///
  ///   try {
  ///     final results = await searchApi.search(query);
  ///     trace.setMetric('result_count', results.length);
  ///     return results;
  ///   } finally {
  ///     await trace.stop();
  ///   }
  /// }
  /// ```
  Future<Trace?> createCustomTrace(String name) async {
    if (!_isTracingSupported) {
      if (kDebugMode) {
        print('Custom trace "$name" skipped (web platform)');
      }
      return null;
    }

    final trace = _performance.newTrace(name);
    await trace.start();
    return trace;
  }

  /// Track a custom event with automatic trace management and metrics.
  ///
  /// Provides a convenient way to track one-off events or operations
  /// without manually managing trace lifecycle. The trace is automatically
  /// started, configured with provided attributes and metrics, and stopped.
  ///
  /// [eventName] A descriptive name for the event being tracked. Should
  ///           follow naming conventions and be consistent across similar
  ///           events. Examples: 'user_action', 'data_sync', 'feature_usage'.
  ///
  /// [attributes] Optional map of string key-value pairs providing contextual
  ///             information about the event. Examples: user type, feature
  ///             flags, screen context, error conditions.
  ///
  /// [metrics] Optional map of string keys to integer values for quantitative
  ///          measurements. Examples: item count, duration in milliseconds,
  ///          data size in bytes, retry attempts.
  ///
  /// This method is ideal for tracking discrete events that don't require
  /// complex timing measurements or ongoing monitoring. For operations that
  /// need precise timing control, use [createCustomTrace] instead.
  ///
  /// Example usage:
  /// ```dart
  /// // Track user interaction
  /// await PerformanceService().trackCustomEvent(
  ///   'album_shared',
  ///   attributes: {
  ///     'share_method': 'social_media',
  ///     'album_genre': 'rock',
  ///     'user_type': 'premium',
  ///   },
  ///   metrics: {
  ///     'album_track_count': 12,
  ///     'user_library_size': 150,
  ///   },
  /// );
  ///
  /// // Track feature usage
  /// await PerformanceService().trackCustomEvent('search_used');
  /// ```
  Future<void> trackCustomEvent(
    String eventName, {
    Map<String, String>? attributes,
    Map<String, int>? metrics,
  }) async {
    if (!_isTracingSupported) {
      if (kDebugMode) {
        print('Custom event "$eventName" skipped (web platform)');
      }
      return;
    }

    try {
      final trace = _performance.newTrace(eventName);
      await trace.start();

      // Add attributes
      if (attributes != null) {
        for (final entry in attributes.entries) {
          trace.putAttribute(entry.key, entry.value);
        }
      }

      // Add metrics
      if (metrics != null) {
        for (final entry in metrics.entries) {
          trace.setMetric(entry.key, entry.value);
        }
      }

      await trace.stop();

      if (kDebugMode) {
        print('Custom event tracked: $eventName');
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Error tracking custom event: $e');
      }
    }
  }

  /// Track application memory usage for performance monitoring.
  ///
  /// Creates a custom trace to monitor memory consumption patterns
  /// and identify potential memory leaks or optimization opportunities.
  /// This is particularly useful for detecting memory issues in
  /// long-running sessions or after intensive operations.
  ///
  /// The trace includes:
  /// - Timestamp of the memory check
  /// - Current memory usage metrics (when platform support is available)
  /// - Context about current app state and active operations
  ///
  /// Memory tracking considerations:
  /// - Platform-specific implementations may provide detailed metrics
  /// - Web platform has limited memory introspection capabilities
  /// - Mobile platforms may provide more detailed system memory info
  /// - Memory checks should be performed at strategic intervals
  ///
  /// Use cases:
  /// - After large data loading operations
  /// - During long music playback sessions
  /// - After image caching operations
  /// - When users report performance issues
  /// - As part of automated performance testing
  ///
  /// Example usage:
  /// ```dart
  /// // Check memory after large operation
  /// await loadLargeMusicLibrary();
  /// await PerformanceService().trackMemoryUsage();
  ///
  /// // Periodic memory monitoring
  /// Timer.periodic(Duration(minutes: 5), (_) {
  ///   PerformanceService().trackMemoryUsage();
  /// });
  /// ```
  Future<void> trackMemoryUsage() async {
    try {
      // This would require platform-specific implementation
      // For now, we'll create a placeholder trace
      await trackCustomEvent(
        'memory_check',
        attributes: {
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Error tracking memory usage: $e');
      }
    }
  }

  // ============================================================
  // Image Loading Performance Traces
  // ============================================================

  /// Start tracking image loading performance.
  ///
  /// Begins monitoring the process of loading an image from a URL,
  /// including network fetch time, decoding, and rendering preparation.
  /// Essential for optimizing album artwork and cover image loading.
  ///
  /// [imageUrl] The URL of the image being loaded. Recorded as an
  ///           attribute to identify specific images or patterns.
  ///
  /// The image load trace measures:
  /// - Network fetch time
  /// - Image decoding performance
  /// - Cache hit/miss patterns
  /// - Image size impact on loading times
  ///
  /// Example usage:
  /// ```dart
  /// Future<void> loadAlbumCover(String url) async {
  ///   await PerformanceService().startImageLoadTrace(url);
  ///   try {
  ///     await imageLoader.load(url);
  ///     await PerformanceService().stopImageLoadTrace(
  ///       imageUrl: url,
  ///       fromCache: false,
  ///       imageSize: 1024,
  ///     );
  ///   } catch (e) {
  ///     await PerformanceService().stopImageLoadTrace();
  ///     rethrow;
  ///   }
  /// }
  /// ```
  Future<void> startImageLoadTrace(String imageUrl) async {
    if (!_isTracingSupported) {
      if (kDebugMode) {
        print('Image load trace skipped (web platform)');
      }
      return;
    }

    try {
      _imageLoadTrace = _performance.newTrace('image_load');
      _imageLoadTrace?.putAttribute('image_url', _truncateUrl(imageUrl));
      await _imageLoadTrace?.start();

      if (kDebugMode) {
        print('Image load trace started for: ${_truncateUrl(imageUrl)}');
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Error starting image load trace: $e');
      }
    }
  }

  /// Stop image loading trace and record performance metrics.
  ///
  /// Completes the image loading performance measurement and enriches
  /// the trace with information about the loaded image.
  ///
  /// [imageUrl] The URL of the loaded image for verification.
  /// [fromCache] Whether the image was loaded from cache.
  /// [imageSize] The size of the loaded image in bytes (optional).
  /// [width] The width of the loaded image in pixels (optional).
  /// [height] The height of the loaded image in pixels (optional).
  Future<void> stopImageLoadTrace({
    String? imageUrl,
    bool? fromCache,
    int? imageSize,
    int? width,
    int? height,
  }) async {
    try {
      if (_imageLoadTrace != null) {
        if (fromCache != null) {
          _imageLoadTrace!.putAttribute('from_cache', fromCache.toString());
        }
        if (imageSize != null) {
          _imageLoadTrace!.setMetric('image_size_bytes', imageSize);
        }
        if (width != null) {
          _imageLoadTrace!.setMetric('image_width', width);
        }
        if (height != null) {
          _imageLoadTrace!.setMetric('image_height', height);
        }

        await _imageLoadTrace?.stop();
        _imageLoadTrace = null;

        if (kDebugMode) {
          print('Image load trace stopped');
        }
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Error stopping image load trace: $e');
      }
    }
  }

  /// Convenience method to trace a complete image load operation.
  ///
  /// Wraps an async image loading operation with performance tracing,
  /// automatically handling start/stop and error scenarios.
  ///
  /// [imageUrl] The URL of the image to load.
  /// [loadOperation] The async function that performs the actual loading.
  ///
  /// Returns the result of the load operation.
  ///
  /// Example usage:
  /// ```dart
  /// final image = await PerformanceService().traceImageLoad(
  ///   imageUrl,
  ///   () => imageProvider.load(imageUrl),
  /// );
  /// ```
  Future<T> traceImageLoad<T>(
    String imageUrl,
    Future<T> Function() loadOperation,
  ) async {
    await startImageLoadTrace(imageUrl);
    try {
      final result = await loadOperation();
      await stopImageLoadTrace(imageUrl: imageUrl);
      return result;
    } catch (e) {
      await stopImageLoadTrace(imageUrl: imageUrl);
      rethrow;
    }
  }

  // ============================================================
  // Audio Buffering Performance Traces
  // ============================================================

  /// Start tracking audio buffering performance.
  ///
  /// Begins monitoring the audio buffering process for a specific track,
  /// measuring time from buffer start to playback-ready state.
  ///
  /// [trackId] The unique identifier of the track being buffered.
  /// [trackName] Optional human-readable track name for logging.
  ///
  /// The audio buffer trace measures:
  /// - Initial buffering time
  /// - Network conditions during buffering
  /// - Track metadata impact on buffering
  /// - Audio codec/format effects
  ///
  /// Example usage:
  /// ```dart
  /// Future<void> bufferTrack(Song song) async {
  ///   await PerformanceService().startAudioBufferTrace(
  ///     song.id,
  ///     trackName: song.songName,
  ///   );
  ///   try {
  ///     await audioPlayer.setUrl(song.url);
  ///     await PerformanceService().stopAudioBufferTrace(
  ///       bufferDurationMs: bufferTime,
  ///       trackDurationMs: song.duration,
  ///     );
  ///   } catch (e) {
  ///     await PerformanceService().stopAudioBufferTrace();
  ///     rethrow;
  ///   }
  /// }
  /// ```
  Future<void> startAudioBufferTrace(
    String trackId, {
    String? trackName,
  }) async {
    if (!_isTracingSupported) {
      if (kDebugMode) {
        print('Audio buffer trace skipped (web platform)');
      }
      return;
    }

    try {
      _audioBufferTrace = _performance.newTrace('audio_buffer');
      _audioBufferTrace?.putAttribute('track_id', trackId);
      if (trackName != null) {
        _audioBufferTrace?.putAttribute(
          'track_name',
          _truncateString(trackName, 100),
        );
      }
      await _audioBufferTrace?.start();

      if (kDebugMode) {
        print('Audio buffer trace started for: $trackId');
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Error starting audio buffer trace: $e');
      }
    }
  }

  /// Stop audio buffering trace and record performance metrics.
  ///
  /// Completes the audio buffering performance measurement with
  /// detailed metrics about the buffering operation.
  ///
  /// [bufferDurationMs] Time taken to buffer in milliseconds.
  /// [trackDurationMs] Total track duration in milliseconds.
  /// [bufferSizeBytes] Size of buffered audio data in bytes.
  /// [audioFormat] The audio format/codec used (e.g., 'mp3', 'aac').
  Future<void> stopAudioBufferTrace({
    int? bufferDurationMs,
    int? trackDurationMs,
    int? bufferSizeBytes,
    String? audioFormat,
  }) async {
    try {
      if (_audioBufferTrace != null) {
        if (bufferDurationMs != null) {
          _audioBufferTrace!.setMetric('buffer_duration_ms', bufferDurationMs);
        }
        if (trackDurationMs != null) {
          _audioBufferTrace!.setMetric('track_duration_ms', trackDurationMs);
        }
        if (bufferSizeBytes != null) {
          _audioBufferTrace!.setMetric('buffer_size_bytes', bufferSizeBytes);
        }
        if (audioFormat != null) {
          _audioBufferTrace!.putAttribute('audio_format', audioFormat);
        }

        await _audioBufferTrace?.stop();
        _audioBufferTrace = null;

        if (kDebugMode) {
          print('Audio buffer trace stopped');
        }
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Error stopping audio buffer trace: $e');
      }
    }
  }

  // ============================================================
  // Search Operation Performance Traces
  // ============================================================

  /// Start tracking search operation performance.
  ///
  /// Begins monitoring a search operation, measuring the time from
  /// query submission to results display.
  ///
  /// [query] The search query string being executed.
  /// [searchType] The type of search (e.g., 'albums', 'tracks', 'all').
  ///
  /// Example usage:
  /// ```dart
  /// Future<List<Album>> searchAlbums(String query) async {
  ///   await PerformanceService().startSearchTrace(query, searchType: 'albums');
  ///   try {
  ///     final results = await repository.search(query);
  ///     await PerformanceService().stopSearchTrace(
  ///       resultCount: results.length,
  ///     );
  ///     return results;
  ///   } catch (e) {
  ///     await PerformanceService().stopSearchTrace();
  ///     rethrow;
  ///   }
  /// }
  /// ```
  Future<void> startSearchTrace(String query, {String? searchType}) async {
    if (!_isTracingSupported) {
      if (kDebugMode) {
        print('Search trace skipped (web platform)');
      }
      return;
    }

    try {
      _searchTrace = _performance.newTrace('search_operation');
      _searchTrace?.putAttribute('query_length', query.length.toString());
      if (searchType != null) {
        _searchTrace?.putAttribute('search_type', searchType);
      }
      await _searchTrace?.start();

      if (kDebugMode) {
        print('Search trace started for query length: ${query.length}');
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Error starting search trace: $e');
      }
    }
  }

  /// Stop search operation trace and record performance metrics.
  ///
  /// Completes the search performance measurement with result metrics.
  ///
  /// [resultCount] Number of results returned by the search.
  /// [fromCache] Whether results came from local cache.
  Future<void> stopSearchTrace({
    int? resultCount,
    bool? fromCache,
  }) async {
    try {
      if (_searchTrace != null) {
        if (resultCount != null) {
          _searchTrace!.setMetric('result_count', resultCount);
        }
        if (fromCache != null) {
          _searchTrace!.putAttribute('from_cache', fromCache.toString());
        }

        await _searchTrace?.stop();
        _searchTrace = null;

        if (kDebugMode) {
          print('Search trace stopped with $resultCount results');
        }
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Error stopping search trace: $e');
      }
    }
  }

  // ============================================================
  // Navigation Transition Performance Traces
  // ============================================================

  /// Start tracking navigation transition performance.
  ///
  /// Begins monitoring a navigation transition, measuring the time
  /// from navigation initiation to destination screen ready state.
  ///
  /// [fromRoute] The source route/screen name.
  /// [toRoute] The destination route/screen name.
  /// [transitionType] The type of transition (e.g., 'push', 'replace', 'pop').
  ///
  /// Example usage:
  /// ```dart
  /// Future<void> navigateToAlbum(Album album) async {
  ///   await PerformanceService().startNavigationTrace(
  ///     fromRoute: 'albums_list',
  ///     toRoute: 'album_detail',
  ///     transitionType: 'push',
  ///   );
  ///   await Get.to(() => AlbumDetailView(album: album));
  ///   await PerformanceService().stopNavigationTrace();
  /// }
  /// ```
  Future<void> startNavigationTrace({
    required String fromRoute,
    required String toRoute,
    String? transitionType,
  }) async {
    if (!_isTracingSupported) {
      if (kDebugMode) {
        print('Navigation trace skipped (web platform)');
      }
      return;
    }

    try {
      _navigationTrace = _performance.newTrace('navigation_transition');
      _navigationTrace?.putAttribute('from_route', fromRoute);
      _navigationTrace?.putAttribute('to_route', toRoute);
      if (transitionType != null) {
        _navigationTrace?.putAttribute('transition_type', transitionType);
      }
      await _navigationTrace?.start();

      if (kDebugMode) {
        print('Navigation trace started: $fromRoute -> $toRoute');
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Error starting navigation trace: $e');
      }
    }
  }

  /// Stop navigation transition trace and record completion status.
  ///
  /// Completes the navigation performance measurement.
  ///
  /// [success] Whether the navigation completed successfully.
  /// [dataLoadTimeMs] Time taken to load destination screen data.
  Future<void> stopNavigationTrace({
    bool? success,
    int? dataLoadTimeMs,
  }) async {
    try {
      if (_navigationTrace != null) {
        if (success != null) {
          _navigationTrace!.putAttribute('success', success.toString());
        }
        if (dataLoadTimeMs != null) {
          _navigationTrace!.setMetric('data_load_time_ms', dataLoadTimeMs);
        }

        await _navigationTrace?.stop();
        _navigationTrace = null;

        if (kDebugMode) {
          print('Navigation trace stopped');
        }
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Error stopping navigation trace: $e');
      }
    }
  }

  // ============================================================
  // Album List Loading Performance
  // ============================================================

  /// Trace album list loading operation with automatic lifecycle management.
  ///
  /// Convenience method that wraps album loading with performance tracing,
  /// automatically handling start/stop and error scenarios.
  ///
  /// [loadOperation] The async function that loads the albums.
  /// [source] The data source (e.g., 'firebase', 'cache', 'local').
  ///
  /// Returns the loaded albums.
  ///
  /// Example usage:
  /// ```dart
  /// final albums = await PerformanceService().traceAlbumListLoad(
  ///   () => repository.getAlbums(),
  ///   source: 'firebase',
  /// );
  /// ```
  Future<List<T>> traceAlbumListLoad<T>(
    Future<List<T>> Function() loadOperation, {
    String? source,
  }) async {
    await startMusicLoadTrace();
    try {
      final result = await loadOperation();
      await stopMusicLoadTrace(
        albumCount: result.length,
        fromCache: source == 'cache',
      );
      return result;
    } catch (e) {
      await stopMusicLoadTrace();
      rethrow;
    }
  }

  // ============================================================
  // Helper Methods
  // ============================================================

  /// Truncate a URL to a reasonable length for attribute storage.
  String _truncateUrl(String url) {
    const maxLength = 100;
    if (url.length <= maxLength) {
      return url;
    }
    return '${url.substring(0, maxLength)}...';
  }

  /// Truncate a string to a specified maximum length.
  String _truncateString(String str, int maxLength) {
    if (str.length <= maxLength) {
      return str;
    }
    return '${str.substring(0, maxLength)}...';
  }

  /// Create an HTTP metric for tracking network request performance.
  ///
  /// Provides Firebase Performance Monitoring for HTTP requests, enabling
  /// detailed analysis of network operation performance including request
  /// duration, response size, and success rates across different endpoints.
  ///
  /// [url] The complete URL being requested. Should include the full endpoint
  ///      path to enable detailed analysis of different API endpoints.
  ///
  /// [method] The HTTP method being used (GET, POST, PUT, DELETE, etc.).
  ///         This helps categorize and analyze different types of requests.
  ///
  /// Returns an [HttpMetric] object that should be used to track the request:
  /// 1. Call `start()` before sending the request
  /// 2. Set response attributes like status code and content type
  /// 3. Call `stop()` after receiving the response
  ///
  /// The HTTP metric automatically captures:
  /// - Request duration from start to completion
  /// - Response HTTP status code
  /// - Response payload size
  /// - Network error conditions
  /// - Request success/failure rates
  ///
  /// Example usage:
  /// ```dart
  /// Future<Response> makeApiRequest(String url, String method) async {
  ///   final httpMetric = PerformanceService().createHttpMetric(url, HttpMethod.get);
  ///   await httpMetric.start();
  ///
  ///   try {
  ///     final response = await http.get(Uri.parse(url));
  ///
  ///     httpMetric.responseCode = response.statusCode;
  ///     httpMetric.responsePayloadSize = response.body.length;
  ///
  ///     return response;
  ///   } finally {
  ///     await httpMetric.stop();
  ///   }
  /// }
  /// ```
  HttpMetric createHttpMetric(String url, HttpMethod method) =>
      _performance.newHttpMetric(url, method);

  /// Check if Firebase Performance data collection is currently enabled.
  ///
  /// Queries the current state of performance monitoring to determine
  /// whether performance data is being collected and sent to Firebase.
  /// Useful for debugging configuration issues and providing user
  /// transparency about data collection.
  ///
  /// Returns `true` if performance collection is active, `false` if disabled.
  /// In case of errors (such as Firebase not being properly configured),
  /// returns `false` and logs the error in debug mode.
  ///
  /// Performance collection can be disabled by:
  /// - User privacy settings
  /// - Firebase configuration issues
  /// - Network connectivity problems
  /// - Platform-specific restrictions
  /// - Development mode settings
  ///
  /// Use cases:
  /// - Debugging performance monitoring setup
  /// - Providing user transparency about data collection
  /// - Conditional performance tracking based on user preferences
  /// - Troubleshooting Firebase integration issues
  ///
  /// Example usage:
  /// ```dart
  /// if (await PerformanceService().isPerformanceCollectionEnabled()) {
  ///   print('Performance monitoring is active');
  ///   await startDetailedTracking();
  /// } else {
  ///   print('Performance monitoring is disabled');
  ///   await fallbackToLocalMetrics();
  /// }
  /// ```
  Future<bool> isPerformanceCollectionEnabled() async {
    try {
      return await _performance.isPerformanceCollectionEnabled();
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Error checking performance collection status: $e');
      }
      return false;
    }
  }
}
