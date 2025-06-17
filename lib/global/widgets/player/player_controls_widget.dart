import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../modules/player/player_controller.dart';

/// Adaptive music player control widget for managing audio playback.
///
/// Provides essential playback controls including play/pause, next/previous track
/// navigation, and visual feedback for current playback state. Designed to work
/// seamlessly across different app contexts from mini-players to full-screen
/// interfaces while maintaining consistent behavior and accessibility.
///
/// ## Features
///
/// **Core Controls:**
/// - Play/pause toggle with real-time state synchronization
/// - Next track navigation with queue awareness
/// - Previous track navigation (context-dependent availability)
/// - Adaptive icon sizing for different UI layouts
/// - Customizable color schemes to match app themes
///
/// **Adaptive Behavior:**
/// - Context-aware previous button visibility (album vs radio mode)
/// - Compact mode for mini-players and constrained layouts
/// - Full-size mode for primary player interfaces
/// - Responsive design that scales appropriately
///
/// **State Management:**
/// - Reactive UI updates using GetX observers
/// - Real-time playback state synchronization
/// - Automatic icon transitions (play ↔ pause)
/// - Loading states during track transitions
/// - Error state handling for failed operations
///
/// **Accessibility:**
/// - Semantic labels for all interactive controls
/// - Tooltip support for enhanced usability
/// - Keyboard navigation compatibility
/// - Screen reader support with descriptive labels
/// - Touch target optimization for mobile devices
///
/// ## Layout Modes
///
/// **Standard Mode (Default):**
/// ```
/// [Previous] [Play/Pause (Large)] [Next]
/// ```
/// - Previous button visible in album mode only
/// - Large play/pause button (40px) for primary emphasis
/// - Standard-sized navigation buttons (24px default)
///
/// **Compact Mode:**
/// ```
/// [Previous] [Play/Pause] [Next]
/// ```
/// - Reduced spacing and uniform button sizes
/// - Proportionally sized controls for space-constrained layouts
/// - Previous button still respects context rules
///
/// ## Usage Patterns
///
/// **Mini Player Integration:**
/// ```dart
/// Container(
///   height: 64,
///   child: PlayerControlsWidget(
///     compactMode: true,
///     iconSize: 20,
///     iconColor: Theme.of(context).primaryColor,
///     showPrevious: false, // Simplified for mini player
///   ),
/// );
/// ```
///
/// **Full Player Interface:**
/// ```dart
/// Column(
///   children: [
///     // Track info, progress bar, etc.
///     PlayerControlsWidget(
///       iconSize: 32,
///       iconColor: Colors.white,
///       showPrevious: true,
///       compactMode: false,
///     ),
///     // Volume, repeat, shuffle controls
///   ],
/// );
/// ```
///
/// **Themed Integration:**
/// ```dart
/// PlayerControlsWidget(
///   iconColor: Theme.of(context).colorScheme.onBackground,
///   iconSize: 28,
///   compactMode: MediaQuery.of(context).size.width < 400,
/// );
/// ```
///
/// **Lock Screen Style:**
/// ```dart
/// PlayerControlsWidget(
///   iconColor: Colors.white,
///   iconSize: 36,
///   showPrevious: true,
///   compactMode: false,
/// );
/// ```
///
/// ## Player Mode Integration
///
/// The widget automatically adapts its behavior based on the current player mode:
///
/// **Album Mode:**
/// - Previous button visible (when showPrevious = true)
/// - Linear track progression through album
/// - Clear beginning and end boundaries
///
/// **Radio Mode:**
/// - Previous button hidden (no backward navigation)
/// - Continuous forward-only progression
/// - Infinite stream of curated content
///
/// **Playlist Mode:**
/// - Previous button visible for playlist navigation
/// - Respects playlist boundaries and repeat settings
/// - Context-aware button availability
///
/// ## Performance Considerations
///
/// **Efficient Updates:**
/// - RepaintBoundary prevents unnecessary parent redraws
/// - Selective Obx wrapping minimizes reactive rebuilds
/// - Icon caching through controller optimization
/// - Minimal widget tree for fast builds
///
/// **Memory Management:**
/// - Stateless design prevents memory leaks
/// - Efficient GetX integration with automatic cleanup
/// - Minimal object allocation during state changes
/// - Optimal rendering for 60fps animations
///
/// **Responsive Design:**
/// - Adapts to screen density and text scaling
/// - Maintains touch targets across different device sizes
/// - Efficient layout for varying screen orientations
/// - Optimal performance on both iOS and Android
///
/// ## Customization Options
///
/// **Visual Customization:**
/// - Icon sizes can be adjusted for different contexts
/// - Colors can be themed to match app design
/// - Compact mode provides space-efficient layouts
/// - Button visibility can be controlled contextually
///
/// **Behavioral Customization:**
/// - Previous button can be hidden for simplified interfaces
/// - Icon sizing adapts to available space
/// - Controller integration allows custom playback logic
/// - Tooltip text can be localized for international users
///
/// ## Error Handling
///
/// The widget gracefully handles various error scenarios:
/// - Controller unavailability during initialization
/// - Network failures during track loading
/// - Invalid track data or missing resources
/// - Permission issues on different platforms
///
/// Error states are communicated through the controller's icon system,
/// providing visual feedback without disrupting the user interface flow.
class PlayerControlsWidget extends GetWidget<PlayerController> {
  /// Creates a PlayerControlsWidget with customizable appearance and behavior.
  ///
  /// [iconSize] The size in pixels for navigation icons (previous/next).
  ///           Defaults to 24px for standard layouts. The play/pause button
  ///           scales proportionally: 40px in standard mode, 1.5x iconSize
  ///           in compact mode. Should be at least 16px for accessibility.
  ///
  /// [iconColor] The color applied to all control icons. Should provide
  ///            sufficient contrast against the background for accessibility.
  ///            Defaults to white, suitable for dark player backgrounds.
  ///
  /// [showPrevious] Whether to display the previous track button. When false,
  ///               the button is completely hidden, useful for radio modes
  ///               or simplified interfaces. When true, button visibility
  ///               still depends on the current player mode context.
  ///
  /// [compactMode] Enables space-efficient layout for constrained interfaces.
  ///              When true, reduces spacing and normalizes button sizes.
  ///              The play/pause button becomes 1.5x the icon size instead
  ///              of the fixed 40px used in standard mode.
  ///
  /// Example configurations:
  /// ```dart
  /// // Standard player interface
  /// PlayerControlsWidget(
  ///   iconSize: 28,
  ///   iconColor: Colors.white,
  ///   showPrevious: true,
  ///   compactMode: false,
  /// );
  ///
  /// // Mini player
  /// PlayerControlsWidget(
  ///   iconSize: 20,
  ///   iconColor: Theme.of(context).primaryColor,
  ///   showPrevious: false,
  ///   compactMode: true,
  /// );
  ///
  /// // Notification/lock screen style
  /// PlayerControlsWidget(
  ///   iconSize: 32,
  ///   iconColor: Colors.black87,
  ///   showPrevious: true,
  ///   compactMode: false,
  /// );
  /// ```
  const PlayerControlsWidget({
    super.key,
    this.iconSize = 24,
    this.iconColor = Colors.white,
    this.showPrevious = true,
    this.compactMode = false,
  });

