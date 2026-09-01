import 'dart:io';

/// Fails the build when line coverage drops below a floor.
///
/// Generated sources are excluded: freezed and riverpod output, and the
/// localisation catalogues, whose coverage measures how many strings a test
/// happened to render rather than anything about the code.
///
/// Usage: dart run tool/check_coverage.dart [minimum-percent]
const _generated = [
  '.g.dart',
  '.freezed.dart',
  'lib/l10n/app_localizations',
];

void main(List<String> args) {
  final minimum = args.isEmpty ? 60.0 : double.parse(args.first);
  final file = File('coverage/lcov.info');
  if (!file.existsSync()) {
    stderr.writeln('coverage/lcov.info not found; run flutter test --coverage');
    exit(1);
  }

  var found = 0;
  var hit = 0;
  final worst = <({double ratio, int hit, int found, String path})>[];
  String? path;
  var fileFound = 0;
  var fileHit = 0;

  for (final line in file.readAsLinesSync()) {
    if (line.startsWith('SF:')) {
      path = line.substring(3);
      fileFound = 0;
      fileHit = 0;
    } else if (line.startsWith('LF:')) {
      fileFound = int.parse(line.substring(3));
    } else if (line.startsWith('LH:')) {
      fileHit = int.parse(line.substring(3));
    } else if (line == 'end_of_record' && path != null) {
      final current = path;
      final isGenerated = _generated.any(current.contains);
      if (!isGenerated && fileFound > 0) {
        found += fileFound;
        hit += fileHit;
        worst.add((
          ratio: fileHit / fileFound,
          hit: fileHit,
          found: fileFound,
          path: current,
        ));
      }
      path = null;
    }
  }

  if (found == 0) {
    stderr.writeln('no coverage data for first-party code');
    exit(1);
  }

  final percent = hit / found * 100;
  stdout.writeln(
    'line coverage (excluding generated): '
    '$hit/$found = ${percent.toStringAsFixed(1)}%',
  );

  worst.sort((a, b) => a.ratio.compareTo(b.ratio));
  stdout.writeln('\nleast covered:');
  for (final entry in worst.take(10)) {
    final pct = (entry.ratio * 100).toStringAsFixed(1).padLeft(5);
    stdout.writeln('  $pct%  ${entry.hit}/${entry.found}  ${entry.path}');
  }

  if (percent < minimum) {
    stderr.writeln(
      '\ncoverage ${percent.toStringAsFixed(1)}% is below the '
      '${minimum.toStringAsFixed(0)}% floor',
    );
    exit(1);
  }
}
