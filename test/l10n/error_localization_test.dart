import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `ApiException` carries two strings: `message`, which its own docstring
/// calls "English, for logs and tests", and `localizedMessage`, which is
/// what belongs in front of a user.
///
/// Reaching for the wrong one shows English to everybody, and it is an easy
/// mistake because both read naturally at the call site. It has been made
/// three times here already -- on the sign-in screen, and on five feature
/// screens through `commonError(e.message)` -- so it is worth a rule rather
/// than another round of finding them by hand.
///
/// The rule is deliberately blunt: no `.message` on a caught exception
/// anywhere in the UI layers, whatever the surrounding code looks like. A
/// context-sensitive pattern was tried first and could not see a call that
/// `dart format` had wrapped across four lines, which is how these are
/// formatted in practice.
void main() {
  /// The one place the English half is the right half, with the reason.
  const allowed = {
    // Compares against invalidCredentialsMessage to tell a wrong password
    // from an expired session. It tests the value, it does not show it.
    'lib/features/auth/ui/auth_controller.dart',
    // Stores the reason a queued transaction was refused, to show beside it
    // later. `ApiException.fromDio` puts the server's own explanation in
    // `message` -- it never sets `serverMessage`, so `localizedMessage`
    // would replace the server's words with a generic fallback and throw
    // away the only thing that tells the user what to fix. The drain has no
    // BuildContext to localize with anyway. The UI quotes this string
    // inside a translated label, so the frame around it is localized even
    // when the server's own sentence is not.
    // TODO(cuenti): a workaround, not a design choice -- it stands only because
    // ApiException.fromDio never sets serverMessage or statusCode. Fixing
    // that is an app-wide error-display change; this entry comes off the
    // list with it.
    'lib/features/transactions/data/transaction_sync.dart',
  };

  test('no UI code reads the English half of an exception', () {
    final offenders = <String>[];
    final banned = RegExp(r'\b(?:e|error|err|exception)\.message\b');

    for (final dir in ['lib/features', 'lib/screens']) {
      for (final file in Directory(dir).listSync(recursive: true)) {
        if (file is! File || !file.path.endsWith('.dart')) continue;
        if (file.path.endsWith('.g.dart') ||
            file.path.endsWith('.freezed.dart')) {
          continue;
        }
        if (allowed.contains(file.path)) continue;
        final src = file.readAsStringSync();
        for (final match in banned.allMatches(src)) {
          final line =
              '\n'.allMatches(src.substring(0, match.start)).length + 1;
          offenders.add('${file.path}:$line  ${match.group(0)}');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'this is the English text ApiException keeps for its logs. Use '
          'e.localizedMessage(L.of(context)) so the error reaches the user '
          'in the language they chose, or add the file to `allowed` above '
          'with the reason it is testing the value rather than showing it.',
    );
  });
}
