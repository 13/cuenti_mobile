import 'dart:async';

import 'package:cuentimobile/core/enum_labels.dart';
import 'package:cuentimobile/core/widgets/amount_text.dart';
import 'package:cuentimobile/core/widgets/async_value_widget.dart';
import 'package:cuentimobile/core/widgets/confirm_sheet.dart';
import 'package:cuentimobile/core/widgets/empty_state.dart';
import 'package:cuentimobile/core/widgets/entity_edit_sheet.dart';
import 'package:cuentimobile/core/widgets/entity_list_filter.dart';
import 'package:cuentimobile/core/widgets/entity_list_header.dart';
import 'package:cuentimobile/core/widgets/enum_dropdown.dart';
import 'package:cuentimobile/core/widgets/feedback_snack.dart';
import 'package:cuentimobile/core/widgets/skeleton_loader.dart';
import 'package:cuentimobile/features/accounts/domain/account.dart';
import 'package:cuentimobile/features/accounts/ui/accounts_controller.dart';
import 'package:cuentimobile/features/currencies/domain/currency.dart';
import 'package:cuentimobile/features/currencies/ui/currencies_controller.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AccountsScreen extends ConsumerStatefulWidget {
  const AccountsScreen({super.key});

  @override
  ConsumerState<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends ConsumerState<AccountsScreen> {
  static const _screen = 'accounts';
  final _searchController = TextEditingController();

  /// The order the server holds, which the user arranges by dragging. No
  /// chip chosen means this one, so the list opens the way it was left.
  static const _customOrder = SortSelection('custom');

  @override
  void initState() {
    super.initState();
    _searchController.text = ref.read(entityListFilterProvider(_screen)).query;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    _searchController.clear();
    ref.read(entityListFilterProvider(_screen).notifier).clearQuery();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final filter = ref.watch(entityListFilterProvider(_screen));
    final filters = ref.read(entityListFilterProvider(_screen).notifier);
    // Nothing chosen means the order the server holds, which is
    // exactly what the custom chip stands for.
    final sort = filter.sort == SortSelection.none ? _customOrder : filter.sort;
    final accountsAsync = ref.watch(accountsControllerProvider);
    final currencies = ref.watch(currenciesControllerProvider).value ?? [];
    final options = [
      SortOption<Account>(id: _customOrder.id, label: l.commonSortCustom),
      SortOption<Account>(
        id: 'name',
        label: l.commonName,
        compare: (a, b) =>
            a.accountName.toLowerCase().compareTo(b.accountName.toLowerCase()),
      ),
      SortOption<Account>(
        id: 'type',
        label: l.commonType,
        compare: (a, b) => accountTypeLabel(
          l,
          a.accountType,
        ).compareTo(accountTypeLabel(l, b.accountType)),
      ),
      SortOption<Account>(
        id: 'balance',
        label: l.commonBalance,
        compare: (a, b) => a.balance.compareTo(b.balance),
      ),
      SortOption<Account>(
        id: 'group',
        label: l.commonGroup,
        compare: (a, b) => (a.accountGroup ?? '').toLowerCase().compareTo(
          (b.accountGroup ?? '').toLowerCase(),
        ),
      ),
    ];
    // Dragging needs the whole list on screen: a search hides rows, and the
    // ids of what is left would describe an order missing everything filtered
    // out.
    final draggable = sort.id == _customOrder.id && filter.query.isEmpty;

    return Scaffold(
      body: Column(
        children: [
          EntityListHeader<Account>(
            searchController: _searchController,
            searchHint: l.accountsSearchHint,
            onSearchChanged: filters.setQuery,
            options: options,
            selected: sort,
            onSortChanged: filters.setSort,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () {
                ref.invalidate(accountsControllerProvider);
                return ref.read(accountsControllerProvider.future);
              },
              child: AsyncValueWidget<List<Account>>(
                value: accountsAsync,
                skeleton: SkeletonLoader.tiles(items: 4, height: 88),
                data: (accounts) {
                  final shown = applySearchAndSort(
                    accounts,
                    query: filter.query,
                    searchText: (a) =>
                        '${a.accountName} ${a.institution ?? ''} '
                        '${a.accountGroup ?? ''} ${a.accountType} ${a.currency}',
                    sort: sortOptionFor(options, sort),
                    descending: sort.descending,
                  );

                  if (shown.isEmpty) {
                    return ListView(
                      children: [
                        const SizedBox(height: 80),
                        if (accounts.isEmpty)
                          EmptyState(
                            icon: Icons.account_balance_wallet,
                            message: l.accountsEmpty,
                            actionLabel: l.accountsAdd,
                            onAction: () =>
                                _showEditDialog(context, null, currencies),
                          )
                        else
                          EmptyState(
                            icon: Icons.account_balance_wallet,
                            message: l.accountsNoMatch,
                            actionLabel: l.commonClearFilters,
                            onAction: _clearFilters,
                          ),
                      ],
                    );
                  }

                  Widget itemBuilder(BuildContext context, int i) =>
                      _accountCard(context, shown[i], currencies);

                  const padding = EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  );

                  // In any other order the drop position describes the
                  // sort, not the order to save, so there is nothing honest
                  // to write back.
                  if (!draggable) {
                    return ListView.builder(
                      padding: padding,
                      itemCount: shown.length,
                      itemBuilder: itemBuilder,
                    );
                  }

                  return ReorderableListView.builder(
                    padding: padding,
                    itemCount: shown.length,
                    // onReorderItem (unlike the deprecated onReorder) hands
                    // back an index already adjusted for the removed item, so
                    // no off-by-one correction here.
                    onReorderItem: (old, newIdx) {
                      final ids = shown.map((a) => a.id!).toList();
                      final id = ids.removeAt(old);
                      ids.insert(newIdx, id);
                      unawaited(_updateSortOrder(ids));
                    },
                    itemBuilder: itemBuilder,
                  );
                },
                onRetry: () => ref.invalidate(accountsControllerProvider),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditDialog(context, null, currencies),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _accountCard(
    BuildContext context,
    Account a,
    List<Currency> currencies,
  ) {
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
        title: L.of(context).accountsDeleteTitle,
        message: L.of(context).accountsDeleteBody,
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
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          _iconForAccountType(a.accountType),
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a.accountName,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          if (a.institution != null &&
                              a.institution!.isNotEmpty)
                            Text(
                              a.institution!,
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        AmountText(
                          a.balance,
                          currency: a.currency,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                if (a.accountGroup != null && a.accountGroup!.isNotEmpty) ...[
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
  }

  Future<void> _delete(int id) => reportingFailure(
    context,
    () => ref.read(accountsControllerProvider.notifier).delete(id),
  );

  Future<void> _updateSortOrder(List<int> ids) => reportingFailure(
    context,
    () => ref.read(accountsControllerProvider.notifier).updateSortOrder(ids),
  );

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
    BuildContext context,
    Account? account,
    List<Currency> currencies,
  ) {
    final name = TextEditingController(text: account?.accountName ?? '');
    final institution = TextEditingController(text: account?.institution ?? '');
    final group = TextEditingController(text: account?.accountGroup ?? '');
    final startBalance = TextEditingController(
      text: account?.startBalance.toStringAsFixed(2) ?? '0.00',
    );
    var type = account?.accountType ?? 'BANK';
    var currency = account?.currency ?? 'EUR';
    var excludeSummary = account?.excludeFromSummary ?? false;
    var excludeReports = account?.excludeFromReports ?? false;
    final currencyNames = {for (final c in currencies) c.code: c.name};

    Widget field(TextEditingController controller, String label) => TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );

    unawaited(
      showEntityEditSheet(
        context: context,
        title: account == null
            ? L.of(context).accountsAddTitle
            : L.of(context).accountsEditTitle,
        successMessage: L.of(context).accountsSaved,
        fields: (context, rebuild) => [
          field(name, L.of(context).commonName),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: type,
            decoration: InputDecoration(
              labelText: L.of(context).commonType,
              border: const OutlineInputBorder(),
            ),
            items: dropdownItemsFor(
              kAccountTypes,
              type,
              label: (v) => accountTypeLabel(L.of(context), v),
            ),
            onChanged: (v) {
              type = v ?? 'BANK';
              rebuild();
            },
          ),
          const SizedBox(height: 12),
          field(institution, L.of(context).accountsInstitution),
          const SizedBox(height: 12),
          field(group, L.of(context).commonGroup),
          const SizedBox(height: 12),
          TextField(
            controller: startBalance,
            decoration: InputDecoration(
              labelText: L.of(context).accountsStartBalance,
              border: const OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: currency,
            decoration: InputDecoration(
              labelText: L.of(context).commonCurrency,
              border: const OutlineInputBorder(),
            ),
            items: dropdownItemsFor(
              currencyNames.keys,
              currency,
              label: (code) => '$code - ${currencyNames[code]}',
            ),
            onChanged: (v) {
              currency = v ?? 'EUR';
              rebuild();
            },
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: Text(L.of(context).accountsExcludeSummary),
            value: excludeSummary,
            onChanged: (v) {
              excludeSummary = v;
              rebuild();
            },
          ),
          SwitchListTile(
            title: Text(L.of(context).accountsExcludeReports),
            value: excludeReports,
            onChanged: (v) {
              excludeReports = v;
              rebuild();
            },
          ),
        ],
        onSave: () => ref
            .read(accountsControllerProvider.notifier)
            .save(
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
            ),
      ),
    );
  }
}
