import 'package:flutter/material.dart';

/// A reusable widget for displaying an icon with text in a row
/// Commonly used in menu items, list tiles, and other UI elements
class IconTextRow extends StatelessWidget {
  const IconTextRow({
    required this.icon,
    required this.text,
    super.key,
    this.spacing = 8.0,
    this.mainAxisSize = MainAxisSize.max,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  final IconData icon;
  final String text;
  final double spacing;
  final MainAxisSize mainAxisSize;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: mainAxisSize,
        crossAxisAlignment: crossAxisAlignment,
        children: [
          Icon(icon),
          SizedBox(width: spacing),
          Text(text),
        ],
      );
}
