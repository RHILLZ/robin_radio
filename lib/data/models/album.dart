import 'package:json_annotation/json_annotation.dart';

import 'song.dart';

part 'album.g.dart';

/// Represents a music album containing metadata and a collection of tracks.
///
/// This model supports JSON serialization/deserialization for data persistence
/// and API communication. Includes utility methods for calculating album
/// statistics and creating modified copies.
@JsonSerializable()
class Album {
  /// Creates a new Album instance.
  ///
  /// [albumName] The title/name of the album (required).
  /// [tracks] The list of songs/tracks in this album (required).
  /// [albumCover] Optional URL or path to the album cover image.
  /// [artist] Optional name of the primary artist or band.
  /// [releaseDate] Optional release date as a string.
  /// [id] Optional unique identifier for the album.
  const Album({
    required this.albumName,
    required this.tracks,
    this.albumCover,
    this.artist,
    this.releaseDate,
    this.id,
  });

  /// Creates an Album instance from a JSON map.
  ///
  /// Used for deserializing album data from APIs or storage.
  factory Album.fromJson(Map<String, dynamic> json) => _$AlbumFromJson(json);

  /// The title or name of the album.
  final String albumName;

  /// List of songs/tracks contained in this album.
  final List<Song> tracks;

  /// URL or file path to the album cover image.
  ///
  /// Can be null if no cover image is available.
  final String? albumCover;

  /// Name of the primary artist or band for this album.
  ///
  /// Can be null if artist information is not available.
  final String? artist;

  /// Release date of the album as a string.
  ///
  /// Format may vary depending on data source. Can be null if unknown.
  final String? releaseDate;

  /// Unique identifier for this album.
  ///
  /// Used for database operations and caching. Can be null for local albums.
  final String? id;

  /// Converts the Album instance to a JSON map.
  ///
  /// Used for serializing album data for APIs or storage.
  Map<String, dynamic> toJson() => _$AlbumToJson(this);

  /// Calculates the total duration of all tracks in the album.
  ///
  /// Returns Duration.zero if no tracks have duration information.
  Duration get totalDuration => tracks.fold(
        Duration.zero,
        (total, song) => total + (song.duration ?? Duration.zero),
      );

  /// Gets the number of tracks in the album.
  int get trackCount => tracks.length;

  /// Creates a copy of this album with optionally modified properties.
  ///
  /// Any parameter that is not provided will retain its current value.
  /// This is useful for updating specific album properties while preserving others.
  ///
  /// [albumName] New album name, if different.
  /// [tracks] New track list, if different.
  /// [albumCover] New album cover URL, if different.
  /// [artist] New artist name, if different.
  /// [releaseDate] New release date, if different.
  /// [id] New ID, if different.
  ///
  /// Returns a new Album instance with the specified changes.
  Album copyWith({
    String? albumName,
    List<Song>? tracks,
    String? albumCover,
    String? artist,
    String? releaseDate,
    String? id,
  }) =>
      Album(
        albumName: albumName ?? this.albumName,
        tracks: tracks ?? this.tracks,
        albumCover: albumCover ?? this.albumCover,
        artist: artist ?? this.artist,
        releaseDate: releaseDate ?? this.releaseDate,
        id: id ?? this.id,
      );
}
