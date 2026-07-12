// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assets_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AssetsController)
final assetsControllerProvider = AssetsControllerProvider._();

final class AssetsControllerProvider
    extends $AsyncNotifierProvider<AssetsController, List<Asset>> {
  AssetsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'assetsControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$assetsControllerHash();

  @$internal
  @override
  AssetsController create() => AssetsController();
}

String _$assetsControllerHash() => r'81cd5e7c7336607835bef9d85a385d90128e059b';

abstract class _$AssetsController extends $AsyncNotifier<List<Asset>> {
  FutureOr<List<Asset>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Asset>>, List<Asset>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Asset>>, List<Asset>>,
              AsyncValue<List<Asset>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
