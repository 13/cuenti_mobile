// test/features/transactions/transaction_sync_test.dart
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cuentimobile/core/api/api_client.dart';
import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:cuentimobile/core/storage/secure_storage.dart';
import 'package:cuentimobile/features/transactions/data/outbox_ownership.dart';
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

/// The account every `sync` in this file drains for.
const _ourKey = 'https://cuenti.muh#2';

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

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('sync_test');
    outbox = TransactionOutbox(dir);
    repo = MockTransactionsRepository();
    sync = TransactionSync(outbox, repo, () => _ourKey);
    // The queue is ours by default, as it is in the app: `_enqueue` claims
    // it for the account that queued the write. Without a claim every
    // drain below would read an empty queue and prove nothing about
    // sending. Tests about a queue that is NOT ours set their own owner.
    await outbox.setOwner(_ourKey);
  });

  tearDown(() => dir.deleteSync(recursive: true));

  /// Drops the claim [setUp] made, leaving the store as a queue written
  /// before ownership existed: entries, and nothing saying whose they are.
  void unclaim() => File('${dir.path}/.owner.json').deleteSync();

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
    final brittle = TransactionSync(
      _BrokenWriteOutbox(dir),
      repo,
      () => _ourKey,
    );

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
        () => _ourKey,
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

  group('a queue that is not ours', () {
    test('a foreign queue is not sent', () async {
      await queue('local-1');
      await outbox.setOwner('https://cuenti.muh#1');
      // The sync is built for account 2.

      expect(await sync.drain(), 0);
      verifyNever(
        () => repo.save(any(), splitsTouched: any(named: 'splitsTouched')),
      );
      expect(await outbox.all(), hasLength(1));
    });

    test('an unclaimed queue is not sent either', () async {
      await queue('local-1');
      unclaim();

      expect(await sync.drain(), 0);
      verifyNever(
        () => repo.save(any(), splitsTouched: any(named: 'splitsTouched')),
      );
    });

    test('a drain with nobody signed in sends nothing', () async {
      // A drain can outlive the sign-in it started under, which is why the
      // key is a callback read per pass rather than a value captured once.
      await queue('local-1');
      final signedOut = TransactionSync(outbox, repo, () => null);

      expect(await signedOut.drain(), 0);
      verifyNever(
        () => repo.save(any(), splitsTouched: any(named: 'splitsTouched')),
      );
    });

    // The other half of the guard: it must seal foreign queues without
    // sealing everything, or the feature is just broken sending.
    test('our own queue is still sent', () async {
      when(
        () => repo.save(any(), splitsTouched: any(named: 'splitsTouched')),
      ).thenAnswer((i) async => i.positionalArguments.first as Transaction);
      await queue('local-1');
      await outbox.setOwner(_ourKey);

      expect(await sync.drain(), 1);
    });
  });

  // The two ways a stale queue reaches a new account. Both end at the same
  // guard, but they are named separately because they are the reason the
  // guard exists, and a future reader deleting one should have to argue
  // with the door it describes rather than with a generic case.
  group('the doors this closes', () {
    test('door 1: a real store that survived a fallback sign-out is not '
        'sent for the next account', () async {
      // Account 1 queued into the real store while a fallback was in use,
      // so sign-out cleared the fallback and left this untouched.
      await queue('local-1');
      await outbox.setOwner('https://cuenti.muh#1');

      expect(await sync.drain(), 0);
      expect(await outbox.all(), hasLength(1), reason: 'left, not deleted');
    });

    test('door 2: a queue kept across an expired session is not sent to '
        'whoever signs in next', () async {
      // _handleSessionExpired keeps the outbox deliberately -- the session
      // expired, the user did not ask to be forgotten. That is safe only
      // because the next account cannot read it.
      await queue('local-1');
      await outbox.setOwner('https://cuenti.muh#1');

      expect(await ownedEntries(outbox, _ourKey), isEmpty);
      expect(await sync.drain(), 0);
    });

    test('but the same account signing back in still gets its queue', () async {
      await queue('local-1');
      await outbox.setOwner(_ourKey);

      expect(await ownedEntries(outbox, _ourKey), hasLength(1));
    });
  });

  group('drainAgain', () {
    test(
      'a retry during an in-flight drain still sends the entry',
      () async {
        // The first drain is made slow so the retry lands inside it, which
        // is the case that fails: its snapshot was taken before the
        // rejection was cleared, so joining it sends nothing.
        final gate = Completer<void>();
        var saves = 0;
        when(
          () => repo.save(any(), splitsTouched: any(named: 'splitsTouched')),
        ).thenAnswer((i) async {
          saves++;
          await gate.future;
          return i.positionalArguments.first as Transaction;
        });

        await queue('slow-one');
        final first = sync.drain();
        await Future<void>.delayed(Duration.zero);

        // Meanwhile the user clears a rejection and asks again.
        await queue('retried', minute: 1);
        final again = sync.drainAgain();

        gate.complete();
        await first;
        await again;

        expect(saves, 2, reason: 'the retried entry was sent, not skipped');
        expect(await outbox.all(), isEmpty);
      },
    );

    test(
      'a burst of retries queues one follow-up run, not one per tap',
      () async {
        final gate = Completer<void>();
        var runs = 0;
        when(
          () => repo.save(any(), splitsTouched: any(named: 'splitsTouched')),
        ).thenAnswer((i) async {
          runs++;
          await gate.future;
          return i.positionalArguments.first as Transaction;
        });

        await queue('one');
        final first = sync.drain();
        await Future<void>.delayed(Duration.zero);

        final a = sync.drainAgain();
        final b = sync.drainAgain();
        final c = sync.drainAgain();
        expect(identical(a, b), isTrue, reason: 'one follow-up, shared');
        expect(identical(b, c), isTrue);

        gate.complete();
        await Future.wait([first, a, b, c]);

        expect(runs, 1, reason: 'nothing left to send on the follow-up run');
      },
    );

    test('with nothing in flight it behaves exactly like drain', () async {
      when(
        () => repo.save(any(), splitsTouched: any(named: 'splitsTouched')),
      ).thenAnswer((i) async => i.positionalArguments.first as Transaction);
      await queue('one');

      expect(await sync.drainAgain(), 1);
      expect(await outbox.all(), isEmpty);
    });

    test(
      'a retry tapped while the queued follow-up is itself running gets a '
      'fresh pass, not the one already reading a stale outbox',
      () async {
        // Three sends, each released independently, and a "started" signal
        // per send so the test can wait for exactly the right moment
        // instead of guessing how many microtasks a real disk write takes.
        final started = List.generate(3, (_) => Completer<void>());
        final release = List.generate(3, (_) => Completer<void>());
        var calls = 0;
        when(
          () => repo.save(any(), splitsTouched: any(named: 'splitsTouched')),
        ).thenAnswer((i) async {
          final index = calls;
          calls++;
          started[index].complete();
          await release[index].future;
          return i.positionalArguments.first as Transaction;
        });

        await queue('a');
        final first = sync.drain();
        await started[0].future; // the initial pass is sending 'a'

        await queue('b', minute: 1);
        final second = sync.drainAgain(); // queued behind `first`

        release[0].complete(); // let the initial pass finish sending 'a'
        await started[1].future; // the follow-up pass is now sending 'b'

        // A third tap lands while the follow-up itself is running -- the
        // case F1 named. It must not join `second`: that pass already read
        // the outbox and cannot see what this tap is about to queue.
        await queue('c', minute: 2);
        final third = sync.drainAgain();

        expect(
          identical(second, third),
          isFalse,
          reason: 'a retry during the follow-up must start its own fresh pass',
        );

        release[1].complete(); // let the follow-up finish sending 'b'
        release[2].complete(); // let the fresh pass send 'c' once it starts

        await Future.wait([first, second, third]);

        expect(calls, 3, reason: 'a, b and c all reached the repository');
        expect(await outbox.all(), isEmpty);
      },
    );

    test(
      'a queued follow-up still runs even when the pass it waited on threw',
      () async {
        var calls = 0;
        when(
          () => repo.save(any(), splitsTouched: any(named: 'splitsTouched')),
        ).thenAnswer((i) async {
          calls++;
          if (calls == 1) throw Exception('boom');
          return i.positionalArguments.first as Transaction;
        });

        await queue('a');
        final first = sync.drain();
        // No gate needed: drain() (and _drain()'s first await) has not
        // progressed past its own synchronous prelude yet, so `_inFlight`
        // is already memoised and this joins the same run `first` did.
        final second = sync.drainAgain();

        await expectLater(first, throwsA(isA<Exception>()));
        expect(
          await second,
          1,
          reason:
              'the follow-up ran and delivered the retried entry despite '
              'the pass it waited on throwing',
        );
        expect(await outbox.all(), isEmpty);
        expect(calls, 2, reason: 'the entry that failed was tried again');
      },
    );

    test(
      'a queued follow-up still runs when the pass it waited on threw an '
      'Error rather than an Exception',
      () async {
        // Same contract as the test above, for the other half of the
        // hierarchy. `on Exception` let an Error propagate out of the
        // await and skipped the `return drain()` below it, so the retry
        // the person asked for silently never ran.
        var calls = 0;
        when(
          () => repo.save(any(), splitsTouched: any(named: 'splitsTouched')),
        ).thenAnswer((i) async {
          calls++;
          if (calls == 1) throw StateError('boom');
          return i.positionalArguments.first as Transaction;
        });

        await queue('a');
        final first = sync.drain();
        final second = sync.drainAgain();

        await expectLater(first, throwsA(isA<StateError>()));
        expect(
          await second,
          1,
          reason:
              'the follow-up ran and delivered the retried entry despite '
              'the pass it waited on throwing an Error',
        );
        expect(await outbox.all(), isEmpty);
        expect(calls, 2, reason: 'the entry that failed was tried again');
      },
    );
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
