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
    } catch (e) {
      throw _handleException(e, 'Failed to get albums');
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
    } catch (e) {
      throw _handleException(e, 'Failed to get tracks for album: $albumId');
    }
  }

  @override
  Future<Stream<Song>> getRadioStream() async {
    try {
      _radioStreamController?.close();
      _radioStreamController = StreamController<Song>.broadcast();

      // Start generating random songs
      _generateRadioStream();

      return _radioStreamController!.stream;
    } catch (e) {
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
    } catch (e) {
      throw _handleException(e, 'Failed to get track by ID: $id');
    }
  }

  @override
  Future<List<Album>> searchAlbums(String query) async {
    try {
      if (query.isEmpty) return [];

      final albums = await getAlbums();
      final lowercaseQuery = query.toLowerCase();

      return albums
          .where(
            (album) =>
                album.albumName.toLowerCase().contains(lowercaseQuery) ||
                (album.artist?.toLowerCase().contains(lowercaseQuery) ?? false),
          )
          .toList();
    } catch (e) {
      throw _handleException(e, 'Failed to search albums');
    }
  }

  @override
  Future<List<Song>> searchTracks(String query) async {
    try {
      if (query.isEmpty) return [];

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
    } catch (e) {
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
    } catch (e) {
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
    } catch (e) {
      throw const CacheRepositoryException.writeFailed();
    }
  }

  /// Loads albums from Firebase Storage with retry logic.
  Future<List<Album>> _loadAlbumsFromFirebase() async {
    final albums = <Album>[];

    try {
      // Add connection timeout for Firebase operations
      final storageRef = _storage.ref().child('Artist');
      final artistResult = await _executeWithRetry(() async {
        return await storageRef.listAll().timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw TimeoutException('Firebase connection timeout', const Duration(seconds: 15)),
        );
      });

      debugPrint('MusicRepository: Found ${artistResult.prefixes.length} artists');
      
      for (int artistIndex = 0; artistIndex < artistResult.prefixes.length; artistIndex++) {
        final artist = artistResult.prefixes[artistIndex];
        final artistName = artist.name;
        
        try {
          final albumsResult = await _executeWithRetry(() async {
            return await artist.listAll().timeout(
              const Duration(seconds: 10),
              onTimeout: () => throw TimeoutException('Artist listing timeout for $artistName', const Duration(seconds: 10)),
            );
          });

          debugPrint('MusicRepository: Artist $artistName has ${albumsResult.prefixes.length} albums');

          for (int albumIndex = 0; albumIndex < albumsResult.prefixes.length; albumIndex++) {
            final albumRef = albumsResult.prefixes[albumIndex];
            final albumName = albumRef.name;
            
            try {
              String? albumArt;
              final tracks = <Song>[];

              final songsResult = await _executeWithRetry(() async {
                return await albumRef.listAll().timeout(
                  const Duration(seconds: 8),
                  onTimeout: () => throw TimeoutException('Album listing timeout for $albumName', const Duration(seconds: 8)),
                );
              });

              // First pass: find album art (with timeout)
              for (final item in songsResult.items) {
                final itemName = item.name;
                if (_isImageFile(itemName)) {
                  try {
                    albumArt = await _executeWithRetry(() async {
                      return await item.getDownloadURL().timeout(
                        const Duration(seconds: 5),
                        onTimeout: () => throw TimeoutException('Album art URL timeout', const Duration(seconds: 5)),
                      );
                    });
                    break;
                  } catch (e) {
                    debugPrint('MusicRepository: Failed to get album art for $albumName: $e');
                    // Continue without album art
                  }
                }
              }

              // Second pass: process songs (with timeout and error recovery)
              for (final songRef in songsResult.items) {
                final songName = songRef.name;

                // Skip image files
                if (_isImageFile(songName)) continue;

                try {
                  final songUrl = await _executeWithRetry(() async {
                    return await songRef.getDownloadURL().timeout(
                      const Duration(seconds: 5),
                      onTimeout: () => throw TimeoutException('Song URL timeout for $songName', const Duration(seconds: 5)),
                    );
                  });

                  tracks.add(
                    Song(
                      id: '${artistName}_${albumName}_$songName',
                      songName: songName,
                      songUrl: songUrl,
                      artist: artistName,
                      albumName: albumName,
                    ),
                  );
                } catch (e) {
                  debugPrint('MusicRepository: Failed to load song $songName: $e');
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
                debugPrint('MusicRepository: Added album $albumName with ${tracks.length} tracks');
              }
            } catch (e) {
              debugPrint('MusicRepository: Failed to load album $albumName: $e');
              // Continue with other albums
            }
          }
        } catch (e) {
          debugPrint('MusicRepository: Failed to load artist $artistName: $e');
          // Continue with other artists
        }
      }

      debugPrint(
        'MusicRepository: Successfully loaded ${albums.length} albums from Firebase',
      );
      
      if (albums.isEmpty) {
        throw const DataRepositoryException.notFound();
      }
      
      return albums;
    } on TimeoutException catch (e) {
      debugPrint('MusicRepository: Timeout error: ${e.message}');
      throw NetworkRepositoryException('Connection timeout: ${e.message}', 'FIREBASE_TIMEOUT');
    } on FirebaseException catch (e) {
      debugPrint('MusicRepository: Firebase error: ${e.message}');
      throw FirebaseRepositoryException('Firebase error: ${e.message}', e.code);
    } catch (e) {
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
    } catch (e) {
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
    } catch (e) {
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
          await Future.delayed(const Duration(seconds: 5));
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
        await Future.delayed(const Duration(minutes: 3));
      }
    } catch (e) {
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
      } catch (e) {
        if (attempt == _maxRetries) rethrow;

        debugPrint('MusicRepository: Attempt $attempt failed, retrying: $e');
        await Future.delayed(_retryDelay * attempt);
      }
    }
    throw Exception('Maximum retries exceeded');
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
  RepositoryException _handleException(error, String context) {
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

  /// Disposes of resources.
  void dispose() {
    _radioStreamController?.close();
    _radioStreamController = null;
  }
}
