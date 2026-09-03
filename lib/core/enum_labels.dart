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

/// Covers every entry of `kPaymentMethods`, which is the backend's own
/// vocabulary. It was written against a five-value list that turned out to
/// be a stale copy -- two of whose values, CARD and CHECK, the server has
/// never sent -- so three of the twelve real methods were labelled and the
/// rest showed as constants.
String paymentMethodLabel(L l, String value) => switch (value) {
  'NONE' => l.commonNone,
  'CASH' => l.paymentMethodCash,
  'DEBIT_CARD' => l.paymentMethodDebitCard,
  'BANK_TRANSFER' => l.paymentMethodBankTransfer,
  'STANDING_ORDER' => l.paymentMethodStandingOrder,
  'ELECTRONIC_PAYMENT' => l.paymentMethodElectronic,
  'FI_FEE' => l.paymentMethodBankFee,
  'CARD_TRANSACTION' => l.paymentMethodCardTransaction,
  'TRADE' => l.paymentMethodTrade,
  'TRANSFER' => l.commonTransfer,
  'REWARD' => l.paymentMethodReward,
  'INTEREST' => l.paymentMethodInterest,
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
