import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'loading_overlay.dart';

/// Type of progress indicator
enum ProgressIndicatorType {
  /// Linear horizontal progress bar
  linear,

  /// Circular progress indicator
  circular,

  /// Ring-style progress with center text
  ring,

  /// Wave animation progress
  wave,

  /// Step-based progress indicator
  step,
}

/// Position of progress text
enum ProgressTextPosition {
  /// Text centered on indicator
  center,

  /// Text below indicator
  bottom,

  /// Text above indicator
  top,

  /// Text to the right of indicator
  right,

  /// Text to the left of indicator
  left,

  /// No text shown
  none,
}

/// Style of progress indicator
enum ProgressIndicatorStyle {
  /// Material Design style
  material,

  /// iOS Cupertino style
  cupertino,

  /// Custom styling
  custom,
}

/// Configuration for progress indicator appearance and behavior
class ProgressIndicatorConfig {
  /// Creates a progress indicator configuration with customizable appearance and behavior
  const ProgressIndicatorConfig({
    this.type = ProgressIndicatorType.linear,
    this.style = ProgressIndicatorStyle.material,
    this.height = 6.0,
    this.width,
    this.strokeWidth = 4.0,
    this.color,
    this.backgroundColor,
    this.borderRadius,
    this.showPercentage = true,
    this.showTimeRemaining = false,
    this.showProgressText = true,
    this.textPosition = ProgressTextPosition.bottom,
    this.textStyle,
    this.animationDuration = const Duration(milliseconds: 300),
    this.animationCurve = Curves.easeInOut,
    this.semanticsLabel,
    this.semanticsValue,
    this.minHeight = 2.0,
    this.maxHeight = 20.0,
  });

  /// Create a minimal linear progress indicator
  const ProgressIndicatorConfig.linear({
    double height = 6.0,
    Color? color,
    bool showPercentage = true,
  }) : this(
        height: height,
        color: color,
        showPercentage: showPercentage,
      );

  /// Create a circular progress indicator
  const ProgressIndicatorConfig.circular({
    double strokeWidth = 4.0,
    Color? color,
    bool showPercentage = true,
  }) : this(
        type: ProgressIndicatorType.circular,
        strokeWidth: strokeWidth,
        color: color,
        showPercentage: showPercentage,
      );

  /// Create a ring-style progress indicator
  const ProgressIndicatorConfig.ring({
    double strokeWidth = 8.0,
    Color? color,
    bool showPercentage = true,
  }) : this(
        type: ProgressIndicatorType.ring,
        strokeWidth: strokeWidth,
        color: color,
        showPercentage: showPercentage,
        textPosition: ProgressTextPosition.center,
      );

  /// Create a step-based progress indicator
  const ProgressIndicatorConfig.step({
    Color? color,
    bool showPercentage = false,
  }) : this(
        type: ProgressIndicatorType.step,
        color: color,
        showPercentage: showPercentage,
      );

  /// Type of progress indicator
  final ProgressIndicatorType type;

  /// Visual style of the indicator
  final ProgressIndicatorStyle style;

  /// Height for linear indicators
  final double height;

  /// Width for linear indicators (defaults to full width)
  final double? width;

  /// Stroke width for circular indicators
  final double strokeWidth;

  /// Color of the progress fill
  final Color? color;

  /// Background color of the indicator
  final Color? backgroundColor;

  /// Border radius for linear indicators
  final BorderRadius? borderRadius;

  /// Whether to show percentage text
  final bool showPercentage;

  /// Whether to show estimated time remaining
  final bool showTimeRemaining;

  /// Whether to show any progress text
  final bool showProgressText;

  /// Position of progress text relative to indicator
  final ProgressTextPosition textPosition;

  /// Style for progress text
  final TextStyle? textStyle;

  /// Duration of progress animations
  final Duration animationDuration;

  /// Curve for progress animations
  final Curve animationCurve;

  /// Accessibility label
  final String? semanticsLabel;

  /// Accessibility value
  final String? semanticsValue;

  /// Minimum height for responsive design
  final double minHeight;

  /// Maximum height for responsive design
  final double maxHeight;
}

/// Data class for progress information
class ProgressData {
  /// Creates progress data with current and total values
  const ProgressData({
    required this.current,
    required this.total,
    this.message,
    this.startTime,
  });

  /// Current progress value
  final double current;

  /// Total/maximum progress value
  final double total;

  /// Optional message describing current operation
  final String? message;

  /// Time when progress started (for ETA calculation)
  final DateTime? startTime;

