import 'dart:async';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:miniplayer/miniplayer.dart';

import '../../core/di/service_locator.dart';
import '../../data/exceptions/repository_exception.dart';
import '../../data/models/album.dart';
import '../../data/models/song.dart';
import '../../data/repositories/music_repository.dart';
import '../../data/services/image_preload_service.dart';
import '../../data/services/performance_service.dart';
import '../home/track_list_view.dart';

/// Represents the current state of music loading in the application.
///
/// Used to provide granular control over loading UI and behavior.
enum MusicLoadingState {
  /// Initial state before any loading has started
  initializing,

  /// Loading music data from local cache (fast)
  loadingCache,

  /// Loading music data from network/Firebase (slower)
  loadingNetwork,

  /// Music loaded successfully, content is ready
  success,

  /// Loading failed but may have cached content to show
  error,
}

/// Main application controller that manages global app state and music data.
///
/// Handles music library initialization, loading progress tracking, error handling,
/// and navigation between different app views. Integrates with Firebase for data
/// storage and includes performance monitoring for optimal user experience.
class AppController extends GetxController {
  /// Controller for the mini player widget that appears at the bottom of screens.
  final MiniplayerController miniPlayerController = MiniplayerController();

  /// Repository for accessing music data from Firebase storage.
  late final MusicRepository _musicRepository;

  /// Observable list of albums loaded from the music repository.
  final RxList<Album> _albums = <Album>[].obs;

  /// Observable flag indicating whether music data is currently being loaded.
  final RxBool _isLoading = true.obs;

  /// Observable flag indicating whether an error occurred during loading.
  final RxBool _hasError = false.obs;

  /// Observable error message describing any loading failures.
  final RxString _errorMessage = ''.obs;

  /// Observable for the current music loading state (more granular than isLoading).
  final Rx<MusicLoadingState> _loadingState =
      MusicLoadingState.initializing.obs;

  /// Whether a background refresh is in progress (doesn't show loading UI).
  final RxBool _isBackgroundRefreshing = false.obs;

  // Loading progress tracking
  /// Observable progress value (0.0 to 1.0) for music loading operations.
  final RxDouble _loadingProgress = 0.0.obs;

  /// Observable status message describing the current loading operation.
  final RxString _loadingStatusMessage = 'Initializing...'.obs;

  /// Subscription to album loading progress updates
  StreamSubscription<AlbumLoadingProgress>? _progressSubscription;

  /// Set of album IDs that are currently being reloaded (for UI indicators)
  final RxSet<String> _albumsBeingReloaded = <String>{}.obs;

  /// Completers for tracking in-progress album refreshes (for race condition handling)
  /// Allows concurrent callers to wait for the same refresh operation instead of skipping
  final Map<String, Completer<void>> _refreshCompleters = {};

  // Getters
  /// Current list of albums loaded from the music repository.
  List<Album> get albums => _albums;

  /// Whether music data is currently being loaded.
  bool get isLoading => _isLoading.value;

  /// Whether an error occurred during the last loading operation.
  bool get hasError => _hasError.value;

  /// Error message from the last failed operation, if any.
  String get errorMessage => _errorMessage.value;

  /// Current loading progress as a value between 0.0 and 1.0.
  double get loadingProgress => _loadingProgress.value;

  /// Human-readable status message for the current loading operation.
  String get loadingStatusMessage => _loadingStatusMessage.value;

  /// Current loading state for more granular UI control.
  MusicLoadingState get loadingState => _loadingState.value;

  /// Whether a background refresh is currently in progress.
  bool get isBackgroundRefreshing => _isBackgroundRefreshing.value;

  /// Whether the loading screen should be shown.
  ///
  /// Returns true only when we're in the initial loading phase AND have no content.
  /// If we have cached content, we don't show the loading screen even during refresh.
  bool get shouldShowLoadingScreen =>
      _isLoading.value &&
      _albums.isEmpty &&
      (_loadingState.value == MusicLoadingState.initializing ||
          _loadingState.value == MusicLoadingState.loadingCache);

  /// Whether there are more albums available to load.
  ///
  /// Currently returns false as all albums are loaded at once.
  /// This property is kept for compatibility but will be deprecated.
  bool get hasMoreAlbums => false;

  /// Whether additional albums are currently being loaded.
  ///
  /// Currently returns false as pagination is not implemented.
  /// This property is kept for compatibility but will be deprecated.
  bool get isLoadingMore => false;

