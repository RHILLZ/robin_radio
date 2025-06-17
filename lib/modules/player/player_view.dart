import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:miniplayer/miniplayer.dart';
import 'package:sizer/sizer.dart';

import '../../global/widgets/widgets.dart';
import '../app/app_controller.dart';
import 'player_controller.dart';

class PlayerView extends GetView<PlayerController> {
  const PlayerView({super.key});

  @override
  Widget build(BuildContext context) => Obx(
        () {
          final currentTrack = controller.currentSong ??
              (controller.playerMode == PlayerMode.radio
                  ? controller.currentRadioSong
                  : null);

          if (currentTrack == null) {
            return const Center(child: Text('No track selected'));
          }

          return ColoredBox(
            color: Theme.of(context).colorScheme.surface,
            child: SafeArea(
              child: Column(
                children: [
                  // App bar with close button
                  _buildAppBar(context),

                  // Flexible content area to prevent overflow
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          SizedBox(height: 2.h),

                          // Album cover - responsive sizing
                          _buildResponsiveAlbumCover(context),

                          // Track info
                          _buildTrackInfo(context, currentTrack),

                          // Progress bar
                          _buildProgressBar(context),

                          // Player controls
                          _buildPlayerControls(context),

                          // Additional controls (shuffle, repeat)
                          _buildAdditionalControls(context),

                          SizedBox(height: 2.h),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

  Widget _buildAppBar(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_down),
              onPressed: () => Get.find<AppController>()
                  .miniPlayerController
                  .animateToHeight(state: PanelState.MIN),
              tooltip: 'Minimize',
            ),
            Text(
              controller.playerMode == PlayerMode.radio
                  ? 'Radio'
                  : 'Now Playing',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                // Show options menu
                showModalBottomSheet<void>(
                  context: context,
                  builder: _buildOptionsMenu,
                );
              },
              tooltip: 'Options',
            ),
          ],
        ),
      );

  Widget _buildResponsiveAlbumCover(BuildContext context) {
    // Calculate responsive size based on available screen space
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Reserve space for other UI elements (app bar, controls, etc.)
    const reservedHeight = 300; // Approximate height of other elements
    final availableHeight = screenHeight - reservedHeight;

    // Use the smaller of 70% screen width or available height, with reasonable min/max
    final maxSize = screenWidth * 0.7;
    final responsiveSize = (availableHeight * 0.6).clamp(200.0, maxSize);

    return Container(
      width: responsiveSize,
      height: responsiveSize,
      margin: EdgeInsets.symmetric(vertical: 1.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(51),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ImageLoader(
          imageUrl: controller.coverURL ?? '',
          width: responsiveSize,
          height: responsiveSize,
          context: ImageContext.detailView,
          progressiveMode: ProgressiveLoadingMode.twoPhase,
          transitionDuration: const Duration(milliseconds: 800),
          heroTag: 'player_cover_${controller.currentSong?.songName}',
        ),
      ),
    );
  }

  Widget _buildTrackInfo(BuildContext context, song) {
    final songTitle = _formatSongTitle(song.songName as String);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      child: Column(
        children: [
          Text(
            songTitle,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 1.h),
          Text(
            song.artist as String,
            style: TextStyle(
              fontSize: 18,
              color: Theme.of(context).colorScheme.onSurface.withAlpha(179),
            ),
            textAlign: TextAlign.center,
          ),
          if (song.albumName != null && (song.albumName as String).isNotEmpty)
            Text(
              song.albumName as String,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(128),
              ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: Column(
          children: [
            Slider(
              value: controller.positionAsDouble,
              max: controller.durationAsDouble > 0
                  ? controller.durationAsDouble
                  : 1.0,
              onChanged: (value) => controller.seek(value),
              activeColor: Theme.of(context).colorScheme.primary,
              inactiveColor:
                  Theme.of(context).colorScheme.primary.withAlpha(77),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    controller.playerPositionFormatted,
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withAlpha(179),
                    ),
                  ),
                  Text(
                    controller.playerDurationFormatted,
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
          ],
        ),
      );

  Widget _buildPlayerControls(BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(vertical: 4.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PlayerControlButton(
              icon: Icons.skip_previous,
              onPressed: controller.previous,
              size: 40,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            SizedBox(width: 4.w),
            Container(
              height: 20.w,
              width: 20.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.primaryContainer,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(26),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: controller.playerIcon(size: 50),
            ),
            SizedBox(width: 4.w),
            PlayerControlButton(
              icon: Icons.skip_next,
              onPressed: controller.next,
              size: 40,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ],
        ),
      );

  Widget _buildAdditionalControls(BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: Icon(
                controller.isShuffleOn ? Icons.shuffle : Icons.shuffle,
                color: controller.isShuffleOn
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface.withAlpha(128),
              ),
              onPressed: controller.toggleShuffleMode,
              tooltip: 'Shuffle',
            ),
            IconButton(
              icon: Icon(
                controller.isRepeatOne
                    ? Icons.repeat_one
                    : controller.isRepeatAll
                        ? Icons.repeat
                        : Icons.repeat,
                color: (controller.isRepeatOne || controller.isRepeatAll)
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface.withAlpha(128),
              ),
              onPressed: controller.toggleRepeatMode,
              tooltip: 'Repeat',
            ),
            IconButton(
              icon: Icon(
                Icons.playlist_play,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(128),
              ),
              onPressed: () {
                // Show playlist
                showModalBottomSheet<void>(
                  context: context,
                  builder: _buildPlaylist,
                );
              },
              tooltip: 'Playlist',
            ),
          ],
        ),
      );

  Widget _buildOptionsMenu(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Close Player'),
              onTap: () {
                Navigator.pop(context);
                controller.closePlayer();
              },
            ),
            if (controller.playerMode == PlayerMode.album)
              ListTile(
                leading: const Icon(Icons.album),
                title: const Text('View Album'),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to album view
                },
              ),
          ],
        ),
      );

  Widget _buildPlaylist(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Text(
                    'Current Playlist',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: controller.tracks.length,
                itemBuilder: (context, index) {
                  final track = controller.tracks[index];
                  final isCurrentTrack = index == controller.trackIndex;

                  return ListTile(
                    key: ValueKey(
                      track.id ?? '${track.songName}_${track.artist}_$index',
                    ),
                    leading: isCurrentTrack
                        ? Icon(
                            Icons.play_arrow,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withAlpha(179),
                            ),
                          ),
                    title: Text(
                      _formatSongTitle(track.songName),
                      style: TextStyle(
                        fontWeight: isCurrentTrack
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isCurrentTrack
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Text(track.artist),
                    onTap: () {
                      controller.trackIndex = index;
                      controller.playTrack();
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      );

  String _formatSongTitle(String name) {
    if (name.length < 3) return name;
    final parts = name.substring(3).split('.');
    return parts.isNotEmpty ? parts[0] : name;
  }
}
