import '../models/album.dart';
import '../models/song.dart';

/// Abstract repository interface for music data operations.
/// This interface defines the contract for all music data access.
abstract class MusicRepository {
  /// Retrieves all available albums from the data source.
  ///
  /// Throws [RepositoryException] if the operation fails.
  Future<List<Album>> getAlbums();

  /// Retrieves all tracks for a specific album.
  ///
  /// [albumId] The unique identifier of the album.
  ///
  /// Throws [RepositoryException] if the operation fails.
  Future<List<Song>> getTracks(String albumId);

  /// Gets a stream of random tracks for radio mode.
  ///
  /// Returns a stream that emits random tracks continuously.
  ///
  /// Throws [RepositoryException] if the operation fails.
  Future<Stream<Song>> getRadioStream();

  /// Retrieves a specific track by its unique identifier.
  ///
  /// [id] The unique identifier of the track.
  ///
  /// Returns null if the track is not found.
  /// Throws [RepositoryException] if the operation fails.
  Future<Song?> getTrackById(String id);

  /// Searches for albums matching the given query.
  ///
  /// [query] The search term to match against album names and artist names.
  ///
  /// Returns an empty list if no matches are found.
  /// Throws [RepositoryException] if the operation fails.
  Future<List<Album>> searchAlbums(String query);

  /// Searches for tracks matching the given query.
  ///
  /// [query] The search term to match against track names and artist names.
  ///
  /// Returns an empty list if no matches are found.
  /// Throws [RepositoryException] if the operation fails.
  Future<List<Song>> searchTracks(String query);

  /// Refreshes the local cache by fetching fresh data from the remote source.
  ///
  /// Throws [RepositoryException] if the operation fails.
  Future<void> refreshCache();

  /// Clears all cached data.
  ///
  /// Throws [RepositoryException] if the operation fails.
  Future<void> clearCache();
}