  /// Progress as a percentage (0.0 to 1.0)
  double get percentage => total > 0 ? (current / total).clamp(0.0, 1.0) : 0.0;

  /// Progress as a percentage string
  String get percentageText => '${(percentage * 100).round()}%';

  /// Whether progress is complete
  bool get isComplete => current >= total;

  /// Estimated time remaining (requires startTime)
  Duration? get estimatedTimeRemaining {
    if (startTime == null || percentage <= 0 || isComplete) {
      return null;
    }

    final elapsed = DateTime.now().difference(startTime!);
    final estimatedTotal = elapsed.inMilliseconds / percentage;
    final remaining = estimatedTotal - elapsed.inMilliseconds;

    return remaining > 0 ? Duration(milliseconds: remaining.round()) : null;
  }

  /// Formatted time remaining string
  String? get timeRemainingText {
    final eta = estimatedTimeRemaining;
    if (eta == null) {
      return null;
    }

    if (eta.inHours > 0) {
      return '${eta.inHours}h ${eta.inMinutes.remainder(60)}m remaining';
    } else if (eta.inMinutes > 0) {
      return '${eta.inMinutes}m ${eta.inSeconds.remainder(60)}s remaining';
    } else {
      return '${eta.inSeconds}s remaining';
    }
  }

  /// Create a copy with updated values
  ProgressData copyWith({
    double? current,
    double? total,
    String? message,
    DateTime? startTime,
  }) =>
      ProgressData(
        current: current ?? this.current,
        total: total ?? this.total,
        message: message ?? this.message,
        startTime: startTime ?? this.startTime,
      );
}

/// Controller for managing progress state
class ProgressController extends ChangeNotifier {
  /// Creates a progress controller with optional initial data
  ProgressController({
    ProgressData? initialData,
  }) : _data = initialData ?? const ProgressData(current: 0, total: 100);

  ProgressData _data;
  bool _isActive = false;

  /// Current progress data
  ProgressData get data => _data;

  /// Whether progress is currently active
  bool get isActive => _isActive;

  /// Current progress percentage
  double get percentage => _data.percentage;

  /// Whether progress is complete
  bool get isComplete => _data.isComplete;

  /// Update progress with new values
  void updateProgress({
    double? current,
    double? total,
    String? message,
  }) {
    final newData = _data.copyWith(
      current: current,
      total: total,
      message: message,
    );

    if (newData.current != _data.current ||
        newData.total != _data.total ||
        newData.message != _data.message) {
      _data = newData;
      notifyListeners();
    }
  }

  /// Set progress percentage (0.0 to 1.0)
  void setPercentage(double percentage, {String? message}) {
    updateProgress(
      current: (percentage * _data.total).clamp(0.0, _data.total),
      message: message,
    );
  }

  /// Start progress tracking
  void start({double? total, String? message}) {
    _data = ProgressData(
      current: 0,
      total: total ?? _data.total,
      message: message,
      startTime: DateTime.now(),
    );
    _isActive = true;
    notifyListeners();
  }

  /// Complete progress
  void complete({String? message}) {
    _data = _data.copyWith(
      current: _data.total,
      message: message ?? 'Complete',
    );
    _isActive = false;
    notifyListeners();
  }

  /// Reset progress
  void reset() {
    _data = ProgressData(
      current: 0,
      total: _data.total,
    );
    _isActive = false;
    notifyListeners();
  }

  /// Increment progress by a value
  void increment(double value, {String? message}) {
    updateProgress(
      current: (_data.current + value).clamp(0.0, _data.total),
      message: message,
    );
  }
}

/// Advanced progress indicator widget with multiple styles and configurations
class AdvancedProgressIndicator extends StatefulWidget {
  /// Creates an advanced progress indicator
  const AdvancedProgressIndicator({
    required this.progress,
    super.key,
    this.config,
    this.controller,
    this.onCompleted,
  });

  /// Progress data (0.0 to 1.0)
  final double progress;

  /// Configuration for the progress indicator
  final ProgressIndicatorConfig? config;

  /// Optional controller for managing progress
  final ProgressController? controller;

  /// Callback when progress reaches 1.0
  final VoidCallback? onCompleted;

  @override
  State<AdvancedProgressIndicator> createState() =>
      _AdvancedProgressIndicatorState();
}

