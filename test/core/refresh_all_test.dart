import 'dart:io';

import 'package:cuentimobile/core/theme/app_theme.dart';
import 'package:cuentimobile/core/widgets/refresh_all.dart';
import 'package:cuentimobile/features/tags/data/tags_repository.dart';
import 'package:cuentimobile/features/tags/domain/tag.dart';
import 'package:cuentimobile/features/tags/ui/tags_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockTagsRepository extends Mock implements TagsRepository {}

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
    // Derived from scheduledControllerProvider, which is on the list.
    // Invalidating it as well would recompute a count whose input has not
    // been refetched yet.
    'overdueScheduledCountProvider',
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

  /// The source check above proves the list names every provider. It cannot
  /// prove the call itself works: nothing in the suite ran it, so a provider
  /// renamed out from under it, or one that throws when invalidated, would
  /// have gone unnoticed.
  testWidgets('invalidating actually refetches', (tester) async {
    final repo = _MockTagsRepository();
    var calls = 0;
    when(repo.getAll).thenAnswer((_) async {
      calls++;
      return const [Tag(id: 1, name: 'Urlaub')];
    });

    late WidgetRef captured;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [tagsRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Consumer(
            builder: (context, ref, _) {
              captured = ref;
              final tags = ref.watch(tagsControllerProvider).value ?? [];
              return Text('${tags.length}', textDirection: TextDirection.ltr);
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(calls, 1);

    invalidateAllData(captured);
    await tester.pumpAndSettle();

    expect(calls, 2, reason: 'the watched provider refetched');
    expect(tester.takeException(), isNull);
  });
}
