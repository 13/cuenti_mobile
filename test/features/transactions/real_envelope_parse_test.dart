import 'dart:convert';
import 'dart:io';

import 'package:cuentimobile/features/transactions/domain/transaction_page.dart';
import 'package:flutter_test/flutter_test.dart';

/// Parses a REAL /api/transactions envelope captured from a running
/// v2.10.0 backend (demo dataset) to pin the live wire contract.
void main() {
  test('real v2.10.0 envelope parses end-to-end', () {
    final raw = File('test/fixtures/real_tx_envelope.json').readAsStringSync();
    final page = TransactionPage.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
    expect(page.content.length, 50);
    expect(page.totalPages, 2);
    expect(page.content.first.amount, greaterThan(0));
  });
}
