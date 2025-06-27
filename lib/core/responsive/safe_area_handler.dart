import 'package:flutter/material.dart';
import 'breakpoints.dart';
import 'responsive_builder.dart';

/// Enhanced safe area handling that considers both device types and screen orientations.
///
/// Provides intelligent safe area management that adapts to different devices
/// and handles edge cases like notches, home indicators, and navigation bars.
class AdaptiveSafeArea extends StatelessWidget {
  /// Creates an adaptive safe area with responsive behavior.
  const AdaptiveSafeArea({
    required this.child,
    this.left = true,
    this.top = true,
    this.right = true,
    this.bottom = true,
    this.maintainBottomViewPadding = false,
    this.minimum = EdgeInsets.zero,
    this.mobileMinimum,
    this.tabletMinimum,
    this.desktopMinimum,
    super.key,
  });

  /// The child widget to wrap with safe area.
  final Widget child;
  
  /// Whether to apply safe area on the left edge.
  final bool left;
  
  /// Whether to apply safe area on the top edge.
  final bool top;
  
  /// Whether to apply safe area on the right edge.
  final bool right;
  
  /// Whether to apply safe area on the bottom edge.
  final bool bottom;
  
  /// Whether to maintain bottom view padding.
  final bool maintainBottomViewPadding;
  
  /// Minimum padding to apply (fallback for all device types).
  final EdgeInsets minimum;
  
  /// Minimum padding for mobile devices.
  final EdgeInsets? mobileMinimum;
  
  /// Minimum padding for tablet devices.
  final EdgeInsets? tabletMinimum;
  
  /// Minimum padding for desktop devices.
  final EdgeInsets? desktopMinimum;

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, constraints, deviceType, screenSize) {
        EdgeInsets deviceMinimum;
        
        switch (deviceType) {
          case DeviceType.mobile:
            deviceMinimum = mobileMinimum ?? minimum;
            break;
          case DeviceType.tablet:
            deviceMinimum = tabletMinimum ?? minimum;
            break;
          case DeviceType.desktop:
            deviceMinimum = desktopMinimum ?? minimum;
            break;
        }
        
        return SafeArea(
          left: left,
          top: top,
          right: right,
          bottom: bottom,
          maintainBottomViewPadding: maintainBottomViewPadding,
          minimum: deviceMinimum,
          child: child,
        );
      },
    );
  }
}

/// A responsive scaffold that handles safe areas and provides adaptive app bars.
///
/// Automatically adjusts app bar height, padding, and safe area behavior
/// based on device type and screen orientation.
class ResponsiveScaffold extends StatelessWidget {
  /// Creates a responsive scaffold with adaptive safe area handling.
  const ResponsiveScaffold({
    this.appBar,
    this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.drawer,
    this.endDrawer,
    this.bottomNavigationBar,
    this.backgroundColor,
    this.resizeToAvoidBottomInset,
    this.primary = true,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.automaticallyImplyLeading = true,
    this.adaptiveAppBar = true,
    this.adaptivePadding = true,
    super.key,
  });

  /// The app bar to display.
  final PreferredSizeWidget? appBar;
  
  /// The primary content of the scaffold.
  final Widget? body;
  
  /// Floating action button.
  final Widget? floatingActionButton;
  
  /// Location of the floating action button.
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  
  /// Drawer widget.
  final Widget? drawer;
  
  /// End drawer widget.
  final Widget? endDrawer;
  
  /// Bottom navigation bar.
  final Widget? bottomNavigationBar;
  
  /// Background color of the scaffold.
  final Color? backgroundColor;
  
  /// Whether to resize the body when the keyboard appears.
  final bool? resizeToAvoidBottomInset;
  
  /// Whether this is a primary scaffold.
  final bool primary;
  
  /// Whether to extend the body behind the app bar.
  final bool extendBody;
  
  /// Whether to extend the body behind the app bar.
  final bool extendBodyBehindAppBar;
  
  /// Whether to automatically imply leading widget.
  final bool automaticallyImplyLeading;
  
  /// Whether to apply adaptive behavior to the app bar.
  final bool adaptiveAppBar;
  
