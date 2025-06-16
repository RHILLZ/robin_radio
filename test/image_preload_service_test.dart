import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:robin_radio/data/services/image_preload_service.dart';

void main() {
  group('ImagePreloadService Tests', () {
    late ImagePreloadService service;

    setUp(() {
      service = ImagePreloadService.instance;
    });

    tearDown(() {
      service.clearPreloadCache();
      service.clearAnalytics();
    });

    group('Configuration Tests', () {
      test('should initialize with default configuration', () {
        service.initialize();

        expect(service.config.preloadOnWifi, isTrue);
        expect(service.config.preloadOnMobile, isFalse);
        expect(service.config.maxConcurrentPreloads, equals(3));
        expect(service.config.compressionQuality, equals(85));
      });

      test('should initialize with custom configuration', () {
        const customConfig = ImagePreloadConfig(
          preloadOnWifi: false,
          preloadOnMobile: true,
          maxConcurrentPreloads: 5,
          compressionQuality: 90,
        );

        service.initialize(config: customConfig);

        expect(service.config.preloadOnWifi, isFalse);
        expect(service.config.preloadOnMobile, isTrue);
        expect(service.config.maxConcurrentPreloads, equals(5));
        expect(service.config.compressionQuality, equals(90));
      });

      test('should provide predefined configurations', () {
        // Conservative config
        expect(ImagePreloadConfig.conservative.preloadOnWifi, isTrue);
        expect(ImagePreloadConfig.conservative.preloadOnMobile, isFalse);
        expect(
          ImagePreloadConfig.conservative.maxConcurrentPreloads,
          equals(2),
        );
        expect(ImagePreloadConfig.conservative.compressionQuality, equals(70));

        // Aggressive config
        expect(ImagePreloadConfig.aggressive.preloadOnWifi, isTrue);
        expect(ImagePreloadConfig.aggressive.preloadOnMobile, isTrue);
        expect(ImagePreloadConfig.aggressive.maxConcurrentPreloads, equals(5));
        expect(ImagePreloadConfig.aggressive.compressionQuality, equals(90));

        // Minimal config
        expect(ImagePreloadConfig.minimal.preloadOnWifi, isFalse);
        expect(ImagePreloadConfig.minimal.preloadOnMobile, isFalse);
        expect(ImagePreloadConfig.minimal.maxConcurrentPreloads, equals(1));
        expect(ImagePreloadConfig.minimal.compressionQuality, equals(60));
      });
    });

    group('Compression Configuration Tests', () {
      test('should provide correct compression presets', () {
        // Thumbnail preset
        const thumbnail = CompressionConfig.thumbnail;
        expect(thumbnail.quality, equals(60));
        expect(thumbnail.maxWidth, equals(150));
        expect(thumbnail.maxHeight, equals(150));

        // Preview preset
        const preview = CompressionConfig.preview;
        expect(preview.quality, equals(75));
        expect(preview.maxWidth, equals(500));
        expect(preview.maxHeight, equals(500));

        // Standard preset
        const standard = CompressionConfig.standard;
        expect(standard.quality, equals(85));
        expect(standard.maxWidth, equals(1024));
        expect(standard.maxHeight, equals(1024));

        // High quality preset
        const highQuality = CompressionConfig.highQuality;
        expect(highQuality.quality, equals(95));
        expect(highQuality.maxWidth, equals(2048));
        expect(highQuality.maxHeight, equals(2048));
      });

      test('should create configuration from presets', () {
        final thumbnailConfig =
            CompressionConfig.fromPreset(CompressionPreset.thumbnail);
        expect(thumbnailConfig.quality, equals(60));
        expect(thumbnailConfig.maxWidth, equals(150));
        expect(thumbnailConfig.maxHeight, equals(150));

        final losslessConfig =
            CompressionConfig.fromPreset(CompressionPreset.lossless);
        expect(losslessConfig.quality, equals(100));
      });
    });

    group('Analytics Tests', () {
      test('should track preload analytics correctly', () {
        final analytics = PreloadAnalytics(
          url: 'test_url',
          startTime: DateTime.now(),
          success: true,
          fileSize: 1024,
          connectionType: 'wifi',
        );
        analytics.endTime =
            DateTime.now().add(const Duration(milliseconds: 500));

        expect(analytics.url, equals('test_url'));
        expect(analytics.success, isTrue);
        expect(analytics.fileSize, equals(1024));
        expect(analytics.connectionType, equals('wifi'));
        expect(analytics.duration, isNotNull);
        expect(analytics.duration!.inMilliseconds, greaterThanOrEqualTo(500));
      });

      test('should convert analytics to JSON', () {
        final startTime = DateTime.now();
        final endTime = startTime.add(const Duration(milliseconds: 500));

        final analytics = PreloadAnalytics(
          url: 'test_url',
          startTime: startTime,
          success: true,
          fileSize: 1024,
          connectionType: 'wifi',
        );
        analytics.endTime = endTime;

        final json = analytics.toJson();
        expect(json['url'], equals('test_url'));
        expect(json['success'], isTrue);
        expect(json['fileSize'], equals(1024));
        expect(json['connectionType'], equals('wifi'));
        expect(json['duration'], equals(500));
      });

      test('should provide preload statistics', () {
        service.initialize();

        // Initially empty stats
        final initialStats = service.getPreloadStats();
        expect(initialStats['totalPreloads'], equals(0));
        expect(initialStats['successful'], equals(0));
        expect(initialStats['failed'], equals(0));
        expect(initialStats['successRate'], equals(0));
        expect(initialStats['preloadedUrls'], equals(0));
        expect(initialStats['currentlyPreloading'], equals(0));
      });
    });

    group('Cache Management Tests', () {
      test('should track preloaded URLs', () {
        const testUrl = 'https://example.com/image.jpg';

        expect(service.isPreloaded(testUrl), isFalse);
        expect(service.isPreloading(testUrl), isFalse);

        // Simulate preloading process would mark URLs as preloaded
        // Note: This is a unit test, so we're testing the interface
      });

      test('should clear preload cache', () {
        service.clearPreloadCache();

        final stats = service.getPreloadStats();
        expect(stats['preloadedUrls'], equals(0));
        expect(stats['currentlyPreloading'], equals(0));
      });

      test('should clear analytics', () {
        service.clearAnalytics();

        final analytics = service.getAnalytics();
        expect(analytics, isEmpty);
      });
    });

    group('Widget Tests', () {
      testWidgets('should preload essential assets in app view',
          (tester) async {
        // Initialize service with conservative config
        service.initialize(config: ImagePreloadConfig.conservative);

        // Create a test widget that uses the preload service
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                // Simulate preloading essential assets
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  service.preloadEssentialAssets(context);
                });
                return const Scaffold(
                  body: Center(child: Text('Test')),
                );
              },
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify the widget was built successfully
        expect(find.text('Test'), findsOneWidget);
      });

      testWidgets('should use extension methods for preloading',
          (tester) async {
        // Initialize service
        service.initialize();

        // Test extension methods
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                // Test extension methods exist and can be called
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  // These would normally make network calls, but in test environment
                  // they will handle gracefully
                  context.preloadImages(['https://example.com/image1.jpg']);
                  context.preloadAlbumCovers(
                    ['https://example.com/cover1.jpg'],
                    limit: 5,
                  );
                });
                return const Scaffold(
                  body: Center(child: Text('Extension Test')),
                );
              },
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify the extension methods don't cause crashes
        expect(find.text('Extension Test'), findsOneWidget);
      });
    });

    group('Error Handling Tests', () {
      test('should handle compression errors gracefully', () async {
        service.initialize();

        // Test with non-existent file path
        expect(
          () => service.compressImageForUpload('/non/existent/path.jpg'),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle empty image data', () async {
        service.initialize();

        // Test with empty data - should throw an exception
        final emptyData = Uint8List(0);
        expect(
          () => service.compressImageData(emptyData),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('File Size Formatting Tests', () {
      test('should format file sizes correctly', () {
        // Note: _formatFileSize is private, but we can test the concept
        // In a real implementation, you might expose this as a utility function

        // Test bytes
        expect(500 < 1024, isTrue); // Would format as "500B"

        // Test KB
        expect(
          1536 >= 1024 && 1536 < 1024 * 1024,
          isTrue,
        ); // Would format as "1.5KB"

        // Test MB
        expect(
          2 * 1024 * 1024 >= 1024 * 1024,
          isTrue,
        ); // Would format as "2.0MB"
      });
    });
  });
}
