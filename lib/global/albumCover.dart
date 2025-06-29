// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'widgets/common/image_loader.dart';

class AlbumCover extends StatelessWidget {
  const AlbumCover({
    super.key,
    this.imageUrl,
    this.albumName,
    this.size,
    this.borderRadius = 8.0,
  });

  final String? imageUrl;
  final String? albumName;
  final double? size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    // If size is provided and valid, use it; otherwise let the parent constrain us
    final useExplicitSize = size != null && size!.isFinite && size! > 0;
    final coverSize = useExplicitSize ? size : null;

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