  /// Whether to apply adaptive padding to the body.
  final bool adaptivePadding;

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, constraints, deviceType, screenSize) {
        Widget? wrappedBody = body;
        
        // Apply adaptive padding to body if enabled
        if (adaptivePadding && wrappedBody != null) {
          EdgeInsets padding;
          
          switch (deviceType) {
            case DeviceType.mobile:
              padding = const EdgeInsets.symmetric(horizontal: 16.0);
              break;
            case DeviceType.tablet:
              padding = const EdgeInsets.symmetric(horizontal: 24.0);
              break;
            case DeviceType.desktop:
              padding = const EdgeInsets.symmetric(horizontal: 32.0);
              break;
          }
          
          wrappedBody = Padding(
            padding: padding,
            child: wrappedBody,
          );
        }
        
        return Scaffold(
          appBar: adaptiveAppBar ? _buildAdaptiveAppBar(context, deviceType) : appBar,
          body: wrappedBody,
          floatingActionButton: floatingActionButton,
          floatingActionButtonLocation: floatingActionButtonLocation,
          drawer: drawer,
          endDrawer: endDrawer,
          bottomNavigationBar: bottomNavigationBar,
          backgroundColor: backgroundColor,
          resizeToAvoidBottomInset: resizeToAvoidBottomInset,
          primary: primary,
          extendBody: extendBody,
          extendBodyBehindAppBar: extendBodyBehindAppBar,
        );
      },
    );
  }
  
  /// Builds an adaptive app bar with device-specific styling.
  PreferredSizeWidget? _buildAdaptiveAppBar(BuildContext context, DeviceType deviceType) {
    if (appBar == null) return null;
    
    // If it's already an AppBar, enhance it with adaptive properties
    if (appBar is AppBar) {
      final originalAppBar = appBar as AppBar;
      
      // Adjust app bar height based on device type
      double height;
      switch (deviceType) {
        case DeviceType.mobile:
          height = kToolbarHeight;
          break;
        case DeviceType.tablet:
          height = kToolbarHeight + 8.0;
          break;
        case DeviceType.desktop:
          height = kToolbarHeight + 16.0;
          break;
      }
      
      return PreferredSize(
        preferredSize: Size.fromHeight(height),
        child: AppBar(
          title: originalAppBar.title,
          leading: originalAppBar.leading,
          actions: originalAppBar.actions,
          backgroundColor: originalAppBar.backgroundColor,
          foregroundColor: originalAppBar.foregroundColor,
          elevation: originalAppBar.elevation,
          shadowColor: originalAppBar.shadowColor,
          automaticallyImplyLeading: automaticallyImplyLeading,
          centerTitle: originalAppBar.centerTitle,
          titleSpacing: originalAppBar.titleSpacing,
          toolbarOpacity: originalAppBar.toolbarOpacity,
          bottomOpacity: originalAppBar.bottomOpacity,
          toolbarHeight: height,
        ),
      );
    }
    
    return appBar;
  }
}

/// Extension on MediaQuery for safe area utilities.
extension SafeAreaContext on BuildContext {
  /// Returns the safe area padding for the current device.
  EdgeInsets get safeAreaPadding => MediaQuery.of(this).padding;
  
  /// Returns the view insets (usually keyboard) for the current device.
  EdgeInsets get viewInsets => MediaQuery.of(this).viewInsets;
  
  /// Returns the view padding for the current device.
  EdgeInsets get viewPadding => MediaQuery.of(this).viewPadding;
  
  /// Returns true if the device has a top notch or status bar.
  bool get hasTopNotch => safeAreaPadding.top > 24;
  
  /// Returns true if the device has a bottom home indicator.
  bool get hasBottomSafeArea => safeAreaPadding.bottom > 0;
  
  /// Returns true if the keyboard is currently visible.
  bool get isKeyboardVisible => viewInsets.bottom > 0;
  
  /// Returns the height available for content (excluding safe areas).
  double get availableHeight {
    final size = MediaQuery.of(this).size;
    final padding = safeAreaPadding;
    return size.height - padding.top - padding.bottom;
  }
  
  /// Returns the width available for content (excluding safe areas).
  double get availableWidth {
    final size = MediaQuery.of(this).size;
    final padding = safeAreaPadding;
    return size.width - padding.left - padding.right;
  }
}