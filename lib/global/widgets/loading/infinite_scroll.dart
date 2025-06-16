import 'dart:async';
import 'package:flutter/material.dart';
import 'loading_indicator.dart';
import 'skeleton_loader.dart';

/// Status of infinite scroll loading
enum InfiniteScrollStatus {
  idle,
  loading,
  completed,
  error,
}

/// Configuration for infinite scroll behavior
class InfiniteScrollConfig {
  const InfiniteScrollConfig({
    this.threshold = 200.0,
    this.loadingIndicatorType = LoadingIndicatorType.circular,
    this.loadingIndicatorSize = LoadingIndicatorSize.medium,
    this.loadingIndicatorColor,
    this.showSkeletonLoader = false,
    this.skeletonItemCount = 3,
    this.skeletonHeight = 72.0,
    this.loadingMessage,
    this.completedMessage = 'No more items',
    this.errorMessage = 'Failed to load more items',
    this.retryMessage = 'Tap to retry',
    this.messageStyle,
    this.padding = const EdgeInsets.all(16),
    this.minLoadingDelay = const Duration(milliseconds: 500),
    this.throttleDuration = const Duration(milliseconds: 300),
    this.enableVibration = false,
    this.semanticsLabel,
  });

  /// Distance from bottom to trigger loading (in pixels)
  final double threshold;

  /// Type of loading indicator to show
  final LoadingIndicatorType loadingIndicatorType;

  /// Size of the loading indicator
  final LoadingIndicatorSize loadingIndicatorSize;

  /// Color of the loading indicator
  final Color? loadingIndicatorColor;

  /// Whether to show skeleton loader instead of spinner
  final bool showSkeletonLoader;

  /// Number of skeleton items to show
  final int skeletonItemCount;

  /// Height of each skeleton item
  final double skeletonHeight;

  /// Message to show while loading
  final String? loadingMessage;

  /// Message to show when all items are loaded
  final String completedMessage;

  /// Message to show on error
  final String errorMessage;

  /// Message to show for retry action
  final String retryMessage;

  /// Style for status messages
  final TextStyle? messageStyle;

  /// Padding around loading indicators
  final EdgeInsets padding;

  /// Minimum time to show loading state
  final Duration minLoadingDelay;

  /// Throttle duration to prevent rapid triggers
  final Duration throttleDuration;

  /// Whether to provide haptic feedback
  final bool enableVibration;

  /// Accessibility label
  final String? semanticsLabel;

  /// Create a minimal configuration
  static InfiniteScrollConfig minimal() => const InfiniteScrollConfig(
        threshold: 100,
        padding: EdgeInsets.all(8),
      );

  /// Create a skeleton-based configuration
  static InfiniteScrollConfig skeleton({
    int itemCount = 3,
    double itemHeight = 72.0,
    double threshold = 200.0,
  }) =>
      InfiniteScrollConfig(
        threshold: threshold,
        showSkeletonLoader: true,
        skeletonItemCount: itemCount,
        skeletonHeight: itemHeight,
      );

  /// Create a configuration with messages
  static InfiniteScrollConfig withMessages({
    String? loadingMessage,
    String? completedMessage,
    String? errorMessage,
  }) =>
      InfiniteScrollConfig(
        loadingMessage: loadingMessage ?? 'Loading more...',
        completedMessage: completedMessage ?? 'No more items',
        errorMessage: errorMessage ?? 'Failed to load more items',
      );
}

/// Controller for managing infinite scroll state and pagination
class InfiniteScrollController extends ChangeNotifier {
  InfiniteScrollController({
    int initialPage = 1,
    this.pageSize = 20,
  }) : _currentPage = initialPage;

  /// Current page number
  int _currentPage;

  /// Items per page
  final int pageSize;

  /// Current loading status
  InfiniteScrollStatus _status = InfiniteScrollStatus.idle;

  /// Whether there are more items to load
  bool _hasMore = true;

  /// Error message if loading failed
  String? _errorMessage;

  /// Timer for throttling requests
  Timer? _throttleTimer;

