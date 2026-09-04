import 'dart:async';

import 'package:cuentimobile/core/theme/cuenti_colors.dart';
import 'package:cuentimobile/core/widgets/amount_text.dart';
import 'package:cuentimobile/core/widgets/confirm_sheet.dart';
import 'package:cuentimobile/features/transactions/data/transaction_outbox.dart';
import 'package:cuentimobile/features/transactions/data/transaction_sync.dart';
import 'package:cuentimobile/features/transactions/domain/pending_transaction.dart';
import 'package:cuentimobile/features/transactions/domain/transaction.dart';
import 'package:cuentimobile/features/transactions/domain/transaction_filter.dart';
import 'package:cuentimobile/features/transactions/ui/transaction_dialog.dart';
import 'package:cuentimobile/features/transactions/ui/transactions_controller.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The pieces the transactions list is built from: a day's worth of rows,
/// the sticky header above them, the stagger that fades them in, and the
/// row itself.
///
/// Split out of transactions_screen.dart, which was the largest file in the
/// app at 718 lines. These four are purely presentational -- none of them
/// touches the screen's state -- so they read and test better on their own.

class DayGroup {
  DayGroup(this.dayKey, this.label, this.entries);
  final String dayKey;
  final String label;
  final List<(Transaction, int)> entries;
}

class DayHeaderDelegate extends SliverPersistentHeaderDelegate {
  const DayHeaderDelegate({required this.label});
  final String label;

  static const double _height = 36;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: _height,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: colorScheme.surfaceContainerHighest,
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: colorScheme.primary,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant DayHeaderDelegate oldDelegate) =>
      oldDelegate.label != label;
}

/// One-shot entrance animation for a list tile: fades and slides in on
/// first build only (per-[State] lifetime), capped at [index] 12 so a long
/// list doesn't produce an ever-growing delay. Skipped entirely when the
/// platform/test requests reduced motion.
class Staggered extends StatefulWidget {
  const Staggered({required this.child, required this.index, super.key});
  final Widget child;
  final int index;

  @override
  State<Staggered> createState() => StaggeredState();
}

class StaggeredState extends State<Staggered> {
  bool _visible = false;
  bool _animate = true;
  bool _scheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_visible || _scheduled) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _animate = false;
      _visible = true;
      return;
    }
    _scheduled = true;
    final cappedIndex = widget.index > 12 ? 12 : widget.index;
    Future.delayed(Duration(milliseconds: cappedIndex * 35), () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_animate) return widget.child;
    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: _visible ? Offset.zero : const Offset(0, 0.08),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

class TransactionTile extends ConsumerWidget {
  const TransactionTile({
    required this.transaction,
    required this.filter,
    required this.onDelete,
    super.key,
  });

  final Transaction transaction;
  final TransactionFilter filter;
  final void Function(int id) onDelete;

  /// Clears the rejection and asks the sync to try again. Reads the outbox
  /// and the sync directly rather than going through the controller: this
  /// row already knows the filter its own list is keyed by, and
  /// invalidating that one provider is all a fresh merge needs.
  ///
  /// Uses `drainAgain` rather than `drain`: a pass already in flight read
  /// the outbox before the rejection was cleared and would skip this
  /// entry.
  Future<void> _retry(WidgetRef ref, PendingTransaction entry) async {
    await ref
        .read(transactionOutboxProvider)
        .replace(entry.copyWith(rejection: null));
    try {
      await ref.read(transactionSyncProvider).drainAgain();
    } on Exception catch (_) {
      // Still queued and still shown as unsent, which is the truth. The
      // list is rebuilt either way: the rejection has been cleared, and
      // leaving the old reason on screen would be a lie about it.
    }
    ref.invalidate(transactionsControllerProvider(filter: filter));
  }

