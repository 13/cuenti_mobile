import 'package:cuentimobile/features/scheduled/domain/overdue.dart';
import 'package:cuentimobile/features/scheduled/domain/scheduled_transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// Mid-afternoon, so a date-only comparison and an instant comparison
  /// disagree about today -- which is the whole point of the rule.
  final now = DateTime(2026, 9, 3, 14, 30);

  ScheduledTransaction due(DateTime date, {bool enabled = true}) =>
      ScheduledTransaction(
        id: 1,
        amount: 10,
        nextOccurrence: date,
        enabled: enabled,
      );

  group('isOverdue', () {
    test('yesterday is overdue', () {
      expect(isOverdue(due(DateTime(2026, 9, 2)), now), isTrue);
    });

    test('today is due, not late -- the backend sends a date, so it arrives '
        'at midnight and every entry due today would otherwise read as '
        'overdue from the moment it opens', () {
      expect(isOverdue(due(DateTime(2026, 9, 3)), now), isFalse);
    });

    test('later today is not overdue either', () {
      expect(isOverdue(due(DateTime(2026, 9, 3, 23, 59)), now), isFalse);
    });

    test('tomorrow is not overdue', () {
      expect(isOverdue(due(DateTime(2026, 9, 4)), now), isFalse);
    });

    test('the boundary is the start of today, not this instant', () {
      final justBeforeMidnight = DateTime(2026, 9, 2, 23, 59, 59);
      expect(isOverdue(due(justBeforeMidnight), now), isTrue);
    });

    test('a paused entry never counts, however far past it is', () {
      expect(
        isOverdue(due(DateTime(2020), enabled: false), now),
        isFalse,
        reason: 'switched off on purpose; nagging about it has no remedy',
      );
    });

    test('a paused entry due today is not overdue either', () {
      expect(
        isOverdue(due(DateTime(2026, 9, 3), enabled: false), now),
        isFalse,
      );
    });
  });

  group('countOverdue', () {
    test('counts only the ones past due and still live', () {
      final entries = [
        due(DateTime(2026, 9)),
        due(DateTime(2026, 9, 2)),
        due(DateTime(2026, 9, 3)),
        due(DateTime(2026, 9, 4)),
        due(DateTime(2020), enabled: false),
      ];

      expect(countOverdue(entries, now), 2);
    });

    test('an empty list counts nothing', () {
      expect(countOverdue(const [], now), 0);
    });
  });
}
