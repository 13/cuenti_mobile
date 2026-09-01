import 'package:flutter/material.dart';

/// The period the statistics screen reports on.
enum TimeRange { daily, weekly, monthly, yearly, custom }

/// The concrete window [range] stands for at [now].
///
/// Every preset ends at [now] rather than at the end of the period, so the
/// figures include what has happened so far today. [custom] supplies the
/// user's picked window; without one, custom behaves as this month.
DateTimeRange statisticsRange(
  TimeRange range, {
  required DateTime now,
  DateTimeRange? custom,
}) {
  final today = DateTime(now.year, now.month, now.day);
  return switch (range) {
    TimeRange.daily => DateTimeRange(start: today, end: now),
    // weekday is 1 on Monday, so this lands on Monday of the current week
    // and stays put when today already is one.
    TimeRange.weekly => DateTimeRange(
      start: today.subtract(Duration(days: now.weekday - 1)),
      end: now,
    ),
    TimeRange.monthly => DateTimeRange(
      start: DateTime(now.year, now.month),
      end: now,
    ),
    TimeRange.yearly => DateTimeRange(start: DateTime(now.year), end: now),
    TimeRange.custom =>
      custom ?? DateTimeRange(start: DateTime(now.year, now.month), end: now),
  };
}
