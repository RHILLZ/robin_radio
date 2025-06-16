import 'package:flutter/material.dart';
import '../../../data/models/album.dart';
import '../../albumCover.dart';

class AlbumCardWidget extends StatelessWidget {
  const AlbumCardWidget({
    required this.album,
    required this.onTap,
    super.key,
  });

  final Album album;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: GestureDetector(
          onTap: onTap,
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Album cover
                Expanded(
                  child: Hero(
                    tag: 'album-${album.id}',
                    child: ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(12)),
                      child: RepaintBoundary(
                        child: AlbumCover(
                          imageUrl: album.albumCover,
                          albumName: album.albumName,
                          size: double.infinity,
                        ),
                      ),
                    ),
                  ),
                ),

                // Album info
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        album.albumName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        album.artist ?? 'Unknown Artist',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${album.trackCount} tracks',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AlbumCardWidget && other.album.id == album.id;
  }

  @override
  int get hashCode => album.id.hashCode;
}
