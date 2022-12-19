import 'package:get/get.dart';
import 'package:robin_radio/modules/app/app_controller.dart';
import 'package:robin_radio/modules/player/player_controller.dart';

class MainBindings implements Bindings {
  @override
  void dependencies() {
    _injectDependencies();
    _injectServices();
  }

  void _injectDependencies() {
    Get
      ..lazyPut<AppController>(() => AppController())
      ..lazyPut<PlayerController>(() => PlayerController());
  }

  void _injectServices() {}
}
