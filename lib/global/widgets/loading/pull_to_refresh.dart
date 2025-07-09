import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'loading_indicator.dart';

/// Configuration for pull-to-refresh behavior and appearance
class PullToRefreshConfig {
  const PullToRefreshConfig({
    this.displacement = 40.0,
    this.strokeWidth = 2.0,
    this.color,
    this.backgroundColor,
    this.semanticsLabel,
    this.semanticsValue,
    this.triggerMode = RefreshIndicatorTriggerMode.onEdge,
    this.edgeOffset = 0.0,
    this.notificationPredicate = defaultScrollNotificationPredicate,
    this.loadingIndicatorType = LoadingIndicatorType.circular,
    this.loadingIndicatorSize = LoadingIndicatorSize.medium,
    this.showRefreshMessage = false,
    this.refreshMessage = 'Pull to refresh',
    this.releaseMessage = 'Release to refresh',
    this.refreshingMessage = 'Refreshing...',
    this.messageStyle,
    this.animationDuration = const Duration(milliseconds: 300),
    this.platformStyle = PullToRefreshPlatformStyle.material,
  });

  /// Distance from the top where the refresh indicator appears
  final double displacement;

  /// Width of the refresh indicator stroke
  final double strokeWidth;

  /// Color of the refresh indicator
  final Color? color;

  /// Background color of the refresh indicator
  final Color? backgroundColor;

  /// Accessibility label for screen readers
  final String? semanticsLabel;

  /// Accessibility value for screen readers
  final String? semanticsValue;

  /// When the refresh action should be triggered
  final RefreshIndicatorTriggerMode triggerMode;

  /// Offset from the edge where refresh can be triggered
  final double edgeOffset;

  /// Predicate to determine if scroll notifications should trigger refresh
  final ScrollNotificationPredicate notificationPredicate;

  /// Type of loading indicator to show
  final LoadingIndicatorType loadingIndicatorType;

  /// Size of the loading indicator
  final LoadingIndicatorSize loadingIndicatorSize;

  /// Whether to show text messages during refresh states
  final bool showRefreshMessage;

  /// Message shown when user can pull to refresh
  final String refreshMessage;

  /// Message shown when user can release to refresh
  final String releaseMessage;

  /// Message shown while refreshing
  final String refreshingMessage;

  /// Style for refresh messages
  final TextStyle? messageStyle;

  /// Duration of animations
  final Duration animationDuration;

  /// Platform-specific styling
  final PullToRefreshPlatformStyle platformStyle;

  /// Create iOS-style configuration
  static PullToRefreshConfig ios({
    Color? color,
    String? refreshMessage,
    bool showRefreshMessage = false,
  }) =>
      PullToRefreshConfig(
        platformStyle: PullToRefreshPlatformStyle.cupertino,
        color: color,
        refreshMessage: refreshMessage ?? 'Pull to refresh',
        showRefreshMessage: showRefreshMessage,
        animationDuration: const Duration(milliseconds: 400),
      );

  /// Create Material Design configuration
  static PullToRefreshConfig material({
    Color? color,
    Color? backgroundColor,
    String? refreshMessage,
    bool showRefreshMessage = true,
  }) =>
      PullToRefreshConfig(
        color: color,
        backgroundColor: backgroundColor,
        refreshMessage: refreshMessage ?? 'Pull to refresh',
        showRefreshMessage: showRefreshMessage,
      );
}

/// Platform-specific styling options
enum PullToRefreshPlatformStyle {
  /// Material Design style
  material,

  /// iOS/Cupertino style
  cupertino,

  /// Custom style using LoadingIndicator
  custom,
}

/// State of the pull-to-refresh interaction
enum PullToRefreshState {
  idle,
  pulling,
  armed,
  refreshing,
  done,
}

/// A customizable pull-to-refresh widget that wraps scrollable content
class PullToRefresh extends StatefulWidget {
  const PullToRefresh({
    required this.onRefresh,
    required this.child,
    super.key,
    this.config,
    this.header,
    this.enablePullDown = true,
    this.enablePullUp = false,
    this.onLoading,
  });

  /// Callback triggered when user pulls down to refresh
  final Future<void> Function() onRefresh;

  /// Callback triggered when user pulls up to load more (optional)
  final Future<void> Function()? onLoading;

  /// The scrollable child widget
  final Widget child;

  /// Configuration for the pull-to-refresh behavior
  final PullToRefreshConfig? config;

  /// Custom header widget (overrides default indicators)
  final Widget? header;

