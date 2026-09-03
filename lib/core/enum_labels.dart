import 'package:cuentimobile/l10n/app_localizations.dart';

/// Readable names for the string enums the backend speaks.
///
/// The API exchanges constants -- `CREDIT_CARD`, `BANK_TRANSFER`, `EXPENSE`
/// -- and those had been rendered straight into dropdowns and subtitles, so
/// the app showed its wire format to the people using it, in English, in
/// every language.
///
/// A value none of these knows is handed back untouched. The backend can
/// grow a new one at any time, and showing the raw constant is honest about
/// what the record holds; a blank or a guessed name would not be.
String accountTypeLabel(L l, String value) => switch (value) {
  'BANK' => l.accountTypeBank,
  'CASH' => l.accountTypeCash,
  'ASSET' => l.accountTypeAsset,
  'CREDIT_CARD' => l.accountTypeCreditCard,
  'LIABILITY' => l.accountTypeLiability,
  'CURRENT' => l.accountTypeCurrent,
  'SAVINGS' => l.accountTypeSavings,
  _ => value,
};

String assetTypeLabel(L l, String value) => switch (value) {
  'STOCK' => l.assetTypeStock,
  'ETF' => l.assetTypeEtf,
  'CRYPTO' => l.assetTypeCrypto,
  _ => value,
};

String paymentMethodLabel(L l, String value) => switch (value) {
  'CASH' => l.paymentMethodCash,
  'CARD' => l.paymentMethodCard,
  'BANK_TRANSFER' => l.paymentMethodBankTransfer,
  'CHECK' => l.paymentMethodCheck,
  'NONE' => l.commonNone,
  _ => value,
};

String categoryTypeLabel(L l, String value) => switch (value) {
  'EXPENSE' => l.commonExpense,
  'INCOME' => l.commonIncome,
  'TRANSFER' => l.commonTransfer,
  _ => value,
};

String recurrenceLabel(L l, String value) => switch (value) {
  'DAILY' => l.recurrenceDaily,
  'WEEKLY' => l.recurrenceWeekly,
  'BI_WEEKLY' => l.recurrenceBiWeekly,
  'MONTHLY' => l.recurrenceMonthly,
  'MONTHLY_LAST_DAY' => l.recurrenceMonthlyLastDay,
  'YEARLY' => l.recurrenceYearly,
  _ => value,
};
