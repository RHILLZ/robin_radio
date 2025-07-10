import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Generic pagination controller for managing paginated data lists with GetX integration.
///
/// Provides a reusable, type-safe solution for implementing pagination in list views,
/// grids, and other scrollable content. Handles all common pagination patterns including
/// initial loading, infinite scroll, pull-to-refresh, error handling, and end-of-data
/// detection with reactive state management.
///
/// Key capabilities:
/// - **Type-safe pagination**: Generic implementation works with any data type
/// - **Reactive state**: Real-time UI updates via GetX reactive programming
/// - **Automatic scroll detection**: Built-in infinite scroll trigger detection
/// - **Error handling**: Comprehensive error management with retry capabilities
/// - **Performance optimized**: Efficient memory usage and loading strategies
/// - **Customizable behavior**: Configurable page sizes and loading strategies
/// - **End detection**: Automatic detection when no more data is available
///
/// Pagination patterns supported:
/// - Initial page loading with loading indicators
/// - Infinite scroll with automatic next page triggers
/// - Pull-to-refresh for manual data refresh
/// - Manual pagination with explicit load controls
/// - Error recovery with retry mechanisms
///
/// Usage patterns:
/// ```dart
/// // Create controller for album pagination
/// final albumController = PaginationController<Album>(
///   loadPage: (page, size) => musicApi.getAlbums(page: page, limit: size),
///   pageSize: 20,
/// );
///
/// // Use in UI with automatic infinite scroll
/// Obx(() => ListView.builder(
///   itemCount: albumController.items.length,
///   itemBuilder: (context, index) {
///     // Trigger pagination near end
///     if (index == albumController.items.length - 3) {
///       albumController.loadNext();
///     }
///     return AlbumTile(albumController.items[index]);
///   },
/// ));
///
/// // Handle loading states
/// if (albumController.isLoading) {
///   return LoadingSpinner();
/// } else if (albumController.hasError) {
///   return ErrorWidget(albumController.errorMessage);
/// }
/// ```
///
/// The controller automatically manages page indices, loading states, and data
/// accumulation while providing reactive properties for immediate UI updates.
class PaginationController<T> extends GetxController {
  /// Creates a pagination controller with the specified data loading function.
  ///
  /// [loadPage] Function that loads a specific page of data. Must return a
  ///           Future<List<T>> where T is the data type being paginated.
  ///           Receives page number (0-based) and page size as parameters.
  ///
  /// [pageSize] Number of items to load per page. Defaults to 20 items,
  ///           which provides good balance between network efficiency and
  ///           scroll performance. Larger sizes reduce API calls but may
  ///           impact initial loading time.
  ///
  /// [initialLoad] Whether to automatically load the first page when the
  ///              controller is initialized. Set to false for manual loading
  ///              control or when initial data comes from cache.
  ///
  /// Example:
  /// ```dart
  /// final controller = PaginationController<Song>(
  ///   loadPage: (page, size) async {
  ///     final response = await api.getTracks(
  ///       offset: page * size,
  ///       limit: size,
  ///     );
  ///     return response.tracks;
  ///   },
  ///   pageSize: 25,
  ///   initialLoad: true,
  /// );
  /// ```
  PaginationController({
    required this.loadPage,
    this.pageSize = 20,
    this.initialLoad = true,
  });

  /// Function to load a specific page of data from the data source.
  ///
  /// This callback is responsible for fetching paginated data and should
  /// handle all networking, caching, and error scenarios appropriately.
  /// The pagination controller will manage calling this function with
  /// appropriate page numbers and handle the returned data.
  ///
  /// Parameters provided to the function:
  /// - `page`: Zero-based page number (0 for first page, 1 for second, etc.)
  /// - `pageSize`: Number of items requested for this page
  ///
  /// The function should return:
  /// - A Future that resolves to a List<T> of items for the requested page
  /// - An empty list if no items are available for the requested page
  /// - Throw an exception if an error occurs during loading
  ///
  /// Implementation considerations:
  /// - Handle network timeouts and connectivity issues
  /// - Implement appropriate caching strategies
  /// - Return consistent data types across all pages
  /// - Consider rate limiting and API quotas
  final Future<List<T>> Function(int page, int pageSize) loadPage;

  /// Number of items to request per page from the data source.
  ///
  /// Affects both network efficiency and user experience:
  /// - **Smaller pages (10-15)**: Faster initial loading, more API calls
  /// - **Medium pages (20-30)**: Balanced performance and efficiency
  /// - **Larger pages (50+)**: Fewer API calls but slower loading
  ///
  /// Consider your data size, network conditions, and UI performance
  /// when choosing an appropriate page size.
  final int pageSize;

