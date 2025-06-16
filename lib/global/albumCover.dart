// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
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
    final coverSize = size ?? 40.h;

    // If no image URL, show fallback immediately
    if (imageUrl == null || imageUrl!.isEmpty) {
      return Container(
        width: coverSize,
        height: coverSize,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          color: Colors.grey.shade200,
        ),
        child: const Center(
          child: Icon(
            Icons.music_note,
            size: 32,
            color: Colors.grey,
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
          child: const Center(
            child: Icon(
              Icons.broken_image,
              size: 32,
              color: Colors.redAccent,
            ),
          ),
        ),
      ),
    );
  }
}
