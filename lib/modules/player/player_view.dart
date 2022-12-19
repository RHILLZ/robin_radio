import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:robin_radio/modules/player/player_controller.dart';
import 'package:sizer/sizer.dart';

class PlayerView extends GetView<PlayerController> {
  const PlayerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        alignment: Alignment.center,
        color: Colors.grey[400],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          // crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            SizedBox(
              // height: 50.h,
              width: double.infinity,
              child: cover(),
            ),
            SizedBox(
              height: 2.h,
            ),
            Text(
              controller.tracks[controller.trackIndex].songName
                  .substring(3)
                  .split('.')[0],
              style: const TextStyle(
                  color: Color(0XFF6C30C4),
                  fontSize: 20,
                  fontWeight: FontWeight.w600),
            ),
            SizedBox(
              height: 1.h,
            ),
            Text(
              controller.tracks[controller.trackIndex].artist,
              style: const TextStyle(
                  color: Colors.black87, fontWeight: FontWeight.w500),
            ),
            SizedBox(
              height: 2.h,
            ),
            Slider.adaptive(
                activeColor: const Color(0XFF6C30C4),
                inactiveColor: const Color(0XFF6C30C4),
                thumbColor: const Color(0XFF6C30C4),
                value: controller.positionAsDouble,
                min: 0.0,
                max: controller.durationAsDouble + 0.1,
                onChanged: (value) => controller.seek(value)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(controller.playerPosition,
                      style: const TextStyle(color: Color(0XFF6C30C4))),
                  Text(controller.playerDuration,
                      style: const TextStyle(color: Color(0XFF6C30C4)))
                ],
              ),
            ),
            SizedBox(
              height: 10.h,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              // mainAxisSize: MainAxisSize.max,
              children: [
                IconButton(
                  alignment: Alignment.center,
                  onPressed: () => controller.previous(),
                  icon: const Icon(
                    Icons.skip_previous,
                    color: Color(0XFF6C30C4),
                  ),
                  iconSize: 50,
                ),
                Container(
                    height: 30.w,
                    width: 30.w,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle, color: Colors.grey[300]),
                    child: controller.playerIcon(50, const Color(0XFF6C30C4))),
                IconButton(
                  onPressed: () => controller.next(),
                  icon: const Icon(
                    Icons.skip_next,
                    color: Color(0XFF6C30C4),
                  ),
                  iconSize: 50,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget cover() => controller.coverURL != null
      ? Image.network(
          controller.coverURL!,
          fit: BoxFit.cover,
        )
      : Image.asset('assets/logo/rr-logo.png');
}
