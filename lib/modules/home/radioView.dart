// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:robin_radio/modules/player/player_controller.dart';
import 'package:sizer/sizer.dart';

class RadioView extends GetView<PlayerController> {
  const RadioView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Container(
          color: Theme.of(context).colorScheme.surface,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo or album art
                _buildLogoOrAlbumArt(context),

                // Song info or start button
                _isRadioPlaying
                    ? _buildNowPlayingInfo(context)
                    : _buildStartRadioButton(context),

                // Player controls
                if (_isRadioPlaying) _buildPlayerControls(context),
              ],
            ),
          ),
        ));
  }

  bool get _isRadioPlaying =>
      controller.playerMode == PlayerMode.radio &&
      controller.currentRadioSong != null &&
      controller.currentRadioSong!.songName.isNotEmpty;

  Widget _buildLogoOrAlbumArt(BuildContext context) {
    if (_isRadioPlaying && controller.coverURL != null) {
      return Container(
        width: 60.w,
        height: 60.w,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(51),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            controller.coverURL!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                Image.asset('assets/logo/rr-logo.png'),
          ),
        ),
      );
    }

    return SizedBox(
      width: 60.w,
      child: Image.asset('assets/logo/rr-logo.png'),
    );
  }

  Widget _buildStartRadioButton(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        elevation: 15,
        shape: const CircleBorder(),
        padding: EdgeInsets.all(12.w),
        backgroundColor:
            const Color(0xFF6C30C4), // Match AppBar color from theme
      ),
      onPressed: () {
        // Just play the radio without showing the player
        controller.playRadio();
        // Explicitly hide the player
        controller.hidePlayer();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Play Radio',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.8, end: 1.2),
            duration: const Duration(seconds: 1),
            curve: Curves.easeInOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Icon(
                  Icons.radio,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 40,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNowPlayingInfo(BuildContext context) {
    final song = controller.currentRadioSong!;
    final songTitle = _formatSongTitle(song.songName);

    return Container(
      padding: const EdgeInsets.all(16),
      width: 80.w,
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withAlpha(179),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            'NOW PLAYING',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            songTitle,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 1.h),
          Text(
            'by ${song.artist}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          if (song.albumName != null && song.albumName!.isNotEmpty)
            Text(
              'from ${song.albumName}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  Widget _buildPlayerControls(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color:
            Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(77),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: () => controller.previous(),
            icon: Icon(
              Icons.skip_previous,
              color: Theme.of(context).colorScheme.primary,
              size: 36,
            ),
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
            child: controller.playerIcon(size: 40),
          ),
          SizedBox(width: 4.w),
          IconButton(
            onPressed: () => controller.next(),
            icon: Icon(
              Icons.skip_next,
              color: Theme.of(context).colorScheme.primary,
              size: 36,
            ),
          ),
        ],
      ),
    );
  }

  String _formatSongTitle(String name) {
    if (name.length < 3) return name;
    final parts = name.substring(3).split('.');
    return parts.isNotEmpty ? parts[0] : name;
  }
}