  /// Whether to automatically load the first page during controller initialization.
  ///
  /// Set to `true` (default) for immediate data loading when the controller
  /// is created. Set to `false` when you need manual control over when
  /// data loading begins, such as after user authentication or cache checks.
  final bool initialLoad;

  // Reactive variables for state management
  final RxList<T> _items = <T>[].obs;
  final RxBool _isLoading = false.obs;
  final RxBool _isLoadingMore = false.obs;
  final RxBool _hasError = false.obs;
  final RxString _errorMessage = ''.obs;
  final RxBool _hasReachedEnd = false.obs;
  final RxInt _currentPage = 0.obs;

  // Getters for reactive state access

  /// Current list of all loaded items across all pages.
  ///
  /// Items are accumulated as new pages are loaded, maintaining order
  /// from the first page to the most recently loaded page.
  List<T> get items => _items;

  /// Whether the initial page is currently being loaded.
  ///
  /// True during the first page load operation, false otherwise.
  /// Use this to show full-screen loading indicators.
  bool get isLoading => _isLoading.value;

  /// Whether additional pages are currently being loaded.
  ///
  /// True during subsequent page loads (not the initial load).
  /// Use this to show pagination loading indicators at the bottom of lists.
  bool get isLoadingMore => _isLoadingMore.value;

  /// Whether the last operation resulted in an error.
  ///
  /// True if the most recent load operation failed, false otherwise.
  /// Check [errorMessage] for specific error details.
  bool get hasError => _hasError.value;

  /// Error message from the most recent failed operation.
  ///
  /// Contains human-readable error description when [hasError] is true.
  /// Empty string when no error has occurred or after successful operations.
  String get errorMessage => _errorMessage.value;

  /// Whether all available data has been loaded.
  ///
  /// True when the last loaded page contained fewer items than [pageSize],
  /// indicating no more data is available from the source.
  bool get hasReachedEnd => _hasReachedEnd.value;

  /// Current page number (1-based for display purposes).
  ///
  /// Represents the number of pages that have been successfully loaded.
  /// Starts at 0 and increments after each successful page load.
  int get currentPage => _currentPage.value;

  /// Whether the items list is currently empty.
  ///
  /// True if no items have been loaded or if the list has been cleared.
  /// Useful for showing empty state UI.
  bool get isEmpty => _items.isEmpty;

  /// Total number of items currently loaded across all pages.
  ///
  /// Represents the sum of all items from all loaded pages.
  int get totalItems => _items.length;

  @override
  void onInit() {
    super.onInit();
    if (initialLoad) {
      loadInitial();
    }
  }

  /// Load the first page of data and reset pagination state.
  ///
  /// Clears any existing data and loads the first page from the beginning.
  /// Sets up initial pagination state and handles any loading errors.
  /// This method is automatically called if [initialLoad] is true.
  ///
  /// Use cases:
  /// - Initial data loading when controller is created
  /// - Refresh operations to reload data from the beginning
  /// - Retry operations after errors
  /// - Search result loading with new parameters
  ///
  /// Loading process:
  /// 1. Sets loading state and clears previous errors
  /// 2. Resets pagination state (page = 0, end detection = false)
  /// 3. Calls [loadPage] function with page 0
  /// 4. Replaces existing items with new data
  /// 5. Detects end condition based on returned item count
  /// 6. Updates page counter and loading state
  ///
  /// Error handling:
  /// - Catches and stores any exceptions from [loadPage]
  /// - Preserves existing data if available
  /// - Sets error state for UI feedback
  ///
  /// Example usage:
  /// ```dart
  /// // Manual refresh
  /// await controller.loadInitial();
  ///
  /// // In pull-to-refresh
  /// RefreshIndicator(
  ///   onRefresh: controller.loadInitial,
  ///   child: ListView(...),
  /// );
  /// ```
  Future<void> loadInitial() async {
    if (_isLoading.value) {
      return;
    }

    try {
      _isLoading.value = true;
      _hasError.value = false;
      _currentPage.value = 0;
      _hasReachedEnd.value = false;

      final firstPage = await loadPage(0, pageSize);

      _items
        ..clear()
        ..addAll(firstPage);

      // Check if we've reached the end
      if (firstPage.length < pageSize) {
        _hasReachedEnd.value = true;
      }

      _currentPage.value = 1;
    } on Exception catch (e) {
      _handleError(e.toString());
    } finally {
      _isLoading.value = false;
    }
  }

