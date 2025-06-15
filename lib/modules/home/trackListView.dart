// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:miniplayer/miniplayer.dart';
import '../../data/models/album.dart';
import '../../global/albumCover.dart';
import '../../global/trackItem.dart';
import '../player/player_controller.dart';
import '../app/app_controller.dart';

class TrackListView extends StatelessWidget {
  const TrackListView({
    required this.album,
    super.key,
  });
  final Album album;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PlayerController());

    return Scaffold(
      appBar: AppBar(
        title: Text(
          album.albumName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_circle_filled),
            onPressed: () => _playAlbum(controller),
            tooltip: 'Play all',
          ),
          IconButton(
            icon: const Icon(Icons.shuffle),
            onPressed: () => _playAlbumShuffled(controller),
            tooltip: 'Shuffle',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildAlbumHeader(context),
          Expanded(
            child: ListView.builder(
              itemCount: album.tracks.length,
              itemBuilder: (context, index) => TrackListItem(
                song: album.tracks[index],
                index: index,
                onTap: () => _playTrack(controller, index),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumHeader(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withAlpha(128),
        child: Row(
          children: [
            Hero(
              tag: 'album-${album.id}',
              child: AlbumCover(
                imageUrl: album.albumCover,
                albumName: album.albumName,
                size: 100,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album.albumName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    album.artist ?? 'Unknown Artist',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${album.trackCount} tracks',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  void _playAlbum(PlayerController controller) {
    controller.playAlbum(album);

    // Expand the player to full screen instead of showing mini player
    Get.find<AppController>().miniPlayerController.animateToHeight(
          state: PanelState.MAX,
        );

    // Close the bottom sheet
    Get.back<void>();
  }

  void _playAlbumShuffled(PlayerController controller) {
    controller.playAlbum(album);
    controller.toggleShuffleMode();

    // Expand the player to full screen instead of showing mini player
    Get.find<AppController>().miniPlayerController.animateToHeight(
          state: PanelState.MAX,
        );

    // Close the bottom sheet
    Get.back<void>();
  }

  void _playTrack(PlayerController controller, int index) {
    controller.playAlbum(album, startIndex: index);

    // Expand the player to full screen instead of showing mini player
    Get.find<AppController>().miniPlayerController.animateToHeight(
          state: PanelState.MAX,
        );

    // Close the bottom sheet
    Get.back<void>();
  }
}
