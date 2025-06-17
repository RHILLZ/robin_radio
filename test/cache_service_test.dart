import 'package:flutter_test/flutter_test.dart';
import 'package:robin_radio/data/services/cache/cache_services.dart';

void main() {
  group('Cache Service Tests', () {
    late MockCacheService mockCache;
    late ICacheService cacheService;

    setUp(() {
      mockCache = MockCacheService();
      cacheService = mockCache;
    });

    tearDown(() async {
      await mockCache.dispose();
    });

    group('Basic Operations', () {
      test('should store and retrieve string data', () async {
        const key = 'test_string';
        const value = 'Hello, World!';

        await cacheService.set(key, value);
        final result = await cacheService.get<String>(key);

        expect(result, equals(value));
      });

      test('should store and retrieve map data', () async {
        const key = 'test_map';
        final value = {'name': 'John', 'age': 30, 'active': true};

        await cacheService.set(key, value);
        final result = await cacheService.get<Map<String, dynamic>>(key);

        expect(result, equals(value));
      });

      test('should store and retrieve list data', () async {
        const key = 'test_list';
        final value = [1, 2, 3, 'four', true];

        await cacheService.set(key, value);
        final result = await cacheService.get<List<dynamic>>(key);

        expect(result, equals(value));
      });

      test('should return null for non-existent key', () async {
        final result = await cacheService.get<String>('non_existent');
        expect(result, isNull);
      });

      test('should check if key exists', () async {
        const key = 'existence_test';
        const value = 'I exist';

        expect(await cacheService.has(key), isFalse);

        await cacheService.set(key, value);
        expect(await cacheService.has(key), isTrue);
      });

      test('should remove individual items', () async {
        const key = 'to_be_removed';
        const value = 'Remove me';

        await cacheService.set(key, value);
        expect(await cacheService.has(key), isTrue);

        await cacheService.remove(key);
        expect(await cacheService.has(key), isFalse);
        expect(await cacheService.get<String>(key), isNull);
      });

      test('should clear all cache', () async {
        await cacheService.set('key1', 'value1');
        await cacheService.set('key2', 'value2');
        await cacheService.set('key3', 'value3');

        expect(await cacheService.has('key1'), isTrue);
        expect(await cacheService.has('key2'), isTrue);
        expect(await cacheService.has('key3'), isTrue);

        await cacheService.clear();

        expect(await cacheService.has('key1'), isFalse);
        expect(await cacheService.has('key2'), isFalse);
        expect(await cacheService.has('key3'), isFalse);
      });
    });

    group('Memory-Only Operations', () {
      test('should handle memory-only storage', () async {
        const key = 'memory_only';
        const value = 'In memory only';

        await cacheService.set(key, value, memoryOnly: true);

        // Should find in memory
        final result1 =
            await cacheService.get<String>(key, fromMemoryOnly: true);
        expect(result1, equals(value));

        // Should also find in general get (since mock doesn't distinguish)
        final result2 = await cacheService.get<String>(key);
        expect(result2, equals(value));
      });

      test('should handle memory-only retrieval', () async {
        const key = 'memory_check';
        const value = 'Check memory';

        await cacheService.set(key, value);

        // Should find item
        final result1 =
            await cacheService.get<String>(key, fromMemoryOnly: true);
        expect(result1, equals(value));

        // Non-existent key should return null
        final result2 = await cacheService.get<String>(
          'non_existent',
          fromMemoryOnly: true,
        );
        expect(result2, isNull);
      });

      test('should handle memory-only removal', () async {
        const key = 'memory_remove';
        const value = 'Remove from memory';

        await cacheService.set(key, value);
        expect(await cacheService.has(key), isTrue);

        await cacheService.remove(key, fromMemoryOnly: true);
        expect(await cacheService.has(key), isFalse);
      });

      test('should handle memory-only clear', () async {
        await cacheService.set('mem1', 'value1');
        await cacheService.set('mem2', 'value2');

        await cacheService.clear(memoryOnly: true);

        expect(await cacheService.has('mem1'), isFalse);
        expect(await cacheService.has('mem2'), isFalse);
      });
    });

    group('Expiration', () {
      test('should handle custom expiry duration', () async {
        const key = 'custom_expiry';
        const value = 'Will expire';
        const expiry = Duration(milliseconds: 100);

        await cacheService.set(key, value, expiry: expiry);

        // Should exist immediately
        expect(await cacheService.has(key), isTrue);
        expect(await cacheService.get<String>(key), equals(value));

        // Wait for expiry
        await Future.delayed(const Duration(milliseconds: 150));

        // Should be expired
        expect(await cacheService.has(key), isFalse);
        expect(await cacheService.get<String>(key), isNull);
      });

      test('should clear expired items manually', () async {
        await cacheService.set(
          'key1',
          'value1',
          expiry: const Duration(hours: 1),
        );
        await cacheService.set(
          'key2',
          'value2',
          expiry: const Duration(hours: 1),
        );

        // Manually expire one item
        mockCache.expireItem('key1');

        // Clear expired items
        await cacheService.clearExpired();

        // Only the expired item should be gone
        expect(await cacheService.has('key1'), isFalse);
        expect(await cacheService.has('key2'), isTrue);
      });

      test('should handle expired items in get operations', () async {
        const key = 'auto_expire';
        const value = 'Will auto-expire';

        await cacheService.set(key, value, expiry: const Duration(hours: 1));

        // Manually expire the item
        mockCache.expireItem(key);

        // Getting expired item should return null and clean it up
        final result = await cacheService.get<String>(key);
        expect(result, isNull);
        expect(await cacheService.has(key), isFalse);
      });
    });

    group('Size Management', () {
      test('should track cache size', () async {
        final initialSize = await cacheService.getCacheSize();

        await cacheService.set('size_test', 'Some data to measure');

        final newSize = await cacheService.getCacheSize();
        expect(newSize, greaterThan(initialSize));
      });

      test('should set maximum cache size', () async {
        const maxSize = 1000; // 1KB

        await cacheService.setMaxCacheSize(maxSize);

        // Add data that might exceed the limit
        for (var i = 0; i < 100; i++) {
          await cacheService.set(
            'item_$i',
            'Data for item $i with some length',
          );
        }

        final finalSize = await cacheService.getCacheSize();
        expect(
          finalSize,
          lessThanOrEqualTo(maxSize * 1.1),
        ); // Allow small buffer
      });

      test('should throw error for invalid cache size', () async {
        expect(
          () async => cacheService.setMaxCacheSize(-1),
          throwsA(isA<CacheConfigurationException>()),
        );

        expect(
          () async => cacheService.setMaxCacheSize(0),
          throwsA(isA<CacheConfigurationException>()),
        );
      });
    });

    group('Statistics', () {
      test('should track cache hit/miss statistics', () async {
        // Start with fresh statistics
        mockCache.reset();

        const key = 'stats_test';
        const value = 'Statistics data';

        // This should be a miss
        await cacheService.get<String>(key);

        // Store and retrieve - this should be a hit
        await cacheService.set(key, value);
        await cacheService.get<String>(key);

        final stats = await cacheService.getStatistics();

        expect(stats.totalRequests, equals(2));
        expect(stats.hits, equals(1));
        expect(stats.misses, equals(1));
        expect(stats.hitRatio, equals(0.5));
        expect(stats.memoryItemCount, equals(1));
      });

      test('should track evictions in statistics', () async {
        mockCache.reset();

        // Set a small cache size to force evictions
        await cacheService.setMaxCacheSize(500);

        // Add items until eviction occurs
        for (var i = 0; i < 50; i++) {
          await cacheService.set('evict_$i', 'Data for eviction test item $i');
        }

        final stats = await cacheService.getStatistics();
        expect(stats.evictions, greaterThan(0));
      });

      test('should track expired items in statistics', () async {
        mockCache.reset();

        await cacheService.set(
          'expire1',
          'data1',
          expiry: const Duration(hours: 1),
        );
        await cacheService.set(
          'expire2',
          'data2',
          expiry: const Duration(hours: 1),
        );

        // Manually expire items
        mockCache.expireItem('expire1');
        mockCache.expireItem('expire2');

        await cacheService.clearExpired();

        final stats = await cacheService.getStatistics();
        expect(stats.expiredItems, equals(2));
      });

      test('should provide current cache statistics', () async {
        final stats = await cacheService.getStatistics();

        expect(stats.totalRequests, isA<int>());
        expect(stats.hits, isA<int>());
        expect(stats.misses, isA<int>());
        expect(stats.hitRatio, isA<double>());
        expect(stats.memoryCacheSize, isA<int>());
        expect(stats.diskCacheSize, isA<int>());
        expect(stats.memoryItemCount, isA<int>());
        expect(stats.diskItemCount, isA<int>());
        expect(stats.evictions, isA<int>());
        expect(stats.expiredItems, isA<int>());
        expect(stats.lastUpdated, isA<DateTime>());
      });

      test('should format statistics string correctly', () async {
        mockCache.reset();
        await cacheService.set('stats_format', 'test data');
        await cacheService.get<String>('stats_format');

        final stats = await cacheService.getStatistics();
        final statsString = stats.toString();

        expect(statsString, contains('CacheStatistics'));
        expect(statsString, contains('requests:'));
        expect(statsString, contains('hitRatio:'));
        expect(statsString, contains('totalSize:'));
        expect(statsString, contains('items:'));
      });
    });

    group('Events', () {
      test('should emit cache events', () async {
        final events = <CacheEvent>[];
        final subscription = cacheService.events.listen(events.add);

        const key = 'event_test';
        const value = 'Event data';

        // Set should emit set event
        await cacheService.set(key, value);

        // Get hit should emit hit event
        await cacheService.get<String>(key);

        // Get miss should emit miss event
        await cacheService.get<String>('non_existent');

        // Remove should emit remove event
        await cacheService.remove(key);

        // Clear should emit clear event
        await cacheService.clear();

        await subscription.cancel();

        expect(events.length, greaterThanOrEqualTo(5));

        final eventTypes = events.map((e) => e.type).toList();
        expect(eventTypes, contains(CacheEventType.set));
        expect(eventTypes, contains(CacheEventType.hit));
        expect(eventTypes, contains(CacheEventType.miss));
        expect(eventTypes, contains(CacheEventType.remove));
        expect(eventTypes, contains(CacheEventType.clear));
      });

      test('should emit eviction events', () async {
        final events = <CacheEvent>[];
        final subscription = cacheService.events.listen(events.add);

        // Set small cache size to force eviction
        await cacheService.setMaxCacheSize(200);

        // Add items to trigger eviction
        for (var i = 0; i < 20; i++) {
          await cacheService.set('evict_$i', 'Data for item $i');
        }

        await subscription.cancel();

        final evictionEvents =
            events.where((e) => e.type == CacheEventType.eviction).toList();
        expect(evictionEvents.length, greaterThan(0));
      });

      test('should emit cleanup events', () async {
        final events = <CacheEvent>[];
        final subscription = cacheService.events.listen(events.add);

        await cacheService.set(
          'cleanup1',
          'data1',
          expiry: const Duration(hours: 1),
        );
        mockCache.expireItem('cleanup1');
        await cacheService.clearExpired();

        await subscription.cancel();

        final cleanupEvents =
            events.where((e) => e.type == CacheEventType.cleanup).toList();
        expect(cleanupEvents.length, equals(1));
      });

      test('should format cache events correctly', () async {
        const key = 'format_test';
        const value = 'Format data';

        final events = <CacheEvent>[];
        final subscription = cacheService.events.listen(events.add);

        await cacheService.set(key, value);

        await subscription.cancel();

        expect(events.length, greaterThan(0));

        final event = events.first;
        final eventString = event.toString();

        expect(eventString, contains('CacheEvent'));
        expect(eventString, contains(key));
        expect(eventString, contains('at'));
      });
    });

    group('Preloading', () {
      test('should preload specified keys', () async {
        const keys = ['preload1', 'preload2', 'preload3'];
        const values = ['data1', 'data2', 'data3'];

        // Store some data first
        for (var i = 0; i < keys.length; i++) {
          await cacheService.set(keys[i], values[i]);
        }

        // Clear and preload
        await cacheService.clear();

        // Add back to "disk" (in mock, just add back)
        for (var i = 0; i < keys.length; i++) {
          await cacheService.set(keys[i], values[i]);
        }

        // Preload should load into memory
        await cacheService.preload(keys);

        // Verify items are accessible
        for (var i = 0; i < keys.length; i++) {
          final result = await cacheService.get<String>(keys[i]);
          expect(result, equals(values[i]));
        }
      });

      test('should handle preloading non-existent keys', () async {
        const keys = ['non_existent1', 'non_existent2'];

        // Should not throw error
        await cacheService.preload(keys);

        // Keys should still not exist
        for (final key in keys) {
          expect(await cacheService.has(key), isFalse);
        }
      });
    });

    group('Error Handling', () {
      test('should throw configuration exception for invalid cache size',
          () async {
        expect(
          () async => cacheService.setMaxCacheSize(-100),
          throwsA(isA<CacheConfigurationException>()),
        );
      });

      test('should handle cache service exceptions', () async {
        // Test that our exception types are properly structured
        const exception = CacheReadException.keyAccessFailed('test_key');

        expect(exception.message, contains('test_key'));
        expect(exception.errorCode, isNotEmpty);
        expect(exception.toString(), contains('CacheServiceException'));
      });
    });

    group('Mock-Specific Features', () {
      test('should reset mock cache state', () async {
        await cacheService.set('reset_test', 'data');
        await cacheService.get<String>('reset_test');

        var stats = await cacheService.getStatistics();
        expect(stats.totalRequests, greaterThan(0));
        expect(stats.memoryItemCount, greaterThan(0));

        mockCache.reset();

        stats = await cacheService.getStatistics();
        expect(stats.totalRequests, equals(0));
        expect(stats.hits, equals(0));
        expect(stats.misses, equals(0));
        expect(stats.memoryItemCount, equals(0));
      });

      test('should add multiple test items at once', () async {
        final testData = {
          'item1': 'value1',
          'item2': {'nested': 'object'},
          'item3': [1, 2, 3],
        };

        await mockCache.addTestItems(testData);

        for (final entry in testData.entries) {
          final result = await cacheService.get(entry.key);
          expect(result, equals(entry.value));
        }
      });

      test('should get cache contents for debugging', () async {
        await cacheService.set('debug1', 'data1');
        await cacheService.set('debug2', 'data2');

        final contents = mockCache.getCacheContents();

        expect(contents, hasLength(2));
        expect(contents['debug1'], equals('data1'));
        expect(contents['debug2'], equals('data2'));
      });

      test('should manually expire items for testing', () async {
        const key = 'manual_expire';
        const value = 'Will be expired';

        await cacheService.set(key, value);
        expect(await cacheService.has(key), isTrue);

        mockCache.expireItem(key);
        expect(await cacheService.has(key), isFalse);
      });
    });

    group('Edge Cases', () {
      test('should handle null values', () async {
        const key = 'null_test';

        await cacheService.set(key, null);
        final result = await cacheService.get(key);

        expect(result, isNull);
      });

      test('should handle empty strings', () async {
        const key = 'empty_string';
        const value = '';

        await cacheService.set(key, value);
        final result = await cacheService.get<String>(key);

        expect(result, equals(value));
      });

      test('should handle complex nested objects', () async {
        const key = 'complex_object';
        final value = {
          'user': {
            'id': 123,
            'name': 'John Doe',
            'preferences': {
              'theme': 'dark',
              'notifications': [
                {'type': 'email', 'enabled': true},
                {'type': 'push', 'enabled': false},
              ],
            },
          },
          'metadata': {
            'created': '2024-01-01T00:00:00Z',
            'version': 1.2,
          },
        };

        await cacheService.set(key, value);
        final result = await cacheService.get<Map<String, dynamic>>(key);

        expect(result, equals(value));
      });

      test('should handle concurrent operations', () async {
        final futures = <Future>[];

        // Perform multiple concurrent operations
        for (var i = 0; i < 10; i++) {
          futures.add(cacheService.set('concurrent_$i', 'data_$i'));
        }

        for (var i = 0; i < 10; i++) {
          futures.add(cacheService.get<String>('concurrent_$i'));
        }

        // Wait for all operations to complete
        await Future.wait(futures);

        // Verify all items were stored correctly
        for (var i = 0; i < 10; i++) {
          final result = await cacheService.get<String>('concurrent_$i');
          expect(result, equals('data_$i'));
        }
      });
    });
  });
}
