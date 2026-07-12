// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payees_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PayeesController)
final payeesControllerProvider = PayeesControllerProvider._();

final class PayeesControllerProvider
    extends $AsyncNotifierProvider<PayeesController, List<Payee>> {
  PayeesControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'payeesControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$payeesControllerHash();

  @$internal
  @override
  PayeesController create() => PayeesController();
}

String _$payeesControllerHash() => r'626717207789e8b74dae014abe42648f766c915b';

abstract class _$PayeesController extends $AsyncNotifier<List<Payee>> {
  FutureOr<List<Payee>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Payee>>, List<Payee>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Payee>>, List<Payee>>,
              AsyncValue<List<Payee>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
