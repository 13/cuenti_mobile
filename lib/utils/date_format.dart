import 'package:flutter/material.dart';

/// Dates written the way the reader's locale writes them.
///
/// Several screens hand-rolled `dd.MM.yyyy`, which is right in German and
/// wrong everywhere else the app is translated. Flutter's own
/// [MaterialLocalizations] already knows each locale's numeric form --
/// `03.09.2026` for German, `09/03/2026` for English -- and it is loaded by
/// the delegates the app registers, so no separate date-symbol setup is
/// needed.
String formatDay(BuildContext context, DateTime date) =>
    MaterialLocalizations.of(context).formatCompactDate(date);

/// [formatDay] plus the clock time, in the reader's 12- or 24-hour
/// preference as the platform reports it.
String formatDayTime(BuildContext context, DateTime date) {
  final l = MaterialLocalizations.of(context);
  final time = l.formatTimeOfDay(
    TimeOfDay.fromDateTime(date),
    alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
  );
  return '${l.formatCompactDate(date)} $time';
}
