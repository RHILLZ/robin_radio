import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:get/get.dart';
import 'package:im_animations/im_animations.dart';
import 'package:robin_radio/modules/player/player_controller.dart';
import 'package:sizer/sizer.dart';

class RadioView extends GetView<PlayerController> {
  const RadioView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Container(
          color: Colors.grey[300],
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  child: Image.asset('assets/logo/rr-logo.png'),
                ),
                controller.currentRadioSong.artist.isEmpty
                    ? ColorSonar(
                        contentAreaRadius: 80,
                        child: ElevatedButton.icon(
                            style: ButtonStyle(
                                elevation: MaterialStatePropertyAll(15),
                                shadowColor: const MaterialStatePropertyAll(
                                    Colors.black),
                                shape: const MaterialStatePropertyAll<
                                    OutlinedBorder>(CircleBorder()),
                                iconSize:
                                    const MaterialStatePropertyAll<double>(60),
                                backgroundColor:
                                    const MaterialStatePropertyAll<Color>(
                                        Color(0XFF6C30C4)),
                                fixedSize: MaterialStatePropertyAll<Size>(
                                    Size(40.w, 40.w))),
                            onPressed: () => controller.playRadio(),
                            icon: const Icon(Icons.play_arrow),
                            label: const Text(
                              'Start Radio',
                              style: TextStyle(fontSize: 18),
                            )),
                      )
                    : Column(
                        children: [
                          Text(
                            '${controller.currentRadioSong.songName}'
                                .substring(3)
                                .split('.')[0],
                            style: const TextStyle(
                                color: Color(0XFF6C30C4),
                                fontSize: 20,
                                fontWeight: FontWeight.bold),
                          ),
                          SizedBox(
                            height: 2.h,
                          ),
                          Text(
                            'by: ${controller.currentRadioSong.artist}',
                            style: const TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w400),
                          ),
                          Text(
                            'album: ${controller.currentRadioSong.albumName}',
                            style: const TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w400),
                          ),
                        ],
                      ),
                Visibility(
                  visible: controller.currentRadioSong.artist.isNotEmpty,
                  child: Row(
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
                              shape: BoxShape.circle, color: Colors.grey[400]),
                          child: controller.playerIcon(
                              50, const Color(0XFF6C30C4))),
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
                ),
              ],
            ),
          ),
        ));
  }
}
