import 'package:cuentimobile/core/storage/at_rest_cipher.dart';
import 'package:cuentimobile/core/storage/secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryStorage extends SecureStorage {
  _MemoryStorage() : super();
  final Map<String, String> data = {};
  int failReads = 0;
  int writes = 0;

  @override
  Future<String?> read(String key) async {
    if (failReads > 0) {
      failReads--;
      throw Exception('keystore unavailable');
    }
    return data[key];
  }

  @override
  Future<void> write(String key, String value) async {
    writes++;
    data[key] = value;
  }

  @override
  Future<void> delete(String key) async => data.remove(key);
}

void main() {
  const secret = '{"payee":"Pharmacy","amount":42.5}';

  test('what is sealed opens back to the same text', () async {
    final cipher = AesGcmAtRestCipher(_MemoryStorage());

    final sealed = await cipher.seal(secret);
    final opened = await cipher.open(sealed);

    expect(opened.text, secret);
    expect(opened.legacy, isFalse);
  });

  test('sealed text reveals nothing of the plaintext', () async {
    final sealed = await AesGcmAtRestCipher(_MemoryStorage()).seal(secret);

    expect(sealed, startsWith(AesGcmAtRestCipher.prefix));
    expect(sealed, isNot(contains('Pharmacy')));
    expect(sealed, isNot(contains('42.5')));
  });

  test('the same text seals differently every time (random nonce)', () async {
    final cipher = AesGcmAtRestCipher(_MemoryStorage());

    expect(await cipher.seal(secret), isNot(await cipher.seal(secret)));
  });

  test('plaintext from before encryption is recognised as legacy', () async {
    final opened = await AesGcmAtRestCipher(_MemoryStorage()).open(secret);

    expect(opened.text, secret);
    expect(opened.legacy, isTrue);
  });

  test('the key is kept, so a later launch can open what an earlier one '
      'sealed', () async {
    final storage = _MemoryStorage();
    final sealed = await AesGcmAtRestCipher(storage).seal(secret);

    final reopened = await AesGcmAtRestCipher(storage).open(sealed);

    expect(reopened.text, secret);
    expect(storage.data.keys, contains('at_rest_key_v1'));
  });

  test('two ciphers over the same storage create one key, not two', () async {
    final storage = _MemoryStorage();

    await Future.wait([
      AesGcmAtRestCipher(storage).seal(secret),
      AesGcmAtRestCipher(storage).seal(secret),
    ]);

    expect(storage.writes, 1);
  });

  test('data sealed under another key is refused, not decrypted into '
      'garbage', () async {
    final sealed = await AesGcmAtRestCipher(_MemoryStorage()).seal(secret);

    await expectLater(
      AesGcmAtRestCipher(_MemoryStorage()).open(sealed),
      throwsA(isA<AtRestDecryptionException>()),
    );
  });

  test('a tampered file is refused', () async {
    final cipher = AesGcmAtRestCipher(_MemoryStorage());
    final sealed = await cipher.seal(secret);
    final body = sealed.substring(AesGcmAtRestCipher.prefix.length);
    final flipped = body.replaceRange(
      body.length - 6,
      body.length - 5,
      body[body.length - 6] == 'A' ? 'B' : 'A',
    );

    await expectLater(
      cipher.open('${AesGcmAtRestCipher.prefix}$flipped'),
      throwsA(isA<AtRestDecryptionException>()),
    );
  });

  test('garbage behind the prefix is refused', () async {
    await expectLater(
      AesGcmAtRestCipher(
        _MemoryStorage(),
      ).open('${AesGcmAtRestCipher.prefix}not base64 at all'),
      throwsA(isA<AtRestDecryptionException>()),
    );
  });

  test('a key read that fails is retried next time, not remembered', () async {
    final storage = _MemoryStorage()..failReads = 1;
    final cipher = AesGcmAtRestCipher(storage);

    await expectLater(cipher.seal(secret), throwsException);
    final sealed = await cipher.seal(secret);

    expect((await cipher.open(sealed)).text, secret);
  });

  test('the plaintext cipher leaves text untouched', () async {
    expect(await AtRestCipher.none.seal(secret), secret);
    final opened = await AtRestCipher.none.open(secret);
    expect(opened.text, secret);
    expect(opened.legacy, isFalse);
  });
}
