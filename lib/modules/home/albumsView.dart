// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:robin_radio/data/models/album.dart';
import 'package:robin_radio/global/albumCover.dart';
import 'package:robin_radio/modules/app/app_controller.dart';
import 'package:sizer/sizer.dart';

class AlbumsView extends StatelessWidget {
  const AlbumsView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetX<AppController>(
      init: Get.find<AppController>(),
      builder: (controller) {
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
          // Search bar (optional)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search albums...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (value) {
                // Implement search functionality here
                // This would filter the albums based on the search term
              },
            ),
          ),

          // Albums grid
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification scrollInfo) {
                // Load more albums when reaching the bottom
                if (scrollInfo.metrics.pixels ==
                        scrollInfo.metrics.maxScrollExtent &&
                    controller.hasMoreAlbums &&
                    !controller.isLoadingMore) {
                  controller.loadMoreAlbums();
                }
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
                itemCount: controller.albums.length +
                    (controller.hasMoreAlbums ? 1 : 0),
                itemBuilder: (context, index) {
                  // Show loading indicator at the end when loading more
                  if (index == controller.albums.length) {
                    return _buildLoadingCard(context);
                  }

                  // Show album card
                  return _buildAlbumCard(
                      context, controller.albums[index], controller);
                },
              ),
            ),
          ),
        ],
      ),
      // Add pull-to-refresh
      floatingActionButton: FloatingActionButton(
        onPressed: () => controller.refreshMusic(),
        tooltip: 'Refresh',
        child: const Icon(Icons.refresh),
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
          const Text(
            'Please wait while we prepare your music',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 3.h),
          SizedBox(
            width: 80.w,
            child: const LinearProgressIndicator(),
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
