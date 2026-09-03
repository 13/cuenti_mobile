import 'package:cuentimobile/core/theme/app_theme.dart';
import 'package:cuentimobile/features/user/ui/about_screen.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Cuenti',
      packageName: 'app.cuenti',
      version: '2.5.0',
      buildNumber: '42',
      buildSignature: '',
    );
  });

  Future<void> pumpScreen(WidgetTester tester, {Locale? locale}) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          theme: AppTheme.light(),
          home: const AboutScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the version the build reports', (tester) async {
    await pumpScreen(tester);

    expect(find.text('2.5.0'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
  });

  testWidgets('renders before the package info has arrived, rather than '
      'showing nothing', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          theme: AppTheme.light(),
          home: const AboutScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(AboutScreen), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('the build labels are translated, not left in English', (
    tester,
  ) async {
    await pumpScreen(tester, locale: const Locale('de'));

    expect(find.text('Build-Nummer'), findsOneWidget);
    expect(find.text('Build Number'), findsNothing);
  });

  testWidgets('offers to check for updates and to visit the website', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.text('Check for updates'), findsOneWidget);
    expect(find.text('Visit Website'), findsOneWidget);
  });
}