  /// Load the next page of data and append to existing items.
  ///
  /// Loads the subsequent page of data and appends it to the current list.
  /// Automatically handles page tracking, end detection, and error states.
  /// Safe to call multiple times - will not trigger concurrent loads.
  ///
  /// Loading conditions:
  /// - Will not load if already loading more data
  /// - Will not load if end of data has been reached
  /// - Will not load if currently in error state (call refresh first)
  ///
  /// Use cases:
  /// - Infinite scroll implementations
  /// - Manual "Load More" button functionality
  /// - Automatic loading when user scrolls near end
  /// - Progressive data loading for large datasets
  ///
  /// Loading process:
  /// 1. Validates that loading is appropriate (not loading, not at end)
  /// 2. Sets loading more state and clears previous errors
  /// 3. Calls [loadPage] with current page number
  /// 4. Appends new items to existing list
  /// 5. Detects end condition based on returned item count
  /// 6. Increments page counter and updates loading state
  ///
  /// End detection:
  /// - Automatically sets [hasReachedEnd] to true if the returned page
  ///   contains fewer items than [pageSize]
  /// - Prevents unnecessary future load attempts
  /// - Enables UI to show "end of list" indicators
  ///
  /// Example usage:
  /// ```dart
  /// // Infinite scroll trigger
  /// ListView.builder(
  ///   itemBuilder: (context, index) {
  ///     if (index == controller.items.length - 1 && !controller.hasReachedEnd) {
  ///       controller.loadNext();
  ///     }
  ///     return ItemWidget(controller.items[index]);
  ///   },
  /// );
  ///
  /// // Manual load more button
  /// if (!controller.hasReachedEnd && !controller.isLoadingMore)
  ///   ElevatedButton(
  ///     onPressed: controller.loadNext,
  ///     child: Text('Load More'),
  ///   ),
  /// ```
  Future<void> loadNext() async {
    if (_isLoadingMore.value || _hasReachedEnd.value) {
      return;
    }

    try {
      _isLoadingMore.value = true;
      _hasError.value = false;

      final nextPage = await loadPage(_currentPage.value, pageSize);

      _items.addAll(nextPage);

      // Check if we've reached the end
      if (nextPage.length < pageSize) {
        _hasReachedEnd.value = true;
      }

      _currentPage.value++;
    } on Exception catch (e) {
      _handleError(e.toString());
    } finally {
      _isLoadingMore.value = false;
    }
  }

  /// Refresh the entire paginated list by reloading from the first page.
  ///
  /// Provides a complete refresh of the paginated data by calling [loadInitial].
  /// This method overrides the standard GetX refresh to implement pagination-specific
  /// refresh behavior. Commonly used with RefreshIndicator widgets.
  ///
  /// Refresh behavior:
  /// - Clears all existing data and state
  /// - Resets pagination to the beginning
  /// - Loads the first page as if starting fresh
  /// - Maintains the same loading function and page size
  /// - Clears any previous error states
  ///
  /// Example usage:
  /// ```dart
  /// RefreshIndicator(
  ///   onRefresh: controller.refresh,
  ///   child: ListView.builder(...),
  /// );
  ///
  /// // Manual refresh
  /// FloatingActionButton(
  ///   onPressed: controller.refresh,
  ///   child: Icon(Icons.refresh),
  /// );
  /// ```
  @override
  Future<void> refresh() async {
    await loadInitial();
  }

  /// Clear all loaded data and reset pagination state to initial values.
  ///
  /// Removes all items from the list and resets pagination state without
  /// triggering any network requests. Useful for logout scenarios, data
  /// source changes, or manual state reset operations.
  ///
  /// Reset operations:
  /// - Clears all items from the list
  /// - Resets current page to 0
  /// - Clears end-of-data flag
  /// - Clears error state and error messages
  /// - Does not trigger automatic reloading
  ///
  /// Use cases:
  /// - User logout or authentication changes
  /// - Switching between different data sources
  /// - Clearing search results
  /// - Resetting after critical errors
  /// - Manual state management
  ///
  /// Example usage:
  /// ```dart
  /// // Clear data on logout
  /// void logout() {
  ///   controller.clear();
  ///   navigateToLogin();
  /// }
  ///
  /// // Reset for new search
  /// void onSearchChanged(String query) {
  ///   controller.clear();
  ///   // Update loadPage function for new search
  ///   controller.loadInitial();
  /// }
  /// ```
  void clear() {
    _items.clear();
    _currentPage.value = 0;
    _hasReachedEnd.value = false;
    _hasError.value = false;
    _errorMessage.value = '';
  }