  Future<void> _discard(WidgetRef ref, PendingTransaction entry) async {
    await ref.read(transactionOutboxProvider).remove(entry.localId);
    ref.invalidate(transactionsControllerProvider(filter: filter));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref
        .watch(transactionsControllerProvider(filter: filter))
        .value;
    final pending = state?.pending ?? const <PendingTransaction>[];

    // For a transaction the server has issued an id for, that id is the
    // stable link to its pending entry. An entry that has never reached the
    // server has no id to match on -- mergePending puts the pending entry's
    // own Transaction object into the list verbatim, so identity is the
    // primary link for those. But nothing enforces that the object stays
    // the same one all the way to this row (a future .map, a copyWith, a
    // separate re-read of pending) -- so freezed's field-for-field equality
    // is a fallback, checked only across the whole list, and only once no
    // entry matches by identity. Trying identity first everywhere (rather
    // than "identical OR equal" per entry) matters when two unsent creates
    // happen to be field-for-field equal (two identical purchases logged
    // the same day): an equal-first search could hand this row the OTHER
    // one's entry merely because it sorts earlier, which is exactly the
    // wrong-match this two-pass order avoids -- as long as identity is
    // intact for at least one of them. If identity were ALSO lost for a
    // genuine duplicate, the two are indistinguishable by data alone; that
    // residual case isn't handled here.
    PendingTransaction? pendingFor(Transaction t) => t.id != null
        ? pending.where((e) => e.transaction.id == t.id).firstOrNull
        : pending.where((e) => identical(e.transaction, t)).firstOrNull ??
              pending.where((e) => e.transaction == t).firstOrNull;

    final entry = pendingFor(transaction);

    final color = amountColorFor(context, transaction.type);
    final icon = switch (transaction.type) {
      'EXPENSE' => Icons.arrow_downward,
      'INCOME' => Icons.arrow_upward,
      _ => Icons.swap_horiz,
    };

    final accountName = switch (transaction.type) {
      'EXPENSE' => transaction.fromAccountName,
      'INCOME' => transaction.toAccountName,
      _ =>
        transaction.fromAccountName != null && transaction.toAccountName != null
            ? '${transaction.fromAccountName} → ${transaction.toAccountName}'
            : null,
    };

    final title = (transaction.payee?.isNotEmpty ?? false)
        ? transaction.payee!
        : (transaction.categoryName ?? transaction.memo ?? transaction.type);

    final subtitleParts = [
      if (transaction.memo != null && transaction.memo!.isNotEmpty)
        transaction.memo!,
      if (accountName != null && accountName.isNotEmpty) accountName,
    ];

    // What the pending row says, when there is a pending entry at all: a
    // refusal the server explained, a refusal it did not, or an entry
    // still on its way. Hoisted out of the tree below, where it read as a
    // three-level nested ternary inside a `Text`.
    final pendingLabel = switch (entry) {
      null => null,
      final e when !e.isRejected => L.of(context).txPendingNotSent,
      final e when e.rejection!.isEmpty => L.of(context).txPendingRefused,
      final e => L.of(context).txPendingRejected(e.rejection!),
    };

    final colorScheme = Theme.of(context).colorScheme;
    final editColor = context.cuentiColors.transfer;

    return Dismissible(
      key: ValueKey(transaction.id),
      background: Container(
        color: editColor.withAlpha(31),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(Icons.edit, color: editColor),
            const SizedBox(width: 8),
            Text(L.of(context).commonEdit, style: TextStyle(color: editColor)),
          ],
        ),
      ),
      secondaryBackground: Container(
        color: colorScheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              L.of(context).commonDelete,
              style: TextStyle(color: colorScheme.onErrorContainer),
            ),
            const SizedBox(width: 8),
            Icon(Icons.delete, color: colorScheme.onErrorContainer),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          final confirmed = await showConfirmSheet(
            context,
            title: L.of(context).txDeleteTitle,
            message: L.of(context).commonUndoWarning,
          );
          if (!confirmed) return false;
          if (transaction.id != null) {
            onDelete(transaction.id!);
            return true;
          }
          // A create the server has never seen: no id to delete by, so
          // deleting it means taking it out of the queue. Dismissing the
          // row without doing that left the entry to be POSTed on the next
          // drain -- the user watched the row vanish and got the
          // transaction anyway.
          if (entry != null) {
            await ref
                .read(transactionsControllerProvider(filter: filter).notifier)
                .discardPending(entry.localId);
            return true;
          }
          // Nothing was actually deleted; don't pretend the row went
          // anywhere.
          return false;
        }
        unawaited(
          showTransactionDialog(
            context,
            transaction: transaction,
            localId: entry?.localId,
            filter: filter,
          ),
        );
        return false;
      },
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withAlpha(31),
          child: Icon(icon, color: color),
        ),
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: subtitleParts.isNotEmpty || entry != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (subtitleParts.isNotEmpty)
                    Text(
                      subtitleParts.join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (entry != null)
                    Row(
                      children: [
                        Icon(
                          entry.isRejected
                              ? Icons.error_outline
                              : Icons.schedule_send,
                          size: 14,
                          color: entry.isRejected
                              ? colorScheme.error
                              : Theme.of(
                                  context,
                                ).textTheme.labelSmall?.color,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            // Non-null exactly when `entry` is.
                            pendingLabel!,
                            style: Theme.of(context).textTheme.labelSmall,
                            // Capped like both of its siblings in this
                            // subtitle: a 200-character server reason plus
                            // the "Refused: " frame wraps to ten lines in
                            // this narrow Expanded, next to two buttons,
                            // and the row grows several times the height
                            // of the ones around it.
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (entry.isRejected) ...[
                          TextButton(
                            onPressed: () => unawaited(_retry(ref, entry)),
                            child: Text(L.of(context).txRetryPending),
                          ),
                          TextButton(
                            onPressed: () => unawaited(_discard(ref, entry)),
                            child: Text(L.of(context).txDiscardPending),
                          ),
                        ],
                      ],
                    ),
                ],
              )
            : null,
        trailing: AmountText(
          transaction.amount,
          type: transaction.type,
          signed: true,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        onTap: () {
          unawaited(
            showTransactionDialog(
              context,
              transaction: transaction,
              localId: entry?.localId,
              filter: filter,
            ),
          );
        },
      ),
    );
  }
}