  /// Whether pull-down refresh is enabled
  final bool enablePullDown;

  /// Whether pull-up loading is enabled
  final bool enablePullUp;

  @override
  State<PullToRefresh> createState() => _PullToRefreshState();
}

class _PullToRefreshState extends State<PullToRefresh>
    with TickerProviderStateMixin {
  late PullToRefreshConfig _config;
  late AnimationController _animationController;
  late Animation<double> _animation;

  PullToRefreshState _refreshState = PullToRefreshState.idle;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _initializeConfig();
    _animationController = AnimationController(
      duration: _config.animationDuration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeConfig();
  }

  @override
  void didUpdateWidget(PullToRefresh oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.config != oldWidget.config) {
      _initializeConfig();
    }
  }

  void _initializeConfig() {
    _config = widget.config ??
        PullToRefreshConfig(
          color: Theme.of(context).colorScheme.primary,
          backgroundColor: Theme.of(context).colorScheme.surface,
          messageStyle: Theme.of(context).textTheme.bodyMedium,
        );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
      _refreshState = PullToRefreshState.refreshing;
    });

    _animationController.forward();

    try {
      await widget.onRefresh();
      setState(() {
        _refreshState = PullToRefreshState.done;
      });

      // Brief delay to show completion state
      await Future<void>.delayed(const Duration(milliseconds: 300));
    } finally {
      _animationController.reverse();
      setState(() {
        _isRefreshing = false;
        _refreshState = PullToRefreshState.idle;
      });
    }
  }

  Widget _buildCustomRefreshIndicator() => AnimatedBuilder(
        animation: _animation,
        builder: (context, child) => Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LoadingIndicator(
                type: _config.loadingIndicatorType,
                size: _config.loadingIndicatorSize,
                color: _config.color,
              ),
              if (_config.showRefreshMessage) ...[
                const SizedBox(height: 8),
                Text(
                  _getRefreshMessage(),
                  style: _config.messageStyle,
                ),
              ],
            ],
          ),
        ),
      );

  String _getRefreshMessage() {
    switch (_refreshState) {
      case PullToRefreshState.idle:
      case PullToRefreshState.pulling:
        return _config.refreshMessage;
      case PullToRefreshState.armed:
        return _config.releaseMessage;
      case PullToRefreshState.refreshing:
        return _config.refreshingMessage;
      case PullToRefreshState.done:
        return 'Complete';
    }
  }

  Widget _buildMaterialRefreshIndicator() => RefreshIndicator(
        onRefresh: _handleRefresh,
        displacement: _config.displacement,
        strokeWidth: _config.strokeWidth,
        color: _config.color,
        backgroundColor: _config.backgroundColor,
        semanticsLabel: _config.semanticsLabel,
        semanticsValue: _config.semanticsValue,
        triggerMode: _config.triggerMode,
        edgeOffset: _config.edgeOffset,
        notificationPredicate: _config.notificationPredicate,
        child: widget.child,
      );

  Widget _buildCupertinoRefreshIndicator() => CustomScrollView(
        slivers: [
          CupertinoSliverRefreshControl(
            onRefresh: _handleRefresh,
            builder: (
              context,
              refreshState,
              pulledExtent,
              refreshTriggerPullDistance,
              refreshIndicatorExtent,
            ) =>
                _buildCustomRefreshIndicator(),
          ),
          SliverToBoxAdapter(child: widget.child),
        ],
      );

  @override
  Widget build(BuildContext context) {
    if (widget.header != null) {
      // Custom header implementation
      return RefreshIndicator(
        onRefresh: _handleRefresh,
        child: widget.child,
      );
    }

    switch (_config.platformStyle) {
      case PullToRefreshPlatformStyle.material:
        return _buildMaterialRefreshIndicator();
      case PullToRefreshPlatformStyle.cupertino:
        return _buildCupertinoRefreshIndicator();
      case PullToRefreshPlatformStyle.custom:
        return RefreshIndicator(
          onRefresh: _handleRefresh,
          displacement: _config.displacement,
          child: widget.child,
        );
    }
  }
}

/// Convenience extensions for easy pull-to-refresh usage
extension PullToRefreshExtensions on Widget {
  /// Wrap this widget with pull-to-refresh functionality
  Widget withPullToRefresh({
    required Future<void> Function() onRefresh,
    PullToRefreshConfig? config,
    bool enablePullDown = true,
    bool enablePullUp = false,
    Future<void> Function()? onLoading,
  }) =>
      PullToRefresh(
        onRefresh: onRefresh,
        config: config,
        enablePullDown: enablePullDown,
        enablePullUp: enablePullUp,
        onLoading: onLoading,
        child: this,
      );

