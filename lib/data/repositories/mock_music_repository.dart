import 'dart:async';
import 'dart:math';

import '../models/album.dart';
import '../models/song.dart';
import '../exceptions/repository_exception.dart';
import 'music_repository.dart';

/// Mock implementation of [MusicRepository] for testing purposes.
///
/// Provides sample music data without requiring Firebase or network access.
class MockMusicRepository implements MusicRepository {
  /// Create a mock repository with optional configuration.
  const MockMusicRepository({
    this.delay = const Duration(milliseconds: 500),
    this.simulateErrors = false,
  });

  /// Sample albums for testing.
  static final List<Album> _sampleAlbums = [
    const Album(
      id: 'album_1',
      albumName: 'Test Album 1',
      artist: 'Test Artist 1',
      albumCover: 'https://example.com/album1.jpg',
      tracks: [
        Song(
          id: 'song_1_1',
          songName: 'Test Song 1.1',
          songUrl: 'https://example.com/song1.mp3',
          artist: 'Test Artist 1',
          albumName: 'Test Album 1',
        ),
        Song(
          id: 'song_1_2',
          songName: 'Test Song 1.2',
          songUrl: 'https://example.com/song2.mp3',
          artist: 'Test Artist 1',
          albumName: 'Test Album 1',
        ),
      ],
    ),
    const Album(
      id: 'album_2',
      albumName: 'Test Album 2',
      artist: 'Test Artist 2',
      albumCover: 'https://example.com/album2.jpg',
      tracks: [
        Song(
          id: 'song_2_1',
          songName: 'Test Song 2.1',
          songUrl: 'https://example.com/song3.mp3',
          artist: 'Test Artist 2',
          albumName: 'Test Album 2',
        ),
        Song(
          id: 'song_2_2',
          songName: 'Test Song 2.2',
          songUrl: 'https://example.com/song4.mp3',
          artist: 'Test Artist 2',
          albumName: 'Test Album 2',
        ),
        Song(
          id: 'song_2_3',
          songName: 'Test Song 2.3',
          songUrl: 'https://example.com/song5.mp3',
          artist: 'Test Artist 2',
          albumName: 'Test Album 2',
        ),
      ],
    ),
  ];

  /// Simulated delay for async operations.
  final Duration delay;

  /// Whether to simulate errors.
  final bool simulateErrors;

  @override
  Future<List<Album>> getAlbums() async {
    await Future<void>.delayed(delay);

    if (simulateErrors && Random().nextBool()) {
      throw const NetworkRepositoryException.connectionFailed();
    }

    return List.from(_sampleAlbums);
  }

  @override
  Future<List<Album>> getAlbumsFromCacheOnly() async {
    // Mock implementation: simulate fast cache access with no delay
    // and never throw errors (cache-only should be safe)
    return List.from(_sampleAlbums);
  }

  @override
  Future<List<Song>> getTracks(String albumId) async {
    await Future<void>.delayed(delay);

    if (simulateErrors && Random().nextBool()) {
      throw const NetworkRepositoryException.connectionFailed();
    }

    final album = _sampleAlbums.firstWhere(
      (album) => album.id == albumId,
      orElse: () => throw const DataRepositoryException.notFound(),
    );

    return List.from(album.tracks);
  }

  @override
  Future<Stream<Song>> getRadioStream() async {
    await Future<void>.delayed(delay);

    if (simulateErrors && Random().nextBool()) {
      throw const NetworkRepositoryException.connectionFailed();
    }

    // Create a stream that emits random songs
    final controller = StreamController<Song>.broadcast();

    // Start generating random songs
    Timer.periodic(const Duration(seconds: 5), (timer) {
      final allSongs = _sampleAlbums.expand((album) => album.tracks).toList();
      if (allSongs.isNotEmpty && !controller.isClosed) {
        final randomSong = allSongs[Random().nextInt(allSongs.length)];
        controller.add(randomSong);
      }
    });

    return controller.stream;
  }

  @override
  Future<Song?> getTrackById(String id) async {
    await Future<void>.delayed(delay);

    if (simulateErrors && Random().nextBool()) {
      throw const NetworkRepositoryException.connectionFailed();
    }

    for (final album in _sampleAlbums) {
      for (final track in album.tracks) {
        if (track.id == id) {
          return track;
        }
      }
    }

    return null;
  }

  @override
  Future<List<Album>> searchAlbums(String query) async {
    await Future<void>.delayed(delay);

    if (simulateErrors && Random().nextBool()) {
      throw const NetworkRepositoryException.connectionFailed();
    }

    if (query.isEmpty) return [];

    final lowercaseQuery = query.toLowerCase();
    return _sampleAlbums
        .where(
          (album) =>
              album.albumName.toLowerCase().contains(lowercaseQuery) ||
              (album.artist?.toLowerCase().contains(lowercaseQuery) ?? false),
        )
        .toList();
  }

  @override
  Future<List<Song>> searchTracks(String query) async {
    await Future<void>.delayed(delay);

    if (simulateErrors && Random().nextBool()) {
      throw const NetworkRepositoryException.connectionFailed();
    }

    if (query.isEmpty) return [];

    final lowercaseQuery = query.toLowerCase();
    final results = <Song>[];

    for (final album in _sampleAlbums) {
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
  Future<void> refreshCache() async {
    await Future<void>.delayed(delay);

    if (simulateErrors && Random().nextBool()) {
      throw const CacheRepositoryException.readFailed();
    }

    // Mock implementation - nothing to refresh
  }

  @override
  Future<void> clearCache() async {
    await Future<void>.delayed(delay);

    if (simulateErrors && Random().nextBool()) {
      throw const CacheRepositoryException.writeFailed();
    }

    // Mock implementation - nothing to clear
  }
}
