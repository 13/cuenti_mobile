import 'package:cuentimobile/features/scheduled/domain/scheduled_transaction.dart';

/// Whether [st] is past its due date as of [asOf], and still live enough to
/// be worth saying so.
///
/// Compared by calendar day rather than by instant. The backend sends
/// `nextOccurrence` as a date, which arrives at midnight, so an instant
/// comparison calls everything due today overdue from the moment the day
/// starts -- an alert on the morning something is due, which is exactly when
/// it is not yet late.
///
/// A paused entry is never overdue. It is not going to post, so the only way
/// to clear the alert would be to delete the schedule the user deliberately
/// switched off.
bool isOverdue(ScheduledTransaction st, DateTime asOf) {
  if (!st.enabled) return false;
  final due = DateTime(
    st.nextOccurrence.year,
    st.nextOccurrence.month,
    st.nextOccurrence.day,
  );
  return due.isBefore(DateTime(asOf.year, asOf.month, asOf.day));
}

/// How many of [entries] are overdue as of [asOf].
int countOverdue(List<ScheduledTransaction> entries, DateTime asOf) =>
    entries.where((st) => isOverdue(st, asOf)).length;
