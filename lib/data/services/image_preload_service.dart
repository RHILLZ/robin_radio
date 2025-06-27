import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../exceptions/network_service_exception.dart';

/// Configuration for image preloading behavior
class ImagePreloadConfig {
  /// Creates a new image preload configuration.
  const ImagePreloadConfig({
    this.preloadOnWifi = true,
    this.preloadOnMobile = false,
    this.maxConcurrentPreloads = 3,
    this.preloadTimeout = const Duration(seconds: 30),
    this.enableAnalytics = true,
    this.compressionQuality = 85,
    this.maxPreloadSize = 1024 * 1024, // 1MB
  });

  /// Whether to preload images on WiFi connection
  final bool preloadOnWifi;

  /// Whether to preload images on mobile data connection
  final bool preloadOnMobile;

  /// Maximum number of concurrent preload operations
  final int maxConcurrentPreloads;

  /// Timeout for each preload operation
  final Duration preloadTimeout;

  /// Whether to collect analytics on preload performance
  final bool enableAnalytics;

  /// Default compression quality for uploads (0-100)
  final int compressionQuality;

  /// Maximum file size for preloading (bytes)
  final int maxPreloadSize;

  /// Conservative settings for mobile data
  static const ImagePreloadConfig conservative = ImagePreloadConfig(
    maxConcurrentPreloads: 2,
    compressionQuality: 70,
    maxPreloadSize: 512 * 1024, // 512KB
  );

  /// Aggressive settings for WiFi
  static const ImagePreloadConfig aggressive = ImagePreloadConfig(
    preloadOnMobile: true,
    maxConcurrentPreloads: 5,
    compressionQuality: 90,
    maxPreloadSize: 2 * 1024 * 1024, // 2MB
  );

  /// Minimal settings for low-resource devices
  static const ImagePreloadConfig minimal = ImagePreloadConfig(
    preloadOnWifi: false,
    maxConcurrentPreloads: 1,
    compressionQuality: 60,
    maxPreloadSize: 256 * 1024, // 256KB
  );
}

/// Analytics data for preload operations
class PreloadAnalytics {
  /// Creates a new preload analytics instance.
  PreloadAnalytics({
    required this.url,
    required this.startTime,
    this.endTime,
    this.success = false,
    this.fileSize,
    this.error,
    this.connectionType,
  });

  /// The URL of the image being preloaded.
  final String url;
  /// Timestamp when preloading started.
  final DateTime startTime;
  /// Timestamp when preloading completed (null if still in progress).
  DateTime? endTime;
  /// Whether the preload operation was successful.
  bool success;
  /// Size of the downloaded file in bytes.
  int? fileSize;
  /// Error message if the operation failed.
  String? error;
  /// Type of network connection used (wifi, mobile, etc.).
  String? connectionType;

  /// Duration of the preload operation, null if not yet completed.
  Duration? get duration => endTime?.difference(startTime);

  /// Converts analytics data to JSON format for logging and storage.
  Map<String, dynamic> toJson() => {
        'url': url,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'success': success,
        'duration': duration?.inMilliseconds,
        'fileSize': fileSize,
        'error': error,
        'connectionType': connectionType,
      };
}

/// Compression settings for different use cases
enum CompressionPreset {
  thumbnail,
  preview,
  standard,
  highQuality,
  lossless,
}

/// Configuration for image compression
class CompressionConfig {
  const CompressionConfig({
    required this.quality,
    this.maxWidth,
    this.maxHeight,
    this.format = CompressFormat.webp,
    this.keepExif = false,
  });

  final int quality;
  final int? maxWidth;
  final int? maxHeight;
  final CompressFormat format;
  final bool keepExif;

  /// Thumbnail compression (small, low quality)
  static const CompressionConfig thumbnail = CompressionConfig(
    quality: 60,
    maxWidth: 150,
    maxHeight: 150,
  );

  /// Preview compression (medium size, good quality)
  static const CompressionConfig preview = CompressionConfig(
    quality: 75,
    maxWidth: 500,
    maxHeight: 500,
  );

