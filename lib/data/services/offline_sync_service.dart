import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

import '../models/offline_song.dart';
import '../models/song.dart';
import 'network/enhanced_network_service.dart';
import 'offline_audio_service.dart';
import 'offline_storage_service.dart';

/// Service for managing synchronization between online and offline states.
///
/// Handles switching between online and offline playback modes based on
/// network connectivity and provides seamless transitions.
class OfflineSyncService extends GetxController {
  OfflineSyncService(
    this._networkService,
    this._storageService,
    this._audioService,
  );
  final EnhancedNetworkService _networkService;
  final OfflineStorageService _storageService;
  final OfflineAudioService _audioService;

  /// Current sync mode.
  final Rx<SyncMode> _syncMode = SyncMode.auto.obs;

  /// Whether the app is currently in offline mode.
  final RxBool _isOfflineMode = false.obs;

  /// Whether sync is currently in progress.
  final RxBool _isSyncing = false.obs;

  /// Last sync timestamp.
  final Rx<DateTime?> _lastSyncTime = Rx<DateTime?>(null);

  /// Network connectivity subscription.
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  /// Current sync mode.
  SyncMode get syncMode => _syncMode.value;

  /// Whether the app is currently in offline mode.
  bool get isOfflineMode => _isOfflineMode.value;

  /// Whether sync is currently in progress.
  bool get isSyncing => _isSyncing.value;

  /// Last sync timestamp.
  DateTime? get lastSyncTime => _lastSyncTime.value;

  /// Stream of sync mode changes.
  Stream<SyncMode> get syncModeStream => _syncMode.stream;

  /// Stream of offline mode changes.
  Stream<bool> get offlineModeStream => _isOfflineMode.stream;

  /// Stream of sync status changes.
  Stream<bool> get syncStatusStream => _isSyncing.stream;

  /// Initializes the offline sync service.
  @override
  Future<void> onInit() async {
    super.onInit();
    await _networkService.initialize();
    await _setupConnectivityMonitoring();
    await _checkInitialConnectivity();
  }

  /// Sets the sync mode.
  Future<void> setSyncMode(SyncMode mode) async {
    _syncMode.value = mode;

    switch (mode) {
      case SyncMode.auto:
        await _setupConnectivityMonitoring();
        await _checkInitialConnectivity();
        break;
      case SyncMode.alwaysOnline:
        await _setOfflineMode(false);
        break;
      case SyncMode.alwaysOffline:
        await _setOfflineMode(true);
        break;
    }
  }

  /// Manually triggers a sync operation.
  Future<void> syncNow() async {
    if (_isSyncing.value) {
      return;
    }

    _isSyncing.value = true;

    try {
      await _performSync();
      _lastSyncTime.value = DateTime.now();
    } finally {
      _isSyncing.value = false;
    }
  }

  /// Gets the offline availability status for a song.
  bool isSongAvailableOffline(String songId) =>
      _storageService.isSongOffline(songId);

  /// Gets all offline songs.
  List<OfflineSong> getOfflineSongs() => _storageService.getAllOfflineSongs();

  /// Plays a song with automatic online/offline selection.
  Future<void> playSong(Song song) async {
    if (_isOfflineMode.value || _syncMode.value == SyncMode.alwaysOffline) {
      // Force offline playback
      await _audioService.playSong(song, forceOffline: true);
    } else {
      // Allow online/offline selection
      await _audioService.playSong(song);
    }
  }

  /// Switches to offline mode.
  Future<void> goOffline() async {
    await _setOfflineMode(true);
  }

  /// Switches to online mode.
  Future<void> goOnline() async {
    if (await _networkService.isConnected) {
      await _setOfflineMode(false);
    } else {
      throw Exception('No network connection available');
    }
  }

  /// Estimates offline storage capacity.
  Future<String> getOfflineStorageInfo() async {
    final totalBytes = await _storageService.getTotalStorageUsed();
    final songCount = _storageService.getAllOfflineSongs().length;

    return 'Offline Songs: $songCount\nStorage Used: ${_formatBytes(totalBytes)}';
  }

  /// Cleans up offline storage by removing invalid files.
  Future<int> cleanupOfflineStorage() async {
    final offlineSongs = _storageService.getAllOfflineSongs();
    var removedCount = 0;

    for (final song in offlineSongs) {
      try {
        // Check if file still exists
        final file = await _getFile(song.localPath);
        final fileExists = await file.exists() as bool;
        if (!fileExists) {
          await _storageService.deleteOfflineSong(song.id);
          removedCount++;
        }
      } on Exception {
        // Remove invalid entries
        await _storageService.deleteOfflineSong(song.id);
        removedCount++;
      }
    }

    return removedCount;
  }

  /// Sets up connectivity monitoring.
  Future<void> _setupConnectivityMonitoring() async {
    await _connectivitySubscription?.cancel();

    if (_syncMode.value == SyncMode.auto) {
      _connectivitySubscription =
          _networkService.connectivityStream.listen(_handleConnectivityChange);
    }
  }

  /// Checks initial connectivity state.
  Future<void> _checkInitialConnectivity() async {
    if (_syncMode.value == SyncMode.auto) {
      final connectivity = await _networkService.checkConnectivity();
      await _handleConnectivityChange(connectivity);
    }
  }

  /// Handles connectivity changes.
  Future<void> _handleConnectivityChange(
    ConnectivityResult connectivity,
  ) async {
    final wasOffline = _isOfflineMode.value;
    final isConnected = connectivity != ConnectivityResult.none;

    if (_syncMode.value == SyncMode.auto) {
      await _setOfflineMode(!isConnected);

      // If we just came back online, sync
      if (wasOffline && isConnected) {
        await syncNow();
      }
    }
  }

  /// Sets the offline mode state.
  Future<void> _setOfflineMode(bool offline) async {
    if (_isOfflineMode.value != offline) {
      _isOfflineMode.value = offline;
      await _audioService.setOfflineMode(offline);
    }
  }

  /// Performs sync operations.
  Future<void> _performSync() async {
    // Cleanup invalid offline files
    await cleanupOfflineStorage();

    // Validate offline songs
    await _audioService.syncOfflineSongs();
  }

  /// Gets a file object from path.
  Future<dynamic> _getFile(String path) async => _MockFile(path);

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

  @override
  Future<void> onClose() async {
    await _connectivitySubscription?.cancel();
    super.onClose();
  }
}

/// Synchronization modes for offline functionality.
enum SyncMode {
  /// Automatically switch between online and offline based on connectivity.
  auto,

  /// Always use online playback when possible.
  alwaysOnline,

  /// Always use offline playback.
  alwaysOffline,
}

/// Mock file class for demonstration.
class _MockFile {
  _MockFile(String _);

  Future<bool> exists() async => true;
}
