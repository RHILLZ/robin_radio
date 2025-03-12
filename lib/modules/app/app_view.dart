import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:miniplayer/miniplayer.dart';
import 'package:robin_radio/global/mini_player.dart';
import 'package:robin_radio/modules/app/app_controller.dart';
import 'package:robin_radio/modules/home/mainView.dart';
import 'package:robin_radio/modules/player/player_controller.dart';
import 'package:robin_radio/modules/player/player_view.dart';
import 'package:sizer/sizer.dart';

class AppView extends GetView<AppController> {
  const AppView({super.key});

  @override
  Widget build(BuildContext context) {
    final playerController = Get.find<PlayerController>();

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
                  curve: Curves.easeOut,
                  duration: const Duration(milliseconds: 300),
                  builder: (height, percentage) {
                    // Show mini player when collapsed
                    if (height <= 12.h + 50.0) {
                      return const MiniPlayerWidget();
                    }
                    // Show full player when expanded
                    else {
                      return const PlayerView();
                    }
                  }),
            ),

            // Loading overlay
            if (controller.isLoading)
              Container(
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
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        controller.loadingStatusMessage,
                        style: TextStyle(
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