  /// Standard compression (balanced)
  static const CompressionConfig standard = CompressionConfig(
    quality: 85,
    maxWidth: 1024,
    maxHeight: 1024,
  );

  /// High quality compression
  static const CompressionConfig highQuality = CompressionConfig(
    quality: 95,
    maxWidth: 2048,
    maxHeight: 2048,
  );

  /// Get compression config by preset
  static CompressionConfig fromPreset(CompressionPreset preset) {
    switch (preset) {
      case CompressionPreset.thumbnail:
        return thumbnail;
      case CompressionPreset.preview:
        return preview;
      case CompressionPreset.standard:
        return standard;
      case CompressionPreset.highQuality:
        return highQuality;
      case CompressionPreset.lossless:
        return const CompressionConfig(quality: 100);
    }
  }
}

/// Service for preloading frequently used images and compressing uploads
class ImagePreloadService {
  ImagePreloadService._privateConstructor();
  static final ImagePreloadService _instance =
      ImagePreloadService._privateConstructor();
  static ImagePreloadService get instance => _instance;

  ImagePreloadConfig _config = const ImagePreloadConfig();
  final Map<String, PreloadAnalytics> _analytics = {};
  final Set<String> _preloadedUrls = {};
  final Set<String> _currentlyPreloading = {};

  /// Initialize the preload service with configuration
  void initialize({ImagePreloadConfig? config}) {
    _config = config ?? const ImagePreloadConfig();
  }

  /// Get current configuration
  ImagePreloadConfig get config => _config;

  /// Preload essential app assets on startup
  Future<void> preloadEssentialAssets(BuildContext context) async {
    if (!await _shouldPreload()) return;

    const essentialAssets = [
      'assets/logo/rr-logo.webp',
      'assets/logo/rr-earphones.webp',
    ];

    await Future.wait(
      essentialAssets.map((asset) => _preloadAssetImage(context, asset)),
    );
  }

  /// Preload a list of network images
  Future<void> preloadNetworkImages(
    BuildContext context,
    List<String> urls, {
    ImagePreloadConfig? customConfig,
  }) async {
    final activeConfig = customConfig ?? _config;

    if (!await _shouldPreload()) return;

    // Filter out already preloaded or currently preloading URLs
    final urlsToPreload = urls
        .where(
          (url) =>
              !_preloadedUrls.contains(url) &&
              !_currentlyPreloading.contains(url),
        )
        .take(activeConfig.maxConcurrentPreloads)
        .toList();

    if (urlsToPreload.isEmpty) return;

    debugPrint('🖼️ Preloading ${urlsToPreload.length} network images');

    await Future.wait(
      urlsToPreload
          .map((url) => _preloadNetworkImage(context, url, activeConfig)),
    );
  }

  /// Preload images commonly used in album/track listings
  Future<void> preloadAlbumCovers(
    BuildContext context,
    List<String> coverUrls, {
    int? limit,
  }) async {
    if (!await _shouldPreload()) return;

    final urlsToPreload =
        coverUrls.take(limit ?? _config.maxConcurrentPreloads).toList();

    debugPrint('🎵 Preloading ${urlsToPreload.length} album covers');

    await preloadNetworkImages(context, urlsToPreload);
  }

