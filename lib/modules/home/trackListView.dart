import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:miniplayer/miniplayer.dart';
import 'package:robin_radio/data/models/album.dart';
import 'package:robin_radio/global/trackItem.dart';
import 'package:robin_radio/modules/app/app_controller.dart';
import 'package:robin_radio/modules/player/player_controller.dart';

class TrackListView extends GetView<AppController> {
  const TrackListView({super.key, required Album album}) : _album = album;

  final Album _album;

  @override
  Widget build(BuildContext context) {
    final playerController = Get.find<PlayerController>();
    return DraggableScrollableSheet(
      initialChildSize: .80,
      minChildSize: 0.6,
      maxChildSize: .9,
      builder: (_, scontroller) => Container(
        color: const Color(0XFF6C30C4),
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
                  Future.delayed(
                      Duration(seconds: 1), () => playerController.playTrack());
                },
                child: TrackListItem(song: _album.tracks[index])))),
      ),
    );
  }
}
