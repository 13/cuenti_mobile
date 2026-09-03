import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The payment methods the backend speaks are a single vocabulary, and were
/// declared twice: the transactions model carried the real twelve, while the
/// payees screen kept a five-value copy that included CARD and CHECK --
/// values neither the model nor the captured responses in test/fixtures know
/// anything about. Two lists cannot drift if there is only one.
///
/// Same source-reading trick as icon_button_labels_test.
void main() {
  test('kPaymentMethods is declared exactly once', () {
    final declarations = <String>[];

    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      if (file.path.endsWith('.g.dart') ||
          file.path.endsWith('.freezed.dart')) {
        continue;
      }
      if (file.readAsStringSync().contains('const kPaymentMethods')) {
        declarations.add(file.path);
      }
    }

    expect(
      declarations,
      hasLength(1),
      reason: 'declared in: ${declarations.join(', ')}',
    );
  });
}
