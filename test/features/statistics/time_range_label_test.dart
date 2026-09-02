import 'package:cuentimobile/features/statistics/domain/time_range.dart';
import 'package:cuentimobile/l10n/app_localizations_de.dart';
import 'package:cuentimobile/l10n/app_localizations_en.dart';
import 'package:cuentimobile/l10n/app_localizations_it.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('English reads as it always did', () {
    expect(timeRangeLabel(LEn(), TimeRange.daily), 'Daily');
    expect(timeRangeLabel(LEn(), TimeRange.custom), 'Custom');
  });

  test('every range is translated in German -- the chips used to be the '
      'capitalised enum name, which was English for everyone', () {
    for (final range in TimeRange.values) {
      expect(
        timeRangeLabel(LDe(), range),
        isNot(timeRangeLabel(LEn(), range)),
        reason: '$range is still English in German',
      );
    }
  });

  test('and in Italian', () {
    for (final range in TimeRange.values) {
      expect(
        timeRangeLabel(LIt(), range),
        isNot(timeRangeLabel(LEn(), range)),
        reason: '$range is still English in Italian',
      );
    }
  });
}
