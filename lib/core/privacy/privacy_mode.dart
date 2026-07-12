import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../api/dio_provider.dart';

part 'privacy_mode.g.dart';

const _privacyModeKey = 'privacy_mode';

/// App-wide "hide amounts" toggle. Starts `false` (amounts visible) and
/// asynchronously loads the persisted value on first build, mirroring
/// AuthController's biometric-flag pattern (secure storage, string
/// 'true'/'false', keepAlive so the toggle survives navigation).
@Riverpod(keepAlive: true)
class PrivacyMode extends _$PrivacyMode {
  @override
  bool build() {
    Future.microtask(_load);
    return false;
  }

  Future<void> _load() async {
    final stored = await ref.read(secureStorageProvider).read(_privacyModeKey);
    state = stored == 'true';
  }

  Future<void> toggle() async {
    state = !state;
    await ref.read(secureStorageProvider).write(_privacyModeKey, state.toString());
  }
}
