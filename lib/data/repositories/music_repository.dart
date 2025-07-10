import '../exceptions/repository_exception.dart' show RepositoryException;
import '../models/album.dart';
import '../models/song.dart';
import 'repositories.dart' show RepositoryException;

/// Comprehensive music data repository interface for audio content management.
///
/// Defines the complete contract for accessing, searching, and managing music data
/// across multiple data sources including remote APIs, local cache, and offline storage.
/// Implementations handle the complexities of data synchronization, caching strategies,
/// and network optimization while providing a clean, consistent interface.
///
/// Key capabilities:
/// - **Multi-source data access**: Seamless integration of remote and cached data
/// - **Intelligent caching**: Automatic cache management with offline-first behavior
/// - **Search functionality**: Full-text search across albums and tracks
/// - **Radio streaming**: Continuous random track generation for radio mode
/// - **Performance optimization**: Efficient data loading and memory management
/// - **Error handling**: Comprehensive exception management with recovery strategies
///
/// The repository automatically handles:
/// - Network connectivity issues with graceful fallbacks
/// - Cache expiration and refresh strategies
/// - Data consistency across app sessions
/// - Background synchronization and updates
///
/// Usage patterns:
/// ```dart
/// final musicRepo = GetIt.instance<MusicRepository>();
///
/// // Load albums with cache fallback
/// try {
///   final albums = await musicRepo.getAlbums();
/// } catch (e) {
///   // Handle with cache-only fallback
///   final cached = await musicRepo.getAlbumsFromCacheOnly();
/// }
///
/// // Search across music library
/// final results = await musicRepo.searchAlbums('rock');
///
/// // Stream radio content
/// final radioStream = await musicRepo.getRadioStream();
/// radioStream.listen((song) => playTrack(song));
/// ```

/// Progress information for album loading operations.
///
/// Provides detailed information about the current state of album loading
/// operations, including progress percentage, descriptive messages, and
/// processing counts for user interface updates.
class AlbumLoadingProgress {
  /// Creates an instance of [AlbumLoadingProgress] with the specified values.
  ///
  /// All parameters are required to provide complete progress information.
  const AlbumLoadingProgress({
    required this.message,
    required this.progress,
    required this.albumsProcessed,
    required this.totalAlbums,
  });

  /// Human-readable message describing the current operation
  final String message;

  /// Progress as a value between 0.0 and 1.0
  final double progress;

  /// Number of albums processed so far
  final int albumsProcessed;

  /// Total number of albums to process (if known)
  final int totalAlbums;
}

/// Abstract base class defining the contract for music data repositories.
///
/// This interface establishes the complete API for accessing music content
/// across all supported data sources including remote services, local cache,
/// and offline storage. Implementations handle the complexities of data
/// synchronization, caching strategies, and network optimization.
abstract class MusicRepository {
  /// Retrieves all available albums from the optimal data source.
  ///
  /// Implements intelligent data fetching that prioritizes performance and reliability:
  /// 1. Returns cached data if available and fresh
  /// 2. Fetches from remote source if cache is stale or empty
  /// 3. Updates cache automatically after successful remote fetch
  /// 4. Falls back to stale cache if network fails
  ///
  /// The method handles network timeouts gracefully and provides automatic
  /// retry logic for transient failures. Results are optimized for display
  /// with pre-loaded metadata and efficient serialization.
  ///
  /// Returns a list of [Album] objects with complete metadata including:
  /// - Album artwork URLs (multiple resolutions)
  /// - Artist information and credits
  /// - Release dates and catalog information
  /// - Track counts and duration summaries
  /// - Popularity and rating data
  ///
  /// Throws [RepositoryException] if:
  /// - Network requests fail and no cached data is available
  /// - Data parsing errors occur
  /// - Authentication or authorization fails
  /// - Service quotas or rate limits are exceeded
  ///
  /// Example usage:
  /// ```dart
  /// try {
  ///   final albums = await musicRepo.getAlbums();
  ///   albumView.displayAlbums(albums);
  /// } on RepositoryException catch (e) {
  ///   if (e.isNetworkError) {
  ///     showOfflineMessage();
  ///   } else {
  ///     showErrorDialog(e.message);
  ///   }
  /// }
  /// ```
  Future<List<Album>> getAlbums();

