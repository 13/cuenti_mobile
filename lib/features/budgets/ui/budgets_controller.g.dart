// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budgets_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(BudgetsController)
final budgetsControllerProvider = BudgetsControllerProvider._();

final class BudgetsControllerProvider
    extends $AsyncNotifierProvider<BudgetsController, List<BudgetProgress>> {
  BudgetsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'budgetsControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$budgetsControllerHash();

  @$internal
  @override
  BudgetsController create() => BudgetsController();
}

String _$budgetsControllerHash() => r'087347138723f9649b25ab00502ec33a0f36b671';

abstract class _$BudgetsController
    extends $AsyncNotifier<List<BudgetProgress>> {
  FutureOr<List<BudgetProgress>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<BudgetProgress>>, List<BudgetProgress>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<BudgetProgress>>,
                List<BudgetProgress>
              >,
              AsyncValue<List<BudgetProgress>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
