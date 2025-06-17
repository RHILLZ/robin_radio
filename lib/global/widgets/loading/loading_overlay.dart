import 'package:flutter/material.dart';
import 'loading_indicator.dart';

/// Position of the loading content within the overlay
enum LoadingOverlayPosition {
  center,
  top,
  bottom,
  custom,
}

/// Configuration for the loading overlay appearance and behavior
class LoadingOverlayConfig {
  const LoadingOverlayConfig({
    this.backgroundColor,
    this.opacity = 0.7,
    this.blurBackground = false,
    this.position = LoadingOverlayPosition.center,
    this.customPosition,
    this.animationDuration = const Duration(milliseconds: 300),
    this.animationCurve = Curves.easeInOut,
    this.dismissible = false,
    this.barrierDismissible = false,
    this.semanticsLabel,
    this.semanticsValue,
  });

  /// Background color of the overlay (defaults to black)
  final Color? backgroundColor;

  /// Opacity of the background overlay (0.0 to 1.0)
  final double opacity;

  /// Whether to apply a blur effect to the background
  final bool blurBackground;

  /// Position of the loading content
  final LoadingOverlayPosition position;

  /// Custom position when using LoadingOverlayPosition.custom
  final Alignment? customPosition;

  /// Duration of the show/hide animation
  final Duration animationDuration;

  /// Animation curve for show/hide transitions
  final Curve animationCurve;

  /// Whether the overlay can be dismissed programmatically
  final bool dismissible;

  /// Whether tapping outside dismisses the overlay
  final bool barrierDismissible;

  /// Accessibility label for screen readers
  final String? semanticsLabel;

  /// Accessibility value for screen readers
  final String? semanticsValue;

  /// Create a light-themed overlay configuration
  static LoadingOverlayConfig light({
    double opacity = 0.6,
    bool blurBackground = false,
    LoadingOverlayPosition position = LoadingOverlayPosition.center,
    bool dismissible = false,
  }) =>
      LoadingOverlayConfig(
        backgroundColor: Colors.white,
        opacity: opacity,
        blurBackground: blurBackground,
        position: position,
        dismissible: dismissible,
      );

  /// Create a dark-themed overlay configuration
  static LoadingOverlayConfig dark({
    double opacity = 0.8,
    bool blurBackground = false,
    LoadingOverlayPosition position = LoadingOverlayPosition.center,
    bool dismissible = false,
  }) =>
      LoadingOverlayConfig(
        backgroundColor: Colors.black,
        opacity: opacity,
        blurBackground: blurBackground,
        position: position,
        dismissible: dismissible,
      );
}

/// A widget that displays a loading overlay over content, blocking user interaction
class LoadingOverlay extends StatefulWidget {
  const LoadingOverlay({
    required this.isLoading,
    required this.child,
    super.key,
    this.loadingWidget,
    this.message,
    this.messageStyle,
    this.config,
    this.onDismiss,
  });

  /// Whether the loading overlay is currently shown
  final bool isLoading;

  /// The content behind the overlay
  final Widget child;

  /// Custom loading widget (defaults to LoadingIndicator)
  final Widget? loadingWidget;

  /// Optional message to display with the loading indicator
  final String? message;

  /// Style for the loading message
  final TextStyle? messageStyle;

  /// Configuration for the overlay appearance
  final LoadingOverlayConfig? config;

  /// Callback when the overlay is dismissed (if dismissible)
  final VoidCallback? onDismiss;

  @override
  State<LoadingOverlay> createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends State<LoadingOverlay>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late LoadingOverlayConfig _config;

  @override
  void initState() {
    super.initState();
    _initializeConfig();
    _animationController = AnimationController(
      duration: _config.animationDuration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: _config.animationCurve,
      ),
    );

