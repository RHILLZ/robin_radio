import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:robin_radio/data/models/song.dart';
import 'package:robin_radio/modules/player/player_controller.dart';
import 'package:sizer/sizer.dart';

class MiniPlayerWidget extends GetWidget<PlayerController> {
  const MiniPlayerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final bool hasTrack = controller.tracks.isNotEmpty;
      final Song? currentTrack = controller.currentSong ??
          (controller.playerMode == PlayerMode.radio
              ? controller.currentRadioSong
              : null);

      // Don't show the player if there's no track
      if (!hasTrack && controller.playerMode != PlayerMode.radio) {
        return const SizedBox.shrink();
      }

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Player content
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(26),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Album cover
                SizedBox(
                  width: 25.w,
                  height: 12.h - 6.0,
                  child: _buildAlbumCover(),
                ),

                // Track info
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Track title
                        Text(
                          _formatTrackTitle(currentTrack?.songName),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 1.h),

                        // Artist name
                        Text(
                          currentTrack?.artist ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withAlpha(179),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Player controls
                _buildPlayerControls(context),

                // Close button
                IconButton(
                  onPressed: controller.closePlayer,
                  iconSize: 24,
                  icon: const Icon(Icons.close),
                  tooltip: 'Close player',
                ),

                SizedBox(width: 2.w),
              ],
            ),
          ),

          // Progress bar
          LinearProgressIndicator(
            value: controller.getProgressValue(),
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
            minHeight: 2,
          ),
        ],
      );
    });
  }

  Widget _buildAlbumCover() {
    return controller.coverURL != null
        ? CachedNetworkImage(
            imageUrl: controller.coverURL!,
            fit: BoxFit.cover,
            placeholder: (context, url) => _buildFallbackCover(),
            errorWidget: (context, url, error) => _buildFallbackCover(),
          )
        : _buildFallbackCover();
  }

  Widget _buildFallbackCover() {
    return Container(
      color: Get.theme.colorScheme.primaryContainer,
      child: Center(
        child: Icon(
          Icons.music_note,
          size: 40,
          color: Get.theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildPlayerControls(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Previous button (only in album mode)
        if (controller.playerMode == PlayerMode.album)
          IconButton(
            icon: const Icon(Icons.skip_previous),
            onPressed: controller.previous,
            iconSize: 24,
            tooltip: 'Previous',
          ),

        // Play/pause button
        controller.playerIcon(size: 40),

        // Next button
        IconButton(
          icon: const Icon(Icons.skip_next),
          onPressed: controller.next,
          iconSize: 24,
          tooltip: 'Next',
        ),
      ],
    );
  }

  String _formatTrackTitle(String? name) {
    if (name == null || name.isEmpty) return '';
    if (name.length < 3) return name;

    final parts = name.substring(3).split('.');
    return parts.isNotEmpty ? parts[0] : name;
  }
}
