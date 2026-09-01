import 'package:cuentimobile/features/categories/domain/category.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:cuentimobile/utils/token_search.dart';
import 'package:flutter/material.dart';

/// The path a category is shown and searched by: the full `Parent:Child`
/// path when the backend supplied one, the bare name otherwise.
String categoryLabel(Category category) => category.fullName ?? category.name;

/// Case-insensitive filter over [categoryLabel]. Every whitespace-separated
/// token of [query] must occur somewhere in the label, so `food groc` finds
/// `Food:Groceries` without the user typing the separator. A blank query
/// matches everything.
List<Category> filterCategories(List<Category> categories, String query) =>
    categories.where((c) => matchesAllTokens(categoryLabel(c), query)).toList();

/// Builds the trailing widget for one row, letting a caller hang a per-row
/// action (a "set as default" star, say) off the shared sheet. When given, it
/// replaces the selected-row check mark, so include one if selection still
/// needs to read.
typedef CategoryTrailingBuilder =
    Widget? Function(BuildContext context, Category category);

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
  String? title,
  String? noneLabel,
  CategoryTrailingBuilder? trailingBuilder,
}) {
  return showModalBottomSheet<CategoryChoice>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => CategorySearchSheet(
      categories: categories,
      selectedId: selectedId,
      allowNone: allowNone,
      title: title ?? L.of(context).categoryLabel,
      noneLabel: noneLabel ?? L.of(context).commonNone,
      trailingBuilder: trailingBuilder,
    ),
  );
}

/// Search field over a scrollable list of categories. Pops with a
/// [CategoryChoice] as soon as the user taps an entry.
class CategorySearchSheet extends StatefulWidget {
  const CategorySearchSheet({
    required this.categories,
    required this.selectedId,
    required this.allowNone,
    required this.title,
    super.key,
    this.noneLabel = 'None',
    this.trailingBuilder,
  });

  final List<Category> categories;
  final int? selectedId;
  final bool allowNone;
  final String title;
  final String noneLabel;
  final CategoryTrailingBuilder? trailingBuilder;

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
                  hintText: L
                      .of(context)
                      .categorySearchHint(
                        widget.title.toLowerCase(),
                      ),
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                  suffixIcon: _query.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          tooltip: L.of(context).categorySearchClear,
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
                      title: Text(widget.noneLabel),
                      trailing: widget.selectedId == null
                          ? const Icon(Icons.check)
                          : null,
                      onTap: () => _pick(null),
                    ),
                  if (matches.isEmpty)
                    ListTile(
                      enabled: false,
                      title: Text(L.of(context).categorySearchEmpty),
                    ),
                  for (final category in matches)
                    ListTile(
                      title: Text(categoryLabel(category)),
                      trailing:
                          widget.trailingBuilder?.call(context, category) ??
                          (category.id == widget.selectedId
                              ? const Icon(Icons.check)
                              : null),
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
    required this.categories,
    required this.selectedId,
    required this.onChanged,
    super.key,
    this.allowNone = true,
    this.isDense = false,
    this.labelText,
    this.placeholder,
    this.noneLabel,
    this.validator,
  });

  final List<Category> categories;

  /// Ids absent from [categories] render as unselected, so a category that
  /// the current transaction type filters out never shows a stale label.
  final int? selectedId;
  final ValueChanged<int?> onChanged;
  final bool allowNone;
  final bool isDense;
  final String? labelText;

  /// Shown on the field itself when nothing is selected.
  final String? placeholder;

  /// Label of the clear-the-selection entry inside the sheet. Filter-style
  /// pickers want "All", form-style pickers want "None". Null takes the
  /// localised default -- a const parameter cannot hold one.
  final String? noneLabel;

  /// Optional [FormField] validator, so the picker takes part in an
  /// enclosing [Form] the way the dropdown it replaces did.
  final String? Function(int?)? validator;

  Category? get _selected {
    for (final category in categories) {
      if (category.id == selectedId) return category;
    }
    return null;
  }

  Future<void> _open(
    BuildContext context,
    FormFieldState<int?> field,
  ) async {
    final selected = _selected;
    final choice = await showCategorySearchSheet(
      context,
      categories: categories,
      selectedId: selected?.id,
      allowNone: allowNone,
      title: labelText ?? L.of(context).categoryLabel,
      noneLabel: noneLabel,
    );
    if (choice == null) return;
    // Tell the FormField as well as the parent, so an enclosing Form
    // revalidates against what the user just picked.
    field.didChange(choice.categoryId);
    onChanged(choice.categoryId);
  }

  @override
  Widget build(BuildContext context) {
    return FormField<int?>(
      initialValue: selectedId,
      validator: validator,
      builder: (field) => _build(context, field),
    );
  }

  Widget _build(BuildContext context, FormFieldState<int?> field) {
    final selected = _selected;
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => _open(context, field),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: labelText ?? L.of(context).categoryLabel,
          border: const OutlineInputBorder(),
          isDense: isDense,
          errorText: field.errorText,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                selected == null
                    ? (placeholder ?? L.of(context).commonNone)
                    : categoryLabel(selected),
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
