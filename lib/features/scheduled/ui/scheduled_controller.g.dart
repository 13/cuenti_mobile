// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scheduled_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ScheduledController)
final scheduledControllerProvider = ScheduledControllerProvider._();

final class ScheduledControllerProvider
    extends
        $AsyncNotifierProvider<
          ScheduledController,
          List<ScheduledTransaction>
        > {
  ScheduledControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'scheduledControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$scheduledControllerHash();

  @$internal
  @override
  ScheduledController create() => ScheduledController();
}

String _$scheduledControllerHash() =>
    r'f757045d4653df9ac6de4077e90f1407589824ec';

abstract class _$ScheduledController
    extends $AsyncNotifier<List<ScheduledTransaction>> {
  FutureOr<List<ScheduledTransaction>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<ScheduledTransaction>>,
              List<ScheduledTransaction>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<ScheduledTransaction>>,
                List<ScheduledTransaction>
              >,
              AsyncValue<List<ScheduledTransaction>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
