import 'package:cuentimobile/core/theme/app_theme.dart';
import 'package:cuentimobile/core/theme/cuenti_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// WCAG relative-luminance contrast ratio.
double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  final light = AppTheme.light();
  final dark = AppTheme.dark();

  test('body text meets WCAG 4.5:1 in both modes', () {
    for (final t in [light, dark]) {
      final cs = t.colorScheme;
      expect(contrast(cs.onSurface, cs.surface), greaterThanOrEqualTo(4.5));
      expect(contrast(cs.onPrimary, cs.primary), greaterThanOrEqualTo(4.5));
      expect(
          contrast(cs.onSurfaceVariant, cs.surface), greaterThanOrEqualTo(4.5));
    }
  });

  test('semantic tokens present with 3:1 contrast vs surface', () {
    for (final t in [light, dark]) {
      final c = t.extension<CuentiColors>()!;
      final surface = t.colorScheme.surface;
      expect(contrast(c.income, surface), greaterThanOrEqualTo(3.0));
      expect(contrast(c.expense, surface), greaterThanOrEqualTo(3.0));
      expect(c.chartPalette.length, 6);
    }
  });

  test('Manrope is the theme font', () {
    expect(light.textTheme.bodyMedium!.fontFamily, 'Manrope');
    expect(dark.textTheme.titleLarge!.fontFamily, 'Manrope');
  });

  test('brand anchors', () {
    // Brief specified 0xFF0E8A6B; adjusted to 0xFF0D8467 (minimal HSL
    // darkening) so onPrimary (white) reaches WCAG 4.5:1 — see
    // AppTheme._seed comment and task report for detail.
    expect(light.colorScheme.primary, const Color(0xFF0D8467));
    expect(light.scaffoldBackgroundColor, const Color(0xFFF7F9F8));
    expect(dark.scaffoldBackgroundColor, const Color(0xFF0E1513));
  });
}