  /// Compress an image file for upload
  Future<Uint8List?> compressImageForUpload(
    String filePath, {
    CompressionPreset preset = CompressionPreset.standard,
    CompressionConfig? customConfig,
  }) async {
    try {
      final config = customConfig ?? CompressionConfig.fromPreset(preset);

      debugPrint('🗜️ Compressing image: $filePath (Q:${config.quality})');

      final file = File(filePath);
      if (!await file.exists()) {
        throw NetworkServiceInitializationException(
          'File not found: $filePath',
          'IMAGE_FILE_NOT_FOUND',
        );
      }

      final originalSize = await file.length();
      debugPrint('📏 Original size: ${_formatFileSize(originalSize)}');

      final compressedData = await FlutterImageCompress.compressWithFile(
        filePath,
        quality: config.quality,
        minWidth: config.maxWidth ?? 1024,
        minHeight: config.maxHeight ?? 1024,
        format: config.format,
        keepExif: config.keepExif,
      );

      if (compressedData != null) {
        final compressedSize = compressedData.length;
        final reduction =
            ((originalSize - compressedSize) / originalSize * 100).round();
        debugPrint(
          '✅ Compressed size: ${_formatFileSize(compressedSize)} ($reduction% reduction)',
        );

        if (_config.enableAnalytics) {
          _recordCompressionAnalytics(
            filePath,
            originalSize,
            compressedSize,
            preset,
          );
        }
      }

      return compressedData;
    } on Exception catch (e) {
      debugPrint('❌ Compression failed: $e');
      throw NetworkServiceInitializationException(
        'Image compression failed: $e',
        'IMAGE_COMPRESSION_FAILED',
      );
    }
  }

  /// Compress image data from memory
  Future<Uint8List?> compressImageData(
    Uint8List imageData, {
    CompressionPreset preset = CompressionPreset.standard,
    CompressionConfig? customConfig,
  }) async {
    try {
      final config = customConfig ?? CompressionConfig.fromPreset(preset);

      debugPrint(
        '🗜️ Compressing image data (${_formatFileSize(imageData.length)})',
      );

      final compressedData = await FlutterImageCompress.compressWithList(
        imageData,
        quality: config.quality,
        minWidth: config.maxWidth ?? 1024,
        minHeight: config.maxHeight ?? 1024,
        format: config.format,
        keepExif: config.keepExif,
      );

      if (compressedData.isNotEmpty) {
        final reduction = ((imageData.length - compressedData.length) /
                imageData.length *
                100)
            .round();
        debugPrint(
          '✅ Compressed to: ${_formatFileSize(compressedData.length)} ($reduction% reduction)',
        );
      }

      return compressedData;
    } on Exception catch (e) {
      debugPrint('❌ Data compression failed: $e');
      throw NetworkServiceInitializationException(
        'Image data compression failed: $e',
        'IMAGE_DATA_COMPRESSION_FAILED',
      );
    }
  }

  /// Get preload analytics
  List<PreloadAnalytics> getAnalytics() => _analytics.values.toList();

  /// Clear analytics data
  void clearAnalytics() {
    _analytics.clear();
  }

  /// Get preload statistics
  Map<String, dynamic> getPreloadStats() {
    final analytics = _analytics.values.toList();
    final successful = analytics.where((a) => a.success).length;
    final failed = analytics.length - successful;
    // Calculate average duration safely
    final durationsWithTime =
        analytics.where((a) => a.duration != null).toList();
    final avgDuration = durationsWithTime.isEmpty
        ? 0.0
        : durationsWithTime
                .map((a) => a.duration!.inMilliseconds)
                .fold<double>(0, (sum, duration) => sum + duration) /
            durationsWithTime.length;

    return {
      'totalPreloads': analytics.length,
      'successful': successful,
      'failed': failed,
      'successRate':
          analytics.isEmpty ? 0 : (successful / analytics.length * 100).round(),
      'averageDuration': avgDuration.round(),
      'preloadedUrls': _preloadedUrls.length,
      'currentlyPreloading': _currentlyPreloading.length,
    };
  }

  /// Check if we should preload based on connection and config
  Future<bool> _shouldPreload() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();

