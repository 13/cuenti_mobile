import 'package:flutter/widgets.dart';

/// The language the app falls back to. English is the source the other
/// catalogues are translated from, so it is the one guaranteed complete.
const fallbackLocale = Locale('en');

/// Picks the closest supported locale, preferring an exact
/// language-and-region match, then the language alone, and otherwise
/// [fallbackLocale].
///
/// Worth stating explicitly rather than leaning on Flutter's default, which
/// falls back to the first entry of `supportedLocales` -- generated in
/// alphabetical order, so an unsupported device language would land on
/// German purely because "de" sorts before "en".
Locale resolveAppLocale(Locale? preferred, Iterable<Locale> supported) {
  if (preferred == null) return fallbackLocale;
  for (final locale in supported) {
    if (locale.languageCode == preferred.languageCode &&
        locale.countryCode == preferred.countryCode) {
      return locale;
    }
  }
  for (final locale in supported) {
    if (locale.languageCode == preferred.languageCode) return locale;
  }
  return fallbackLocale;
}
