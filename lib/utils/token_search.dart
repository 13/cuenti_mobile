/// Whether [haystack] contains every whitespace-separated token of [query],
/// case-insensitively and in any order.
///
/// Lets a user type "food groc" to reach "Food:Groceries" without knowing
/// the separator, and "aral tank" to reach "Aral Tankstelle". A blank query
/// matches everything, so callers can pass the raw search field text.
bool matchesAllTokens(String haystack, String query) {
  final tokens = query
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty);
  if (tokens.isEmpty) return true;
  final lower = haystack.toLowerCase();
  return tokens.every(lower.contains);
}
