import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/theme/cuenti_colors.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/confirm_sheet.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../utils/number_format.dart';
import '../../categories/ui/categories_controller.dart';
import '../domain/budget.dart';
import '../domain/budget_progress.dart';
import 'budgets_controller.dart';

/// Unlike most other feature screens (accounts/categories/payees), this
/// screen has no Scaffold of its own — it's mounted directly inside
/// ShellScreen's Scaffold body (same as DashboardScreen), so the FAB is
/// laid out via a [Stack] + [Positioned] instead of Scaffold.floatingActionButton.
class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(budgetsControllerProvider);

    return Stack(
      children: [
        Positioned.fill(
          child: AsyncValueWidget<List<BudgetProgress>>(
            value: progressAsync,
            skeleton: SkeletonLoader.tiles(items: 4, height: 96),
            data: (progress) => _BudgetsList(progress: progress),
            onRetry: () => ref.invalidate(budgetsControllerProvider),
          ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: () => _openEditSheet(context,
                existing: null, allProgress: progressAsync.value ?? []),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

class _BudgetsList extends ConsumerWidget {
  const _BudgetsList({required this.progress});

  final List<BudgetProgress> progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (progress.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          EmptyState(
            icon: Icons.pie_chart,
            message: 'No budgets yet',
            actionLabel: 'Add budget',
            onAction: () =>
                _openEditSheet(context, existing: null, allProgress: progress),
          ),
        ],
      );
    }

    // Active budgets first; `where` preserves relative order so this stays
    // stable without needing a custom comparator.
    final actives = progress.where((p) => p.active).toList();
    final inactives = progress.where((p) => !p.active).toList();
    final ordered = [...actives, ...inactives];

    return RefreshIndicator(
      onRefresh: () {
        ref.invalidate(budgetsControllerProvider);
        return ref.read(budgetsControllerProvider.future);
      },
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
        itemCount: ordered.length,
        itemBuilder: (context, i) {
          final bp = ordered[i];
          return _BudgetCard(
            progress: bp,
            onTap: () => _openEditSheet(context,
                existing: bp, allProgress: progress),
            onDelete: () => _delete(context, ref, bp),
          );
        },
      ),
    );
  }

  Future<void> _delete(
      BuildContext context, WidgetRef ref, BudgetProgress bp) async {
    try {
      await ref.read(budgetsControllerProvider.notifier).delete(bp.budgetId);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}

void _openEditSheet(
  BuildContext context, {
  required BudgetProgress? existing,
  required List<BudgetProgress> allProgress,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) =>
        _BudgetEditSheet(existing: existing, allProgress: allProgress),
  );
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({
    required this.progress,
    required this.onTap,
    required this.onDelete,
  });

  final BudgetProgress progress;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final overBudget = progress.spent >= progress.monthlyLimit;
    final ratio = progress.monthlyLimit > 0
        ? (progress.spent / progress.monthlyLimit).clamp(0.0, 1.0)
        : 0.0;

    final card = Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                progress.categoryName ?? '',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 8,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  color: overBudget
                      ? context.cuentiColors.expense
                      : colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AmountText(progress.spent, type: 'EXPENSE'),
                  AmountText(progress.monthlyLimit),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Remaining: ${formatNumber(progress.remaining)}',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );

    return Dismissible(
      key: ValueKey(progress.budgetId),
      direction: DismissDirection.endToStart,
      background: Container(
        color: colorScheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: Icon(Icons.delete, color: colorScheme.onErrorContainer),
      ),
      confirmDismiss: (_) => showConfirmSheet(
        context,
        title: 'Delete Budget?',
        message: 'Delete budget for "${progress.categoryName}"?',
      ),
      onDismissed: (_) => onDelete(),
      child: Opacity(opacity: progress.active ? 1.0 : 0.5, child: card),
    );
  }
}

class _BudgetEditSheet extends ConsumerStatefulWidget {
  const _BudgetEditSheet({required this.existing, required this.allProgress});

  final BudgetProgress? existing;
  final List<BudgetProgress> allProgress;

  @override
  ConsumerState<_BudgetEditSheet> createState() => _BudgetEditSheetState();
}

class _BudgetEditSheetState extends ConsumerState<_BudgetEditSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _limit;
  int? _categoryId;
  bool _active = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _limit = TextEditingController(
      text: existing != null ? formatNumber(existing.monthlyLimit) : '',
    );
    _categoryId = existing?.categoryId;
    _active = existing?.active ?? true;
  }

  @override
  void dispose() {
    _limit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesControllerProvider).value ?? [];
    final existingId = widget.existing?.budgetId;
    final usedCategoryIds = widget.allProgress
        .where((p) => existingId == null || p.budgetId != existingId)
        .map((p) => p.categoryId)
        .toSet();
    final categoryOptions = categories
        .where((c) =>
            c.type == 'EXPENSE' &&
            (!usedCategoryIds.contains(c.id) ||
                c.id == widget.existing?.categoryId))
        .toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.existing == null ? 'Add Budget' : 'Edit Budget',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: categoryOptions.any((c) => c.id == _categoryId)
                    ? _categoryId
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: categoryOptions
                    .map((c) =>
                        DropdownMenuItem(value: c.id, child: Text(c.name)))
                    .toList(),
                onChanged: (v) => setState(() => _categoryId = v),
                validator: (v) => v == null ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _limit,
                decoration: const InputDecoration(
                  labelText: 'Monthly Limit',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  final normalized =
                      v.replaceAll('.', '').replaceAll(',', '.');
                  if (double.tryParse(normalized) == null) {
                    return 'Invalid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Active'),
                value: _active,
                onChanged: (v) => setState(() => _active = v),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _submitting ? null : _save,
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
              if (widget.existing != null) ...[
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _submitting ? null : _delete,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  child: const Text('Delete'),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    try {
      await ref.read(budgetsControllerProvider.notifier).save(
            Budget(
              id: widget.existing?.budgetId,
              categoryId: _categoryId!,
              monthlyLimit: double.parse(
                _limit.text.replaceAll('.', '').replaceAll(',', '.'),
              ),
              active: _active,
            ),
          );
      if (mounted) Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _delete() async {
    final existing = widget.existing;
    if (existing == null) return;
    final confirmed = await showConfirmSheet(
      context,
      title: 'Delete Budget?',
      message: 'Delete budget for "${existing.categoryName}"?',
    );
    if (!confirmed) return;

    setState(() => _submitting = true);
    try {
      await ref
          .read(budgetsControllerProvider.notifier)
          .delete(existing.budgetId);
      if (mounted) Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