  int get currentPage => _currentPage;
  int get initialPage => _currentPage;
  InfiniteScrollStatus get status => _status;
  bool get hasMore => _hasMore;
  bool get isLoading => _status == InfiniteScrollStatus.loading;
  bool get isCompleted => _status == InfiniteScrollStatus.completed;
  bool get isError => _status == InfiniteScrollStatus.error;
  bool get isIdle => _status == InfiniteScrollStatus.idle;
  String? get errorMessage => _errorMessage;

  /// Load next page of data
  Future<bool> loadMore(
    Future<List<dynamic>> Function(int page, int pageSize) loader,
  ) async {
    if (_status == InfiniteScrollStatus.loading || !_hasMore) {
      return false;
    }

    _setStatus(InfiniteScrollStatus.loading);

    try {
      final items = await loader(_currentPage, pageSize);

      if (items.isEmpty || items.length < pageSize) {
        _hasMore = false;
        _setStatus(InfiniteScrollStatus.completed);
      } else {
        _currentPage++;
        _setStatus(InfiniteScrollStatus.idle);
      }

      return items.isNotEmpty;
    } catch (error) {
      _errorMessage = error.toString();
      _setStatus(InfiniteScrollStatus.error);
      return false;
    }
  }

  /// Reset to initial state
  void reset() {
    _currentPage = 1;
    _hasMore = true;
    _errorMessage = null;
    _setStatus(InfiniteScrollStatus.idle);
  }

  /// Retry loading after error
  Future<bool> retry(
    Future<List<dynamic>> Function(int page, int pageSize) loader,
  ) async {
    if (_status != InfiniteScrollStatus.error) return false;
    return loadMore(loader);
  }

  /// Mark as completed (no more items)
  void markCompleted() {
    _hasMore = false;
    _setStatus(InfiniteScrollStatus.completed);
  }

  /// Throttled trigger for loading
  void throttledTrigger(VoidCallback onTrigger, Duration throttleDuration) {
    _throttleTimer?.cancel();
    _throttleTimer = Timer(throttleDuration, onTrigger);
  }

  void _setStatus(InfiniteScrollStatus status) {
    if (_status != status) {
      _status = status;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _throttleTimer?.cancel();
    super.dispose();
  }
}

/// Widget that adds infinite scrolling capability to any scrollable widget
class InfiniteScroll extends StatefulWidget {
  const InfiniteScroll({
    required this.child,
    required this.onLoadMore,
    super.key,
    this.controller,
    this.config,
    this.scrollController,
    this.onError,
    this.onCompleted,
  });

  /// The scrollable child widget
  final Widget child;

  /// Callback to load more data
  final Future<bool> Function() onLoadMore;

  /// Controller for managing infinite scroll state
  final InfiniteScrollController? controller;

  /// Configuration for infinite scroll behavior
  final InfiniteScrollConfig? config;

  /// Scroll controller for the child widget
  final ScrollController? scrollController;

  /// Callback when loading fails
  final void Function(String error)? onError;

  /// Callback when all items are loaded
  final VoidCallback? onCompleted;

  @override
  State<InfiniteScroll> createState() => _InfiniteScrollState();
}

class _InfiniteScrollState extends State<InfiniteScroll> {
  late InfiniteScrollController _controller;
  late ScrollController _scrollController;
  late InfiniteScrollConfig _config;
  Timer? _loadingTimer;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? InfiniteScrollController();
    _scrollController = widget.scrollController ?? ScrollController();
    _initializeConfig();

    _scrollController.addListener(_onScroll);
    _controller.addListener(_onControllerChange);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeConfig();
  }

  @override
  void didUpdateWidget(InfiniteScroll oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.controller != oldWidget.controller) {
      _controller.removeListener(_onControllerChange);
      _controller = widget.controller ?? InfiniteScrollController();
      _controller.addListener(_onControllerChange);
    }

