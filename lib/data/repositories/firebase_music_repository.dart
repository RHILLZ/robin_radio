import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../exceptions/repository_exception.dart';
import '../models/album.dart';
import '../models/song.dart';
import 'music_repository.dart';

/// Firebase implementation of [MusicRepository].
///
/// Provides music data access through Firebase Storage with local caching,
/// retry logic, and comprehensive error handling.
class FirebaseMusicRepository implements MusicRepository {
  /// Factory constructor returning singleton instance.
  factory FirebaseMusicRepository() => _instance;
  FirebaseMusicRepository._internal();

  /// Singleton instance.
  static final FirebaseMusicRepository _instance =
      FirebaseMusicRepository._internal();

  // Firebase Storage instance
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Cache configuration
  static const String _cacheKey = 'robin_radio_music_cache';
  static const String _cacheTimeKey = '${_cacheKey}_time';
  static const Duration _cacheExpiry = Duration(hours: 24);
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 1);

  // In-memory cache for performance
  List<Album>? _albumsCache;
  DateTime? _cacheTime;

  // Stream controller for radio mode
  StreamController<Song>? _radioStreamController;

  // Stream controller for album loading progress
  final StreamController<AlbumLoadingProgress> _progressController = 
      StreamController<AlbumLoadingProgress>.broadcast();

  @override
  Future<List<Album>> getAlbums() async {
    try {
      // Check in-memory cache first
      if (_albumsCache != null && _cacheTime != null) {
        final age = DateTime.now().difference(_cacheTime!);
        if (age < _cacheExpiry) {
          debugPrint('MusicRepository: Returning albums from memory cache');
          return _albumsCache!;
        }
      }

      // Try to load from persistent cache
      final cachedAlbums = await _loadFromCache();
      if (cachedAlbums != null) {
        _albumsCache = cachedAlbums;
        _cacheTime = DateTime.now();
        debugPrint('MusicRepository: Returning albums from persistent cache');
        return cachedAlbums;
      }

      // Load from Firebase
      debugPrint('MusicRepository: Loading albums from Firebase');
      final albums = await _loadAlbumsFromFirebase();

      // Update cache
      _albumsCache = albums;
      _cacheTime = DateTime.now();
      await _saveToCache(albums);

      return albums;
    } on Exception catch (e) {
      throw _handleException(e, 'Failed to get albums');
    }
  }

  @override
  Future<List<Album>> getAlbumsFromCacheOnly() async {
    try {
      // Check in-memory cache first
      if (_albumsCache != null && _cacheTime != null) {
        final age = DateTime.now().difference(_cacheTime!);
        if (age < _cacheExpiry) {
          debugPrint(
            'MusicRepository: Returning albums from memory cache (cache-only)',
          );
          return _albumsCache!;
        }
      }

      // Try to load from persistent cache
      final cachedAlbums = await _loadFromCache();
      if (cachedAlbums != null) {
        _albumsCache = cachedAlbums;
        _cacheTime = DateTime.now();
        debugPrint(
          'MusicRepository: Returning albums from persistent cache (cache-only)',
        );
        return cachedAlbums;
      }

      // Never attempt Firebase - return empty list if no cache available
      debugPrint('MusicRepository: No cache available (cache-only)');
      return [];
    } on Exception catch (e) {
      // Never throw exceptions in cache-only mode
      debugPrint('MusicRepository: Cache-only load failed silently: $e');
      return [];
    }
  }

  @override
  Future<List<Song>> getTracks(String albumId) async {
    try {
      final albums = await getAlbums();
      final album = albums.firstWhere(
        (album) => album.id == albumId,
        orElse: () => throw const DataRepositoryException.notFound(),
      );
      return album.tracks;
    } on Exception catch (e) {
      throw _handleException(e, 'Failed to get tracks for album: $albumId');
    }
  }

  @override
  Future<Stream<Song>> getRadioStream() async {
    try {
      unawaited(_radioStreamController?.close());
      _radioStreamController = StreamController<Song>.broadcast();

      // Start generating random songs
      unawaited(_generateRadioStream());

      return _radioStreamController!.stream;
    } on Exception catch (e) {
      throw _handleException(e, 'Failed to create radio stream');
    }
  }

  @override
  Future<Song?> getTrackById(String id) async {
    try {
      final albums = await getAlbums();
      for (final album in albums) {
        for (final track in album.tracks) {
          if (track.id == id) {
            return track;
          }
        }
      }
      return null;
    } on Exception catch (e) {
      throw _handleException(e, 'Failed to get track by ID: $id');
    }
  }

  @override
  Future<List<Album>> searchAlbums(String query) async {
    try {
      if (query.isEmpty) {
        return [];
      }

      final albums = await getAlbums();
      final lowercaseQuery = query.toLowerCase();

      return albums
          .where(
            (album) =>
                album.albumName.toLowerCase().contains(lowercaseQuery) ||
                (album.artist?.toLowerCase().contains(lowercaseQuery) ?? false),
          )
          .toList();
    } on Exception catch (e) {
      throw _handleException(e, 'Failed to search albums');
    }
  }

  @override
  Future<List<Song>> searchTracks(String query) async {
    try {
      if (query.isEmpty) {
        return [];
      }

      final albums = await getAlbums();
      final lowercaseQuery = query.toLowerCase();
      final results = <Song>[];

      for (final album in albums) {
        for (final song in album.tracks) {
          if (song.songName.toLowerCase().contains(lowercaseQuery) ||
              song.artist.toLowerCase().contains(lowercaseQuery)) {
            results.add(song);
          }
        }
      }

      return results;
    } on Exception catch (e) {
      throw _handleException(e, 'Failed to search tracks');
    }
  }

  @override
  Future<void> refreshCache() async {
    try {
      debugPrint('MusicRepository: Refreshing cache');

      // Clear caches
      _albumsCache = null;
      _cacheTime = null;
      await clearCache();

      // Force reload from Firebase
      await getAlbums();
    } on Exception catch (e) {
      throw _handleException(e, 'Failed to refresh cache');
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_cacheTimeKey);

      _albumsCache = null;
      _cacheTime = null;

      debugPrint('MusicRepository: Cache cleared');
    } on Exception {
      throw const CacheRepositoryException.writeFailed();
    }
  }

  /// Loads albums from Firebase Storage with retry logic.
  Future<List<Album>> _loadAlbumsFromFirebase() async {
    final albums = <Album>[];

    try {
      // Add connection timeout for Firebase operations
      final storageRef = _storage.ref().child('Artist');
      final artistResult = await _executeWithRetry(
        () async => storageRef.listAll().timeout(
              const Duration(seconds: 15),
              onTimeout: () => throw TimeoutException(
                'Firebase connection timeout',
                const Duration(seconds: 15),
              ),
            ),
      );

      debugPrint(
        'MusicRepository: Found ${artistResult.prefixes.length} artists',
      );

      // Emit initial progress
      _progressController.add(AlbumLoadingProgress(
        message: 'Found ${artistResult.prefixes.length} artists',
        progress: 0.1,
        albumsProcessed: 0,
        totalAlbums: 0,
      ));

      var totalAlbumsEstimate = 0;
      var albumsProcessed = 0;

      for (var artistIndex = 0;
          artistIndex < artistResult.prefixes.length;
          artistIndex++) {
        final artist = artistResult.prefixes[artistIndex];
        final artistName = artist.name;

        try {
          final albumsResult = await _executeWithRetry(
            () async => artist.listAll().timeout(
                  const Duration(seconds: 10),
                  onTimeout: () => throw TimeoutException(
                    'Artist listing timeout for $artistName',
                    const Duration(seconds: 10),
                  ),
                ),
          );

          debugPrint(
            'MusicRepository: Artist $artistName has ${albumsResult.prefixes.length} albums',
          );

          // Update total albums estimate
          totalAlbumsEstimate += albumsResult.prefixes.length;

          // Emit progress for artist discovery
          _progressController.add(AlbumLoadingProgress(
            message: 'Loading albums from $artistName...',
            progress: 0.2 + (artistIndex / artistResult.prefixes.length) * 0.6,
            albumsProcessed: albumsProcessed,
            totalAlbums: totalAlbumsEstimate,
          ));

          for (var albumIndex = 0;
              albumIndex < albumsResult.prefixes.length;
              albumIndex++) {
            final albumRef = albumsResult.prefixes[albumIndex];
            final albumName = albumRef.name;

            try {
              String? albumArt;
              final tracks = <Song>[];

              final songsResult = await _executeWithRetry(
                () async => albumRef.listAll().timeout(
                      const Duration(seconds: 8),
                      onTimeout: () => throw TimeoutException(
                        'Album listing timeout for $albumName',
                        const Duration(seconds: 8),
                      ),
                    ),
              );

              // First pass: find album art (with timeout)
              for (final item in songsResult.items) {
                final itemName = item.name;
                if (_isImageFile(itemName)) {
                  try {
                    albumArt = await _executeWithRetry(
                      () async => item.getDownloadURL().timeout(
                            const Duration(seconds: 5),
                            onTimeout: () => throw TimeoutException(
                              'Album art URL timeout',
                              const Duration(seconds: 5),
                            ),
                          ),
                    );
                    break;
                  } on Exception catch (e) {
                    debugPrint(
                      'MusicRepository: Failed to get album art for $albumName: $e',
                    );
                    // Continue without album art
                  }
                }
              }

              // Second pass: process songs (with timeout and error recovery)
              for (final songRef in songsResult.items) {
                final songName = songRef.name;

                // Skip image files
                if (_isImageFile(songName)) {
                  continue;
                }

                try {
                  final songUrl = await _executeWithRetry(
                    () async => songRef.getDownloadURL().timeout(
                          const Duration(seconds: 5),
                          onTimeout: () => throw TimeoutException(
                            'Song URL timeout for $songName',
                            const Duration(seconds: 5),
                          ),
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
                  debugPrint(
                    'MusicRepository: Failed to load song $songName: $e',
                  );
                  // Continue with other songs
                }
              }

              // Only add albums that have tracks
              if (tracks.isNotEmpty) {
                albums.add(
                  Album(
                    id: '${artistName}_$albumName',
                    albumName: albumName,
                    tracks: tracks,
                    albumCover: albumArt,
                    artist: artistName,
                  ),
                );
                debugPrint(
                  'MusicRepository: Added album $albumName with ${tracks.length} tracks',
                );

                // Update albums processed count and emit progress
                albumsProcessed++;
                _progressController.add(AlbumLoadingProgress(
                  message: 'Added album "$albumName"',
                  progress: 0.2 + (albumsProcessed / (totalAlbumsEstimate > 0 ? totalAlbumsEstimate : 1)) * 0.6,
                  albumsProcessed: albumsProcessed,
                  totalAlbums: totalAlbumsEstimate,
                ));
              }
            } on Exception catch (e) {
              debugPrint(
                'MusicRepository: Failed to load album $albumName: $e',
              );
              // Continue with other albums
            }
          }
        } on Exception catch (e) {
          debugPrint('MusicRepository: Failed to load artist $artistName: $e');
          // Continue with other artists
        }
      }

      debugPrint(
        'MusicRepository: Successfully loaded ${albums.length} albums from Firebase',
      );

      // Emit final progress
      _progressController.add(AlbumLoadingProgress(
        message: 'Successfully loaded ${albums.length} albums',
        progress: 1.0,
        albumsProcessed: albums.length,
        totalAlbums: albums.length,
      ));

      if (albums.isEmpty) {
        throw const DataRepositoryException.notFound();
      }

      return albums;
    } on TimeoutException catch (e) {
      debugPrint('MusicRepository: Timeout error: ${e.message}');
      throw NetworkRepositoryException(
        'Connection timeout: ${e.message}',
        'FIREBASE_TIMEOUT',
      );
    } on FirebaseException catch (e) {
      debugPrint('MusicRepository: Firebase error: ${e.message}');
      throw FirebaseRepositoryException('Firebase error: ${e.message}', e.code);
    } on Exception catch (e) {
      debugPrint('MusicRepository: Unexpected error: $e');
      throw NetworkRepositoryException('Network error: $e', 'NETWORK_ERROR');
    }
  }

  /// Loads albums from persistent cache.
  Future<List<Album>?> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_cacheKey);
      final cachedTimeStr = prefs.getString(_cacheTimeKey);

      if (cachedData != null && cachedTimeStr != null) {
        final cachedTime = DateTime.parse(cachedTimeStr);

        // Check if cache is still valid
        if (DateTime.now().difference(cachedTime) < _cacheExpiry) {
          final decoded = jsonDecode(cachedData) as List<dynamic>;
          final albums = decoded
              .map((item) => Album.fromJson(item as Map<String, dynamic>))
              .toList();

          debugPrint(
            'MusicRepository: Loaded ${albums.length} albums from cache',
          );
          return albums;
        }
      }
      return null;
    } on Exception catch (e) {
      debugPrint('MusicRepository: Cache loading error: $e');
      return null;
    }
  }

  /// Saves albums to persistent cache.
  Future<void> _saveToCache(List<Album> albums) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded =
          jsonEncode(albums.map((album) => album.toJson()).toList());

      await prefs.setString(_cacheKey, encoded);
      await prefs.setString(_cacheTimeKey, DateTime.now().toIso8601String());

      debugPrint('MusicRepository: Saved ${albums.length} albums to cache');
    } on Exception catch (e) {
      debugPrint('MusicRepository: Cache saving error: $e');
      // Don't throw here as caching is non-critical
    }
  }

  /// Generates a continuous stream of random songs for radio mode.
  Future<void> _generateRadioStream() async {
    try {
      while (
          _radioStreamController != null && !_radioStreamController!.isClosed) {
        final albums = await getAlbums();
        if (albums.isEmpty) {
          await Future<void>.delayed(const Duration(seconds: 5));
          continue;
        }

        // Get a random album and track
        final randomAlbum = albums[Random().nextInt(albums.length)];
        if (randomAlbum.tracks.isNotEmpty) {
          final randomTrack =
              randomAlbum.tracks[Random().nextInt(randomAlbum.tracks.length)];

          if (!_radioStreamController!.isClosed) {
            _radioStreamController!.add(randomTrack);
          }
        }

        // Wait before next song (simulating song duration)
        await Future<void>.delayed(const Duration(minutes: 3));
      }
    } on Exception catch (e) {
      if (!_radioStreamController!.isClosed) {
        _radioStreamController!
            .addError(_handleException(e, 'Radio stream error'));
      }
    }
  }

  /// Executes a function with retry logic.
  Future<T> _executeWithRetry<T>(Future<T> Function() operation) async {
    for (var attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        return await operation();
      } on Exception catch (e) {
        if (attempt == _maxRetries) {
          rethrow;
        }

        debugPrint('MusicRepository: Attempt $attempt failed, retrying: $e');
        await Future<void>.delayed(_retryDelay * attempt);
      }
    }
    throw const NetworkRepositoryException.connectionFailed();
  }

  /// Checks if a file name represents an image.
  bool _isImageFile(String fileName) {
    final extension = fileName.toLowerCase();
    return extension.endsWith('.jpg') ||
        extension.endsWith('.jpeg') ||
        extension.endsWith('.png') ||
        extension.endsWith('.webp');
  }

  /// Handles exceptions and converts them to appropriate repository exceptions.
  RepositoryException _handleException(Object error, String context) {
    if (error is RepositoryException) {
      return error;
    }

    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return const FirebaseRepositoryException.permissionDenied();
        case 'unauthenticated':
          return const FirebaseRepositoryException.authenticationFailed();
        default:
          return const FirebaseRepositoryException.storageError();
      }
    }

    if (error.toString().contains('network') ||
        error.toString().contains('connection')) {
      return const NetworkRepositoryException.connectionFailed();
    }

    return DataRepositoryException('$context: $error', 'UNKNOWN_ERROR');
  }

  @override
  Stream<AlbumLoadingProgress> get albumLoadingProgress => _progressController.stream;

  /// Disposes of resources.
  void dispose() {
    _radioStreamController?.close();
    _radioStreamController = null;
    _progressController.close();
  }
}
