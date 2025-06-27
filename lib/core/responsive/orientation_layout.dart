import 'package:flutter/material.dart';

/// Builder function for orientation-specific layouts.
typedef OrientationWidgetBuilder = Widget Function(
  BuildContext context,
  Orientation orientation,
);

/// A widget that builds different layouts based on device orientation.
///
/// Automatically detects orientation changes and rebuilds with the appropriate
/// layout for portrait or landscape modes.
class OrientationLayout extends StatelessWidget {
  /// Creates an orientation-aware layout.
  ///
  /// Provide separate builders for portrait and landscape orientations.
  /// If only one builder is provided, it will be used for both orientations.
  const OrientationLayout({
    this.portrait,
    this.landscape,
    super.key,
  }) : assert(
         portrait != null || landscape != null,
         'At least one orientation builder must be provided',
       );

  /// Builder for portrait orientation.
  final OrientationWidgetBuilder? portrait;
  
  /// Builder for landscape orientation.
  final OrientationWidgetBuilder? landscape;

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        switch (orientation) {
          case Orientation.portrait:
            return portrait?.call(context, orientation) ??
                   landscape!.call(context, orientation);
          case Orientation.landscape:
            return landscape?.call(context, orientation) ??
                   portrait!.call(context, orientation);
        }
      },
    );
  }
}

/// A responsive layout that considers both screen size and orientation.
///
/// Combines responsive breakpoints with orientation detection to provide
/// the most appropriate layout for any device configuration.
class ResponsiveOrientationLayout extends StatelessWidget {
  /// Creates a layout that responds to both screen size and orientation.
  const ResponsiveOrientationLayout({
    this.mobilePortrait,
    this.mobileLandscape,
    this.tabletPortrait,
    this.tabletLandscape,
    this.desktopPortrait,
    this.desktopLandscape,
    super.key,
  }) : assert(
         mobilePortrait != null ||
         mobileLandscape != null ||
         tabletPortrait != null ||
         tabletLandscape != null ||
         desktopPortrait != null ||
         desktopLandscape != null,
         'At least one layout builder must be provided',
       );

  /// Builder for mobile portrait layout.
  final Widget Function(BuildContext context)? mobilePortrait;
  
  /// Builder for mobile landscape layout.
  final Widget Function(BuildContext context)? mobileLandscape;
  
  /// Builder for tablet portrait layout.
  final Widget Function(BuildContext context)? tabletPortrait;
  
  /// Builder for tablet landscape layout.
  final Widget Function(BuildContext context)? tabletLandscape;
  
  /// Builder for desktop portrait layout.
  final Widget Function(BuildContext context)? desktopPortrait;
  
  /// Builder for desktop landscape layout.
  final Widget Function(BuildContext context)? desktopLandscape;

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        final isPortrait = orientation == Orientation.portrait;
        final screenWidth = MediaQuery.of(context).size.width;
        
        // Determine device type based on screen width
        if (screenWidth < 600) {
          // Mobile
          if (isPortrait) {
            return mobilePortrait?.call(context) ??
                   mobileLandscape?.call(context) ??
                   _getFallbackWidget(context);
          } else {
            return mobileLandscape?.call(context) ??
                   mobilePortrait?.call(context) ??
                   _getFallbackWidget(context);
          }
        } else if (screenWidth < 1200) {
          // Tablet
          if (isPortrait) {
            return tabletPortrait?.call(context) ??
                   tabletLandscape?.call(context) ??
                   mobilePortrait?.call(context) ??
                   _getFallbackWidget(context);
          } else {
            return tabletLandscape?.call(context) ??
                   tabletPortrait?.call(context) ??
                   mobileLandscape?.call(context) ??
                   _getFallbackWidget(context);
          }
        } else {
          // Desktop
          if (isPortrait) {
            return desktopPortrait?.call(context) ??
                   desktopLandscape?.call(context) ??
                   tabletPortrait?.call(context) ??
                   _getFallbackWidget(context);
          } else {
            return desktopLandscape?.call(context) ??
                   desktopPortrait?.call(context) ??
                   tabletLandscape?.call(context) ??
                   _getFallbackWidget(context);
          }
        }
      },
    );
  }
  
  /// Returns the first available widget builder as fallback.
  Widget _getFallbackWidget(BuildContext context) {
    return mobilePortrait?.call(context) ??
           mobileLandscape?.call(context) ??
           tabletPortrait?.call(context) ??
           tabletLandscape?.call(context) ??
           desktopPortrait?.call(context) ??
           desktopLandscape!.call(context);
  }
}

/// Extension on BuildContext for orientation utilities.
extension OrientationContext on BuildContext {
  /// Returns the current device orientation.
  Orientation get orientation => MediaQuery.of(this).orientation;
  
  /// Returns true if the device is in portrait orientation.
  bool get isPortrait => orientation == Orientation.portrait;
  
  /// Returns true if the device is in landscape orientation.
  bool get isLandscape => orientation == Orientation.landscape;
  
  /// Returns the aspect ratio of the screen.
  double get aspectRatio {
    final size = MediaQuery.of(this).size;
    return size.width / size.height;
  }
  
  /// Returns true if the screen is wider than it is tall (considering orientation).
  bool get isWideScreen => aspectRatio > 1.5;
  
  /// Returns true if the screen has a typical phone aspect ratio.
  bool get isPhoneAspectRatio => aspectRatio < 0.7 || (aspectRatio > 1.4 && aspectRatio < 2.5);
}