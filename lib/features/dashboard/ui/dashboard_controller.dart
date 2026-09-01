import 'package:cuentimobile/features/dashboard/data/dashboard_repository.dart';
import 'package:cuentimobile/features/dashboard/domain/dashboard_data.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dashboard_controller.g.dart';

/// Plain read-only provider — the dashboard is a snapshot with no
/// mutations from this screen, so a function provider (not a class
/// notifier) is enough. Refresh via `ref.invalidate(dashboardProvider)`.
@riverpod
Future<DashboardData> dashboard(Ref ref) =>
    ref.watch(dashboardRepositoryProvider).load();
