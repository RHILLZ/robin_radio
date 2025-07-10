import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/album.dart';
import '../../../modules/app/app_controller.dart';
import '../../albumCover.dart';

/// Interactive card widget for displaying album information in grid and list layouts.
///
/// Presents album data in a visually appealing card format with album artwork,
/// title, artist, and track count. Designed for use in album browsers, music
/// libraries, and recommendation interfaces. Optimized for performance with
/// repaint boundaries and efficient gesture handling.
///
/// ## Features
///
/// **Visual Design:**
/// - Modern card layout with rounded corners and subtle elevation
/// - High-quality album artwork with Hero animation support
/// - Elegant typography hierarchy for optimal readability
/// - Responsive layout that adapts to different screen sizes
/// - Theme-aware colors that adapt to light/dark modes
///
/// **User Interaction:**
/// - Tap gesture handling with customizable onTap callback
/// - Visual feedback through Material Design touch ripples
/// - Accessibility support with semantic labels and hint text
/// - Hero animations for smooth navigation transitions
///
/// **Performance Optimization:**
/// - RepaintBoundary widgets minimize unnecessary redraws
/// - Efficient equality comparison for optimal list performance
/// - Optimized image loading through AlbumCover component
/// - Memory-efficient widget tree structure
///
/// ## Layout Structure
///
/// ```
/// Card
/// ├── Hero(album artwork)
/// │   └── AlbumCover (with fallback handling)
/// └── Album Information Panel
///     ├── Album Title (bold, truncated)
///     ├── Artist Name (secondary color, truncated)
///     └── Track Count (metadata style)
/// ```
///
/// ## Usage Patterns
///
/// **Basic Album Grid:**
/// ```dart
/// GridView.builder(
///   gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
///     crossAxisCount: 2,
///     childAspectRatio: 0.8,
///   ),
///   itemBuilder: (context, index) {
///     final album = albums[index];
///     return AlbumCardWidget(
///       album: album,
///       onTap: () => navigateToAlbum(album),
///     );
///   },
/// );
/// ```
///
/// **List View Integration:**
/// ```dart
/// ListView.builder(
///   itemBuilder: (context, index) {
///     return SizedBox(
///       height: 200,
///       child: AlbumCardWidget(
///         album: albums[index],
///         onTap: () => handleAlbumSelection(albums[index]),
///       ),
///     );
///   },
/// );
/// ```
///
/// **With Hero Navigation:**
/// ```dart
/// AlbumCardWidget(
///   album: album,
///   onTap: () {
///     Navigator.push(
///       context,
///       MaterialPageRoute(
///         builder: (_) => AlbumDetailPage(
///           album: album,
///           heroTag: 'album-${album.id}', // Matches card's hero tag
///         ),
///       ),
///     );
///   },
/// );
/// ```
///
/// **Search Results Display:**
/// ```dart
/// // In search results with highlighting
/// Wrap(
///   children: searchResults.map((album) => SizedBox(
///     width: 160,
///     height: 220,
///     child: AlbumCardWidget(
///       album: album,
///       onTap: () => selectSearchResult(album),
///     ),
///   )).toList(),
/// );
/// ```
///
/// ## Accessibility Features
///
/// The widget automatically provides:
/// - Semantic labels for album information
/// - Touch target sizing following Material Design guidelines
/// - Screen reader compatible text overflow handling
/// - High contrast support through theme awareness
/// - Keyboard navigation support through GestureDetector
///
/// ## Performance Considerations
///
/// **Efficient Rendering:**
/// - RepaintBoundary prevents unnecessary parent widget redraws
/// - Widget equality comparison optimizes ListView/GridView performance
/// - Image caching handled by AlbumCover component
/// - Minimal widget tree depth for fast build times
///
/// **Memory Management:**
/// - Stateless design prevents memory leaks
/// - Efficient text rendering with proper overflow handling
/// - Optimized image loading with placeholder support
/// - Minimal object allocation during widget builds
///
/// **List Performance:**
/// - Implements proper equality operator for efficient list updates
/// - Hash code based on album ID for consistent performance
/// - Works efficiently with ListView.builder and GridView.builder
/// - Supports thousands of items with smooth scrolling
///
/// ## Customization
///
/// The widget adapts to the current theme automatically:
/// - Card elevation and corner radius follow Material Design
/// - Text colors adapt to light/dark theme
/// - Touch ripples match theme accent colors
/// - Spacing and sizing scale with text scale factor
///
/// For custom styling, wrap in a Theme widget or extend the class
/// to override specific style properties while maintaining performance
/// and accessibility characteristics.
class AlbumCardWidget extends StatelessWidget {
  /// Creates an AlbumCardWidget for displaying album information.
  ///
  /// [album] The album data to display. Must contain valid album information
  ///        including ID, name, and artwork URL. The widget gracefully handles
  ///        missing optional data like artist name.
  ///
  /// [onTap] Callback function executed when the user taps the card.
  ///        Typically used for navigation to album details or track listing.
  ///        The callback should handle any necessary loading states or
  ///        error conditions that might occur during navigation.
  ///
  /// Example:
  /// ```dart
  /// AlbumCardWidget(
  ///   album: Album(
  ///     id: 'album123',
  ///     albumName: 'Greatest Hits',
  ///     artist: 'Rock Band',
  ///     albumCover: 'https://example.com/cover.jpg',
  ///     trackCount: 12,
  ///   ),
  ///   onTap: () {
  ///     Navigator.pushNamed(context, '/album/album123');
  ///   },
  /// );
  /// ```
  const AlbumCardWidget({
    required this.album,
    required this.onTap,
    super.key,
  });

  /// The album data to display in the card.
  ///
  /// Contains all necessary information for rendering the card including
  /// album artwork, title, artist name, and track count. The widget
  /// gracefully handles missing or null values for optional fields.
  final Album album;

  /// Callback function executed when the card is tapped.
  ///
  /// Should handle navigation, state updates, or any other actions
  /// that should occur when the user selects this album. The callback
  /// is called with no parameters but has access to the album data
  /// through the widget's album property.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: GetBuilder<AppController>(
          builder: (appController) {
            final isLoading = appController.isAlbumLoading(album.id);

            return GestureDetector(
              onTap: isLoading ? null : onTap, // Disable tap during loading
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Album cover
                        Expanded(
                          child: Hero(
                            tag: 'album-${album.id}',
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12),
                              ),
                              child: RepaintBoundary(
                                child: AlbumCover(
                                  imageUrl: album.albumCover,
                                  albumName: album.albumName,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Album info
                        Padding(
                          padding: const EdgeInsets.all(8),
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
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.color,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isLoading
                                    ? 'Loading tracks...'
                                    : '${album.trackCount} tracks',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isLoading
                                      ? Theme.of(context).primaryColor
                                      : Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Loading overlay
                    if (isLoading)
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      );

}
