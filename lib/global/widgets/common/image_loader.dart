import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Image cache configuration for the application.
///
/// Provides centralized management of Flutter's in-memory image cache
/// with sensible defaults optimized for music streaming apps where
/// album artwork is frequently displayed.
///
/// ## Cache Sizing Strategy
///
/// - **Maximum images**: 100 entries (covers typical album browse sessions)
/// - **Maximum size**: 100 MB (balances memory usage with cache effectiveness)
///
/// These limits prevent excessive memory usage while maintaining
/// good cache hit rates for recently viewed album covers.
class ImageCacheConfig {
  ImageCacheConfig._();

  /// Maximum number of images to keep in memory cache
  static const int maxCacheEntries = 100;

  /// Maximum total size of cached images in bytes (100 MB)
  static const int maxCacheSizeBytes = 100 * 1024 * 1024;

  /// Whether the cache has been configured
  static bool _isConfigured = false;

  /// Configure the global image cache with optimized settings.
  ///
  /// Should be called early in app initialization, typically in main()
  /// or during the first widget build.
  ///
  /// This method is idempotent - calling it multiple times has no effect
  /// after the first configuration.
  static void configure() {
    if (_isConfigured) {
      return;
    }

    final imageCache = PaintingBinding.instance.imageCache
      ..maximumSize = maxCacheEntries
      ..maximumSizeBytes = maxCacheSizeBytes;

    // Ensure cache is configured
    assert(imageCache.maximumSize == maxCacheEntries);
    _isConfigured = true;
  }

  /// Clear the image cache to free memory.
  ///
  /// Useful when the app enters background or when memory pressure is detected.
  static void clear() {
    PaintingBinding.instance.imageCache.clear();
  }

  /// Evict a specific image from the cache by its key.
  static void evict(String key) {
    PaintingBinding.instance.imageCache.evict(key);
  }

  /// Get current cache statistics for debugging.
  static ImageCacheStats getStats() {
    final cache = PaintingBinding.instance.imageCache;
    return ImageCacheStats(
      currentSize: cache.currentSize,
      currentSizeBytes: cache.currentSizeBytes,
      maximumSize: cache.maximumSize,
      maximumSizeBytes: cache.maximumSizeBytes,
      liveImageCount: cache.liveImageCount,
      pendingImageCount: cache.pendingImageCount,
    );
  }
}

/// Statistics about the current image cache state.
class ImageCacheStats {
  /// Creates image cache statistics
  const ImageCacheStats({
    required this.currentSize,
    required this.currentSizeBytes,
    required this.maximumSize,
    required this.maximumSizeBytes,
    required this.liveImageCount,
    required this.pendingImageCount,
  });

  /// Current number of cached images
  final int currentSize;

  /// Current total size of cached images in bytes
  final int currentSizeBytes;

  /// Maximum number of images allowed in cache
  final int maximumSize;

  /// Maximum total size of cached images in bytes
  final int maximumSizeBytes;

  /// Number of images currently being used by widgets
  final int liveImageCount;

  /// Number of images currently being loaded
  final int pendingImageCount;

  /// Cache utilization as a percentage (0.0 to 1.0)
  double get utilizationPercent => currentSize / maximumSize;

  /// Memory utilization as a percentage (0.0 to 1.0)
  double get memoryUtilizationPercent =>
      currentSizeBytes / maximumSizeBytes;

  @override
  String toString() =>
      'ImageCacheStats(entries: $currentSize/$maximumSize, '
      'memory: ${(currentSizeBytes / 1024 / 1024).toStringAsFixed(1)}MB/'
      '${(maximumSizeBytes / 1024 / 1024).toStringAsFixed(1)}MB)';
}

/// Progressive loading mode options
enum ProgressiveLoadingMode {
  /// No progressive loading
  none,

  /// Blur up effect from low to high quality
  blurUp,

  /// Two phase loading with thumbnail first
  twoPhase,

  /// Simple fade transition
  fade,
}

/// Size constraint constants for different UI contexts
class ImageSizeConstraints {
  /// Private constructor to prevent instantiation
  ImageSizeConstraints._();

  /// Thumbnail size constraint
  static const int thumbnailSize = 150;

  /// List item size constraint
  static const int listItemSize = 300;

  /// Detail view size constraint
  static const int detailViewSize = 800;

  /// Full screen size constraint
  static const int fullScreenSize = 1200;

