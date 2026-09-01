import 'package:cuentimobile/utils/number_format.dart';

/// One row of the splits editor, reduced to what validation needs.
typedef SplitEntry = ({int? categoryId, double? amount});

/// Null when the drafted splits are valid, otherwise the message to show
/// under the editor. The caller uses the same value to gate Save and to
/// render the banner, so the two can never disagree.
///
/// Null for TRANSFER as well, mirroring the section's visibility: an
/// invalid draft must not keep Save disabled after the user switches to a
/// type that hides the editor (the save path drops splits for TRANSFER
/// anyway).
String? splitsValidationMessage({
  required String type,
  required bool touched,
  required List<SplitEntry> splits,
  required double mainAmount,
}) {
  if (type == 'TRANSFER' || !touched || splits.isEmpty) return null;
  if (splits.any((s) => s.categoryId == null)) {
    return 'Each split needs a category';
  }
  final sum = splits.fold<double>(0, (acc, s) => acc + (s.amount ?? 0));
  if ((sum - mainAmount).abs() > 0.005) {
    return 'Splits must sum to the amount: '
        '${formatNumber(sum)} of ${formatNumber(mainAmount)}';
  }
  return null;
}
