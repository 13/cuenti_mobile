// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'currencies_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CurrenciesController)
final currenciesControllerProvider = CurrenciesControllerProvider._();

final class CurrenciesControllerProvider
    extends $AsyncNotifierProvider<CurrenciesController, List<Currency>> {
  CurrenciesControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currenciesControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currenciesControllerHash();

  @$internal
  @override
  CurrenciesController create() => CurrenciesController();
}

String _$currenciesControllerHash() =>
    r'a53d9ab66bff8d59e116c9c07f24a435c64582fc';

abstract class _$CurrenciesController extends $AsyncNotifier<List<Currency>> {
  FutureOr<List<Currency>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Currency>>, List<Currency>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Currency>>, List<Currency>>,
              AsyncValue<List<Currency>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
