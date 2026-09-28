import 'dart:async';

import 'package:cuentimobile/features/accounts/ui/accounts_controller.dart';
import 'package:cuentimobile/features/dashboard/ui/dashboard_controller.dart';
import 'package:cuentimobile/features/transactions/data/transaction_sync.dart';
import 'package:cuentimobile/features/transactions/ui/transactions_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sends what the outbox is holding, and refreshes what it changed if
/// anything got through.
///
/// Every trigger -- app start, the connection returning, a manual refresh --
/// wants the same two things, and none of them wants to wait for the
/// network. The refresh is the point: a row that has just reached the
/// server goes on saying "Not sent yet" until the list is rebuilt, which is
/// the whole "did it send?" feedback loop. Only when something was actually
/// delivered, so a drain that sent nothing costs no fetch. The balances and
/// the dashboard are rebuilt with it: a sent transaction moved money, and
/// the account list went on showing the figures from before.
///
/// [afterwards], when given, replaces that refresh and runs however the
/// drain ended -- for a caller that means to refetch those screens anyway
/// and would otherwise have them fetched twice.
///
/// A failure is not the caller's problem -- the entries stay queued and
/// stay marked -- but it must not surface as an unhandled async error
/// either.
void drainOutbox(WidgetRef ref, {void Function()? afterwards}) {
  unawaited(
    ref
        .read(transactionSyncProvider)
        .drain()
        .then((delivered) {
          if (afterwards == null && delivered > 0 && ref.context.mounted) {
            ref
              ..invalidate(transactionsControllerProvider)
              ..invalidate(accountsControllerProvider)
              ..invalidate(dashboardProvider);
          }
        })
        .catchError((Object _) {})
        .whenComplete(() {
          if (afterwards != null && ref.context.mounted) afterwards();
        }),
  );
}
