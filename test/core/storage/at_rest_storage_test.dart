import 'dart:io';

import 'package:cuentimobile/core/api/response_cache.dart';
import 'package:cuentimobile/core/storage/at_rest_cipher.dart';
import 'package:cuentimobile/core/storage/secure_storage.dart';
import 'package:cuentimobile/features/transactions/data/transaction_outbox.dart';
import 'package:cuentimobile/features/transactions/domain/pending_transaction.dart';
import 'package:cuentimobile/features/transactions/domain/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

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

/// What offline mode leaves on disk: nothing readable without the key.
void main() {
  late Directory dir;
  late AtRestCipher cipher;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('at_rest');
    cipher = AesGcmAtRestCipher(_MemoryStorage());
  });

  tearDown(() => dir.deleteSync(recursive: true));

  List<File> filesIn(Directory d) => d.listSync().whereType<File>().toList();

  group('response cache', () {
    test('entries are sealed on disk and read back', () async {
      final cache = ResponseCache(dir, cipher: cipher);

      await cache.store('k', {'payee': 'Pharmacy', 'balance': 1234.5});

      final raw = File('${dir.path}/k.json').readAsStringSync();
      expect(raw, startsWith(AesGcmAtRestCipher.prefix));
      expect(raw, isNot(contains('Pharmacy')));
      expect((await cache.read('k'))!.body, {
        'payee': 'Pharmacy',
        'balance': 1234.5,
      });
    });

    test(
      'a plaintext entry from before encryption is dropped, not served',
      () async {
        File('${dir.path}/k.json').writeAsStringSync(
          '{"storedAt":"${DateTime.now().toIso8601String()}",'
          '"body":{"payee":"Pharmacy"}}',
        );

        expect(await ResponseCache(dir, cipher: cipher).read('k'), isNull);
        expect(File('${dir.path}/k.json').existsSync(), isFalse);
      },
    );

    test('an entry sealed under a lost key is a miss, and removed', () async {
      await ResponseCache(
        dir,
        cipher: AesGcmAtRestCipher(_MemoryStorage()),
      ).store('k', {'a': 1});

      expect(await ResponseCache(dir, cipher: cipher).read('k'), isNull);
      expect(File('${dir.path}/k.json').existsSync(), isFalse);
    });
  });

  group('outbox', () {
    const owner = 'https://cuenti.muh#2';

    PendingTransaction entry(String id) => PendingTransaction(
      localId: id,
      operation: PendingOperation.create,
      transaction: Transaction(
        amount: 42.5,
        payee: 'Pharmacy',
        transactionDate: DateTime(2026, 9, 4),
      ),
      queuedAt: DateTime(2026, 9, 4, 10),
    );

    void expectSealed(Directory d) {
      final files = filesIn(d);
      expect(files, isNotEmpty);
      for (final file in files) {
        final raw = file.readAsStringSync();
        expect(raw, startsWith(AesGcmAtRestCipher.prefix), reason: file.path);
        expect(raw, isNot(contains('Pharmacy')));
        expect(raw, isNot(contains('cuenti.muh')));
      }
    }

    test('entries and the owner file are sealed on disk', () async {
      final outbox = TransactionOutbox(dir, cipher: cipher);

      await outbox.setOwner(owner);
      await outbox.add(entry('a'));

      expectSealed(dir);
      expect((await outbox.all()).single.transaction.payee, 'Pharmacy');
      expect(await outbox.owner(), owner);
    });

    test(
      'plaintext entries from before encryption are kept and re-sealed',
      () async {
        final before = TransactionOutbox(dir);
        await before.setOwner(owner);
        await before.add(entry('a'));
        final outbox = TransactionOutbox(dir, cipher: cipher);

        expect((await outbox.all()).single.localId, 'a');
        expect(await outbox.owner(), owner);

        expectSealed(dir);
        expect(
          await TransactionOutbox(dir, cipher: cipher).all(),
          hasLength(1),
        );
      },
    );

    test('a queue sealed under a lost key is kept but never adopted', () async {
      final lost = TransactionOutbox(
        dir,
        cipher: AesGcmAtRestCipher(_MemoryStorage()),
      );
      await lost.setOwner(owner);
      await lost.add(entry('a'));
      final outbox = TransactionOutbox(dir, cipher: cipher);

      expect(await outbox.all(), isEmpty);
      expect(await outbox.owner(), TransactionOutbox.unattributableOwner);
      expect(filesIn(dir), hasLength(2), reason: 'not deleted');
    });

    test(
      'a sidelined queue keeps its owner readable through the cipher',
      () async {
        final outbox = TransactionOutbox(dir, cipher: cipher);
        await outbox.setOwner(owner);
        await outbox.add(entry('a'));

        await outbox.sideline();

        final queue = (await outbox.sidelinedQueues()).single;
        expect(queue.owner, owner);
        expectSealed(queue.directory);
      },
    );
  });
}
