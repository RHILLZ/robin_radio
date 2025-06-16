import 'package:flutter/material.dart';

/// A const widget for player control buttons
/// Provides consistent styling and performance optimization
class PlayerControlButton extends StatelessWidget {
  const PlayerControlButton({
    required this.icon,
    required this.onPressed,
    super.key,
    this.size = 36.0,
    this.color,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final Color? color;
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
