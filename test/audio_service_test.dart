import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:robin_radio/data/models/song.dart';
import 'package:robin_radio/data/services/audio/audio_services.dart';

void main() {
  group('IAudioService Tests', () {
    late IAudioService audioService;
    late Song testSong;

    setUp(() {
      audioService = MockAudioService();
      testSong = const Song(
        id: 'test_song_1',
        songName: 'Test Song',
        songUrl: 'https://example.com/test.mp3',
        artist: 'Test Artist',
        albumName: 'Test Album',
      );
    });

    tearDown(() async {
      await audioService.dispose();
    });

    group('Initialization', () {
      test('should initialize successfully', () async {
        await audioService.initialize();
        expect(audioService.isStopped, true);
      });

      test('should handle double initialization', () async {
        await audioService.initialize();
        await audioService.initialize();
        expect(audioService.isStopped, true);
      });
    });

    group('Basic Playback Controls', () {
      setUp(() async {
        await audioService.initialize();
      });

      test('should play a track', () async {
        await audioService.play(testSong);

        expect(audioService.currentSong, equals(testSong));
        expect(audioService.isPlaying, true);
        expect(audioService.queue.length, 1);
        expect(audioService.queue.first, equals(testSong));
      });

      test('should pause playback', () async {
        await audioService.play(testSong);
        await audioService.pause();

        expect(audioService.isPaused, true);
        expect(audioService.currentSong, equals(testSong));
      });

      test('should resume playback', () async {
        await audioService.play(testSong);
        await audioService.pause();
        await audioService.resume();

        expect(audioService.isPlaying, true);
        expect(audioService.currentSong, equals(testSong));
      });

      test('should stop playback', () async {
        await audioService.play(testSong);
        await audioService.stop();

        expect(audioService.isStopped, true);
        expect(audioService.currentSong, null);
        expect(audioService.currentPosition, Duration.zero);
      });

      test('should seek to position', () async {
        await audioService.play(testSong);
        const seekPosition = Duration(seconds: 30);
        await audioService.seek(seekPosition);

        expect(audioService.currentPosition, seekPosition);
      });
    });

    group('Volume and Speed Controls', () {
      setUp(() async {
        await audioService.initialize();
      });

      test('should set volume', () async {
        const volume = 0.5;
        await audioService.setVolume(volume);

        expect(audioService.currentVolume, volume);
      });

      test('should clamp volume to valid range', () async {
        await audioService.setVolume(-0.5);
        expect(audioService.currentVolume, 0.0);

        await audioService.setVolume(1.5);
        expect(audioService.currentVolume, 1.0);
      });

      test('should set playback speed', () async {
        const speed = 1.5;
        await audioService.setPlaybackSpeed(speed);

        expect(audioService.currentSpeed, speed);
      });

      test('should clamp speed to valid range', () async {
        await audioService.setPlaybackSpeed(0.1);
        expect(audioService.currentSpeed, 0.25);

        await audioService.setPlaybackSpeed(5);
        expect(audioService.currentSpeed, 3.0);
      });
    });

    group('Playback Mode Controls', () {
      setUp(() async {
        await audioService.initialize();
      });

      test('should set normal playback mode', () async {
        await audioService.setPlaybackMode(PlaybackMode.normal);
        expect(audioService.currentMode, PlaybackMode.normal);
      });

      test('should set repeat one mode', () async {
        await audioService.setPlaybackMode(PlaybackMode.repeatOne);
        expect(audioService.currentMode, PlaybackMode.repeatOne);
      });

      test('should set repeat all mode', () async {
        await audioService.setPlaybackMode(PlaybackMode.repeatAll);
        expect(audioService.currentMode, PlaybackMode.repeatAll);
      });

      test('should set shuffle mode', () async {
        await audioService.setPlaybackMode(PlaybackMode.shuffle);
        expect(audioService.currentMode, PlaybackMode.shuffle);
      });
    });

    group('Queue Management', () {
      setUp(() async {
        await audioService.initialize();
      });

      test('should add track to queue', () async {
        await audioService.addToQueue(testSong);

        expect(audioService.queue.length, 1);
        expect(audioService.queue.first, equals(testSong));
      });

      test('should add track at specific index', () async {
        const song2 = Song(
          id: 'test_song_2',
          songName: 'Test Song 2',
          songUrl: 'https://example.com/test2.mp3',
          artist: 'Test Artist 2',
          albumName: 'Test Album 2',
        );

        await audioService.addToQueue(testSong);
        await audioService.addToQueue(song2, index: 0);

        expect(audioService.queue.length, 2);
        expect(audioService.queue.first, equals(song2));
        expect(audioService.queue.last, equals(testSong));
      });

      test('should remove track from queue', () async {
        await audioService.addToQueue(testSong);
        await audioService.removeFromQueue(0);

        expect(audioService.queue.length, 0);
      });

      test('should clear entire queue', () async {
        await audioService.addToQueue(testSong);
        const song2 = Song(
          id: 'test_song_2',
          songName: 'Test Song 2',
          songUrl: 'https://example.com/test2.mp3',
          artist: 'Test Artist 2',
          albumName: 'Test Album 2',
        );
        await audioService.addToQueue(song2);

        await audioService.clearQueue();

        expect(audioService.queue.length, 0);
        expect(audioService.isStopped, true);
      });
    });

    group('Skip Controls', () {
      late Song song2;
      late Song song3;

      setUp(() async {
        await audioService.initialize();

        song2 = const Song(
          id: 'test_song_2',
          songName: 'Test Song 2',
          songUrl: 'https://example.com/test2.mp3',
          artist: 'Test Artist 2',
          albumName: 'Test Album 2',
        );

        song3 = const Song(
          id: 'test_song_3',
          songName: 'Test Song 3',
          songUrl: 'https://example.com/test3.mp3',
          artist: 'Test Artist 3',
          albumName: 'Test Album 3',
        );

        await audioService.addToQueue(testSong);
        await audioService.addToQueue(song2);
        await audioService.addToQueue(song3);
      });

      test('should skip to next track', () async {
        await audioService.play(testSong);
        await audioService.skipToNext();

        expect(audioService.currentSong, equals(song2));
      });

      test('should skip to previous track', () async {
        await audioService.play(song2);
        await audioService.skipToPrevious();

        expect(audioService.currentSong, equals(testSong));
      });
    });

    group('Background Playback', () {
      setUp(() async {
        await audioService.initialize();
      });

      test('should enable background playback', () async {
        await audioService.setBackgroundPlaybackEnabled(enabled: true);
        // Note: In mock implementation, this just sets a flag
        // In real implementation, this would configure platform-specific settings
      });

      test('should disable background playback', () async {
        await audioService.setBackgroundPlaybackEnabled(enabled: false);
        // Note: In mock implementation, this just sets a flag
      });
    });

    group('Duration Formatting', () {
      setUp(() async {
        await audioService.initialize();
      });

      test('should format short duration correctly', () {
        const duration = Duration(minutes: 2, seconds: 30);
        final formatted = audioService.formatDuration(duration);

        expect(formatted, '02:30');
      });

      test('should format long duration with hours', () {
        const duration = Duration(hours: 1, minutes: 15, seconds: 45);
        final formatted = audioService.formatDuration(duration);

        expect(formatted, '01:15:45');
      });

      test('should get formatted position and duration', () async {
        await audioService.play(testSong);

        expect(audioService.formattedPosition, isNotEmpty);
        expect(audioService.formattedDuration, isNotEmpty);
      });
    });

    group('Progress Calculation', () {
      setUp(() async {
        await audioService.initialize();
      });

      test('should calculate progress correctly', () async {
        await audioService.play(testSong);
        await audioService.seek(const Duration(seconds: 30));

        expect(audioService.progress, greaterThan(0.0));
        expect(audioService.progress, lessThanOrEqualTo(1.0));
      });

      test('should return zero progress when duration is zero', () async {
        expect(audioService.progress, 0.0);
      });
    });

    group('State Streams', () {
      setUp(() async {
        await audioService.initialize();
      });

      test('should emit playback state changes', () async {
        final states = <PlaybackState>[];
        audioService.playbackState.listen(states.add);

        await audioService.play(testSong);
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(states, contains(PlaybackState.playing));
      });

      test('should emit current track changes', () async {
        final tracks = <Song?>[];
        audioService.currentTrack.listen(tracks.add);

        await audioService.play(testSong);
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(tracks, contains(testSong));
      });

      test('should emit volume changes', () async {
        final volumes = <double>[];
        audioService.volume.listen(volumes.add);

        await audioService.setVolume(0.7);
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(volumes, contains(0.7));
      });
    });

    group('Error Handling', () {
      test('should handle operations on uninitialized service', () async {
        expect(
          () => audioService.play(testSong),
          throwsA(isA<StateError>()),
        );
      });
    });

    group('Disposal', () {
      test('should dispose cleanly', () async {
        await audioService.initialize();
        await audioService.play(testSong);
        await audioService.dispose();

        // After disposal, service should be in clean state
        expect(audioService.isStopped, true);
      });
    });
  });

  group('EnhancedAudioService Integration', () {
    late EnhancedAudioService realService;

    setUp(() {
      realService = EnhancedAudioService();
    });

    tearDown(() async {
      await realService.dispose();
    });

    test('should implement IAudioService interface', () {
      expect(realService, isA<IAudioService>());
    });

    test('should be a singleton', () {
      final instance1 = EnhancedAudioService();
      final instance2 = EnhancedAudioService();
      expect(identical(instance1, instance2), true);
    });

    test('should handle lifecycle events', () {
      // Test the manual lifecycle handler
      realService
        ..handleAppLifecycleState(AppLifecycleState.paused)
        ..handleAppLifecycleState(AppLifecycleState.resumed);
      // No assertion needed - just ensure it doesn't crash
    });
  });
}
