import 'package:cuentimobile/features/statistics/data/statistics_repository.dart';
import 'package:cuentimobile/features/statistics/domain/statistics_data.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'statistics_controller.g.dart';

/// Read-only family provider — the screen's date-range/account pickers
/// become the family args, so changing a picker re-targets the provider
/// instead of triggering a manual reload.
@riverpod
Future<StatisticsData> statistics(
  Ref ref, {
  String? start,
  String? end,
  int? accountId,
}) => ref
    .watch(statisticsRepositoryProvider)
    .load(start: start, end: end, accountId: accountId);
