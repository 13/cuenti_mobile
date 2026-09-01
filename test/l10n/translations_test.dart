import 'dart:convert';
import 'dart:io';

import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:cuentimobile/l10n/app_localizations_de.dart';
import 'package:cuentimobile/l10n/app_localizations_en.dart';
import 'package:cuentimobile/l10n/app_localizations_it.dart';
import 'package:cuentimobile/l10n/locale_resolution.dart';
import 'package:cuentimobile/utils/number_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _arb(String locale) =>
    jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  final en = _arb('en');
  final keys = en.keys.where((k) => !k.startsWith('@')).toSet();

  group('the German and Italian catalogues keep up with English', () {
    for (final locale in ['de', 'it']) {
      test('$locale translates every key', () {
        final theirs = _arb(locale).keys.where((k) => !k.startsWith('@'));
        expect(
          keys.difference(theirs.toSet()),
          isEmpty,
          reason: 'missing in app_$locale.arb',
        );
      });

      test('$locale has no keys English does not', () {
        final theirs = _arb(locale).keys.where((k) => !k.startsWith('@'));
        expect(theirs.toSet().difference(keys), isEmpty);
      });

      test('$locale leaves nothing as the English string, which would be an '
          'untranslated placeholder hiding in plain sight', () {
        final theirs = _arb(locale);
        // Words that are genuinely identical across these languages.
        const sameEverywhere = {
          'commonEmail',
          'commonPassword',
          'settingsAdministration',
          'navBudgets',
          'dashboardPortfolio',
          'settingsServer',
          'authRegister',
          'aboutSoftwareInfo',
          'commonName',
        };
        final untranslated = [
          for (final k in keys)
            if (!sameEverywhere.contains(k) && theirs[k] == en[k]) k,
        ];
        expect(untranslated, isEmpty);
      });

      test('$locale keeps every placeholder its English string declares', () {
        final theirs = _arb(locale);
        for (final k in keys) {
          final wanted = RegExp(
            r'\{(\w+)\}',
          ).allMatches(en[k] as String).map((m) => m.group(1)).toSet();
          final got = RegExp(
            r'\{(\w+)\}',
          ).allMatches(theirs[k] as String).map((m) => m.group(1)).toSet();
          expect(got, wanted, reason: 'placeholders differ for "$k"');
        }
      });
    }
  });

  group('a widget renders in the chosen language', () {
    Future<void> pumpIn(WidgetTester tester, Locale locale) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          localizationsDelegates: L.localizationsDelegates,
          localeResolutionCallback: resolveAppLocale,
          supportedLocales: L.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: Column(
                children: [
                  Text(L.of(context).commonSave),
                  Text(L.of(context).txEmpty),
                  Text(L.of(context).settingsBiometric),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('English', (tester) async {
      await pumpIn(tester, const Locale('en'));
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('No transactions yet'), findsOneWidget);
      expect(find.text('Biometric Unlock'), findsOneWidget);
    });

    testWidgets('German', (tester) async {
      await pumpIn(tester, const Locale('de'));
      expect(find.text('Speichern'), findsOneWidget);
      expect(find.text('Noch keine Buchungen'), findsOneWidget);
      expect(find.text('Biometrische Entsperrung'), findsOneWidget);
    });

    testWidgets('Italian', (tester) async {
      await pumpIn(tester, const Locale('it'));
      expect(find.text('Salva'), findsOneWidget);
      expect(find.text('Nessun movimento'), findsOneWidget);
      expect(find.text('Sblocco biometrico'), findsOneWidget);
    });

    testWidgets('an unsupported locale falls back to English rather than '
        'showing raw keys', (tester) async {
      await pumpIn(tester, const Locale('pt'));
      expect(find.text('Save'), findsOneWidget);
    });
  });

  group('placeholders survive translation', () {
    test('German keeps both split amounts', () {
      expect(LDe().txSplitSumMismatch('30,00', '40,00'), contains('30,00'));
      expect(LDe().txSplitSumMismatch('30,00', '40,00'), contains('40,00'));
    });

    test('Italian keeps the fuel figures', () {
      final line = LIt().fuelConsumption('500', '8.0');
      expect(line, contains('500'));
      expect(line, contains('8.0'));
    });

    test('English is unchanged', () {
      expect(LEn().commonSave, 'Save');
    });
  });

  test('every locale the picker offers is one the app can render', () {
    for (final tag in ['en-US', 'de-DE', 'it-IT']) {
      final locale = localeOf(tag);
      expect(
        L.supportedLocales.any((l) => l.languageCode == locale.languageCode),
        isTrue,
        reason: '$tag is offered in settings but not supported',
      );
    }
  });

  group('resolveAppLocale', () {
    test('prefers an exact language and region match', () {
      expect(
        resolveAppLocale(const Locale('de', 'DE'), const [
          Locale('de', 'DE'),
          Locale('de'),
        ]),
        const Locale('de', 'DE'),
      );
    });

    test('falls back to the language when the region is unknown', () {
      expect(
        resolveAppLocale(const Locale('de', 'AT'), L.supportedLocales),
        const Locale('de'),
      );
    });

    test('falls back to English, not to whatever sorts first', () {
      expect(
        resolveAppLocale(const Locale('pt'), L.supportedLocales),
        const Locale('en'),
      );
    });

    test('a device with no preference gets English', () {
      expect(resolveAppLocale(null, L.supportedLocales), const Locale('en'));
    });
  });
}
