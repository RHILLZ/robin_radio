import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:miniplayer/miniplayer.dart';
import 'package:robin_radio/data/models/album.dart';
import 'package:robin_radio/data/models/song.dart';
import 'package:robin_radio/modules/home/trackListView.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AppController extends GetxController {
  final MiniplayerController miniPlayerController = MiniplayerController();
  final storage = FirebaseStorage.instance;
  final RxList<Album> _albums = <Album>[].obs;
  final RxBool _isLoading = true.obs;
  final RxBool _hasError = false.obs;
  final RxString _errorMessage = ''.obs;

  // Loading progress tracking
  final RxDouble _loadingProgress = 0.0.obs;
  final RxString _loadingStatusMessage = 'Initializing...'.obs;

  // Cache control
  static const String _cacheKey = 'robin_radio_music_cache';
  static const Duration _cacheExpiry = Duration(hours: 24);

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
  void onInit() async {
    super.onInit();
    await _initializeMusic();
  }

  Future<void> _initializeMusic() async {
    try {
      _isLoading.value = true;
      _hasError.value = false;
      _loadingProgress.value = 0.0;
      _loadingStatusMessage.value = 'Initializing...';

      // Try to load from cache first
      _loadingStatusMessage.value = 'Checking cache...';
      _loadingProgress.value = 0.1;
      final bool cacheLoaded = await _loadFromCache();

      // If cache is expired or empty, load from Firebase
      if (!cacheLoaded) {
        _loadingStatusMessage.value = 'Loading from cloud...';
        _loadingProgress.value = 0.2;
        await _loadAllAlbums();
      } else {
        _loadingProgress.value = 1.0;
        _loadingStatusMessage.value = 'Music loaded from cache';
      }
    } catch (e) {
      _handleError('Failed to initialize music: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cachedData = prefs.getString(_cacheKey);
      final String? cachedTimeStr = prefs.getString('${_cacheKey}_time');

      if (cachedData != null && cachedTimeStr != null) {
        final cachedTime = DateTime.parse(cachedTimeStr);

        // Check if cache is still valid
        if (DateTime.now().difference(cachedTime) < _cacheExpiry) {
          _loadingStatusMessage.value = 'Loading from cache...';
          _loadingProgress.value = 0.5;
          final List<dynamic> decoded = jsonDecode(cachedData);
          _albums.value = decoded.map((item) => Album.fromJson(item)).toList();
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Cache loading error: $e');
      return false;
    }
  }

  Future<void> _saveToCache() async {
    try {
      _loadingStatusMessage.value = 'Saving to cache...';
      _loadingProgress.value = 0.9;
      final prefs = await SharedPreferences.getInstance();
      final String encoded =
          jsonEncode(_albums.map((album) => album.toJson()).toList());
      await prefs.setString(_cacheKey, encoded);

      final now = DateTime.now();
      await prefs.setString('${_cacheKey}_time', now.toIso8601String());

      _loadingProgress.value = 1.0;
      _loadingStatusMessage.value = 'Music loaded successfully';
    } catch (e) {
      debugPrint('Cache saving error: $e');
    }
  }

  Future<void> _loadAllAlbums() async {
    try {
      _albums.clear();

      final storageRef = storage.ref().child('Artist');
      _loadingStatusMessage.value = 'Fetching artists...';
      _loadingProgress.value = 0.3;
      final ListResult artistResult = await storageRef.listAll();
      final List<Album> newAlbums = [];

      final int totalArtists = artistResult.prefixes.length;
      int processedArtists = 0;

      // Process each artist
      for (final artist in artistResult.prefixes) {
        final nameOfArtist = artist.name;
        _loadingStatusMessage.value = 'Loading music from $nameOfArtist...';

        final ListResult albumsResult = await artist.listAll();

        // Process each album
        for (final album in albumsResult.prefixes) {
          final nameOfAlbum = album.name;
          String? albumArt;
          final List<Song> tracks = [];

          // Get all songs in the album
          final ListResult songsResult = await album.listAll();

          // First pass: find album art
          for (final item in songsResult.items) {
            final nameOfItem = item.name;
            if (nameOfItem.endsWith('.jpg') || nameOfItem.endsWith('.png')) {
              albumArt = await item.getDownloadURL();
              break;
            }
          }

          // Second pass: process songs
          for (final song in songsResult.items) {
            final nameOfSong = song.name;

            // Skip image files
            if (nameOfSong.endsWith('.jpg') ||
                nameOfSong.endsWith('.png') ||
                nameOfSong.endsWith('.jpeg')) {
              continue;
            }

            // Get song URL with retry logic
            String? url;
            for (int attempt = 0; attempt < 3; attempt++) {
              try {
                url = await song.getDownloadURL();
                break;
              } catch (e) {
                if (attempt == 2) rethrow;
                await Future.delayed(const Duration(seconds: 1));
              }
            }

            if (url != null) {
              tracks.add(Song(
                id: '${nameOfArtist}_${nameOfAlbum}_$nameOfSong',
                songName: nameOfSong,
                songUrl: url,
                artist: nameOfArtist,
                albumName: nameOfAlbum,
              ));
            }
          }

          // Only add albums that have tracks
          if (tracks.isNotEmpty) {
            newAlbums.add(Album(
              id: '${nameOfArtist}_$nameOfAlbum',
              albumName: nameOfAlbum,
              tracks: tracks,
              albumCover: albumArt,
              artist: nameOfArtist,
            ));
          }
        }

        // Update progress after each artist is processed
        processedArtists++;
        // Calculate progress between 0.3 and 0.8 based on artist processing
        _loadingProgress.value =
            0.3 + (0.5 * (processedArtists / totalArtists));
      }

      // Add all albums to the list
      _albums.addAll(newAlbums);

      // Save to cache
      _saveToCache();
    } catch (e) {
      _handleError('Failed to load albums: $e');
    }
  }

  // This method is kept for compatibility but now loads all albums
  Future<void> loadMoreAlbums() async {
    if (_isLoading.value) return;
    refreshMusic();
  }

  void refreshMusic() async {
    _isLoading.value = true;
    _loadingProgress.value = 0.0;
    _loadingStatusMessage.value = 'Refreshing music...';
    await _loadAllAlbums();
    _isLoading.value = false;
  }

  void _handleError(String message) {
    _hasError.value = true;
    _errorMessage.value = message;
    _loadingProgress.value = 0.0;
    _loadingStatusMessage.value = 'Error loading music';
    debugPrint(message);
  }

  void openTrackList(Album album) {
    Get.bottomSheet(
      Scaffold(body: TrackListView(album: album)),
      isScrollControlled: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
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
    return _albums.where((album) {
      return album.albumName.toLowerCase().contains(lowercaseQuery) ||
          (album.artist?.toLowerCase().contains(lowercaseQuery) ?? false);
    }).toList();
  }

  List<Song> searchSongs(String query) {
    if (query.isEmpty) return [];

    final lowercaseQuery = query.toLowerCase();
    final List<Song> results = [];

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
}
