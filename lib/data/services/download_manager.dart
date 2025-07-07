import 'dart:io';
import 'dart:math';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

import '../models/download_item.dart';
import '../models/offline_song.dart';
import '../models/song.dart';
import 'offline_storage_service.dart';

/// Service for managing song downloads for offline playback.
///
/// Handles download queue management, progress tracking, and file storage.
/// Supports concurrent downloads and retry mechanisms.
class DownloadManager extends GetxController {
  DownloadManager(this._storageService);
  final OfflineStorageService _storageService;

  static const int maxConcurrentDownloads = 3;
  static const int maxRetryAttempts = 3;

  /// Currently active downloads.
  final RxList<DownloadItem> _activeDownloads = <DownloadItem>[].obs;

  /// Download queue (pending downloads).
  final RxList<DownloadItem> _downloadQueue = <DownloadItem>[].obs;

  /// All download items (active + queue + completed/failed).
  final RxList<DownloadItem> _allDownloads = <DownloadItem>[].obs;

  /// Currently active downloads.
  List<DownloadItem> get activeDownloads => _activeDownloads;

  /// Download queue.
  List<DownloadItem> get downloadQueue => _downloadQueue;

  /// All download items.
  List<DownloadItem> get allDownloads => _allDownloads;

  /// Initializes the download manager.
  Future<void> initialize() async {
    await _loadExistingDownloads();
    await _resumePendingDownloads();
  }

  /// Adds a song to the download queue.
  Future<String> downloadSong(Song song) async {
    // Check if already downloading or downloaded
    if (_allDownloads.any((item) => item.songId == song.id)) {
      throw Exception('Song is already in download queue or downloaded');
    }

    // Create download item
    final downloadId = _generateDownloadId();
    final downloadItem = DownloadItem(
      id: downloadId,
      songId: song.id ?? downloadId,
      songName: song.songName,
      artist: song.artist,
      albumName: song.albumName,
      url: song.songUrl,
      status: DownloadStatus.pending,
      progress: 0,
      createdAt: DateTime.now(),
    );

    // Add to queue and storage
    _downloadQueue.add(downloadItem);
    _allDownloads.add(downloadItem);
    await _storageService.saveDownloadItem(downloadItem);

    // Start processing queue
    _processDownloadQueue();

    return downloadId;
  }

  /// Pauses a download.
  Future<void> pauseDownload(String downloadId) async {
    final item = _findDownloadItem(downloadId);
    if (item != null && item.status == DownloadStatus.downloading) {
      await _updateDownloadStatus(item, DownloadStatus.paused);
      _activeDownloads.removeWhere((d) => d.id == downloadId);
      _downloadQueue.add(item);
    }
  }

  /// Resumes a paused download.
  Future<void> resumeDownload(String downloadId) async {
    final item = _findDownloadItem(downloadId);
    if (item != null && item.status == DownloadStatus.paused) {
      await _updateDownloadStatus(item, DownloadStatus.pending);
      _processDownloadQueue();
    }
  }

  /// Cancels a download.
  Future<void> cancelDownload(String downloadId) async {
    final item = _findDownloadItem(downloadId);
    if (item != null) {
      await _updateDownloadStatus(item, DownloadStatus.cancelled);
      _activeDownloads.removeWhere((d) => d.id == downloadId);
      _downloadQueue.removeWhere((d) => d.id == downloadId);

      // Delete partial file if exists
      if (item.status == DownloadStatus.downloading) {
        await _deletePartialFile(item);
      }
    }
  }

  /// Retries a failed download.
  Future<void> retryDownload(String downloadId) async {
    final item = _findDownloadItem(downloadId);
    if (item != null && item.status == DownloadStatus.failed) {
      final retryItem = item.copyWith(
        status: DownloadStatus.pending,
        progress: 0,
      );

      await _storageService.saveDownloadItem(retryItem);
      _updateDownloadItemInList(retryItem);
      _downloadQueue.add(retryItem);
      _processDownloadQueue();
    }
  }

  /// Removes a download item from history.
  Future<void> removeDownloadItem(String downloadId) async {
    await cancelDownload(downloadId);
    await _storageService.deleteDownloadItem(downloadId);
    _allDownloads.removeWhere((d) => d.id == downloadId);
  }

  /// Clears all completed and failed downloads.
  Future<void> clearDownloadHistory() async {
    final toRemove = _allDownloads
        .where(
          (item) =>
              item.status == DownloadStatus.completed ||
              item.status == DownloadStatus.failed ||
              item.status == DownloadStatus.cancelled,
        )
        .toList();

    for (final item in toRemove) {
      await _storageService.deleteDownloadItem(item.id);
      _allDownloads.remove(item);
    }
  }

  /// Processes the download queue.
  void _processDownloadQueue() {
    while (_activeDownloads.length < maxConcurrentDownloads &&
        _downloadQueue.isNotEmpty) {
      final nextDownload = _downloadQueue.removeAt(0);
      _activeDownloads.add(nextDownload);
      _startDownload(nextDownload);
    }
  }

