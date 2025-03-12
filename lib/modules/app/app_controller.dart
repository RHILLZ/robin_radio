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

  // Pagination control
  final int _pageSize = 5; // Number of albums to load at once
  final RxBool _hasMoreAlbums = true.obs;
  final RxBool _isLoadingMore = false.obs;
  final RxInt _currentPage = 0.obs;

  // Cache control
  static const String _cacheKey = 'robin_radio_music_cache';
  static const Duration _cacheExpiry = Duration(hours: 24);

  // Getters
  List<Album> get albums => _albums;
  bool get isLoading => _isLoading.value;
  bool get hasError => _hasError.value;
  String get errorMessage => _errorMessage.value;
  bool get hasMoreAlbums => _hasMoreAlbums.value;
  bool get isLoadingMore => _isLoadingMore.value;

  @override
  void onInit() async {
    super.onInit();
    await _initializeMusic();
  }

  Future<void> _initializeMusic() async {
    try {
      _isLoading.value = true;
      _hasError.value = false;

      // Try to load from cache first
      final bool cacheLoaded = await _loadFromCache();

      // If cache is expired or empty, load from Firebase
      if (!cacheLoaded) {
        await _loadInitialBatch();
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
      final prefs = await SharedPreferences.getInstance();
      final String encoded =
          jsonEncode(_albums.map((album) => album.toJson()).toList());
      await prefs.setString(_cacheKey, encoded);

      final now = DateTime.now();
      await prefs.setString('${_cacheKey}_time', now.toIso8601String());
    } catch (e) {
      debugPrint('Cache saving error: $e');
    }
  }

  Future<void> _loadInitialBatch() async {
    _currentPage.value = 0;
    _albums.clear();
    _hasMoreAlbums.value = true;
    await loadMoreAlbums();
  }

  Future<void> loadMoreAlbums() async {
    if (_isLoadingMore.value || !_hasMoreAlbums.value) return;

    try {
      _isLoadingMore.value = true;

      final storageRef = storage.ref().child('Artist');
      final ListResult artistResult = await storageRef.listAll();

      // Calculate pagination indices
      final int startIndex = _currentPage.value * _pageSize;
      final int endIndex = startIndex + _pageSize;
      final int totalArtists = artistResult.prefixes.length;

      // Check if we've reached the end
      if (startIndex >= totalArtists) {
        _hasMoreAlbums.value = false;
        return;
      }

      // Get the subset of artists for this page
      final artistsToLoad = artistResult.prefixes.sublist(
          startIndex, endIndex > totalArtists ? totalArtists : endIndex);

      final List<Album> newAlbums = [];

      // Process each artist
      for (final artist in artistsToLoad) {
        final nameOfArtist = artist.name;
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
      }

      // Add new albums to the list
      _albums.addAll(newAlbums);
      _currentPage.value++;

      // Update hasMoreAlbums flag
      _hasMoreAlbums.value = endIndex < totalArtists;

      // Save to cache if we've loaded all albums or have a significant number
      if (!_hasMoreAlbums.value || _albums.length >= 10) {
        _saveToCache();
      }
    } catch (e) {
      _handleError('Failed to load more albums: $e');
    } finally {
      _isLoadingMore.value = false;
    }
  }

  void refreshMusic() async {
    _isLoading.value = true;
    await _loadInitialBatch();
    _isLoading.value = false;
  }

  void _handleError(String message) {
    _hasError.value = true;
    _errorMessage.value = message;
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
