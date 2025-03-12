// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:robin_radio/data/models/album.dart';
import 'package:robin_radio/global/albumCover.dart';
import 'package:robin_radio/modules/app/app_controller.dart';
import 'package:sizer/sizer.dart';

class AlbumsView extends StatefulWidget {
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

  @override
  void initState() {
    super.initState();

    // Initialize with all albums
    final controller = Get.find<AppController>();
    filteredAlbums.value = controller.albums;

    // Update filtered albums when search query changes
    ever(searchQuery, (query) {
      final controller = Get.find<AppController>();
      filteredAlbums.value = controller.searchAlbums(query);
    });

    // Add listener to focus node to hide search when focus is lost
    _searchFocusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    // If focus is lost and search is empty, hide the search field
    if (!_searchFocusNode.hasFocus && searchQuery.value.isEmpty) {
      isSearchVisible.value = false;
    }
  }

  @override
  void dispose() {
    // Dispose of the TextEditingController when the widget is disposed
    _searchController.dispose();
    // Remove listener before disposing focus node
    _searchFocusNode.removeListener(_onFocusChange);
    // Dispose of the FocusNode when the widget is disposed
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetX<AppController>(
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
  }

  Widget _buildAlbumsGrid(BuildContext context, AppController controller) {
    return Scaffold(
      body: Column(
        children: [
          // Search bar (conditionally visible)
          Obx(() => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: isSearchVisible.value ? 12.h : 0,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: isSearchVisible.value ? 1.0 : 0.0,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      decoration: InputDecoration(
                        hintText: 'Search albums...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            searchQuery.value = '';
                            isSearchVisible.value = false;
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onChanged: (value) {
                        // Update search query when text changes
                        searchQuery.value = value;
                      },
                    ),
                  ),
                ),
              )),

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
                            fontSize: 20, fontWeight: FontWeight.bold),
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
                onNotification: (ScrollNotification scrollInfo) {
                  // Pagination removed - no need to load more albums
                  return false;
                },
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: filteredAlbums.value.length,
                  itemBuilder: (context, index) {
                    // Show album card
                    return _buildAlbumCard(
                        context, filteredAlbums.value[index], controller);
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
          Future.delayed(const Duration(milliseconds: 100), () {
            _searchFocusNode.requestFocus();
          });
        },
        tooltip: 'Search',
        backgroundColor: const Color(0xFF6C30C4), // Match AppBar color
        foregroundColor: Colors.white, // White icon
        child: const Icon(Icons.search),
      ),
    );
  }

  Widget _buildAlbumCard(
      BuildContext context, Album album, AppController controller) {
    return GestureDetector(
      onTap: () => controller.openTrackList(album),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Album cover
            Expanded(
              child: Hero(
                tag: 'album-${album.id}',
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: AlbumCover(
                    imageUrl: album.albumCover,
                    albumName: album.albumName,
                    size: double.infinity,
                  ),
                ),
              ),
            ),

            // Album info
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album.albumName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    album.artist ?? 'Unknown Artist',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${album.trackCount} tracks',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingCard(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildLoadingView(BuildContext context, AppController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          spinkit(context),
          SizedBox(height: 2.h),
          const Text(
            'Loading Robin\'s Music...',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 1.h),
          Text(
            controller.loadingStatusMessage,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 3.h),
          SizedBox(
            width: 80.w,
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: controller.loadingProgress,
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  '${(controller.loadingProgress * 100).toInt()}% Complete',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, AppController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red,
          ),
          SizedBox(height: 2.h),
          Text(
            'Oops! Something went wrong',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 1.h),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              controller.errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          SizedBox(height: 3.h),
          ElevatedButton.icon(
            onPressed: () => controller.refreshMusic(),
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.music_off,
            size: 80,
            color: Colors.grey,
          ),
          SizedBox(height: 2.h),
          const Text(
            'No Music Found',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 1.h),
          const Text(
            'We couldn\'t find any music in your library',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 3.h),
          ElevatedButton.icon(
            onPressed: () => Get.find<AppController>().refreshMusic(),
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget spinkit(context) => const SpinKitChasingDots(
        color: Colors.deepPurpleAccent,
        size: 50.0,
      );
}
