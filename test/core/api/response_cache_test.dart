import 'dart:io';

import 'package:cuentimobile/core/api/response_cache.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory dir;
  late ResponseCache cache;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('cuenti-cache-test');
    cache = ResponseCache(dir);
  });

  tearDown(() => dir.deleteSync(recursive: true));

  group('cacheKeyFor', () {
    RequestOptions request(String path, [Map<String, dynamic>? query]) =>
        RequestOptions(path: path, queryParameters: query ?? {});

    test('separates different endpoints', () {
      expect(cacheKeyFor(request('/a')), isNot(cacheKeyFor(request('/b'))));
    });

    test('separates different query parameters, so a filtered list does not '
        'serve an unfiltered one', () {
      expect(
        cacheKeyFor(request('/transactions', {'page': 0})),
        isNot(cacheKeyFor(request('/transactions', {'page': 1}))),
      );
    });

    test('ignores the order parameters happen to be written in', () {
      expect(
        cacheKeyFor(request('/t', {'a': 1, 'b': 2})),
        cacheKeyFor(request('/t', {'b': 2, 'a': 1})),
      );
    });

    test('is safe to use as a file name', () {
      final key = cacheKeyFor(request('/a/b/c', {'q': 'x y/z'}));
      expect(key, matches(RegExp(r'^[A-Za-z0-9_-]+$')));
    });
  });

  group('ResponseCache', () {
    test('returns nothing for an endpoint never seen', () async {
      expect(await cache.read('unknown'), isNull);
    });

    test('gives back what was stored', () async {
      await cache.store('k', {'total': 42});

      final entry = await cache.read('k');
      expect(entry?.body, {'total': 42});
    });

    test(
      'records when it was stored, so the UI can say how stale it is',
      () async {
        final before = DateTime.now().subtract(const Duration(seconds: 1));
        await cache.store('k', {'total': 42});

        expect(
          await cache.read('k').then((e) => e!.storedAt.isAfter(before)),
          isTrue,
        );
      },
    );

    test('a later store replaces the earlier one', () async {
      await cache.store('k', {'total': 1});
      await cache.store('k', {'total': 2});

      expect((await cache.read('k'))?.body, {'total': 2});
    });

    test('survives being reopened on the same directory', () async {
      await cache.store('k', {'total': 42});

      expect((await ResponseCache(dir).read('k'))?.body, {'total': 42});
    });

    test('stores lists as happily as maps', () async {
      await cache.store('k', [1, 2, 3]);

      expect((await cache.read('k'))?.body, [1, 2, 3]);
    });

    test('treats a corrupted entry as a miss rather than throwing', () async {
      await cache.store('k', {'total': 42});
      File('${dir.path}/k.json').writeAsStringSync('{not json');

      expect(await cache.read('k'), isNull);
    });

    test('clear drops everything, for logout', () async {
      await cache.store('k', {'total': 42});
      await cache.clear();

      expect(await cache.read('k'), isNull);
    });
  });

  group('bounding the store', () {
    test('an entry older than the maximum age reads as a miss, so months '
        'old figures are never presented as the last known ones', () async {
      final old = ResponseCache(dir, maxAge: const Duration(days: 7));
      await old.store('k', {'total': 42});
      // Backdate the entry the way the passage of time would.
      File('${dir.path}/k.json').setLastModifiedSync(
        DateTime.now().subtract(const Duration(days: 8)),
      );

      expect(await old.read('k'), isNull);
    });

    test('an entry inside the maximum age still reads', () async {
      final fresh = ResponseCache(dir, maxAge: const Duration(days: 7));
      await fresh.store('k', {'total': 42});
      File('${dir.path}/k.json').setLastModifiedSync(
        DateTime.now().subtract(const Duration(days: 6)),
      );

      expect((await fresh.read('k'))?.body, {'total': 42});
    });

    test('the store is capped, because every search anyone types becomes '
        'its own entry', () async {
      final capped = ResponseCache(dir, maxEntries: 3);
      for (var i = 0; i < 10; i++) {
        await capped.store('key$i', {'n': i});
      }

      expect(dir.listSync().length, lessThanOrEqualTo(3));
    });

    test('eviction drops the oldest first and keeps the newest', () async {
      final capped = ResponseCache(dir, maxEntries: 2);
      await capped.store('oldest', {'n': 1});
      File('${dir.path}/oldest.json').setLastModifiedSync(
        DateTime.now().subtract(const Duration(hours: 3)),
      );
      await capped.store('middle', {'n': 2});
      File('${dir.path}/middle.json').setLastModifiedSync(
        DateTime.now().subtract(const Duration(hours: 2)),
      );
      await capped.store('newest', {'n': 3});

      expect(await capped.read('newest'), isNotNull);
      expect(await capped.read('oldest'), isNull);
    });

    test('re-storing a key refreshes it rather than adding another', () async {
      final capped = ResponseCache(dir, maxEntries: 2);
      await capped.store('a', {'n': 1});
      await capped.store('a', {'n': 2});
      await capped.store('b', {'n': 3});

      expect((await capped.read('a'))?.body, {'n': 2});
      expect((await capped.read('b'))?.body, {'n': 3});
    });

    test('defaults are generous enough not to evict in normal use', () async {
      final plain = ResponseCache(dir);
      for (var i = 0; i < 20; i++) {
        await plain.store('key$i', {'n': i});
      }

      expect(await plain.read('key0'), isNotNull);
    });
  });
}
