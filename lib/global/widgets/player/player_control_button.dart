import 'package:flutter/material.dart';

/// A const widget for player control buttons
/// Provides consistent styling and performance optimization
class PlayerControlButton extends StatelessWidget {
  /// Creates a player control button with the specified icon and behavior.
  /// 
  /// The [icon] and [onPressed] parameters are required. The [size] defaults
  /// to 36.0 pixels, and [color] defaults to the theme's primary color.
  /// An optional [tooltip] can be provided for accessibility.
  const PlayerControlButton({
    required this.icon,
    required this.onPressed,
    super.key,
    this.size = 36.0,
    this.color,
    this.tooltip,
  });

  /// The icon to display in the button
  final IconData icon;
  
  /// Callback function called when the button is pressed
  final VoidCallback? onPressed;
  
  /// Size of the icon in logical pixels
  final double size;
  
  /// Color of the icon, defaults to theme's primary color if not specified
  final Color? color;
  
  /// Optional tooltip message for accessibility
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final iconButton = IconButton(
      onPressed: onPressed,
      icon: Icon(
        icon,
        color: color ?? Theme.of(context).colorScheme.primary,
        size: size,
      ),
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip,
        child: iconButton,
      );
    }

    return iconButton;
  }
}