      switch (connectivityResult) {
        case ConnectivityResult.wifi:
          return _config.preloadOnWifi;
        case ConnectivityResult.mobile:
          return _config.preloadOnMobile;
        case ConnectivityResult.ethernet:
          return _config.preloadOnWifi; // Treat ethernet like WiFi
        case ConnectivityResult.none:
          return false;
        default:
          return false;
      }
    } on Exception catch (e) {
      debugPrint('⚠️ Connection check failed: $e');
      return false;
    }
  }

  /// Preload an asset image
  Future<void> _preloadAssetImage(
    BuildContext context,
    String assetPath,
  ) async {
    try {
      debugPrint('📱 Preloading asset: $assetPath');

      final analytics = PreloadAnalytics(
        url: assetPath,
        startTime: DateTime.now(),
        connectionType: 'asset',
      );

      await precacheImage(AssetImage(assetPath), context);

      analytics.endTime = DateTime.now();
      analytics.success = true;

      _preloadedUrls.add(assetPath);

      if (_config.enableAnalytics) {
        _analytics[assetPath] = analytics;
      }

      debugPrint('✅ Asset preloaded: $assetPath');
    } on Exception catch (e) {
      debugPrint('❌ Asset preload failed: $assetPath - $e');

      if (_config.enableAnalytics) {
        _analytics[assetPath] = PreloadAnalytics(
          url: assetPath,
          startTime: DateTime.now(),
          endTime: DateTime.now(),
          error: e.toString(),
          connectionType: 'asset',
        );
      }
    }
  }

  /// Preload a network image
  Future<void> _preloadNetworkImage(
    BuildContext context,
    String url,
    ImagePreloadConfig config,
  ) async {
    if (_currentlyPreloading.contains(url)) return;

    _currentlyPreloading.add(url);

    try {
      debugPrint('🌐 Preloading network image: $url');

      final analytics = PreloadAnalytics(
        url: url,
        startTime: DateTime.now(),
        connectionType: await _getConnectionType(),
      );

      final imageProvider = CachedNetworkImageProvider(url);

      await precacheImage(imageProvider, context)
          .timeout(config.preloadTimeout);

      analytics.endTime = DateTime.now();
      analytics.success = true;

      _preloadedUrls.add(url);

      if (config.enableAnalytics) {
        _analytics[url] = analytics;
      }

      debugPrint('✅ Network image preloaded: $url');
    } on Exception catch (e) {
      debugPrint('❌ Network preload failed: $url - $e');

      if (config.enableAnalytics) {
        _analytics[url] = PreloadAnalytics(
          url: url,
          startTime: DateTime.now(),
          endTime: DateTime.now(),
          error: e.toString(),
          connectionType: await _getConnectionType(),
        );
      }
    } finally {
      _currentlyPreloading.remove(url);
    }
  }

  /// Get current connection type as string
  Future<String> _getConnectionType() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      switch (connectivityResult) {
        case ConnectivityResult.wifi:
          return 'wifi';
        case ConnectivityResult.mobile:
          return 'mobile';
        case ConnectivityResult.ethernet:
          return 'ethernet';
        case ConnectivityResult.none:
          return 'none';
        default:
          return 'unknown';
      }
    } on Exception {
      return 'unknown';
    }
  }

  /// Record compression analytics
  void _recordCompressionAnalytics(
    String filePath,
    int originalSize,
    int compressedSize,
    CompressionPreset preset,
  ) {
    // Could be extended to send to analytics service
    debugPrint('📊 Compression analytics: $filePath - ${preset.name} - '
        'Original: ${_formatFileSize(originalSize)} -> '
        'Compressed: ${_formatFileSize(compressedSize)}');
  }

  /// Format file size for display
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  /// Clear all preload caches
  void clearPreloadCache() {
    _preloadedUrls.clear();
    _currentlyPreloading.clear();
    _analytics.clear();
    debugPrint('🧹 Preload cache cleared');
  }

  /// Check if URL is preloaded
  bool isPreloaded(String url) => _preloadedUrls.contains(url);

  /// Check if URL is currently being preloaded
  bool isPreloading(String url) => _currentlyPreloading.contains(url);
}

/// Extension methods for easy preloading
extension ImagePreloadExtensions on BuildContext {
  /// Preload images for this context
  Future<void> preloadImages(List<String> urls) async {
    await ImagePreloadService.instance.preloadNetworkImages(this, urls);
  }

  /// Preload album covers for this context
  Future<void> preloadAlbumCovers(List<String> coverUrls, {int? limit}) async {
    await ImagePreloadService.instance
        .preloadAlbumCovers(this, coverUrls, limit: limit);
  }
}
