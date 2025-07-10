import 'package:flutter/material.dart';

/// A performance-optimized wrapper for grid items.
/// 
/// This widget wraps grid items with a RepaintBoundary to prevent unnecessary
/// repaints when scrolling or when other grid items change. This improves
/// performance in large grids by isolating the rendering of individual items.
class GridItemWrapper extends StatelessWidget {
  /// Creates a grid item wrapper with performance optimizations.
  /// 
  /// The [child] parameter is the widget to wrap.
  /// The [itemKey] parameter is used as the key for the RepaintBoundary.
  const GridItemWrapper({
    required this.child,
    required this.itemKey,
    super.key,
  });

  /// The widget to wrap with performance optimizations.
  final Widget child;
  
  /// The key used for the RepaintBoundary to optimize repainting.
  final Key itemKey;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        key: itemKey,
        child: child,
      );
}
