import 'package:cuentimobile/core/storage/secure_storage.dart';
import 'package:cuentimobile/features/app_update/data/update_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryStorage extends SecureStorage {
  _MemoryStorage() : super();
  final Map<String, String> data = {};
  @override
  Future<String?> read(String key) async => data[key];
  @override
  Future<void> write(String key, String value) async => data[key] = value;
  @override
  Future<void> delete(String key) async => data.remove(key);
}

void main() {
  late _MemoryStorage storage;
  late UpdatePreferences prefs;

  setUp(() {
    storage = _MemoryStorage();
    prefs = UpdatePreferences(storage);
  });

  group('automatic checking', () {
    test('is on for a fresh install', () async {
      expect(await prefs.autoCheckEnabled(), isTrue);
    });

    test('can be turned off and stays off', () async {
      await prefs.setAutoCheckEnabled(enabled: false);

      expect(await prefs.autoCheckEnabled(), isFalse);
      expect(await UpdatePreferences(storage).autoCheckEnabled(), isFalse);
    });

    test('can be turned back on', () async {
      await prefs.setAutoCheckEnabled(enabled: false);
      await prefs.setAutoCheckEnabled(enabled: true);

      expect(await prefs.autoCheckEnabled(), isTrue);
    });

    test('an unreadable value leaves checking on rather than silently off, '
        'since off is the state that hides security updates', () async {
      storage.data['update_auto_check'] = 'perhaps';

      expect(await prefs.autoCheckEnabled(), isTrue);
    });
  });

  group('last checked', () {
    test('is null before the first check', () async {
      expect(await prefs.lastChecked(), isNull);
    });

    test('round-trips the timestamp', () async {
      final when = DateTime(2026, 5, 13, 12);
      await prefs.setLastChecked(when);

      expect(await prefs.lastChecked(), when);
    });

    test('a corrupt timestamp reads as never checked, so checking resumes '
        'rather than throwing on every launch', () async {
      storage.data['update_last_checked'] = 'not a date';

      expect(await prefs.lastChecked(), isNull);
    });
  });

  group('skipped version', () {
    test('is null until one is skipped', () async {
      expect(await prefs.skippedVersion(), isNull);
    });

    test('remembers the skipped tag', () async {
      await prefs.skipVersion('v2.2.0');

      expect(await prefs.skippedVersion(), 'v2.2.0');
    });

    test('skipping a newer one replaces the old skip', () async {
      await prefs.skipVersion('v2.2.0');
      await prefs.skipVersion('v2.3.0');

      expect(await prefs.skippedVersion(), 'v2.3.0');
    });
  });
}
