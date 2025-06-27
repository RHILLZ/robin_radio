import 'package:flutter/material.dart';
import 'breakpoints.dart';
import 'responsive_builder.dart';

/// An adaptive container that adjusts its properties based on screen size.
///
/// Automatically scales padding, margin, and other properties to provide
/// appropriate spacing for different device types.
class AdaptiveContainer extends StatelessWidget {
  /// Creates an adaptive container with responsive properties.
  const AdaptiveContainer({
    this.child,
    this.mobilePadding,
    this.tabletPadding,
    this.desktopPadding,
    this.mobileMargin,
    this.tabletMargin,
    this.desktopMargin,
    this.color,
    this.decoration,
    this.width,
    this.height,
    this.constraints,
    this.alignment,
    super.key,
  });

  /// The child widget to contain.
  final Widget? child;
  
  /// Padding for mobile devices.
  final EdgeInsetsGeometry? mobilePadding;
  
  /// Padding for tablet devices.
  final EdgeInsetsGeometry? tabletPadding;
  
  /// Padding for desktop devices.
  final EdgeInsetsGeometry? desktopPadding;
  
  /// Margin for mobile devices.
  final EdgeInsetsGeometry? mobileMargin;
  
  /// Margin for tablet devices.
  final EdgeInsetsGeometry? tabletMargin;
  
  /// Margin for desktop devices.
  final EdgeInsetsGeometry? desktopMargin;
  
  /// Container color.
  final Color? color;
  
  /// Container decoration.
  final Decoration? decoration;
  
  /// Container width.
  final double? width;
  
  /// Container height.
  final double? height;
  
  /// Container constraints.
  final BoxConstraints? constraints;
  
  /// Child alignment within the container.
  final AlignmentGeometry? alignment;

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, constraints, deviceType, screenSize) {
        EdgeInsetsGeometry? padding;
        EdgeInsetsGeometry? margin;
        
        switch (deviceType) {
          case DeviceType.mobile:
            padding = mobilePadding ?? const EdgeInsets.all(16.0);
            margin = mobileMargin;
            break;
          case DeviceType.tablet:
            padding = tabletPadding ?? const EdgeInsets.all(24.0);
            margin = tabletMargin;
            break;
          case DeviceType.desktop:
            padding = desktopPadding ?? const EdgeInsets.all(32.0);
            margin = desktopMargin;
            break;
        }
        
        return Container(
          padding: padding,
          margin: margin,
          color: color,
          decoration: decoration,
          width: width,
          height: height,
          constraints: this.constraints,
          alignment: alignment,
          child: child,
        );
      },
    );
  }
}

/// Adaptive text that scales font size based on screen size.
///
/// Automatically adjusts font size and text properties for optimal
/// readability across different device types.
class AdaptiveText extends StatelessWidget {
  /// Creates adaptive text with responsive font sizing.
  const AdaptiveText(
    this.text, {
    this.style,
    this.mobileScale = 1.0,
    this.tabletScale = 1.1,
    this.desktopScale = 1.2,
    this.textAlign,
    this.overflow,
    this.maxLines,
    super.key,
  });

  /// The text to display.
  final String text;
  
  /// Base text style.
  final TextStyle? style;
  
  /// Font scale factor for mobile devices.
  final double mobileScale;
  
  /// Font scale factor for tablet devices.
  final double tabletScale;
  
  /// Font scale factor for desktop devices.
  final double desktopScale;
  
  /// Text alignment.
  final TextAlign? textAlign;
  
  /// Text overflow behavior.
  final TextOverflow? overflow;
  
  /// Maximum number of lines.
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, constraints, deviceType, screenSize) {
        double scale;
        
        switch (deviceType) {
          case DeviceType.mobile:
            scale = mobileScale;
            break;
          case DeviceType.tablet:
            scale = tabletScale;
            break;
          case DeviceType.desktop:
            scale = desktopScale;
            break;
        }
        
        final scaledStyle = style?.copyWith(
          fontSize: (style?.fontSize ?? 14.0) * scale,
        ) ?? TextStyle(fontSize: 14.0 * scale);
        
        return Text(
          text,
          style: scaledStyle,
          textAlign: textAlign,
          overflow: overflow,
          maxLines: maxLines,
        );
      },
    );
  }
}

/// Adaptive spacing that provides different spacing values based on screen size.
///
/// Useful for creating consistent spacing that scales appropriately
/// across different device types.
class AdaptiveSpacing extends StatelessWidget {
  /// Creates adaptive spacing with responsive values.
  const AdaptiveSpacing({
    this.mobile = 8.0,
    this.tablet = 12.0,
    this.desktop = 16.0,
    this.direction = Axis.vertical,
    super.key,
  });

