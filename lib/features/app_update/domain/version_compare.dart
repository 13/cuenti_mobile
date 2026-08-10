/// True iff [tagName] (e.g. 'v2.0.5') is a strictly newer semver than
/// [currentVersion] (e.g. '2.0.4' or '2.0.4+12'). Build numbers are
/// ignored; malformed input is never considered newer.
bool isNewerVersion(String currentVersion, String tagName) {
  List<int>? parse(String s) {
    final m = RegExp(r'^v?(\d+)\.(\d+)\.(\d+)').firstMatch(s.trim());
    if (m == null) return null;
    return [int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!)];
  }

  final current = parse(currentVersion);
  final tag = parse(tagName);
  if (current == null || tag == null) return false;
  for (var i = 0; i < 3; i++) {
    if (tag[i] != current[i]) return tag[i] > current[i];
  }
  return false;
}
