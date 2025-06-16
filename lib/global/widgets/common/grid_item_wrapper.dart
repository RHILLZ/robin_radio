import 'package:flutter/material.dart';

/// A performance-optimized wrapper for grid items
/// Adds RepaintBoundary to prevent unnecessary repaints when scrolling
/// or when other grid items change
class GridItemWrapper extends StatelessWidget {
  const GridItemWrapper({
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
