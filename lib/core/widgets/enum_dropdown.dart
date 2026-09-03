import 'package:flutter/material.dart';

/// Dropdown entries for [values], always including one for [selected].
///
/// A [DropdownButtonFormField] asserts that exactly one of its items carries
/// its value, and throws the whole form away when none does. That is easy to
/// hit whenever the value comes from the server and the items are a constant
/// list compiled into the app: a payment method, account type or asset type
/// this build has never heard of, or a list that has not loaded yet.
///
/// So an unrecognised [selected] is carried as an extra entry at the top,
/// showing its raw value -- a label function is only asked about values the
/// app knows, and inventing a name for one it does not would be a lie. The
/// user sees what the record actually holds and can pick something else,
/// which beats a screen that will not open.
List<DropdownMenuItem<String>> dropdownItemsFor(
  Iterable<String> values,
  String selected, {
  String Function(String value)? label,
}) {
  final items = [
    for (final value in values)
      DropdownMenuItem(
        value: value,
        child: Text(label?.call(value) ?? value),
      ),
  ];
  if (!values.contains(selected)) {
    items.insert(
      0,
      DropdownMenuItem(value: selected, child: Text(selected)),
    );
  }
  return items;
}
