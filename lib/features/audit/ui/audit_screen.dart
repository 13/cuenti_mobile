import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/theme/cuenti_colors.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/empty_state.dart';
import '../domain/audit_entry.dart';
import 'audit_controller.dart';

class AuditScreen extends ConsumerStatefulWidget {
  const AuditScreen({super.key});

  @override
  ConsumerState<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends ConsumerState<AuditScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _debounce;
  String? _filter;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    try {
      await ref
          .read(auditControllerProvider(filter: _filter).notifier)
          .loadMore();
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

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(
        () => _filter = value.isEmpty ? null : value,
      );
    });
  }

  void _resetFilters() {
    _debounce?.cancel();
    _searchController.clear();
    setState(() => _filter = null);
  }

  @override
  Widget build(BuildContext context) {
    final auditAsync = ref.watch(
      auditControllerProvider(filter: _filter),
    );

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search audit log...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () {
                ref.invalidate(auditControllerProvider(filter: _filter));
                return ref.read(
                  auditControllerProvider(filter: _filter).future,
                );
              },
              child: AsyncValueWidget<AuditState>(
                value: auditAsync,
                data: (state) {
                  if (state.items.isEmpty) {
                    return ListView(
                      children: [
                        const SizedBox(height: 80),
                        if (_filter == null)
                          const EmptyState(
                            icon: Icons.history,
                            message: 'No audit entries',
                          )
                        else
                          EmptyState(
                            icon: Icons.history,
                            message: 'No audit entries match',
                            actionLabel: 'Clear filters',
                            onAction: _resetFilters,
                          ),
                      ],
                    );
                  }
                  return _buildList(context, state);
                },
                onRetry: () => ref.invalidate(
                  auditControllerProvider(filter: _filter),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, AuditState state) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: state.items.length + (state.loadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.items.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        return _AuditTile(entry: state.items[index]);
      },
    );
  }
}

class _AuditTile extends StatelessWidget {
  const _AuditTile({required this.entry});

  final AuditEntry entry;

  @override
  Widget build(BuildContext context) {
    final icon = switch (entry.action) {
      'CREATE' => Icons.add_circle_outline,
      'UPDATE' => Icons.edit,
      'DELETE' => Icons.delete,
      _ => Icons.help,
    };

    final color = switch (entry.action) {
      'CREATE' => context.cuentiColors.income,
      'UPDATE' => context.cuentiColors.transfer,
      'DELETE' => context.cuentiColors.expense,
      _ => Theme.of(context).colorScheme.onSurface,
    };

    final title = entry.entityType != null && entry.details != null
        ? '${entry.entityType} · ${entry.details}'
        : (entry.entityType ?? entry.details ?? '—');

    final subtitle = entry.username != null && entry.timestamp != null
        ? '${entry.username} · ${DateFormat('dd.MM.yyyy HH:mm').format(entry.timestamp)}'
        : '—';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.12),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(subtitle),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}
