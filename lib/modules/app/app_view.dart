import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:miniplayer/miniplayer.dart';
import 'package:robin_radio/global/mini_player.dart';
import 'package:robin_radio/modules/app/app_controller.dart';
import 'package:robin_radio/modules/home/mainView.dart';
import 'package:robin_radio/modules/player/player_controller.dart';
import 'package:robin_radio/modules/player/player_view.dart';
import 'package:sizer/sizer.dart';

class AppView extends GetView<AppController> {
  const AppView({super.key});

  @override
  Widget build(BuildContext context) {
    final playerController = Get.find<PlayerController>();
    return Scaffold(
        backgroundColor: Colors.grey.shade200,
        // bottomNavigationBar: const NavBarCirle(),
        body: Obx(
          () => Stack(
            children: [
              const MainView(),
              Offstage(
                offstage: playerController.tracks.isEmpty,
                child: Miniplayer(
                    controller: controller.miniPlayerController,
                    minHeight: 12.h,
                    maxHeight: MediaQuery.of(context).size.height,
                    builder: (height, percentage) {
                      if (height <= 12.h + 50.0) {
                        return Container(
                            decoration:
                                const BoxDecoration(color: Color(0XFF6C30C4)),
                            child: const MiniPlayerWidget());
                      } else {
                        return const PlayerView();
                      }
                    }),
              ),
            ],
          ),
        ));
  }
}
