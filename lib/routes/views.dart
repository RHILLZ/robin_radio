import 'package:get/get.dart';
import '../modules/app/app_view.dart';
import '../modules/app/main_bindings.dart';
import '../modules/home/albums_view.dart';
import '../modules/home/main_view.dart';
import '../modules/home/radio_view.dart';

part 'routes.dart';

/// Application view configuration and route definitions for GetX navigation.
///
/// Manages the mapping between route names and their corresponding page widgets,
/// including dependency injection setup through bindings. Provides a centralized
/// location for all navigation configuration in the app.
class Views {
  Views._();

  /// Default route path for the main application view.
  static const mainView = Routes.mainViewRoute;

  /// List of all GetX page routes configured for the application.
  ///
  /// Each route maps a path to its corresponding widget and optional bindings
  /// for dependency injection. Used by GetMaterialApp to handle navigation.
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
      name: Routes.appViewRoute,
      page: AppView.new,
      binding: MainBindings(),
    ),
  ];
}
