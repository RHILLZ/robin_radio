// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:robin_radio/global/albumCover.dart';
import 'package:robin_radio/modules/app/app_controller.dart';

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
                separatorBuilder: (context, index) => const SizedBox(
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
                                  controller.robinsMusic[index].albumCover,
                              albumName:
                                  controller.robinsMusic[index].albumName,
                            ),
                          ),
                          // Text(controller.robinsMusic[index].albumName),
                        ],
                      ),
                    ))))
      ],
    );
  }
}
