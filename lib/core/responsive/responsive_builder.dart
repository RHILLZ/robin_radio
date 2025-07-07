import 'package:flutter/material.dart';
import 'breakpoints.dart';

/// Builder function type for responsive layouts.
///
/// Provides context, screen constraints, device type, and screen size
/// to build appropriate layouts for different screen sizes.
typedef ResponsiveWidgetBuilder = Widget Function(
  BuildContext context,
  BoxConstraints constraints,
  DeviceType deviceType,
  ScreenSize screenSize,
);

/// A widget that builds different layouts based on screen size and device type.
///
/// Automatically detects the current screen size and provides appropriate
/// device type and screen size information to the builder function.
///
/// Usage:
/// ```dart
/// ResponsiveBuilder(
///   builder: (context, constraints, deviceType, screenSize) {
///     if (deviceType == DeviceType.mobile) {
///       return MobileLayout();
///     } else if (deviceType == DeviceType.tablet) {
///       return TabletLayout();
///     } else {
///       return DesktopLayout();
///     }
///   },
/// )
/// ```
class ResponsiveBuilder extends StatelessWidget {
  /// Creates a responsive builder widget.
  ///
  /// The [builder] function is called with screen information to create
  /// the appropriate layout for the current device.
  const ResponsiveBuilder({
    required this.builder,
    super.key,
  });

  /// Builder function that creates the widget based on screen characteristics.
  final ResponsiveWidgetBuilder builder;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final deviceType = ResponsiveUtils.getDeviceType(width);
          final screenSize = ResponsiveUtils.getScreenSize(width);

          return builder(context, constraints, deviceType, screenSize);
        },
      );
}

/// A simplified responsive builder that provides separate builders for each device type.
///
/// Automatically chooses the appropriate builder based on screen size,
/// with fallback logic for missing builders.
///
/// Usage:
/// ```dart
/// ResponsiveLayout(
///   mobile: (context) => MobileLayout(),
///   tablet: (context) => TabletLayout(),
///   desktop: (context) => DesktopLayout(),
/// )
/// ```
class ResponsiveLayout extends StatelessWidget {
  /// Creates a responsive layout with separate builders for each device type.
  ///
  /// At least one builder must be provided. Missing builders will fall back
  /// to the next available option in the order: desktop → tablet → mobile.
  const ResponsiveLayout({
    this.mobile,
    this.tablet,
    this.desktop,
    super.key,
  }) : assert(
          mobile != null || tablet != null || desktop != null,
          'At least one layout builder must be provided',
        );

  /// Builder for mobile layouts (< 600px width).
  final Widget Function(BuildContext context)? mobile;

  /// Builder for tablet layouts (600px - 1200px width).
  final Widget Function(BuildContext context)? tablet;

  /// Builder for desktop layouts (> 1200px width).
  final Widget Function(BuildContext context)? desktop;

  @override
  Widget build(BuildContext context) => ResponsiveBuilder(
        builder: (context, constraints, deviceType, screenSize) {
          switch (deviceType) {
            case DeviceType.mobile:
              return mobile?.call(context) ??
                  tablet?.call(context) ??
                  desktop!.call(context);
            case DeviceType.tablet:
              return tablet?.call(context) ??
                  desktop?.call(context) ??
                  mobile!.call(context);
            case DeviceType.desktop:
              return desktop?.call(context) ??
                  tablet?.call(context) ??
                  mobile!.call(context);
          }
        },
      );
}

/// Responsive value provider that returns different values based on screen size.
///
/// Useful for providing responsive values like padding, font sizes, or counts
/// without rebuilding the entire widget tree.
///
/// Usage:
/// ```dart
/// ResponsiveValue<int>(
///   mobile: 2,
///   tablet: 3,
///   desktop: 4,
/// ).value(context)
/// ```
class ResponsiveValue<T> {
  /// Creates a responsive value with different values for each device type.
  const ResponsiveValue({
    this.mobile,
    this.tablet,
    this.desktop,
  }) : assert(
          mobile != null || tablet != null || desktop != null,
          'At least one value must be provided',
        );

  /// Value for mobile devices.
  final T? mobile;

  /// Value for tablet devices.
  final T? tablet;

  /// Value for desktop devices.
  final T? desktop;

  /// Returns the appropriate value for the current screen size.
  T value(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final deviceType = ResponsiveUtils.getDeviceType(width);

    switch (deviceType) {
      case DeviceType.mobile:
        return mobile ?? tablet ?? desktop!;
      case DeviceType.tablet:
        return tablet ?? desktop ?? mobile!;
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile!;
    }
  }
}

/// Extension on BuildContext for convenient responsive utilities.
extension ResponsiveContext on BuildContext {
  /// Returns the current device type.
  DeviceType get deviceType {
    final width = MediaQuery.of(this).size.width;
    return ResponsiveUtils.getDeviceType(width);
  }

  /// Returns the current screen size category.
  ScreenSize get screenSize {
    final width = MediaQuery.of(this).size.width;
    return ResponsiveUtils.getScreenSize(width);
  }

  /// Returns true if the current device is mobile-sized.
  bool get isMobile => ResponsiveUtils.isMobile(MediaQuery.of(this).size.width);

  /// Returns true if the current device is tablet-sized.
  bool get isTablet => ResponsiveUtils.isTablet(MediaQuery.of(this).size.width);

  /// Returns true if the current device is desktop-sized.
  bool get isDesktop =>
      ResponsiveUtils.isDesktop(MediaQuery.of(this).size.width);

  /// Returns responsive padding for the current screen size.
  double get responsivePadding =>
      ResponsiveUtils.getResponsivePadding(MediaQuery.of(this).size.width);

  /// Returns responsive font scale for the current screen size.
  double get responsiveFontScale =>
      ResponsiveUtils.getFontScale(MediaQuery.of(this).size.width);

  /// Returns the recommended grid columns for the current screen size.
  int get gridColumns =>
      ResponsiveUtils.getGridColumns(MediaQuery.of(this).size.width);
}