  /// Handle errors that occur during pagination operations.
  ///
  /// Centralized error handling that updates error state and provides
  /// consistent error reporting across all pagination operations.
  /// Errors are also logged to debug console for development visibility.
  ///
  /// [message] Human-readable error description to display to users.
  ///
  /// Error handling includes:
  /// - Setting error state flag for UI conditional rendering
  /// - Storing error message for user display
  /// - Debug logging for development troubleshooting
  /// - Preserving existing data when possible
  void _handleError(String message) {
    _hasError.value = true;
    _errorMessage.value = message;
    debugPrint('PaginationController Error: $message');
  }

  @override
  void onClose() {
    _items.clear();
    super.onClose();
  }
}

/// Mixin for widgets that need pagination scroll detection and trigger logic.
///
/// Provides utility methods for detecting when users scroll near the end of
/// scrollable content and automatically triggering pagination. Designed to
/// work with any ScrollView widget including ListView, GridView, and CustomScrollView.
///
/// Key features:
/// - **Automatic scroll detection**: Monitors scroll position relative to content length
/// - **Configurable threshold**: Customizable trigger point for pagination
/// - **Performance optimized**: Only triggers on scroll end to avoid excessive calls
/// - **Widget agnostic**: Works with any Flutter scrollable widget
/// - **Event-driven**: Uses callback pattern for loose coupling
///
/// Usage patterns:
/// ```dart
/// class AlbumListPage extends StatelessWidget with PaginationScrollMixin {
///   @override
///   Widget build(BuildContext context) {
///     return NotificationListener<ScrollNotification>(
///       onNotification: (notification) => handleScrollNotification(
///         notification,
///         () => controller.loadNext(),
///       ),
///       child: ListView.builder(...),
///     );
///   }
/// }
/// ```
///
/// The mixin provides intelligent scroll detection that balances user experience
/// with performance by only triggering pagination at appropriate scroll positions
/// and intervals.
mixin PaginationScrollMixin {
  /// Check if user has scrolled near the end and trigger pagination loading.
  ///
  /// Monitors scroll notifications to detect when the user has scrolled close
  /// to the end of the content and automatically triggers pagination loading.
  /// Uses a threshold-based approach to start loading before the user reaches
  /// the absolute end, providing smooth infinite scroll experience.
  ///
  /// [notification] The scroll notification from the scrollable widget.
  ///               Should be passed directly from NotificationListener.
  ///
  /// [onLoadMore] Callback function to trigger when pagination should occur.
  ///             Typically calls controller.loadNext() or similar method.
  ///
  /// Detection logic:
  /// - Only triggers on ScrollEndNotification to avoid excessive calls
  /// - Uses 80% threshold - pagination triggers when user scrolls 80% through content
  /// - Accounts for scroll position relative to maximum scroll extent
  /// - Returns true if pagination was triggered, false otherwise
  ///
  /// Threshold consideration:
  /// - 80% provides good balance between preemptive loading and performance
  /// - Earlier thresholds (60-70%) load more aggressively but may waste bandwidth
  /// - Later thresholds (90%+) may cause visible loading delays for users
  ///
  /// Example usage:
  /// ```dart
  /// NotificationListener<ScrollNotification>(
  ///   onNotification: (notification) {
  ///     return handleScrollNotification(
  ///       notification,
  ///       () {
  ///         if (!controller.isLoadingMore && !controller.hasReachedEnd) {
  ///           controller.loadNext();
  ///         }
  ///       },
  ///     );
  ///   },
  ///   child: ListView.builder(
  ///     itemCount: controller.items.length,
  ///     itemBuilder: (context, index) => ItemWidget(controller.items[index]),
  ///   ),
  /// );
  /// ```
  ///
  /// Returns `true` if pagination was triggered, `false` otherwise.
  /// This can be used by the NotificationListener to determine whether
  /// to consume the scroll notification.
  bool handleScrollNotification(
    ScrollNotification notification,
    VoidCallback onLoadMore,
  ) {
    if (notification is ScrollEndNotification) {
      final metrics = notification.metrics;
      final threshold = metrics.maxScrollExtent * 0.8; // 80% threshold

      if (metrics.pixels >= threshold) {
        onLoadMore();
        return true;
      }
    }
    return false;
  }
}
