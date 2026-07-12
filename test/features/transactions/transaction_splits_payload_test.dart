import 'package:cuentimobile/features/transactions/data/transactions_repository.dart';
import 'package:cuentimobile/features/transactions/domain/transaction.dart';
import 'package:cuentimobile/features/transactions/domain/transaction_split.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../../helpers/fake_dio.dart';

/// Backend contract (Phase 1): PUT/POST with `splits` key ABSENT leaves
/// existing splits untouched server-side; `splits: []` is a deliberate
/// remove-all; a non-empty list is a full replacement. These tests pin the
/// repository's `splitsTouched` flag semantics that produce those payloads.
void main() {
  late MockDio dio;
  late TransactionsRepository repo;

  setUp(() {
    dio = MockDio();
    repo = TransactionsRepository(dio);
  });

  test('splitsTouched: false (default) omits splits key even when non-empty',
      () async {
    final tx = Transaction(
      amount: 30,
      transactionDate: DateTime(2026, 1, 1),
      splits: const [
        TransactionSplit(categoryId: 1, amount: 10),
        TransactionSplit(categoryId: 2, amount: 20),
      ],
    );

    when(() => dio.post<Map<String, dynamic>>('/transactions',
            data: any(named: 'data')))
        .thenAnswer((_) async => ok({
              'id': 1,
              'type': 'EXPENSE',
              'amount': 30,
              'transactionDate': '2026-01-01T00:00:00.000',
            }));

    await repo.save(tx);

    final captured = verify(() => dio.post<Map<String, dynamic>>(
            '/transactions',
            data: captureAny(named: 'data')))
        .captured
        .single as Map<String, dynamic>;
    expect(captured.containsKey('splits'), isFalse);
  });

  test('splitsTouched: true with 2 splits sends exact list of maps',
      () async {
    final tx = Transaction(
      amount: 30,
      transactionDate: DateTime(2026, 1, 1),
      splits: const [
        TransactionSplit(categoryId: 1, amount: 10, memo: 'coffee'),
        TransactionSplit(categoryId: 2, amount: 20),
      ],
    );

    when(() => dio.post<Map<String, dynamic>>('/transactions',
            data: any(named: 'data')))
        .thenAnswer((_) async => ok({
              'id': 1,
              'type': 'EXPENSE',
              'amount': 30,
              'transactionDate': '2026-01-01T00:00:00.000',
            }));

    await repo.save(tx, splitsTouched: true);

    final captured = verify(() => dio.post<Map<String, dynamic>>(
            '/transactions',
            data: captureAny(named: 'data')))
        .captured
        .single as Map<String, dynamic>;
    expect(captured['splits'], [
      {'categoryId': 1, 'amount': 10.0, 'memo': 'coffee'},
      {'categoryId': 2, 'amount': 20.0},
    ]);
  });

  test('splitsTouched: true with empty list sends splits: [] (remove-all)',
      () async {
    final tx = Transaction(
      amount: 30,
      transactionDate: DateTime(2026, 1, 1),
    );

    when(() => dio.post<Map<String, dynamic>>('/transactions',
            data: any(named: 'data')))
        .thenAnswer((_) async => ok({
              'id': 1,
              'type': 'EXPENSE',
              'amount': 30,
              'transactionDate': '2026-01-01T00:00:00.000',
            }));

    await repo.save(tx, splitsTouched: true);

    final captured = verify(() => dio.post<Map<String, dynamic>>(
            '/transactions',
            data: captureAny(named: 'data')))
        .captured
        .single as Map<String, dynamic>;
    expect(captured.containsKey('splits'), isTrue);
    expect(captured['splits'], isEmpty);
  });
}
