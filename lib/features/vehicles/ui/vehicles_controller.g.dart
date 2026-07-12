// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vehicles_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Read-only family provider — the screen's category/date-range selection
/// becomes the family arg, so changing either re-targets the provider
/// instead of triggering a manual reload.

@ProviderFor(vehicleReport)
final vehicleReportProvider = VehicleReportFamily._();

/// Read-only family provider — the screen's category/date-range selection
/// becomes the family arg, so changing either re-targets the provider
/// instead of triggering a manual reload.

final class VehicleReportProvider
    extends
        $FunctionalProvider<
          AsyncValue<VehicleReport>,
          VehicleReport,
          FutureOr<VehicleReport>
        >
    with $FutureModifier<VehicleReport>, $FutureProvider<VehicleReport> {
  /// Read-only family provider — the screen's category/date-range selection
  /// becomes the family arg, so changing either re-targets the provider
  /// instead of triggering a manual reload.
  VehicleReportProvider._({
    required VehicleReportFamily super.from,
    required ({int categoryId, DateTime? start, DateTime? end}) super.argument,
  }) : super(
         retry: null,
         name: r'vehicleReportProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$vehicleReportHash();

  @override
  String toString() {
    return r'vehicleReportProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<VehicleReport> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<VehicleReport> create(Ref ref) {
    final argument =
        this.argument as ({int categoryId, DateTime? start, DateTime? end});
    return vehicleReport(
      ref,
      categoryId: argument.categoryId,
      start: argument.start,
      end: argument.end,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is VehicleReportProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$vehicleReportHash() => r'b1f23ad11799c4440970711be632fdcf0c633210';

/// Read-only family provider — the screen's category/date-range selection
/// becomes the family arg, so changing either re-targets the provider
/// instead of triggering a manual reload.

final class VehicleReportFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<VehicleReport>,
          ({int categoryId, DateTime? start, DateTime? end})
        > {
  VehicleReportFamily._()
    : super(
        retry: null,
        name: r'vehicleReportProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Read-only family provider — the screen's category/date-range selection
  /// becomes the family arg, so changing either re-targets the provider
  /// instead of triggering a manual reload.

  VehicleReportProvider call({
    required int categoryId,
    DateTime? start,
    DateTime? end,
  }) => VehicleReportProvider._(
    argument: (categoryId: categoryId, start: start, end: end),
    from: this,
  );

  @override
  String toString() => r'vehicleReportProvider';
}
