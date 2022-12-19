import 'package:get/get.dart';
import 'package:robin_radio/modules/app/app_view.dart';
import 'package:robin_radio/modules/app/main_bindings.dart';
import 'package:robin_radio/modules/home/albumsView.dart';
import 'package:robin_radio/modules/home/mainView.dart';
import 'package:robin_radio/modules/home/radioView.dart';

part 'routes.dart';

class Views {
  Views._();

  static const mainView = Routes.mainViewRoute;

  static final routes = [
    GetPage<AlbumsView>(
      name: Routes.albumsViewRoute,
      page: AlbumsView.new,
    ),
    GetPage<RadioView>(
      name: Routes.radioViewRoute,
      page: RadioView.new,
    ),
    GetPage<MainView>(
      name: Routes.mainViewRoute,
      page: MainView.new,
    ),
    GetPage<AppView>(
        name: Routes.appViewRoute, page: AppView.new, binding: MainBindings())
  ];
}
