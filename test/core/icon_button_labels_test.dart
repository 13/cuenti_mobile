import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every icon-only button needs a tooltip: it is the label a screen reader
/// announces, and without one the user hears "button" with no hint of what
/// it does -- including on the destructive ones.
void main() {
  test('every IconButton in lib carries a tooltip', () {
    final offenders = <String>[];

    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      if (file.path.endsWith('.g.dart') ||
          file.path.endsWith('.freezed.dart')) {
        continue;
      }
      final source = file.readAsStringSync();
      for (final match in 'IconButton('.allMatches(source)) {
        var depth = 0;
        var i = match.end - 1;
        while (i < source.length) {
          if (source[i] == '(') depth++;
          if (source[i] == ')') {
            depth--;
            if (depth == 0) break;
          }
          i++;
        }
        if (!source.substring(match.end, i).contains('tooltip:')) {
          final line = '\n'.allMatches(source.substring(0, match.start)).length;
          offenders.add('${file.path}:${line + 1}');
        }
      }
    }

    expect(offenders, isEmpty, reason: 'IconButtons without a tooltip');
  });
}
