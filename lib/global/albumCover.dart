// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sizer/sizer.dart';

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
    final double coverSize = size ?? 40.h;

    return Container(
      width: coverSize,
      height: coverSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: imageUrl == null
            ? Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(51),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background or fallback
          Container(
            color: Colors.grey.shade200,
            child: imageUrl == null
                ? Image.asset(
                    'assets/logo/rr-logo.png',
                    fit: BoxFit.contain,
                  )
                : null,
          ),

          // Album image
          if (imageUrl != null)
            CachedNetworkImage(
              imageUrl: imageUrl!,
              fit: BoxFit.cover,
              placeholder: (context, url) => Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              errorWidget: (context, url, error) => const Icon(
                Icons.broken_image,
                size: 40,
              ),
            ),

          // Album name overlay
          if (albumName != null && imageUrl == null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                color: Colors.black.withAlpha(153),
                child: Text(
                  albumName!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
