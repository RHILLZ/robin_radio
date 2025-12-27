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

  /// Observable elapsed time since loading started
  final Rx<Duration?> _elapsedTime = Rx<Duration?>(null);

  /// Observable estimated time remaining until completion
  final Rx<Duration?> _estimatedTimeRemaining = Rx<Duration?>(null);

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

  /// Elapsed time since loading started
  Duration? get elapsedTime => _elapsedTime.value;

  /// Estimated time remaining until completion
  Duration? get estimatedTimeRemaining => _estimatedTimeRemaining.value;

  /// Current loading state for more granular UI control.
  MusicLoadingState get loadingState => _loadingState.value;

  /// Whether a background refresh is currently in progress.
  bool get isBackgroundRefreshing => _isBackgroundRefreshing.value;

  /// Whether the loading screen should be shown (blocking load).
  ///
  /// Returns true when we're loading AND have no valid content to display.
  /// The loading screen blocks all user interaction until music is fully loaded.
  /// This ensures users can't navigate to incomplete views during loading.
  bool get shouldShowLoadingScreen {
    // PRIMARY CHECK: If progress is less than 100%, ALWAYS show loading screen
    // This ensures we wait for ALL albums to be loaded, not just some
    if (_loadingProgress.value < 1.0) {
      return true;
    }

    // SECONDARY CHECK: If progress is 100% but albums aren't valid yet, keep showing
    // This handles the case where loading completes but albums are empty or invalid
    if (_loadingProgress.value >= 1.0 &&
        !_areAlbumsValid(_albums) &&
        _isLoading.value) {
      return true;
    }

    // TERTIARY CHECK: If loading is true but no valid albums yet, show loading screen
    if (_isLoading.value && !_areAlbumsValid(_albums)) {
      return true;
    }

    // Otherwise, hide loading screen (progress is 100% and we have valid albums OR loading is false)
    return false;
  }

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

  /// Validates that an album has complete data (at least one track with valid URL).
  ///
  /// An album is considered complete if it has at least one track with a non-empty songUrl.
  bool _isAlbumComplete(Album album) {
    if (album.tracks.isEmpty) {
      return false;
    }
    return album.tracks.any((track) => track.songUrl.isNotEmpty);
  }

  /// Validates that the albums list has at least one complete album.
  ///
  /// Used to determine if cached content is valid for display.
  bool _areAlbumsValid(List<Album> albums) {
    if (albums.isEmpty) {
      return false;
    }
    return albums.any(_isAlbumComplete);
  }

  /// Whether content is ready for user interaction.
  ///
  /// Returns true only when we have valid albums AND are not in a loading state.
  bool get isContentReady => _areAlbumsValid(_albums) && !_isLoading.value;

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
        // Exception: allow progress to reset to 0 if we're starting fresh
        if (progress.progress > _loadingProgress.value ||
            (_loadingProgress.value >= 1.0 && progress.progress < 0.1)) {
          _loadingProgress.value = progress.progress;
        }
        // Update time tracking
        _elapsedTime.value = progress.elapsedTime;
        _estimatedTimeRemaining.value = progress.estimatedTimeRemaining;

        // When progress reaches 100%, ensure we have valid albums before allowing
        // loading screen to disappear (handled by shouldShowLoadingScreen)
        // Note: shouldShowLoadingScreen will keep screen visible until progress = 100%
      },
      onError: (Object error) {
        debugPrint('AppController: Progress stream error: $error');
        // Don't update progress on error, but log it
      },
      onDone: () {
        debugPrint('AppController: Progress stream closed');
        // Stream closed - if progress isn't 100%, something went wrong
        if (_loadingProgress.value < 1.0) {
          debugPrint(
            'AppController: Progress stream closed before reaching 100% (${_loadingProgress.value})',
          );
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
      final performanceService = Get.find<PerformanceService>();
      await performanceService.startMusicLoadTrace();

      // Step 1: Initialize services
      _loadingStatusMessage.value = 'Initializing services...';
      _loadingProgress.value = 0.0;

      // Step 2: Try loading from cache first (fast path)
      _loadingState.value = MusicLoadingState.loadingCache;
      _loadingStatusMessage.value = 'Loading cached music...';
      _loadingProgress.value =
          0.0; // Let repository or cache result set progress

      final cachedAlbums = await _musicRepository.getAlbumsFromCacheOnly();

      // Validate that cache has complete albums (with tracks)
      if (_areAlbumsValid(cachedAlbums)) {
        // Valid cache hit! Show content immediately
        _albums.value = cachedAlbums;
        _loadingProgress.value = 1.0;
        _loadingStatusMessage.value = 'Music loaded from cache';
        _loadingState.value = MusicLoadingState.success;

        // Log incomplete albums for debugging
        final incompleteCount =
            cachedAlbums.where((a) => !_isAlbumComplete(a)).length;
        if (incompleteCount > 0) {
          debugPrint(
            'AppController: $incompleteCount albums have incomplete data',
          );
        }

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

        // Ensure minimum loading duration to prevent UI flicker
        final elapsed = DateTime.now().difference(startTime);
        if (elapsed < minLoadingDuration) {
          await Future<void>.delayed(minLoadingDuration - elapsed);
        }

        _isLoading.value = false;

        // Trigger background refresh to get fresh data
        unawaited(_refreshInBackground());
        return;
      } else if (cachedAlbums.isNotEmpty) {
        debugPrint(
          'AppController: Cache has ${cachedAlbums.length} albums but none are complete, loading from network',
        );
      }

      // Step 3: No cache, load from network (slow path with loading UI)
      debugPrint('AppController: No cache found, loading from network');
      _loadingState.value = MusicLoadingState.loadingNetwork;
      _loadingStatusMessage.value = 'Connecting to music library...';
      // Don't set hardcoded progress - let repository stream handle it
      _loadingProgress.value = 0.0;

      final albums = await _loadAlbumsWithProgress();

      // Set albums and clear any previous errors immediately when albums are loaded
      // Clear errors as soon as we have albums, even if they're not fully valid yet
      // This prevents error screen from showing when albums exist
      _albums.value = albums;
      if (albums.isNotEmpty) {
        // Clear errors whenever we have albums, regardless of validity
        // Validity will be checked later to determine if loading should complete
        _hasError.value = false;
        _errorMessage.value = '';
      }

      // Wait for progress to reach 100% - the repository emits final progress (100%)
      // before returning, but we need to ensure the stream has processed it
      // Poll until progress is 100% or timeout after reasonable delay
      var attempts = 0;
      const maxAttempts = 50; // 5 seconds max wait (50 * 100ms)
      while (_loadingProgress.value < 1.0 && attempts < maxAttempts) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        attempts++;
      }

      // If progress still isn't 100%, set it manually as fallback
      // This should rarely happen since repository emits 100% before returning
      if (_loadingProgress.value < 1.0) {
        debugPrint(
          'AppController: Progress not at 100% after wait, setting manually',
        );
        _loadingProgress.value = 1.0;
      }

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

      // Only set loading to false after progress is 100% and albums are valid
      // The shouldShowLoadingScreen check will ensure screen stays visible until then
      if (_loadingProgress.value >= 1.0 && _areAlbumsValid(_albums)) {
        // Successfully loaded valid albums - clear any errors and stop loading
        _hasError.value = false;
        _errorMessage.value = '';
        _isLoading.value = false;
      } else if (_albums.isEmpty) {
        // If albums are empty after loading, this is an error condition
        _handleError(
          'No albums found. Please check your internet connection and try again.',
        );
      } else if (_loadingProgress.value >= 1.0 && !_areAlbumsValid(_albums)) {
        // Albums loaded but none have valid tracks - this is also an error
        _handleError(
          'Albums loaded but no playable tracks found. Please check your internet connection and try again.',
        );
      }
    } on RepositoryException catch (e) {
      _handleError(e.message);
      _loadingState.value = MusicLoadingState.error;
    } on Exception catch (e) {
      _handleError('Failed to initialize music: $e');
      _loadingState.value = MusicLoadingState.error;
    } finally {
      // Only set loading to false if progress is 100% and albums are valid
      // This ensures loading screen stays visible until everything is complete
      if (_loadingProgress.value >= 1.0 && _areAlbumsValid(_albums)) {
        _isLoading.value = false;
      } else if (_hasError.value) {
        // On error, hide loading screen even if not complete
        _isLoading.value = false;
      }
      // Otherwise, keep loading true - shouldShowLoadingScreen will handle visibility
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

      // Only replace albums if fresh data is valid (has complete albums)
      if (_areAlbumsValid(freshAlbums)) {
        _albums.value = freshAlbums;
        debugPrint(
          'AppController: Background refresh complete - ${freshAlbums.length} albums',
        );
      } else {
        debugPrint(
          'AppController: Background refresh returned invalid data, keeping cache',
        );
      }
    } on Exception catch (e) {
      // Silently ignore background refresh failures - we already have cached content
      debugPrint('AppController: Background refresh failed (ignored): $e');
    } finally {
      _isBackgroundRefreshing.value = false;
    }
  }

  /// Load albums with progressive updates and timeout handling.
  ///
  /// Uses a completer-based approach to handle the race condition between
  /// timeout and album loading. If albums finish loading after the timeout
  /// fires, they are still applied to the UI and the error state is cleared.
  Future<List<Album>> _loadAlbumsWithProgress() async {
    // Create a completer to handle the result
    final completer = Completer<List<Album>>();
    var timeoutFired = false;

    // Start the actual loading
    final loadingFuture = _loadAlbumsWithProgressUpdates();

    // Set up timeout timer (2 minutes)
    // The two-pass loading approach (discover all artists, then load albums) can take
    // longer than 30 seconds for large music libraries
    final timeoutTimer = Timer(const Duration(minutes: 2), () async {
      if (!completer.isCompleted) {
        timeoutFired = true;

        // Try cache first
        _loadingStatusMessage.value =
            'Loading taking longer than expected, checking cache...';
        _loadingProgress.value = 0.8;

        try {
          final cachedAlbums = await _musicRepository.getAlbumsFromCacheOnly();
          if (cachedAlbums.isNotEmpty && !completer.isCompleted) {
            completer.complete(cachedAlbums);
            return;
          }
        } on Exception {
          // Cache failed, continue to error
        }

        // No cache available, complete with error
        if (!completer.isCompleted) {
          completer.completeError(
            const DataRepositoryException(
              'Loading music took too long. Please check your internet connection and try again.',
              'NETWORK_TIMEOUT',
            ),
          );
        }
      }
    });

    // Wait for loading to complete
    unawaited(
      loadingFuture.then((albums) {
        timeoutTimer.cancel();

        if (!completer.isCompleted) {
          // Normal case: loading completed before timeout
          completer.complete(albums);
        } else if (timeoutFired && albums.isNotEmpty) {
          // KEY FIX: Loading completed AFTER timeout - update albums silently
          // This prevents the error screen from showing when albums eventually load
          debugPrint(
            'AppController: Albums loaded after timeout (${albums.length} albums), updating UI...',
          );
          _albums.value = albums;
          _hasError.value = false;
          _errorMessage.value = '';
          _loadingProgress.value = 1.0;
          _loadingStatusMessage.value = 'Music loaded successfully';
          _loadingState.value = MusicLoadingState.success;
          _isLoading.value = false;
        }
      }).catchError((Object error) {
        timeoutTimer.cancel();
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
      }),
    );

    return completer.future;
  }

  /// Load albums with detailed progress updates
  ///
  /// Progress updates come from the repository's progress stream, not hardcoded values.
  /// This ensures accurate progress based on actual album processing.
  Future<List<Album>> _loadAlbumsWithProgressUpdates() async {
    // Let the repository's progress stream handle all progress updates
    // The repository will emit progress from 0.1 (discovery) to 1.0 (complete)
    final albums = await _musicRepository.getAlbums();
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
    final performanceService = Get.find<PerformanceService>();
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
