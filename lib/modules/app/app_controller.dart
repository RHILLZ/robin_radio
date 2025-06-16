import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:miniplayer/miniplayer.dart';
import '../../data/models/album.dart';
import '../../data/models/song.dart';
import '../../data/repositories/music_repository.dart';
import '../../data/repositories/firebase_music_repository.dart';
import '../../data/exceptions/repository_exception.dart';
import '../../data/services/performance_service.dart';
import '../home/trackListView.dart';

class AppController extends GetxController {
  final MiniplayerController miniPlayerController = MiniplayerController();
  final MusicRepository _musicRepository = FirebaseMusicRepository();
  final RxList<Album> _albums = <Album>[].obs;
  final RxBool _isLoading = true.obs;
  final RxBool _hasError = false.obs;
  final RxString _errorMessage = ''.obs;

  // Loading progress tracking
  final RxDouble _loadingProgress = 0.0.obs;
  final RxString _loadingStatusMessage = 'Initializing...'.obs;

  // Getters
  List<Album> get albums => _albums;
  bool get isLoading => _isLoading.value;
  bool get hasError => _hasError.value;
  String get errorMessage => _errorMessage.value;
  double get loadingProgress => _loadingProgress.value;
  String get loadingStatusMessage => _loadingStatusMessage.value;
  // These properties are kept for compatibility but will be deprecated
  bool get hasMoreAlbums => false;
  bool get isLoadingMore => false;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _initializeMusic();
  }

  Future<void> _initializeMusic() async {
    try {
      _isLoading.value = true;
      _hasError.value = false;
      _loadingProgress.value = 0.0;
      _loadingStatusMessage.value = 'Initializing...';

      // Start music loading performance trace
      final performanceService = PerformanceService();
      await performanceService.startMusicLoadTrace();

      _loadingStatusMessage.value = 'Loading music...';
      _loadingProgress.value = 0.2;

      // Load albums using repository
      final albums = await _musicRepository.getAlbums();
      _albums.value = albums;

      _loadingProgress.value = 1.0;
      _loadingStatusMessage.value = 'Music loaded successfully';

      // Stop music loading trace with metrics
      final totalSongs =
          _albums.fold<int>(0, (sum, album) => sum + album.tracks.length);
      await performanceService.stopMusicLoadTrace(
        albumCount: _albums.length,
        songCount: totalSongs,
        fromCache: false, // Repository handles caching internally
      );
    } on RepositoryException catch (e) {
      _handleError(e.message);
    } catch (e) {
      _handleError('Failed to initialize music: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  // This method is kept for compatibility but now loads all albums
  Future<void> loadMoreAlbums() async {
    if (_isLoading.value) return;
    refreshMusic();
  }

  Future<void> refreshMusic() async {
    try {
      _isLoading.value = true;
      _loadingProgress.value = 0.0;
      _loadingStatusMessage.value = 'Refreshing music...';

      // Clear cache and reload from repository
      await _musicRepository.refreshCache();
      final albums = await _musicRepository.getAlbums();
      _albums.value = albums;

      _loadingProgress.value = 1.0;
      _loadingStatusMessage.value = 'Music refreshed successfully';
    } on RepositoryException catch (e) {
      _handleError(e.message);
    } catch (e) {
      _handleError('Failed to refresh music: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  void _handleError(String message) {
    _hasError.value = true;
    _errorMessage.value = message;
    _loadingProgress.value = 0.0;
    _loadingStatusMessage.value = 'Error loading music';
    debugPrint(message);
  }

  Future<void> openTrackList(Album album) async {
    // Track album loading performance
    final performanceService = PerformanceService();
    await performanceService.startAlbumLoadTrace(album.id ?? 'unknown_album');

    Get.bottomSheet<void>(
      Scaffold(body: TrackListView(album: album)),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );

    // Stop album loading trace
    await performanceService.stopAlbumLoadTrace(
      trackCount: album.tracks.length,
    );
  }

  // Get a specific album by ID
  Album? getAlbumById(String id) {
    try {
      return _albums.firstWhere((album) => album.id == id);
    } catch (e) {
      return null;
    }
  }

  // Search functionality
  List<Album> searchAlbums(String query) {
    if (query.isEmpty) return _albums;

    final lowercaseQuery = query.toLowerCase();
    return _albums
        .where(
          (album) =>
              album.albumName.toLowerCase().contains(lowercaseQuery) ||
              (album.artist?.toLowerCase().contains(lowercaseQuery) ?? false),
        )
        .toList();
  }

  List<Song> searchSongs(String query) {
    if (query.isEmpty) return [];

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

  @override
  void onClose() {
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
