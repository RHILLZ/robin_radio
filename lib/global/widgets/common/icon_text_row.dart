import 'package:flutter/material.dart';

/// A reusable widget for displaying an icon with text in a row
/// Commonly used in menu items, list tiles, and other UI elements
class IconTextRow extends StatelessWidget {
  /// Creates an IconTextRow widget
  const IconTextRow({
    required this.icon,
    required this.text,
    super.key,
    this.spacing = 8.0,
    this.mainAxisSize = MainAxisSize.max,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  /// The icon to display
  final IconData icon;
  
  /// The text to display next to the icon
  final String text;
  
  /// The spacing between the icon and text
  final double spacing;
  
  /// The main axis size of the row
  final MainAxisSize mainAxisSize;
  
  /// The cross axis alignment of the row
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
