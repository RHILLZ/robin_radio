import 'package:get/get.dart';

import '../player/player_controller.dart';
import 'app_controller.dart';

class MainBindings implements Bindings {
  @override
  void dependencies() {
    _injectDependencies();
    _injectServices();
  }

  void _injectDependencies() {
    Get
      ..put<AppController>(AppController())
      ..put<PlayerController>(PlayerController());
  }

  void _injectServices() {}
}