  /// Retrieves albums exclusively from local cache without network requests.
  ///
  /// Provides fast, offline-first access to previously cached album data without
  /// making any network calls. Essential for implementing true offline functionality
  /// and handling network timeout scenarios with graceful degradation.
  ///
  /// This method is designed to be used as a fallback when:
  /// - Network connectivity is unavailable or unreliable
  /// - App is in offline mode or low-data usage mode
  /// - Immediate response is required (UI responsiveness)
  /// - Network operations have failed or timed out
  ///
  /// Cache behavior:
  /// - Returns all available cached albums regardless of age
  /// - Includes albums cached during previous successful network operations
  /// - Preserves full album metadata including artwork URLs
  /// - Maintains original sort order from last successful fetch
  ///
  /// Never throws exceptions - instead returns empty list when:
  /// - No albums have been cached yet (first app launch)
  /// - Cache has been explicitly cleared
  /// - Cache corruption is detected
  /// - Insufficient storage space for cache operation
  ///
  /// Returns empty list rather than throwing to support safe fallback patterns
  /// in timeout scenarios where exception handling might interfere with
  /// user experience continuity.
  ///
  /// Example usage:
  /// ```dart
  /// // Timeout fallback pattern
  /// try {
  ///   final albums = await musicRepo.getAlbums()
  ///     .timeout(Duration(seconds: 5));
  /// } on TimeoutException {
  ///   // Graceful fallback without exceptions
  ///   final cachedAlbums = await musicRepo.getAlbumsFromCacheOnly();
  ///   if (cachedAlbums.isNotEmpty) {
  ///     showCachedContent(cachedAlbums);
  ///   } else {
  ///     showOfflineEmptyState();
  ///   }
  /// }
  /// ```
  Future<List<Album>> getAlbumsFromCacheOnly();

  /// Retrieves all tracks for a specific album with comprehensive metadata.
  ///
  /// Loads complete track listing for the specified album including detailed
  /// metadata, audio file information, and playback-ready URLs. Implements
  /// efficient loading strategies with automatic caching and background
  /// synchronization for optimal performance.
  ///
  /// Track data includes:
  /// - High-quality audio stream URLs with fallback qualities
  /// - Complete track metadata (title, artist, duration, etc.)
  /// - Album context information and track positioning
  /// - Artwork URLs synchronized with parent album
  /// - Playback analytics and recommendation data
  /// - Lyrics and additional content where available
  ///
  /// [albumId] The unique identifier of the album. Must be a valid album ID
  ///          that exists in the music catalog. Invalid IDs result in
  ///          empty returns rather than exceptions for graceful handling.
  ///
  /// Caching behavior:
  /// - Tracks are cached alongside album data for efficiency
  /// - Cache is updated automatically when album data refreshes
  /// - Individual track updates propagate to album cache
  /// - Cache keys are optimized for fast album-based lookups
  ///
  /// Throws [RepositoryException] if:
  /// - Network request fails and no cached data exists
  /// - Album ID format is malformed (not just non-existent)
  /// - Authentication expires during large album loading
  /// - Storage quota exceeded during cache operation
  /// - Data corruption detected in remote or cached data
  ///
  /// Example usage:
  /// ```dart
  /// Future<void> loadAlbumTracks(String albumId) async {
  ///   try {
  ///     final tracks = await musicRepo.getTracks(albumId);
  ///     if (tracks.isEmpty) {
  ///       showEmptyAlbumMessage();
  ///     } else {
  ///       displayTrackListing(tracks);
  ///       preloadFirstTrack(tracks.first);
  ///     }
  ///   } on RepositoryException catch (e) {
  ///     handleLoadError(e);
  ///   }
  /// }
  /// ```
  Future<List<Song>> getTracks(String albumId);

