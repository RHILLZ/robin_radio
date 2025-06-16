import 'package:flutter/material.dart';

/// A performance-optimized wrapper for list items
/// Adds RepaintBoundary to prevent unnecessary repaints when scrolling
/// or when other list items change
class ListItemWrapper extends StatelessWidget {
  const ListItemWrapper({
    required this.child,
    required this.itemKey,
    super.key,
  });

  final Widget child;
  final Key itemKey;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        key: itemKey,
        child: child,
      );
}
