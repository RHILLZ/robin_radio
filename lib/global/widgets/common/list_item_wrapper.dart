import 'package:flutter/material.dart';

/// A performance-optimized wrapper for list items
/// Adds RepaintBoundary to prevent unnecessary repaints when scrolling
/// or when other list items change
class ListItemWrapper extends StatelessWidget {
  /// Creates a ListItemWrapper with the given child and key.
  const ListItemWrapper({
    required this.child,
    required this.itemKey,
    super.key,
  });

  /// The child widget to wrap with performance optimizations.
  final Widget child;
  /// The key for the RepaintBoundary to ensure proper caching.
  final Key itemKey;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        key: itemKey,
        child: child,
      );
}
