import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/confirm_sheet.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../currencies/domain/currency.dart';
import '../../currencies/ui/currencies_controller.dart';
import '../domain/account.dart';
import 'accounts_controller.dart';

class AccountsScreen extends ConsumerStatefulWidget {
  const AccountsScreen({super.key});

  @override
  ConsumerState<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends ConsumerState<AccountsScreen> {
  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsControllerProvider);
    final currencies = ref.watch(currenciesControllerProvider).value ?? [];

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () {
          ref.invalidate(accountsControllerProvider);
          return ref.read(accountsControllerProvider.future);
        },
        child: AsyncValueWidget<List<Account>>(
          value: accountsAsync,
          skeleton: SkeletonLoader.tiles(items: 4, height: 88),
          data: (accounts) => accounts.isEmpty
              ? ListView(
                  children: [
                    const SizedBox(height: 80),
                    EmptyState(
                      icon: Icons.account_balance_wallet,
                      message: 'No accounts yet',
                      actionLabel: 'Add account',
                      onAction: () => _showEditDialog(context, null, currencies),
                    ),
                  ],
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: accounts.length,
                  onReorder: (old, newIdx) {
                    final ids = accounts.map((a) => a.id!).toList();
                    final id = ids.removeAt(old);
                    ids.insert(newIdx > old ? newIdx - 1 : newIdx, id);
                    _updateSortOrder(ids);
                  },
                  itemBuilder: (context, i) {
                    final a = accounts[i];
                    return Dismissible(
                      key: ValueKey(a.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Theme.of(context).colorScheme.errorContainer,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        child: Icon(
                          Icons.delete,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                      confirmDismiss: (_) => showConfirmSheet(
                        context,
                        title: 'Delete Account?',
                        message: 'All associated transactions will be affected.',
                      ),
                      onDismissed: (_) => _delete(a.id!),
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _showEditDialog(context, a, currencies),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: 0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Icon(
                                          _iconForAccountType(a.accountType),
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            a.accountName,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall,
                                          ),
                                          const SizedBox(height: 4),
                                          if (a.institution != null &&
                                              a.institution!.isNotEmpty)
                                            Text(
                                              a.institution!,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelSmall,
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        AmountText(
                                          a.balance,
                                          currency: a.currency,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                if (a.accountGroup != null &&
                                    a.accountGroup!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Chip(
                                      label: Text(a.accountGroup!),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
          onRetry: () => ref.invalidate(accountsControllerProvider),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditDialog(context, null, currencies),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _delete(int id) async {
    try {
      await ref.read(accountsControllerProvider.notifier).delete(id);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _updateSortOrder(List<int> ids) async {
    try {
      await ref.read(accountsControllerProvider.notifier).updateSortOrder(ids);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  IconData _iconForAccountType(String type) {
    return switch (type) {
      'CASH' => Icons.wallet,
      'ASSET' => Icons.trending_up,
      'CREDIT_CARD' => Icons.credit_card,
      'LIABILITY' => Icons.account_balance,
      'CURRENT' => Icons.account_balance,
      'SAVINGS' => Icons.savings,
      _ => Icons.account_balance,
    };
  }

  void _showEditDialog(
      BuildContext context, Account? account, List<Currency> currencies) {
    final name = TextEditingController(text: account?.accountName ?? '');
    final institution = TextEditingController(text: account?.institution ?? '');
    final group = TextEditingController(text: account?.accountGroup ?? '');
    final startBalance = TextEditingController(text: account?.startBalance.toStringAsFixed(2) ?? '0.00');
    String type = account?.accountType ?? 'BANK';
    String currency = account?.currency ?? 'EUR';
    bool excludeSummary = account?.excludeFromSummary ?? false;
    bool excludeReports = account?.excludeFromReports ?? false;
    bool saving = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(account == null ? 'Add Account' : 'Edit Account',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                TextField(controller: name, decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                  items: kAccountTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) => setModalState(() => type = v ?? 'BANK'),
                ),
                const SizedBox(height: 12),
                TextField(controller: institution, decoration: const InputDecoration(labelText: 'Institution', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: group, decoration: const InputDecoration(labelText: 'Group', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: startBalance, decoration: const InputDecoration(labelText: 'Start Balance', border: OutlineInputBorder()),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: currency,
                  decoration: const InputDecoration(labelText: 'Currency', border: OutlineInputBorder()),
                  items: currencies.map((c) => DropdownMenuItem(value: c.code, child: Text('${c.code} - ${c.name}'))).toList(),
                  onChanged: (v) => setModalState(() => currency = v ?? 'EUR'),
                ),
                const SizedBox(height: 12),
                SwitchListTile(title: const Text('Exclude from Summary'), value: excludeSummary,
                    onChanged: (v) => setModalState(() => excludeSummary = v)),
                SwitchListTile(title: const Text('Exclude from Reports'), value: excludeReports,
                    onChanged: (v) => setModalState(() => excludeReports = v)),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: OutlinedButton(
                    onPressed: saving ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: FilledButton(
                    onPressed: saving ? null : () async {
                      setModalState(() => saving = true);
                      try {
                        await ref.read(accountsControllerProvider.notifier).save(
                          Account(
                            id: account?.id,
                            accountName: name.text,
                            accountType: type,
                            institution: institution.text,
                            accountGroup: group.text,
                            currency: currency,
                            startBalance: double.tryParse(startBalance.text) ?? 0,
                            excludeFromSummary: excludeSummary,
                            excludeFromReports: excludeReports,
                          ),
                        );
                        if (context.mounted) Navigator.pop(context);
                      } on ApiException catch (e) {
                        setModalState(() => saving = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: ${e.message}'),
                              backgroundColor: Theme.of(context).colorScheme.error,
                            ),
                          );
                        }
                      }
                    },
                    child: saving
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Save'),
                  )),
                ]),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
