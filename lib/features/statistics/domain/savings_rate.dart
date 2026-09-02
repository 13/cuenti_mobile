/// The share of [income] that was not spent, as a percentage.
///
/// Known in German as the *Sparquote*. Negative when more went out than
/// came in, which is the point: a month in the red should read as one
/// rather than being clamped to zero.
///
/// Null when [income] is not positive. With nothing earned there is no
/// denominator, and "0 %" would claim the user saved none of something
/// they never had.
double? savingsRate({required double income, required double expense}) {
  if (income <= 0) return null;
  return (income - expense) / income * 100;
}
