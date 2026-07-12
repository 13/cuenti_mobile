// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'accounts_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AccountsController)
final accountsControllerProvider = AccountsControllerProvider._();

final class AccountsControllerProvider
    extends $AsyncNotifierProvider<AccountsController, List<Account>> {
  AccountsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'accountsControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$accountsControllerHash();

  @$internal
  @override
  AccountsController create() => AccountsController();
}

String _$accountsControllerHash() =>
    r'49e725c4ae9cc1c1c9ffaf92c88a21b66854153e';

abstract class _$AccountsController extends $AsyncNotifier<List<Account>> {
  FutureOr<List<Account>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Account>>, List<Account>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Account>>, List<Account>>,
              AsyncValue<List<Account>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
