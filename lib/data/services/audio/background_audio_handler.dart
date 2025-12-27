import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:audio_service/audio_service.dart' as audio_service;
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../../models/song.dart';
import 'audio_service_interface.dart';

/// Background audio handler that provides system-level audio controls
/// and media notifications for Robin Radio.
///
/// This handler integrates with the platform's media session system to provide:
/// - Lock screen controls
/// - Notification panel controls
/// - Bluetooth and headset button handling
/// - Background playback capabilities
/// - Media notifications with album art
class BackgroundAudioHandler extends audio_service.BaseAudioHandler
    with audio_service.QueueHandler, audio_service.SeekHandler {
  /// Creates a new background audio handler
  BackgroundAudioHandler() {
    _init();
  }

  /// The audio player instance for actual playback
  final AudioPlayer _player = AudioPlayer();

  /// Current playback mode
  PlaybackMode _playbackMode = PlaybackMode.normal;

  /// Current queue index
  int _currentIndex = 0;

  /// Random number generator for shuffle mode
  final Random _random = Random();

  /// Set of URLs that have been prefetched to avoid redundant requests
  final Set<String> _prefetchedUrls = <String>{};

  /// Number of upcoming tracks to prefetch
  static const int _prefetchCount = 2;

  /// Stream subscription for player state changes
  StreamSubscription<PlayerState>? _playerStateSubscription;

  /// Stream subscription for position changes
  StreamSubscription<Duration>? _positionSubscription;

  /// Stream subscription for duration changes
  StreamSubscription<Duration?>? _durationSubscription;

  /// Stream subscription for sequence state changes
  StreamSubscription<SequenceState?>? _sequenceStateSubscription;

  /// Initialize the background audio handler
  void _init() {
    // Listen to player state changes
    _playerStateSubscription = _player.playerStateStream.listen((state) {
      _broadcastState();

      // Auto-advance when track completes in normal/shuffle modes
      if (state.processingState == ProcessingState.completed) {
        _handleTrackCompletion();
      }
    });

    // Listen to position changes
    _positionSubscription = _player.positionStream.listen((position) {
      playbackState.add(
        playbackState.value.copyWith(
          updatePosition: position,
        ),
      );
    });

    // Listen to duration changes
    _durationSubscription = _player.durationStream.listen((duration) {
      final mediaItem = this.mediaItem.value;
      if (mediaItem != null && duration != null) {
        this.mediaItem.add(mediaItem.copyWith(duration: duration));
      }
    });

    // Listen to sequence state changes
    _sequenceStateSubscription = _player.sequenceStateStream.listen((state) {
      if (state != null) {
        _currentIndex = state.currentIndex;
        if (state.currentSource != null) {
          final tag = state.currentSource!.tag as Song?;
          if (tag != null) {
            _updateMediaItem(tag);
          }
        }
      }
    });

    // Set initial state
    playbackState.add(
      audio_service.PlaybackState(
        controls: [
          audio_service.MediaControl.skipToPrevious,
          audio_service.MediaControl.play,
          audio_service.MediaControl.skipToNext,
          audio_service.MediaControl.stop,
        ],
        systemActions: const {
          audio_service.MediaAction.seek,
          audio_service.MediaAction.seekForward,
          audio_service.MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
      ),
    );
  }

  @override
  Future<void> play() async {
    try {
      await _player.play();
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Error playing audio: $e');
      }
    }
  }

  @override
  Future<void> pause() async {
    try {
      await _player.pause();
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Error pausing audio: $e');
      }
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _player.stop();
      await super.stop();
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Error stopping audio: $e');
      }
    }
  }

  @override
  Future<void> seek(Duration position) async {
    try {
      await _player.seek(position);
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Error seeking audio: $e');
      }
    }
  }

  @override
  Future<void> skipToNext() async {
    try {
      final nextIndex = _getNextIndex();
      if (nextIndex != -1) {
        await _player.seekToNext();
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Error skipping to next: $e');
      }
    }
  }

  @override
  Future<void> skipToPrevious() async {
    try {
      final prevIndex = _getPreviousIndex();
      if (prevIndex != -1) {
        await _player.seekToPrevious();
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Error skipping to previous: $e');
      }
    }
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    try {
      if (index >= 0 && index < queue.value.length) {
        await _player.seek(Duration.zero, index: index);
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Error skipping to queue item: $e');
      }
    }
  }

  @override
  Future<void> addQueueItem(audio_service.MediaItem mediaItem) async {
    try {
      final song = _mediaItemToSong(mediaItem);
      final audioSource = AudioSource.uri(
        Uri.parse(song.songUrl),
        tag: song,
      );

      if (_player.sequence?.isEmpty ?? true) {
        await _player
            .setAudioSource(ConcatenatingAudioSource(children: [audioSource]));
      } else {
        final playlist = _player.sequence! as ConcatenatingAudioSource;
        await playlist.add(audioSource);
      }

      final newQueue = queue.value..add(mediaItem);
      queue.add(newQueue);
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Error adding queue item: $e');
      }
    }
  }

  @override
  Future<void> removeQueueItemAt(int index) async {
    try {
      if (index >= 0 && index < queue.value.length) {
        if (_player.sequence != null) {
          final playlist = _player.sequence! as ConcatenatingAudioSource;
          await playlist.removeAt(index);
        }

        final newQueue = queue.value..removeAt(index);
        queue.add(newQueue);

        // Adjust current index if necessary
        if (_currentIndex > index) {
          _currentIndex--;
        } else if (_currentIndex == index && newQueue.isNotEmpty) {
          if (_currentIndex >= newQueue.length) {
            _currentIndex = newQueue.length - 1;
          }
        }
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Error removing queue item: $e');
      }
    }
  }

  @override
  Future<void> onTaskRemoved() async {
    // Handle task removal (when user swipes away the app)
    final state = playbackState.value;
    if (state.playing) {
      await pause();
    }
    await super.onTaskRemoved();
  }

  @override
  Future<void> onNotificationDeleted() async {
    // Handle notification deletion
    await stop();
    await super.onNotificationDeleted();
  }

  /// Set the playback mode
  Future<void> setPlaybackMode(PlaybackMode mode) async {
    _playbackMode = mode;

    // Update shuffle mode if applicable
    if (mode == PlaybackMode.shuffle) {
      await _player.setShuffleModeEnabled(true);
    } else {
      await _player.setShuffleModeEnabled(false);
    }

    // Update loop mode
    switch (mode) {
      case PlaybackMode.repeatOne:
        await _player.setLoopMode(LoopMode.one);
        break;
      case PlaybackMode.repeatAll:
        await _player.setLoopMode(LoopMode.all);
        break;
      case PlaybackMode.normal:
      case PlaybackMode.shuffle:
        await _player.setLoopMode(LoopMode.off);
        break;
    }
  }

  /// Handle track completion and auto-advance to next track
  Future<void> _handleTrackCompletion() async {
    // Don't auto-advance if repeat one is enabled (handled by LoopMode.one)
    if (_playbackMode == PlaybackMode.repeatOne) {
      return;
    }

    // For normal and shuffle modes, advance to next track
    final nextIndex = _getNextIndex();
    if (nextIndex != -1) {
      try {
        await _player.seek(Duration.zero, index: nextIndex);
        await _player.play();
      } on Exception catch (e) {
        if (kDebugMode) {
          print('Error auto-advancing to next track: $e');
        }
      }
    }
    // If nextIndex == -1, we're at the end with no repeat - let it stay completed
  }

  /// Play a specific song
  Future<void> playSong(Song song, {List<Song>? playlist}) async {
    try {
      List<AudioSource> sources;

      if (playlist != null && playlist.isNotEmpty) {
        sources = playlist
            .map(
              (s) => AudioSource.uri(
                Uri.parse(s.songUrl),
                tag: s,
              ),
            )
            .toList();

        // Find the index of the current song
        _currentIndex = playlist.indexWhere((s) => s.id == song.id);
        if (_currentIndex == -1) {
          _currentIndex = 0;
        }
      } else {
        sources = [AudioSource.uri(Uri.parse(song.songUrl), tag: song)];
        _currentIndex = 0;
      }

      final concatenatingAudioSource =
          ConcatenatingAudioSource(children: sources);
      await _player.setAudioSource(
        concatenatingAudioSource,
        initialIndex: _currentIndex,
      );

      // Update queue
      if (playlist != null) {
        queue.add(
          playlist.map(_songToMediaItem).toList(),
        );
      } else {
        queue.add(
          [_songToMediaItem(song)],
        );
      }

      await _player.play();
      _updateMediaItem(song);
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Error playing song: $e');
      }
    }
  }

  /// Update the current media item
  void _updateMediaItem(Song song) {
    mediaItem.add(
      audio_service.MediaItem(
        id: song.id ?? '',
        album: song.albumName ?? '',
        title: song.songName,
        artist: song.artist,
        duration: song.duration,
        extras: {
          'songUrl': song.songUrl,
          'albumName': song.albumName,
          'duration': song.duration?.inSeconds,
        },
      ),
    );

    // Prefetch upcoming tracks when a new track starts
    unawaited(_prefetchUpcomingTracks());
  }

  /// Convert Song to MediaItem
  audio_service.MediaItem _songToMediaItem(Song song) =>
      audio_service.MediaItem(
        id: song.id ?? '',
        album: song.albumName ?? '',
        title: song.songName,
        artist: song.artist,
        duration: song.duration,
        extras: {
          'songUrl': song.songUrl,
          'albumName': song.albumName,
          'duration': song.duration?.inSeconds,
        },
      );

  /// Convert MediaItem to Song
  Song _mediaItemToSong(audio_service.MediaItem mediaItem) => Song(
        id: mediaItem.id,
        songName: mediaItem.title,
        artist: mediaItem.artist ?? '',
        albumName: mediaItem.album,
        songUrl: mediaItem.extras?['songUrl'] as String? ?? '',
        duration: Duration(seconds: mediaItem.extras?['duration'] as int? ?? 0),
      );

  /// Broadcast the current playback state
  void _broadcastState() {
    final playerState = _player.playerState;
    final processingState = _mapProcessingState(playerState.processingState);
    final playing = playerState.playing;

    final controls = <audio_service.MediaControl>[];

    if (playing) {
      controls.addAll(
        [
          audio_service.MediaControl.skipToPrevious,
          audio_service.MediaControl.pause,
          audio_service.MediaControl.skipToNext,
          audio_service.MediaControl.stop,
        ],
      );
    } else {
      controls.addAll(
        [
          audio_service.MediaControl.skipToPrevious,
          audio_service.MediaControl.play,
          audio_service.MediaControl.skipToNext,
          audio_service.MediaControl.stop,
        ],
      );
    }

    playbackState.add(
      audio_service.PlaybackState(
        controls: controls,
        systemActions: const {
          audio_service.MediaAction.seek,
          audio_service.MediaAction.seekForward,
          audio_service.MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: processingState,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: _currentIndex,
      ),
    );
  }

  /// Map just_audio processing state to audio_service processing state
  audio_service.AudioProcessingState _mapProcessingState(
    ProcessingState state,
  ) {
    switch (state) {
      case ProcessingState.idle:
        return audio_service.AudioProcessingState.idle;
      case ProcessingState.loading:
        return audio_service.AudioProcessingState.loading;
      case ProcessingState.buffering:
        return audio_service.AudioProcessingState.buffering;
      case ProcessingState.ready:
        return audio_service.AudioProcessingState.ready;
      case ProcessingState.completed:
        return audio_service.AudioProcessingState.completed;
    }
  }

  /// Get the next index based on playback mode
  int _getNextIndex() {
    final queueLength = queue.value.length;
    if (queueLength == 0) {
      return -1;
    }

    switch (_playbackMode) {
      case PlaybackMode.normal:
        return _currentIndex + 1 < queueLength ? _currentIndex + 1 : -1;
      case PlaybackMode.repeatAll:
        return _currentIndex + 1 < queueLength ? _currentIndex + 1 : 0;
      case PlaybackMode.repeatOne:
        return _currentIndex;
      case PlaybackMode.shuffle:
        return _getRandomIndex();
    }
  }

  /// Get the previous index based on playback mode
  int _getPreviousIndex() {
    final queueLength = queue.value.length;
    if (queueLength == 0) {
      return -1;
    }

    switch (_playbackMode) {
      case PlaybackMode.normal:
        return _currentIndex > 0 ? _currentIndex - 1 : -1;
      case PlaybackMode.repeatAll:
        return _currentIndex > 0 ? _currentIndex - 1 : queueLength - 1;
      case PlaybackMode.repeatOne:
        return _currentIndex;
      case PlaybackMode.shuffle:
        return _getRandomIndex();
    }
  }

  /// Get a random index different from current
  int _getRandomIndex() {
    final queueLength = queue.value.length;
    if (queueLength <= 1) {
      return _currentIndex;
    }

    int randomIndex;
    do {
      randomIndex = _random.nextInt(queueLength);
    } while (randomIndex == _currentIndex);

    return randomIndex;
  }

  /// Prefetch upcoming tracks to reduce playback latency
  ///
  /// This method preloads audio data for the next [_prefetchCount] tracks
  /// in the queue based on the current playback mode. Prefetched URLs are
  /// tracked to avoid redundant network requests.
  Future<void> _prefetchUpcomingTracks() async {
    final queueList = queue.value;
    if (queueList.isEmpty) {
      return;
    }

    final indicesToPrefetch = _getUpcomingIndices();
    if (indicesToPrefetch.isEmpty) {
      return;
    }

    for (final index in indicesToPrefetch) {
      if (index < 0 || index >= queueList.length) {
        continue;
      }

      final mediaItem = queueList[index];
      final songUrl = mediaItem.extras?['songUrl'] as String?;

      if (songUrl == null || songUrl.isEmpty) {
        continue;
      }

      // Skip if already prefetched
      if (_prefetchedUrls.contains(songUrl)) {
        continue;
      }

      // Mark as prefetched to avoid redundant requests
      _prefetchedUrls.add(songUrl);

      // Prefetch in background without blocking
      unawaited(_prefetchAudioUrl(songUrl));
    }
  }

  /// Get indices of upcoming tracks based on playback mode
  List<int> _getUpcomingIndices() {
    final queueLength = queue.value.length;
    if (queueLength <= 1) {
      return const [];
    }

    final indices = <int>[];

    switch (_playbackMode) {
      case PlaybackMode.normal:
        // Get next _prefetchCount tracks sequentially
        for (var i = 1; i <= _prefetchCount; i++) {
          final nextIndex = _currentIndex + i;
          if (nextIndex < queueLength) {
            indices.add(nextIndex);
          }
        }
        break;

      case PlaybackMode.repeatAll:
        // Get next _prefetchCount tracks, wrapping around
        for (var i = 1; i <= _prefetchCount; i++) {
          final nextIndex = (_currentIndex + i) % queueLength;
          if (nextIndex != _currentIndex) {
            indices.add(nextIndex);
          }
        }
        break;

      case PlaybackMode.repeatOne:
        // No need to prefetch - same track repeats
        break;

      case PlaybackMode.shuffle:
        // For shuffle, we can't predict - but we can prefetch a few random ones
        // to improve perceived performance
        final available = List<int>.generate(queueLength, (i) => i)
          ..remove(_currentIndex);
        available.shuffle(_random);
        indices.addAll(available.take(_prefetchCount));
        break;
    }

    return indices;
  }

  /// Prefetch audio data from a URL using HTTP range request
  ///
  /// Uses a small range request to initiate caching on CDN/server side
  /// and to verify the URL is accessible before playback.
  Future<void> _prefetchAudioUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      final httpClient = HttpClient();

      final request = await httpClient.getUrl(uri);
      // Request only first 64KB to trigger CDN caching without downloading entire file
      request.headers.set(HttpHeaders.rangeHeader, 'bytes=0-65535');

      final response = await request.close().timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException('Prefetch timeout for $url');
            },
          );

      // Drain response to complete the request
      await response.drain<void>();
      httpClient.close();

      if (kDebugMode) {
        print('AudioHandler: Prefetched audio: ${uri.pathSegments.last}');
      }
    } on Exception catch (e) {
      // Prefetch failures are non-critical - just log and continue
      if (kDebugMode) {
        print('AudioHandler: Prefetch failed: $e');
      }
      // Remove from prefetched set so it can be retried
      _prefetchedUrls.remove(url);
    }
  }

  /// Clear prefetched URLs cache (call when queue changes significantly)
  void clearPrefetchCache() {
    _prefetchedUrls.clear();
  }

  /// Clear the queue and reset playback state
  ///
  /// This properly clears the just_audio playlist, resets the index,
  /// and clears the queue to prepare for new content.
  Future<void> clearQueue() async {
    try {
      _currentIndex = 0;
      queue.add([]);

      // Stop playback and clear the audio source
      await _player.stop();
      await _player.setAudioSource(
        ConcatenatingAudioSource(children: []),
        initialIndex: 0,
      );

      clearPrefetchCache();

      if (kDebugMode) {
        print('AudioHandler: Queue cleared successfully');
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Error clearing queue: $e');
      }
    }
  }

  /// Clean up resources when the handler is destroyed
  Future<void> cleanUp() async {
    // Cancel all subscriptions
    await _playerStateSubscription?.cancel();
    await _positionSubscription?.cancel();
    await _durationSubscription?.cancel();
    await _sequenceStateSubscription?.cancel();

    // Dispose player
    await _player.dispose();
  }
}
