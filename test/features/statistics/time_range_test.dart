import 'package:cuentimobile/features/statistics/domain/time_range.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // A Wednesday, mid-afternoon, mid-month, mid-year.
  final now = DateTime(2026, 5, 13, 15, 30);

  DateTimeRange range(TimeRange r, {DateTimeRange? custom}) =>
      statisticsRange(r, now: now, custom: custom);

  test('daily starts at midnight today', () {
    expect(range(TimeRange.daily).start, DateTime(2026, 5, 13));
  });

  test('weekly starts on Monday of the current week', () {
    expect(range(TimeRange.weekly).start, DateTime(2026, 5, 11));
  });

  test('weekly on a Monday starts that same day, not the week before', () {
    final monday = DateTime(2026, 5, 11, 9);
    expect(
      statisticsRange(TimeRange.weekly, now: monday).start,
      DateTime(2026, 5, 11),
    );
  });

  test('weekly on a Sunday still starts the preceding Monday', () {
    final sunday = DateTime(2026, 5, 17, 9);
    expect(
      statisticsRange(TimeRange.weekly, now: sunday).start,
      DateTime(2026, 5, 11),
    );
  });

  test('monthly starts on the first of the month', () {
    expect(range(TimeRange.monthly).start, DateTime(2026, 5));
  });

  test('yearly starts on the first of January', () {
    expect(range(TimeRange.yearly).start, DateTime(2026));
  });

  test('every preset ends now, so the current period is included', () {
    for (final r in [
      TimeRange.daily,
      TimeRange.weekly,
      TimeRange.monthly,
      TimeRange.yearly,
    ]) {
      expect(range(r).end, now, reason: '$r');
    }
  });

  test('custom uses the picked range', () {
    final picked = DateTimeRange(
      start: DateTime(2025),
      end: DateTime(2025, 6, 30),
    );
    expect(range(TimeRange.custom, custom: picked), picked);
  });

  test('custom with nothing picked yet falls back to this month', () {
    final fallback = range(TimeRange.custom);
    expect(fallback.start, DateTime(2026, 5));
    expect(fallback.end, now);
  });

  test('weekly start drops the time of day, not just the date', () {
    expect(range(TimeRange.weekly).start.hour, 0);
    expect(range(TimeRange.weekly).start.minute, 0);
  });
}
