import 'package:hive/hive.dart';

part 'offline_song.g.dart';

/// Represents an offline song stored locally with Hive.
///
/// This model stores downloaded song data for offline playback capabilities.
/// It contains both the song metadata and local file path information.
@HiveType(typeId: 0)
class OfflineSong extends HiveObject {
  /// Creates a new OfflineSong instance.
  ///
  /// [id] Unique identifier for the song.
  /// [songName] The title/name of the song.
  /// [artist] The name of the artist or performer.
  /// [albumName] Optional name of the album this song belongs to.
  /// [localPath] Local file path where the audio file is stored.
  /// [originalUrl] Original online URL of the song.
  /// [duration] Duration of the song.
  /// [downloadDate] When the song was downloaded.
  /// [fileSize] Size of the downloaded file in bytes.
  OfflineSong({
    required this.id,
    required this.songName,
    required this.artist,
    required this.localPath,
    required this.originalUrl,
    required this.downloadDate,
    this.albumName,
    this.duration,
    this.fileSize,
  });

  /// Unique identifier for this song.
  @HiveField(0)
  String id;

  /// The title or name of the song.
  @HiveField(1)
  String songName;

  /// The name of the artist, band, or performer of this song.
  @HiveField(2)
  String artist;

  /// The name of the album this song belongs to.
  @HiveField(3)
  String? albumName;

  /// Local file path where the audio file is stored.
  @HiveField(4)
  String localPath;

  /// Original online URL of the song.
  @HiveField(5)
  String originalUrl;

  /// The duration/length of the song in milliseconds.
  @HiveField(6)
  int? duration;

  /// When the song was downloaded.
  @HiveField(7)
  DateTime downloadDate;

  /// Size of the downloaded file in bytes.
  @HiveField(8)
  int? fileSize;

  /// Creates a copy of this offline song with optionally modified properties.
  OfflineSong copyWith({
    String? id,
    String? songName,
    String? artist,
    String? albumName,
    String? localPath,
    String? originalUrl,
    int? duration,
    DateTime? downloadDate,
    int? fileSize,
  }) =>
      OfflineSong(
        id: id ?? this.id,
        songName: songName ?? this.songName,
        artist: artist ?? this.artist,
        albumName: albumName ?? this.albumName,
        localPath: localPath ?? this.localPath,
        originalUrl: originalUrl ?? this.originalUrl,
        duration: duration ?? this.duration,
        downloadDate: downloadDate ?? this.downloadDate,
        fileSize: fileSize ?? this.fileSize,
      );

  @override
  String toString() => 'OfflineSong(id: $id, songName: $songName, artist: $artist)';
}