class _AdvancedProgressIndicatorState extends State<AdvancedProgressIndicator>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  late ProgressIndicatorConfig _config;

  double _lastProgress = 0;
  bool _hasCompleted = false;

  @override
  void initState() {
    super.initState();
    _initializeConfig();
    _animationController = AnimationController(
      duration: _config.animationDuration,
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0,
      end: widget.progress,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: _config.animationCurve,
      ),
    );

    _animationController.forward();
    _lastProgress = widget.progress;

    widget.controller?.addListener(_onControllerUpdate);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeConfig();
  }

  @override
  void didUpdateWidget(AdvancedProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.config != oldWidget.config) {
      _initializeConfig();
      _animationController.duration = _config.animationDuration;
    }

    if (widget.progress != oldWidget.progress) {
      _updateProgress(widget.progress);
    }

    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.removeListener(_onControllerUpdate);
      widget.controller?.addListener(_onControllerUpdate);
    }
  }

  void _initializeConfig() {
    _config = widget.config ??
        ProgressIndicatorConfig(
          color: Theme.of(context).colorScheme.primary,
          backgroundColor:
              Theme.of(context).colorScheme.surfaceContainerHighest,
          textStyle: Theme.of(context).textTheme.bodySmall,
        );
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onControllerUpdate);
    _animationController.dispose();
    super.dispose();
  }

  void _onControllerUpdate() {
    if (widget.controller != null) {
      _updateProgress(widget.controller!.percentage);
    }
  }

  void _updateProgress(double newProgress) {
    final clampedProgress = newProgress.clamp(0.0, 1.0);

    _progressAnimation = Tween<double>(
      begin: _lastProgress,
      end: clampedProgress,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: _config.animationCurve,
      ),
    );

    _animationController
      ..reset()
      ..forward();

    _lastProgress = clampedProgress;

    // Check for completion
    if (clampedProgress >= 1.0 && !_hasCompleted) {
      _hasCompleted = true;
      widget.onCompleted?.call();
    } else if (clampedProgress < 1.0) {
      _hasCompleted = false;
    }
  }

  Widget _buildLinearIndicator() => AnimatedBuilder(
        animation: _progressAnimation,
        builder: (context, child) => Container(
          width: _config.width,
          height: _config.height,
          decoration: BoxDecoration(
            color: _config.backgroundColor,
            borderRadius: _config.borderRadius ??
                BorderRadius.circular(_config.height / 2),
          ),
          child: ClipRRect(
            borderRadius: _config.borderRadius ??
                BorderRadius.circular(_config.height / 2),
            child: LinearProgressIndicator(
              value: _progressAnimation.value,
              backgroundColor: Colors.transparent,
              color: _config.color,
              minHeight: _config.height,
            ),
          ),
        ),
      );

  Widget _buildCircularIndicator() => AnimatedBuilder(
        animation: _progressAnimation,
        builder: (context, child) => SizedBox(
          width: 60,
          height: 60,
          child: CircularProgressIndicator(
            value: _progressAnimation.value,
            strokeWidth: _config.strokeWidth,
            color: _config.color,
            backgroundColor: _config.backgroundColor,
          ),
        ),
      );

  Widget _buildRingIndicator() => AnimatedBuilder(
        animation: _progressAnimation,
        builder: (context, child) => CustomPaint(
          size: const Size(80, 80),
          painter: _RingProgressPainter(
            progress: _progressAnimation.value,
            strokeWidth: _config.strokeWidth,
            progressColor:
                _config.color ?? Theme.of(context).colorScheme.primary,
            backgroundColor: _config.backgroundColor ??
                Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
        ),
      );

  Widget _buildWaveIndicator() => AnimatedBuilder(
        animation: _progressAnimation,
        builder: (context, child) => Container(
          width: _config.width ?? 200,
          height: _config.height.clamp(_config.minHeight, _config.maxHeight),
          decoration: BoxDecoration(
            color: _config.backgroundColor,
            borderRadius: _config.borderRadius ??
                BorderRadius.circular(_config.height / 2),
          ),
          child: ClipRRect(
            borderRadius: _config.borderRadius ??
                BorderRadius.circular(_config.height / 2),
            child: CustomPaint(
              painter: _WaveProgressPainter(
                progress: _progressAnimation.value,
                color: _config.color ?? Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
      );

  Widget _buildStepIndicator() {
    const steps = 5; // Default step count
    final currentStep = (_progressAnimation.value * steps).floor();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(steps, (index) {
        final isActive = index <= currentStep;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 12,
          height: _config.height,
          decoration: BoxDecoration(
            color: isActive
                ? _config.color ?? Theme.of(context).colorScheme.primary
                : _config.backgroundColor ??
                    Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(6),
          ),
        );
      }),
    );
  }

  Widget _buildProgressText() {
    if (!_config.showProgressText) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        final controller = widget.controller;
        var text = '';

        if (_config.showPercentage) {
          final percentage = (_progressAnimation.value * 100).round();
          text = '$percentage%';
        }

        if (_config.showTimeRemaining && controller != null) {
          final timeText = controller.data.timeRemainingText;
          if (timeText != null) {
            text = text.isEmpty ? timeText : '$text • $timeText';
          }
        }

        if (controller?.data.message != null) {
          final message = controller!.data.message!;
          text = text.isEmpty ? message : '$text\n$message';
        }

        return Text(
          text,
          style: _config.textStyle,
          textAlign: TextAlign.center,
        );
      },
    );
  }

  Widget _buildIndicator() {
    switch (_config.type) {
      case ProgressIndicatorType.linear:
        return _buildLinearIndicator();
      case ProgressIndicatorType.circular:
        return _buildCircularIndicator();
      case ProgressIndicatorType.ring:
        return _buildRingIndicator();
      case ProgressIndicatorType.wave:
        return _buildWaveIndicator();
      case ProgressIndicatorType.step:
        return _buildStepIndicator();
    }
  }

  @override
  Widget build(BuildContext context) {
    final indicator = _buildIndicator();
    final progressText = _buildProgressText();

    if (_config.textPosition == ProgressTextPosition.none ||
        !_config.showProgressText) {
      return Semantics(
        label: _config.semanticsLabel ?? 'Progress indicator',
        value: _config.semanticsValue ??
            '${(widget.progress * 100).round()}% complete',
        child: indicator,
      );
    }

    Widget result;
    switch (_config.textPosition) {
      case ProgressTextPosition.center:
        result = Stack(
          alignment: Alignment.center,
          children: [indicator, progressText],
        );
        break;
      case ProgressTextPosition.bottom:
        result = Column(
          mainAxisSize: MainAxisSize.min,
          children: [indicator, const SizedBox(height: 8), progressText],
        );
        break;
      case ProgressTextPosition.top:
        result = Column(
          mainAxisSize: MainAxisSize.min,
          children: [progressText, const SizedBox(height: 8), indicator],
        );
        break;
      case ProgressTextPosition.right:
        result = Row(
          mainAxisSize: MainAxisSize.min,
          children: [indicator, const SizedBox(width: 12), progressText],
        );
        break;
      case ProgressTextPosition.left:
        result = Row(
          mainAxisSize: MainAxisSize.min,
          children: [progressText, const SizedBox(width: 12), indicator],
        );
        break;
      case ProgressTextPosition.none:
        result = indicator;
        break;
    }

    return Semantics(
      label: _config.semanticsLabel ?? 'Progress indicator',
      value: _config.semanticsValue ??
          '${(widget.progress * 100).round()}% complete',
      child: result,
    );
  }
}

