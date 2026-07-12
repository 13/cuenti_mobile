// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transactions_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TransactionsController)
final transactionsControllerProvider = TransactionsControllerFamily._();

final class TransactionsControllerProvider
    extends $AsyncNotifierProvider<TransactionsController, TransactionsState> {
  TransactionsControllerProvider._({
    required TransactionsControllerFamily super.from,
    required int? super.argument,
  }) : super(
         retry: null,
         name: r'transactionsControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$transactionsControllerHash();

  @override
  String toString() {
    return r'transactionsControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  TransactionsController create() => TransactionsController();

  @override
  bool operator ==(Object other) {
    return other is TransactionsControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$transactionsControllerHash() =>
    r'c878e68d6ce31b8ad8a047bfbaa755d94d6ef0f0';

final class TransactionsControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          TransactionsController,
          AsyncValue<TransactionsState>,
          TransactionsState,
          FutureOr<TransactionsState>,
          int?
        > {
  TransactionsControllerFamily._()
    : super(
        retry: null,
        name: r'transactionsControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TransactionsControllerProvider call({int? accountId}) =>
      TransactionsControllerProvider._(argument: accountId, from: this);

  @override
  String toString() => r'transactionsControllerProvider';
}

abstract class _$TransactionsController
    extends $AsyncNotifier<TransactionsState> {
  late final _$args = ref.$arg as int?;
  int? get accountId => _$args;

  FutureOr<TransactionsState> build({int? accountId});
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<TransactionsState>, TransactionsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<TransactionsState>, TransactionsState>,
              AsyncValue<TransactionsState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(accountId: _$args));
  }
}