    if (widget.isLoading) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(LoadingOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.config != oldWidget.config) {
      _initializeConfig();
      _animationController.duration = _config.animationDuration;
    }

    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeConfig();
  }

  void _initializeConfig() {
    _config = widget.config ??
        LoadingOverlayConfig(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.black
              : Colors.white,
        );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleDismiss() {
    if (_config.dismissible && widget.onDismiss != null) {
      widget.onDismiss!();
    }
  }

  Widget _buildLoadingContent() {
    var loadingIndicator = widget.loadingWidget ??
        const LoadingIndicator(
          size: LoadingIndicatorSize.large,
        );

    if (widget.message != null) {
      loadingIndicator = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          loadingIndicator,
          const SizedBox(height: 16),
          Text(
            widget.message!,
            style: widget.messageStyle ??
                Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    // Add semantic information for accessibility
    loadingIndicator = Semantics(
      label: _config.semanticsLabel ?? 'Loading',
      value: _config.semanticsValue ?? widget.message,
      liveRegion: true,
      child: loadingIndicator,
    );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: loadingIndicator,
    );
  }

  Alignment _getAlignment() {
    switch (_config.position) {
      case LoadingOverlayPosition.center:
        return Alignment.center;
      case LoadingOverlayPosition.top:
        return Alignment.topCenter;
      case LoadingOverlayPosition.bottom:
        return Alignment.bottomCenter;
      case LoadingOverlayPosition.custom:
        return _config.customPosition ?? Alignment.center;
    }
  }

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          widget.child,
          if (widget.isLoading)
            AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                if (_fadeAnimation.value == 0.0) {
                  return const SizedBox.shrink();
                }

                return Positioned.fill(
                  child: GestureDetector(
                    onTap: _config.barrierDismissible ? _handleDismiss : null,
                    child: ColoredBox(
                      color: (_config.backgroundColor ?? Colors.black)
                          .withOpacity(_config.opacity * _fadeAnimation.value),
                      child: Align(
                        alignment: _getAlignment(),
                        child: Opacity(
                          opacity: _fadeAnimation.value,
                          child: _buildLoadingContent(),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      );
}

/// Static methods for showing modal loading overlays
class LoadingOverlayManager {
  static OverlayEntry? _currentOverlay;

  /// Show a full-screen loading overlay
  static void show(
    BuildContext context, {
    Widget? loadingWidget,
    String? message,
    TextStyle? messageStyle,
    LoadingOverlayConfig? config,
    bool barrierDismissible = false,
    VoidCallback? onDismiss,
  }) {
    hide(); // Remove any existing overlay

    final overlayState = Overlay.of(context);
    final effectiveConfig = config ??
        LoadingOverlayConfig(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.black
              : Colors.white,
          barrierDismissible: barrierDismissible,
        );

    _currentOverlay = OverlayEntry(
      builder: (context) => _ModalLoadingOverlay(
        loadingWidget: loadingWidget,
        message: message,
        messageStyle: messageStyle,
        config: effectiveConfig,
        onDismiss: () {
          hide();
          onDismiss?.call();
        },
      ),
    );

    overlayState.insert(_currentOverlay!);
  }

  /// Hide the current loading overlay
  static void hide() {
    _currentOverlay?.remove();
    _currentOverlay = null;
  }

  /// Check if a loading overlay is currently shown
  static bool get isShowing => _currentOverlay != null;
}

/// Internal modal overlay widget used by LoadingOverlayManager
class _ModalLoadingOverlay extends StatefulWidget {
  const _ModalLoadingOverlay({
    required this.config,
    this.loadingWidget,
    this.message,
    this.messageStyle,
    this.onDismiss,
  });

  final Widget? loadingWidget;
  final String? message;
  final TextStyle? messageStyle;
  final LoadingOverlayConfig config;
  final VoidCallback? onDismiss;

  @override
  State<_ModalLoadingOverlay> createState() => _ModalLoadingOverlayState();
}

class _ModalLoadingOverlayState extends State<_ModalLoadingOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.config.animationDuration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: widget.config.animationCurve,
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) => Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: widget.config.barrierDismissible ? widget.onDismiss : null,
            child: ColoredBox(
              color: (widget.config.backgroundColor ?? Colors.black)
                  .withOpacity(widget.config.opacity * _fadeAnimation.value),
              child: Align(
                alignment: _getAlignment(),
                child: Opacity(
                  opacity: _fadeAnimation.value,
                  child: _buildLoadingContent(context),
                ),
              ),
            ),
          ),
        ),
      );

  Alignment _getAlignment() {
    switch (widget.config.position) {
      case LoadingOverlayPosition.center:
        return Alignment.center;
      case LoadingOverlayPosition.top:
        return Alignment.topCenter;
      case LoadingOverlayPosition.bottom:
        return Alignment.bottomCenter;
      case LoadingOverlayPosition.custom:
        return widget.config.customPosition ?? Alignment.center;
    }
  }

  Widget _buildLoadingContent(BuildContext context) {
    var loadingIndicator = widget.loadingWidget ??
        const LoadingIndicator(
          size: LoadingIndicatorSize.large,
        );

    if (widget.message != null) {
      loadingIndicator = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          loadingIndicator,
          const SizedBox(height: 16),
          Text(
            widget.message!,
            style: widget.messageStyle ??
                Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return Semantics(
      label: widget.config.semanticsLabel ?? 'Loading',
      value: widget.config.semanticsValue ?? widget.message,
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: loadingIndicator,
      ),
    );
  }
}

/// Convenience extensions for easy loading overlay usage
extension LoadingOverlayExtensions on Widget {
  /// Wrap this widget with a LoadingOverlay
  Widget withLoadingOverlay({
    required bool isLoading,
    Widget? loadingWidget,
    String? message,
    TextStyle? messageStyle,
    LoadingOverlayConfig? config,
    VoidCallback? onDismiss,
  }) =>
      LoadingOverlay(
        isLoading: isLoading,
        loadingWidget: loadingWidget,
        message: message,
        messageStyle: messageStyle,
        config: config,
        onDismiss: onDismiss,
        child: this,
      );
}

/// Convenience widgets for common loading overlay patterns
class LoadingOverlays {
  /// Simple loading overlay with circular indicator
  static Widget simple({
    required bool isLoading,
    required Widget child,
    String? message,
  }) =>
      LoadingOverlay(
        isLoading: isLoading,
        message: message,
        child: child,
      );

  /// Loading overlay with custom indicator
  static Widget custom({
    required bool isLoading,
    required Widget child,
    required Widget loadingWidget,
    String? message,
    LoadingOverlayConfig? config,
  }) =>
      LoadingOverlay(
        isLoading: isLoading,
        loadingWidget: loadingWidget,
        message: message,
        config: config,
        child: child,
      );

  /// Dismissible loading overlay
  static Widget dismissible({
    required bool isLoading,
    required Widget child,
    required VoidCallback onDismiss,
    String? message,
    bool barrierDismissible = true,
  }) =>
      LoadingOverlay(
        isLoading: isLoading,
        message: message,
        config: LoadingOverlayConfig(
          dismissible: true,
          barrierDismissible: barrierDismissible,
        ),
        onDismiss: onDismiss,
        child: child,
      );
}
