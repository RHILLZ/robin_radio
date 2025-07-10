import 'package:flutter/material.dart';

/// An optimized circular progress indicator with RepaintBoundary
/// Prevents unnecessary repaints when used in complex widget trees
class OptimizedProgressIndicator extends StatelessWidget {
  /// Creates an OptimizedProgressIndicator with the given parameters.
  const OptimizedProgressIndicator({
    super.key,
    this.color,
    this.size = 24.0,
    this.strokeWidth = 4.0,
  });

  /// The color of the progress indicator.
  final Color? color;
  /// The size of the progress indicator.
  final double size;
  /// The width of the progress indicator stroke.
  final double strokeWidth;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            color: color ?? Theme.of(context).colorScheme.primary,
            strokeWidth: strokeWidth,
          ),
        ),
      );
}
