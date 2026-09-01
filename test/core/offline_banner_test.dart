import 'package:cuentimobile/core/widgets/offline_banner.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpBanner(
    WidgetTester tester,
    ValueNotifier<bool> stale, {
    ValueNotifier<DateTime?>? since,
    Locale? locale,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        home: Scaffold(
          body: Column(
            children: [
              OfflineBanner(
                stale: stale,
                since: since ?? ValueNotifier(null),
              ),
              const Text('content'),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('stays out of the way while the server is reachable', (
    tester,
  ) async {
    await pumpBanner(tester, ValueNotifier(false));

    expect(find.textContaining('Offline'), findsNothing);
    expect(find.byType(SizedBox), findsWidgets);
  });

  testWidgets('says the figures are the last known ones when offline', (
    tester,
  ) async {
    await pumpBanner(tester, ValueNotifier(true));

    expect(find.textContaining('Offline'), findsOneWidget);
  });

  testWidgets('appears and disappears as the connection comes and goes', (
    tester,
  ) async {
    final stale = ValueNotifier(false);
    await pumpBanner(tester, stale);

    stale.value = true;
    await tester.pumpAndSettle();
    expect(find.textContaining('Offline'), findsOneWidget);

    stale.value = false;
    await tester.pumpAndSettle();
    expect(find.textContaining('Offline'), findsNothing);
  });

  testWidgets('never hides the content it sits above', (tester) async {
    await pumpBanner(tester, ValueNotifier(true));

    expect(find.text('content'), findsOneWidget);
  });

  testWidgets('says how old the figures are, which is what makes stale '
      'numbers safe to read', (tester) async {
    await pumpBanner(
      tester,
      ValueNotifier(true),
      since: ValueNotifier(DateTime(2026, 5, 13, 14, 32)),
    );

    expect(find.textContaining('14:32'), findsOneWidget);
  });

  testWidgets('falls back to the plain message when the age is unknown', (
    tester,
  ) async {
    await pumpBanner(tester, ValueNotifier(true), since: ValueNotifier(null));

    expect(find.textContaining('Offline'), findsOneWidget);
  });

  testWidgets('the age line is localised too', (tester) async {
    await pumpBanner(
      tester,
      ValueNotifier(true),
      since: ValueNotifier(DateTime(2026, 5, 13, 14, 32)),
      locale: const Locale('de'),
    );

    expect(find.textContaining('Zahlen von'), findsOneWidget);
  });
}
