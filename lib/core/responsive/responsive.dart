library;

import 'responsive.dart'
    show
        AdaptiveCard,
        AdaptiveContainer,
        AdaptiveIcon,
        AdaptiveSafeArea,
        AdaptiveSpacing,
        AdaptiveText,
        Breakpoints,
        DeviceType,
        OrientationContext,
        OrientationLayout,
        ResponsiveBuilder,
        ResponsiveContext,
        ResponsiveGrid,
        ResponsiveLayout,
        ResponsiveListGrid,
        ResponsiveOrientationLayout,
        ResponsiveScaffold,
        ResponsiveStaggeredGrid,
        ResponsiveUtils,
        ResponsiveValue,
        SafeAreaContext,
        ScreenSize;

// Adaptive widgets
export 'adaptive_widgets.dart';

/// Responsive design system for Robin Radio.
///
/// This library provides a comprehensive set of utilities and widgets
/// for creating responsive layouts that adapt to different screen sizes,
/// device types, and orientations.
///
/// ## Key Components:
///
/// ### Breakpoints and Detection
/// - [Breakpoints]: Standard breakpoint definitions
/// - [DeviceType]: Device classification enum
/// - [ScreenSize]: Screen size categories
/// - [ResponsiveUtils]: Utility functions for responsive decisions
///
/// ### Layout Builders
/// - [ResponsiveBuilder]: Core responsive layout builder
/// - [ResponsiveLayout]: Simplified device-specific layouts
/// - [ResponsiveValue]: Responsive value provider
///
/// ### Grid Layouts
/// - [ResponsiveGrid]: Adaptive grid with automatic column adjustment
/// - [ResponsiveStaggeredGrid]: Staggered grid for variable-height items
/// - [ResponsiveListGrid]: Adaptive list/grid layout switcher
///
/// ### Orientation Support
/// - [OrientationLayout]: Orientation-specific layouts
/// - [ResponsiveOrientationLayout]: Combined responsive and orientation layouts
///
/// ### Adaptive Widgets
/// - [AdaptiveContainer]: Responsive container with adaptive properties
/// - [AdaptiveText]: Text with responsive font scaling
/// - [AdaptiveSpacing]: Responsive spacing widget
/// - [AdaptiveCard]: Responsive card with adaptive styling
/// - [AdaptiveIcon]: Icons with responsive sizing
///
/// ### Safe Area Management
/// - [AdaptiveSafeArea]: Enhanced safe area with device-specific behavior
/// - [ResponsiveScaffold]: Scaffold with adaptive safe area and app bar
///
/// ### Context Extensions
/// - [ResponsiveContext]: Responsive utilities on BuildContext
/// - [OrientationContext]: Orientation utilities on BuildContext
/// - [SafeAreaContext]: Safe area utilities on BuildContext
///
/// ## Usage Example:
///
/// ```dart
/// // Basic responsive layout
/// ResponsiveLayout(
///   mobile: (context) => MobileHomePage(),
///   tablet: (context) => TabletHomePage(),
///   desktop: (context) => DesktopHomePage(),
/// )
///
/// // Responsive grid
/// ResponsiveGrid(
///   children: albumCards,
///   spacing: 16.0,
/// )
///
/// // Adaptive spacing
/// AdaptiveSpacing(
///   mobile: 8.0,
///   tablet: 12.0,
///   desktop: 16.0,
/// )
///
/// // Context extensions
/// if (context.isMobile) {
///   return MobileWidget();
/// }
/// ```

// Breakpoints and utilities
export 'breakpoints.dart';
// Orientation support
export 'orientation_layout.dart';
// Core responsive builders
export 'responsive_builder.dart';
// Grid layouts
export 'responsive_grid.dart';
// Safe area handling
export 'safe_area_handler.dart';
