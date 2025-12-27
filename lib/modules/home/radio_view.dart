// ignore_for_file: file_names

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';

import '../../global/cosmic_theme.dart';
import '../../global/widgets/widgets.dart';
import '../player/player_controller.dart';

/// A view that displays the radio interface with playback controls.
///
/// This widget provides a radio-style interface allowing users to start
/// radio playback and view currently playing tracks with album art.
/// Features the Cosmic Vinyl aesthetic with glassmorphism and neon effects.
class RadioView extends GetView<PlayerController> {
  /// Creates a radio view.
  ///
  /// This view automatically manages radio playback state and UI updates.
  const RadioView({super.key});

  @override
  Widget build(BuildContext context) => Obx(
        () => Container(
          decoration: const BoxDecoration(
            // Cosmic gradient background
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                CosmicColors.deepPurple,
                Color(0xFF0D0618),
              ],
              stops: [0.0, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Subtle cosmic glow orbs
              _buildCosmicOrbs(),
              // Main content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Logo or album art
                    _buildLogoOrAlbumArt(context),

                    // Song info or start button
                    if (_isRadioPlaying)
                      _buildNowPlayingInfo(context)
                    else
                      _buildStartRadioButton(context),

                    // Player controls
                    if (_isRadioPlaying) _buildPlayerControls(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  bool get _isRadioPlaying =>
      controller.playerMode == PlayerMode.radio &&
      controller.currentRadioSong != null &&
      controller.currentRadioSong!.songName.isNotEmpty;

  /// Builds decorative cosmic glow orbs for atmosphere
  Widget _buildCosmicOrbs() => Stack(
        children: [
          // Top-left purple glow
          Positioned(
            top: -10.h,
            left: -10.w,
            child: Container(
              width: 50.w,
              height: 50.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    CosmicColors.vibrantPurple.withValues(alpha: 0.3),
                    CosmicColors.vibrantPurple.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          // Bottom-right golden glow
          Positioned(
            bottom: -15.h,
            right: -15.w,
            child: Container(
              width: 60.w,
              height: 60.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    CosmicColors.goldenAmber.withValues(alpha: 0.15),
                    CosmicColors.goldenAmber.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ],
      );

  Widget _buildLogoOrAlbumArt(BuildContext context) {
    if (_isRadioPlaying && controller.coverURL != null) {
      return Container(
        width: 65.w,
        height: 65.w,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          // Neon glow effect
          boxShadow: [
            BoxShadow(
              color: CosmicColors.vibrantPurple.withValues(alpha: 0.5),
              blurRadius: 40,
              spreadRadius: 5,
            ),
            BoxShadow(
              color: CosmicColors.lavenderGlow.withValues(alpha: 0.2),
              blurRadius: 60,
              spreadRadius: 10,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              ImageLoader(
                imageUrl: controller.coverURL!,
                width: 65.w,
                height: 65.w,
                context: ImageContext.detailView,
                transitionDuration: const Duration(milliseconds: 700),
                heroTag: 'radio_cover_${controller.currentRadioSong?.songName}',
                enableServerSideResizing: false,
                errorWidget: (context, url, error) => Image.asset(
                  'assets/logo/rr-logo.webp',
                  fit: BoxFit.contain,
                ),
              ),
              // Vinyl groove overlay effect
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.1),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.2),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Logo with cosmic glow when not playing
    return Container(
      width: 60.w,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: CosmicColors.vibrantPurple.withValues(alpha: 0.3),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Image.asset('assets/logo/rr-logo.webp'),
    );
  }

  Widget _buildStartRadioButton(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.95, end: 1.0),
      duration: const Duration(seconds: 2),
      curve: Curves.easeInOut,
      builder: (context, scale, child) => Transform.scale(
        scale: scale,
        child: child,
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // Outer glow ring
          boxShadow: [
            BoxShadow(
              color: CosmicColors.vibrantPurple.withValues(alpha: 0.6),
              blurRadius: 30,
              spreadRadius: 5,
            ),
            BoxShadow(
              color: CosmicColors.goldenAmber.withValues(alpha: 0.2),
              blurRadius: 50,
              spreadRadius: 10,
            ),
          ],
        ),
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    CosmicColors.vibrantPurple,
                    CosmicColors.royalPurple,
                  ],
                ),
                border: Border.all(
                  color: CosmicColors.lavenderGlow.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    controller.playRadio();
                    controller.hidePlayer();
                  },
                  customBorder: const CircleBorder(),
                  splashColor: CosmicColors.lavenderGlow.withValues(alpha: 0.3),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'PLAY RADIO',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: Colors.white,
                          letterSpacing: 3,
                          shadows: [
                            Shadow(
                              color: CosmicColors.lavenderGlow.withValues(alpha: 0.5),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildPulsingRadioIcon(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPulsingRadioIcon() => TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.8, end: 1.2),
        duration: const Duration(milliseconds: 1200),
        curve: Curves.easeInOut,
        builder: (context, value, child) => Transform.scale(
          scale: value,
          child: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [
                CosmicColors.lavenderGlow,
                CosmicColors.goldenAmber,
              ],
            ).createShader(bounds),
            child: const Icon(
              Icons.radio,
              color: Colors.white,
              size: 44,
            ),
          ),
        ),
      );

  Widget _buildNowPlayingInfo(BuildContext context) {
    final song = controller.currentRadioSong!;
    final songTitle = _formatSongTitle(song.songName);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          width: 85.w,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                CosmicColors.royalPurple.withValues(alpha: 0.6),
                CosmicColors.deepPurple.withValues(alpha: 0.4),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: CosmicColors.lavenderGlow.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: CosmicColors.vibrantPurple.withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              // Now Playing badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      CosmicColors.vibrantPurple,
                      CosmicColors.royalPurple,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: CosmicColors.vibrantPurple.withValues(alpha: 0.4),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildEqualizerBars(),
                    const SizedBox(width: 8),
                    const Text(
                      'NOW PLAYING',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 2.h),
              // Song title with gradient text effect
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Colors.white, CosmicColors.lavenderGlow],
                ).createShader(bounds),
                child: Text(
                  songTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(height: 1.h),
              // Artist name
              Text(
                song.artist,
                style: TextStyle(
                  color: CosmicColors.goldenAmber.withValues(alpha: 0.9),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              if (song.albumName != null && song.albumName!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  song.albumName!,
                  style: TextStyle(
                    color: CosmicColors.lavenderGlow.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Animated equalizer bars for "Now Playing" badge
  Widget _buildEqualizerBars() => SizedBox(
        width: 16,
        height: 12,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(3, (index) {
            return TweenAnimationBuilder<double>(
              tween: Tween<double>(
                begin: 0.3,
                end: index == 1 ? 1.0 : 0.7,
              ),
              duration: Duration(milliseconds: 400 + (index * 100)),
              curve: Curves.easeInOut,
              builder: (context, value, child) => Container(
                width: 3,
                height: 12 * value,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
      );

  Widget _buildPlayerControls(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  CosmicColors.royalPurple.withValues(alpha: 0.5),
                  CosmicColors.deepPurple.withValues(alpha: 0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(
                color: CosmicColors.lavenderGlow.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildControlButton(
                  icon: Icons.skip_previous_rounded,
                  onPressed: () => controller.previous(),
                ),
                SizedBox(width: 4.w),
                // Play/Pause button with glow
                Container(
                  height: 18.w,
                  width: 18.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        CosmicColors.vibrantPurple,
                        CosmicColors.royalPurple,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: CosmicColors.vibrantPurple.withValues(alpha: 0.5),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: controller.playerIcon(size: 36),
                ),
                SizedBox(width: 4.w),
                _buildControlButton(
                  icon: Icons.skip_next_rounded,
                  onPressed: () => controller.next(),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) =>
      Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(30),
          splashColor: CosmicColors.lavenderGlow.withValues(alpha: 0.2),
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Icon(
              icon,
              color: CosmicColors.lavenderGlow,
              size: 32,
            ),
          ),
        ),
      );

  String _formatSongTitle(String name) {
    if (name.length < 3) {
      return name;
    }
    final parts = name.substring(3).split('.');
    return parts.isNotEmpty ? parts[0] : name;
  }
}
