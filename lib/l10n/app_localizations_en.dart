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
  String get serverInsecureTitle => 'Unencrypted connection';

  @override
  String serverInsecureBody(String host) {
    return '$host will be reached over http, so your password, your session and everything this app loads travel unencrypted. Anyone on the same network can read them. Use https unless you trust every device on this network.';
  }

  @override
  String get serverInsecureContinue => 'Use http anyway';

  @override
  String serverUntrustedBody(String host) {
    return '$host presented a certificate no certificate authority vouches for. That is normal for a self-hosted Cuenti server, but it is also what an intercepted connection looks like. Trust it only if this fingerprint matches your server.';
  }

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
  String get forecastsMonthlyForecast => 'Monthly Forecast';

  @override
  String get forecastsBreakdown => 'Breakdown';

  @override
  String get vehiclesConsumption => 'Consumption';

  @override
  String get vehiclesEntries => 'Entries';

  @override
  String get statsAllAccounts => 'All Accounts';

  @override
  String get statsIncomeByCategory => 'Income by Category';

  @override
  String get statsExpenseByCategory => 'Expense by Category';

  @override
  String get statsTotal => 'Total';

  @override
  String get statsOverview => 'Overview';

  @override
  String get scheduledLate => '(LATE!)';

  @override
  String dashboardAssetUnits(String units, String symbol) {
    return '$units units · $symbol';
  }

  @override
  String scheduledNextOn(String pattern, String date) {
    return '$pattern · Next: $date';
  }

  @override
  String currenciesFormatSummary(
    String symbol,
    String digits,
    String decimal,
    String grouping,
  ) {
    return 'Symbol $symbol · $digits decimals · $decimal $grouping';
  }

  @override
  String get a11yChartIncomeExpense => 'Income versus expense chart';

  @override
  String get a11yChartCashFlow => 'Net cash flow chart';

  @override
  String get a11yChartMonthlyCashFlow => 'Monthly cash flow chart';

  @override
  String get a11yChartCategories => 'Category breakdown chart';

  @override
  String get commonBalance => 'Balance';

  @override
  String get statsSavingsRate => 'Savings rate';

  @override
  String get statsIncomeVsExpense => 'Income vs Expense';

  @override
  String get statsNetCashFlowTrend => 'Net Cash Flow Trend';

  @override
  String get statsMonthlyCashFlow => 'Monthly Cash Flow';

  @override
  String get statsRangeDaily => 'Daily';

  @override
  String get statsRangeWeekly => 'Weekly';

  @override
  String get statsRangeMonthly => 'Monthly';

  @override
  String get statsRangeYearly => 'Yearly';

  @override
  String get statsAllCategories => 'All categories';

  @override
  String statsDirectAmount(String name) {
    return '$name (direct)';
  }

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

  @override
  String get updateSkipVersion => 'Skip this version';

  @override
  String get updateInstall => 'Update';

  @override
  String get updateDownloadFailed => 'Download failed';

  @override
  String updateReady(String tag) {
    return '$tag is ready to install.';
  }

  @override
  String get settingsAutoUpdate => 'Automatic update check';

  @override
  String get settingsAutoUpdateSubtitle =>
      'Look for a new release on GitHub when the app opens';

  @override
  String commonError(String message) {
    return 'Error: $message';
  }

  @override
  String commonDeleteConfirm(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get commonRequired => 'Required';

  @override
  String get commonInvalidNumber => 'Invalid number';

  @override
  String get commonAll => 'All';

  @override
  String get commonToday => 'Today';

  @override
  String get commonYesterday => 'Yesterday';

  @override
  String get commonCustom => 'Custom';

  @override
  String get commonDateRange => 'Date range';

  @override
  String get navScheduled => 'Scheduled';

  @override
  String get navForecasts => 'Forecasts';

  @override
  String get navAccounts => 'Accounts';

  @override
  String get navPayees => 'Payees';

  @override
  String get navCategories => 'Categories';

  @override
  String get navTags => 'Tags';

  @override
  String get navCurrencies => 'Currencies';

  @override
  String get navAssets => 'Assets';

  @override
  String get navVehicles => 'Vehicles';

  @override
  String get navSettings => 'Settings';

  @override
  String get navAbout => 'About';

  @override
  String get navAuditLog => 'Audit Log';

  @override
  String get navGeneral => 'General';

  @override
  String get navManagement => 'Management';

  @override
  String get navSettingsSection => 'Settings';

  @override
  String get privacyShow => 'Show amounts';

  @override
  String get privacyHide => 'Hide amounts';

  @override
  String get accountsAddTitle => 'Add Account';

  @override
  String get accountsEditTitle => 'Edit Account';

  @override
  String get assetsAddTitle => 'Add Asset';

  @override
  String get assetsEditTitle => 'Edit Asset';

  @override
  String get budgetsAddTitle => 'Add Budget';

  @override
  String get budgetsEditTitle => 'Edit Budget';

  @override
  String get categoriesAddTitle => 'Add Category';

  @override
  String get categoriesEditTitle => 'Edit Category';

  @override
  String get currenciesAddTitle => 'Add Currency';

  @override
  String get currenciesEditTitle => 'Edit Currency';

  @override
  String get payeesAddTitle => 'Add Payee';

  @override
  String get payeesEditTitle => 'Edit Payee';

  @override
  String get tagsAddTitle => 'Add Tag';

  @override
  String get tagsEditTitle => 'Edit Tag';

  @override
  String get txAddTitle => 'Add Transaction';

  @override
  String get txEditTitle => 'Edit Transaction';

  @override
  String get txAllAccounts => 'All accounts';

  @override
  String get authBiometricReason => 'Sign in to Cuenti';

  @override
  String get authUnlockReason => 'Authenticate to unlock Cuenti';

  @override
  String authServerLine(String url) {
    return 'Server: $url';
  }

  @override
  String get assetsNoPrice => 'No price';

  @override
  String assetsPriceRefreshed(String symbol) {
    return 'Price refreshed for $symbol';
  }

  @override
  String statsTransactionsInPeriod(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString transactions in period',
      one: '1 transaction in period',
      zero: 'No transactions in period',
    );
    return '$_temp0';
  }

  @override
  String get vehiclesCustomRange => 'Custom range';

  @override
  String scheduledDeleteBody(String name) {
    return 'Delete \"$name\" recurring transaction?';
  }

  @override
  String budgetsDeleteBody(String category) {
    return 'Delete budget for \"$category\"?';
  }

  @override
  String settingsUsersCount(String count) {
    return 'Users ($count)';
  }

  @override
  String settingsDeleteUserTitle(String username) {
    return 'Delete $username?';
  }

  @override
  String aboutCopyright(String year) {
    return '© $year Cuenti Team';
  }

  @override
  String get txFuelHint =>
      'No km/liters entered — this entry will not appear in the vehicle report';

  @override
  String get errorNetwork => 'Cannot connect to server';

  @override
  String get errorNotAuthenticated => 'Not authenticated';

  @override
  String get errorInvalidCredentials => 'Invalid username or password';

  @override
  String get errorApiDisabled => 'API access is not enabled';

  @override
  String get errorInvalidRequest => 'Invalid request';

  @override
  String errorServer(String status) {
    return 'Server error ($status)';
  }

  @override
  String get errorCertificate =>
      'The server certificate is not trusted. Re-run Server Setup to check its fingerprint and trust it.';

  @override
  String get errorUnknown => 'An error occurred';

  @override
  String get errorNoSavedCredentials => 'No saved credentials';

  @override
  String get errorSavedPasswordInvalid => 'Saved password no longer valid';

  @override
  String get errorUnexpectedResponse => 'Unexpected response from server';

  @override
  String get txSaved => 'Transaction saved';

  @override
  String get txDeleted => 'Transaction deleted';

  @override
  String get txPendingNotSent => 'Not sent yet';

  @override
  String txPendingRejected(String reason) {
    return 'Refused: $reason';
  }

  @override
  String get txSavedOnDevice =>
      'Saved on this device — it will send when there is a connection';

  @override
  String get txDiscardPending => 'Discard';

  @override
  String get txRetryPending => 'Try again';

  @override
  String get accountsSaved => 'Account saved';

  @override
  String get accountsDeleted => 'Account deleted';

  @override
  String get categoriesSaved => 'Category saved';

  @override
  String get categoriesDeleted => 'Category deleted';

  @override
  String get payeesSaved => 'Payee saved';

  @override
  String get payeesDeleted => 'Payee deleted';

  @override
  String get tagsSaved => 'Tag saved';

  @override
  String get tagsDeleted => 'Tag deleted';

  @override
  String get currenciesSaved => 'Currency saved';

  @override
  String get currenciesDeleted => 'Currency deleted';

  @override
  String get assetsSaved => 'Asset saved';

  @override
  String get assetsDeleted => 'Asset deleted';

  @override
  String get budgetsSaved => 'Budget saved';

  @override
  String get budgetsDeleted => 'Budget deleted';

  @override
  String get savedViewsSaved => 'View saved';

  @override
  String get savedViewsDeleted => 'View deleted';

  @override
  String get settingsProfileSaved => 'Profile saved';

  @override
  String offlineBannerSince(String when) {
    return 'Offline — figures from $when';
  }

  @override
  String get accountsSearchHint => 'Search accounts...';

  @override
  String get accountsNoMatch => 'No accounts match';

  @override
  String get payeesSearchHint => 'Search payees...';

  @override
  String get payeesNoMatch => 'No payees match';

  @override
  String get categoriesSearchHint => 'Search categories...';

  @override
  String get categoriesNoMatch => 'No categories match';

  @override
  String get tagsSearchHint => 'Search tags...';

  @override
  String get tagsNoMatch => 'No tags match';

  @override
  String get currenciesSearchHint => 'Search currencies...';

  @override
  String get currenciesNoMatch => 'No currencies match';

  @override
  String get assetsSearchHint => 'Search assets...';

  @override
  String get assetsNoMatch => 'No assets match';

  @override
  String get commonSortCustom => 'Custom order';

  @override
  String get commonCode => 'Code';

  @override
  String get commonSymbol => 'Symbol';

  @override
  String get commonPrice => 'Price';

  @override
  String get accountTypeBank => 'Bank';

  @override
  String get accountTypeCash => 'Cash';

  @override
  String get accountTypeAsset => 'Asset';

  @override
  String get accountTypeCreditCard => 'Credit Card';

  @override
  String get accountTypeLiability => 'Liability';

  @override
  String get accountTypeCurrent => 'Current Account';

  @override
  String get accountTypeSavings => 'Savings Account';

  @override
  String get assetTypeStock => 'Stock';

  @override
  String get assetTypeEtf => 'ETF';

  @override
  String get assetTypeCrypto => 'Crypto';

  @override
  String get paymentMethodCash => 'Cash';

  @override
  String get paymentMethodBankTransfer => 'Bank Transfer';

  @override
  String get sortAscending => 'Ascending';

  @override
  String get sortDescending => 'Descending';

  @override
  String get recurrenceDaily => 'Daily';

  @override
  String get recurrenceWeekly => 'Weekly';

  @override
  String get recurrenceBiWeekly => 'Fortnightly';

  @override
  String get recurrenceMonthly => 'Monthly';

  @override
  String get recurrenceMonthlyLastDay => 'Monthly (last day)';

  @override
  String get recurrenceYearly => 'Yearly';

  @override
  String validationMinCharacters(int count) {
    return 'Minimum $count characters';
  }

  @override
  String get validationInvalidEmail => 'Invalid email';

  @override
  String get authPasswordsMismatch => 'Passwords do not match';

  @override
  String get aboutVersion => 'Version';

  @override
  String get aboutBuildNumber => 'Build Number';

  @override
  String get aboutBuildDate => 'Build Date';

  @override
  String get aboutBuildTime => 'Build Time';

  @override
  String get scheduledSearchHint => 'Search scheduled...';

  @override
  String get scheduledNoMatch => 'No scheduled transactions match';

  @override
  String get commonNext => 'Next';

  @override
  String get budgetsSearchHint => 'Search budgets...';

  @override
  String get budgetsNoMatch => 'No budgets match';

  @override
  String get budgetsSpent => 'Spent';

  @override
  String scheduledOverdue(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count overdue',
      one: '1 overdue',
    );
    return '$_temp0';
  }

  @override
  String get paymentMethodDebitCard => 'Debit Card';

  @override
  String get paymentMethodStandingOrder => 'Standing Order';

  @override
  String get paymentMethodElectronic => 'Electronic Payment';

  @override
  String get paymentMethodBankFee => 'Bank Fee';

  @override
  String get paymentMethodCardTransaction => 'Card Transaction';

  @override
  String get paymentMethodTrade => 'Trade';

  @override
  String get paymentMethodReward => 'Reward';

  @override
  String get paymentMethodInterest => 'Interest';

  @override
  String categoryCreate(String name) {
    return 'Create \"$name\"';
  }

  @override
  String categoryCreateUnder(String parent) {
    return 'under $parent';
  }

  @override
  String get categoryCreateTopLevel => 'New top-level category';

  @override
  String get logoutPendingTitle => 'Unsent transactions';

  @override
  String logoutPendingBody(int count) {
    return '$count transactions have not reached the server. Signing out will discard them.';
  }
}
