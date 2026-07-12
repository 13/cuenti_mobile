import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/vehicles_repository.dart';
import '../domain/vehicle_report.dart';

part 'vehicles_controller.g.dart';

/// Read-only family provider — the screen's category/date-range selection
/// becomes the family arg, so changing either re-targets the provider
/// instead of triggering a manual reload.
@riverpod
Future<VehicleReport> vehicleReport(
  Ref ref, {
  required int categoryId,
  DateTime? start,
  DateTime? end,
}) =>
    ref.watch(vehiclesRepositoryProvider).getReport(
          categoryId: categoryId,
          start: start,
          end: end,
        );
