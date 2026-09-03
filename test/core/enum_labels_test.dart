import 'package:cuentimobile/core/enum_labels.dart';
import 'package:cuentimobile/features/transactions/domain/transaction.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:cuentimobile/l10n/app_localizations_de.dart';
import 'package:cuentimobile/l10n/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final L en = LEn();
  final L de = LDe();

  group('accountTypeLabel', () {
    test("names each type in the reader's language", () {
      expect(accountTypeLabel(en, 'CREDIT_CARD'), 'Credit Card');
      expect(accountTypeLabel(de, 'CREDIT_CARD'), 'Kreditkarte');
    });

    test('hands back a type it does not know, rather than a blank or a '
        'wrong guess', () {
      expect(accountTypeLabel(en, 'BROKERAGE'), 'BROKERAGE');
    });
  });

  group('assetTypeLabel', () {
    test("names each type in the reader's language", () {
      expect(assetTypeLabel(en, 'CRYPTO'), 'Crypto');
      expect(assetTypeLabel(de, 'CRYPTO'), 'Krypto');
    });

    test('hands back a type it does not know', () {
      expect(assetTypeLabel(en, 'BOND'), 'BOND');
    });
  });

  group('paymentMethodLabel', () {
    test("names each method in the reader's language", () {
      expect(paymentMethodLabel(en, 'BANK_TRANSFER'), 'Bank Transfer');
      expect(paymentMethodLabel(de, 'BANK_TRANSFER'), 'Überweisung');
    });

    test('NONE reads as the same "None" the rest of the app uses', () {
      expect(paymentMethodLabel(en, 'NONE'), en.commonNone);
    });

    test('names TRADE, which this backend really sends -- four of the fifty '
        'transactions in test/fixtures use it', () {
      expect(paymentMethodLabel(en, 'TRADE'), 'Trade');
      expect(paymentMethodLabel(de, 'TRADE'), 'Wertpapiergeschäft');
    });

    test('every method the app offers reads as words, not as the constant '
        'underneath it', () {
      // The label function was written against a five-value list that has
      // since turned out to be the wrong one; this holds it to the list the
      // app actually offers, whatever that grows into.
      for (final method in kPaymentMethods) {
        expect(
          paymentMethodLabel(en, method),
          isNot(method),
          reason: '$method has no label',
        );
        expect(paymentMethodLabel(de, method), isNot(method));
      }
    });

    test('hands back a method it does not know', () {
      expect(paymentMethodLabel(en, 'DIRECT_DEBIT'), 'DIRECT_DEBIT');
    });
  });

  group('categoryTypeLabel', () {
    test('reuses the words the rest of the app already has', () {
      expect(categoryTypeLabel(en, 'EXPENSE'), en.commonExpense);
      expect(categoryTypeLabel(de, 'INCOME'), de.commonIncome);
    });

    test('hands back a type it does not know', () {
      expect(categoryTypeLabel(en, 'REFUND'), 'REFUND');
    });
  });

  group('recurrenceLabel', () {
    test("names each pattern in the reader's language", () {
      expect(recurrenceLabel(en, 'MONTHLY'), 'Monthly');
      expect(recurrenceLabel(de, 'MONTHLY'), 'Monatlich');
    });

    test('spells out the compound ones rather than the constant', () {
      expect(recurrenceLabel(en, 'MONTHLY_LAST_DAY'), 'Monthly (last day)');
      expect(recurrenceLabel(en, 'BI_WEEKLY'), 'Fortnightly');
    });

    test('hands back a pattern it does not know', () {
      expect(recurrenceLabel(en, 'EVERY_THIRD_TUESDAY'), 'EVERY_THIRD_TUESDAY');
    });
  });
}
