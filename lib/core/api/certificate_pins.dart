import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:cuentimobile/core/storage/secure_storage.dart';

const _pinsKey = 'cert_pins';

/// SHA-256 of a certificate's DER encoding, formatted the way `openssl
/// x509 -fingerprint -sha256` prints it, so a user can compare what the app
/// shows against what their server reports.
String certificateFingerprint(Uint8List der) {
  final digest = sha256.convert(der);
  return [
    for (final byte in digest.bytes) byte.toRadixString(16).padLeft(2, '0'),
  ].join(':').toUpperCase();
}

/// Which self-signed certificates this install has been told to trust.
///
/// Cuenti is normally self-hosted behind a certificate no public CA has
/// signed, so those connections have to be accepted somehow. Accepting every
/// certificate would mean accepting an interceptor's too, so trust is
/// granted per host, once, by the user, against a fingerprint they can
/// verify -- and a host whose certificate later changes is refused, which is
/// exactly what an interception attempt looks like.
///
/// Certificates that chain to a real CA never reach here: the platform
/// accepts them before the bad-certificate callback is consulted. That
/// includes anything signed by a CA in the device's *user* store, which
/// `network_security_config.xml` trusts on purpose for self-hosters running
/// an internal CA -- so the refusal above is a guarantee against a swapped
/// self-signed certificate, not against an interceptor whose root the
/// device has been persuaded to install. The reasoning is written out in
/// that file.
class CertificatePins {
  CertificatePins(this._storage);

  final SecureStorage _storage;

  /// Held in memory because `badCertificateCallback` is synchronous and
  /// cannot await storage.
  final Map<String, String> _pins = {};

  /// The last certificate turned away, for the setup screen to show the user
  /// so they can decide whether it is the one they expect.
  ({String host, String fingerprint})? lastRejection;

  Future<void> load() async {
    _pins.clear();
    final raw = await _storage.read(_pinsKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      _pins.addAll(decoded.map((host, fp) => MapEntry(host, fp as String)));
      // A store we cannot read is treated as no pins rather than as a hard
      // failure: the user can re-trust their server, where refusing to start
      // would leave them with no way back in.
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      _pins.clear();
    }
  }

  /// Whether [fingerprint] is the certificate this install trusts for
  /// [host]. Records a rejection as a side effect so the UI can offer it.
  bool evaluate(String host, String fingerprint) {
    if (_pins[host] == fingerprint) return true;
    lastRejection = (host: host, fingerprint: fingerprint);
    return false;
  }

  Future<void> trust(String host, String fingerprint) async {
    _pins[host] = fingerprint;
    if (lastRejection?.host == host) lastRejection = null;
    await _persist();
  }

  Future<void> forget(String host) async {
    _pins.remove(host);
    await _persist();
  }

  String? pinFor(String host) => _pins[host];

  Future<void> _persist() => _storage.write(_pinsKey, jsonEncode(_pins));
}