  /// Creates a continuous stream of random tracks for radio-style playback.
  ///
  /// Generates an infinite stream of randomly selected tracks suitable for
  /// radio mode, background listening, and music discovery. The stream
  /// intelligently balances variety, user preferences, and content availability
  /// to provide an engaging listening experience.
  ///
  /// Stream characteristics:
  /// - **Infinite duration**: Continues until explicitly cancelled
  /// - **Smart randomization**: Avoids immediate repeats and considers history
  /// - **Quality filtering**: Only includes high-quality, complete tracks
  /// - **Preference awareness**: Weights selection based on user behavior
  /// - **Adaptive buffering**: Optimizes for continuous playback
  /// - **Error resilience**: Automatically recovers from individual track failures
  ///
  /// Randomization algorithm:
  /// - Maintains variety by avoiding recent selections
  /// - Considers track popularity and user engagement metrics
  /// - Balances familiar content with discovery opportunities
  /// - Adapts to current listening context and time of day
  /// - Respects content availability and licensing restrictions
  ///
  /// Stream management:
  /// - Automatically handles buffering and preloading
  /// - Manages memory usage for long-running streams
  /// - Provides backpressure handling for slow consumers
  /// - Includes error recovery and retry mechanisms
  ///
  /// The returned Future resolves to a Stream<Song> that emits tracks
  /// continuously. The stream should be managed properly to prevent
  /// memory leaks and unnecessary resource consumption.
  ///
  /// Throws [RepositoryException] if:
  /// - Insufficient content available for stream generation
  /// - Authentication or licensing issues prevent access
  /// - Network connectivity required but unavailable
  /// - Service rate limits prevent stream initialization
  ///
  /// Example usage:
  /// ```dart
  /// StreamSubscription<Song>? _radioSubscription;
  ///
  /// Future<void> startRadioMode() async {
  ///   try {
  ///     final radioStream = await musicRepo.getRadioStream();
  ///     _radioSubscription = radioStream.listen(
  ///       (song) => audioPlayer.play(song),
  ///       onError: (error) => handleStreamError(error),
  ///       onDone: () => handleStreamComplete(),
  ///     );
  ///   } on RepositoryException catch (e) {
  ///     showRadioUnavailable(e.message);
  ///   }
  /// }
  ///
  /// void stopRadioMode() {
  ///   _radioSubscription?.cancel();
  ///   _radioSubscription = null;
  /// }
  /// ```
  Future<Stream<Song>> getRadioStream();

  /// Retrieves a specific track by its unique identifier with full metadata.
  ///
  /// Performs efficient lookup of individual tracks using their unique ID,
  /// returning complete track information suitable for immediate playback
  /// or detailed display. Optimized for single-track access patterns
  /// common in playlist navigation, search results, and direct linking.
  ///
  /// Track lookup process:
  /// 1. Checks local cache for immediate availability
  /// 2. Validates cached data freshness and completeness
  /// 3. Fetches from remote source if cache miss or stale
  /// 4. Updates cache with fresh data automatically
  /// 5. Returns null for graceful handling of missing tracks
  ///
  /// Returned track data includes:
  /// - Complete metadata (title, artist, album, duration)
  /// - High-quality audio stream URLs with format options
  /// - Album artwork and track-specific imagery
  /// - Playback analytics and user engagement data
  /// - Related content suggestions and similar tracks
  /// - Licensing and availability information
  ///
  /// [id] The unique identifier of the track. Must be a properly formatted
  ///     track ID string. Malformed IDs return null rather than throwing
  ///     exceptions for consistent error handling patterns.
  ///
  /// Returns null if:
  /// - Track ID doesn't exist in the music catalog
  /// - Track has been removed or is no longer available
  /// - Content licensing restricts access in current region
  /// - Track is temporarily unavailable due to service issues
  ///
  /// Null returns enable graceful handling of missing content without
  /// requiring exception handling, supporting robust playlist and
  /// navigation implementations.
  ///
  /// Throws [RepositoryException] if:
  /// - Network request fails and no cached data is available
  /// - Authentication or authorization problems occur
  /// - Service is temporarily unavailable or overloaded
  /// - Data corruption is detected in remote or cached content
  ///
  /// Example usage:
  /// ```dart
  /// Future<void> playTrackById(String trackId) async {
  ///   try {
  ///     final track = await musicRepo.getTrackById(trackId);
  ///     if (track != null) {
  ///       await audioPlayer.play(track);
  ///       updateNowPlaying(track);
  ///     } else {
  ///       showTrackNotAvailable();
  ///     }
  ///   } on RepositoryException catch (e) {
  ///     showPlaybackError(e.message);
  ///   }
  /// }
  /// ```
  Future<Song?> getTrackById(String id);

