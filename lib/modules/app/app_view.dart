import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:miniplayer/miniplayer.dart';
import 'package:sizer/sizer.dart';

import '../../data/services/image_preload_service.dart';
import '../../global/mini_player.dart';
import '../../global/widgets/performance_dashboard.dart';
import '../home/mainView.dart';
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

  @override
  Widget build(BuildContext context) {
    final playerController = Get.find<PlayerController>();

    // Preload essential assets when app is not loading
    if (!controller.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ImagePreloadService.instance.preloadEssentialAssets(context);
      });
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Obx(
        () => Stack(
          children: [
            // Main content
            const MainView(),

            // Player
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

            // Loading overlay - only shown when loading AND no cached content
            if (controller.shouldShowLoadingScreen)
              AnimatedOpacity(
                opacity: controller.shouldShowLoadingScreen ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: ColoredBox(
                  color: Colors.black87,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.primary,
                          value: controller.loadingProgress > 0
                              ? controller.loadingProgress
                              : null,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          controller.loadingProgress > 0
                              ? 'Loading Music... ${(controller.loadingProgress * 100).toInt()}%'
                              : 'Loading Music...',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          controller.loadingStatusMessage,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 2.h),
                        SizedBox(
                          width: 80.w,
                          child: LinearProgressIndicator(
                            value: controller.loadingProgress > 0
                                ? controller.loadingProgress
                                : null,
                            backgroundColor: Colors.white24,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
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
}
