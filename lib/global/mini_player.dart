import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'widgets/widgets.dart';
import '../modules/player/player_controller.dart';
import 'package:sizer/sizer.dart';
import 'widgets/common/image_loader.dart';

class MiniPlayerWidget extends GetWidget<PlayerController> {
  const MiniPlayerWidget({super.key});

  @override
  Widget build(BuildContext context) => Obx(() {
        final hasTrack = controller.tracks.isNotEmpty;
        final currentTrack = controller.currentSong ??
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
            DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF6C30C4), // Match AppBar color
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(26),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Album cover
                  RepaintBoundary(
                    child: SizedBox(
                      width: 25.w,
                      height: 12.h - 6.0,
                      child: _buildAlbumCover(),
                    ),
                  ),

                  // Track info
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
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
                              color: Colors
                                  .white, // Ensure text is visible on purple background
                            ),
                          ),
                          SizedBox(height: 1.h),

                          // Artist name
                          Text(
                            currentTrack?.artist ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors
                                  .white70, // Lighter white for subtitle on purple background
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Player controls
                  const PlayerControlsWidget(
                    compactMode: true,
                  ),

                  // Close button
                  RepaintBoundary(
                    child: IconButton(
                      onPressed: controller.closePlayer,
                      iconSize: 24,
                      icon: const Icon(
                        Icons.close,
                        color: Colors
                            .white, // Ensure icon is visible on purple background
                      ),
                      tooltip: 'Close player',
                    ),
                  ),

                  SizedBox(width: 2.w),
                ],
              ),
            ),

            // Progress bar
            LinearProgressIndicator(
              value: controller.getProgressValue(),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Colors.white, // White progress for better visibility on purple
              ),
              backgroundColor:
                  Colors.white24, // Semi-transparent white background
              minHeight: 2,
            ),
          ],
        );
      });

  Widget _buildAlbumCover() => controller.coverURL != null
      ? ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: ImageLoader(
            imageUrl: controller.coverURL!,
            width: 40,
            height: 40,
            context: ImageContext.thumbnail,
            transitionDuration: const Duration(milliseconds: 500),
            heroTag: 'mini_player_cover_${controller.currentSong?.songName}',
          ),
        )
      : _buildFallbackCover();

  Widget _buildFallbackCover() => const ColoredBox(
        color: Color(0xFF6C30C4), // Match AppBar color
        child: Center(
          child: Icon(
            Icons.music_note,
            size: 40,
            color: Colors
                .white, // White icon for better contrast on purple background
          ),
        ),
      );

  String _formatTrackTitle(String? name) {
    if (name == null || name.isEmpty) return '';
    if (name.length < 3) return name;

    final parts = name.substring(3).split('.');
    return parts.isNotEmpty ? parts[0] : name;
  }
}
