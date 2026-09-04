import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:cuentimobile/utils/token_search.dart';
import 'package:flutter/material.dart';

/// A searchable list of [T] that can also make one that is not there yet.
///
/// The category picker and the payee picker want the same sheet over
/// different things: type to narrow, tap to choose, and -- when nothing
/// answers to what was typed -- a last row offering to create it.
///
/// What differs between them is passed in: how an item is labelled, what
/// sits at the end of its row, and whether the create row explains itself.
class SearchCreateSheet<T> extends StatefulWidget {
  const SearchCreateSheet({
    required this.items,
    required this.label,
    required this.title,
    required this.onPick,
    super.key,
    this.selected,
    this.allowNone = true,
    this.noneLabel,
    this.trailingBuilder,
    this.onCreate,
    this.createSubtitle,
    this.emptyLabel,
  });

  final List<T> items;

  /// How an item reads, and what the search matches against.
  final String Function(T item) label;

  final String title;

  /// Called with the chosen item, or null for the "none" row.
  final void Function(T? item) onPick;

  /// Marked with a check when [label] matches.
  final String? selected;

  final bool allowNone;
  final String? noneLabel;
  final String? emptyLabel;

  /// Hangs something off a row, replacing the selected check mark.
  final Widget? Function(BuildContext context, T item)? trailingBuilder;

  /// Makes what the search did not find, answering whether the sheet should
  /// close with the typed text adopted. A category answers false when the
  /// server refused, because there is no id to reference; a payee answers
  /// true regardless, because the transaction carries the name either way.
  /// Null offers no create row at all.
  final Future<bool> Function(String typed)? onCreate;

  /// A line under the create row saying what it will do, when there is
  /// something worth saying.
  final String Function(String typed)? createSubtitle;

  @override
  State<SearchCreateSheet<T>> createState() => _SearchCreateSheetState<T>();
}

class _SearchCreateSheetState<T> extends State<SearchCreateSheet<T>> {
  final _query = TextEditingController();
  bool _creating = false;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  List<T> get _matches => [
    for (final item in widget.items)
      if (matchesAllTokens(widget.label(item), _query.text)) item,
  ];

  /// Judged on an exact match rather than an empty result: with
  /// 'Werkstatt Nord' listed, typing 'Werk' should still offer to make one.
  bool get _offersCreate {
    if (widget.onCreate == null) return false;
    final typed = _query.text.trim().toLowerCase();
    if (typed.isEmpty) return false;
    return !widget.items.any(
      (i) => widget.label(i).trim().toLowerCase() == typed,
    );
  }

  Future<void> _create() async {
    setState(() => _creating = true);
    final adopted = await widget.onCreate!(_query.text.trim());
    if (!mounted) return;
    if (adopted) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _creating = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final matches = _matches;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _query,
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: l.categorySearchHint(widget.title.toLowerCase()),
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                  suffixIcon: _query.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          tooltip: l.categorySearchClear,
                          onPressed: () => setState(_query.clear),
                        ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 8),
                children: [
                  // Kept above the results and never filtered out: clearing
                  // stays one tap away mid-search.
                  if (widget.allowNone)
                    ListTile(
                      title: Text(widget.noneLabel ?? l.commonNone),
                      trailing: widget.selected == null
                          ? const Icon(Icons.check)
                          : null,
                      onTap: () => widget.onPick(null),
                    ),
                  if (matches.isEmpty && !_offersCreate)
                    ListTile(
                      enabled: false,
                      title: Text(widget.emptyLabel ?? l.categorySearchEmpty),
                    ),
                  for (final item in matches)
                    ListTile(
                      title: Text(widget.label(item)),
                      trailing:
                          widget.trailingBuilder?.call(context, item) ??
                          (widget.label(item) == widget.selected
                              ? const Icon(Icons.check)
                              : null),
                      onTap: () => widget.onPick(item),
                    ),
                  if (_offersCreate)
                    ListTile(
                      leading: _creating
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add),
                      title: Text(l.categoryCreate(_query.text.trim())),
                      subtitle: widget.createSubtitle == null
                          ? null
                          : Text(widget.createSubtitle!(_query.text.trim())),
                      onTap: _creating ? null : _create,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
