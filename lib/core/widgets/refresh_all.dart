import 'package:cuentimobile/core/api/dio_provider.dart';
import 'package:cuentimobile/features/accounts/ui/accounts_controller.dart';
import 'package:cuentimobile/features/assets/ui/assets_controller.dart';
import 'package:cuentimobile/features/audit/ui/audit_controller.dart';
import 'package:cuentimobile/features/budgets/ui/budgets_controller.dart';
import 'package:cuentimobile/features/categories/ui/categories_controller.dart';
import 'package:cuentimobile/features/currencies/ui/currencies_controller.dart';
import 'package:cuentimobile/features/dashboard/ui/dashboard_controller.dart';
import 'package:cuentimobile/features/forecasts/ui/forecasts_controller.dart';
import 'package:cuentimobile/features/payees/ui/payees_controller.dart';
import 'package:cuentimobile/features/scheduled/ui/scheduled_controller.dart';
import 'package:cuentimobile/features/statistics/ui/statistics_controller.dart';
import 'package:cuentimobile/features/tags/ui/tags_controller.dart';
import 'package:cuentimobile/features/transactions/ui/outbox_drain.dart';
import 'package:cuentimobile/features/transactions/ui/transactions_controller.dart';
import 'package:cuentimobile/features/vehicles/ui/vehicles_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Refresh-all parity with the old DataProvider.loadAll(): every data
/// provider is invalidated so the next watch re-fetches. These are
/// autoDispose providers — invalidating one with no current listener is a
/// cheap no-op, it just stays dormant.
///
/// Shared by the shell's refresh button and the settings import flow (a
/// successful import replaces server-side data wholesale, so every cached
/// provider is stale afterwards too).
///
/// Note: savedViews is intentionally omitted — it self-invalidates whenever
/// its sheet is opened, so there's no stale-cache risk to cover here.
void invalidateAllData(WidgetRef ref) {
  // Asked for fresh figures: ask the server, even if it could not be reached
  // a moment ago.
  ref.read(apiClientProvider).retryNetwork();
  ref
    ..invalidate(categoriesControllerProvider)
    ..invalidate(payeesControllerProvider)
    ..invalidate(tagsControllerProvider)
    ..invalidate(currenciesControllerProvider)
    ..invalidate(assetsControllerProvider)
    ..invalidate(scheduledControllerProvider)
    ..invalidate(vehicleReportProvider)
    ..invalidate(auditControllerProvider);
  // Not a data provider to invalidate -- an action to run. "Refresh"
  // means "get me up to date", and an entry still sitting in the outbox is
  // part of that.
  //
  // Everything a sent transaction changes is refetched once the drain has
  // settled, and only then. Invalidated up front as well, it was fetched
  // twice whenever something was sent: once against the queue as it stood,
  // then again because the drain had delivered -- and without the second,
  // the pending marks would have sat there until a second refresh.
  drainOutbox(
    ref,
    afterwards: () => ref
      ..invalidate(transactionsControllerProvider)
      ..invalidate(accountsControllerProvider)
      ..invalidate(dashboardProvider)
      ..invalidate(statisticsProvider)
      ..invalidate(budgetsControllerProvider)
      ..invalidate(forecastProvider),
  );
}
