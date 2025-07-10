import 'dart:io';

import 'package:get/get.dart';

import '../models/offline_song.dart';
import '../models/song.dart';
import 'audio/enhanced_audio_service.dart';
import 'offline_storage_service.dart';

/// Service for handling offline audio playback functionality.
///
/// Extends the enhanced audio service to support offline song playback
/// by managing local file paths and integration with online/offline states.
class OfflineAudioService extends GetxController {
  /// Creates an offline audio service with the required dependencies.
  ///
  /// [_audioService] handles the actual audio playback operations.
  /// [_storageService] manages local storage of offline songs.
  OfflineAudioService(this._audioService, this._storageService);
  final EnhancedAudioService _audioService;
  final OfflineStorageService _storageService;

  /// Current offline playback mode.
  final RxBool _isOfflineMode = false.obs;

  /// Whether the service is currently in offline mode.
  bool get isOfflineMode => _isOfflineMode.value;

  /// Stream of offline mode changes.
  Stream<bool> get offlineModeStream => _isOfflineMode.stream;

  /// Initializes the offline audio service.
  Future<void> initialize() async {
    await _audioService.initialize();
  }

  /// Plays a song, automatically choosing between online and offline sources.
  ///
  /// If the song is available offline, it will play from local storage.
  /// Otherwise, it will play from the online URL if network is available.
  Future<void> playSong(Song song, {bool forceOffline = false}) async {
    // Check if song is available offline
    final offlineSong = _storageService.getOfflineSong(song.id ?? '');

    if (offlineSong != null && await _isOfflineFileValid(offlineSong)) {
      // Play offline version
      await _playOfflineSong(offlineSong);
    } else if (!forceOffline) {
      // Play online version
      await _audioService.play(song);
    } else {
      throw Exception('Song not available offline and offline mode is forced');
    }
  }

  /// Plays an offline song from local storage.
  Future<void> _playOfflineSong(OfflineSong offlineSong) async {
    // Convert offline song to regular song with local file path
    final localSong = Song(
      id: offlineSong.id,
      songName: offlineSong.songName,
      artist: offlineSong.artist,
      albumName: offlineSong.albumName,
      songUrl: 'file://${offlineSong.localPath}',
      duration: offlineSong.duration != null
          ? Duration(milliseconds: offlineSong.duration!)
          : null,
    );

    await _audioService.play(localSong);
  }

  /// Sets the offline mode for the service.
  Future<void> setOfflineMode({required bool enabled}) async {
    _isOfflineMode.value = enabled;

    if (enabled) {
      // Switch current playing song to offline if available
      final currentSong = _audioService.currentSong;
      if (currentSong != null) {
        final offlineVersion =
            _storageService.getOfflineSong(currentSong.id ?? '');
        if (offlineVersion != null &&
            await _isOfflineFileValid(offlineVersion)) {
          await _playOfflineSong(offlineVersion);
        } else {
          // Stop playback if no offline version available
          await _audioService.stop();
        }
      }
    }
  }

  /// Gets all available offline songs.
  List<OfflineSong> getOfflineSongs() => _storageService.getAllOfflineSongs();

  /// Checks if a song is available for offline playback.
  bool isSongAvailableOffline(String songId) {
    final offlineSong = _storageService.getOfflineSong(songId);
    return offlineSong != null;
  }

  /// Gets offline songs as regular Song objects for playback.
  List<Song> getOfflineSongsAsSongs() => _storageService
      .getAllOfflineSongs()
      .map(
        (offlineSong) => Song(
          id: offlineSong.id,
          songName: offlineSong.songName,
          artist: offlineSong.artist,
          albumName: offlineSong.albumName,
          songUrl: 'file://${offlineSong.localPath}',
          duration: offlineSong.duration != null
              ? Duration(milliseconds: offlineSong.duration!)
              : null,
        ),
      )
      .toList();

  /// Plays offline songs in a queue.
  Future<void> playOfflineQueue(List<OfflineSong> songs) async {
    if (songs.isEmpty) {
      return;
    }

    // Clear current queue
    await _audioService.clearQueue();

    // Add offline songs to queue
    for (final offlineSong in songs) {
      if (await _isOfflineFileValid(offlineSong)) {
        final song = Song(
          id: offlineSong.id,
          songName: offlineSong.songName,
          artist: offlineSong.artist,
          albumName: offlineSong.albumName,
          songUrl: 'file://${offlineSong.localPath}',
          duration: offlineSong.duration != null
              ? Duration(milliseconds: offlineSong.duration!)
              : null,
        );
        await _audioService.addToQueue(song);
      }
    }

    // Play first song
    if (_audioService.queue.isNotEmpty) {
      await _audioService.play(_audioService.queue.first);
    }
  }

  /// Deletes an offline song and removes it from storage.
  Future<void> deleteOfflineSong(String songId) async {
    // Stop playback if currently playing this song
    final currentSong = _audioService.currentSong;
    if (currentSong?.id == songId) {
      await _audioService.stop();
    }

    // Remove from queue if present
    final queue = _audioService.queue;
    for (var i = 0; i < queue.length; i++) {
      if (queue[i].id == songId) {
        await _audioService.removeFromQueue(i);
        break;
      }
    }

    // Delete from storage
    await _storageService.deleteOfflineSong(songId);
  }

  /// Validates that an offline file still exists and is accessible.
  Future<bool> _isOfflineFileValid(OfflineSong offlineSong) async {
    try {
      final file = File(offlineSong.localPath);
      return file.existsSync();
    } on Exception {
      return false;
    }
  }

  /// Gets the total size of offline storage used.
  Future<String> getOfflineStorageSize() async {
    final totalBytes = await _storageService.getTotalStorageUsed();
    return _formatBytes(totalBytes);
  }

  /// Formats bytes into human-readable format.
  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Syncs offline songs with online availability.
  ///
  /// This could be used to check if offline songs are still available online
  /// and update metadata or remove songs that are no longer available.
  Future<void> syncOfflineSongs() async {
    // Implementation would depend on the online music service API
    // This is a placeholder for the sync functionality
    final offlineSongs = _storageService.getAllOfflineSongs();

    for (final song in offlineSongs) {
      // Validate that the file still exists
      if (!await _isOfflineFileValid(song)) {
        // Remove invalid song from storage
        await _storageService.deleteOfflineSong(song.id);
      }
    }
  }

  /// Disposes of the offline audio service.
  @override
  Future<void> onClose() async {
    await _audioService.dispose();
    super.onClose();
  }
}
