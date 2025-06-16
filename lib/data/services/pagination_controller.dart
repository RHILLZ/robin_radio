import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Generic pagination controller for managing paginated lists
class PaginationController<T> extends GetxController {
  PaginationController({
    required this.loadPage,
    this.pageSize = 20,
    this.initialLoad = true,
  });

  /// Function to load a specific page of data
  final Future<List<T>> Function(int page, int pageSize) loadPage;

  /// Number of items per page
  final int pageSize;

  /// Whether to load initial data automatically
  final bool initialLoad;

  // Reactive variables
  final RxList<T> _items = <T>[].obs;
  final RxBool _isLoading = false.obs;
  final RxBool _isLoadingMore = false.obs;
  final RxBool _hasError = false.obs;
  final RxString _errorMessage = ''.obs;
  final RxBool _hasReachedEnd = false.obs;
  final RxInt _currentPage = 0.obs;

  // Getters
  List<T> get items => _items;
  bool get isLoading => _isLoading.value;
  bool get isLoadingMore => _isLoadingMore.value;
  bool get hasError => _hasError.value;
  String get errorMessage => _errorMessage.value;
  bool get hasReachedEnd => _hasReachedEnd.value;
  int get currentPage => _currentPage.value;
  bool get isEmpty => _items.isEmpty;
  int get totalItems => _items.length;

  @override
  void onInit() {
    super.onInit();
    if (initialLoad) {
      loadInitial();
    }
  }

  /// Load the first page of data
  Future<void> loadInitial() async {
    if (_isLoading.value) return;

    try {
      _isLoading.value = true;
      _hasError.value = false;
      _currentPage.value = 0;
      _hasReachedEnd.value = false;

      final firstPage = await loadPage(0, pageSize);

      _items.clear();
      _items.addAll(firstPage);

      // Check if we've reached the end
      if (firstPage.length < pageSize) {
        _hasReachedEnd.value = true;
      }

      _currentPage.value = 1;
    } catch (e) {
      _handleError(e.toString());
    } finally {
      _isLoading.value = false;
    }
  }

  /// Load the next page of data
  Future<void> loadNext() async {
    if (_isLoadingMore.value || _hasReachedEnd.value) return;

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
    } catch (e) {
      _handleError(e.toString());
    } finally {
      _isLoadingMore.value = false;
    }
  }

  /// Refresh the entire list (reload from first page)
  @override
  Future<void> refresh() async {
    await loadInitial();
  }

  /// Clear all data
  void clear() {
    _items.clear();
    _currentPage.value = 0;
    _hasReachedEnd.value = false;
    _hasError.value = false;
    _errorMessage.value = '';
  }

  /// Handle errors
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

/// Mixin for widgets that need pagination scroll detection
mixin PaginationScrollMixin {
  /// Check if user has scrolled near the end and trigger pagination
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
