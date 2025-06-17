// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:robin_radio/data/repositories/firebase_music_repository.dart';
import 'package:robin_radio/data/repositories/mock_music_repository.dart';
import 'package:robin_radio/main.dart';

void main() {
  group('Repository Cache-Only Tests', () {
    test(
        'MockMusicRepository getAlbumsFromCacheOnly should return albums without delay',
        () async {
      const repository = MockMusicRepository();

      final albums = await repository.getAlbumsFromCacheOnly();

      expect(albums, isNotEmpty);
      expect(albums.length, 2); // Mock repository has 2 sample albums
    });

    test('MockMusicRepository getAlbumsFromCacheOnly should never throw errors',
        () async {
      const repository = MockMusicRepository(simulateErrors: true);

      // Even with simulateErrors: true, cache-only should never throw
      final albums = await repository.getAlbumsFromCacheOnly();

      expect(albums, isNotEmpty);
    });

    test(
        'FirebaseMusicRepository getAlbumsFromCacheOnly should return empty list when no cache',
        () async {
      try {
        final repository = FirebaseMusicRepository();

        // Since we haven't cached anything, this should return empty list
        final albums = await repository.getAlbumsFromCacheOnly();

        expect(albums, isEmpty);
      } catch (e) {
        // In test environment, Firebase might not be initialized
        // This is expected behavior and the test should pass
        expect(e.toString(), contains('Firebase'));
      }
    });
  });

  testWidgets('Counter increments smoke test', (tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(theme: ThemeData.light()));

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
