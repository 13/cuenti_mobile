import 'package:flutter/material.dart';

/// Brand-semantic colors the Material ColorScheme has no roles for.
/// Widgets access these via `context.cuentiColors` — never raw hex.
class CuentiColors extends ThemeExtension<CuentiColors> {
  const CuentiColors({
    required this.income,
    required this.expense,
    required this.transfer,
    required this.heroGradient,
    required this.chartPalette,
  });

  final Color income;
  final Color expense;
  final Color transfer;
  final Gradient heroGradient;
  final List<Color> chartPalette;

  static const light = CuentiColors(
    income: Color(0xFF1E9E63),
    expense: Color(0xFFD64545),
    transfer: Color(0xFF5B7286),
    heroGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF12A57F), Color(0xFF0A5C4A)],
    ),
    chartPalette: [
      Color(0xFF0D8467), // teal (brand) — matches AppTheme._seed
      Color(0xFFB9821D), // amber
      Color(0xFF4F63C2), // indigo
      Color(0xFFC25B4F), // coral
      Color(0xFF2793A8), // cyan
      Color(0xFF8A5BA6), // purple
    ],
  );

  static const dark = CuentiColors(
    income: Color(0xFF5CC894),
    expense: Color(0xFFF07575),
    transfer: Color(0xFF8FA6BA),
    heroGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF0F8065), Color(0xFF07443A)],
    ),
    chartPalette: [
      Color(0xFF3FB392), // teal
      Color(0xFFD9A94A), // amber
      Color(0xFF8B9BE0), // indigo
      Color(0xFFE08A80), // coral
      Color(0xFF5BB8CC), // cyan
      Color(0xFFB78CD1), // purple
    ],
  );

  @override
  CuentiColors copyWith({
    Color? income,
    Color? expense,
    Color? transfer,
    Gradient? heroGradient,
    List<Color>? chartPalette,
  }) {
    return CuentiColors(
      income: income ?? this.income,
      expense: expense ?? this.expense,
      transfer: transfer ?? this.transfer,
      heroGradient: heroGradient ?? this.heroGradient,
      chartPalette: chartPalette ?? this.chartPalette,
    );
  }

  @override
  CuentiColors lerp(CuentiColors? other, double t) {
    if (other == null) return this;
    return CuentiColors(
      income: Color.lerp(income, other.income, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      transfer: Color.lerp(transfer, other.transfer, t)!,
      heroGradient: Gradient.lerp(heroGradient, other.heroGradient, t)!,
      chartPalette: [
        for (var i = 0; i < chartPalette.length; i++)
          Color.lerp(chartPalette[i], other.chartPalette[i], t)!,
      ],
    );
  }
}

extension CuentiColorsX on BuildContext {
  CuentiColors get cuentiColors => Theme.of(this).extension<CuentiColors>()!;
}

/// Semantic amount color for a transaction type string.
Color amountColorFor(BuildContext context, String type) {
  final c = context.cuentiColors;
  return switch (type) {
    'EXPENSE' => c.expense,
    'INCOME' => c.income,
    _ => c.transfer,
  };
}
