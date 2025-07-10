import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/services/pagination_controller.dart';

/// A ListView widget that automatically handles pagination
class PaginatedListView<T> extends StatelessWidget {
  /// Creates a paginated list view with automatic pagination handling.
  ///
  /// The [controller] manages the pagination state and data loading.
  /// The [itemBuilder] is called for each item in the list.
  /// Optional builders can be provided for different states like loading, error, etc.
  const PaginatedListView({
    required this.controller,
    required this.itemBuilder,
    this.loadingBuilder,
    this.errorBuilder,
    this.emptyBuilder,
    this.loadingMoreBuilder,
    this.separatorBuilder,
    this.padding,
    this.physics,
    this.shrinkWrap = false,
    super.key,
  });

  /// Pagination controller
  final PaginationController<T> controller;

  /// Builder for list items
  final Widget Function(BuildContext context, T item, int index) itemBuilder;

  /// Builder for loading state
  final Widget Function(BuildContext context)? loadingBuilder;

  /// Builder for error state
  final Widget Function(BuildContext context, String error)? errorBuilder;

  /// Builder for empty state
  final Widget Function(BuildContext context)? emptyBuilder;

  /// Builder for loading more indicator
  final Widget Function(BuildContext context)? loadingMoreBuilder;

  /// Separator builder (for ListView.separated style)
  final Widget Function(BuildContext context, int index)? separatorBuilder;

  /// List padding
  final EdgeInsetsGeometry? padding;

  /// Scroll physics
  final ScrollPhysics? physics;

  /// Whether the list should shrink wrap
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) => Obx(() {
        // Show loading for initial load
        if (controller.isLoading && controller.isEmpty) {
          return loadingBuilder?.call(context) ??
              const Center(child: CircularProgressIndicator());
        }

        // Show error state
        if (controller.hasError && controller.isEmpty) {
          return errorBuilder?.call(context, controller.errorMessage) ??
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      controller.errorMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: controller.refresh,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
        }

        // Show empty state
        if (controller.isEmpty) {
          return emptyBuilder?.call(context) ??
              const Center(
                child: Text(
                  'No items found',
                  style: TextStyle(fontSize: 16),
                ),
              );
        }

        // Build the list
        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollEndNotification) {
              final metrics = notification.metrics;
              final threshold = metrics.maxScrollExtent * 0.8;

              if (metrics.pixels >= threshold && !controller.hasReachedEnd) {
                controller.loadNext();
              }
            }
            return false;
          },
          child: separatorBuilder != null
              ? _buildSeparatedList()
              : _buildRegularList(),
        );
      });

  Widget _buildRegularList() => ListView.builder(
        padding: padding,
        physics: physics,
        shrinkWrap: shrinkWrap,
        itemCount: controller.items.length + (controller.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          // Show loading more indicator at the end
          if (index == controller.items.length) {
            return loadingMoreBuilder?.call(context) ??
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
          }

          final item = controller.items[index];
          return itemBuilder(context, item, index);
        },
      );

  Widget _buildSeparatedList() => ListView.separated(
        padding: padding,
        physics: physics,
        shrinkWrap: shrinkWrap,
        itemCount: controller.items.length,
        separatorBuilder: separatorBuilder!,
        itemBuilder: (context, index) {
          final item = controller.items[index];
          final itemWidget = itemBuilder(context, item, index);

          // Add loading more indicator after last item if loading
          if (index == controller.items.length - 1 &&
              controller.isLoadingMore) {
            return Column(
              children: [
                itemWidget,
                separatorBuilder!(context, index),
                loadingMoreBuilder?.call(context) ??
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
              ],
            );
          }

          return itemWidget;
        },
      );
}

/// A GridView widget that automatically handles pagination
class PaginatedGridView<T> extends StatelessWidget {
  /// Creates a paginated grid view with automatic pagination handling.
  ///
  /// The [controller] manages the pagination state and data loading.
  /// The [itemBuilder] is called for each item in the grid.
  /// The [gridDelegate] defines the layout of grid items.
  /// Optional builders can be provided for different states like loading, error, etc.
  const PaginatedGridView({
    required this.controller,
    required this.itemBuilder,
    required this.gridDelegate,
    this.loadingBuilder,
    this.errorBuilder,
    this.emptyBuilder,
    this.loadingMoreBuilder,
    this.padding,
    this.physics,
    this.shrinkWrap = false,
    super.key,
  });

  /// Pagination controller
  final PaginationController<T> controller;

  /// Builder for grid items
  final Widget Function(BuildContext context, T item, int index) itemBuilder;

  /// Grid delegate for layout
  final SliverGridDelegate gridDelegate;

  /// Builder for loading state
  final Widget Function(BuildContext context)? loadingBuilder;

  /// Builder for error state
  final Widget Function(BuildContext context, String error)? errorBuilder;

  /// Builder for empty state
  final Widget Function(BuildContext context)? emptyBuilder;

  /// Builder for loading more indicator
  final Widget Function(BuildContext context)? loadingMoreBuilder;

  /// Grid padding
  final EdgeInsetsGeometry? padding;

  /// Scroll physics
  final ScrollPhysics? physics;

  /// Whether the grid should shrink wrap
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) => Obx(() {
        // Show loading for initial load
        if (controller.isLoading && controller.isEmpty) {
          return loadingBuilder?.call(context) ??
              const Center(child: CircularProgressIndicator());
        }

        // Show error state
        if (controller.hasError && controller.isEmpty) {
          return errorBuilder?.call(context, controller.errorMessage) ??
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      controller.errorMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: controller.refresh,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
        }

        // Show empty state
        if (controller.isEmpty) {
          return emptyBuilder?.call(context) ??
              const Center(
                child: Text(
                  'No items found',
                  style: TextStyle(fontSize: 16),
                ),
              );
        }

        // Build the grid
        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollEndNotification) {
              final metrics = notification.metrics;
              final threshold = metrics.maxScrollExtent * 0.8;

              if (metrics.pixels >= threshold && !controller.hasReachedEnd) {
                controller.loadNext();
              }
            }
            return false;
          },
          child: CustomScrollView(
            physics: physics,
            shrinkWrap: shrinkWrap,
            slivers: [
              SliverPadding(
                padding: padding ?? EdgeInsets.zero,
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = controller.items[index];
                      return itemBuilder(context, item, index);
                    },
                    childCount: controller.items.length,
                  ),
                  gridDelegate: gridDelegate,
                ),
              ),
              if (controller.isLoadingMore)
                SliverToBoxAdapter(
                  child: loadingMoreBuilder?.call(context) ??
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                ),
            ],
          ),
        );
      });
}