    if (widget.config != oldWidget.config) {
      _initializeConfig();
    }
  }

  void _initializeConfig() {
    _config = widget.config ??
        InfiniteScrollConfig(
          loadingIndicatorColor: Theme.of(context).colorScheme.primary,
          messageStyle: Theme.of(context).textTheme.bodyMedium,
        );
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _controller.removeListener(_onControllerChange);

    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    if (widget.controller == null) {
      _controller.dispose();
    }

    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final threshold = _config.threshold;

    if (currentScroll >= maxScroll - threshold &&
        _controller.hasMore &&
        !_controller.isLoading) {
      _triggerLoadMore();
    }
  }

  void _onControllerChange() {
    if (_controller.isError && widget.onError != null) {
      widget.onError!(_controller.errorMessage ?? 'Unknown error');
    }

    if (_controller.isCompleted && widget.onCompleted != null) {
      widget.onCompleted!();
    }
  }

  void _triggerLoadMore() {
    _controller.throttledTrigger(
      () async {
        if (_config.enableVibration) {
          // Add haptic feedback if available
          // HapticFeedback.lightImpact();
        }

        _loadingTimer = Timer(_config.minLoadingDelay, () {});

        try {
          await widget.onLoadMore();
        } finally {
          _loadingTimer?.cancel();
        }
      },
      _config.throttleDuration,
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// A complete infinite scroll list view with built-in loading indicators
class InfiniteScrollListView extends StatefulWidget {
  const InfiniteScrollListView({
    required this.itemCount,
    required this.itemBuilder,
    required this.onLoadMore,
    super.key,
    this.controller,
    this.scrollController,
    this.config,
    this.padding,
    this.physics,
    this.separatorBuilder,
    this.emptyStateWidget,
    this.emptyStateMessage = 'No items found',
    this.onError,
    this.onCompleted,
  });

  /// Number of items currently loaded
  final int itemCount;

  /// Builder for list items
  final Widget Function(BuildContext context, int index) itemBuilder;

  /// Callback to load more data
  final Future<bool> Function() onLoadMore;

  /// Infinite scroll controller
  final InfiniteScrollController? controller;

  /// Scroll controller
  final ScrollController? scrollController;

  /// Infinite scroll configuration
  final InfiniteScrollConfig? config;

  /// List padding
  final EdgeInsetsGeometry? padding;

  /// Scroll physics
  final ScrollPhysics? physics;

  /// Separator builder for list items
  final Widget Function(BuildContext context, int index)? separatorBuilder;

  /// Widget to show when list is empty
  final Widget? emptyStateWidget;

  /// Message to show when list is empty
  final String emptyStateMessage;

  /// Error callback
  final void Function(String error)? onError;

  /// Completion callback
  final VoidCallback? onCompleted;

  @override
  State<InfiniteScrollListView> createState() => _InfiniteScrollListViewState();
}

class _InfiniteScrollListViewState extends State<InfiniteScrollListView> {
  late InfiniteScrollController _controller;
  late ScrollController _scrollController;
  late InfiniteScrollConfig _config;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? InfiniteScrollController();
    _scrollController = widget.scrollController ?? ScrollController();
    _initializeConfig();

    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeConfig();
  }

  void _initializeConfig() {
    _config = widget.config ??
        InfiniteScrollConfig(
          loadingIndicatorColor: Theme.of(context).colorScheme.primary,
          messageStyle: Theme.of(context).textTheme.bodyMedium,
        );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);

    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    if (widget.controller == null) {
      _controller.dispose();
    }

    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final threshold = _config.threshold;

    if (currentScroll >= maxScroll - threshold &&
        _controller.hasMore &&
        !_controller.isLoading) {
      _triggerLoadMore();
    }
  }

  void _triggerLoadMore() {
    _controller.throttledTrigger(
      () async {
        try {
          final success = await widget.onLoadMore();
          if (!success && _controller.hasMore) {
            _controller.markCompleted();
          }
        } catch (error) {
          widget.onError?.call(error.toString());
        }
      },
      _config.throttleDuration,
    );
  }

  Widget _buildLoadingIndicator() {
    if (_config.showSkeletonLoader) {
      return Column(
        children: List.generate(
          _config.skeletonItemCount,
          (index) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: SkeletonLoader(
              type: SkeletonType.listItem,
              height: _config.skeletonHeight,
            ),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LoadingIndicator(
          type: _config.loadingIndicatorType,
          size: _config.loadingIndicatorSize,
          color: _config.loadingIndicatorColor,
        ),
        if (_config.loadingMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            _config.loadingMessage!,
            style: _config.messageStyle,
          ),
        ],
      ],
    );
  }

  Widget _buildStatusIndicator() => AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          if (_controller.isLoading) {
            return Container(
              padding: _config.padding,
              child: _buildLoadingIndicator(),
            );
          }

          if (_controller.isError) {
            return Container(
              padding: _config.padding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Theme.of(context).colorScheme.error,
                    size: 24,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _config.errorMessage,
                    style: _config.messageStyle?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _triggerLoadMore,
                    child: Text(_config.retryMessage),
                  ),
                ],
              ),
            );
          }

          if (_controller.isCompleted && widget.itemCount > 0) {
            return Container(
              padding: _config.padding,
              child: Text(
                _config.completedMessage,
                style: _config.messageStyle?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
            );
          }

          return const SizedBox.shrink();
        },
      );

  Widget _buildEmptyState() =>
      widget.emptyStateWidget ??
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
              widget.emptyStateMessage,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (widget.itemCount == 0 && !_controller.isLoading) {
      return _buildEmptyState();
    }

    final listView = widget.separatorBuilder != null
        ? ListView.separated(
            controller: _scrollController,
            padding: widget.padding,
            physics: widget.physics,
            itemCount: widget.itemCount + 1, // +1 for loading indicator
            itemBuilder: (context, index) {
              if (index == widget.itemCount) {
                return _buildStatusIndicator();
              }
              return widget.itemBuilder(context, index);
            },
            separatorBuilder: (context, index) {
              if (index == widget.itemCount - 1) {
                return const SizedBox.shrink();
              }
              return widget.separatorBuilder!(context, index);
            },
          )
        : ListView.builder(
            controller: _scrollController,
            padding: widget.padding,
            physics: widget.physics,
            itemCount: widget.itemCount + 1, // +1 for loading indicator
            itemBuilder: (context, index) {
              if (index == widget.itemCount) {
                return _buildStatusIndicator();
              }
              return widget.itemBuilder(context, index);
            },
          );

    return Semantics(
      label: _config.semanticsLabel ?? 'Infinite scroll list',
      child: listView,
    );
  }
}

