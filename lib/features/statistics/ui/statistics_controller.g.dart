// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'statistics_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Read-only family provider — the screen's date-range/account pickers
/// become the family args, so changing a picker re-targets the provider
/// instead of triggering a manual reload.

@ProviderFor(statistics)
final statisticsProvider = StatisticsFamily._();

/// Read-only family provider — the screen's date-range/account pickers
/// become the family args, so changing a picker re-targets the provider
/// instead of triggering a manual reload.

final class StatisticsProvider
    extends
        $FunctionalProvider<
          AsyncValue<StatisticsData>,
          StatisticsData,
          FutureOr<StatisticsData>
        >
    with $FutureModifier<StatisticsData>, $FutureProvider<StatisticsData> {
  /// Read-only family provider — the screen's date-range/account pickers
  /// become the family args, so changing a picker re-targets the provider
  /// instead of triggering a manual reload.
  StatisticsProvider._({
    required StatisticsFamily super.from,
    required ({String? start, String? end, int? accountId}) super.argument,
  }) : super(
         retry: null,
         name: r'statisticsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$statisticsHash();

  @override
  String toString() {
    return r'statisticsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<StatisticsData> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<StatisticsData> create(Ref ref) {
    final argument =
        this.argument as ({String? start, String? end, int? accountId});
    return statistics(
      ref,
      start: argument.start,
      end: argument.end,
      accountId: argument.accountId,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is StatisticsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$statisticsHash() => r'58c98c1cf230293576050c3bddb9ac24381eb580';

/// Read-only family provider — the screen's date-range/account pickers
/// become the family args, so changing a picker re-targets the provider
/// instead of triggering a manual reload.

final class StatisticsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<StatisticsData>,
          ({String? start, String? end, int? accountId})
        > {
  StatisticsFamily._()
    : super(
        retry: null,
        name: r'statisticsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Read-only family provider — the screen's date-range/account pickers
  /// become the family args, so changing a picker re-targets the provider
  /// instead of triggering a manual reload.

  StatisticsProvider call({String? start, String? end, int? accountId}) =>
      StatisticsProvider._(
        argument: (start: start, end: end, accountId: accountId),
        from: this,
      );

  @override
  String toString() => r'statisticsProvider';
}
