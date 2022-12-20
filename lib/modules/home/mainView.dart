import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:get/get.dart';
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
            headerSliverBuilder: ((context, innerBoxIsScrolled) => [
                  SliverAppBar(
                    actions: [
                      // Obx(() => playerController.playerIcon(30, null)),
                      IconButton(
                          onPressed: () => playerController.closePlayer(),
                          icon: const Icon(Icons.close))
                    ],
                    floating: true,
                    snap: true,
                    expandedHeight: 5.h,
                    title: const Text('Robin Radio'),
                    bottom: const TabBar(
                        indicatorWeight: 7.0,
                        indicatorColor: Colors.white,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.grey,
                        tabs: [Text('Radio'), Text('Albums')]),
                  )
                ]),
            body: const TabBarView(children: [RadioView(), AlbumsView()])));
  }
}
