// ignore_for_file: file_names

import 'package:flip_card/flip_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:robin_radio/global/albumCover.dart';
import 'package:robin_radio/modules/app/app_controller.dart';
import 'package:robin_radio/modules/home/trackListView.dart';
import 'package:sizer/sizer.dart';

class AlbumsView extends StatelessWidget {
  const AlbumsView({super.key});

  // @override
  @override
  Widget build(BuildContext context) {
    return GetX<AppController>(
      init: Get.find<AppController>(),
      builder: (controller) => controller.isMusicRetrieved
          ? Scaffold(
              body: Column(
              children: [
                // ElevatedButton(
                //     onPressed: () => controller.getMusic(),
                //     child: const Text('Get Music')),
                Expanded(
                    child: Obx(() => ListView.separated(
                        separatorBuilder: (context, index) => SizedBox(
                              height: 2.h,
                            ),
                        itemCount: controller.robinsMusic.length,
                        itemBuilder: (context, index) => Center(
                              child: Column(
                                children: [
                                  FlipCard(
                                      fill: Fill.fillBack,
                                      direction: FlipDirection.VERTICAL,
                                      front: AlbumCover(
                                        imageUrl: controller
                                            .robinsMusic[index].albumCover,
                                        albumName: controller
                                            .robinsMusic[index].albumName,
                                      ),
                                      back: TrackListView(
                                          album: controller.robinsMusic[index]))

                                  // Text(controller.robinsMusic[index].albumName),
                                ],
                              ),
                            ))))
              ],
            ))
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                spinkit(context),
                SizedBox(height: 2.h),
                const Text('Fetching Robins Music...',
                    style: TextStyle(fontSize: 20, color: Colors.deepPurple)),
                const Text(
                  'Please wait...',
                  style: TextStyle(fontSize: 20, color: Colors.deepPurple),
                ),
                SizedBox(height: 2.h),
                SizedBox(
                  width: 80.w,
                  child: LinearProgressIndicator(
                      value: controller.robinsMusic.length.toDouble() / 101,
                      backgroundColor: Colors.grey,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.deepPurpleAccent)),
                ),
              ],
            ),
    );
  }

  Widget spinkit(context) => const SpinKitChasingDots(
        color: Colors.deepPurpleAccent,
        size: 50.0,
      );
}
