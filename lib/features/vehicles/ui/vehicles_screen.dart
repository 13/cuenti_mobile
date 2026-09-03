import 'package:cuentimobile/core/widgets/async_value_widget.dart';
import 'package:cuentimobile/core/widgets/empty_state.dart';
import 'package:cuentimobile/core/widgets/feedback_snack.dart';
import 'package:cuentimobile/core/widgets/section_header.dart';
import 'package:cuentimobile/core/widgets/skeleton_loader.dart';
import 'package:cuentimobile/features/auth/ui/auth_controller.dart';
import 'package:cuentimobile/features/categories/domain/category.dart';
import 'package:cuentimobile/features/categories/ui/categories_controller.dart';
import 'package:cuentimobile/features/categories/ui/category_picker_field.dart';
import 'package:cuentimobile/features/user/data/user_repository.dart';
import 'package:cuentimobile/features/vehicles/domain/vehicle_report.dart';
import 'package:cuentimobile/features/vehicles/ui/vehicles_controller.dart';
import 'package:cuentimobile/features/vehicles/ui/widgets/vehicle_report_parts.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class VehiclesScreen extends ConsumerStatefulWidget {
  const VehiclesScreen({super.key});

  @override
  ConsumerState<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends ConsumerState<VehiclesScreen> {
  int? _categoryId;
  late DateTime _start;
  late DateTime _end;

  @override
  void initState() {
    super.initState();
    _categoryId = ref
        .read(authControllerProvider)
        .user
        ?.defaultVehicleCategoryId;
    final now = DateTime.now();
    _start = DateTime(now.year);
    _end = DateTime(now.year, 12, 31);
  }

  bool get _isThisYear {
    final now = DateTime.now();
    return _start == DateTime(now.year) && _end == DateTime(now.year, 12, 31);
  }

  @override
  Widget build(BuildContext context) {
    final categoryId = _categoryId;
    if (categoryId == null) {
      return Center(
        child: EmptyState(
          icon: Icons.directions_car,
          message: L.of(context).vehiclesPickPrompt,
          actionLabel: L.of(context).vehiclesChooseCategory,
          onAction: () => _openCategorySheet(context),
        ),
      );
    }

    final reportProv = vehicleReportProvider(
      categoryId: categoryId,
      start: _start,
      end: _end,
    );
    final reportAsync = ref.watch(reportProv);

    return Column(
      children: [
        _buildChipsRow(context),
        const SizedBox(height: 4),
        Expanded(
          child: AsyncValueWidget<VehicleReport>(
            value: reportAsync,
            skeleton: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SkeletonLoader.card(height: 120),
                const SizedBox(height: 24),
                SkeletonLoader.card(height: 220),
                const SizedBox(height: 24),
                SkeletonLoader.tiles(),
              ],
            ),
            onRetry: () => ref.invalidate(reportProv),
            data: (report) => ListView(
              padding: const EdgeInsets.all(16),
              children: [
                VehicleStatCards(report: report),
                const SizedBox(height: 24),
                SectionHeader(L.of(context).vehiclesConsumption),
                const SizedBox(height: 8),
                ConsumptionChart(entries: report.entries),
                const SizedBox(height: 24),
                SectionHeader(L.of(context).vehiclesEntries),
                const SizedBox(height: 8),
                FuelEntriesList(
                  entries: report.entries,
                  currency: report.currency,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChipsRow(BuildContext context) {
    final categories = ref.watch(categoriesControllerProvider).value ?? [];
    final selected = _categoryById(categories, _categoryId);

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: [
          InputChip(
            avatar: const Icon(Icons.directions_car, size: 18),
            label: Text(
              selected != null
                  ? (selected.fullName ?? selected.name)
                  : 'Category',
            ),
            onPressed: () => _openCategorySheet(context),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: Text(L.of(context).vehiclesThisYear),
            selected: _isThisYear,
            onSelected: (v) {
              if (!v) return;
              final now = DateTime.now();
              setState(() {
                _start = DateTime(now.year);
                _end = DateTime(now.year, 12, 31);
              });
            },
          ),
          const SizedBox(width: 8),
          InputChip(
            avatar: const Icon(Icons.date_range_outlined, size: 18),
            label: Text(
              _isThisYear
                  ? L.of(context).vehiclesCustomRange
                  : '${_shortDate(_start)} – ${_shortDate(_end)}',
            ),
            onPressed: () => _pickCustomRange(context),
          ),
        ],
      ),
    );
  }

  String _shortDate(DateTime d) => DateFormat('d MMM yyyy').format(d);

  Category? _categoryById(List<Category> categories, int? id) {
    if (id == null) return null;
    for (final c in categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  Future<void> _pickCustomRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: DateTimeRange(start: _start, end: _end),
    );
    if (picked != null && mounted) {
      setState(() {
        _start = picked.start;
        _end = picked.end;
      });
    }
  }

  Future<void> _openCategorySheet(BuildContext context) async {
    // Await the provider rather than reading its current value: when the
    // screen is showing the no-category EmptyState nothing else has loaded
    // the categories yet, and a plain read would open an empty sheet with
    // no way to pick a fuel category.
    final expenseCategories = (await ref.read(
      categoriesControllerProvider.future,
    )).where((c) => c.type == 'EXPENSE').toList();
    if (!context.mounted) return;
    final choice = await showCategorySearchSheet(
      context,
      categories: expenseCategories,
      selectedId: _categoryId,
      allowNone: false,
      title: L.of(context).vehiclesFuelCategory,
      trailingBuilder: (ctx, c) => Consumer(
        builder: (ctx, ref, _) {
          final isDefault =
              ref
                  .watch(authControllerProvider)
                  .user
                  ?.defaultVehicleCategoryId ==
              c.id;
          return IconButton(
            icon: Icon(
              isDefault ? Icons.star : Icons.star_border,
              color: isDefault ? Theme.of(ctx).colorScheme.primary : null,
            ),
            tooltip: L.of(context).vehiclesSetDefault,
            onPressed: () async {
              final success = await _setDefaultCategory(ctx, c.id!);
              // Also select the starred category for the current view: close
              // the sheet returning its id so _categoryId updates and the
              // EmptyState doesn't linger after setting a default. Skip on
              // failure so the sheet stays open and the user can retry.
              if (success && ctx.mounted) {
                Navigator.pop(ctx, CategoryChoice(c.id));
              }
            },
          );
        },
      ),
    );
    if (choice == null || !mounted) return;
    setState(() => _categoryId = choice.categoryId);
  }

  /// Returns whether the update succeeded, so the caller can decide whether
  /// it's safe to pop the sheet with the newly-starred selection.
  Future<bool> _setDefaultCategory(BuildContext context, int id) async {
    // `context` is the sheet's, not this State's: the sheet can be dismissed
    // while the request is in flight, so the messenger and the message are
    // read before the await.
    final messenger = ScaffoldMessenger.of(context);
    final saved = L.of(context).vehiclesDefaultSaved;
    final ok = await reportingFailure(context, () async {
      await ref.read(userRepositoryProvider).updatePreferences({
        'defaultVehicleCategoryId': id,
      });
      await ref.read(authControllerProvider.notifier).refreshProfile();
    });
    if (ok) messenger.showSnackBar(SnackBar(content: Text(saved)));
    return ok;
  }
}
