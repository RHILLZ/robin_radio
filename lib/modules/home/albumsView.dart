import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:robin_radio/global/albumCover.dart';
import 'package:robin_radio/modules/app/app_controller.dart';
import 'package:robin_radio/modules/home/trackListView.dart';
import 'package:robin_radio/modules/player/player_controller.dart';
import 'package:sizer/sizer.dart';

class AlbumsView extends GetView<AppController> {
  const AlbumsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ElevatedButton(
        //     onPressed: () => controller.getMusic(),
        //     child: const Text('Get Music')),
        Expanded(
            child: Obx(() => ListView.separated(
                separatorBuilder: (context, index) => SizedBox(
                    // height: 2.h,
                    ),
                itemCount: controller.robinsMusic.length,
                itemBuilder: (context, index) => Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            key: Key(index.toString()),
                            onTap: () => controller.openTrackList(
                              controller.robinsMusic[index],
                            ),
                            child: AlbumCover(
                                imageUrl:
                                    controller.robinsMusic[index].albumCover),
                          ),
                          // Text(controller.robinsMusic[index].albumName),
                        ],
                      ),
                    ))))
      ],
    );
  }
}
