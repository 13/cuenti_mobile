import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/data_provider.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try { await context.read<DataProvider>().loadCategories(); } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final dp = context.watch<DataProvider>();
    final categories = dp.categories;

    // Group: parent categories (no parent) and their children
    final parents = categories.where((c) => c.parentId == null).toList();

    if (_loading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: categories.isEmpty
            ? const Center(child: Text('No categories'))
            : ListView.builder(
                itemCount: parents.length,
                itemBuilder: (context, i) {
                  final parent = parents[i];
                  final children = categories.where((c) => c.parentId == parent.id).toList();
                  return ExpansionTile(
                    leading: Icon(
                      parent.type == 'INCOME' ? Icons.arrow_upward : Icons.arrow_downward,
                      color: parent.type == 'INCOME' ? Colors.green : Colors.red,
                    ),
                    title: Text(parent.name),
                    subtitle: Text(parent.type),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () => _showEditDialog(context, parent),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20),
                          onPressed: () => _confirmDelete(context, parent),
                        ),
                      ],
                    ),
                    children: children.map((child) => ListTile(
                      contentPadding: const EdgeInsets.only(left: 56, right: 16),
                      title: Text(child.name),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: () => _showEditDialog(context, child),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 20),
                            onPressed: () => _confirmDelete(context, child),
                          ),
                        ],
                      ),
                    )).toList(),
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

  void _confirmDelete(BuildContext context, Category category) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete Category?'),
        content: Text('Delete "${category.fullName ?? category.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(c);
              context.read<DataProvider>().deleteCategory(category.id!);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, Category? category) {
    final name = TextEditingController(text: category?.name ?? '');
    String type = category?.type ?? 'EXPENSE';
    int? parentId = category?.parentId;
    bool saving = false;

    final dp = context.read<DataProvider>();
    final parentOptions = dp.categories.where((c) => c.parentId == null && c.id != category?.id).toList();

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
                Text(category == null ? 'Add Category' : 'Edit Category',
                    style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 16),
                TextField(controller: name, decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'EXPENSE', child: Text('Expense')),
                    DropdownMenuItem(value: 'INCOME', child: Text('Income')),
                  ],
                  onChanged: (v) => setModalState(() => type = v ?? 'EXPENSE'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int?>(
                  initialValue: parentId,
                  decoration: const InputDecoration(labelText: 'Parent Category', border: OutlineInputBorder()),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('None (Top Level)')),
                    ...parentOptions.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                  ],
                  onChanged: (v) => setModalState(() => parentId = v),
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
                        await dp.saveCategory({
                          'name': name.text,
                          'type': type,
                          'parentId': parentId,
                        }, id: category?.id);
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        setModalState(() => saving = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text('Error: ${dp.lastError ?? e}'),
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
