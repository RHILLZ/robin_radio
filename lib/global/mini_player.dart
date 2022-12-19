import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:robin_radio/modules/player/player_controller.dart';
import 'package:sizer/sizer.dart';

class MiniPlayerWidget extends GetWidget<PlayerController> {
  const MiniPlayerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 25.w,
                  height: 12.h - 6.0,
                  child: albumCover(),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                            child: !controller.tracks.isEmpty
                                ? Text(
                                    controller
                                        .tracks[controller.trackIndex].songName
                                        .substring(3)
                                        .split('.')[0],
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : const Text('')),
                        SizedBox(
                          height: 1.h,
                        ),
                        Flexible(
                            child: !controller.tracks.isEmpty
                                ? Text(
                                    'by: ${controller.tracks[controller.trackIndex].artist}',
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : const Text('')),
                      ],
                    ),
                  ),
                ),
                controller.playerIcon(50, null),
                IconButton(
                    onPressed: () => controller.closePlayer(),
                    iconSize: 40,
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                    )),
                SizedBox(
                  width: 4.w,
                )
              ],
            ),
            LinearProgressIndicator(
                value: controller.linearProgressValue(),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.grey)),
          ],
        ));
  }

  albumCover() => controller.coverURL != null
      ? Image.network(
          controller.coverURL!,
          fit: BoxFit.cover,
        )
      : Image.asset(
          'assets/logo/rr-logo.png',
          fit: BoxFit.cover,
        );
}
