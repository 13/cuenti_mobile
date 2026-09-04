import 'dart:io';

import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:cuentimobile/features/transactions/data/transaction_outbox.dart';
import 'package:cuentimobile/features/transactions/data/transaction_sync.dart';
import 'package:cuentimobile/features/transactions/data/transactions_repository.dart';
import 'package:cuentimobile/features/transactions/domain/transaction_filter.dart';
import 'package:cuentimobile/features/transactions/domain/transaction_page.dart';
import 'package:cuentimobile/features/transactions/ui/outbox_drain.dart';
import 'package:cuentimobile/features/transactions/ui/transactions_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockTransactionsRepository extends Mock
    implements TransactionsRepository {}

/// A drain that reports [delivered] entries sent, or fails outright.
class _StubSync implements TransactionSync {
  _StubSync({this.delivered = 0, this.fails = false});
  final int delivered;
  final bool fails;

  @override
  Future<int> drain() async {
    if (fails) throw const NetworkException('Cannot connect to server');
    return delivered;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _MockTransactionsRepository repo;
  late Directory outboxDir;

  setUpAll(() => registerFallbackValue(const TransactionFilter()));

  setUp(() {
    repo = _MockTransactionsRepository();
    outboxDir = Directory.systemTemp.createTempSync('drain_outbox');
    addTearDown(() => outboxDir.deleteSync(recursive: true));
    when(() => repo.getPage()).thenAnswer(
      (_) async => const TransactionPage(
        content: [],
        page: 0,
        size: 50,
        totalElements: 0,
        totalPages: 1,
      ),
    );
  });

  /// Watches the list the way a screen does, with a button that asks for a
  /// drain the way the refresh, reconnect and app-start triggers do.
  Future<void> pump(WidgetTester tester, TransactionSync sync) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionsRepositoryProvider.overrideWithValue(repo),
          transactionOutboxProvider.overrideWithValue(
            TransactionOutbox(outboxDir),
          ),
          transactionSyncProvider.overrideWithValue(sync),
        ],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) {
              ref.watch(transactionsControllerProvider());
              return TextButton(
                onPressed: () => drainOutbox(ref),
                child: const Text('drain'),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a drain that delivered something refreshes the list, so rows '
      'that have just been sent stop saying they have not been', (
    tester,
  ) async {
    await pump(tester, _StubSync(delivered: 1));
    verify(() => repo.getPage()).called(1);

    await tester.tap(find.text('drain'));
    await tester.pumpAndSettle();

    verify(() => repo.getPage()).called(1);
  });

  testWidgets('a drain that sent nothing costs no fetch', (tester) async {
    await pump(tester, _StubSync());
    verify(() => repo.getPage()).called(1);

    await tester.tap(find.text('drain'));
    await tester.pumpAndSettle();

    verifyNever(() => repo.getPage());
  });

  testWidgets('a drain that fails is not an unhandled error', (tester) async {
    await pump(tester, _StubSync(fails: true));

    await tester.tap(find.text('drain'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