  /// Searches for albums matching the specified query with intelligent ranking.
  ///
  /// Performs comprehensive full-text search across album metadata including
  /// titles, artist names, genre information, and additional descriptive content.
  /// Results are intelligently ranked based on relevance, popularity, and user
  /// preferences to provide the most useful matches first.
  ///
  /// Search capabilities:
  /// - **Multi-field matching**: Searches across album titles, artists, and metadata
  /// - **Fuzzy matching**: Handles typos and partial matches intelligently
  /// - **Relevance ranking**: Orders results by match quality and popularity
  /// - **Real-time results**: Provides fast response for interactive search
  /// - **Cache optimization**: Leverages cached data for offline search
  /// - **Personalization**: Considers user listening history and preferences
  ///
  /// Search algorithm:
  /// - Exact matches are prioritized highest
  /// - Partial matches weighted by field importance
  /// - Popular content receives moderate ranking boost
  /// - User's listening history influences result ordering
  /// - Recent releases get slight relevance enhancement
  ///
  /// [query] The search term to match against album content. Supports:
  ///        - Single words or complete phrases
  ///        - Artist names, album titles, or combined searches
  ///        - Partial matches and common misspellings
  ///        - Special characters and international text
  ///        - Empty strings return empty results gracefully
  ///
  /// Search behavior:
  /// - Minimum query length requirements handled gracefully
  /// - Whitespace and special characters normalized automatically
  /// - Case-insensitive matching across all content fields
  /// - Diacritics and accent marks handled intelligently
  ///
  /// Returns an empty list if:
  /// - No albums match the search criteria
  /// - Query is too short or contains only special characters
  /// - Search index is temporarily unavailable
  /// - User lacks access to matched content
  ///
  /// Results are cached temporarily to improve repeated search performance
  /// and enable offline search capabilities when network is unavailable.
  ///
  /// Throws [RepositoryException] if:
  /// - Search service is unavailable or overloaded
  /// - Network connectivity fails and no cached search data exists
  /// - Authentication expires during search operation
  /// - Search query violates service terms or rate limits
  ///
  /// Example usage:
  /// ```dart
  /// Future<void> performAlbumSearch(String userQuery) async {
  ///   if (userQuery.trim().isEmpty) {
  ///     clearSearchResults();
  ///     return;
  ///   }
  ///
  ///   try {
  ///     showSearchLoading();
  ///     final results = await musicRepo.searchAlbums(userQuery);
  ///
  ///     if (results.isEmpty) {
  ///       showNoResults(userQuery);
  ///     } else {
  ///       displaySearchResults(results);
  ///       trackSearchEvent(userQuery, results.length);
  ///     }
  ///   } on RepositoryException catch (e) {
  ///     showSearchError(e.message);
  ///   } finally {
  ///     hideSearchLoading();
  ///   }
  /// }
  /// ```
  Future<List<Album>> searchAlbums(String query);