/// Convenience extensions for adding infinite scroll to existing widgets
extension InfiniteScrollExtensions on Widget {
  /// Add infinite scroll functionality to this widget
  Widget withInfiniteScroll({
    required Future<bool> Function() onLoadMore,
    InfiniteScrollController? controller,
    InfiniteScrollConfig? config,
    ScrollController? scrollController,
    void Function(String error)? onError,
    VoidCallback? onCompleted,
  }) =>
      InfiniteScroll(
        onLoadMore: onLoadMore,
        controller: controller,
        config: config,
        scrollController: scrollController,
        onError: onError,
        onCompleted: onCompleted,
        child: this,
      );
}

/// Ready-to-use infinite scroll widgets
class InfiniteScrollWidgets {
  /// Simple infinite scroll list with minimal configuration
  static Widget list({
    required int itemCount,
    required Widget Function(BuildContext context, int index) itemBuilder,
    required Future<bool> Function() onLoadMore,
    String? loadingMessage,
    String? completedMessage,
  }) =>
      InfiniteScrollListView(
        itemCount: itemCount,
        itemBuilder: itemBuilder,
        onLoadMore: onLoadMore,
        config: InfiniteScrollConfig.withMessages(
          loadingMessage: loadingMessage,
          completedMessage: completedMessage,
        ),
      );

  /// Infinite scroll list with skeleton loading
  static Widget skeletonList({
    required int itemCount,
    required Widget Function(BuildContext context, int index) itemBuilder,
    required Future<bool> Function() onLoadMore,
    int skeletonCount = 3,
    double skeletonHeight = 72.0,
  }) =>
      InfiniteScrollListView(
        itemCount: itemCount,
        itemBuilder: itemBuilder,
        onLoadMore: onLoadMore,
        config: InfiniteScrollConfig.skeleton(
          itemCount: skeletonCount,
          itemHeight: skeletonHeight,
        ),
      );

  /// Infinite scroll with custom configuration
  static Widget custom({
    required int itemCount,
    required Widget Function(BuildContext context, int index) itemBuilder,
    required Future<bool> Function() onLoadMore,
    required InfiniteScrollConfig config,
    InfiniteScrollController? controller,
  }) =>
      InfiniteScrollListView(
        itemCount: itemCount,
        itemBuilder: itemBuilder,
        onLoadMore: onLoadMore,
        config: config,
        controller: controller,
      );
}
