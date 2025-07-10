// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';

import '../../data/models/album.dart';
import '../../data/services/image_preload_service.dart';
import '../../global/widgets/widgets.dart';
import '../app/app_controller.dart';

/// Albums browsing view for Robin Radio.
///
/// This view displays the user's music collection in a grid layout with
/// comprehensive search and filtering capabilities. It provides an intuitive
/// interface for browsing albums with responsive design and performance
/// optimizations.
///
/// Features:
/// - Responsive grid layout that adapts to different screen sizes
/// - Real-time search functionality with debounced input
/// - Album cover preloading for smooth scrolling experience
/// - Error state handling with retry functionality
/// - Empty state messaging for better user experience
/// - Floating action button for quick search access
/// - Automatic focus management for search interactions
class AlbumsView extends StatefulWidget {
  /// Creates an instance of [AlbumsView].
  ///
  /// The [key] parameter is optional and follows standard Flutter widget conventions.
  const AlbumsView({super.key});

  @override
  State<AlbumsView> createState() => _AlbumsViewState();
}

class _AlbumsViewState extends State<AlbumsView> {
  // Create a RxString for the search query
  final RxString searchQuery = ''.obs;
  // Create a computed list of filtered albums
  final Rx<List<Album>> filteredAlbums = Rx<List<Album>>([]);
  // Create a TextEditingController for the search field
  final TextEditingController _searchController = TextEditingController();
  // Create a FocusNode for the search field
  final FocusNode _searchFocusNode = FocusNode();
  // Track if search field is visible
  final RxBool isSearchVisible = false.obs;

  // Store the worker reference for proper disposal
  Worker? _searchWorker;

  @override
  void initState() {
    super.initState();

    // Initialize with all albums
    final controller = Get.find<AppController>();
    filteredAlbums.value = controller.albums;

    // Update filtered albums when search query changes
    // Store the worker reference for proper disposal
    _searchWorker = ever(searchQuery, (query) {
      final controller = Get.find<AppController>();
      filteredAlbums.value = controller.searchAlbums(query);
    });

    // Add listener to focus node to hide search when focus is lost
    _searchFocusNode.addListener(_onFocusChange);

    // Preload album cover images after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadAlbumCovers();
    });
  }

  void _preloadAlbumCovers() {
    final controller = Get.find<AppController>();
    if (controller.albums.isNotEmpty) {
      final coverUrls = controller.albums
          .where(
            (album) => album.albumCover != null && album.albumCover!.isNotEmpty,
          )
          .map((album) => album.albumCover!)
          .toList();

      if (coverUrls.isNotEmpty) {
        context.preloadAlbumCovers(coverUrls, limit: 10);
      }
    }
  }

  void _onFocusChange() {
    // If focus is lost and search is empty, hide the search field
    if (!_searchFocusNode.hasFocus && searchQuery.value.isEmpty) {
      isSearchVisible.value = false;
    }
  }

  @override
  void dispose() {
    // Dispose of the worker to prevent memory leaks
    _searchWorker?.dispose();

    // Dispose of the TextEditingController when the widget is disposed
    _searchController.dispose();
    // Remove listener before disposing focus node
    _searchFocusNode
      ..removeListener(_onFocusChange)
      ..dispose(); // Dispose of the FocusNode when the widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GetX<AppController>(
        init: Get.find<AppController>(),
        builder: (controller) {
          // Update filtered albums when controller albums change and not searching
          if (searchQuery.value.isEmpty) {
            filteredAlbums.value = controller.albums;
          }

          // Show error state if there's an error
          if (controller.hasError) {
            return _buildErrorView(context, controller);
          }

          // Show loading state if initial loading
          if (controller.isLoading) {
            return _buildLoadingView(context, controller);
          }

          // Show empty state if no albums
          if (controller.albums.isEmpty) {
            return _buildEmptyView(context);
          }

          // Show albums grid
          return _buildAlbumsGrid(context, controller);
        },
      );

  Widget _buildAlbumsGrid(BuildContext context, AppController controller) =>
      Scaffold(
        body: Column(
          children: [
            // Search bar (conditionally visible)
            SearchBarWidget(
              isVisible: isSearchVisible,
              controller: _searchController,
              focusNode: _searchFocusNode,
              hintText: 'Search albums...',
              onChanged: (value) => searchQuery.value = value,
              onClear: () {
                _searchController.clear();
                searchQuery.value = '';
                isSearchVisible.value = false;
              },
            ),

            // Albums grid
            Expanded(
              child: Obx(() {
                // Show empty search results message if needed
                if (searchQuery.value.isNotEmpty &&
                    filteredAlbums.value.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.search_off,
                          size: 80,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 2.h),
                        const Text(
                          'No Results Found',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          'No albums match "${searchQuery.value}"',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return NotificationListener<ScrollNotification>(
                  onNotification: (scrollInfo) =>
                      // Pagination removed - no need to load more albums
                      false,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: filteredAlbums.value.length,
                    itemBuilder: (context, index) {
                      final album = filteredAlbums.value[index];
                      return AlbumCardWidget(
                        key: ValueKey(album.id),
                        album: album,
                        onTap: () => controller.openTrackList(album),
                      );
                    },
                  ),
                );
              }),
            ),
          ],
        ),
        // Search floating action button
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // Show search field and request focus
            isSearchVisible.value = true;
            // Use a small delay to ensure the field is visible before focusing
            Future.delayed(
              const Duration(milliseconds: 100),
              _searchFocusNode.requestFocus,
            );
          },
          tooltip: 'Search',
          backgroundColor: const Color(0xFF6C30C4), // Match AppBar color
          foregroundColor: Colors.white, // White icon
          child: const Icon(Icons.search),
        ),
      );

  Widget _buildLoadingView(BuildContext context, AppController controller) =>
      LoadingStateWidget(
        title: "Loading Robin's Music...",
        message: controller.loadingStatusMessage,
        progress: controller.loadingProgress,
      );

  Widget _buildErrorView(BuildContext context, AppController controller) =>
      ErrorStateWidget(
        title: 'Oops! Something went wrong',
        message: controller.errorMessage,
        onRetry: () => controller.refreshMusic(),
      );

  Widget _buildEmptyView(BuildContext context) => EmptyStateWidget(
        title: 'No Music Found',
        message: "We couldn't find any music in your library",
        icon: Icons.music_off,
        onRefresh: () => Get.find<AppController>().refreshMusic(),
      );
}