  /// Searches for tracks matching the specified query with comprehensive ranking.
  ///
  /// Executes detailed full-text search across track metadata including song titles,
  /// artist names, album information, and lyrical content where available. Results
  /// are intelligently ranked using multiple relevance factors to surface the most
  /// appropriate matches for the user's search intent.
  ///
  /// Advanced search features:
  /// - **Multi-dimensional matching**: Searches titles, artists, albums, and lyrics
  /// - **Semantic understanding**: Handles synonyms and related terms
  /// - **Contextual ranking**: Considers user's musical preferences and history
  /// - **Performance optimization**: Fast response times even for large catalogs
  /// - **Offline capability**: Searches cached content when network unavailable
  /// - **Progressive results**: Can provide partial results for long searches
  ///
  /// Ranking algorithm factors:
  /// - Exact title matches receive highest priority
  /// - Artist name matches weighted heavily
  /// - Album context provides additional relevance signals
  /// - Track popularity and user engagement metrics
  /// - Recency of release and user listening patterns
  /// - Collaborative filtering from similar user preferences
  ///
  /// [query] The search term for finding matching tracks. Supports:
  ///        - Song titles and artist names (individual or combined)
  ///        - Album names to find all tracks from matching albums
  ///        - Lyrical content searches (where lyrics are available)
  ///        - Genre and mood-based search terms
  ///        - Natural language queries like "songs by \[artist\]"
  ///
  /// Query processing:
  /// - Automatic query expansion for common abbreviations
  /// - Stopword removal to focus on meaningful terms
  /// - Phonetic matching for artist and song names
  /// - Synonym expansion for improved recall
  /// - Spell correction for common misspellings
  ///
  /// Returns an empty list when:
  /// - No tracks match the search criteria after applying filters
  /// - Query contains only stopwords or special characters
  /// - User lacks access to tracks that would otherwise match
  /// - Content filtering removes all potential matches
  ///
  /// Search results include tracks from all accessible albums, providing
  /// comprehensive coverage of the user's available music catalog.
  /// Results maintain track-to-album relationships for context.
  ///
  /// Throws [RepositoryException] if:
  /// - Search infrastructure is temporarily unavailable
  /// - Network failures prevent search and no cached results exist
  /// - Authentication issues arise during search processing
  /// - Rate limiting or quota exceeded for search operations
  /// - Data corruption detected in search index or cached data
  ///
  /// Example usage:
  /// ```dart
  /// Future<void> searchForTracks(String searchQuery) async {
  ///   if (searchQuery.length < 2) {
  ///     showSearchPrompt();
  ///     return;
  ///   }
  ///
  ///   try {
  ///     displaySearchSpinner();
  ///     final tracks = await musicRepo.searchTracks(searchQuery);
  ///
  ///     if (tracks.isEmpty) {
  ///       showEmptySearchState(searchQuery);
  ///       suggestAlternativeSearches(searchQuery);
  ///     } else {
  ///       groupTracksByAlbum(tracks);
  ///       displayTrackResults(tracks);
  ///       enablePlayAllOption(tracks);
  ///     }
  ///   } on RepositoryException catch (e) {
  ///     handleSearchFailure(e);
  ///   } finally {
  ///     hideSearchSpinner();
  ///   }
  /// }
  /// ```
  Future<List<Song>> searchTracks(String query);

  /// Refreshes the local cache by fetching fresh data from remote sources.
  ///
  /// Performs a comprehensive cache refresh operation that fetches the latest
  /// content from remote data sources and updates all local cached data.
  /// This operation ensures users have access to the most current music catalog
  /// including new releases, updated metadata, and content availability changes.
  ///
  /// Refresh operation includes:
  /// - **Complete catalog sync**: Downloads latest album and track listings
  /// - **Metadata updates**: Refreshes artist information, artwork, and details
  /// - **Availability changes**: Updates track accessibility and licensing status
  /// - **New content discovery**: Identifies and caches newly released content
  /// - **Cache validation**: Verifies and repairs corrupted cached data
  /// - **Index rebuilding**: Updates search indexes for optimal performance
  ///
  /// Refresh strategy:
  /// - Fetches incremental updates when possible to minimize bandwidth
  /// - Falls back to full refresh if incremental sync fails
  /// - Maintains cache consistency during multi-step refresh process
  /// - Preserves user data and preferences during cache updates
  /// - Optimizes network usage with compression and differential updates
  ///
  /// The operation runs efficiently in the background and provides progress
  /// updates for long-running refresh cycles. Critical user data is never
  /// lost during refresh operations, with atomic updates ensuring consistency.
  ///
  /// Cache refresh triggers:
  /// - User-initiated manual refresh
  /// - Automatic background refresh based on staleness
  /// - App startup refresh for essential data
  /// - Recovery from data corruption or network errors
  /// - After authentication status changes
  ///
  /// Refresh behavior:
  /// - Existing cached content remains available during refresh
  /// - New content becomes available immediately as it's cached
  /// - Failed refreshes leave existing cache intact
  /// - Partial refresh failures are handled gracefully
  /// - Cache storage is optimized automatically during refresh
  ///
  /// The operation may take significant time for large music catalogs or
  /// slow network connections. Progress can be monitored through repository
  /// events or status callbacks where implemented.
  ///
  /// Throws [RepositoryException] if:
  /// - Network connectivity is unavailable for refresh operation
  /// - Remote data source is inaccessible or returning errors
  /// - Authentication expires during the refresh process
  /// - Insufficient local storage space for updated cache data
  /// - Data corruption prevents successful cache update
  /// - Service rate limits prevent completion of refresh operation
  ///
  /// Example usage:
  /// ```dart
  /// Future<void> refreshMusicLibrary() async {
  ///   try {
  ///     showRefreshIndicator();
  ///     await musicRepo.refreshCache();
  ///
  ///     showRefreshSuccess();
  ///     notifyLibraryUpdated();
  ///
  ///     // Reload current view to show fresh content
  ///     await reloadCurrentMusicView();
  ///   } on RepositoryException catch (e) {
  ///     hideRefreshIndicator();
  ///
  ///     if (e.isNetworkError) {
  ///       showNetworkErrorMessage();
  ///     } else if (e.isStorageError) {
  ///       showStorageFullMessage();
  ///     } else {
  ///       showGenericRefreshError(e.message);
  ///     }
  ///   }
  /// }
  /// ```
  Future<void> refreshCache();

