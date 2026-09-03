import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:cuentimobile/core/theme/app_theme.dart';
import 'package:cuentimobile/core/widgets/feedback_snack.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// A page with a button that runs [action] through [reportingFailure].
  Future<void> pumpAction(
    WidgetTester tester,
    Future<void> Function() action, {
    Locale? locale,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        theme: AppTheme.light(),
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => reportingFailure(context, action),
              child: const Text('go'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
  }

  testWidgets('says nothing when the action succeeds', (tester) async {
    await pumpAction(tester, () async {});

    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('reports an ApiException in the reader’s language', (
    tester,
  ) async {
    await pumpAction(
      tester,
      () async => throw const NetworkException('Cannot connect to server'),
      locale: const Locale('de'),
    );

    expect(find.byType(SnackBar), findsOneWidget);
    expect(
      find.textContaining('Server'),
      findsWidgets,
      reason: 'the localized message, not the English literal',
    );
  });

  testWidgets('turns anything else into the generic message, keeping '
      'developer text off the screen', (tester) async {
    await pumpAction(
      tester,
      () async => throw Exception('SocketException: reset by peer'),
    );

    expect(find.text('An error occurred'), findsOneWidget);
    expect(find.textContaining('SocketException'), findsNothing);
  });

  testWidgets('an unexpected failure does not escape to crash the frame', (
    tester,
  ) async {
    await pumpAction(tester, () async => throw Exception('boom'));

    expect(tester.takeException(), isNull);
  });

  testWidgets('returns whether the action got through, so a caller can '
      'skip its follow-up', (tester) async {
    final outcomes = <bool>[];
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        theme: AppTheme.light(),
        home: Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                ElevatedButton(
                  onPressed: () async => outcomes.add(
                    await reportingFailure(context, () async {}),
                  ),
                  child: const Text('ok'),
                ),
                ElevatedButton(
                  onPressed: () async => outcomes.add(
                    await reportingFailure(
                      context,
                      () async => throw Exception('boom'),
                    ),
                  ),
                  child: const Text('bad'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('ok'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('bad'));
    await tester.pumpAndSettle();

    expect(outcomes, [true, false]);
  });
}