  /// Calculate appropriate cache size based on display size
  static int calculateCacheSize(double? displaySize) {
    if (displaySize == null) {
      return listItemSize;
    }

    final pixelSize = (displaySize * 3).round(); // 3x for high DPI displays

    if (pixelSize <= thumbnailSize) {
      return thumbnailSize;
    }
    if (pixelSize <= listItemSize) {
      return listItemSize;
    }
    if (pixelSize <= detailViewSize) {
      return detailViewSize;
    }
    return fullScreenSize;
  }

  /// Generate thumbnail URL for progressive loading
  static String generateThumbnailUrl(String originalUrl, {int maxSize = 50}) {
    final uri = Uri.tryParse(originalUrl);
    if (uri == null) {
      return originalUrl;
    }

    final queryParams = Map<String, String>.from(uri.queryParameters);
    queryParams['width'] = maxSize.toString();
    queryParams['height'] = maxSize.toString();
    queryParams['quality'] = '30'; // Low quality for thumbnails
    queryParams['blur'] = '5'; // Add blur for blur-up effect

    return uri.replace(queryParameters: queryParams).toString();
  }
}

/// Image context for automatic sizing optimization
enum ImageContext {
  /// Thumbnail context
  thumbnail,

  /// List item context
  listItem,

  /// Detail view context
  detailView,

  /// Full screen context
  fullScreen,

  /// Custom context
  custom;

  /// Get maximum size for this context
  int get maxSize {
    switch (this) {
      case ImageContext.thumbnail:
        return ImageSizeConstraints.thumbnailSize;
      case ImageContext.listItem:
        return ImageSizeConstraints.listItemSize;
      case ImageContext.detailView:
        return ImageSizeConstraints.detailViewSize;
      case ImageContext.fullScreen:
        return ImageSizeConstraints.fullScreenSize;
      case ImageContext.custom:
        return ImageSizeConstraints.listItemSize; // Default fallback
    }
  }
}

/// A reusable image loader widget with progressive loading and intelligent resizing.
///
/// Provides multiple loading modes for optimal UX:
/// - **none**: Standard loading with placeholder
/// - **blurUp**: Progressive blur-to-sharp transition
/// - **twoPhase**: Thumbnail then full resolution
/// - **fade**: Simple fade-in on load
///
/// ## Performance Optimizations
///
/// - Lazy animation controller initialization (only created when needed)
/// - Server-side resizing support for bandwidth optimization
/// - Smart cache sizing based on display context
/// - Memory-efficient thumbnail generation
class ImageLoader extends StatefulWidget {
  /// Creates an ImageLoader widget
  const ImageLoader({
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 0,
    this.cacheKey,
    this.cacheWidth,
    this.cacheHeight,
    this.placeholder,
    this.errorWidget,
    this.context = ImageContext.listItem,
    this.enableServerSideResizing = true,
    this.maxCacheSize,
    this.progressiveMode = ProgressiveLoadingMode.blurUp,
    this.heroTag,
    this.transitionDuration = const Duration(milliseconds: 300),
    super.key,
  });

  /// The URL of the image to load
  final String imageUrl;

  /// The width of the image
  final double? width;

  /// The height of the image
  final double? height;

  /// How the image should be fitted
  final BoxFit fit;

  /// The border radius to apply
  final double borderRadius;

  /// Cache key for the image
  final String? cacheKey;

  /// Cache width for the image
  final int? cacheWidth;

  /// Cache height for the image
  final int? cacheHeight;

  /// Placeholder widget while loading
  final Widget Function(BuildContext, String)? placeholder;

  /// Error widget if loading fails
  final Widget Function(BuildContext, String, Object)? errorWidget;

  /// Image context for sizing optimization
  final ImageContext context;

  /// Whether to enable server-side resizing
  final bool enableServerSideResizing;

  /// Maximum cache size
  final int? maxCacheSize;

  /// Progressive loading mode
  final ProgressiveLoadingMode progressiveMode;

  /// Hero tag for hero animations
  final String? heroTag;

  /// Duration for transition animations
  final Duration transitionDuration;

  @override
  State<ImageLoader> createState() => _ImageLoaderState();
}

