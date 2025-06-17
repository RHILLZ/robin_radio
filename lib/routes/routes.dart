part of 'views.dart';

/// Application route definitions for navigation between screens.
///
/// Contains all route constants used throughout the app for type-safe navigation.
/// Routes are used with GetX navigation system to manage page transitions
/// and maintain navigation state.
abstract class Routes {
  Routes._();

  /// Route to the albums listing view showing all available albums.
  static const albumsViewRoute = '/albums_view';

  /// Route to the track listing view displaying songs for a specific album.
  static const trackListViewRoute = '/tracklist_view';

  /// Route to the radio streaming view for live audio playback.
  static const radioViewRoute = '/radio_view';

  /// Route to the main view containing the primary navigation interface.
  static const mainViewRoute = '/main_view';

  /// Route to the player view showing detailed playback controls and information.
  static const playerView = '/player_view';

  /// Route to the main app container view managing the overall app layout.
  static const appViewRoute = '/app_view';
}
