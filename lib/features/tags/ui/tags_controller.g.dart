// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tags_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TagsController)
final tagsControllerProvider = TagsControllerProvider._();

final class TagsControllerProvider
    extends $AsyncNotifierProvider<TagsController, List<Tag>> {
  TagsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tagsControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tagsControllerHash();

  @$internal
  @override
  TagsController create() => TagsController();
}

String _$tagsControllerHash() => r'a28e83b7b9cc7a30f16a7a8ce04945175c9f9519';

abstract class _$TagsController extends $AsyncNotifier<List<Tag>> {
  FutureOr<List<Tag>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Tag>>, List<Tag>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Tag>>, List<Tag>>,
              AsyncValue<List<Tag>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
