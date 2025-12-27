// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';

import '../../global/cosmic_theme.dart';
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
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: CosmicColors.cosmicGradient,
        ),
        child: NestedScrollView(
          floatHeaderSlivers: true,
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              flexibleSpace: ClipRRect(
                child: BackdropFilter(
                  filter: CosmicGlass.blur,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: CosmicColors.cardGradient(opacity: 0.7),
                      border: Border(
                        bottom: BorderSide(
                          color: CosmicColors.lavenderGlow.withValues(alpha: 0.15),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              actions: [
                // Play/pause button with glow effect
                Obx(() {
                  if (playerController.tracks.isNotEmpty ||
                      playerController.playerMode == PlayerMode.radio) {
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: CosmicColors.vibrantPurple.withValues(alpha: 0.4),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: playerController.playerIcon(size: 30),
                    );
                  }
                  return const SizedBox.shrink();
                }),

                // Menu button with cosmic styling
                Theme(
                  data: Theme.of(context).copyWith(
                    popupMenuTheme: PopupMenuThemeData(
                      color: CosmicColors.royalPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: CosmicColors.lavenderGlow.withValues(alpha: 0.2),
                        ),
                      ),
                      shadowColor: CosmicColors.vibrantPurple.withValues(alpha: 0.5),
                      elevation: 12,
                    ),
                  ),
                  child: PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: CosmicColors.lavenderGlow.withValues(alpha: 0.9),
                    ),
                    onSelected: (value) {
                      if (value == 'refresh') {
                        Get.find<AppController>().refreshMusic();
                      } else if (value == 'close_player') {
                        playerController.closePlayer();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem<String>(
                        value: 'refresh',
                        child: Row(
                          children: [
                            Icon(
                              Icons.refresh,
                              color: CosmicColors.goldenAmber,
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Refresh Music',
                              style: TextStyle(
                                color: CosmicColors.lavenderGlow,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (playerController.tracks.isNotEmpty ||
                          playerController.playerMode == PlayerMode.radio)
                        const PopupMenuItem<String>(
                          value: 'close_player',
                          child: Row(
                            children: [
                              Icon(
                                Icons.close,
                                color: CosmicColors.goldenAmber,
                                size: 20,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Close Player',
                                style: TextStyle(
                                  color: CosmicColors.lavenderGlow,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              floating: true,
              snap: true,
              expandedHeight: 5.h,
              title: const AppTitle(),
              bottom: TabBar(
                indicatorWeight: 3,
                indicatorColor: CosmicColors.goldenAmber,
                indicatorSize: TabBarIndicatorSize.label,
                labelColor: Colors.white,
                unselectedLabelColor: CosmicColors.lavenderGlow.withValues(alpha: 0.5),
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1,
                ),
                dividerColor: Colors.transparent,
                splashFactory: InkSparkle.splashFactory,
                overlayColor: WidgetStateProperty.all(
                  CosmicColors.vibrantPurple.withValues(alpha: 0.2),
                ),
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
      ),
    );
  }
}