  /// Clears all cached music data and resets the repository to initial state.
  ///
  /// Performs complete removal of all locally cached music content including
  /// albums, tracks, search indexes, metadata, and user-specific cached data.
  /// This operation provides a clean slate for troubleshooting, storage management,
  /// or when users want to reset their local music library completely.
  ///
  /// Cache clearing includes:
  /// - **Album and track metadata**: All cached music content information
  /// - **Audio file caches**: Temporarily cached audio data for offline playback
  /// - **Search indexes**: Local search optimization data structures
  /// - **Artwork caches**: Album covers and artist images
  /// - **User preference cache**: Personalization data tied to music content
  /// - **Analytics cache**: Local usage tracking and recommendation data
  ///
  /// Clearing strategy:
  /// - Atomic operation that completes fully or not at all
  /// - Preserves critical user settings and authentication data
  /// - Maintains app configuration and non-music preferences
  /// - Clears temporary files and optimization data structures
  /// - Resets cache metadata and tracking information
  ///
  /// Post-clearing behavior:
  /// - Repository returns to initial state as if first launched
  /// - Next data requests will fetch fresh content from remote sources
  /// - Search operations will rebuild indexes as needed
  /// - Cache will be repopulated gradually as content is accessed
  /// - Performance may be temporarily reduced until cache rebuilds
  ///
  /// Use cases for cache clearing:
  /// - Troubleshooting data corruption or inconsistency issues
  /// - Freeing storage space when device storage is critically low
  /// - Resetting after major app updates or data format changes
  /// - User privacy requests to remove all local music data
  /// - Development and testing scenarios requiring clean state
  ///
  /// The operation is irreversible and will require network connectivity
  /// to restore music content availability. Users should be warned about
  /// the implications before clearing cache, especially on metered connections.
  ///
  /// Storage recovery:
  /// - Immediately frees all space used by cached music data
  /// - Optimizes storage allocation for future cache operations
  /// - Defragments cache storage for improved performance
  /// - Removes orphaned files and temporary data
  ///
  /// Throws [RepositoryException] if:
  /// - File system errors prevent cache deletion
  /// - Cache files are locked by other processes
  /// - Insufficient permissions for cache directory access
  /// - Storage corruption prevents clean cache removal
  /// - Critical system files are mistakenly included in cache
  ///
  /// Example usage:
  /// ```dart
  /// Future<void> clearMusicCache() async {
  ///   // Confirm user intent before irreversible operation
  ///   final confirmed = await showClearCacheConfirmation();
  ///   if (!confirmed) return;
  ///
  ///   try {
  ///     showClearingProgress();
  ///     await musicRepo.clearCache();
  ///
  ///     // Update UI to reflect empty state
  ///     resetMusicViews();
  ///     showCacheCleared();
  ///
  ///     // Offer to reload essential content
  ///     offerContentReload();
  ///   } on RepositoryException catch (e) {
  ///     hideClearingProgress();
  ///     showClearCacheError(e.message);
  ///
  ///     // Provide recovery suggestions
  ///     suggestCacheRecoveryOptions();
  ///   }
  /// }
  /// ```
  Future<void> clearCache();

  /// Stream of album loading progress updates.
  ///
  /// Provides real-time updates during album loading operations including:
  /// - Progress percentage (0.0 to 1.0)
  /// - Current operation description
  /// - Number of albums processed
  /// - Total albums to process
  ///
  /// The stream emits updates as albums are loaded from Firebase Storage
  /// and added to the cache. This allows UI components to display
  /// detailed progress information to users.
  ///
  /// Example usage:
  /// ```dart
  /// musicRepo.albumLoadingProgress.listen((progress) {
  ///   updateLoadingUI(progress.message, progress.progress);
  /// });
  /// ```
  Stream<AlbumLoadingProgress> get albumLoadingProgress;
}
