import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The outbox may hold a queue belonging to a different account -- one left
/// behind by a fallback store, or by a session that expired before the next
/// person signed in. `ownedEntries` is what keeps such a queue from being
/// sent and from being shown; a bare `all()` bypasses it.
///
/// The rule is blunt on purpose: no `.all()` on an outbox outside the two
/// files that are allowed one. A reader added later without knowing about
/// ownership fails here rather than quietly leaking somebody's
/// transactions into somebody else's books.
void main() {
  const allowed = {
    // Defines the rule. `ownedEntries`, `entriesIgnoringOwner` and
    // `claimStateOf` are the three sanctioned reads.
    'lib/features/transactions/data/outbox_ownership.dart',
    // The store itself: markRejected reads its own entries to amend one.
    'lib/features/transactions/data/transaction_outbox.dart',
  };

  test('every outbox read goes through outbox_ownership.dart', () {
    final offenders = <String>[];
    // `.all()` is the obvious way past ownership. The other two are the
    // recovery primitives: a sidelined queue is somebody's entries, and
    // `sidelinedQueues()` hands out its directory, so a caller with one
    // can list and parse the files inside without ever touching `.all()`.
    // Reaching them outside the ownership layer skips the gate that
    // decides whether this account may have them back at all.
    final banned = RegExp(r'\.all\(\)|sidelinedQueues\(\)|\.restore\(');

    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      if (file.path.endsWith('.g.dart') ||
          file.path.endsWith('.freezed.dart')) {
        continue;
      }
      if (allowed.contains(file.path)) continue;
      final src = file.readAsStringSync();
      for (final match in banned.allMatches(src)) {
        final line = '\n'.allMatches(src.substring(0, match.start)).length + 1;
        offenders.add('${file.path}:$line');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'read the outbox through ownedEntries() in outbox_ownership.dart, '
          'or add a justified entry to the allow-list above:\n'
          '${offenders.join('\n')}',
    );
  });
}