  /// Starts downloading a specific item.
  Future<void> _startDownload(DownloadItem item) async {
    try {
      await _updateDownloadStatus(item, DownloadStatus.downloading);

      // Create local file path
      final directory = await _storageService.getOfflineStorageDirectory();
      final fileName = _sanitizeFileName('${item.songName}_${item.artist}');
      final localPath = path.join(directory.path, '$fileName.mp3');

      // Download file
      final response = await http.get(Uri.parse(item.url));

      if (response.statusCode == 200) {
        // Save file
        final file = File(localPath);
        await file.writeAsBytes(response.bodyBytes);

        // Create offline song
        final offlineSong = OfflineSong(
          id: item.songId,
          songName: item.songName,
          artist: item.artist,
          albumName: item.albumName,
          localPath: localPath,
          originalUrl: item.url,
          downloadDate: DateTime.now(),
          fileSize: response.bodyBytes.length,
        );

        // Save offline song
        await _storageService.saveOfflineSong(offlineSong);

        // Update download status
        await _updateDownloadStatus(item, DownloadStatus.completed);
        await _updateDownloadProgress(
          item,
          1,
          totalBytes: response.bodyBytes.length,
          downloadedBytes: response.bodyBytes.length,
        );
      } else {
        throw Exception(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      await _updateDownloadStatus(
        item,
        DownloadStatus.failed,
        errorMessage: e.toString(),
      );
    } finally {
      _activeDownloads.removeWhere((d) => d.id == item.id);
      _processDownloadQueue();
    }
  }

  /// Loads existing downloads from storage.
  Future<void> _loadExistingDownloads() async {
    final items = _storageService.getAllDownloadItems();
    _allDownloads.addAll(items);
  }

  /// Resumes pending downloads on startup.
  Future<void> _resumePendingDownloads() async {
    final pendingItems = _allDownloads
        .where(
          (item) =>
              item.status == DownloadStatus.pending ||
              item.status == DownloadStatus.downloading,
        )
        .toList();

    for (final item in pendingItems) {
      // Reset downloading items to pending
      if (item.status == DownloadStatus.downloading) {
        await _updateDownloadStatus(item, DownloadStatus.pending);
      }
      _downloadQueue.add(item);
    }

    _processDownloadQueue();
  }

  /// Updates download status and saves to storage.
  Future<void> _updateDownloadStatus(
    DownloadItem item,
    DownloadStatus status, {
    String? errorMessage,
  }) async {
    final updatedItem = item.copyWith(
      status: status,
      errorMessage: errorMessage,
    );

    await _storageService.saveDownloadItem(updatedItem);
    _updateDownloadItemInList(updatedItem);
  }

  /// Updates download progress and saves to storage.
  Future<void> _updateDownloadProgress(
    DownloadItem item,
    double progress, {
    int? totalBytes,
    int? downloadedBytes,
  }) async {
    final updatedItem = item.copyWith(
      progress: progress,
      totalBytes: totalBytes,
      downloadedBytes: downloadedBytes,
    );

    await _storageService.saveDownloadItem(updatedItem);
    _updateDownloadItemInList(updatedItem);
  }

  /// Updates download item in the reactive lists.
  void _updateDownloadItemInList(DownloadItem updatedItem) {
    final index = _allDownloads.indexWhere((item) => item.id == updatedItem.id);
    if (index != -1) {
      _allDownloads[index] = updatedItem;
    }

    final activeIndex =
        _activeDownloads.indexWhere((item) => item.id == updatedItem.id);
    if (activeIndex != -1) {
      _activeDownloads[activeIndex] = updatedItem;
    }

    final queueIndex =
        _downloadQueue.indexWhere((item) => item.id == updatedItem.id);
    if (queueIndex != -1) {
      _downloadQueue[queueIndex] = updatedItem;
    }
  }

  /// Finds a download item by ID.
  DownloadItem? _findDownloadItem(String downloadId) {
    try {
      return _allDownloads.firstWhere((item) => item.id == downloadId);
    } catch (e) {
      return null;
    }
  }

  /// Generates a unique download ID.
  String _generateDownloadId() =>
      'download_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';

  /// Sanitizes filename for storage.
  String _sanitizeFileName(String fileName) => fileName
      .replaceAll(RegExp(r'[^\w\s-]'), '')
      .replaceAll(RegExp(r'\s+'), '_')
      .toLowerCase();

  /// Deletes partial download file.
  Future<void> _deletePartialFile(DownloadItem item) async {
    try {
      final directory = await _storageService.getOfflineStorageDirectory();
      final fileName = _sanitizeFileName('${item.songName}_${item.artist}');
      final localPath = path.join(directory.path, '$fileName.mp3');
      final file = File(localPath);

      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Ignore errors when deleting partial files
    }
  }
}
