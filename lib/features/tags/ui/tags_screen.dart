import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/confirm_sheet.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../domain/tag.dart';
import 'tags_controller.dart';

class TagsScreen extends ConsumerWidget {
  const TagsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(tagsControllerProvider);

    return Scaffold(
      body: AsyncValueWidget<List<Tag>>(
        value: tagsAsync,
        skeleton: SkeletonLoader.tiles(items: 6, height: 64),
        data: (tags) {
          return RefreshIndicator(
            onRefresh: () {
              ref.invalidate(tagsControllerProvider);
              return ref.read(tagsControllerProvider.future);
            },
            child: tags.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 80),
                      EmptyState(
                        icon: Icons.sell,
                        message: 'No tags yet',
                        actionLabel: 'Add tag',
                        onAction: () => _showEditDialog(context, ref, null),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    itemCount: tags.length,
                    itemBuilder: (context, i) {
                      final tag = tags[i];
                      return Dismissible(
                        key: ValueKey(tag.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Theme.of(context).colorScheme.errorContainer,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          child: Icon(
                            Icons.delete,
                            color: Theme.of(
                              context,
                            ).colorScheme.onErrorContainer,
                          ),
                        ),
                        confirmDismiss: (_) => showConfirmSheet(
                          context,
                          title: 'Delete Tag?',
                          message: 'Delete "${tag.name}"?',
                        ),
                        onDismissed: (_) async {
                          try {
                            await ref
                                .read(tagsControllerProvider.notifier)
                                .delete(tag.id!);
                          } on ApiException catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: ${e.message}'),
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.error,
                                ),
                              );
                            }
                          }
                        },
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _showEditDialog(context, ref, tag),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.sell,
                                      size: 20,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      tag.name,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleSmall,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          );
        },
        onRetry: () => ref.invalidate(tagsControllerProvider),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditDialog(context, ref, null),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, Tag? tag) {
    final name = TextEditingController(text: tag?.name ?? '');
    bool saving = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                tag == null ? 'Add Tag' : 'Edit Tag',
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: name,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: saving ? null : () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: saving
                          ? null
                          : () async {
                              setModalState(() => saving = true);
                              try {
                                final newTag = Tag(
                                  id: tag?.id,
                                  name: name.text,
                                );
                                await ref
                                    .read(tagsControllerProvider.notifier)
                                    .save(newTag);
                                if (ctx.mounted) Navigator.pop(ctx);
                              } on ApiException catch (e) {
                                setModalState(() => saving = false);
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: ${e.message}'),
                                      backgroundColor: Theme.of(
                                        ctx,
                                      ).colorScheme.error,
                                    ),
                                  );
                                }
                              }
                            },
                      child: saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
