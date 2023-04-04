// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:miniplayer/miniplayer.dart';
import 'package:robin_radio/data/models/album.dart';
import 'package:robin_radio/global/trackItem.dart';
import 'package:robin_radio/modules/app/app_controller.dart';
import 'package:robin_radio/modules/player/player_controller.dart';
import 'package:sizer/sizer.dart';

class TrackListView extends GetView<AppController> {
  const TrackListView({super.key, required Album album}) : _album = album;

  final Album _album;

  @override
  Widget build(BuildContext context) {
    final playerController = Get.find<PlayerController>();
    return Container(
      constraints: BoxConstraints(maxHeight: 40.h, minHeight: 40.h),
      color: const Color(0XFF6C30C4),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.max,
              children: [
                Text(_album.albumName, style: const TextStyle(fontSize: 20)),
                const SizedBox(
                  width: 5,
                ),
                const Icon(Icons.flip_to_back, color: Colors.white, size: 35),
              ],
            ),
          ),
          SizedBox(height: 1.h),
          Expanded(
            child: ListView.builder(
                itemCount: _album.tracks.length,
                itemBuilder: ((context, index) => GestureDetector(
                    onTap: () {
                      playerController.tracks = _album.tracks;
                      playerController.trackIndex = index;
                      playerController.song = _album.tracks[index];
                      playerController.coverURL = _album.albumCover;
                      controller.miniPlayerController
                          .animateToHeight(state: PanelState.MAX);
                      if (Get.isBottomSheetOpen == true) {
                        Get.back();
                      }
                      Future.delayed(const Duration(seconds: 1),
                          () => playerController.playTrack());
                    },
                    child: TrackListItem(song: _album.tracks[index])))),
          ),
        ],
      ),
    );
  }
}
