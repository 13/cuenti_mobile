import 'package:cuentimobile/utils/token_search.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('matchesAllTokens', () {
    test('matches a plain substring regardless of case', () {
      expect(matchesAllTokens('Food:Groceries', 'GROC'), isTrue);
    });

    test('requires every token to appear somewhere', () {
      expect(matchesAllTokens('Food:Groceries', 'food groc'), isTrue);
      expect(matchesAllTokens('Food:Groceries', 'food fuel'), isFalse);
    });

    test('ignores token order', () {
      expect(matchesAllTokens('Food:Groceries', 'groc food'), isTrue);
    });

    test('treats a blank query as matching everything', () {
      expect(matchesAllTokens('anything', '   '), isTrue);
      expect(matchesAllTokens('', ''), isTrue);
    });

    test('collapses repeated whitespace between tokens', () {
      expect(matchesAllTokens('Food:Groceries', 'food    groc'), isTrue);
    });
  });
}
