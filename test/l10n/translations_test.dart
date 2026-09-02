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
          // 'Tags' is the same word in German; the other two are a
          // label plus a value and a brand line.
          'navTags',
          'authServerLine',
          'aboutCopyright',
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

  group('no English is left where a literal could hide', () {
    /// Walks the UI source for string literals sitting in positions the eye
    /// reads -- Text(), labels, hints, tooltips, confirm messages. This is
    /// the check that would have caught the entire drawer and every AppBar
    /// title staying English after the first translation pass.
    test('no user-visible literal remains in lib/features or lib/screens', () {
      const allowed = {
        // Brand name, deliberately the same in every language.
        'Cuenti',
        // An example address, not copy.
        'http://192.168.1.100:8080',
      };
      final offenders = <String>[];
      // Positional constructors that render their first argument are
      // included by name: SectionHeader('Monthly Cash Flow') reads as copy
      // on screen but is no Text() and no named argument, which is how
      // three section titles and a summary card stayed English through a
      // whole translation pass.
      final pattern = RegExp(
        r'(?:Text\(\s*|labelText:\s*|hintText:\s*|tooltip:\s*|'
        r'message:\s*|title:\s*|actionLabel:\s*|localizedReason:\s*|'
        r'SectionHeader\(\s*|EmptyState\(\s*|_metric\([^,]+,\s*|'
        r'_legendChip\(\s*)'
        r"'([^'\\\n]{4,})'",
      );
      for (final dir in ['lib/features', 'lib/screens']) {
        for (final file in Directory(dir).listSync(recursive: true)) {
          if (file is! File || !file.path.endsWith('.dart')) continue;
          if (file.path.endsWith('.g.dart') ||
              file.path.endsWith('.freezed.dart')) {
            continue;
          }
          final src = file.readAsStringSync();
          for (final m in pattern.allMatches(src)) {
            final text = m.group(1)!;
            if (allowed.contains(text)) continue;
            // An interpolated string is not automatically safe: it is only
            // safe if the parts around the ${...} are punctuation. Skipping
            // anything containing a '$' is what let "Symbol: ... Decimals:
            // ..." and "last: ..." sit on screen in English, and hid the
            // certificate sheet's whole body before them. Strip the
            // interpolations and judge what is left.
            final literal = text
                .replaceAll(RegExp(r'\$\{[^}]*\}'), '')
                .replaceAll(RegExp(r'\$\w+'), '')
                // A literal containing a quote of its own ("?? ''", or
                // "join(', ')") ends the match early, leaving half an
                // interpolation behind. That tail is code, not copy.
                .replaceAll(RegExp(r'\$\{.*'), '');
            if (!RegExp('[a-z]{3}').hasMatch(literal)) continue;
            if (RegExp(r'^[a-z][a-zA-Z]*$').hasMatch(text)) continue;
            final line = '\n'.allMatches(src.substring(0, m.start)).length + 1;
            offenders.add('${file.path}:$line  "$text"');
          }
        }
      }
      expect(offenders, isEmpty, reason: 'untranslated user-visible strings');
    });
  });

  group('counted strings agree with their number', () {
    test('English uses the singular for one', () {
      expect(LEn().statsTransactionsInPeriod(1), '1 transaction in period');
    });

    test('English uses the plural for many', () {
      expect(LEn().statsTransactionsInPeriod(7), '7 transactions in period');
    });

    test('English has a phrase for none, rather than "0 transactions"', () {
      expect(LEn().statsTransactionsInPeriod(0), 'No transactions in period');
    });

    test('German agrees too', () {
      expect(LDe().statsTransactionsInPeriod(1), '1 Buchung im Zeitraum');
      expect(LDe().statsTransactionsInPeriod(7), '7 Buchungen im Zeitraum');
    });

    test('Italian agrees too', () {
      expect(LIt().statsTransactionsInPeriod(1), '1 movimento nel periodo');
      expect(LIt().statsTransactionsInPeriod(7), '7 movimenti nel periodo');
    });
  });
}
