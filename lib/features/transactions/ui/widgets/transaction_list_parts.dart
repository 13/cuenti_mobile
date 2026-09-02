import 'dart:async';

import 'package:cuentimobile/core/theme/cuenti_colors.dart';
import 'package:cuentimobile/core/widgets/amount_text.dart';
import 'package:cuentimobile/core/widgets/confirm_sheet.dart';
import 'package:cuentimobile/features/transactions/domain/transaction.dart';
import 'package:cuentimobile/features/transactions/domain/transaction_filter.dart';
import 'package:cuentimobile/features/transactions/ui/transaction_dialog.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

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

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    required this.transaction,
    required this.filter,
    required this.onDelete,
    super.key,
  });

  final Transaction transaction;
  final TransactionFilter filter;
  final void Function(int id) onDelete;

  @override
  Widget build(BuildContext context) {
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
          if (confirmed && transaction.id != null) {
            onDelete(transaction.id!);
          }
          return confirmed;
        }
        unawaited(
          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            builder: (_) => TransactionDialog(
              transaction: transaction,
              filter: filter,
            ),
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
        subtitle: subtitleParts.isNotEmpty
            ? Text(
                subtitleParts.join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
            showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => TransactionDialog(
                transaction: transaction,
                filter: filter,
              ),
            ),
          );
        },
      ),
    );
  }
}
