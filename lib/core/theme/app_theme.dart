import 'package:flutter/material.dart';
import 'cuenti_colors.dart';

class AppTheme {
  // NOTE: adjusted from the brief's 0xFF0E8A6B — that raw seed paired with
  // the auto-generated white onPrimary yields only 4.32:1 contrast (fails
  // WCAG 4.5:1). Darkened minimally in HSL space (lightness -0.012, hue/sat
  // preserved) to 0xFF0D8467, giving 4.65:1. See task report for detail.
  static const _seed = Color(0xFF0D8467);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(seedColor: _seed).copyWith(
      primary: _seed,
      surface: Colors.white,
      onSurface: const Color(0xFF16211D),
      onSurfaceVariant: const Color(0xFF44534D),
      outlineVariant: const Color(0xFFDCE5E1),
      surfaceContainerHighest: const Color(0xFFEEF3F1),
    );
    return _base(scheme, CuentiColors.light)
        .copyWith(scaffoldBackgroundColor: const Color(0xFFF7F9F8));
  }

  static ThemeData dark() {
    final scheme =
        ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.dark)
            .copyWith(
      primary: const Color(0xFF3FB392),
      onPrimary: const Color(0xFF072A21),
      surface: const Color(0xFF16201C),
      onSurface: const Color(0xFFE5EDE9),
      onSurfaceVariant: const Color(0xFFA9BBB3),
      outlineVariant: const Color(0xFF2C3A34),
      surfaceContainerHighest: const Color(0xFF1D2925),
    );
    return _base(scheme, CuentiColors.dark)
        .copyWith(scaffoldBackgroundColor: const Color(0xFF0E1513));
  }

  static ThemeData _base(ColorScheme scheme, CuentiColors cuenti) {
    final textTheme = Typography.material2021(colorScheme: scheme)
        .englishLike
        .apply(
          fontFamily: 'Manrope',
          bodyColor: scheme.onSurface,
          displayColor: scheme.onSurface,
        );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: textTheme,
      extensions: [cuenti],
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        isDense: true,
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        showDragHandle: true,
        backgroundColor: scheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      splashFactory: InkSparkle.splashFactory,
    );
  }
}
