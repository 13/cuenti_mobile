import 'package:cuentimobile/features/app_update/domain/version_compare.dart';

/// How long the automatic check waits before asking GitHub again.
const updateCheckInterval = Duration(hours: 6);

/// Whether enough time has passed to ask GitHub for the latest release.
///
/// A [lastChecked] in the future means the device clock moved backwards; that
/// counts as due rather than locking checking out until the clock catches up.
bool shouldCheck({
  required DateTime? lastChecked,
  required DateTime now,
  Duration interval = updateCheckInterval,
}) {
  if (lastChecked == null) return true;
  if (lastChecked.isAfter(now)) return true;
  return now.difference(lastChecked) > interval;
}

/// Whether [tagName] is worth interrupting the user for: newer than what is
/// installed, and not a version they have already chosen to skip.
bool shouldPrompt({
  required String currentVersion,
  required String tagName,
  String? skippedVersion,
}) {
  if (skippedVersion != null && skippedVersion == tagName) return false;
  return isNewerVersion(currentVersion, tagName);
}