/// Custom painter for ring-style progress indicator
class _RingProgressPainter extends CustomPainter {
  const _RingProgressPainter({
    required this.progress,
    required this.strokeWidth,
    required this.progressColor,
    required this.backgroundColor,
  });

  final double progress;
  final double strokeWidth;
  final Color progressColor;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final sweepAngle = 2 * math.pi * progress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2, // Start from top
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingProgressPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Custom painter for wave-style progress indicator
class _WaveProgressPainter extends CustomPainter {
  const _WaveProgressPainter({
    required this.progress,
    required this.color,
  });

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final progressWidth = size.width * progress;

    if (progressWidth > 0) {
      // Create wave path
      final path = Path();
      final waveHeight = size.height * 0.1;
      final waveLength = size.width * 0.2;

      path.moveTo(0, size.height);

      for (var x = 0.0; x <= progressWidth; x += waveLength / 4) {
        final y = size.height / 2 +
            waveHeight * math.sin((x / waveLength + progress) * 2 * math.pi);
        path.lineTo(x, y);
      }

      path
        ..lineTo(progressWidth, size.height)
        ..lineTo(0, size.height)
        ..close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_WaveProgressPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Manager for global progress operations
class ProgressManager {
  ProgressManager._();
  static ProgressManager? _instance;

  /// Singleton instance of ProgressManager
  static ProgressManager get instance => _instance ??= ProgressManager._();

  final Map<String, ProgressController> _controllers = {};
  final Map<String, OverlayEntry> _overlays = {};

  /// Get or create a progress controller
  ProgressController getController(String id) =>
      _controllers.putIfAbsent(id, ProgressController.new);

  /// Remove a progress controller
  void removeController(String id) {
    _controllers[id]?.dispose();
    _controllers.remove(id);
  }

  /// Show progress overlay
  void showProgressOverlay(
    BuildContext context,
    String id, {
    String? message,
    ProgressIndicatorConfig? config,
    bool dismissible = false,
  }) {
    hideProgressOverlay(id); // Remove existing overlay

    final controller = getController(id);
    final overlayState = Overlay.of(context);

    final overlay = OverlayEntry(
      builder: (context) => LoadingOverlay(
        isLoading: true,
        config: LoadingOverlayConfig(
          dismissible: dismissible,
        ),
        loadingWidget: AdvancedProgressIndicator(
          progress: 0,
          controller: controller,
          config: config,
        ),
        child: Container(),
      ),
    );

    _overlays[id] = overlay;
    overlayState.insert(overlay);
  }

  /// Hide progress overlay
  void hideProgressOverlay(String id) {
    final overlay = _overlays.remove(id);
    overlay?.remove();
  }

  /// Update progress for a specific operation
  void updateProgress(
    String id, {
    double? current,
    double? total,
    String? message,
  }) {
    final controller = _controllers[id];
    controller?.updateProgress(
      current: current,
      total: total,
      message: message,
    );
  }

  /// Start progress tracking
  void startProgress(
    String id, {
    double total = 100,
    String? message,
  }) {
    getController(id).start(total: total, message: message);
  }

  /// Complete progress
  void completeProgress(String id, {String? message}) {
    final controller = _controllers[id];
    controller?.complete(message: message);
  }

  /// Clear all progress operations
  void clearAll() {
    for (final overlay in _overlays.values) {
      overlay.remove();
    }
    _overlays.clear();

    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
  }
}

/// Convenience extensions for easy progress indicator usage
extension ProgressIndicatorExtensions on Widget {
  /// Wrap this widget with a progress overlay
  Widget withProgressOverlay({
    required bool isLoading,
    double progress = 0,
    ProgressIndicatorConfig? config,
    ProgressController? controller,
    String? message,
  }) =>
      LoadingOverlay(
        isLoading: isLoading,
        loadingWidget: AdvancedProgressIndicator(
          progress: progress,
          config: config,
          controller: controller,
        ),
        message: message,
        child: this,
      );
}

/// Ready-to-use progress indicator widgets
/// This class provides static factory methods for common progress indicators
class ProgressIndicators {
  /// Private constructor to prevent instantiation
  ProgressIndicators._();
  /// Simple linear progress indicator
  static Widget linear({
    required double progress,
    double height = 6.0,
    Color? color,
    bool showPercentage = true,
  }) =>
      AdvancedProgressIndicator(
        progress: progress,
        config: ProgressIndicatorConfig.linear(
          height: height,
          color: color,
          showPercentage: showPercentage,
        ),
      );

  /// Simple circular progress indicator
  static Widget circular({
    required double progress,
    double strokeWidth = 4.0,
    Color? color,
    bool showPercentage = true,
  }) =>
      AdvancedProgressIndicator(
        progress: progress,
        config: ProgressIndicatorConfig.circular(
          strokeWidth: strokeWidth,
          color: color,
          showPercentage: showPercentage,
        ),
      );

  /// Ring progress indicator with center text
  static Widget ring({
    required double progress,
    double strokeWidth = 8.0,
    Color? color,
    bool showPercentage = true,
  }) =>
      AdvancedProgressIndicator(
        progress: progress,
        config: ProgressIndicatorConfig.ring(
          strokeWidth: strokeWidth,
          color: color,
          showPercentage: showPercentage,
        ),
      );

  /// Step-based progress indicator
  static Widget steps({
    required double progress,
    Color? color,
  }) =>
      AdvancedProgressIndicator(
        progress: progress,
        config: ProgressIndicatorConfig.step(
          color: color,
        ),
      );

  /// Progress indicator with time estimation
  static Widget withTimeEstimate({
    required ProgressController controller,
    ProgressIndicatorType type = ProgressIndicatorType.linear,
    Color? color,
  }) =>
      AdvancedProgressIndicator(
        progress: 0, // Controller manages progress
        controller: controller,
        config: ProgressIndicatorConfig(
          type: type,
          color: color,
          showTimeRemaining: true,
        ),
      );
}
