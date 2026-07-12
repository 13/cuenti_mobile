// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'privacy_mode.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// App-wide "hide amounts" toggle. Starts `false` (amounts visible) and
/// asynchronously loads the persisted value on first build, mirroring
/// AuthController's biometric-flag pattern (secure storage, string
/// 'true'/'false', keepAlive so the toggle survives navigation).

@ProviderFor(PrivacyMode)
final privacyModeProvider = PrivacyModeProvider._();

/// App-wide "hide amounts" toggle. Starts `false` (amounts visible) and
/// asynchronously loads the persisted value on first build, mirroring
/// AuthController's biometric-flag pattern (secure storage, string
/// 'true'/'false', keepAlive so the toggle survives navigation).
final class PrivacyModeProvider extends $NotifierProvider<PrivacyMode, bool> {
  /// App-wide "hide amounts" toggle. Starts `false` (amounts visible) and
  /// asynchronously loads the persisted value on first build, mirroring
  /// AuthController's biometric-flag pattern (secure storage, string
  /// 'true'/'false', keepAlive so the toggle survives navigation).
  PrivacyModeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'privacyModeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$privacyModeHash();

  @$internal
  @override
  PrivacyMode create() => PrivacyMode();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$privacyModeHash() => r'fb92c6311b8baf3ee04725fa5df9e89f2b62fa52';

/// App-wide "hide amounts" toggle. Starts `false` (amounts visible) and
/// asynchronously loads the persisted value on first build, mirroring
/// AuthController's biometric-flag pattern (secure storage, string
/// 'true'/'false', keepAlive so the toggle survives navigation).

abstract class _$PrivacyMode extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
