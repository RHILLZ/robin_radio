// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';

import '../../global/widgets/widgets.dart';
import '../app/app_controller.dart';
import '../player/player_controller.dart';
import 'albums_view.dart';
import 'radio_view.dart';

/// Primary navigation view for Robin Radio.
///
/// This view provides the main navigation structure for the application using
/// a tabbed interface. It serves as the container for the radio and albums
/// sections, featuring a responsive app bar with integrated player controls
/// and navigation options.
///
/// Features:
/// - Tabbed navigation between Radio and Albums sections
/// - Floating app bar with snap and pin behavior
/// - Integrated player controls in the app bar
/// - Context-aware menu options based on player state
/// - Responsive design that adapts to different screen sizes
/// - Nested scroll view for smooth scrolling experience
class MainView extends StatelessWidget {
  /// Creates an instance of [MainView].
  ///
  /// The [key] parameter is optional and follows standard Flutter widget conventions.
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
                    child: IconTextRow(
                      icon: Icons.refresh,
                      text: 'Refresh Music',
                    ),
                  ),
                  if (playerController.tracks.isNotEmpty ||
                      playerController.playerMode == PlayerMode.radio)
                    const PopupMenuItem(
                      value: 'close_player',
                      child: IconTextRow(
                        icon: Icons.close,
                        text: 'Close Player',
                      ),
                    ),
                ],
              ),
            ],
            floating: true,
            snap: true,
            expandedHeight: 5.h,
            title: const AppTitle(),
            bottom: TabBar(
              indicatorWeight: 3,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor:
                  Theme.of(context).colorScheme.onSurface.withAlpha(100),
              tabs: const [
                RadioTab(),
                AlbumsTab(),
              ],
            ),
          ),
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
