import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/data_provider.dart';

class TagsScreen extends StatefulWidget {
  const TagsScreen({super.key});

  @override
  State<TagsScreen> createState() => _TagsScreenState();
}

class _TagsScreenState extends State<TagsScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try { await context.read<DataProvider>().loadTags(); } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final dp = context.watch<DataProvider>();

    if (_loading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: dp.tags.isEmpty
            ? ListView(children: [
                const SizedBox(height: 120),
                Icon(Icons.label, size: 64,
                    color: Theme.of(context).colorScheme.outline),
                const SizedBox(height: 16),
                Center(child: Text('No tags yet',
                    style: Theme.of(context).textTheme.titleMedium)),
                const SizedBox(height: 8),
                Center(child: Text('Tap + to add a tag.',
                    style: Theme.of(context).textTheme.bodySmall)),
              ])
            : ListView.builder(
                itemCount: dp.tags.length,
                itemBuilder: (context, i) {
                  final tag = dp.tags[i];
                  return Dismissible(
                    key: ValueKey(tag.id),
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
                        title: const Text('Delete Tag?'),
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
                    onDismissed: (_) => dp.deleteTag(tag.id!),
                    child: ListTile(
                      leading: const Icon(Icons.label),
                      title: Text(tag.name),
                      onTap: () => _showEditDialog(context, tag),
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

  void _showEditDialog(BuildContext context, Tag? tag) {
    final name = TextEditingController(text: tag?.name ?? '');
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(tag == null ? 'Add Tag' : 'Edit Tag',
                  style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
                autofocus: true,
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
                      await context.read<DataProvider>().saveTag({'name': name.text}, id: tag?.id);
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
    );
  }
}
