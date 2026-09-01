import 'package:cuentimobile/features/vehicles/domain/fuel_advice.dart';
import 'package:cuentimobile/features/vehicles/domain/fuel_memo.dart';
import 'package:cuentimobile/utils/number_format.dart';
import 'package:flutter/material.dart';

/// Structured tanking fields shown when the chosen category records fuel.
///
/// Owns no state: the dialog holds the controllers and the full-tank flag
/// because they are mirrored into the memo text, and this widget only
/// renders them plus the advice derived in [fuelInfoLine].
class FuelEntrySection extends StatelessWidget {
  const FuelEntrySection({
    required this.odometer,
    required this.liters,
    required this.fullTank,
    required this.baseline,
    required this.onFieldChanged,
    required this.onFullTankChanged,
    super.key,
  });

  final TextEditingController odometer;
  final TextEditingController liters;
  final bool fullTank;

  /// Newest odometer reading before this transaction, or null when there is
  /// nothing to compare against.
  final double? baseline;
  final VoidCallback onFieldChanged;
  final ValueChanged<bool> onFullTankChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final info = fuelInfoLine(
      odometer: parseFuelInput(odometer.text),
      lastOdometer: baseline,
      liters: parseFuelInput(liters.text),
      fullTank: fullTank,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                key: const Key('fuel-odometer'),
                controller: odometer,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Odometer (km)',
                  border: const OutlineInputBorder(),
                  helperText: baseline != null
                      ? 'last: ${formatFuelNumber(baseline!)}'
                      : null,
                ),
                onChanged: (_) => onFieldChanged(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                key: const Key('fuel-liters'),
                controller: liters,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Liters',
                  border: const OutlineInputBorder(),
                  helperText: fuelLitersWarning(
                    parseFuelInput(liters.text),
                  ),
                  helperStyle: TextStyle(color: colors.error),
                ),
                onChanged: (_) => onFieldChanged(),
              ),
            ),
          ],
        ),
        if (info case (final message, final isWarning))
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              message,
              key: const Key('fuel-info'),
              style: TextStyle(
                color: isWarning ? colors.error : colors.primary,
              ),
            ),
          ),
        SwitchListTile(
          key: const Key('fuel-full'),
          contentPadding: EdgeInsets.zero,
          title: const Text('Full tank'),
          value: fullTank,
          onChanged: onFullTankChanged,
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
