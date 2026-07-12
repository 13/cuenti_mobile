// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AuditController)
final auditControllerProvider = AuditControllerFamily._();

final class AuditControllerProvider
    extends $AsyncNotifierProvider<AuditController, AuditState> {
  AuditControllerProvider._({
    required AuditControllerFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'auditControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$auditControllerHash();

  @override
  String toString() {
    return r'auditControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  AuditController create() => AuditController();

  @override
  bool operator ==(Object other) {
    return other is AuditControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$auditControllerHash() => r'd558a1fa756d4be46bbf8aa7d0835135df10ab00';

final class AuditControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          AuditController,
          AsyncValue<AuditState>,
          AuditState,
          FutureOr<AuditState>,
          String?
        > {
  AuditControllerFamily._()
    : super(
        retry: null,
        name: r'auditControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  AuditControllerProvider call({String? filter}) =>
      AuditControllerProvider._(argument: filter, from: this);

  @override
  String toString() => r'auditControllerProvider';
}

abstract class _$AuditController extends $AsyncNotifier<AuditState> {
  late final _$args = ref.$arg as String?;
  String? get filter => _$args;

  FutureOr<AuditState> build({String? filter});
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<AuditState>, AuditState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<AuditState>, AuditState>,
              AsyncValue<AuditState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(filter: _$args));
  }
}
