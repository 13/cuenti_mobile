// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class LEn extends L {
  LEn([String locale = 'en']) : super(locale);

  @override
  String get commonSave => 'Save';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonClose => 'Close';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonName => 'Name';

  @override
  String get commonType => 'Type';

  @override
  String get commonCurrency => 'Currency';

  @override
  String get commonAmount => 'Amount';

  @override
  String get commonMemo => 'Memo';

  @override
  String get commonNone => 'None';

  @override
  String get commonNoData => 'No data';

  @override
  String get commonAccount => 'Account';

  @override
  String get commonExpense => 'Expense';

  @override
  String get commonIncome => 'Income';

  @override
  String get commonTransfer => 'Transfer';

  @override
  String get commonClearFilters => 'Clear filters';

  @override
  String get commonEmail => 'Email';

  @override
  String get commonPassword => 'Password';

  @override
  String get commonUsername => 'Username';

  @override
  String get commonFirstName => 'First Name';

  @override
  String get commonLastName => 'Last Name';

  @override
  String get commonGroup => 'Group';

  @override
  String get commonUndoWarning => 'This action cannot be undone.';

  @override
  String get offlineBanner => 'Offline — showing the last figures fetched';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navTransactions => 'Transactions';

  @override
  String get navBudgets => 'Budgets';

  @override
  String get navStatistics => 'Statistics';

  @override
  String get actionRefresh => 'Refresh';

  @override
  String get actionLogout => 'Logout';

  @override
  String get authSignInTitle => 'Sign in';

  @override
  String get authSignInButton => 'Sign In';

  @override
  String get authSignInBiometrics => 'Sign in with biometrics';

  @override
  String get authNotYou => 'Not you?';

  @override
  String get authNoAccountRegister => 'Don\'t have an account? Register';

  @override
  String get authHaveAccountSignIn => 'Already have an account? Sign in';

  @override
  String get authRegister => 'Register';

  @override
  String get authCreateAccount => 'Create account';

  @override
  String get authConfirmPassword => 'Confirm Password';

  @override
  String get authLockedTitle => 'Cuenti is Locked';

  @override
  String get authUnlock => 'Unlock';

  @override
  String get authShowPassword => 'Show password';

  @override
  String get authHidePassword => 'Hide password';

  @override
  String get serverSetupTitle => 'Server Setup';

  @override
  String get serverUrl => 'Server URL';

  @override
  String get serverSaveContinue => 'Save & Continue';

  @override
  String get serverTrust => 'Trust';

  @override
  String get serverUntrustedTitle => 'Unrecognised certificate';

  @override
  String get serverChange => 'Change Server';

  @override
  String get accountsEmpty => 'No accounts yet';

  @override
  String get accountsAdd => 'Add account';

  @override
  String get accountsDeleteTitle => 'Delete Account?';

  @override
  String get accountsDeleteBody =>
      'All associated transactions will be affected.';

  @override
  String get accountsInstitution => 'Institution';

  @override
  String get accountsStartBalance => 'Start Balance';

  @override
  String get accountsExcludeSummary => 'Exclude from Summary';

  @override
  String get accountsExcludeReports => 'Exclude from Reports';

  @override
  String get assetsEmpty => 'No assets yet';

  @override
  String get assetsAdd => 'Add asset';

  @override
  String get assetsDeleteTitle => 'Delete Asset?';

  @override
  String get assetsSymbolHint => 'Symbol (e.g. VWCE.DE)';

  @override
  String get assetsRefreshPrice => 'Refresh price';

  @override
  String get currenciesEmpty => 'No currencies yet';

  @override
  String get currenciesAdd => 'Add currency';

  @override
  String get currenciesDeleteTitle => 'Delete Currency?';

  @override
  String get currenciesCodeHint => 'Code (e.g. EUR)';

  @override
  String get currenciesNameHint => 'Name (e.g. Euro)';

  @override
  String get currenciesSymbolHint => 'Symbol (e.g. €)';

  @override
  String get currenciesDecimals => 'Decimals';

  @override
  String get currenciesDecimal => 'Decimal';

  @override
  String get currenciesGrouping => 'Grouping';

  @override
  String get tagsEmpty => 'No tags yet';

  @override
  String get tagsAdd => 'Add tag';

  @override
  String get tagsDeleteTitle => 'Delete Tag?';

  @override
  String get payeesEmpty => 'No payees yet';

  @override
  String get payeesAdd => 'Add payee';

  @override
  String get payeesDeleteTitle => 'Delete Payee?';

  @override
  String get payeesNotes => 'Notes';

  @override
  String get payeesDefaultCategory => 'Default Category';

  @override
  String get payeesDefaultPayment => 'Default Payment';

  @override
  String get payeeLabel => 'Payee';

  @override
  String get categoriesEmpty => 'No categories yet';

  @override
  String get categoriesAdd => 'Add category';

  @override
  String get categoriesDeleteTitle => 'Delete Category?';

  @override
  String get categoriesEditOne => 'Edit category';

  @override
  String get categoriesDeleteOne => 'Delete category';

  @override
  String get categoriesParent => 'Parent Category';

  @override
  String get categoriesTopLevel => 'None (Top Level)';

  @override
  String get categoryLabel => 'Category';

  @override
  String get categorySearchClear => 'Clear search';

  @override
  String get categorySearchEmpty => 'No matching categories';

  @override
  String categorySearchHint(String what) {
    return 'Search $what';
  }

  @override
  String get txEmpty => 'No transactions yet';

  @override
  String get txNoMatch => 'No transactions match';

  @override
  String get txAdd => 'Add transaction';

  @override
  String get txSearchHint => 'Search transactions...';

  @override
  String get txDeleteTitle => 'Delete transaction?';

  @override
  String get txTypeFilter => 'Transaction type';

  @override
  String get txFromAccount => 'From Account';

  @override
  String get txToAccount => 'To Account';

  @override
  String get txPaymentMethod => 'Payment Method';

  @override
  String get txTagsHint => 'Tags (comma separated)';

  @override
  String get txSplits => 'Splits';

  @override
  String get txAddSplit => 'Add split';

  @override
  String get txRemoveSplit => 'Remove split';

  @override
  String get txSplitNeedsCategory => 'Each split needs a category';

  @override
  String txSplitSumMismatch(String sum, String total) {
    return 'Splits must sum to the amount: $sum of $total';
  }

  @override
  String get txRequired => 'Required';

  @override
  String get txInvalidNumber => 'Invalid number';

  @override
  String get fuelOdometer => 'Odometer (km)';

  @override
  String get fuelLiters => 'Liters';

  @override
  String get fuelFullTank => 'Full tank';

  @override
  String fuelLastReading(String value) {
    return 'last: $value';
  }

  @override
  String get fuelImplausibleLiters => 'Implausible liters value';

  @override
  String fuelNotIncreasing(String last) {
    return 'Odometer is not higher than the last reading ($last)';
  }

  @override
  String fuelLargeJump(String distance) {
    return 'Very large jump since the last reading ($distance km) — typo?';
  }

  @override
  String fuelConsumption(String distance, String consumption) {
    return '$distance km since last, ~$consumption L/100km';
  }

  @override
  String fuelDistanceOnly(String distance) {
    return '$distance km since last fill-up';
  }

  @override
  String get vehiclesChooseCategory => 'Choose category';

  @override
  String get vehiclesFuelCategory => 'Fuel category';

  @override
  String get vehiclesSetDefault => 'Set as default';

  @override
  String get vehiclesDefaultSaved => 'Default saved';

  @override
  String get vehiclesPickPrompt =>
      'Pick a fuel category to see your vehicle report';

  @override
  String get vehiclesNoEntries => 'No fuel entries in this period';

  @override
  String get vehiclesNotEnoughData => 'Not enough data for a chart';

  @override
  String get vehiclesThisYear => 'This year';

  @override
  String get vehiclesTotalCost => 'Total cost';

  @override
  String get vehiclesDistance => 'Distance';

  @override
  String get vehiclesAvgConsumption => '⌀ Consumption';

  @override
  String get vehiclesAvgPricePerLiter => '⌀ Price/L';

  @override
  String get vehiclesFull => 'Full';

  @override
  String get budgetsEmpty => 'No budgets yet';

  @override
  String get budgetsAdd => 'Add budget';

  @override
  String get budgetsDeleteTitle => 'Delete Budget?';

  @override
  String get budgetsMonthlyLimit => 'Monthly Limit';

  @override
  String get budgetsActive => 'Active';

  @override
  String get budgetsRemaining => 'Remaining: ';

  @override
  String get budgetsSelectCategory => 'Select a category';

  @override
  String get scheduledEmpty => 'No scheduled transactions';

  @override
  String get scheduledDeleteTitle => 'Delete Schedule?';

  @override
  String get scheduledPost => 'Post';

  @override
  String get scheduledSkip => 'Skip';

  @override
  String get scheduledPosted => 'Transaction posted';

  @override
  String get scheduledSkipped => 'Occurrence skipped';

  @override
  String get savedViewsTitle => 'Saved views';

  @override
  String get savedViewsEmpty => 'No saved views yet';

  @override
  String get savedViewsSaveCurrent => 'Save current view';

  @override
  String get savedViewsDeleteTitle => 'Delete saved view?';

  @override
  String get savedViewsDeleteOne => 'Delete view';

  @override
  String get savedViewsFromWeb => 'Saved by web app';

  @override
  String get auditEmpty => 'No audit entries';

  @override
  String get auditNoMatch => 'No audit entries match';

  @override
  String get auditSearchHint => 'Search audit log...';

  @override
  String get auditTitle => 'Audit Log';

  @override
  String get dashboardNetWorth => 'Net worth';

  @override
  String get dashboardCash => 'Cash';

  @override
  String get dashboardPortfolio => 'Portfolio';

  @override
  String get dashboardNoAccounts => 'No accounts';

  @override
  String get forecastsNet => 'Net';

  @override
  String get statsAllAccounts => 'All Accounts';

  @override
  String get statsIncomeByCategory => 'Income by Category';

  @override
  String get statsExpenseByCategory => 'Expense by Category';

  @override
  String get statsTotal => 'Total: ';

  @override
  String get statsOverview => 'Overview';

  @override
  String get updateAvailable => 'Update available';

  @override
  String get updateUpToDate => 'You\'re up to date';

  @override
  String get updateCheckFailed => 'Couldn\'t check for updates';

  @override
  String get updateNoApk => 'No APK found in the latest release';

  @override
  String get updateLater => 'Later';

  @override
  String get settingsProfile => 'Profile';

  @override
  String get settingsPreferences => 'Preferences';

  @override
  String get settingsSecurity => 'Security';

  @override
  String get settingsServer => 'Server';

  @override
  String get settingsData => 'Data';

  @override
  String get settingsNotLoggedIn => 'Not logged in';

  @override
  String get settingsEditProfile => 'Edit Profile';

  @override
  String get settingsDarkMode => 'Dark Mode';

  @override
  String get settingsDefaultCurrency => 'Default Currency';

  @override
  String get settingsLocale => 'Locale';

  @override
  String get settingsApiAccess => 'API Access';

  @override
  String get settingsApiAccessSubtitle => 'Enable API access for this account';

  @override
  String get settingsBiometric => 'Biometric Unlock';

  @override
  String get settingsBiometricSubtitle =>
      'Require fingerprint/face to reopen or sign in';

  @override
  String get settingsChangePassword => 'Change Password';

  @override
  String get settingsCurrentPassword => 'Current Password';

  @override
  String get settingsNewPassword => 'New Password';

  @override
  String get settingsConfirmNewPassword => 'Confirm New Password';

  @override
  String get settingsPasswordsMismatch => 'Passwords do not match';

  @override
  String get settingsPasswordChanged => 'Password changed';

  @override
  String settingsConnectedTo(String url) {
    return 'Connected to: $url';
  }

  @override
  String get settingsExportData => 'Export data';

  @override
  String get settingsImportData => 'Import data';

  @override
  String get settingsImportTitle => 'Import data?';

  @override
  String get settingsImportBody =>
      'This replaces data on the server with the file contents.';

  @override
  String get settingsImport => 'Import';

  @override
  String get settingsImportComplete => 'Import complete';

  @override
  String settingsExportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String settingsImportFailed(String error) {
    return 'Import failed: $error';
  }

  @override
  String get settingsAdministration => 'Administration';

  @override
  String get settingsAdminPanel => 'Admin Panel';

  @override
  String get settingsGlobalApiEnabled => 'Global API Enabled';

  @override
  String get settingsRegistrationEnabled => 'Registration Enabled';

  @override
  String get settingsEnable => 'Enable';

  @override
  String get settingsDisable => 'Disable';

  @override
  String get settingsDeleteUserBody =>
      'This permanently removes the user and their data.';

  @override
  String get settingsChange => 'Change';

  @override
  String get settingsAbout => 'About';

  @override
  String get aboutTitle => 'About Cuenti';

  @override
  String get aboutTagline => 'A mobile cuenti app';

  @override
  String get aboutDescription =>
      'Cuenti is a personal finance management application that helps you track your transactions, manage accounts, and monitor your assets across different currencies.';

  @override
  String get aboutSoftwareInfo => 'Software Info';

  @override
  String get aboutCheckUpdates => 'Check for updates';

  @override
  String get aboutVisitWebsite => 'Visit Website';
}
