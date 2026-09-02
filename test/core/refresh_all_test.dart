import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `invalidateAllData` is a hand-written list of providers. Nothing links it
/// to the providers that exist, so adding a feature and forgetting this file
/// leaves "refresh all" quietly not refreshing that screen -- a bug with no
/// error, no crash, and nothing on screen to notice.
///
/// Same trick as `icon_button_labels_test.dart`: read the source and hold it
/// to the rule.
void main() {
  /// Providers that belong to a feature's data but are deliberately absent,
  /// each with the reason. Anything not listed here has to be in the list.
  const deliberatelyOmitted = {
    // Session state, not server data: invalidating it would sign the user
    // out every time they pulled to refresh.
    'authControllerProvider',
    // Self-invalidates whenever its sheet opens, so there is no stale cache
    // to clear. Documented in refresh_all.dart too.
    'savedViewsControllerProvider',
    // Admin-only, and the panel invalidates them itself after every write.
    'adminUsersProvider',
    'adminSettingsProvider',
  };

  /// `xControllerProvider` for `class XController`, `fooProvider` for a
  /// `foo(Ref ref)` function provider.
  Set<String> providersDeclaredIn(String source) {
    final found = <String>{};
    final annotation = RegExp(r'@(?:riverpod\b|Riverpod\([^)]*\))');
    for (final match in annotation.allMatches(source)) {
      final after = source.substring(
        match.end,
        (match.end + 240).clamp(0, source.length),
      );
      final asClass = RegExp(r'^\s*class\s+(\w+)').firstMatch(after);
      if (asClass != null) {
        final name = asClass.group(1)!;
        found.add('${name[0].toLowerCase()}${name.substring(1)}Provider');
        continue;
      }
      final asFunction = RegExp(r'^[\s\S]*?\b(\w+)\s*\(').firstMatch(after);
      if (asFunction != null) found.add('${asFunction.group(1)}Provider');
    }
    return found;
  }

  test('every feature provider is either refreshed or deliberately not', () {
    final refreshAll = File(
      'lib/core/widgets/refresh_all.dart',
    ).readAsStringSync();

    final missing = <String>[];
    for (final file in Directory('lib/features').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('_controller.dart')) continue;
      for (final provider in providersDeclaredIn(file.readAsStringSync())) {
        if (deliberatelyOmitted.contains(provider)) continue;
        if (!refreshAll.contains(provider)) {
          missing.add('$provider (${file.path})');
        }
      }
    }

    expect(
      missing,
      isEmpty,
      reason:
          'these providers are never invalidated by invalidateAllData, so '
          'a refresh leaves their screens on stale data. Add them to '
          'refresh_all.dart, or to deliberatelyOmitted here with the reason.',
    );
  });

  test('the scan finds the providers it is meant to, so an empty result '
      'cannot pass this file by accident', () {
    final accounts = File(
      'lib/features/accounts/ui/accounts_controller.dart',
    ).readAsStringSync();
    final dashboard = File(
      'lib/features/dashboard/ui/dashboard_controller.dart',
    ).readAsStringSync();

    expect(
      providersDeclaredIn(accounts),
      contains('accountsControllerProvider'),
    );
    expect(providersDeclaredIn(dashboard), contains('dashboardProvider'));
  });
}
