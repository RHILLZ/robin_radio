import 'package:flutter/material.dart';

/// An optimized circular progress indicator with RepaintBoundary
/// Prevents unnecessary repaints when used in complex widget trees
class OptimizedProgressIndicator extends StatelessWidget {
  const OptimizedProgressIndicator({
    super.key,
    this.color,
    this.size = 24.0,
    this.strokeWidth = 4.0,
  });

  final Color? color;
  final double size;
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
