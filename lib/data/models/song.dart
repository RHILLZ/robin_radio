import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'song.g.dart';

/// Represents a music track/song with metadata and playback information.
///
/// This model extends Equatable for value equality comparison and supports
/// JSON serialization/deserialization for data persistence and API communication.
/// Contains all necessary information for audio playback and display in the UI.
@JsonSerializable()
class Song extends Equatable {
  /// Creates a new Song instance.
  ///
  /// [songName] The title/name of the song (required).
  /// [songUrl] The URL or file path for audio playback (required).
  /// [artist] The name of the artist or performer (required).
  /// [albumName] Optional name of the album this song belongs to.
  /// [duration] Optional duration of the song for player controls.
  /// [id] Optional unique identifier for the song.
  const Song({
    required this.songName,
    required this.songUrl,
    required this.artist,
    this.albumName,
    this.duration,
    this.id,
  });

  /// Creates a Song instance from a JSON map.
  ///
  /// Used for deserializing song data from APIs or storage.
  factory Song.fromJson(Map<String, dynamic> json) => _$SongFromJson(json);

  /// The title or name of the song.
  final String songName;

  /// The URL or file path where the audio file can be accessed for playback.
  final String songUrl;

  /// The name of the artist, band, or performer of this song.
  final String artist;

  /// The name of the album this song belongs to.
  ///
  /// Can be null for singles or when album information is not available.
  final String? albumName;

  /// The duration/length of the song.
  ///
  /// Used for better player control, progress bars, and time display.
  /// Can be null if duration information is not available.
  final Duration? duration;

  /// Unique identifier for this song.
  ///
  /// Used for database operations, caching, and playlist management.
  /// Can be null for local files or when not provided by the data source.
  final String? id;

  /// Converts the Song instance to a JSON map.
  ///
  /// Used for serializing song data for APIs or storage.
  Map<String, dynamic> toJson() => _$SongToJson(this);

  /// Creates a copy of this song with optionally modified properties.
  ///
  /// Any parameter that is not provided will retain its current value.
  /// This is useful for updating specific song properties while preserving others.
  ///
  /// [songName] New song name, if different.
  /// [songUrl] New song URL, if different.
  /// [artist] New artist name, if different.
  /// [albumName] New album name, if different.
  /// [duration] New duration, if different.
  /// [id] New ID, if different.
  ///
  /// Returns a new Song instance with the specified changes.
  Song copyWith({
    String? songName,
    String? songUrl,
    String? artist,
    String? albumName,
    Duration? duration,
    String? id,
  }) =>
      Song(
        songName: songName ?? this.songName,
        songUrl: songUrl ?? this.songUrl,
        artist: artist ?? this.artist,
        albumName: albumName ?? this.albumName,
        duration: duration ?? this.duration,
        id: id ?? this.id,
      );

  /// Properties used for value equality comparison.
  ///
  /// Two Song instances are considered equal if all their properties match.
  /// This is used by Equatable for comparison operations and collection management.
  @override
  List<Object?> get props =>
      [songName, songUrl, artist, albumName, duration, id];
}
