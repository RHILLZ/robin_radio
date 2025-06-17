import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Progressive loading mode options
enum ProgressiveLoadingMode {
  none,
  blurUp,
  twoPhase,
  fade,
}

/// Size constraint constants for different UI contexts
class ImageSizeConstraints {
  static const int thumbnailSize = 150;
  static const int listItemSize = 300;
  static const int detailViewSize = 800;
  static const int fullScreenSize = 1200;

  /// Calculate appropriate cache size based on display size
  static int calculateCacheSize(double? displaySize) {
    if (displaySize == null) return listItemSize;

    final pixelSize = (displaySize * 3).round(); // 3x for high DPI displays

    if (pixelSize <= thumbnailSize) return thumbnailSize;
    if (pixelSize <= listItemSize) return listItemSize;
    if (pixelSize <= detailViewSize) return detailViewSize;
    return fullScreenSize;
  }

  /// Generate thumbnail URL for progressive loading
  static String generateThumbnailUrl(String originalUrl, {int maxSize = 50}) {
    final uri = Uri.tryParse(originalUrl);
    if (uri == null) return originalUrl;

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
  thumbnail,
  listItem,
  detailView,
  fullScreen,
  custom;

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
class ImageLoader extends StatefulWidget {
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

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;
  final String? cacheKey;
  final int? cacheWidth;
  final int? cacheHeight;
  final Widget Function(BuildContext, String)? placeholder;
  final Widget Function(BuildContext, String, Object)? errorWidget;
  final ImageContext context;
  final bool enableServerSideResizing;
  final int? maxCacheSize;
  final ProgressiveLoadingMode progressiveMode;
  final String? heroTag;
  final Duration transitionDuration;

  @override
  State<ImageLoader> createState() => _ImageLoaderState();
}

class _ImageLoaderState extends State<ImageLoader>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _blurController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _blurAnimation;

  bool _isMainImageLoaded = false;
  bool _isThumbnailLoaded = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: widget.transitionDuration,
      vsync: this,
    );
    _blurController = AnimationController(
      duration: widget.transitionDuration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    _blurAnimation = Tween<double>(begin: 5, end: 0).animate(
      CurvedAnimation(parent: _blurController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _blurController.dispose();
    super.dispose();
  }

  /// Generate optimized image URL with size parameters for server-side resizing
  String _getOptimizedImageUrl() {
    if (!widget.enableServerSideResizing) return widget.imageUrl;

    final uri = Uri.tryParse(widget.imageUrl);
    if (uri == null) return widget.imageUrl;

    // Calculate optimal size
    final targetWidth = _calculateOptimalCacheWidth();
    final targetHeight = _calculateOptimalCacheHeight();

    // Add size parameters if the URL doesn't already have them
    final queryParams = Map<String, String>.from(uri.queryParameters);

    // Only add size params if they're not already present
    if (!queryParams.containsKey('width') && !queryParams.containsKey('w')) {
      queryParams['width'] = targetWidth.toString();
    }
    if (!queryParams.containsKey('height') && !queryParams.containsKey('h')) {
      queryParams['height'] = targetHeight.toString();
    }

    // Common server-side resizing parameters
    if (!queryParams.containsKey('quality') && !queryParams.containsKey('q')) {
      queryParams['quality'] = '85'; // Good balance of quality vs size
    }
    if (!queryParams.containsKey('format') && !queryParams.containsKey('f')) {
      queryParams['format'] = 'webp'; // Prefer WebP if server supports it
    }

    return uri.replace(queryParameters: queryParams).toString();
  }

  /// Calculate optimal cache width based on display width and context
  int _calculateOptimalCacheWidth() {
    if (widget.cacheWidth != null) return widget.cacheWidth!;
    if (widget.maxCacheSize != null) return widget.maxCacheSize!;

    if (widget.width != null) {
      return ImageSizeConstraints.calculateCacheSize(widget.width);
    }

    return widget.context.maxSize;
  }

  /// Calculate optimal cache height based on display height and context
  int _calculateOptimalCacheHeight() {
    if (widget.cacheHeight != null) return widget.cacheHeight!;
    if (widget.maxCacheSize != null) return widget.maxCacheSize!;

    if (widget.height != null) {
      return ImageSizeConstraints.calculateCacheSize(widget.height);
    }

    return widget.context.maxSize;
  }

  void _onMainImageLoaded() {
    if (!_isMainImageLoaded) {
      setState(() {
        _isMainImageLoaded = true;
      });
      _fadeController.forward();
      if (widget.progressiveMode == ProgressiveLoadingMode.blurUp) {
        _blurController.forward();
      }
    }
  }

  void _onThumbnailLoaded() {
    if (!_isThumbnailLoaded) {
      setState(() {
        _isThumbnailLoaded = true;
      });
    }
  }

  Widget _buildProgressiveImage() {
    final optimizedUrl = _getOptimizedImageUrl();
    final optimalCacheWidth = _calculateOptimalCacheWidth();
    final optimalCacheHeight = _calculateOptimalCacheHeight();

    switch (widget.progressiveMode) {
      case ProgressiveLoadingMode.none:
        return _buildStandardImage(
          optimizedUrl,
          optimalCacheWidth,
          optimalCacheHeight,
        );

      case ProgressiveLoadingMode.blurUp:
        return _buildBlurUpImage(
          optimizedUrl,
          optimalCacheWidth,
          optimalCacheHeight,
        );

      case ProgressiveLoadingMode.twoPhase:
        return _buildTwoPhaseImage(
          optimizedUrl,
          optimalCacheWidth,
          optimalCacheHeight,
        );

      case ProgressiveLoadingMode.fade:
        return _buildFadeImage(
          optimizedUrl,
          optimalCacheWidth,
          optimalCacheHeight,
        );
    }
  }

  Widget _buildStandardImage(String url, int cacheWidth, int cacheHeight) =>
      CachedNetworkImage(
        imageUrl: url,
        cacheKey:
            widget.cacheKey ?? '${widget.imageUrl}_${cacheWidth}x$cacheHeight',
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        memCacheWidth: cacheWidth,
        memCacheHeight: cacheHeight,
        placeholder: widget.placeholder ?? _defaultPlaceholder,
        errorWidget: widget.errorWidget ?? _defaultErrorWidget,
      );

  Widget _buildBlurUpImage(String url, int cacheWidth, int cacheHeight) {
    final thumbnailUrl =
        ImageSizeConstraints.generateThumbnailUrl(widget.imageUrl);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Thumbnail with blur effect
        if (!_isMainImageLoaded)
          AnimatedBuilder(
            animation: _blurAnimation,
            builder: (context, child) => ImageFiltered(
              imageFilter: ui.ImageFilter.blur(
                sigmaX: _blurAnimation.value,
                sigmaY: _blurAnimation.value,
              ),
              child: CachedNetworkImage(
                imageUrl: thumbnailUrl,
                width: widget.width,
                height: widget.height,
                fit: widget.fit,
                memCacheWidth: 50,
                memCacheHeight: 50,
                placeholder: widget.placeholder ?? _defaultPlaceholder,
                errorWidget: widget.errorWidget ?? _defaultErrorWidget,
              ),
            ),
          ),

        // Main image with fade transition
        AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) => Opacity(
            opacity: _fadeAnimation.value,
            child: CachedNetworkImage(
              imageUrl: url,
              cacheKey: widget.cacheKey ??
                  '${widget.imageUrl}_${cacheWidth}x$cacheHeight',
              width: widget.width,
              height: widget.height,
              fit: widget.fit,
              memCacheWidth: cacheWidth,
              memCacheHeight: cacheHeight,
              placeholder: (context, url) => const SizedBox.shrink(),
              errorWidget: widget.errorWidget ?? _defaultErrorWidget,
              imageBuilder: (context, imageProvider) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _onMainImageLoaded();
                });
                return Image(image: imageProvider, fit: widget.fit);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTwoPhaseImage(String url, int cacheWidth, int cacheHeight) {
    final thumbnailUrl = ImageSizeConstraints.generateThumbnailUrl(
      widget.imageUrl,
      maxSize: 100,
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        // Thumbnail phase
        if (!_isMainImageLoaded)
          CachedNetworkImage(
            imageUrl: thumbnailUrl,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            memCacheWidth: 100,
            memCacheHeight: 100,
            placeholder: widget.placeholder ?? _defaultPlaceholder,
            errorWidget: widget.errorWidget ?? _defaultErrorWidget,
            imageBuilder: (context, imageProvider) {
              // Fix: Wrap setState call in addPostFrameCallback to avoid calling setState during build
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _onThumbnailLoaded();
              });
              return Image(image: imageProvider, fit: widget.fit);
            },
          ),

        // Main image phase
        AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) => Opacity(
            opacity: _fadeAnimation.value,
            child: CachedNetworkImage(
              imageUrl: url,
              cacheKey: widget.cacheKey ??
                  '${widget.imageUrl}_${cacheWidth}x$cacheHeight',
              width: widget.width,
              height: widget.height,
              fit: widget.fit,
              memCacheWidth: cacheWidth,
              memCacheHeight: cacheHeight,
              placeholder: (context, url) => const SizedBox.shrink(),
              errorWidget: widget.errorWidget ?? _defaultErrorWidget,
              imageBuilder: (context, imageProvider) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _onMainImageLoaded();
                });
                return Image(image: imageProvider, fit: widget.fit);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFadeImage(String url, int cacheWidth, int cacheHeight) =>
      AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) => AnimatedOpacity(
          opacity: _isMainImageLoaded ? 1.0 : 0.0,
          duration: widget.transitionDuration,
          child: CachedNetworkImage(
            imageUrl: url,
            cacheKey: widget.cacheKey ??
                '${widget.imageUrl}_${cacheWidth}x$cacheHeight',
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            memCacheWidth: cacheWidth,
            memCacheHeight: cacheHeight,
            placeholder: widget.placeholder ?? _defaultPlaceholder,
            errorWidget: widget.errorWidget ?? _defaultErrorWidget,
            imageBuilder: (context, imageProvider) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _onMainImageLoaded();
              });
              return Image(image: imageProvider, fit: widget.fit);
            },
          ),
        ),
      );

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
      imageWidget = Hero(
        tag: widget.heroTag!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}
