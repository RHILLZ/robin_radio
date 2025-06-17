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

class AppView extends GetView<AppController> {
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

            // Loading overlay
            if (controller.isLoading)
              ColoredBox(
                color: Colors.black54,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.primary,
                        value: controller.loadingProgress,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'Loading Music... ${(controller.loadingProgress * 100).toInt()}%',
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
                          value: controller.loadingProgress,
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
          ],
        ),
      ),
    );
  }
}