  /// Checks if a specific album is currently being reloaded
  bool isAlbumLoading(String? albumId) {
    if (albumId == null) {
      return false;
    }
    return _albumsBeingReloaded.contains(albumId);
  }

  @override
  Future<void> onInit() async {
    super.onInit();
    // Initialize repository from ServiceLocator
    _musicRepository = ServiceLocator.get<MusicRepository>();

    // Set up progress listener
    _progressSubscription = _musicRepository.albumLoadingProgress.listen(
      (progress) {
        _loadingStatusMessage.value = progress.message;
        // Only update progress if it's greater than current progress
        // This prevents backward progress during different loading phases
        if (progress.progress > _loadingProgress.value) {
          _loadingProgress.value = progress.progress;
        }
      },
    );

    await _initializeServices();
    await _initializeMusic();
  }

  /// Initializes required services before loading music data.
  Future<void> _initializeServices() async {
    // Initialize image preload service with conservative settings
    ImagePreloadService.instance.initialize(
      config: ImagePreloadConfig.conservative,
    );
  }

  /// Initializes the music library using a cache-first strategy.
  ///
  /// This method prioritizes showing cached content immediately, then refreshes
  /// from the network in the background. This ensures users see content quickly
  /// and never see an error screen if cached data is available.
  ///
  /// Loading flow:
  /// 1. Try to load from cache immediately (fast)
  /// 2. If cache has content, show it and refresh in background
  /// 3. If cache is empty, load from network with loading UI
  /// 4. Only show error if both cache AND network fail with no content
  Future<void> _initializeMusic() async {
    final startTime = DateTime.now();
    const minLoadingDuration = Duration(seconds: 1); // Reduced minimum time

    try {
      _isLoading.value = true;
      _hasError.value = false;
      _loadingProgress.value = 0.0;
      _loadingState.value = MusicLoadingState.initializing;
      _loadingStatusMessage.value = 'Initializing...';

      // Start music loading performance trace
      final performanceService = PerformanceService();
      await performanceService.startMusicLoadTrace();

      // Step 1: Initialize services (10% progress)
      _loadingStatusMessage.value = 'Initializing services...';
      _loadingProgress.value = 0.1;

      // Step 2: Try loading from cache first (fast path)
      _loadingState.value = MusicLoadingState.loadingCache;
      _loadingStatusMessage.value = 'Loading cached music...';
      _loadingProgress.value = 0.2;

      final cachedAlbums = await _musicRepository.getAlbumsFromCacheOnly();

      if (cachedAlbums.isNotEmpty) {
        // Cache hit! Show content immediately
        _albums.value = cachedAlbums;
        _loadingProgress.value = 1.0;
        _loadingStatusMessage.value = 'Music loaded from cache';
        _loadingState.value = MusicLoadingState.success;
        _isLoading.value = false;

        debugPrint(
          'AppController: Loaded ${cachedAlbums.length} albums from cache',
        );

        // Stop performance trace for cache load
        final totalSongs =
            _albums.fold<int>(0, (sum, album) => sum + album.tracks.length);
        await performanceService.stopMusicLoadTrace(
          albumCount: _albums.length,
          songCount: totalSongs,
          fromCache: true,
        );

        // Trigger background refresh to get fresh data
        unawaited(_refreshInBackground());
        return;
      }

      // Step 3: No cache, load from network (slow path with loading UI)
      debugPrint('AppController: No cache found, loading from network');
      _loadingState.value = MusicLoadingState.loadingNetwork;
      _loadingStatusMessage.value = 'Connecting to music library...';
      _loadingProgress.value = 0.3;

      final albums = await _loadAlbumsWithProgress();
      _albums.value = albums;

      _loadingProgress.value = 1.0;
      _loadingStatusMessage.value = 'Music loaded successfully';
      _loadingState.value = MusicLoadingState.success;

      // Stop music loading trace with metrics
      final totalSongs =
          _albums.fold<int>(0, (sum, album) => sum + album.tracks.length);
      await performanceService.stopMusicLoadTrace(
        albumCount: _albums.length,
        songCount: totalSongs,
        fromCache: false,
      );

      // Ensure minimum loading duration for proper UI feedback
      final elapsed = DateTime.now().difference(startTime);
      if (elapsed < minLoadingDuration) {
        await Future<void>.delayed(minLoadingDuration - elapsed);
      }
    } on RepositoryException catch (e) {
      _handleError(e.message);
      _loadingState.value = MusicLoadingState.error;
    } on Exception catch (e) {
      _handleError('Failed to initialize music: $e');
      _loadingState.value = MusicLoadingState.error;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Refreshes music data in the background without showing loading UI.
  ///
  /// This is called after successfully loading from cache to fetch fresh data.
  /// Failures are silently ignored since we already have cached content.
  Future<void> _refreshInBackground() async {
    if (_isBackgroundRefreshing.value) {
      debugPrint('AppController: Background refresh already in progress');
      return;
    }

    try {
      _isBackgroundRefreshing.value = true;
      debugPrint('AppController: Starting background refresh');

      // Clear cache and fetch fresh data
      await _musicRepository.refreshCache();
      final freshAlbums = await _musicRepository.getAlbums();

      if (freshAlbums.isNotEmpty) {
        _albums.value = freshAlbums;
        debugPrint(
          'AppController: Background refresh complete - ${freshAlbums.length} albums',
        );
      }
    } on Exception catch (e) {
      // Silently ignore background refresh failures - we already have cached content
      debugPrint('AppController: Background refresh failed (ignored): $e');
    } finally {
      _isBackgroundRefreshing.value = false;
    }
  }

  /// Load albums with progressive updates and timeout handling
  Future<List<Album>> _loadAlbumsWithProgress() async {
    // Try to get albums with a 30-second timeout
    try {
      return await Future.any([
        _loadAlbumsWithProgressUpdates(),
        Future<void>.delayed(const Duration(seconds: 30)).then<List<Album>>(
          (_) => throw TimeoutException(
            'Loading music timed out after 30 seconds',
            const Duration(seconds: 30),
          ),
        ),
      ]);
    } on Exception catch (e) {
      if (e.toString().contains('timeout') ||
          e.toString().contains('TimeoutException')) {
        // If timeout occurs, try to load from cache only
        _loadingStatusMessage.value = 'Network timeout, checking cache...';
        _loadingProgress.value = 0.8;

        try {
          // Use cache-only method to avoid further network requests
          final cachedAlbums = await _musicRepository.getAlbumsFromCacheOnly();
          if (cachedAlbums.isNotEmpty) {
            return cachedAlbums;
          }
        } on Exception {
          // Cache also failed (this should rarely happen with the cache-only method)
        }

        throw const DataRepositoryException(
          'Unable to load music. Please check your internet connection and try again.',
          'NETWORK_TIMEOUT',
        );
      }
      rethrow;
    }
  }

  /// Load albums with detailed progress updates
  Future<List<Album>> _loadAlbumsWithProgressUpdates() async {
    // Simulate progressive loading with status updates
    _loadingStatusMessage.value = 'Connecting to music library...';
    _loadingProgress.value = 0.3;
    await Future<void>.delayed(const Duration(milliseconds: 500));

    _loadingStatusMessage.value = 'Loading artists...';
    _loadingProgress.value = 0.4;
    await Future<void>.delayed(const Duration(milliseconds: 500));

    _loadingStatusMessage.value = 'Loading albums...';
    _loadingProgress.value = 0.6;

    // Load albums using repository
    final albums = await _musicRepository.getAlbums();

    _loadingStatusMessage.value = 'Processing music data...';
    _loadingProgress.value = 0.9;
    await Future<void>.delayed(const Duration(milliseconds: 300));

    return albums;
  }

  /// Loads more albums from the music repository.
  ///
  /// This method is kept for compatibility but now triggers a full refresh
  /// since all albums are loaded at once. Will be deprecated in future versions.
  Future<void> loadMoreAlbums() async {
    if (_isLoading.value) {
      return;
    }
    await refreshMusic();
  }

  /// Refreshes the music library by clearing cache and reloading from the repository.
  ///
  /// Updates loading progress and status messages during the refresh operation.
  /// Handles errors gracefully and ensures loading state is properly managed.
  /// Ensures minimum loading duration for proper UI feedback.
  Future<void> refreshMusic() async {
    final startTime = DateTime.now();
    const minLoadingDuration = Duration(seconds: 2); // Minimum loading time

    try {
      _isLoading.value = true;
      _loadingProgress.value = 0.0;
      _loadingStatusMessage.value = 'Refreshing music...';

      // Progressive updates for better UX
      _loadingProgress.value = 0.2;
      await Future<void>.delayed(const Duration(milliseconds: 300));

      _loadingStatusMessage.value = 'Clearing cache...';
      _loadingProgress.value = 0.4;
      await _musicRepository.refreshCache();

      _loadingStatusMessage.value = 'Reloading music library...';
      _loadingProgress.value = 0.6;
      await Future<void>.delayed(const Duration(milliseconds: 300));

      // The progress listener will automatically update the UI as albums load
      final albums = await _musicRepository.getAlbums();
      _albums.value = albums;

      // Ensure minimum loading duration for proper UI feedback
      final elapsed = DateTime.now().difference(startTime);
      if (elapsed < minLoadingDuration) {
        await Future<void>.delayed(minLoadingDuration - elapsed);
      }
    } on RepositoryException catch (e) {
      _handleError(e.message);
      // Still enforce minimum duration even on error
      final elapsed = DateTime.now().difference(startTime);
      if (elapsed < minLoadingDuration) {
        await Future<void>.delayed(minLoadingDuration - elapsed);
      }
    } on Exception catch (e) {
      _handleError('Failed to refresh music: $e');
      // Still enforce minimum duration even on error
      final elapsed = DateTime.now().difference(startTime);
      if (elapsed < minLoadingDuration) {
        await Future<void>.delayed(minLoadingDuration - elapsed);
      }
    } finally {
      _isLoading.value = false;
    }
  }

  /// Refreshes a single album from Firebase and updates it in the cache.
  ///
  /// Shows loading indicator for the specific album while refreshing.
  /// Updates only the specified album without affecting other cached data.
  /// If a refresh is already in progress for this album, waits for it to complete
  /// instead of starting a duplicate operation (prevents race conditions).
  ///
  /// [albumId] The unique identifier of the album to refresh.
  Future<void> refreshSingleAlbum(String albumId) async {
    // If a refresh is already in progress for this album, wait for it
    if (_refreshCompleters.containsKey(albumId)) {
      debugPrint('Album $albumId refresh already in progress, waiting...');
      return _refreshCompleters[albumId]!.future;
    }

    // Find the current album
    final currentAlbum = getAlbumById(albumId);
    if (currentAlbum == null) {
      debugPrint('Album $albumId not found in current albums list');
      return;
    }

    debugPrint(
      'Targeted refresh for album: ${currentAlbum.albumName} ($albumId)',
    );

    // Create a completer to track this refresh operation
    final completer = Completer<void>();
    _refreshCompleters[albumId] = completer;

    // Add to loading set to show loading indicator
    _albumsBeingReloaded.add(albumId);

    try {
      // Parse albumId to get artist and album name (format: ${artistName}_${albumName})
      final parts = albumId.split('_');
      if (parts.length < 2) {
        throw Exception('Invalid album ID format: $albumId');
      }

      final artistName = parts[0];
      final albumName =
          parts.sublist(1).join('_'); // Handle album names with underscores

      // Fetch fresh data directly from Firebase for this specific album
      final refreshedAlbum =
          await _fetchSingleAlbumFromFirebase(artistName, albumName, albumId);

      if (refreshedAlbum != null) {
        // Update just this album in our albums list
        final albumIndex = _albums.indexWhere((a) => a.id == albumId);
        if (albumIndex >= 0) {
          final updatedAlbums = List<Album>.from(_albums);
          updatedAlbums[albumIndex] = refreshedAlbum;
          _albums.value = updatedAlbums;

          debugPrint(
            'Successfully refreshed album: ${refreshedAlbum.albumName} with ${refreshedAlbum.tracks.length} tracks',
          );

          // Show a brief success message
          Get.snackbar(
            'Album Refreshed',
            '${refreshedAlbum.albumName} has been updated',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green.withValues(alpha: 0.8),
            colorText: Colors.white,
            margin: const EdgeInsets.all(16),
          );
        }
      } else {
        throw Exception('Failed to fetch album data from Firebase');
      }

      // Complete successfully
      completer.complete();
    } on Exception catch (e) {
      debugPrint('Unexpected error refreshing album $albumId: $e');

      // Show generic error message
      Get.snackbar(
        'Refresh Failed',
        'Unable to refresh ${currentAlbum.albumName}. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );

      // Complete with error so waiting callers know it failed
      completer.completeError(e);
    } finally {
      // Remove from tracking maps
      _refreshCompleters.remove(albumId);
      _albumsBeingReloaded.remove(albumId);
    }
  }

  /// Handles error states by updating reactive variables and logging the error.
  ///
  /// [message] The error message to display to the user and log for debugging.
  void _handleError(String message) {
    _hasError.value = true;
    _errorMessage.value = message;
    _loadingProgress.value = 0.0;
    _loadingStatusMessage.value = 'Error loading music';
    debugPrint(message);
  }

  /// Opens the track list view as a bottom sheet for the specified album.
  ///
  /// Includes performance monitoring and targeted track loading for albums with missing tracks.
  /// Shows loading indicators for individual albums and only reloads that specific album's data.
  ///
  /// [album] The album whose tracks should be displayed.
  Future<void> openTrackList(Album album) async {
    var albumToShow = album;

    // Always try to get the most up-to-date album from our albums list first
    if (album.id != null) {
      final currentAlbum = getAlbumById(album.id!);
      if (currentAlbum != null) {
        albumToShow = currentAlbum;
        debugPrint(
          'Using current album from albums list with ${currentAlbum.tracks.length} tracks',
        );
      }
    }

    // Defensive check: if album has no tracks, try to reload just this album
    if (albumToShow.tracks.isEmpty && albumToShow.id != null) {
      final albumId = albumToShow.id!;

      // If a reload is already in progress for this album, wait for it
      if (_refreshCompleters.containsKey(albumId)) {
        debugPrint(
          'Album "${albumToShow.albumName}" reload already in progress, waiting...',
        );
        try {
          await _refreshCompleters[albumId]!.future;
          // After waiting, get the updated album
          final updatedAlbum = getAlbumById(albumId);
          if (updatedAlbum != null && updatedAlbum.tracks.isNotEmpty) {
            albumToShow = updatedAlbum;
          }
        } on Exception {
          // If the in-progress reload failed, continue with what we have
        }
      } else {
        debugPrint(
          'Album "${albumToShow.albumName}" has no tracks, attempting targeted reload...',
        );

        // Create a completer to track this reload operation
        final completer = Completer<void>();
        _refreshCompleters[albumId] = completer;

        // Add to loading set to show loading indicator
        _albumsBeingReloaded.add(albumId);

        try {
          // First, try to find the album in our current albums list
          final foundAlbum = getAlbumById(albumId);
          if (foundAlbum != null && foundAlbum.tracks.isNotEmpty) {
            debugPrint(
              'Found album with ${foundAlbum.tracks.length} tracks in current list',
            );
            albumToShow = foundAlbum;
          } else {
            // Use targeted loading - get tracks for just this album
            debugPrint('Loading tracks for album ID: $albumId');
            final tracks = await _musicRepository.getTracks(albumId);

            if (tracks.isNotEmpty) {
              debugPrint(
                'Successfully loaded ${tracks.length} tracks for album',
            );

              // Create updated album with the loaded tracks
              albumToShow = albumToShow.copyWith(tracks: tracks);

              // Update just this album in our albums list
              final albumIndex = _albums.indexWhere((a) => a.id == albumId);
              if (albumIndex >= 0) {
                final updatedAlbums = List<Album>.from(_albums);
                updatedAlbums[albumIndex] = albumToShow;
                _albums.value = updatedAlbums;
                debugPrint('Updated album in albums list');
              }
            } else {
              debugPrint(
                'Warning: No tracks found for album after targeted reload',
              );
            }
          }
          completer.complete();
        } on Exception catch (e) {
          debugPrint('Failed to reload album tracks: $e');
          completer.completeError(e);
          // Continue with original album even if it has no tracks
        } finally {
          // Remove from tracking maps
          _refreshCompleters.remove(albumId);
          _albumsBeingReloaded.remove(albumId);
        }
      }
    }

    // Track album loading performance
    final performanceService = PerformanceService();
    await performanceService
        .startAlbumLoadTrace(albumToShow.id ?? 'unknown_album');

    await Get.bottomSheet<void>(
      Scaffold(body: TrackListView(album: albumToShow)),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );

    // Stop album loading trace
    await performanceService.stopAlbumLoadTrace(
      trackCount: albumToShow.tracks.length,
    );
  }

  /// Retrieves a specific album by its unique identifier.
  ///
  /// [id] The unique identifier of the album to retrieve.
  /// Returns the album if found, or null if no album with the given ID exists.
  Album? getAlbumById(String id) {
    try {
      return _albums.firstWhere((album) => album.id == id);
    } on Exception {
      return null;
    }
  }

  /// Searches for albums matching the given query string.
  ///
  /// Performs case-insensitive search across album names and artist names.
  /// Returns all albums if the query is empty.
  ///
  /// [query] The search term to match against album and artist names.
  /// Returns a list of albums that match the search criteria.
  List<Album> searchAlbums(String query) {
    if (query.isEmpty) {
      return _albums;
    }

    final lowercaseQuery = query.toLowerCase();
    return _albums
        .where(
          (album) =>
              album.albumName.toLowerCase().contains(lowercaseQuery) ||
              (album.artist?.toLowerCase().contains(lowercaseQuery) ?? false),
        )
        .toList();
  }

  /// Searches for songs matching the given query string across all albums.
  ///
  /// Performs case-insensitive search across song names and artist names.
  /// Returns an empty list if the query is empty.
  ///
  /// [query] The search term to match against song and artist names.
  /// Returns a list of songs that match the search criteria.
  List<Song> searchSongs(String query) {
    if (query.isEmpty) {
      return [];
    }

    final lowercaseQuery = query.toLowerCase();
    final results = <Song>[];

    for (final album in _albums) {
      for (final song in album.tracks) {
        if (song.songName.toLowerCase().contains(lowercaseQuery) ||
            song.artist.toLowerCase().contains(lowercaseQuery)) {
          results.add(song);
        }
      }
    }

    return results;
  }

  /// Fetches a single album directly from Firebase Storage without affecting the cache.
  Future<Album?> _fetchSingleAlbumFromFirebase(
    String artistName,
    String albumName,
    String albumId,
  ) async {
    try {
      final storage = FirebaseStorage.instance;
      final albumRef =
          storage.ref().child('Artist').child(artistName).child(albumName);

      // Get all items in the album folder with timeout
      final result = await albumRef.listAll().timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException(
              'Firebase fetch timeout',
              const Duration(seconds: 10),
            ),
          );

      String? albumArt;
      final tracks = <Song>[];

      // First pass: find album art
      for (final item in result.items) {
        final itemName = item.name;
        if (_isImageFile(itemName)) {
          try {
            albumArt = await item.getDownloadURL().timeout(
                  const Duration(seconds: 5),
                  onTimeout: () => throw TimeoutException(
                    'Album art URL timeout',
                    const Duration(seconds: 5),
                  ),
                );
            break;
          } on Exception catch (e) {
            debugPrint('Failed to get album art URL: $e');
          }
        }
      }

      // Second pass: process songs
      for (final songRef in result.items) {
        final songName = songRef.name;

        // Skip image files
        if (_isImageFile(songName)) {
          continue;
        }

        try {
          final songUrl = await songRef.getDownloadURL().timeout(
                const Duration(seconds: 5),
                onTimeout: () => throw TimeoutException(
                  'Song URL timeout for $songName',
                  const Duration(seconds: 5),
                ),
              );

          tracks.add(
            Song(
              id: '${artistName}_${albumName}_$songName',
              songName: songName,
              songUrl: songUrl,
              artist: artistName,
              albumName: albumName,
            ),
          );
        } on Exception catch (e) {
          debugPrint('Failed to load song $songName: $e');
          // Continue with other songs
        }
      }

      if (tracks.isNotEmpty) {
        return Album(
          id: albumId,
          albumName: albumName,
          tracks: tracks,
          albumCover: albumArt,
          artist: artistName,
        );
      }

      return null;
    } on Exception catch (e) {
      debugPrint('Error fetching album from Firebase: $e');
      return null;
    }
  }

  /// Checks if a file is an image based on its extension.
  bool _isImageFile(String fileName) {
    final lowerName = fileName.toLowerCase();
    return lowerName.endsWith('.jpg') ||
        lowerName.endsWith('.jpeg') ||
        lowerName.endsWith('.png') ||
        lowerName.endsWith('.gif') ||
        lowerName.endsWith('.webp');
  }

  @override
  void onClose() {
    // Cancel progress subscription
    _progressSubscription?.cancel();
    _progressSubscription = null;

    // Clear all reactive variables to prevent memory leaks
    _albums.clear();
    _isLoading.value = false;
    _hasError.value = false;
    _errorMessage.value = '';
    _loadingProgress.value = 0.0;
    _loadingStatusMessage.value = '';

    // Dispose of the MiniplayerController
    miniPlayerController.dispose();

    // Call super to complete disposal
    super.onClose();
  }
}
