import 'package:hive/hive.dart';

part 'download_item.g.dart';

/// Represents the status of a download operation.
@HiveType(typeId: 2)
enum DownloadStatus {
  /// Download is queued and waiting to start
  @HiveField(0)
  pending,
  
  /// Download is actively in progress
  @HiveField(1)
  downloading,
  
  /// Download has completed successfully
  @HiveField(2)
  completed,
  
  /// Download has failed due to an error
  @HiveField(3)
  failed,
  
  /// Download has been paused by user
  @HiveField(4)
  paused,
  
  /// Download has been cancelled by user
  @HiveField(5)
  cancelled,
}

/// Represents a download item in the download queue.
///
/// This model tracks the progress and status of song downloads
/// for offline playback functionality.
@HiveType(typeId: 1)
class DownloadItem extends HiveObject {
  /// Creates a new DownloadItem instance.
  ///
  /// [id] Unique identifier for this download.
  /// [songId] ID of the song being downloaded.
  /// [songName] Name of the song.
  /// [artist] Artist name.
  /// [url] URL to download from.
  /// [status] Current download status.
  /// [progress] Download progress (0.0 to 1.0).
  /// [createdAt] When the download was initiated.
  /// [albumName] Optional album name.
  /// [totalBytes] Total file size in bytes.
  /// [downloadedBytes] Downloaded bytes so far.
  /// [errorMessage] Error message if download failed.
  DownloadItem({
    required this.id,
    required this.songId,
    required this.songName,
    required this.artist,
    required this.url,
    required this.status,
    required this.progress,
    required this.createdAt,
    this.albumName,
    this.totalBytes,
    this.downloadedBytes,
    this.errorMessage,
  });

  /// Unique identifier for this download.
  @HiveField(0)
  String id;

  /// ID of the song being downloaded.
  @HiveField(1)
  String songId;

  /// Name of the song.
  @HiveField(2)
  String songName;

  /// Artist name.
  @HiveField(3)
  String artist;

  /// Album name (optional).
  @HiveField(4)
  String? albumName;

  /// URL to download from.
  @HiveField(5)
  String url;

  /// Current download status.
  @HiveField(6)
  DownloadStatus status;

  /// Download progress (0.0 to 1.0).
  @HiveField(7)
  double progress;

  /// Total file size in bytes.
  @HiveField(8)
  int? totalBytes;

  /// Downloaded bytes so far.
  @HiveField(9)
  int? downloadedBytes;

  /// When the download was initiated.
  @HiveField(10)
  DateTime createdAt;

  /// Error message if download failed.
  @HiveField(11)
  String? errorMessage;

  /// Creates a copy of this download item with optionally modified properties.
  DownloadItem copyWith({
    String? id,
    String? songId,
    String? songName,
    String? artist,
    String? albumName,
    String? url,
    DownloadStatus? status,
    double? progress,
    int? totalBytes,
    int? downloadedBytes,
    DateTime? createdAt,
    String? errorMessage,
  }) =>
      DownloadItem(
        id: id ?? this.id,
        songId: songId ?? this.songId,
        songName: songName ?? this.songName,
        artist: artist ?? this.artist,
        albumName: albumName ?? this.albumName,
        url: url ?? this.url,
        status: status ?? this.status,
        progress: progress ?? this.progress,
        totalBytes: totalBytes ?? this.totalBytes,
        downloadedBytes: downloadedBytes ?? this.downloadedBytes,
        createdAt: createdAt ?? this.createdAt,
        errorMessage: errorMessage ?? this.errorMessage,
      );

  @override
  String toString() => 'DownloadItem(id: $id, songName: $songName, status: $status, progress: $progress)';
}