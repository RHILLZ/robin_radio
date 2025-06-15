import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';

class PerformanceService {
  static final PerformanceService _instance = PerformanceService._internal();
  factory PerformanceService() => _instance;
  PerformanceService._internal();

  final FirebasePerformance _performance = FirebasePerformance.instance;

  // Custom traces for key user flows
  Trace? _appStartTrace;
  Trace? _musicLoadTrace;
  Trace? _albumLoadTrace;
  Trace? _playerInitTrace;

  /// Initialize performance monitoring
  Future<void> initialize() async {
    try {
      // Enable performance collection (no-op for web)
      await _performance.setPerformanceCollectionEnabled(true);

      if (kDebugMode) {
        print('Performance monitoring initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing performance monitoring: $e');
      }
    }
  }

  /// Start app startup trace
  Future<void> startAppStartTrace() async {
    try {
      _appStartTrace = _performance.newTrace('app_start');
      await _appStartTrace?.start();

      if (kDebugMode) {
        print('App start trace started');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error starting app start trace: $e');
      }
    }
  }

  /// Stop app startup trace
  Future<void> stopAppStartTrace() async {
    try {
      await _appStartTrace?.stop();
      _appStartTrace = null;

      if (kDebugMode) {
        print('App start trace stopped');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error stopping app start trace: $e');
      }
    }
  }

  /// Start music loading trace
  Future<void> startMusicLoadTrace() async {
    try {
      _musicLoadTrace = _performance.newTrace('music_load');
      await _musicLoadTrace?.start();

      if (kDebugMode) {
        print('Music load trace started');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error starting music load trace: $e');
      }
    }
  }

  /// Stop music loading trace with metrics
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
    } catch (e) {
      if (kDebugMode) {
        print('Error stopping music load trace: $e');
      }
    }
  }

  /// Start album loading trace
  Future<void> startAlbumLoadTrace(String albumId) async {
    try {
      _albumLoadTrace = _performance.newTrace('album_load');
      _albumLoadTrace?.putAttribute('album_id', albumId);
      await _albumLoadTrace?.start();

      if (kDebugMode) {
        print('Album load trace started for: $albumId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error starting album load trace: $e');
      }
    }
  }

  /// Stop album loading trace
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
    } catch (e) {
      if (kDebugMode) {
        print('Error stopping album load trace: $e');
      }
    }
  }

  /// Start player initialization trace
  Future<void> startPlayerInitTrace() async {
    try {
      _playerInitTrace = _performance.newTrace('player_init');
      await _playerInitTrace?.start();

      if (kDebugMode) {
        print('Player init trace started');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error starting player init trace: $e');
      }
    }
  }

  /// Stop player initialization trace
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
    } catch (e) {
      if (kDebugMode) {
        print('Error stopping player init trace: $e');
      }
    }
  }

  /// Create a custom trace for any operation
  Future<Trace> createCustomTrace(String name) async {
    final trace = _performance.newTrace(name);
    await trace.start();
    return trace;
  }

  /// Track a custom event with metrics
  Future<void> trackCustomEvent(
    String eventName, {
    Map<String, String>? attributes,
    Map<String, int>? metrics,
  }) async {
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
    } catch (e) {
      if (kDebugMode) {
        print('Error tracking custom event: $e');
      }
    }
  }

  /// Track memory usage (custom metric)
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
    } catch (e) {
      if (kDebugMode) {
        print('Error tracking memory usage: $e');
      }
    }
  }

  /// Track network request performance
  HttpMetric createHttpMetric(String url, HttpMethod method) {
    return _performance.newHttpMetric(url, method);
  }

  /// Get performance collection status
  Future<bool> isPerformanceCollectionEnabled() async {
    try {
      return await _performance.isPerformanceCollectionEnabled();
    } catch (e) {
      if (kDebugMode) {
        print('Error checking performance collection status: $e');
      }
      return false;
    }
  }
}
