import 'package:flutter/material.dart';

/// Direction of the shimmer animation
enum ShimmerDirection {
  leftToRight,
  rightToLeft,
  topToBottom,
  bottomToTop,
}

/// Shimmer effect configuration
class ShimmerConfig {
  const ShimmerConfig({
    this.baseColor,
    this.highlightColor,
    this.direction = ShimmerDirection.leftToRight,
    this.duration = const Duration(milliseconds: 1500),
    this.curve = Curves.easeInOut,
    this.enabled = true,
  });

  /// Base color of the shimmer (background)
  final Color? baseColor;

  /// Highlight color that moves across the shimmer
  final Color? highlightColor;

  /// Direction of the shimmer animation
  final ShimmerDirection direction;

  /// Duration of one complete shimmer cycle
  final Duration duration;

  /// Animation curve for the shimmer effect
  final Curve curve;

  /// Whether the shimmer animation is enabled
  final bool enabled;

  /// Create a light theme shimmer configuration
  static ShimmerConfig light({
    Color? baseColor,
    Color? highlightColor,
    ShimmerDirection direction = ShimmerDirection.leftToRight,
    Duration duration = const Duration(milliseconds: 1500),
  }) =>
      ShimmerConfig(
        baseColor: baseColor ?? Colors.grey.shade300,
        highlightColor: highlightColor ?? Colors.grey.shade100,
        direction: direction,
        duration: duration,
      );

  /// Create a dark theme shimmer configuration
  static ShimmerConfig dark({
    Color? baseColor,
    Color? highlightColor,
    ShimmerDirection direction = ShimmerDirection.leftToRight,
    Duration duration = const Duration(milliseconds: 1500),
  }) =>
      ShimmerConfig(
        baseColor: baseColor ?? Colors.grey.shade700,
        highlightColor: highlightColor ?? Colors.grey.shade600,
        direction: direction,
        duration: duration,
      );

  /// Create a shimmer configuration from theme
  static ShimmerConfig fromTheme(
    BuildContext context, {
    ShimmerDirection direction = ShimmerDirection.leftToRight,
    Duration duration = const Duration(milliseconds: 1500),
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return ShimmerConfig(
      baseColor: isDark
          ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      highlightColor: isDark
          ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.1)
          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
      direction: direction,
      duration: duration,
    );
  }
}

/// A widget that creates a shimmer effect animation
class ShimmerEffect extends StatefulWidget {
  const ShimmerEffect({
    required this.child,
    super.key,
    this.config,
    this.width,
    this.height,
  });

  /// The widget to apply the shimmer effect to
  final Widget child;

  /// Shimmer configuration (uses theme-based defaults if null)
  final ShimmerConfig? config;

  /// Optional width constraint
  final double? width;

  /// Optional height constraint
  final double? height;

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late ShimmerConfig _config;

  @override
  void initState() {
    super.initState();
    _initializeConfig();
    _controller = AnimationController(
      duration: _config.duration,
      vsync: this,
    );

    if (_config.enabled) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(ShimmerEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.config != oldWidget.config) {
      _initializeConfig();
      _controller.duration = _config.duration;

      if (_config.enabled && !_controller.isAnimating) {
        _controller.repeat();
      } else if (!_config.enabled && _controller.isAnimating) {
        _controller.stop();
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeConfig();
  }

  void _initializeConfig() {
    _config = widget.config ?? ShimmerConfig.fromTheme(context);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_config.enabled) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => _ShimmerPainter(
        animation: CurvedAnimation(
          parent: _controller,
          curve: _config.curve,
        ),
        config: _config,
        width: widget.width,
        height: widget.height,
        child: widget.child,
      ),
    );
  }
}

/// Internal widget that applies the shimmer gradient paint
class _ShimmerPainter extends StatelessWidget {
  const _ShimmerPainter({
    required this.animation,
    required this.config,
    required this.child,
    this.width,
    this.height,
  });

  final Animation<double> animation;
  final ShimmerConfig config;
  final Widget child;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _ShimmerGradientPainter(
          animation: animation,
          config: config,
        ),
        child: SizedBox(
          width: width,
          height: height,
          child: child,
        ),
      );
}

/// Custom painter that creates the shimmer gradient effect
class _ShimmerGradientPainter extends CustomPainter {
  _ShimmerGradientPainter({
    required this.animation,
    required this.config,
  }) : super(repaint: animation);

  final Animation<double> animation;
  final ShimmerConfig config;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..blendMode = BlendMode.srcATop;

    final progress = animation.value;
    final gradientColors = [
      config.baseColor!,
      config.highlightColor!,
      config.baseColor!,
    ];

    Gradient gradient;

