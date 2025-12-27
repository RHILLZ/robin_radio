// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'widgets/common/image_loader.dart';

/// A widget that displays album artwork with fallback handling.
///
/// Provides a consistent way to display album covers throughout the app
/// with proper loading states, error handling, and fallback imagery.
class AlbumCover extends StatelessWidget {
  /// Creates an album cover widget.
  ///
  /// [imageUrl] is the URL of the album artwork to display.
  /// [albumName] is the name of the album for accessibility.
  /// [size] is the desired width and height of the cover.
  /// [borderRadius] is the radius for rounded corners (defaults to 8.0).
  const AlbumCover({
    super.key,
    this.imageUrl,
    this.albumName,
    this.size,
    this.borderRadius = 8.0,
  });

  /// The URL of the album artwork to display.
  final String? imageUrl;

  /// The name of the album for accessibility purposes.
  final String? albumName;

  /// The desired width and height of the cover in logical pixels.
  final double? size;

  /// The radius for rounded corners of the album cover.
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    // If size is provided and valid, use it; otherwise let the parent constrain us
    final useExplicitSize = size != null && size!.isFinite && size! > 0;
    final coverSize = useExplicitSize ? size : null;

    // Wrap in RepaintBoundary to isolate album cover repaints
    // Album covers are frequently displayed in lists and player views,
    // preventing repaint propagation improves scroll and animation performance
    return RepaintBoundary(
      child: _buildCoverContent(coverSize),
    );
  }

  Widget _buildCoverContent(double? coverSize) {
    // If no image URL, show logo fallback immediately
    if (imageUrl == null || imageUrl!.isEmpty) {
      return Container(
        width: coverSize,
        height: coverSize,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          color: Colors.grey.shade200,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Image.asset(
              'assets/logo/rr-logo.webp',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.music_note,
                size: 32,
                color: Colors.grey,
              ),
            ),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: ImageLoader(
        imageUrl: imageUrl!,
        width: coverSize,
        height: coverSize,
        context: ImageContext.detailView,
        progressiveMode: ProgressiveLoadingMode.fade,
        transitionDuration: const Duration(milliseconds: 600),
        // Disable server-side resizing for Firebase Storage URLs
        // Firebase Storage URLs are signed and adding query params breaks them
        enableServerSideResizing: false,
        placeholder: (context, url) => Container(
          width: coverSize,
          height: coverSize,
          color: Colors.grey.shade200,
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: coverSize,
          height: coverSize,
          color: Colors.grey.shade100,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Image.asset(
                'assets/logo/rr-logo.webp',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.broken_image,
                  size: 32,
                  color: Colors.redAccent,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
