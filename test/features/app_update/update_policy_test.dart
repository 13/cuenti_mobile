import 'package:cuentimobile/features/app_update/domain/update_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 5, 13, 12);
  // Deliberately not the default, so the parameter is exercised.
  const interval = Duration(hours: 2);

  group('shouldCheck', () {
    test('checks when it never has', () {
      expect(
        shouldCheck(lastChecked: null, now: now, interval: interval),
        isTrue,
      );
    });

    test('does not check again straight away', () {
      expect(
        shouldCheck(
          lastChecked: now.subtract(const Duration(minutes: 5)),
          now: now,
          interval: interval,
        ),
        isFalse,
      );
    });

    test('checks once the interval has elapsed', () {
      expect(
        shouldCheck(
          lastChecked: now.subtract(const Duration(hours: 2, seconds: 1)),
          now: now,
          interval: interval,
        ),
        isTrue,
      );
    });

    test(
      'a clock that jumped backwards does not lock checking out forever',
      () {
        expect(
          shouldCheck(
            lastChecked: now.add(const Duration(days: 30)),
            now: now,
          ),
          isTrue,
        );
      },
    );
  });

  group('shouldPrompt', () {
    test('prompts for a newer release', () {
      expect(
        shouldPrompt(currentVersion: '2.1.0', tagName: 'v2.2.0'),
        isTrue,
      );
    });

    test('says nothing when already current', () {
      expect(
        shouldPrompt(currentVersion: '2.1.0', tagName: 'v2.1.0'),
        isFalse,
      );
    });

    test('says nothing for an older tag', () {
      expect(
        shouldPrompt(currentVersion: '2.1.0', tagName: 'v2.0.9'),
        isFalse,
      );
    });

    test('stays quiet about a version the user skipped', () {
      expect(
        shouldPrompt(
          currentVersion: '2.1.0',
          tagName: 'v2.2.0',
          skippedVersion: 'v2.2.0',
        ),
        isFalse,
      );
    });

    test('speaks up again for the version after a skipped one', () {
      expect(
        shouldPrompt(
          currentVersion: '2.1.0',
          tagName: 'v2.3.0',
          skippedVersion: 'v2.2.0',
        ),
        isTrue,
      );
    });

    test('ignores a malformed tag rather than treating it as newer', () {
      expect(
        shouldPrompt(currentVersion: '2.1.0', tagName: 'nightly'),
        isFalse,
      );
    });
  });
}
