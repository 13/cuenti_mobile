// test/features/transactions/transaction_sync_test.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:cuentimobile/core/api/api_client.dart';
import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:cuentimobile/core/storage/secure_storage.dart';
import 'package:cuentimobile/features/transactions/data/transaction_outbox.dart';
import 'package:cuentimobile/features/transactions/data/transaction_sync.dart';
import 'package:cuentimobile/features/transactions/data/transactions_repository.dart';
import 'package:cuentimobile/features/transactions/domain/pending_transaction.dart';
import 'package:cuentimobile/features/transactions/domain/transaction.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTransactionsRepository extends Mock
    implements TransactionsRepository {}

class _MemoryStorage extends SecureStorage {
  _MemoryStorage() : super();
  final Map<String, String> _data = {};
  @override
  Future<String?> read(String key) async => _data[key];
  @override
  Future<void> write(String key, String value) async => _data[key] = value;
  @override
  Future<void> delete(String key) async => _data.remove(key);
}

/// Records what a request was addressed to and then fails the way a
/// request that never reached a server does -- which is what
/// `DioExceptionType.unknown` is, and what an unset base URL produced.
class _UnansweredAdapter implements HttpClientAdapter {
  final uris = <Uri>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    uris.add(options.uri);
    throw DioException(
      requestOptions: options,
      error: 'no answer',
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late Directory dir;
  late TransactionOutbox outbox;
  late MockTransactionsRepository repo;
  late TransactionSync sync;

  setUpAll(
    () => registerFallbackValue(
      Transaction(amount: 0, transactionDate: DateTime(2026)),
    ),
  );

  setUp(() {
    dir = Directory.systemTemp.createTempSync('sync_test');
    outbox = TransactionOutbox(dir);
    repo = MockTransactionsRepository();
    sync = TransactionSync(outbox, repo);
  });

  tearDown(() => dir.deleteSync(recursive: true));

  Future<void> queue(
    String id, {
    int minute = 0,
    PendingOperation operation = PendingOperation.create,
    int? transactionId,
  }) => outbox.add(
    PendingTransaction(
      localId: id,
      operation: operation,
      transaction: Transaction(
        id: transactionId,
        amount: 1,
        transactionDate: DateTime(2026, 9, 4),
      ),
      queuedAt: DateTime(2026, 9, 4, 10, minute),
    ),
  );

  test('a delivered entry leaves the queue', () async {
    when(
      () => repo.save(any(), splitsTouched: any(named: 'splitsTouched')),
    ).thenAnswer((i) async => i.positionalArguments.first as Transaction);
    await queue('a');

    expect(await sync.drain(), 1);
    expect(await outbox.all(), isEmpty);
  });

  test(
    'two drains running at once send one queued entry exactly once',
    () async {
      var saves = 0;
      when(
        () => repo.save(any(), splitsTouched: any(named: 'splitsTouched')),
      ).thenAnswer((i) async {
        saves++;
        // A real send is not instant, and the overlap is the whole point:
        // reconnect-then-pull-to-refresh is an ordinary gesture.
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return i.positionalArguments.first as Transaction;
      });
      await queue('a');

      final counts = await Future.wait([sync.drain(), sync.drain()]);

      expect(saves, 1, reason: 'a duplicate on the server, invisible here');
      expect(await outbox.all(), isEmpty);
      expect(counts, [1, 1]);
    },
  );

  test('a delete entry is sent as a delete', () async {
    when(() => repo.delete(any())).thenAnswer((_) async {});
    await queue('a', operation: PendingOperation.delete, transactionId: 7);

    await sync.drain();

    verify(() => repo.delete(7)).called(1);
  });

  test('still offline stops the run and keeps everything queued', () async {
    when(
      () => repo.save(any(), splitsTouched: any(named: 'splitsTouched')),
    ).thenThrow(const NetworkException('Cannot connect to server'));
    await queue('a');
    await queue('b', minute: 1);

    expect(await sync.drain(), 0);

    final left = await outbox.all();
    expect(left, hasLength(2));
    expect(
      left.every((e) => !e.isRejected),
      isTrue,
      reason: 'still offline means untried, not refused',
    );
    verify(
      () => repo.save(any(), splitsTouched: any(named: 'splitsTouched')),
    ).called(1);
  });

  test('a refusal marks that entry and the run carries on to the next: one '
      'bad entry must not hold up the rest', () async {
    var calls = 0;
    when(
      () => repo.save(any(), splitsTouched: any(named: 'splitsTouched')),
    ).thenAnswer((i) async {
      calls++;
      if (calls == 1) {
        throw const ValidationException(
          'Account is closed',
          serverMessage: 'Account is closed',
        );
      }
      return i.positionalArguments.first as Transaction;
    });
    await queue('bad');
    await queue('good', minute: 1);

    expect(await sync.drain(), 1);

    final left = await outbox.all();
    expect(left.single.localId, 'bad');
    expect(left.single.rejection, 'Account is closed');
  });

  test('a refusal stores the server own words, not the English half', () async {
    when(
      () => repo.save(any(), splitsTouched: any(named: 'splitsTouched')),
    ).thenThrow(
      const ValidationException(
        'Amount must be positive',
        serverMessage: 'Amount must be positive',
        statusCode: 422,
      ),
    );
    await queue('a');

    await sync.drain();

    final all = await outbox.all();
    expect(all.single.rejection, 'Amount must be positive');
  });

  test('a refusal with no server body stores an empty reason, and the '
      'entry is still refused', () async {
    when(
      () => repo.save(any(), splitsTouched: any(named: 'splitsTouched')),
    ).thenThrow(const ValidationException('Invalid request'));
    await queue('a');

    await sync.drain();

    final all = await outbox.all();
    expect(all.single.rejection, '');
    expect(all.single.isRejected, isTrue);
  });

  test('an entry already refused is not tried again on the next run', () async {
    when(
      () => repo.save(any(), splitsTouched: any(named: 'splitsTouched')),
    ).thenAnswer((i) async => i.positionalArguments.first as Transaction);
    await outbox.add(
      PendingTransaction(
        localId: 'refused',
        operation: PendingOperation.create,
        transaction: Transaction(
          amount: 1,
          transactionDate: DateTime(2026, 9, 4),
        ),
        queuedAt: DateTime(2026, 9, 4, 10),
        rejection: 'Account is closed',
      ),
    );

    expect(await sync.drain(), 0);
    verifyNever(
      () => repo.save(any(), splitsTouched: any(named: 'splitsTouched')),
    );
  });

  test(
    'a session that expired mid-queue stops the run rather than marking '
    'every entry refused: the credential was refused, not the entry',
    () async {
      when(
        () => repo.save(any(), splitsTouched: any(named: 'splitsTouched')),
      ).thenThrow(const UnauthorizedException('Not authenticated'));
      await queue('a');
      await queue('b', minute: 1);

      expect(await sync.drain(), 0);

      final left = await outbox.all();
      expect(left, hasLength(2));
      expect(
        left.every((e) => !e.isRejected),
        isTrue,
        reason:
            'nothing retries a refused entry automatically, so "Refused: Not '
            'authenticated" on the whole queue would be permanent',
      );
      verify(
        () => repo.save(any(), splitsTouched: any(named: 'splitsTouched')),
      ).called(1);
    },
  );

  test('a request that got no answer at all is not a refusal either', () async {
    when(
      () => repo.save(any(), splitsTouched: any(named: 'splitsTouched')),
    ).thenThrow(const UnknownApiException('An error occurred'));
    await queue('a');

    expect(await sync.drain(), 0);
    expect((await outbox.all()).single.isRejected, isFalse);
  });

  test('a failure writing the outbox after a send does not abandon the rest '
      'of the queue', () async {
    when(
      () => repo.save(any(), splitsTouched: any(named: 'splitsTouched')),
    ).thenAnswer((i) async => i.positionalArguments.first as Transaction);
    await queue('a');
    await queue('b', minute: 1);
    // The store goes away between the read and the bookkeeping, which is
    // what an unwritable file or a vanished directory looks like here.
    final brittle = TransactionSync(_BrokenWriteOutbox(dir), repo);

    expect(await brittle.drain(), 2, reason: 'both were actually sent');
    verify(
      () => repo.save(any(), splitsTouched: any(named: 'splitsTouched')),
    ).called(2);
  });

  group('a drain that goes out before ApiClient.init() has run', () {
    test('addresses the configured server and marks nothing refused', () async {
      // The client the app builds, with init() deliberately not called --
      // the app-start race this reproduces.
      final client = ApiClient(_MemoryStorage());
      final adapter = _UnansweredAdapter();
      client.dio.httpClientAdapter = adapter;
      final startup = TransactionSync(
        outbox,
        TransactionsRepository(client.dio),
      );
      await queue('a');

      expect(await startup.drain(), 0);

      expect(
        adapter.uris.single.toString(),
        startsWith('${ApiClient.defaultServerUrl}/api'),
        reason: 'RequestOptions captures the base URL as it composes',
      );
      expect(
        (await outbox.all()).single.isRejected,
        isFalse,
        reason:
            'a falsely-refused entry is skipped by every later drain, so one '
            'app start would poison the queue against the reconnect and '
            'refresh triggers for good',
      );
    });
  });

  test('replays the splits flag as it was recorded, since an empty list '
      'under a true flag means delete them all', () async {
    final sent = <bool>[];
    when(
      () => repo.save(any(), splitsTouched: any(named: 'splitsTouched')),
    ).thenAnswer((i) async {
      sent.add(i.namedArguments[#splitsTouched] as bool);
      return i.positionalArguments.first as Transaction;
    });
    await outbox.add(
      PendingTransaction(
        localId: 'a',
        operation: PendingOperation.update,
        transaction: Transaction(
          id: 3,
          amount: 1,
          transactionDate: DateTime(2026, 9, 4),
        ),
        queuedAt: DateTime(2026, 9, 4, 10),
      ),
    );

    await sync.drain();

    expect(sent, [false], reason: 'not touched, so not sent');
  });

  test('replays a true splits flag too, since an offline edit that did '
      'manage splits must not sync as if it never touched them', () async {
    final sent = <bool>[];
    when(
      () => repo.save(any(), splitsTouched: any(named: 'splitsTouched')),
    ).thenAnswer((i) async {
      sent.add(i.namedArguments[#splitsTouched] as bool);
      return i.positionalArguments.first as Transaction;
    });
    await outbox.add(
      PendingTransaction(
        localId: 'a',
        operation: PendingOperation.update,
        transaction: Transaction(
          id: 3,
          amount: 1,
          transactionDate: DateTime(2026, 9, 4),
        ),
        queuedAt: DateTime(2026, 9, 4, 10),
        splitsTouched: true,
      ),
    );

    await sync.drain();

    expect(sent, [true], reason: 'touched, so sent as touched');
  });
}

/// An outbox whose post-send bookkeeping always fails.
class _BrokenWriteOutbox extends TransactionOutbox {
  _BrokenWriteOutbox(super._directory);

  @override
  Future<void> remove(String localId) async =>
      throw const FileSystemException('read-only file system');

  @override
  Future<void> markRejected(String localId, String reason) async =>
      throw const FileSystemException('read-only file system');
}
