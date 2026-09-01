import 'dart:convert';
import 'dart:typed_data';

import 'package:cuentimobile/core/api/certificate_pins.dart';
import 'package:cuentimobile/core/storage/secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryStorage extends SecureStorage {
  _MemoryStorage() : super();
  final Map<String, String> data = {};
  @override
  Future<String?> read(String key) async => data[key];
  @override
  Future<void> write(String key, String value) async => data[key] = value;
  @override
  Future<void> delete(String key) async => data.remove(key);
}

void main() {
  group('certificateFingerprint', () {
    test('is the SHA-256 of the DER as colon-separated uppercase hex', () {
      // SHA-256 of the empty input, the one digest anyone can check.
      expect(
        certificateFingerprint(Uint8List(0)),
        'E3:B0:C4:42:98:FC:1C:14:9A:FB:F4:C8:99:6F:B9:24:'
        '27:AE:41:E4:64:9B:93:4C:A4:95:99:1B:78:52:B8:55',
      );
    });

    test('differs for different certificates', () {
      final a = certificateFingerprint(Uint8List.fromList([1, 2, 3]));
      final b = certificateFingerprint(Uint8List.fromList([1, 2, 4]));
      expect(a, isNot(b));
    });
  });

  group('CertificatePins', () {
    late _MemoryStorage storage;
    late CertificatePins pins;
    const host = 'cuenti.muh';
    const fingerprint = 'AA:BB:CC';

    setUp(() async {
      storage = _MemoryStorage();
      pins = CertificatePins(storage);
      await pins.load();
    });

    test('rejects a host it has never seen', () {
      expect(pins.evaluate(host, fingerprint), isFalse);
    });

    test('accepts a fingerprint that was explicitly trusted', () async {
      await pins.trust(host, fingerprint);

      expect(pins.evaluate(host, fingerprint), isTrue);
    });

    test('rejects a different fingerprint for a trusted host, which is what '
        'an interception attempt looks like', () async {
      await pins.trust(host, fingerprint);

      expect(pins.evaluate(host, 'DD:EE:FF'), isFalse);
    });

    test('scopes trust to the host it was granted for', () async {
      await pins.trust(host, fingerprint);

      expect(pins.evaluate('evil.example', fingerprint), isFalse);
    });

    test('remembers what it rejected so the UI can offer to trust it', () {
      pins.evaluate(host, fingerprint);

      expect(pins.lastRejection, (host: host, fingerprint: fingerprint));
    });

    test('survives a reload', () async {
      await pins.trust(host, fingerprint);

      final reloaded = CertificatePins(storage);
      await reloaded.load();

      expect(reloaded.evaluate(host, fingerprint), isTrue);
    });

    test('forgetting a host revokes its trust', () async {
      await pins.trust(host, fingerprint);
      await pins.forget(host);

      expect(pins.evaluate(host, fingerprint), isFalse);
    });

    test('ignores a corrupt store rather than locking the user out', () async {
      storage.data['cert_pins'] = 'not json';

      final loaded = CertificatePins(storage);
      await loaded.load();

      expect(loaded.evaluate(host, fingerprint), isFalse);
      await loaded.trust(host, fingerprint);
      expect(loaded.evaluate(host, fingerprint), isTrue);
    });

    test('persists as readable json so a pin can be inspected', () async {
      await pins.trust(host, fingerprint);

      expect(
        jsonDecode(storage.data['cert_pins']!),
        {host: fingerprint},
      );
    });
  });
}
