import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/data_provider.dart';

class PayeesScreen extends StatefulWidget {
  const PayeesScreen({super.key});

  @override
  State<PayeesScreen> createState() => _PayeesScreenState();
}

class _PayeesScreenState extends State<PayeesScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try { await context.read<DataProvider>().loadPayees(); } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final dp = context.watch<DataProvider>();

    if (_loading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: dp.payees.isEmpty
            ? ListView(children: [
                const SizedBox(height: 120),
                Icon(Icons.people, size: 64,
                    color: Theme.of(context).colorScheme.outline),
                const SizedBox(height: 16),
                Center(child: Text('No payees yet',
                    style: Theme.of(context).textTheme.titleMedium)),
                const SizedBox(height: 8),
                Center(child: Text('Tap + to add a payee.',
                    style: Theme.of(context).textTheme.bodySmall)),
              ])
            : ListView.builder(
                itemCount: dp.payees.length,
                itemBuilder: (context, i) {
                  final p = dp.payees[i];
                  return Dismissible(
                    key: ValueKey(p.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Theme.of(context).colorScheme.errorContainer,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      child: Icon(Icons.delete, color: Theme.of(context).colorScheme.onErrorContainer),
                    ),
                    confirmDismiss: (_) => showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        icon: const Icon(Icons.delete_outline),
                        title: const Text('Delete Payee?'),
                        actions: [
                          OutlinedButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: Theme.of(c).colorScheme.error,
                              foregroundColor: Theme.of(c).colorScheme.onError,
                            ),
                            onPressed: () => Navigator.pop(c, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    ),
                    onDismissed: (_) => dp.deletePayee(p.id!),
                    child: ListTile(
                      leading: CircleAvatar(child: Text(p.name[0].toUpperCase())),
                      title: Text(p.name),
                      subtitle: Text(p.defaultCategoryName ?? p.notes ?? ''),
                      onTap: () => _showEditDialog(context, p),
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

  void _showEditDialog(BuildContext context, Payee? payee) {
    final name = TextEditingController(text: payee?.name ?? '');
    final notes = TextEditingController(text: payee?.notes ?? '');
    int? categoryId = payee?.defaultCategoryId;
    String paymentMethod = payee?.defaultPaymentMethod ?? 'NONE';
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 16, right: 16, top: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(payee == null ? 'Add Payee' : 'Edit Payee',
                    style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 16),
                TextField(controller: name, decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: notes, decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder()), maxLines: 2),
                const SizedBox(height: 12),
                DropdownButtonFormField<int?>(
                  initialValue: categoryId,
                  decoration: const InputDecoration(labelText: 'Default Category', border: OutlineInputBorder()),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('None')),
                    ...context.read<DataProvider>().categories.map((c) =>
                        DropdownMenuItem(value: c.id, child: Text(c.fullName ?? c.name))),
                  ],
                  onChanged: (v) => setModalState(() => categoryId = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: paymentMethod,
                  decoration: const InputDecoration(labelText: 'Default Payment', border: OutlineInputBorder()),
                  items: Transaction.paymentMethods.map((p) =>
                      DropdownMenuItem(value: p, child: Text(p))).toList(),
                  onChanged: (v) => setModalState(() => paymentMethod = v ?? 'NONE'),
                ),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: OutlinedButton(
                    onPressed: saving ? null : () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: FilledButton(
                    onPressed: saving ? null : () async {
                      setModalState(() => saving = true);
                      try {
                        await context.read<DataProvider>().savePayee({
                          'name': name.text,
                          'notes': notes.text.isNotEmpty ? notes.text : null,
                          'defaultCategoryId': categoryId,
                          'defaultPaymentMethod': paymentMethod,
                        }, id: payee?.id);
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        setModalState(() => saving = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text('Error: ${context.read<DataProvider>().lastError ?? e}'),
                              backgroundColor: Theme.of(ctx).colorScheme.error,
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
