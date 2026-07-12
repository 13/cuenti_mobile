// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_views_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SavedViewsController)
final savedViewsControllerProvider = SavedViewsControllerProvider._();

final class SavedViewsControllerProvider
    extends $AsyncNotifierProvider<SavedViewsController, List<SavedView>> {
  SavedViewsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'savedViewsControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$savedViewsControllerHash();

  @$internal
  @override
  SavedViewsController create() => SavedViewsController();
}

String _$savedViewsControllerHash() =>
    r'f2a53c120763c9fa24c426861f1cdf780d4e63a1';

abstract class _$SavedViewsController extends $AsyncNotifier<List<SavedView>> {
  FutureOr<List<SavedView>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<SavedView>>, List<SavedView>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<SavedView>>, List<SavedView>>,
              AsyncValue<List<SavedView>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
