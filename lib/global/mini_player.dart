import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';

import '../data/models/song.dart';
import '../modules/player/player_controller.dart';
import 'cosmic_theme.dart';
import 'widgets/widgets.dart';

/// A compact mini player widget that displays current track information and controls.
///
/// This widget provides a condensed view of the music player that appears
/// at the bottom of the screen, showing current track details and basic
/// playback controls without taking up the full screen.
///
/// ## Performance Optimization
///
/// This widget uses targeted `Obx` wrappers for individual reactive components
/// instead of wrapping the entire widget tree. This ensures:
/// - **Minimal rebuilds**: Only affected components rebuild when state changes
/// - **Better performance**: Progress bar updates don't rebuild track info
/// - **Isolated updates**: Album cover, track info, and controls rebuild independently
class MiniPlayerWidget extends GetWidget<PlayerController> {
  /// Creates a mini player widget.
  const MiniPlayerWidget({super.key});

  @override
  Widget build(BuildContext context) => Obx(_buildVisibilityWrapper);

  /// Wraps content in visibility check - only this rebuilds on visibility changes.
  Widget _buildVisibilityWrapper() {
    final hasTrack = controller.tracks.isNotEmpty;
    final currentTrack = controller.currentSong ??
        (controller.playerMode == PlayerMode.radio
            ? controller.currentRadioSong
            : null);

    // Don't show the player if there's no track
    if (!hasTrack && controller.playerMode != PlayerMode.radio) {
      return const SizedBox.shrink();
    }

    // Don't show the player if it's being closed
    if (currentTrack == null && controller.tracks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Player content with glassmorphism
        ClipRRect(
          child: BackdropFilter(
            filter: CosmicGlass.blur,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: CosmicColors.cardGradient(opacity: 0.8),
                boxShadow: [
                  BoxShadow(
                    color: CosmicColors.vibrantPurple.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, -4),
                  ),
                  BoxShadow(
                    color: CosmicColors.lavenderGlow.withValues(alpha: 0.1),
                    blurRadius: 30,
                    spreadRadius: 2,
                  ),
                ],
                border: Border(
                  top: BorderSide(
                    color: CosmicColors.lavenderGlow.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Album cover with neon glow - isolated rebuild
                  const _MiniPlayerAlbumCover(),

                  // Track info - isolated rebuild
                  const Expanded(
                    child: _MiniPlayerTrackInfo(),
                  ),

                  // Player controls - uses its own Obx internally
                  const PlayerControlsWidget(
                    compactMode: true,
                  ),

                  // Close button - static, no rebuild needed
                  _buildCloseButton(),

                  SizedBox(width: 2.w),
                ],
              ),
            ),
          ),
        ),

        // Progress bar - isolated rebuild for position updates
        const _MiniPlayerProgressBar(),
      ],
    );
  }

  Widget _buildCloseButton() => RepaintBoundary(
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: CosmicColors.lavenderGlow.withValues(alpha: 0.15),
                blurRadius: 8,
              ),
            ],
          ),
          child: IconButton(
            onPressed: () {
              controller.closePlayer();
            },
            iconSize: 24,
            icon: Icon(
              Icons.close,
              color: CosmicColors.lavenderGlow.withValues(alpha: 0.8),
            ),
            tooltip: 'Close player',
          ),
        ),
      );
}

/// Isolated album cover widget with its own Obx for targeted rebuilds.
class _MiniPlayerAlbumCover extends GetWidget<PlayerController> {
  const _MiniPlayerAlbumCover();

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: Container(
          width: 25.w,
          height: 12.h - 6.0,
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: CosmicColors.vibrantPurple.withValues(alpha: 0.4),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Obx(_buildAlbumCover),
        ),
      );

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
            enableServerSideResizing: false,
          ),
        )
      : _buildFallbackCover();

  Widget _buildFallbackCover() => DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              CosmicColors.vibrantPurple,
              CosmicColors.royalPurple,
            ],
          ),
        ),
        child: Center(
          child: Icon(
            Icons.music_note,
            size: 40,
            color: CosmicColors.lavenderGlow.withValues(alpha: 0.9),
          ),
        ),
      );
}

/// Isolated track info widget with its own Obx for targeted rebuilds.
class _MiniPlayerTrackInfo extends GetWidget<PlayerController> {
  const _MiniPlayerTrackInfo();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Track title with glow - rebuilds only on track change
            Obx(
              () => Text(
                _formatTrackTitle(_getCurrentTrack()?.songName),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: CosmicColors.lavenderGlow.withValues(alpha: 0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 1.h),

            // Artist name with golden accent - rebuilds only on track change
            Obx(
              () => Text(
                _getCurrentTrack()?.artist ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: CosmicColors.goldenAmber.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );

  /// Gets the current track based on player mode.
  Song? _getCurrentTrack() =>
      controller.currentSong ??
      (controller.playerMode == PlayerMode.radio
          ? controller.currentRadioSong
          : null);

  String _formatTrackTitle(String? name) {
    if (name == null || name.isEmpty) {
      return '';
    }
    if (name.length < 3) {
      return name;
    }

    final parts = name.substring(3).split('.');
    return parts.isNotEmpty ? parts[0] : name;
  }
}

/// Isolated progress bar widget with its own Obx for targeted rebuilds.
///
/// This is critical for performance as position updates frequently (every ~100ms)
/// and should not cause the entire mini player to rebuild.
class _MiniPlayerProgressBar extends GetWidget<PlayerController> {
  const _MiniPlayerProgressBar();

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: Container(
          height: 3,
          decoration: BoxDecoration(
            color: CosmicColors.deepPurple,
            boxShadow: [
              BoxShadow(
                color: CosmicColors.vibrantPurple.withValues(alpha: 0.3),
                blurRadius: 4,
              ),
            ],
          ),
          child: Obx(
            () => LinearProgressIndicator(
              value: controller.getProgressValue(),
              valueColor: const AlwaysStoppedAnimation<Color>(
                CosmicColors.goldenAmber,
              ),
              backgroundColor: CosmicColors.royalPurple.withValues(alpha: 0.5),
              minHeight: 3,
            ),
          ),
        ),
      );
}