  /// Spacing value for mobile devices.
  final double mobile;
  
  /// Spacing value for tablet devices.
  final double tablet;
  
  /// Spacing value for desktop devices.
  final double desktop;
  
  /// Direction of spacing (vertical or horizontal).
  final Axis direction;

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, constraints, deviceType, screenSize) {
        double spacing;
        
        switch (deviceType) {
          case DeviceType.mobile:
            spacing = mobile;
            break;
          case DeviceType.tablet:
            spacing = tablet;
            break;
          case DeviceType.desktop:
            spacing = desktop;
            break;
        }
        
        return direction == Axis.vertical 
            ? SizedBox(height: spacing)
            : SizedBox(width: spacing);
      },
    );
  }
}

/// Adaptive card that adjusts its appearance based on screen size.
///
/// Provides appropriate elevation, padding, and border radius
/// for different device types.
class AdaptiveCard extends StatelessWidget {
  /// Creates an adaptive card with responsive styling.
  const AdaptiveCard({
    required this.child,
    this.mobileElevation = 2.0,
    this.tabletElevation = 4.0,
    this.desktopElevation = 8.0,
    this.mobilePadding,
    this.tabletPadding,
    this.desktopPadding,
    this.mobileRadius = 8.0,
    this.tabletRadius = 12.0,
    this.desktopRadius = 16.0,
    this.color,
    this.margin,
    super.key,
  });

  /// The child widget to display in the card.
  final Widget child;
  
  /// Card elevation for mobile devices.
  final double mobileElevation;
  
  /// Card elevation for tablet devices.
  final double tabletElevation;
  
  /// Card elevation for desktop devices.
  final double desktopElevation;
  
  /// Card padding for mobile devices.
  final EdgeInsetsGeometry? mobilePadding;
  
  /// Card padding for tablet devices.
  final EdgeInsetsGeometry? tabletPadding;
  
  /// Card padding for desktop devices.
  final EdgeInsetsGeometry? desktopPadding;
  
  /// Border radius for mobile devices.
  final double mobileRadius;
  
  /// Border radius for tablet devices.
  final double tabletRadius;
  
  /// Border radius for desktop devices.
  final double desktopRadius;
  
  /// Card background color.
  final Color? color;
  
  /// Card margin.
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, constraints, deviceType, screenSize) {
        double elevation;
        EdgeInsetsGeometry? padding;
        double radius;
        
        switch (deviceType) {
          case DeviceType.mobile:
            elevation = mobileElevation;
            padding = mobilePadding ?? const EdgeInsets.all(16.0);
            radius = mobileRadius;
            break;
          case DeviceType.tablet:
            elevation = tabletElevation;
            padding = tabletPadding ?? const EdgeInsets.all(20.0);
            radius = tabletRadius;
            break;
          case DeviceType.desktop:
            elevation = desktopElevation;
            padding = desktopPadding ?? const EdgeInsets.all(24.0);
            radius = desktopRadius;
            break;
        }
        
        return Card(
          elevation: elevation,
          color: color,
          margin: margin,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          child: Padding(
            padding: padding,
            child: child,
          ),
        );
      },
    );
  }
}

/// Adaptive icon that adjusts size based on screen size.
///
/// Provides appropriate icon sizes for different device types
/// to maintain visual hierarchy and usability.
class AdaptiveIcon extends StatelessWidget {
  /// Creates an adaptive icon with responsive sizing.
  const AdaptiveIcon(
    this.icon, {
    this.mobileSize = 20.0,
    this.tabletSize = 24.0,
    this.desktopSize = 28.0,
    this.color,
    super.key,
  });

  /// The icon to display.
  final IconData icon;
  
  /// Icon size for mobile devices.
  final double mobileSize;
  
  /// Icon size for tablet devices.
  final double tabletSize;
  
  /// Icon size for desktop devices.
  final double desktopSize;
  
  /// Icon color.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, constraints, deviceType, screenSize) {
        double size;
        
        switch (deviceType) {
          case DeviceType.mobile:
            size = mobileSize;
            break;
          case DeviceType.tablet:
            size = tabletSize;
            break;
          case DeviceType.desktop:
            size = desktopSize;
            break;
        }
        
        return Icon(
          icon,
          size: size,
          color: color,
        );
      },
    );
  }
}