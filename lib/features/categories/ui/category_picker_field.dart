import 'package:flutter/material.dart';
import '../domain/category.dart';

/// The path a category is shown and searched by: the full `Parent:Child`
/// path when the backend supplied one, the bare name otherwise.
String categoryLabel(Category category) => category.fullName ?? category.name;

/// Case-insensitive filter over [categoryLabel]. Every whitespace-separated
/// token of [query] must occur somewhere in the label, so `food groc` finds
/// `Food:Groceries` without the user typing the separator. A blank query
/// matches everything.
List<Category> filterCategories(List<Category> categories, String query) {
  final tokens = query
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .toList();
  if (tokens.isEmpty) return categories;
  return categories.where((category) {
    final label = categoryLabel(category).toLowerCase();
    return tokens.every(label.contains);
  }).toList();
}

/// What the user picked in the sheet. Wrapping the id keeps "picked None"
/// (`categoryId == null`) distinct from "dismissed the sheet" (no choice).
class CategoryChoice {
  const CategoryChoice(this.categoryId);

  final int? categoryId;
}

/// Opens the searchable category picker. Resolves to null when the sheet is
/// dismissed without a choice, leaving the caller's selection untouched.
Future<CategoryChoice?> showCategorySearchSheet(
  BuildContext context, {
  required List<Category> categories,
  int? selectedId,
  bool allowNone = true,
  String title = 'Category',
}) {
  return showModalBottomSheet<CategoryChoice>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => CategorySearchSheet(
      categories: categories,
      selectedId: selectedId,
      allowNone: allowNone,
      title: title,
    ),
  );
}

/// Search field over a scrollable list of categories. Pops with a
/// [CategoryChoice] as soon as the user taps an entry.
class CategorySearchSheet extends StatefulWidget {
  const CategorySearchSheet({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.allowNone,
    required this.title,
  });

  final List<Category> categories;
  final int? selectedId;
  final bool allowNone;
  final String title;

  @override
  State<CategorySearchSheet> createState() => _CategorySearchSheetState();
}

class _CategorySearchSheetState extends State<CategorySearchSheet> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _pick(int? categoryId) =>
      Navigator.of(context).pop(CategoryChoice(categoryId));

  @override
  Widget build(BuildContext context) {
    final matches = filterCategories(widget.categories, _query.text);
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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _query,
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search ${widget.title.toLowerCase()}',
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                  suffixIcon: _query.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          tooltip: 'Clear search',
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
                  // the category stays one tap away mid-search.
                  if (widget.allowNone)
                    ListTile(
                      title: const Text('None'),
                      trailing: widget.selectedId == null
                          ? const Icon(Icons.check)
                          : null,
                      onTap: () => _pick(null),
                    ),
                  if (matches.isEmpty)
                    const ListTile(
                      enabled: false,
                      title: Text('No matching categories'),
                    ),
                  for (final category in matches)
                    ListTile(
                      title: Text(categoryLabel(category)),
                      trailing: category.id == widget.selectedId
                          ? const Icon(Icons.check)
                          : null,
                      onTap: () => _pick(category.id),
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

/// Form field that looks like the dropdown it replaces but opens
/// [showCategorySearchSheet] on tap. Reports a pick through [onChanged];
/// a dismissed sheet reports nothing.
class CategoryPickerField extends StatelessWidget {
  const CategoryPickerField({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onChanged,
    this.allowNone = true,
    this.isDense = false,
    this.labelText = 'Category',
    this.placeholder = 'None',
  });

  final List<Category> categories;

  /// Ids absent from [categories] render as unselected, so a category that
  /// the current transaction type filters out never shows a stale label.
  final int? selectedId;
  final ValueChanged<int?> onChanged;
  final bool allowNone;
  final bool isDense;
  final String labelText;
  final String placeholder;

  Category? get _selected {
    for (final category in categories) {
      if (category.id == selectedId) return category;
    }
    return null;
  }

  Future<void> _open(BuildContext context) async {
    final selected = _selected;
    final choice = await showCategorySearchSheet(
      context,
      categories: categories,
      selectedId: selected?.id,
      allowNone: allowNone,
      title: labelText,
    );
    if (choice != null) onChanged(choice.categoryId);
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => _open(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: labelText,
          border: const OutlineInputBorder(),
          isDense: isDense,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                selected == null ? placeholder : categoryLabel(selected),
                overflow: TextOverflow.ellipsis,
                style: selected == null
                    ? theme.textTheme.bodyLarge?.copyWith(
                        color: theme.hintColor,
                      )
                    : null,
              ),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}
