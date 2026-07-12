import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/accounts/ui/accounts_controller.dart';
import '../../features/assets/ui/assets_controller.dart';
import '../../features/categories/ui/categories_controller.dart';
import '../../features/currencies/ui/currencies_controller.dart';
import '../../features/dashboard/ui/dashboard_controller.dart';
import '../../features/payees/ui/payees_controller.dart';
import '../../features/scheduled/ui/scheduled_controller.dart';
import '../../features/statistics/ui/statistics_controller.dart';
import '../../features/tags/ui/tags_controller.dart';
import '../../features/transactions/ui/transactions_controller.dart';

/// Refresh-all parity with the old DataProvider.loadAll(): every data
/// provider is invalidated so the next watch re-fetches. These are
/// autoDispose providers — invalidating one with no current listener is a
/// cheap no-op, it just stays dormant.
///
/// Shared by the shell's refresh button and the settings import flow (a
/// successful import replaces server-side data wholesale, so every cached
/// provider is stale afterwards too).
void invalidateAllData(WidgetRef ref) {
  ref
    ..invalidate(accountsControllerProvider)
    ..invalidate(categoriesControllerProvider)
    ..invalidate(payeesControllerProvider)
    ..invalidate(tagsControllerProvider)
    ..invalidate(currenciesControllerProvider)
    ..invalidate(assetsControllerProvider)
    ..invalidate(scheduledControllerProvider)
    ..invalidate(transactionsControllerProvider)
    ..invalidate(dashboardProvider)
    ..invalidate(statisticsProvider);
}