    switch (config.direction) {
      case ShimmerDirection.leftToRight:
        gradient = LinearGradient(
          begin: Alignment(-1.0 + (progress * 3), 0),
          end: Alignment(progress * 3, 0),
          colors: gradientColors,
          stops: const [0.0, 0.5, 1.0],
        );
        break;

      case ShimmerDirection.rightToLeft:
        gradient = LinearGradient(
          begin: Alignment(1.0 - (progress * 3), 0),
          end: Alignment(1.0 - progress * 3 - 2.0, 0),
          colors: gradientColors,
          stops: const [0.0, 0.5, 1.0],
        );
        break;

      case ShimmerDirection.topToBottom:
        gradient = LinearGradient(
          begin: Alignment(0, -1.0 + (progress * 3)),
          end: Alignment(0, progress * 3),
          colors: gradientColors,
          stops: const [0.0, 0.5, 1.0],
        );
        break;

      case ShimmerDirection.bottomToTop:
        gradient = LinearGradient(
          begin: Alignment(0, 1.0 - (progress * 3)),
          end: Alignment(0, 1.0 - progress * 3 - 2.0),
          colors: gradientColors,
          stops: const [0.0, 0.5, 1.0],
        );
        break;
    }

    paint.shader =
        gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

/// Convenience widget that combines skeleton loading with shimmer effect
class ShimmerSkeleton extends StatelessWidget {
  const ShimmerSkeleton({
    required this.child,
    super.key,
    this.config,
    this.width,
    this.height,
    this.enabled = true,
  });

  /// The skeleton widget to apply shimmer to
  final Widget child;

  /// Shimmer configuration
  final ShimmerConfig? config;

  /// Width constraint
  final double? width;

  /// Height constraint
  final double? height;

  /// Whether shimmer is enabled
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return child;
    }

    return ShimmerEffect(
      config: config,
      width: width,
      height: height,
      child: child,
    );
  }
}

/// Extension to add shimmer effect to any widget
extension ShimmerExtension on Widget {
  /// Apply a shimmer effect to this widget
  Widget shimmer({
    ShimmerConfig? config,
    double? width,
    double? height,
    bool enabled = true,
  }) =>
      ShimmerSkeleton(
        config: config,
        width: width,
        height: height,
        enabled: enabled,
        child: this,
      );

  /// Apply a light-themed shimmer effect
  Widget shimmerLight({
    ShimmerDirection direction = ShimmerDirection.leftToRight,
    Duration duration = const Duration(milliseconds: 1500),
    double? width,
    double? height,
    bool enabled = true,
  }) =>
      ShimmerSkeleton(
        config: ShimmerConfig.light(
          direction: direction,
          duration: duration,
        ),
        width: width,
        height: height,
        enabled: enabled,
        child: this,
      );

  /// Apply a dark-themed shimmer effect
  Widget shimmerDark({
    ShimmerDirection direction = ShimmerDirection.leftToRight,
    Duration duration = const Duration(milliseconds: 1500),
    double? width,
    double? height,
    bool enabled = true,
  }) =>
      ShimmerSkeleton(
        config: ShimmerConfig.dark(
          direction: direction,
          duration: duration,
        ),
        width: width,
        height: height,
        enabled: enabled,
        child: this,
      );
}

/// Shimmer-enabled skeleton components with built-in animations
class AnimatedSkeletons {
  /// Animated skeleton text
  static Widget text({
    double? width,
    double? height = 16,
    Color? color,
    int lines = 1,
    ShimmerConfig? shimmerConfig,
  }) =>
      ShimmerSkeleton(
        config: shimmerConfig,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(
            lines,
            (index) => Container(
              width: width ?? (index == lines - 1 ? 120 : double.infinity),
              height: height,
              margin: EdgeInsets.only(bottom: index < lines - 1 ? 6 : 0),
              decoration: BoxDecoration(
                color: color ?? Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      );

  /// Animated skeleton list item
  static Widget listItem({
    Color? color,
    ShimmerConfig? shimmerConfig,
    bool showLeading = true,
    bool showTrailing = true,
  }) =>
      ShimmerSkeleton(
        config: shimmerConfig,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              if (showLeading) ...[
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color ?? Colors.grey.shade300,
                  ),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 16,
                      decoration: BoxDecoration(
                        color: color ?? Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 120,
                      height: 14,
                      decoration: BoxDecoration(
                        color: color ?? Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ),
              if (showTrailing) ...[
                const SizedBox(width: 16),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: color ?? Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ],
          ),
        ),
      );

  /// Animated skeleton card
  static Widget card({
    double? width,
    double? height = 200,
    Color? color,
    ShimmerConfig? shimmerConfig,
  }) =>
      ShimmerSkeleton(
        config: shimmerConfig,
        child: Container(
          width: width,
          height: height,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: height != null ? height * 0.6 : 120,
                decoration: BoxDecoration(
                  color: color ?? Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                height: 16,
                decoration: BoxDecoration(
                  color: color ?? Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 100,
                height: 14,
                decoration: BoxDecoration(
                  color: color ?? Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        ),
      );
}