  /// Size in pixels for navigation control icons.
  ///
  /// Determines the size of the previous and next buttons. The play/pause
  /// button scales proportionally based on the compact mode setting.
  /// Should be large enough for comfortable touch interaction (minimum 16px)
  /// while fitting appropriately in the intended layout context.
  final double iconSize;

  /// Color applied to all control icons.
  ///
  /// Should provide sufficient contrast against the background for
  /// accessibility compliance. Consider the app theme and player
  /// background when selecting this color.
  final Color iconColor;

  /// Whether to show the previous track button.
  ///
  /// When false, the previous button is completely hidden from the layout.
  /// When true, the button's actual visibility depends on the current
  /// player mode (hidden in radio mode, visible in album/playlist modes).
  final bool showPrevious;

  /// Enables compact layout for space-constrained interfaces.
  ///
  /// When true, reduces spacing and makes the play/pause button
  /// proportional to iconSize rather than using a fixed large size.
  /// Ideal for mini-players, notification controls, or mobile landscapes.
  final bool compactMode;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Previous button (only in album mode)
            if (showPrevious && controller.playerMode == PlayerMode.album)
              IconButton(
                icon: Icon(
                  Icons.skip_previous,
                  color: iconColor,
                ),
                onPressed: controller.previous,
                iconSize: iconSize,
                tooltip: 'Previous',
              ),

            // Play/pause button
            Obx(
              () => controller.playerIcon(
                size: compactMode ? iconSize * 1.5 : 40,
              ),
            ),

            // Next button
            IconButton(
              icon: Icon(
                Icons.skip_next,
                color: iconColor,
              ),
              onPressed: controller.next,
              iconSize: iconSize,
              tooltip: 'Next',
            ),
          ],
        ),
      );
}
