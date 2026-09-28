import 'dart:convert';
import 'dart:typed_data';

import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:cuentimobile/features/transactions/data/transactions_repository.dart';
import 'package:cuentimobile/features/transactions/domain/pending_transaction.dart';
import 'package:cuentimobile/features/transactions/domain/transaction.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records the request and answers with [status] and [body].
class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter(this.status, this.body);

  final int status;
  final Object body;
  RequestOptions? request;
  Object? sent;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    sent = options.data;
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

PendingTransaction _entry(
  String localId,
  PendingOperation op, {
  int? id,
  String? version,
  double amount = 1,
}) => PendingTransaction(
  localId: localId,
  operation: op,
  transaction: Transaction(
    id: id,
    amount: amount,
    transactionDate: DateTime(2026, 9, 4),
    version: version,
  ),
  queuedAt: DateTime(2026, 9, 4, 10),
);

void main() {
  TransactionsRepository repoWith(_RecordingAdapter adapter) =>
      TransactionsRepository(
        Dio(BaseOptions(baseUrl: 'https://cuenti.test/api'))
          ..httpClientAdapter = adapter,
      );

  test('each queued write goes as the operation its own request would '
      'have been, with the same idempotency and version', () async {
    final adapter = _RecordingAdapter(200, {'results': <Object>[]});
    final create = _entry('local-1', PendingOperation.create);
    final update = _entry(
      'local-2',
      PendingOperation.update,
      id: 5,
      version: 'v5',
    );
    final delete = _entry(
      'local-3',
      PendingOperation.delete,
      id: 6,
      version: 'v6',
    );

    await repoWith(adapter).sendBatch([create, update, delete]);

    expect(adapter.request!.path, '/transactions/batch');
    final ops = ((adapter.sent! as Map)['operations'] as List)
        .cast<Map<String, dynamic>>();
    expect(ops.map((o) => o['op']), ['CREATE', 'UPDATE', 'DELETE']);
    expect(ops[0]['clientId'], 'local-1');
    expect(ops[0]['idempotencyKey'], 'local-1');
    expect(
      ops[0]['transaction'],
      TransactionsRepository.payloadFor(
        create.transaction,
        splitsTouched: false,
      ),
      reason: 'the same body save() sends',
    );
    expect(ops[1]['id'], 5);
    expect(ops[1]['version'], 'v5');
    expect(
      ops[1]['idempotencyKey'],
      TransactionsRepository.updateKeyFor(update),
    );
    expect(ops[2]['id'], 6);
    expect(ops[2]['version'], 'v6');
    expect(ops[2].containsKey('transaction'), isFalse);
  });

  test('results come back per entry', () async {
    final adapter = _RecordingAdapter(200, {
      'results': [
        {
          'clientId': 'local-1',
          'status': 200,
          'transaction': <String, Object>{},
        },
        {'clientId': 'local-2', 'status': 409, 'error': 'Changed'},
      ],
    });

    final results = await repoWith(adapter).sendBatch([
      _entry('local-1', PendingOperation.create),
      _entry('local-2', PendingOperation.update, id: 2),
    ]);

    expect(results.map((r) => (r.clientId, r.status, r.error)), [
      ('local-1', 200, null),
      ('local-2', 409, 'Changed'),
    ]);
  });

  test('a server without the endpoint fails the call with its status, for '
      'the drain to fall back on', () async {
    final adapter = _RecordingAdapter(405, {'error': 'Method Not Allowed'});

    await expectLater(
      repoWith(adapter).sendBatch([_entry('local-1', PendingOperation.create)]),
      throwsA(
        isA<ValidationException>().having((e) => e.statusCode, 'status', 405),
      ),
    );
  });

  test('an answer that is not batch results -- a catch-all page -- fails '
      'with no status, which the drain reads as no batch support', () async {
    final adapter = _RecordingAdapter(200, '<html>app</html>');

    await expectLater(
      repoWith(adapter).sendBatch([_entry('local-1', PendingOperation.create)]),
      throwsA(
        isA<ServerException>().having((e) => e.statusCode, 'status', isNull),
      ),
    );
  });

  group('the key a queued update is sent with', () {
    test('is the same for a resend of the same update', () {
      final a = _entry('local-1', PendingOperation.update, id: 1, version: 'v');
      final b = _entry('local-1', PendingOperation.update, id: 1, version: 'v');

      expect(
        TransactionsRepository.updateKeyFor(a),
        TransactionsRepository.updateKeyFor(b),
      );
    });

    test('changes when the queued update is edited, so the edit is not '
        "answered with the earlier version's result", () {
      final a = _entry('local-1', PendingOperation.update, id: 1, version: 'v');
      final b = _entry(
        'local-1',
        PendingOperation.update,
        id: 1,
        version: 'v',
        amount: 2,
      );

      expect(
        TransactionsRepository.updateKeyFor(a),
        isNot(TransactionsRepository.updateKeyFor(b)),
      );
    });

    test('fits the length the server accepts', () {
      final e = _entry(
        'local-${DateTime(2099).microsecondsSinceEpoch}-999999',
        PendingOperation.update,
        id: 1,
      );

      expect(
        TransactionsRepository.updateKeyFor(e).length,
        lessThanOrEqualTo(100),
      );
    });
  });
}
