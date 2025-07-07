import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../models/download_item.dart';
import '../models/offline_song.dart';

/// Service for managing offline storage using Hive.
///
/// Provides functionality to store and retrieve offline songs,
/// manage download items, and handle local file storage.
class OfflineStorageService {
  static const String _offlineSongsBoxName = 'offline_songs';
  static const String _downloadItemsBoxName = 'download_items';

  Box<OfflineSong>? _offlineSongsBox;
  Box<DownloadItem>? _downloadItemsBox;

  /// Initializes the offline storage service.
  ///
  /// Registers Hive adapters and opens storage boxes.
  Future<void> initialize() async {
    // Register Hive adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(OfflineSongAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(DownloadItemAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(DownloadStatusAdapter());
    }

    // Open boxes
    _offlineSongsBox = await Hive.openBox<OfflineSong>(_offlineSongsBoxName);
    _downloadItemsBox = await Hive.openBox<DownloadItem>(_downloadItemsBoxName);
  }

  /// Saves an offline song to storage.
  Future<void> saveOfflineSong(OfflineSong song) async {
    await _offlineSongsBox?.put(song.id, song);
  }

  /// Retrieves an offline song by ID.
  OfflineSong? getOfflineSong(String id) => _offlineSongsBox?.get(id);

  /// Retrieves all offline songs.
  List<OfflineSong> getAllOfflineSongs() =>
      _offlineSongsBox?.values.toList() ?? [];

  /// Checks if a song is available offline.
  bool isSongOffline(String songId) =>
      _offlineSongsBox?.containsKey(songId) ?? false;

  /// Deletes an offline song and its local file.
  Future<void> deleteOfflineSong(String songId) async {
    final song = getOfflineSong(songId);
    if (song != null) {
      // Delete local file
      final file = File(song.localPath);
      if (await file.exists()) {
        await file.delete();
      }

      // Remove from storage
      await _offlineSongsBox?.delete(songId);
    }
  }

  /// Saves a download item to storage.
  Future<void> saveDownloadItem(DownloadItem item) async {
    await _downloadItemsBox?.put(item.id, item);
  }

  /// Retrieves a download item by ID.
  DownloadItem? getDownloadItem(String id) => _downloadItemsBox?.get(id);

  /// Retrieves all download items.
  List<DownloadItem> getAllDownloadItems() =>
      _downloadItemsBox?.values.toList() ?? [];

  /// Retrieves download items by status.
  List<DownloadItem> getDownloadItemsByStatus(DownloadStatus status) =>
      _downloadItemsBox?.values
          .where((item) => item.status == status)
          .toList() ??
      [];

  /// Updates download item progress.
  Future<void> updateDownloadProgress(
    String id,
    double progress, {
    int? downloadedBytes,
    int? totalBytes,
  }) async {
    final item = getDownloadItem(id);
    if (item != null) {
      final updatedItem = item.copyWith(
        progress: progress,
        downloadedBytes: downloadedBytes ?? item.downloadedBytes,
        totalBytes: totalBytes ?? item.totalBytes,
      );
      await saveDownloadItem(updatedItem);
    }
  }

  /// Updates download item status.
  Future<void> updateDownloadStatus(
    String id,
    DownloadStatus status, {
    String? errorMessage,
  }) async {
    final item = getDownloadItem(id);
    if (item != null) {
      final updatedItem = item.copyWith(
        status: status,
        errorMessage: errorMessage,
      );
      await saveDownloadItem(updatedItem);
    }
  }

  /// Deletes a download item.
  Future<void> deleteDownloadItem(String id) async {
    await _downloadItemsBox?.delete(id);
  }

  /// Gets the offline storage directory.
  Future<Directory> getOfflineStorageDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final offlineDir = Directory('${appDir.path}/offline_music');

    if (!await offlineDir.exists()) {
      await offlineDir.create(recursive: true);
    }

    return offlineDir;
  }

  /// Calculates total offline storage used in bytes.
  Future<int> getTotalStorageUsed() async {
    var totalSize = 0;
    final songs = getAllOfflineSongs();

    for (final song in songs) {
      if (song.fileSize != null) {
        totalSize += song.fileSize!;
      } else {
        // Calculate file size if not stored
        final file = File(song.localPath);
        if (await file.exists()) {
          final size = await file.length();
          totalSize += size;

          // Update the song with file size
          final updatedSong = song.copyWith(fileSize: size);
          await saveOfflineSong(updatedSong);
        }
      }
    }

    return totalSize;
  }

  /// Clears all offline data.
  Future<void> clearAllOfflineData() async {
    // Delete all local files
    final songs = getAllOfflineSongs();
    for (final song in songs) {
      final file = File(song.localPath);
      if (await file.exists()) {
        await file.delete();
      }
    }

    // Clear storage boxes
    await _offlineSongsBox?.clear();
    await _downloadItemsBox?.clear();
  }

  /// Disposes of the service and closes storage boxes.
  Future<void> dispose() async {
    await _offlineSongsBox?.close();
    await _downloadItemsBox?.close();
  }
}
