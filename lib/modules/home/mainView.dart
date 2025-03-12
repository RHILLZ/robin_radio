// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:robin_radio/modules/app/app_controller.dart';
import 'package:robin_radio/modules/home/albumsView.dart';
import 'package:robin_radio/modules/home/radioView.dart';
import 'package:robin_radio/modules/player/player_controller.dart';
import 'package:sizer/sizer.dart';

class MainView extends StatelessWidget {
  const MainView({super.key});

  @override
  Widget build(BuildContext context) {
    final playerController = Get.find<PlayerController>();

    return DefaultTabController(
      length: 2,
      child: NestedScrollView(
        floatHeaderSlivers: true,
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            actions: [
              // Play/pause button for quick access
              Obx(() {
                if (playerController.tracks.isNotEmpty ||
                    playerController.playerMode == PlayerMode.radio) {
                  return playerController.playerIcon(size: 30);
                }
                return const SizedBox.shrink();
              }),

              // Menu button
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'refresh') {
                    Get.find<AppController>().refreshMusic();
                  } else if (value == 'close_player') {
                    playerController.closePlayer();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'refresh',
                    child: Row(
                      children: [
                        Icon(Icons.refresh),
                        SizedBox(width: 8),
                        Text('Refresh Music'),
                      ],
                    ),
                  ),
                  if (playerController.tracks.isNotEmpty ||
                      playerController.playerMode == PlayerMode.radio)
                    const PopupMenuItem(
                      value: 'close_player',
                      child: Row(
                        children: [
                          Icon(Icons.close),
                          SizedBox(width: 8),
                          Text('Close Player'),
                        ],
                      ),
                    ),
                ],
              ),
            ],
            floating: true,
            snap: true,
            expandedHeight: 5.h,
            title: const Text(
              'Robin Radio',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            bottom: TabBar(
              indicatorWeight: 3.0,
              indicatorColor: Theme.of(context).colorScheme.primary,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor:
                  Theme.of(context).colorScheme.onSurface.withAlpha(153),
              tabs: const [
                Tab(
                  icon: Icon(Icons.radio),
                  text: 'Radio',
                ),
                Tab(
                  icon: Icon(Icons.album),
                  text: 'Albums',
                ),
              ],
            ),
          )
        ],
        body: const TabBarView(
          children: [
            RadioView(),
            AlbumsView(),
          ],
        ),
      ),
    );
  }
}
