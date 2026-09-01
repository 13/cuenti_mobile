import 'package:cuentimobile/core/widgets/offline_banner.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpBanner(
    WidgetTester tester,
    ValueNotifier<bool> stale,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        home: Scaffold(
          body: Column(
            children: [
              OfflineBanner(stale: stale),
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
}
