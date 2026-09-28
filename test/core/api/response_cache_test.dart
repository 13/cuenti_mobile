import 'dart:async';
import 'dart:io';

import 'package:cuentimobile/core/api/response_cache.dart';
import 'package:cuentimobile/core/storage/at_rest_cipher.dart';
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

  test(
    'an entry written "in the future" is a miss: the clock was moved back',
    () async {
      final dir = Directory.systemTemp.createTempSync('cache_clock');
      addTearDown(() => dir.deleteSync(recursive: true));
      final cache = ResponseCache(dir);
      await cache.store('k', {'a': 1});
      File(
        '${dir.path}/k.json',
      ).setLastModifiedSync(DateTime.now().add(const Duration(days: 1)));

      expect(await cache.read('k'), isNull);
    },
  );

  test('the server is part of the cache key', () {
    RequestOptions at(String base) =>
        RequestOptions(path: '/transactions', baseUrl: base);

    expect(
      cacheKeyFor(at('https://a.example/api')),
      isNot(cacheKeyFor(at('https://b.example/api'))),
    );
  });

  group('writes in flight', () {
    test('a clear while a write is still encrypting leaves nothing behind, '
        "so a sign-out cannot have the old account's figures written back "
        'after it', () async {
      final gate = Completer<void>();
      final slow = ResponseCache(dir, cipher: _GatedCipher(gate.future));

      final writing = slow.store('k', {'total': 42});
      final clearing = slow.clear();
      gate.complete();
      await writing;
      await clearing;

      expect(await slow.read('k'), isNull);
      expect(dir.listSync(), isEmpty);
    });

    test('an answer to a request made before a clear is not written after '
        'it', () async {
      final before = cache.generation;
      await cache.clear();

      await cache.store('k', {'total': 42}, generation: before);

      expect(await cache.read('k'), isNull);
    });

    test('a read waits for a write to the same key that is still going, '
        'rather than missing it', () async {
      final gate = Completer<void>();
      final slow = ResponseCache(dir, cipher: _GatedCipher(gate.future));

      unawaited(slow.store('k', {'total': 42}));
      final reading = slow.read('k');
      gate.complete();

      expect((await reading)?.body, {'total': 42});
    });

    test('two writes to one key land in the order they were made', () async {
      final gate = Completer<void>();
      final slow = ResponseCache(dir, cipher: _GatedCipher(gate.future));

      final first = slow.store('k', {'n': 1});
      final second = slow.store('k', {'n': 2});
      gate.complete();
      await Future.wait([first, second]);

      expect((await slow.read('k'))?.body, {'n': 2});
    });

    test('eviction trims below the cap, so it is not paid on every write '
        'from then on', () async {
      final capped = ResponseCache(dir, maxEntries: 10);
      for (var i = 0; i < 11; i++) {
        await capped.store('key$i', {'n': i});
      }

      expect(dir.listSync().length, 9);
      expect(await capped.read('key10'), isNotNull);
    });
  });
}

/// Seals in the clear, but only once [gate] completes -- a stand-in for an
/// encryption that is still running when something else happens.
class _GatedCipher implements AtRestCipher {
  _GatedCipher(this.gate);

  final Future<void> gate;

  @override
  Future<String> seal(String plaintext) async {
    await gate;
    return AtRestCipher.none.seal(plaintext);
  }

  @override
  Future<OpenedText> open(String stored) => AtRestCipher.none.open(stored);
}
