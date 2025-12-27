import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:miniplayer/miniplayer.dart';
import 'package:sizer/sizer.dart';

import '../../data/services/image_preload_service.dart';
import '../../global/cosmic_theme.dart';
import '../../global/mini_player.dart';
import '../../global/widgets/performance_dashboard.dart';
import '../home/main_view.dart';
import '../player/player_controller.dart';
import '../player/player_view.dart';
import 'app_controller.dart';

/// Main application view that provides the core UI structure for Robin Radio.
///
/// This view serves as the root layout container that orchestrates the main
/// application components including the music player, mini player, and loading states.
/// It integrates with the miniplayer widget to provide a seamless music playback
/// experience with collapsible player controls.
///
/// Features:
/// - Responsive miniplayer that transitions between collapsed and expanded states
/// - Loading overlay with progress indicators during music library initialization
/// - Performance monitoring dashboard for debugging
/// - Essential asset preloading for improved user experience
/// - Safe area handling for different device configurations
class AppView extends GetView<AppController> {
  /// Creates an instance of [AppView].
  ///
  /// The [key] parameter is optional and follows standard Flutter widget conventions.
  const AppView({super.key});

  /// Formats a duration into a human-readable string
  String _formatDuration(Duration duration) {
    if (duration.inMinutes > 0) {
      final minutes = duration.inMinutes;
      final seconds = duration.inSeconds % 60;
      return '${minutes}m ${seconds}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  @override
  Widget build(BuildContext context) {
    final playerController = Get.find<PlayerController>();

    // Preload essential assets only when content is ready
    if (controller.isContentReady) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ImagePreloadService.instance.preloadEssentialAssets(context);
      });
    }

    return Scaffold(
      backgroundColor: CosmicColors.voidBlack,
      body: Obx(
        () => Stack(
          children: [
            // Main content
            const MainView(),

            // Player - only show when not in loading screen
            if (!controller.shouldShowLoadingScreen)
              Offstage(
                offstage: (playerController.tracks.isEmpty) ||
                    playerController.hidePlayerInRadioView,
                child: Miniplayer(
                controller: controller.miniPlayerController,
                minHeight: 12.h,
                maxHeight: MediaQuery.of(context).size.height,
                elevation: 4,
                builder: (height, percentage) {
                  // Show mini player when collapsed
                  if (height <= 12.h + 50.0) {
                    return const MiniPlayerWidget();
                  }
                  // Show full player when expanded
                  else {
                    return const PlayerView();
                  }
                },
              ),
            ),

            // Performance Dashboard (debug mode only)
            const PerformanceDashboard(),

            // Cosmic loading overlay with glassmorphism
            if (controller.shouldShowLoadingScreen)
              AbsorbPointer(
                child: AnimatedOpacity(
                  opacity: controller.shouldShowLoadingScreen ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      gradient: CosmicColors.cosmicGradient,
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // App logo with glow effect
                            DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: CosmicColors.neonGlow(intensity: 0.6),
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/logo/rr-logo.webp',
                                  width: 20.w,
                                  height: 20.w,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            SizedBox(height: 4.h),
                            // Cosmic progress indicator with neon glow
                            DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: CosmicColors.neonGlow(intensity: 0.4),
                              ),
                              child: CircularProgressIndicator(
                                color: CosmicColors.vibrantPurple,
                                backgroundColor: CosmicColors.royalPurple
                                    .withValues(alpha: 0.3),
                                value: controller.loadingProgress > 0
                                    ? controller.loadingProgress
                                    : null,
                                strokeWidth: 3,
                              ),
                            ),
                            SizedBox(height: 3.h),
                            // Main loading text with lavender glow
                            Text(
                              controller.loadingProgress > 0
                                  ? 'Loading Music... ${(controller.loadingProgress * 100).toInt()}%'
                                  : 'Loading Music...',
                              style: TextStyle(
                                color: CosmicColors.lavenderGlow,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                                shadows: [
                                  Shadow(
                                    color: CosmicColors.vibrantPurple
                                        .withValues(alpha: 0.8),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 1.h),
                            // Status message
                            Text(
                              controller.loadingStatusMessage,
                              style: TextStyle(
                                color: CosmicColors.lavenderGlow
                                    .withValues(alpha: 0.7),
                                fontSize: 14,
                                letterSpacing: 0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            // Time information with golden accent
                            if (controller.elapsedTime != null ||
                                controller.estimatedTimeRemaining != null)
                              Padding(
                                padding: EdgeInsets.only(top: 1.5.h),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (controller.elapsedTime != null)
                                      Text(
                                        'Elapsed: ${_formatDuration(controller.elapsedTime!)}',
                                        style: TextStyle(
                                          color: CosmicColors.goldenAmber
                                              .withValues(alpha: 0.8),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    if (controller.elapsedTime != null &&
                                        controller.estimatedTimeRemaining !=
                                            null)
                                      const Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 8,),
                                        child: Text(
                                          '•',
                                          style: TextStyle(
                                            color: CosmicColors.vibrantPurple,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    if (controller.estimatedTimeRemaining !=
                                        null)
                                      Text(
                                        'Remaining: ${_formatDuration(controller.estimatedTimeRemaining!)}',
                                        style: TextStyle(
                                          color: CosmicColors.goldenAmber
                                              .withValues(alpha: 0.8),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            SizedBox(height: 3.h),
                            // Cosmic progress bar with glow
                            Container(
                              width: 70.w,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  BoxShadow(
                                    color: CosmicColors.vibrantPurple
                                        .withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: controller.loadingProgress > 0
                                      ? controller.loadingProgress
                                      : null,
                                  backgroundColor: CosmicColors.royalPurple
                                      .withValues(alpha: 0.4),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                    CosmicColors.vibrantPurple,
                                  ),
                                  minHeight: 6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
