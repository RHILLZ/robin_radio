import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../modules/player/player_controller.dart';

class PlayerControlsWidget extends GetWidget<PlayerController> {
  const PlayerControlsWidget({
    super.key,
    this.iconSize = 24,
    this.iconColor = Colors.white,
    this.showPrevious = true,
    this.compactMode = false,
  });

  final double iconSize;
  final Color iconColor;
  final bool showPrevious;
  final bool compactMode;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Previous button (only in album mode)
            if (showPrevious && controller.playerMode == PlayerMode.album)
              IconButton(
                icon: Icon(
                  Icons.skip_previous,
                  color: iconColor,
                ),
                onPressed: controller.previous,
                iconSize: iconSize,
                tooltip: 'Previous',
              ),

            // Play/pause button
            Obx(
              () => controller.playerIcon(
                size: compactMode ? iconSize * 1.5 : 40,
              ),
            ),

            // Next button
            IconButton(
              icon: Icon(
                Icons.skip_next,
                color: iconColor,
              ),
              onPressed: controller.next,
              iconSize: iconSize,
              tooltip: 'Next',
            ),
          ],
        ),
      );
}
