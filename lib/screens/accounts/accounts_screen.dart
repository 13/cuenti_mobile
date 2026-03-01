import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/data_provider.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try { await context.read<DataProvider>().loadAccounts(); } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final dp = context.watch<DataProvider>();

    if (_loading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: dp.accounts.isEmpty
            ? const Center(child: Text('No accounts'))
            : ReorderableListView.builder(
                itemCount: dp.accounts.length,
                onReorder: (old, newIdx) {
                  final ids = dp.accounts.map((a) => a.id!).toList();
                  final id = ids.removeAt(old);
                  ids.insert(newIdx > old ? newIdx - 1 : newIdx, id);
                  dp.accountApi.updateSortOrder(ids).then((_) => dp.loadAccounts());
                },
                itemBuilder: (context, i) {
                  final a = dp.accounts[i];
                  return Dismissible(
                    key: ValueKey(a.id),
                    direction: DismissDirection.endToStart,
                    background: Container(color: Colors.red, alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16), child: const Icon(Icons.delete, color: Colors.white)),
                    confirmDismiss: (_) => showDialog<bool>(context: context,
                        builder: (c) => AlertDialog(title: const Text('Delete Account?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                              TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete')),
                            ])),
                    onDismissed: (_) => dp.deleteAccount(a.id!),
                    child: Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(child: Text(a.accountName[0].toUpperCase())),
                        title: Text(a.accountName),
                        subtitle: Text('${a.displayType} • ${a.institution ?? ''} • ${a.currency}'),
                        trailing: Text('${a.balance.toStringAsFixed(2)}',
                            style: TextStyle(fontWeight: FontWeight.bold,
                                color: a.balance >= 0 ? Colors.green : Colors.red)),
                        onTap: () => _showEditDialog(context, a),
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditDialog(context, null),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showEditDialog(BuildContext context, Account? account) {
    final name = TextEditingController(text: account?.accountName ?? '');
    final institution = TextEditingController(text: account?.institution ?? '');
    final group = TextEditingController(text: account?.accountGroup ?? '');
    final startBalance = TextEditingController(text: account?.startBalance.toStringAsFixed(2) ?? '0.00');
    String type = account?.accountType ?? 'BANK';
    String currency = account?.currency ?? 'EUR';
    bool excludeSummary = account?.excludeFromSummary ?? false;
    bool excludeReports = account?.excludeFromReports ?? false;
    bool saving = false;

    showModalBottomSheet(
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
                  items: Account.accountTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
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
                  items: context.read<DataProvider>().currencies.map((c) => DropdownMenuItem(value: c.code, child: Text('${c.code} - ${c.name}'))).toList(),
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
                        await context.read<DataProvider>().saveAccount({
                          'accountName': name.text,
                          'accountType': type,
                          'institution': institution.text,
                          'accountGroup': group.text,
                          'currency': currency,
                          'startBalance': double.tryParse(startBalance.text) ?? 0,
                          'excludeFromSummary': excludeSummary,
                          'excludeFromReports': excludeReports,
                        }, id: account?.id);
                        if (context.mounted) Navigator.pop(context);
                      } catch (e) {
                        setModalState(() => saving = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: ${context.read<DataProvider>().lastError ?? e}'),
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
