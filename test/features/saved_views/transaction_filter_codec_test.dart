import 'package:cuentimobile/features/transactions/domain/transaction_filter.dart';
import 'package:cuentimobile/features/transactions/domain/transaction_filter_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TransactionFilterCodec', () {
    test('round-trips a fully populated filter', () {
      final filter = TransactionFilter(
        accountId: 3,
        type: 'EXPENSE',
        categoryId: 7,
        start: DateTime(2026, 1, 1),
        end: DateTime(2026, 1, 31),
        search: 'coffee',
      );

      final encoded = TransactionFilterCodec.encode(filter);
      final decoded = TransactionFilterCodec.decode(encoded);

      expect(decoded, filter);
    });

    test('round-trips the default (empty) filter', () {
      const filter = TransactionFilter();

      final encoded = TransactionFilterCodec.encode(filter);
      final decoded = TransactionFilterCodec.decode(encoded);

      expect(decoded, filter);
    });

    test('decode returns null for foreign (web app) params format', () {
      expect(TransactionFilterCodec.decode('{"someWebFormat":true}'), isNull);
    });

    test('decode returns null for invalid JSON', () {
      expect(TransactionFilterCodec.decode('not json'), isNull);
    });

    test('decode returns null for empty string', () {
      expect(TransactionFilterCodec.decode(''), isNull);
    });

    test('decode returns null for null input', () {
      expect(TransactionFilterCodec.decode(null), isNull);
    });

    test('decode returns null for an unsupported version envelope', () {
      expect(
        TransactionFilterCodec.decode('{"v":2,"accountId":1}'),
        isNull,
      );
    });
  });
}