  /// Wrap with Material Design pull-to-refresh
  Widget withMaterialRefresh({
    required Future<void> Function() onRefresh,
    Color? color,
    String? message,
  }) =>
      PullToRefresh(
        onRefresh: onRefresh,
        config: PullToRefreshConfig.material(
          color: color,
          refreshMessage: message,
        ),
        child: this,
      );

  /// Wrap with iOS-style pull-to-refresh
  Widget withCupertinoRefresh({
    required Future<void> Function() onRefresh,
    Color? color,
    String? message,
  }) =>
      PullToRefresh(
        onRefresh: onRefresh,
        config: PullToRefreshConfig.ios(
          color: color,
          refreshMessage: message,
        ),
        child: this,
      );
}

/// Ready-to-use pull-to-refresh widgets for common scenarios
class PullToRefreshWidgets {
  /// Simple Material Design pull-to-refresh
  static Widget material({
    required Future<void> Function() onRefresh,
    required Widget child,
    Color? color,
    String? message,
  }) =>
      PullToRefresh(
        onRefresh: onRefresh,
        config: PullToRefreshConfig.material(
          color: color,
          refreshMessage: message,
        ),
        child: child,
      );

  /// Simple iOS-style pull-to-refresh
  static Widget ios({
    required Future<void> Function() onRefresh,
    required Widget child,
    Color? color,
    String? message,
  }) =>
      PullToRefresh(
        onRefresh: onRefresh,
        config: PullToRefreshConfig.ios(
          color: color,
          refreshMessage: message,
        ),
        child: child,
      );

  /// Custom pull-to-refresh with LoadingIndicator
  static Widget custom({
    required Future<void> Function() onRefresh,
    required Widget child,
    LoadingIndicatorType indicatorType = LoadingIndicatorType.circular,
    LoadingIndicatorSize indicatorSize = LoadingIndicatorSize.medium,
    Color? color,
    String? message,
    bool showMessage = true,
  }) =>
      PullToRefresh(
        onRefresh: onRefresh,
        config: PullToRefreshConfig(
          platformStyle: PullToRefreshPlatformStyle.custom,
          loadingIndicatorType: indicatorType,
          loadingIndicatorSize: indicatorSize,
          color: color,
          refreshMessage: message ?? 'Pull to refresh',
          showRefreshMessage: showMessage,
        ),
        child: child,
      );

  /// Pull-to-refresh with both refresh and load more
  static Widget withLoadMore({
    required Future<void> Function() onRefresh,
    required Future<void> Function() onLoading,
    required Widget child,
    PullToRefreshConfig? config,
  }) =>
      PullToRefresh(
        onRefresh: onRefresh,
        onLoading: onLoading,
        config: config,
        enablePullUp: true,
        child: child,
      );
}

/// A specialized pull-to-refresh for lists with built-in empty state handling
class ListPullToRefresh extends StatelessWidget {
  const ListPullToRefresh({
    required this.onRefresh,
    required this.itemCount,
    required this.itemBuilder,
    super.key,
    this.config,
    this.emptyStateWidget,
    this.emptyStateMessage = 'No items found',
    this.padding,
    this.physics,
    this.controller,
  });

  /// Refresh callback
  final Future<void> Function() onRefresh;

  /// Number of items in the list
  final int itemCount;

  /// Builder for list items
  final Widget Function(BuildContext context, int index) itemBuilder;

  /// Pull-to-refresh configuration
  final PullToRefreshConfig? config;

  /// Custom empty state widget
  final Widget? emptyStateWidget;

  /// Message to show when list is empty
  final String emptyStateMessage;

  /// Padding for the list
  final EdgeInsetsGeometry? padding;

  /// Physics for the scroll view
  final ScrollPhysics? physics;

  /// Scroll controller
  final ScrollController? controller;

  Widget _buildEmptyState(BuildContext context) =>
      emptyStateWidget ??
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              emptyStateMessage,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (itemCount == 0) {
      return PullToRefresh(
        onRefresh: onRefresh,
        config: config,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: _buildEmptyState(context),
          ),
        ),
      );
    }

    return PullToRefresh(
      onRefresh: onRefresh,
      config: config,
      child: ListView.builder(
        controller: controller,
        physics: physics,
        padding: padding,
        itemCount: itemCount,
        itemBuilder: itemBuilder,
      ),
    );
  }
}
