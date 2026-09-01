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

    test('records when it was stored, so the UI can say how stale it is',
        () async {
      final before = DateTime.now().subtract(const Duration(seconds: 1));
      await cache.store('k', {'total': 42});

      expect(await cache.read('k').then((e) => e!.storedAt.isAfter(before)),
          isTrue);
    });

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
}
