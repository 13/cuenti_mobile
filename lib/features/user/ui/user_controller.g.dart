// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Plain read-only providers for the admin panel. Writes go through
/// `userRepositoryProvider` directly and then `ref.invalidate` these to
/// refetch — no local optimistic state to manage, so a class notifier
/// would add nothing.

@ProviderFor(adminUsers)
final adminUsersProvider = AdminUsersProvider._();

/// Plain read-only providers for the admin panel. Writes go through
/// `userRepositoryProvider` directly and then `ref.invalidate` these to
/// refetch — no local optimistic state to manage, so a class notifier
/// would add nothing.

final class AdminUsersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<UserProfile>>,
          List<UserProfile>,
          FutureOr<List<UserProfile>>
        >
    with
        $FutureModifier<List<UserProfile>>,
        $FutureProvider<List<UserProfile>> {
  /// Plain read-only providers for the admin panel. Writes go through
  /// `userRepositoryProvider` directly and then `ref.invalidate` these to
  /// refetch — no local optimistic state to manage, so a class notifier
  /// would add nothing.
  AdminUsersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adminUsersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adminUsersHash();

  @$internal
  @override
  $FutureProviderElement<List<UserProfile>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<UserProfile>> create(Ref ref) {
    return adminUsers(ref);
  }
}

String _$adminUsersHash() => r'48107819b4f462dba9eec1869ad5c53f578c9615';

@ProviderFor(adminSettings)
final adminSettingsProvider = AdminSettingsProvider._();

final class AdminSettingsProvider
    extends
        $FunctionalProvider<
          AsyncValue<AdminSettings>,
          AdminSettings,
          FutureOr<AdminSettings>
        >
    with $FutureModifier<AdminSettings>, $FutureProvider<AdminSettings> {
  AdminSettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adminSettingsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adminSettingsHash();

  @$internal
  @override
  $FutureProviderElement<AdminSettings> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<AdminSettings> create(Ref ref) {
    return adminSettings(ref);
  }
}

String _$adminSettingsHash() => r'9512bb4ae4de6020248e7d5f780bdc94df3c46e0';
