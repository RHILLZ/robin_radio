import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Loading indicator animation types
enum LoadingIndicatorType {
  circular,
  linear,
  dots,
  pulse,
  wave,
}

/// Size presets for loading indicators
enum LoadingIndicatorSize {
  small,
  medium,
  large,
  custom,
}

/// A reusable loading indicator widget with multiple animation types and customization options
class LoadingIndicator extends StatefulWidget {
  const LoadingIndicator({
    super.key,
    this.type = LoadingIndicatorType.circular,
    this.size = LoadingIndicatorSize.medium,
    this.customSize,
    this.color,
    this.backgroundColor,
    this.strokeWidth,
    this.animationDuration = const Duration(milliseconds: 1200),
    this.message,
    this.messageStyle,
    this.spacing = 8.0,
  });

  /// Type of loading animation to display
  final LoadingIndicatorType type;

  /// Predefined size for the indicator
  final LoadingIndicatorSize size;

  /// Custom size when using LoadingIndicatorSize.custom
  final double? customSize;

  /// Primary color for the indicator (defaults to theme primary color)
  final Color? color;

  /// Background color for applicable indicators (defaults to theme surface)
  final Color? backgroundColor;

  /// Stroke width for circular and linear indicators
  final double? strokeWidth;

  /// Duration of the animation cycle
  final Duration animationDuration;

  /// Optional message to display below the indicator
  final String? message;

  /// Style for the message text
  final TextStyle? messageStyle;

  /// Spacing between indicator and message
  final double spacing;

  @override
  State<LoadingIndicator> createState() => _LoadingIndicatorState();
}

class _LoadingIndicatorState extends State<LoadingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_controller);

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _indicatorSize {
    switch (widget.size) {
      case LoadingIndicatorSize.small:
        return 16;
      case LoadingIndicatorSize.medium:
        return 24;
      case LoadingIndicatorSize.large:
        return 32;
      case LoadingIndicatorSize.custom:
        return widget.customSize ?? 24.0;
    }
  }

  double get _strokeWidth {
    if (widget.strokeWidth != null) return widget.strokeWidth!;

    switch (widget.size) {
      case LoadingIndicatorSize.small:
        return 2;
      case LoadingIndicatorSize.medium:
        return 3;
      case LoadingIndicatorSize.large:
        return 4;
      case LoadingIndicatorSize.custom:
        return math.max(2, _indicatorSize / 12);
    }
  }

  Color get _primaryColor => widget.color ?? Theme.of(context).primaryColor;
  Color get _backgroundColorValue =>
      widget.backgroundColor ??
      Theme.of(context).colorScheme.surface.withValues(alpha: 0.3);

  Widget _buildCircularIndicator() => SizedBox(
        width: _indicatorSize,
        height: _indicatorSize,
        child: CircularProgressIndicator(
          strokeWidth: _strokeWidth,
          valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
          backgroundColor: _backgroundColorValue,
        ),
      );

  Widget _buildLinearIndicator() => SizedBox(
        width: _indicatorSize * 3, // Linear indicators are typically wider
        height: _strokeWidth,
        child: LinearProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
          backgroundColor: _backgroundColorValue,
        ),
      );

  Widget _buildDotsIndicator() => AnimatedBuilder(
        animation: _animation,
        builder: (context, child) => Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final progress = (_animation.value + delay) % 1.0;
            final opacity = math.sin(progress * math.pi);

            return Container(
              margin: EdgeInsets.symmetric(horizontal: _indicatorSize / 8),
              width: _indicatorSize / 3,
              height: _indicatorSize / 3,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _primaryColor.withValues(alpha: opacity.abs()),
              ),
            );
          }),
        ),
      );

  Widget _buildPulseIndicator() => AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final scale = 0.7 + (math.sin(_animation.value * math.pi * 2) * 0.3);
          return Transform.scale(
            scale: scale,
            child: Container(
              width: _indicatorSize,
              height: _indicatorSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _primaryColor,
              ),
            ),
          );
        },
      );

  Widget _buildWaveIndicator() => AnimatedBuilder(
        animation: _animation,
        builder: (context, child) => Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            final delay = index * 0.1;
            final progress = (_animation.value + delay) % 1.0;
            final height = _indicatorSize *
                (0.3 + 0.7 * math.sin(progress * math.pi * 2).abs());

            return Container(
              margin: EdgeInsets.symmetric(horizontal: _indicatorSize / 16),
              width: _indicatorSize / 8,
              height: height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_indicatorSize / 16),
                color: _primaryColor,
              ),
            );
          }),
        ),
      );

  Widget _buildIndicator() {
    switch (widget.type) {
      case LoadingIndicatorType.circular:
        return _buildCircularIndicator();
      case LoadingIndicatorType.linear:
        return _buildLinearIndicator();
      case LoadingIndicatorType.dots:
        return _buildDotsIndicator();
      case LoadingIndicatorType.pulse:
        return _buildPulseIndicator();
      case LoadingIndicatorType.wave:
        return _buildWaveIndicator();
    }
  }

  @override
  Widget build(BuildContext context) {
    final indicator = _buildIndicator();

    if (widget.message != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          indicator,
          SizedBox(height: widget.spacing),
          Text(
            widget.message!,
            style: widget.messageStyle ??
                Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return indicator;
  }
}

/// Convenience constructors for common loading indicator patterns
extension LoadingIndicatorConvenience on LoadingIndicator {
  /// Small circular loading indicator for buttons and compact spaces
  static Widget small({
    Color? color,
    String? message,
  }) =>
      LoadingIndicator(
        size: LoadingIndicatorSize.small,
        color: color,
        message: message,
      );

  /// Medium circular loading indicator for general use
  static Widget medium({
    Color? color,
    String? message,
  }) =>
      LoadingIndicator(
        color: color,
        message: message,
      );

  /// Large loading indicator for full-screen loading states
  static Widget large({
    Color? color,
    String? message,
  }) =>
      LoadingIndicator(
        size: LoadingIndicatorSize.large,
        color: color,
        message: message,
      );

  /// Dots loading indicator for subtle animations
  static Widget dots({
    LoadingIndicatorSize size = LoadingIndicatorSize.medium,
    Color? color,
    String? message,
  }) =>
      LoadingIndicator(
        type: LoadingIndicatorType.dots,
        size: size,
        color: color,
        message: message,
      );

  /// Linear progress indicator for progress bars
  static Widget linear({
    LoadingIndicatorSize size = LoadingIndicatorSize.medium,
    Color? color,
    Color? backgroundColor,
    String? message,
  }) =>
      LoadingIndicator(
        type: LoadingIndicatorType.linear,
        size: size,
        color: color,
        backgroundColor: backgroundColor,
        message: message,
      );
}
