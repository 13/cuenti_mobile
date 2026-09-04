import 'dart:async';

import 'package:cuentimobile/features/transactions/data/transaction_sync.dart';
import 'package:cuentimobile/features/transactions/ui/transactions_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sends what the outbox is holding, and refreshes the list if anything got
/// through.
///
/// Every trigger -- app start, the connection returning, a manual refresh --
/// wants the same two things, and none of them wants to wait for the
/// network. The refresh is the point: a row that has just reached the
/// server goes on saying "Not sent yet" until the list is rebuilt, which is
/// the whole "did it send?" feedback loop. Only when something was actually
/// delivered, so a drain that sent nothing costs no fetch.
///
/// A failure is not the caller's problem -- the entries stay queued and
/// stay marked -- but it must not surface as an unhandled async error
/// either.
void drainOutbox(WidgetRef ref) {
  unawaited(
    ref
        .read(transactionSyncProvider)
        .drain()
        .then((delivered) {
          if (delivered > 0 && ref.context.mounted) {
            ref.invalidate(transactionsControllerProvider);
          }
        })
        .catchError((Object _) {}),
  );
}
