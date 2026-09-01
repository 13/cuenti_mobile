import 'package:cuentimobile/core/api/dio_provider.dart';
import 'package:cuentimobile/core/storage/secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _autoCheckKey = 'update_auto_check';
const _lastCheckedKey = 'update_last_checked';
const _skippedVersionKey = 'update_skipped_version';

final updatePreferencesProvider = Provider<UpdatePreferences>(
  (ref) => UpdatePreferences(ref.watch(secureStorageProvider)),
);

/// What this install remembers about updating itself: whether to look for
/// new releases at all, when it last looked, and which version the user has
/// waved away.
///
/// Deliberately local rather than on the user profile with darkMode and the
/// rest. Whether to fetch an APK from GitHub is a property of this Android
/// install, not of the account -- syncing it to the server would push an
/// Android updater setting onto someone using the web app.
///
/// Stored through [SecureStorage] because it is the app's only key-value
/// store and is already faked throughout the tests, not because any of it is
/// secret.
class UpdatePreferences {
  const UpdatePreferences(this._storage);

  final SecureStorage _storage;

  /// Defaults to on, and stays on for any value it cannot read: off is the
  /// state that hides a security release, so it is never arrived at by
  /// accident.
  Future<bool> autoCheckEnabled() async =>
      await _storage.read(_autoCheckKey) != 'false';

  Future<void> setAutoCheckEnabled({required bool enabled}) =>
      _storage.write(_autoCheckKey, enabled.toString());

  /// Null when never checked, and also when the stored value is unreadable
  /// -- treating that as "never" resumes checking instead of throwing on
  /// every launch.
  Future<DateTime?> lastChecked() async {
    final raw = await _storage.read(_lastCheckedKey);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  Future<void> setLastChecked(DateTime when) =>
      _storage.write(_lastCheckedKey, when.toIso8601String());

  Future<String?> skippedVersion() => _storage.read(_skippedVersionKey);

  Future<void> skipVersion(String tagName) =>
      _storage.write(_skippedVersionKey, tagName);
}

/// The automatic-check switch, as state the settings screen can watch.
///
/// Optimistic: the switch flips immediately and the write follows, because
/// a toggle that lags behind the finger feels broken and there is nothing
/// here worth rolling back for.
class AutoUpdateCheck extends AsyncNotifier<bool> {
  @override
  Future<bool> build() =>
      ref.watch(updatePreferencesProvider).autoCheckEnabled();

  Future<void> set({required bool enabled}) async {
    state = AsyncData(enabled);
    await ref
        .read(updatePreferencesProvider)
        .setAutoCheckEnabled(enabled: enabled);
  }
}

final autoUpdateCheckProvider = AsyncNotifierProvider<AutoUpdateCheck, bool>(
  AutoUpdateCheck.new,
);
