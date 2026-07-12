import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../domain/category.dart';
import 'categories_controller.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesControllerProvider);

    return Scaffold(
      body: AsyncValueWidget<List<Category>>(
        value: categoriesAsync,
        data: (categories) {
          // Group: parent categories (no parent) and their children
          final parents = categories.where((c) => c.parentId == null).toList();

          return RefreshIndicator(
            onRefresh: () {
              ref.invalidate(categoriesControllerProvider);
              return ref.read(categoriesControllerProvider.future);
            },
            child: categories.isEmpty
                ? ListView(children: [
                    const SizedBox(height: 120),
                    Icon(Icons.category, size: 64,
                        color: Theme.of(context).colorScheme.outline),
                    const SizedBox(height: 16),
                    Center(child: Text('No categories yet',
                        style: Theme.of(context).textTheme.titleMedium)),
                    const SizedBox(height: 8),
                    Center(child: Text('Tap + to add a category.',
                        style: Theme.of(context).textTheme.bodySmall)),
                  ])
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
                              onPressed: () => _showEditDialog(context, ref, parent),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20),
                              onPressed: () => _confirmDelete(context, ref, parent),
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
                                onPressed: () => _showEditDialog(context, ref, child),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 20),
                                onPressed: () => _confirmDelete(context, ref, child),
                              ),
                            ],
                          ),
                        )).toList(),
                      );
                    },
                  ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditDialog(context, ref, null),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Category category) {
    showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        icon: const Icon(Icons.delete_outline),
        title: const Text('Delete Category?'),
        content: Text('Delete "${category.fullName ?? category.name}"?'),
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(c).colorScheme.error,
              foregroundColor: Theme.of(c).colorScheme.onError,
            ),
            onPressed: () async {
              Navigator.pop(c);
              try {
                await ref.read(categoriesControllerProvider.notifier).delete(category.id!);
              } on ApiException catch (e) {
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, Category? category) {
    final name = TextEditingController(text: category?.name ?? '');
    String type = category?.type ?? 'EXPENSE';
    int? parentId = category?.parentId;
    bool saving = false;

    final categories = ref.read(categoriesControllerProvider).value ?? [];
    final parentOptions = categories.where((c) => c.parentId == null && c.id != category?.id).toList();

    showModalBottomSheet<void>(
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
                        final newCategory = Category(
                          id: category?.id,
                          name: name.text,
                          type: type,
                          parentId: parentId,
                        );
                        await ref.read(categoriesControllerProvider.notifier).save(newCategory);
                        if (ctx.mounted) Navigator.pop(ctx);
                      } on ApiException catch (e) {
                        setModalState(() => saving = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text('Error: ${e.message}'),
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
