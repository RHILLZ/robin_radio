/// Responsive design breakpoints and screen size utilities for Robin Radio.
///
/// Defines standardized breakpoints for creating adaptive layouts that work
/// across mobile phones, tablets, and desktop devices.
library;

/// Screen size breakpoints following Material Design guidelines.
class Breakpoints {
  Breakpoints._();
  /// Small screens (mobile phones): < 600px width
  static const double small = 600;

  /// Medium screens (tablets): 600px - 1200px width
  static const double medium = 1200;

  /// Large screens (desktop): > 1200px width
  static const double large = 1200;

  /// Extra small screens (compact phones): < 360px width
  static const double extraSmall = 360;

  /// Extra large screens (wide desktop): > 1600px width
  static const double extraLarge = 1600;
}

/// Device type classification based on screen size and characteristics.
enum DeviceType {
  /// Mobile phone (small screen, portrait-first)
  mobile,

  /// Tablet (medium screen, flexible orientation)
  tablet,

  /// Desktop computer (large screen, landscape-first)
  desktop,
}

/// Screen size classification for responsive layouts.
enum ScreenSize {
  /// Extra small: < 360px (compact phones)
  extraSmall,

  /// Small: 360px - 600px (standard phones)
  small,

  /// Medium: 600px - 1200px (tablets)
  medium,

  /// Large: 1200px - 1600px (desktop)
  large,

  /// Extra large: > 1600px (wide desktop)
  extraLarge,
}

/// Responsive design utilities for screen size detection and layout decisions.
class ResponsiveUtils {
  ResponsiveUtils._();
  /// Determines the device type based on screen width and platform.
  static DeviceType getDeviceType(double width) {
    if (width < Breakpoints.small) {
      return DeviceType.mobile;
    } else if (width < Breakpoints.medium) {
      return DeviceType.tablet;
    } else {
      return DeviceType.desktop;
    }
  }

  /// Determines the screen size category based on width.
  static ScreenSize getScreenSize(double width) {
    if (width < Breakpoints.extraSmall) {
      return ScreenSize.extraSmall;
    } else if (width < Breakpoints.small) {
      return ScreenSize.small;
    } else if (width < Breakpoints.medium) {
      return ScreenSize.medium;
    } else if (width < Breakpoints.extraLarge) {
      return ScreenSize.large;
    } else {
      return ScreenSize.extraLarge;
    }
  }

  /// Returns true if the screen is considered mobile-sized.
  static bool isMobile(double width) => width < Breakpoints.small;

  /// Returns true if the screen is considered tablet-sized.
  static bool isTablet(double width) =>
      width >= Breakpoints.small && width < Breakpoints.medium;

  /// Returns true if the screen is considered desktop-sized.
  static bool isDesktop(double width) => width >= Breakpoints.medium;

  /// Returns the recommended number of columns for grid layouts.
  static int getGridColumns(double width) {
    if (width < Breakpoints.extraSmall) {
      return 1; // Very small screens: single column
    } else if (width < Breakpoints.small) {
      return 2; // Mobile: 2 columns
    } else if (width < Breakpoints.medium) {
      return 3; // Tablet: 3 columns
    } else if (width < Breakpoints.extraLarge) {
      return 4; // Desktop: 4 columns
    } else {
      return 6; // Wide desktop: 6 columns
    }
  }

  /// Returns responsive padding based on screen size.
  static double getResponsivePadding(double width) {
    if (width < Breakpoints.small) {
      return 16; // Mobile: standard padding
    } else if (width < Breakpoints.medium) {
      return 24; // Tablet: more generous padding
    } else {
      return 32; // Desktop: maximum padding
    }
  }

  /// Returns responsive font size scaling factor.
  static double getFontScale(double width) {
    if (width < Breakpoints.small) {
      return 1; // Mobile: standard scale
    } else if (width < Breakpoints.medium) {
      return 1.1; // Tablet: slightly larger
    } else {
      return 1.2; // Desktop: larger text
    }
  }
}