class _ImageLoaderState extends State<ImageLoader>
    with TickerProviderStateMixin {
  // Lazy-initialized animation controllers (only created when needed)
  AnimationController? _fadeController;
  AnimationController? _blurController;

  bool _isMainImageLoaded = false;
  bool _isThumbnailLoaded = false;

  // Lazily create fade controller only when needed
  AnimationController get fadeController {
    _fadeController ??= AnimationController(
      duration: widget.transitionDuration,
      vsync: this,
    );
    return _fadeController!;
  }

  // Lazily create blur controller only when needed
  AnimationController get blurController {
    _blurController ??= AnimationController(
      duration: widget.transitionDuration,
      vsync: this,
    );
    return _blurController!;
  }

  // Lazy animation getters
  Animation<double> get fadeAnimation => Tween<double>(begin: 0, end: 1)
      .animate(CurvedAnimation(parent: fadeController, curve: Curves.easeIn));

  Animation<double> get blurAnimation => Tween<double>(begin: 5, end: 0)
      .animate(CurvedAnimation(parent: blurController, curve: Curves.easeOut));

  @override
  void dispose() {
    _fadeController?.dispose();
    _blurController?.dispose();
    super.dispose();
  }

  // ============================================================
  // Cache Size Calculation Helpers
  // ============================================================

  /// Calculate optimal cache width based on widget configuration
  int get _optimalCacheWidth {
    return widget.cacheWidth ??
        widget.maxCacheSize ??
        (widget.width != null
            ? ImageSizeConstraints.calculateCacheSize(widget.width)
            : widget.context.maxSize);
  }

  /// Calculate optimal cache height based on widget configuration
  int get _optimalCacheHeight {
    return widget.cacheHeight ??
        widget.maxCacheSize ??
        (widget.height != null
            ? ImageSizeConstraints.calculateCacheSize(widget.height)
            : widget.context.maxSize);
  }

  /// Generate cache key for the image
  String get _cacheKey =>
      widget.cacheKey ??
      '${widget.imageUrl}_${_optimalCacheWidth}x$_optimalCacheHeight';

  /// Generate optimized image URL with size parameters for server-side resizing
  String get _optimizedImageUrl {
    if (!widget.enableServerSideResizing) {
      return widget.imageUrl;
    }

    final uri = Uri.tryParse(widget.imageUrl);
    if (uri == null) {
      return widget.imageUrl;
    }

    final queryParams = Map<String, String>.from(uri.queryParameters);

    // Only add size params if not already present
    _addIfMissing(queryParams, ['width', 'w'], _optimalCacheWidth.toString());
    _addIfMissing(queryParams, ['height', 'h'], _optimalCacheHeight.toString());
    _addIfMissing(queryParams, ['quality', 'q'], '85');
    _addIfMissing(queryParams, ['format', 'f'], 'webp');

    return uri.replace(queryParameters: queryParams).toString();
  }

  /// Add value to map if none of the keys are present
  void _addIfMissing(Map<String, String> map, List<String> keys, String value) {
    if (!keys.any(map.containsKey)) {
      map[keys.first] = value;
    }
  }

  // ============================================================
  // Image Loading Callbacks
  // ============================================================

  void _onMainImageLoaded() {
    if (_isMainImageLoaded) {
      return;
    }

    setState(() => _isMainImageLoaded = true);
    fadeController.forward();

    if (widget.progressiveMode == ProgressiveLoadingMode.blurUp) {
      blurController.forward();
    }
  }

  void _onThumbnailLoaded() {
    if (_isThumbnailLoaded) {
      return;
    }
    setState(() => _isThumbnailLoaded = true);
  }

  // ============================================================
  // Image Builder Methods
  // ============================================================

  Widget _buildProgressiveImage() {
    switch (widget.progressiveMode) {
      case ProgressiveLoadingMode.none:
        return _buildStandardImage();
      case ProgressiveLoadingMode.blurUp:
        return _buildBlurUpImage();
      case ProgressiveLoadingMode.twoPhase:
        return _buildTwoPhaseImage();
      case ProgressiveLoadingMode.fade:
        return _buildFadeImage();
    }
  }

  Widget _buildStandardImage() => _cachedImage(
        url: _optimizedImageUrl,
        cacheWidth: _optimalCacheWidth,
        cacheHeight: _optimalCacheHeight,
        placeholder: widget.placeholder ?? _defaultPlaceholder,
      );

  Widget _buildBlurUpImage() {
    final thumbnailUrl =
        ImageSizeConstraints.generateThumbnailUrl(widget.imageUrl);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Thumbnail with blur effect
        if (!_isMainImageLoaded)
          AnimatedBuilder(
            animation: blurAnimation,
            builder: (context, child) => ImageFiltered(
              imageFilter: ui.ImageFilter.blur(
                sigmaX: blurAnimation.value,
                sigmaY: blurAnimation.value,
              ),
              child: _cachedImage(
                url: thumbnailUrl,
                cacheWidth: 50,
                cacheHeight: 50,
                placeholder: widget.placeholder ?? _defaultPlaceholder,
              ),
            ),
          ),

        // Main image with fade transition
        AnimatedBuilder(
          animation: fadeAnimation,
          builder: (context, child) => Opacity(
            opacity: fadeAnimation.value,
            child: _cachedImage(
              url: _optimizedImageUrl,
              cacheWidth: _optimalCacheWidth,
              cacheHeight: _optimalCacheHeight,
              placeholder: (_, __) => const SizedBox.shrink(),
              onLoaded: _onMainImageLoaded,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTwoPhaseImage() {
    final thumbnailUrl = ImageSizeConstraints.generateThumbnailUrl(
      widget.imageUrl,
      maxSize: 100,
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        // Thumbnail phase
        if (!_isMainImageLoaded)
          _cachedImage(
            url: thumbnailUrl,
            cacheWidth: 100,
            cacheHeight: 100,
            placeholder: widget.placeholder ?? _defaultPlaceholder,
            onLoaded: _onThumbnailLoaded,
          ),

        // Main image phase with fade
        AnimatedBuilder(
          animation: fadeAnimation,
          builder: (context, child) => Opacity(
            opacity: fadeAnimation.value,
            child: _cachedImage(
              url: _optimizedImageUrl,
              cacheWidth: _optimalCacheWidth,
              cacheHeight: _optimalCacheHeight,
              placeholder: (_, __) => const SizedBox.shrink(),
              onLoaded: _onMainImageLoaded,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFadeImage() => Stack(
        fit: StackFit.expand,
        children: [
          // Placeholder layer
          if (!_isMainImageLoaded)
            widget.placeholder?.call(context, _optimizedImageUrl) ??
                _defaultPlaceholder(context, _optimizedImageUrl),

          // Main image with fade transition
          _cachedImage(
            url: _optimizedImageUrl,
            cacheWidth: _optimalCacheWidth,
            cacheHeight: _optimalCacheHeight,
            placeholder: (_, __) => const SizedBox.shrink(),
            onLoaded: _onMainImageLoaded,
            useFadeTransition: true,
          ),
        ],
      );

  // ============================================================
  // Reusable CachedNetworkImage Builder
  // ============================================================

  /// Builds a CachedNetworkImage with common configuration
  Widget _cachedImage({
    required String url,
    required int cacheWidth,
    required int cacheHeight,
    Widget Function(BuildContext, String)? placeholder,
    VoidCallback? onLoaded,
    bool useFadeTransition = false,
  }) {
    return CachedNetworkImage(
      imageUrl: url,
      cacheKey: url == _optimizedImageUrl ? _cacheKey : null,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      memCacheWidth: cacheWidth,
      memCacheHeight: cacheHeight,
      placeholder: placeholder,
      errorWidget: widget.errorWidget ?? _defaultErrorWidget,
      imageBuilder: onLoaded != null
          ? (context, imageProvider) {
              WidgetsBinding.instance.addPostFrameCallback((_) => onLoaded());
              return useFadeTransition
                  ? AnimatedOpacity(
                      opacity: _isMainImageLoaded ? 1.0 : 0.0,
                      duration: widget.transitionDuration,
                      child: Image(image: imageProvider, fit: widget.fit),
                    )
                  : Image(image: imageProvider, fit: widget.fit);
            }
          : null,
    );
  }

  // ============================================================
  // Default Placeholder and Error Widgets
  // ============================================================

  static Widget _defaultPlaceholder(BuildContext context, String url) =>
      ColoredBox(
        color: Colors.grey.shade200,
        child: const Center(
          child: SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );

  static Widget _defaultErrorWidget(
    BuildContext context,
    String url,
    Object error,
  ) =>
      ColoredBox(
        color: Colors.grey.shade100,
        child: const Center(
          child: Icon(Icons.broken_image, size: 32, color: Colors.redAccent),
        ),
      );

  @override
  Widget build(BuildContext context) {
    Widget imageWidget = ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: _buildProgressiveImage(),
    );

    // Wrap with Hero if heroTag is provided
    if (widget.heroTag != null) {
      imageWidget = Hero(tag: widget.heroTag!, child: imageWidget);
    }

    return imageWidget;
  }
}
