import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of L
/// returned by `L.of(context)`.
///
/// Applications need to include `L.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: L.localizationsDelegates,
///   supportedLocales: L.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the L.supportedLocales
/// property.
abstract class L {
  L(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static L of(BuildContext context) {
    return Localizations.of<L>(context, L)!;
  }

  static const LocalizationsDelegate<L> delegate = _LDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('it'),
  ];

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get commonName;

  /// No description provided for @commonType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get commonType;

  /// No description provided for @commonCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get commonCurrency;

  /// No description provided for @commonAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get commonAmount;

  /// No description provided for @commonMemo.
  ///
  /// In en, this message translates to:
  /// **'Memo'**
  String get commonMemo;

  /// No description provided for @commonNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get commonNone;

  /// No description provided for @commonNoData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get commonNoData;

  /// No description provided for @commonAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get commonAccount;

  /// No description provided for @commonExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get commonExpense;

  /// No description provided for @commonIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get commonIncome;

  /// No description provided for @commonTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get commonTransfer;

  /// No description provided for @commonClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get commonClearFilters;

  /// No description provided for @commonEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get commonEmail;

  /// No description provided for @commonPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get commonPassword;

  /// No description provided for @commonUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get commonUsername;

  /// No description provided for @commonFirstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get commonFirstName;

  /// No description provided for @commonLastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get commonLastName;

  /// No description provided for @commonGroup.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get commonGroup;

  /// No description provided for @commonUndoWarning.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get commonUndoWarning;

  /// No description provided for @offlineBanner.
  ///
  /// In en, this message translates to:
  /// **'Offline — showing the last figures fetched'**
  String get offlineBanner;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navTransactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get navTransactions;

  /// No description provided for @navBudgets.
  ///
  /// In en, this message translates to:
  /// **'Budgets'**
  String get navBudgets;

  /// No description provided for @navStatistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get navStatistics;

  /// No description provided for @actionRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get actionRefresh;

  /// No description provided for @actionLogout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get actionLogout;

  /// No description provided for @authSignInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignInTitle;

  /// No description provided for @authSignInButton.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get authSignInButton;

  /// No description provided for @authSignInBiometrics.
  ///
  /// In en, this message translates to:
  /// **'Sign in with biometrics'**
  String get authSignInBiometrics;

  /// No description provided for @authNotYou.
  ///
  /// In en, this message translates to:
  /// **'Not you?'**
  String get authNotYou;

  /// No description provided for @authNoAccountRegister.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Register'**
  String get authNoAccountRegister;

  /// No description provided for @authHaveAccountSignIn.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get authHaveAccountSignIn;

  /// No description provided for @authRegister.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get authRegister;

  /// No description provided for @authCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authCreateAccount;

  /// No description provided for @authConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get authConfirmPassword;

  /// No description provided for @authLockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Cuenti is Locked'**
  String get authLockedTitle;

  /// No description provided for @authUnlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get authUnlock;

  /// No description provided for @authShowPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get authShowPassword;

  /// No description provided for @authHidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get authHidePassword;

  /// No description provided for @serverSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Server Setup'**
  String get serverSetupTitle;

  /// No description provided for @serverUrl.
  ///
  /// In en, this message translates to:
  /// **'Server URL'**
  String get serverUrl;

  /// No description provided for @serverSaveContinue.
  ///
  /// In en, this message translates to:
  /// **'Save & Continue'**
  String get serverSaveContinue;

  /// No description provided for @serverTrust.
  ///
  /// In en, this message translates to:
  /// **'Trust'**
  String get serverTrust;

  /// No description provided for @serverUntrustedTitle.
  ///
  /// In en, this message translates to:
  /// **'Unrecognised certificate'**
  String get serverUntrustedTitle;

  /// No description provided for @serverInsecureTitle.
  ///
  /// In en, this message translates to:
  /// **'Unencrypted connection'**
  String get serverInsecureTitle;

  /// No description provided for @serverInsecureBody.
  ///
  /// In en, this message translates to:
  /// **'{host} will be reached over http, so your password, your session and everything this app loads travel unencrypted. Anyone on the same network can read them. Use https unless you trust every device on this network.'**
  String serverInsecureBody(String host);

  /// No description provided for @serverInsecureContinue.
  ///
  /// In en, this message translates to:
  /// **'Use http anyway'**
  String get serverInsecureContinue;

  /// No description provided for @serverUntrustedBody.
  ///
  /// In en, this message translates to:
  /// **'{host} presented a certificate no certificate authority vouches for. That is normal for a self-hosted Cuenti server, but it is also what an intercepted connection looks like. Trust it only if this fingerprint matches your server.'**
  String serverUntrustedBody(String host);

  /// No description provided for @serverChange.
  ///
  /// In en, this message translates to:
  /// **'Change Server'**
  String get serverChange;

  /// No description provided for @accountsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No accounts yet'**
  String get accountsEmpty;

  /// No description provided for @accountsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add account'**
  String get accountsAdd;

  /// No description provided for @accountsDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Account?'**
  String get accountsDeleteTitle;

  /// No description provided for @accountsDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'All associated transactions will be affected.'**
  String get accountsDeleteBody;

  /// No description provided for @accountsInstitution.
  ///
  /// In en, this message translates to:
  /// **'Institution'**
  String get accountsInstitution;

  /// No description provided for @accountsStartBalance.
  ///
  /// In en, this message translates to:
  /// **'Start Balance'**
  String get accountsStartBalance;

  /// No description provided for @accountsExcludeSummary.
  ///
  /// In en, this message translates to:
  /// **'Exclude from Summary'**
  String get accountsExcludeSummary;

  /// No description provided for @accountsExcludeReports.
  ///
  /// In en, this message translates to:
  /// **'Exclude from Reports'**
  String get accountsExcludeReports;

  /// No description provided for @assetsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No assets yet'**
  String get assetsEmpty;

  /// No description provided for @assetsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add asset'**
  String get assetsAdd;

  /// No description provided for @assetsDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Asset?'**
  String get assetsDeleteTitle;

  /// No description provided for @assetsSymbolHint.
  ///
  /// In en, this message translates to:
  /// **'Symbol (e.g. VWCE.DE)'**
  String get assetsSymbolHint;

  /// No description provided for @assetsRefreshPrice.
  ///
  /// In en, this message translates to:
  /// **'Refresh price'**
  String get assetsRefreshPrice;

  /// No description provided for @currenciesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No currencies yet'**
  String get currenciesEmpty;

  /// No description provided for @currenciesAdd.
  ///
  /// In en, this message translates to:
  /// **'Add currency'**
  String get currenciesAdd;

  /// No description provided for @currenciesDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Currency?'**
  String get currenciesDeleteTitle;

  /// No description provided for @currenciesCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Code (e.g. EUR)'**
  String get currenciesCodeHint;

  /// No description provided for @currenciesNameHint.
  ///
  /// In en, this message translates to:
  /// **'Name (e.g. Euro)'**
  String get currenciesNameHint;

  /// No description provided for @currenciesSymbolHint.
  ///
  /// In en, this message translates to:
  /// **'Symbol (e.g. €)'**
  String get currenciesSymbolHint;

  /// No description provided for @currenciesDecimals.
  ///
  /// In en, this message translates to:
  /// **'Decimals'**
  String get currenciesDecimals;

  /// No description provided for @currenciesDecimal.
  ///
  /// In en, this message translates to:
  /// **'Decimal'**
  String get currenciesDecimal;

  /// No description provided for @currenciesGrouping.
  ///
  /// In en, this message translates to:
  /// **'Grouping'**
  String get currenciesGrouping;

  /// No description provided for @tagsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No tags yet'**
  String get tagsEmpty;

  /// No description provided for @tagsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add tag'**
  String get tagsAdd;

  /// No description provided for @tagsDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Tag?'**
  String get tagsDeleteTitle;

  /// No description provided for @payeesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No payees yet'**
  String get payeesEmpty;

  /// No description provided for @payeesAdd.
  ///
  /// In en, this message translates to:
  /// **'Add payee'**
  String get payeesAdd;

  /// No description provided for @payeesDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Payee?'**
  String get payeesDeleteTitle;

  /// No description provided for @payeesNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get payeesNotes;

  /// No description provided for @payeesDefaultCategory.
  ///
  /// In en, this message translates to:
  /// **'Default Category'**
  String get payeesDefaultCategory;

  /// No description provided for @payeesDefaultPayment.
  ///
  /// In en, this message translates to:
  /// **'Default Payment'**
  String get payeesDefaultPayment;

  /// No description provided for @payeeLabel.
  ///
  /// In en, this message translates to:
  /// **'Payee'**
  String get payeeLabel;

  /// No description provided for @categoriesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No categories yet'**
  String get categoriesEmpty;

  /// No description provided for @categoriesAdd.
  ///
  /// In en, this message translates to:
  /// **'Add category'**
  String get categoriesAdd;

  /// No description provided for @categoriesDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Category?'**
  String get categoriesDeleteTitle;

  /// No description provided for @categoriesEditOne.
  ///
  /// In en, this message translates to:
  /// **'Edit category'**
  String get categoriesEditOne;

  /// No description provided for @categoriesDeleteOne.
  ///
  /// In en, this message translates to:
  /// **'Delete category'**
  String get categoriesDeleteOne;

  /// No description provided for @categoriesParent.
  ///
  /// In en, this message translates to:
  /// **'Parent Category'**
  String get categoriesParent;

  /// No description provided for @categoriesTopLevel.
  ///
  /// In en, this message translates to:
  /// **'None (Top Level)'**
  String get categoriesTopLevel;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @categorySearchClear.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get categorySearchClear;

  /// No description provided for @categorySearchEmpty.
  ///
  /// In en, this message translates to:
  /// **'No matching categories'**
  String get categorySearchEmpty;

  /// No description provided for @categorySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search {what}'**
  String categorySearchHint(String what);

  /// No description provided for @txEmpty.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get txEmpty;

  /// No description provided for @txNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No transactions match'**
  String get txNoMatch;

  /// No description provided for @txAdd.
  ///
  /// In en, this message translates to:
  /// **'Add transaction'**
  String get txAdd;

  /// No description provided for @txSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search transactions...'**
  String get txSearchHint;

  /// No description provided for @txDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete transaction?'**
  String get txDeleteTitle;

  /// No description provided for @txTypeFilter.
  ///
  /// In en, this message translates to:
  /// **'Transaction type'**
  String get txTypeFilter;

  /// No description provided for @txFromAccount.
  ///
  /// In en, this message translates to:
  /// **'From Account'**
  String get txFromAccount;

  /// No description provided for @txToAccount.
  ///
  /// In en, this message translates to:
  /// **'To Account'**
  String get txToAccount;

  /// No description provided for @txPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get txPaymentMethod;

  /// No description provided for @txTagsHint.
  ///
  /// In en, this message translates to:
  /// **'Tags (comma separated)'**
  String get txTagsHint;

  /// No description provided for @txSplits.
  ///
  /// In en, this message translates to:
  /// **'Splits'**
  String get txSplits;

  /// No description provided for @txAddSplit.
  ///
  /// In en, this message translates to:
  /// **'Add split'**
  String get txAddSplit;

  /// No description provided for @txRemoveSplit.
  ///
  /// In en, this message translates to:
  /// **'Remove split'**
  String get txRemoveSplit;

  /// No description provided for @txSplitNeedsCategory.
  ///
  /// In en, this message translates to:
  /// **'Each split needs a category'**
  String get txSplitNeedsCategory;

  /// No description provided for @txSplitSumMismatch.
  ///
  /// In en, this message translates to:
  /// **'Splits must sum to the amount: {sum} of {total}'**
  String txSplitSumMismatch(String sum, String total);

  /// No description provided for @txRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get txRequired;

  /// No description provided for @txInvalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Invalid number'**
  String get txInvalidNumber;

  /// No description provided for @fuelOdometer.
  ///
  /// In en, this message translates to:
  /// **'Odometer (km)'**
  String get fuelOdometer;

  /// No description provided for @fuelLiters.
  ///
  /// In en, this message translates to:
  /// **'Liters'**
  String get fuelLiters;

  /// No description provided for @fuelFullTank.
  ///
  /// In en, this message translates to:
  /// **'Full tank'**
  String get fuelFullTank;

  /// No description provided for @fuelLastReading.
  ///
  /// In en, this message translates to:
  /// **'last: {value}'**
  String fuelLastReading(String value);

  /// No description provided for @fuelImplausibleLiters.
  ///
  /// In en, this message translates to:
  /// **'Implausible liters value'**
  String get fuelImplausibleLiters;

  /// No description provided for @fuelNotIncreasing.
  ///
  /// In en, this message translates to:
  /// **'Odometer is not higher than the last reading ({last})'**
  String fuelNotIncreasing(String last);

  /// No description provided for @fuelLargeJump.
  ///
  /// In en, this message translates to:
  /// **'Very large jump since the last reading ({distance} km) — typo?'**
  String fuelLargeJump(String distance);

  /// No description provided for @fuelConsumption.
  ///
  /// In en, this message translates to:
  /// **'{distance} km since last, ~{consumption} L/100km'**
  String fuelConsumption(String distance, String consumption);

  /// No description provided for @fuelDistanceOnly.
  ///
  /// In en, this message translates to:
  /// **'{distance} km since last fill-up'**
  String fuelDistanceOnly(String distance);

  /// No description provided for @vehiclesChooseCategory.
  ///
  /// In en, this message translates to:
  /// **'Choose category'**
  String get vehiclesChooseCategory;

  /// No description provided for @vehiclesFuelCategory.
  ///
  /// In en, this message translates to:
  /// **'Fuel category'**
  String get vehiclesFuelCategory;

  /// No description provided for @vehiclesSetDefault.
  ///
  /// In en, this message translates to:
  /// **'Set as default'**
  String get vehiclesSetDefault;

  /// No description provided for @vehiclesDefaultSaved.
  ///
  /// In en, this message translates to:
  /// **'Default saved'**
  String get vehiclesDefaultSaved;

  /// No description provided for @vehiclesPickPrompt.
  ///
  /// In en, this message translates to:
  /// **'Pick a fuel category to see your vehicle report'**
  String get vehiclesPickPrompt;

  /// No description provided for @vehiclesNoEntries.
  ///
  /// In en, this message translates to:
  /// **'No fuel entries in this period'**
  String get vehiclesNoEntries;

  /// No description provided for @vehiclesNotEnoughData.
  ///
  /// In en, this message translates to:
  /// **'Not enough data for a chart'**
  String get vehiclesNotEnoughData;

  /// No description provided for @vehiclesThisYear.
  ///
  /// In en, this message translates to:
  /// **'This year'**
  String get vehiclesThisYear;

  /// No description provided for @vehiclesTotalCost.
  ///
  /// In en, this message translates to:
  /// **'Total cost'**
  String get vehiclesTotalCost;

  /// No description provided for @vehiclesDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get vehiclesDistance;

  /// No description provided for @vehiclesAvgConsumption.
  ///
  /// In en, this message translates to:
  /// **'⌀ Consumption'**
  String get vehiclesAvgConsumption;

  /// No description provided for @vehiclesAvgPricePerLiter.
  ///
  /// In en, this message translates to:
  /// **'⌀ Price/L'**
  String get vehiclesAvgPricePerLiter;

  /// No description provided for @vehiclesFull.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get vehiclesFull;

  /// No description provided for @budgetsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No budgets yet'**
  String get budgetsEmpty;

  /// No description provided for @budgetsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add budget'**
  String get budgetsAdd;

  /// No description provided for @budgetsDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Budget?'**
  String get budgetsDeleteTitle;

  /// No description provided for @budgetsMonthlyLimit.
  ///
  /// In en, this message translates to:
  /// **'Monthly Limit'**
  String get budgetsMonthlyLimit;

  /// No description provided for @budgetsActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get budgetsActive;

  /// No description provided for @budgetsRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining: '**
  String get budgetsRemaining;

  /// No description provided for @budgetsSelectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select a category'**
  String get budgetsSelectCategory;

  /// No description provided for @scheduledEmpty.
  ///
  /// In en, this message translates to:
  /// **'No scheduled transactions'**
  String get scheduledEmpty;

  /// No description provided for @scheduledDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Schedule?'**
  String get scheduledDeleteTitle;

  /// No description provided for @scheduledPost.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get scheduledPost;

  /// No description provided for @scheduledSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get scheduledSkip;

  /// No description provided for @scheduledPosted.
  ///
  /// In en, this message translates to:
  /// **'Transaction posted'**
  String get scheduledPosted;

  /// No description provided for @scheduledSkipped.
  ///
  /// In en, this message translates to:
  /// **'Occurrence skipped'**
  String get scheduledSkipped;

  /// No description provided for @savedViewsTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved views'**
  String get savedViewsTitle;

  /// No description provided for @savedViewsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No saved views yet'**
  String get savedViewsEmpty;

  /// No description provided for @savedViewsSaveCurrent.
  ///
  /// In en, this message translates to:
  /// **'Save current view'**
  String get savedViewsSaveCurrent;

  /// No description provided for @savedViewsDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete saved view?'**
  String get savedViewsDeleteTitle;

  /// No description provided for @savedViewsDeleteOne.
  ///
  /// In en, this message translates to:
  /// **'Delete view'**
  String get savedViewsDeleteOne;

  /// No description provided for @savedViewsFromWeb.
  ///
  /// In en, this message translates to:
  /// **'Saved by web app'**
  String get savedViewsFromWeb;

  /// No description provided for @auditEmpty.
  ///
  /// In en, this message translates to:
  /// **'No audit entries'**
  String get auditEmpty;

  /// No description provided for @auditNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No audit entries match'**
  String get auditNoMatch;

  /// No description provided for @auditSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search audit log...'**
  String get auditSearchHint;

  /// No description provided for @auditTitle.
  ///
  /// In en, this message translates to:
  /// **'Audit Log'**
  String get auditTitle;

  /// No description provided for @dashboardNetWorth.
  ///
  /// In en, this message translates to:
  /// **'Net worth'**
  String get dashboardNetWorth;

  /// No description provided for @dashboardCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get dashboardCash;

  /// No description provided for @dashboardPortfolio.
  ///
  /// In en, this message translates to:
  /// **'Portfolio'**
  String get dashboardPortfolio;

  /// No description provided for @dashboardNoAccounts.
  ///
  /// In en, this message translates to:
  /// **'No accounts'**
  String get dashboardNoAccounts;

  /// No description provided for @forecastsNet.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get forecastsNet;

  /// No description provided for @forecastsMonthlyForecast.
  ///
  /// In en, this message translates to:
  /// **'Monthly Forecast'**
  String get forecastsMonthlyForecast;

  /// No description provided for @forecastsBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Breakdown'**
  String get forecastsBreakdown;

  /// No description provided for @vehiclesConsumption.
  ///
  /// In en, this message translates to:
  /// **'Consumption'**
  String get vehiclesConsumption;

  /// No description provided for @vehiclesEntries.
  ///
  /// In en, this message translates to:
  /// **'Entries'**
  String get vehiclesEntries;

  /// No description provided for @statsAllAccounts.
  ///
  /// In en, this message translates to:
  /// **'All Accounts'**
  String get statsAllAccounts;

  /// No description provided for @statsIncomeByCategory.
  ///
  /// In en, this message translates to:
  /// **'Income by Category'**
  String get statsIncomeByCategory;

  /// No description provided for @statsExpenseByCategory.
  ///
  /// In en, this message translates to:
  /// **'Expense by Category'**
  String get statsExpenseByCategory;

  /// No description provided for @statsTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get statsTotal;

  /// No description provided for @statsOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get statsOverview;

  /// No description provided for @scheduledLate.
  ///
  /// In en, this message translates to:
  /// **'(LATE!)'**
  String get scheduledLate;

  /// No description provided for @dashboardAssetUnits.
  ///
  /// In en, this message translates to:
  /// **'{units} units · {symbol}'**
  String dashboardAssetUnits(String units, String symbol);

  /// No description provided for @scheduledNextOn.
  ///
  /// In en, this message translates to:
  /// **'{pattern} · Next: {date}'**
  String scheduledNextOn(String pattern, String date);

  /// No description provided for @currenciesFormatSummary.
  ///
  /// In en, this message translates to:
  /// **'Symbol {symbol} · {digits} decimals · {decimal} {grouping}'**
  String currenciesFormatSummary(
    String symbol,
    String digits,
    String decimal,
    String grouping,
  );

  /// No description provided for @a11yChartIncomeExpense.
  ///
  /// In en, this message translates to:
  /// **'Income versus expense chart'**
  String get a11yChartIncomeExpense;

  /// No description provided for @a11yChartCashFlow.
  ///
  /// In en, this message translates to:
  /// **'Net cash flow chart'**
  String get a11yChartCashFlow;

  /// No description provided for @a11yChartMonthlyCashFlow.
  ///
  /// In en, this message translates to:
  /// **'Monthly cash flow chart'**
  String get a11yChartMonthlyCashFlow;

  /// No description provided for @a11yChartCategories.
  ///
  /// In en, this message translates to:
  /// **'Category breakdown chart'**
  String get a11yChartCategories;

  /// No description provided for @commonBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get commonBalance;

  /// No description provided for @statsSavingsRate.
  ///
  /// In en, this message translates to:
  /// **'Savings rate'**
  String get statsSavingsRate;

  /// No description provided for @statsIncomeVsExpense.
  ///
  /// In en, this message translates to:
  /// **'Income vs Expense'**
  String get statsIncomeVsExpense;

  /// No description provided for @statsNetCashFlowTrend.
  ///
  /// In en, this message translates to:
  /// **'Net Cash Flow Trend'**
  String get statsNetCashFlowTrend;

  /// No description provided for @statsMonthlyCashFlow.
  ///
  /// In en, this message translates to:
  /// **'Monthly Cash Flow'**
  String get statsMonthlyCashFlow;

  /// No description provided for @statsRangeDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get statsRangeDaily;

  /// No description provided for @statsRangeWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get statsRangeWeekly;

  /// No description provided for @statsRangeMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get statsRangeMonthly;

  /// No description provided for @statsRangeYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get statsRangeYearly;

  /// No description provided for @statsAllCategories.
  ///
  /// In en, this message translates to:
  /// **'All categories'**
  String get statsAllCategories;

  /// No description provided for @statsDirectAmount.
  ///
  /// In en, this message translates to:
  /// **'{name} (direct)'**
  String statsDirectAmount(String name);

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Update available'**
  String get updateAvailable;

  /// No description provided for @updateUpToDate.
  ///
  /// In en, this message translates to:
  /// **'You\'re up to date'**
  String get updateUpToDate;

  /// No description provided for @updateCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t check for updates'**
  String get updateCheckFailed;

  /// No description provided for @updateNoApk.
  ///
  /// In en, this message translates to:
  /// **'No APK found in the latest release'**
  String get updateNoApk;

  /// No description provided for @updateLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get updateLater;

  /// No description provided for @settingsProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get settingsProfile;

  /// No description provided for @settingsPreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get settingsPreferences;

  /// No description provided for @settingsSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get settingsSecurity;

  /// No description provided for @settingsServer.
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get settingsServer;

  /// No description provided for @settingsData.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get settingsData;

  /// No description provided for @settingsNotLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'Not logged in'**
  String get settingsNotLoggedIn;

  /// No description provided for @settingsEditProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get settingsEditProfile;

  /// No description provided for @settingsDarkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get settingsDarkMode;

  /// No description provided for @settingsDefaultCurrency.
  ///
  /// In en, this message translates to:
  /// **'Default Currency'**
  String get settingsDefaultCurrency;

  /// No description provided for @settingsLocale.
  ///
  /// In en, this message translates to:
  /// **'Locale'**
  String get settingsLocale;

  /// No description provided for @settingsApiAccess.
  ///
  /// In en, this message translates to:
  /// **'API Access'**
  String get settingsApiAccess;

  /// No description provided for @settingsApiAccessSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enable API access for this account'**
  String get settingsApiAccessSubtitle;

  /// No description provided for @settingsBiometric.
  ///
  /// In en, this message translates to:
  /// **'Biometric Unlock'**
  String get settingsBiometric;

  /// No description provided for @settingsBiometricSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Require fingerprint/face to reopen or sign in'**
  String get settingsBiometricSubtitle;

  /// No description provided for @settingsChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get settingsChangePassword;

  /// No description provided for @settingsCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get settingsCurrentPassword;

  /// No description provided for @settingsNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get settingsNewPassword;

  /// No description provided for @settingsConfirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get settingsConfirmNewPassword;

  /// No description provided for @settingsPasswordsMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get settingsPasswordsMismatch;

  /// No description provided for @settingsPasswordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password changed'**
  String get settingsPasswordChanged;

  /// No description provided for @settingsConnectedTo.
  ///
  /// In en, this message translates to:
  /// **'Connected to: {url}'**
  String settingsConnectedTo(String url);

  /// No description provided for @settingsExportData.
  ///
  /// In en, this message translates to:
  /// **'Export data'**
  String get settingsExportData;

  /// No description provided for @settingsImportData.
  ///
  /// In en, this message translates to:
  /// **'Import data'**
  String get settingsImportData;

  /// No description provided for @settingsImportTitle.
  ///
  /// In en, this message translates to:
  /// **'Import data?'**
  String get settingsImportTitle;

  /// No description provided for @settingsImportBody.
  ///
  /// In en, this message translates to:
  /// **'This replaces data on the server with the file contents.'**
  String get settingsImportBody;

  /// No description provided for @settingsImport.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get settingsImport;

  /// No description provided for @settingsImportComplete.
  ///
  /// In en, this message translates to:
  /// **'Import complete'**
  String get settingsImportComplete;

  /// No description provided for @settingsExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String settingsExportFailed(String error);

  /// No description provided for @settingsImportFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed: {error}'**
  String settingsImportFailed(String error);

  /// No description provided for @settingsAdministration.
  ///
  /// In en, this message translates to:
  /// **'Administration'**
  String get settingsAdministration;

  /// No description provided for @settingsAdminPanel.
  ///
  /// In en, this message translates to:
  /// **'Admin Panel'**
  String get settingsAdminPanel;

  /// No description provided for @settingsGlobalApiEnabled.
  ///
  /// In en, this message translates to:
  /// **'Global API Enabled'**
  String get settingsGlobalApiEnabled;

  /// No description provided for @settingsRegistrationEnabled.
  ///
  /// In en, this message translates to:
  /// **'Registration Enabled'**
  String get settingsRegistrationEnabled;

  /// No description provided for @settingsEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get settingsEnable;

  /// No description provided for @settingsDisable.
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get settingsDisable;

  /// No description provided for @settingsDeleteUserBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently removes the user and their data.'**
  String get settingsDeleteUserBody;

  /// No description provided for @settingsChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get settingsChange;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About Cuenti'**
  String get aboutTitle;

  /// No description provided for @aboutTagline.
  ///
  /// In en, this message translates to:
  /// **'A mobile cuenti app'**
  String get aboutTagline;

  /// No description provided for @aboutDescription.
  ///
  /// In en, this message translates to:
  /// **'Cuenti is a personal finance management application that helps you track your transactions, manage accounts, and monitor your assets across different currencies.'**
  String get aboutDescription;

  /// No description provided for @aboutSoftwareInfo.
  ///
  /// In en, this message translates to:
  /// **'Software Info'**
  String get aboutSoftwareInfo;

  /// No description provided for @aboutCheckUpdates.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get aboutCheckUpdates;

  /// No description provided for @aboutVisitWebsite.
  ///
  /// In en, this message translates to:
  /// **'Visit Website'**
  String get aboutVisitWebsite;

  /// No description provided for @updateSkipVersion.
  ///
  /// In en, this message translates to:
  /// **'Skip this version'**
  String get updateSkipVersion;

  /// No description provided for @updateInstall.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get updateInstall;

  /// No description provided for @updateDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed'**
  String get updateDownloadFailed;

  /// No description provided for @updateReady.
  ///
  /// In en, this message translates to:
  /// **'{tag} is ready to install.'**
  String updateReady(String tag);

  /// No description provided for @settingsAutoUpdate.
  ///
  /// In en, this message translates to:
  /// **'Automatic update check'**
  String get settingsAutoUpdate;

  /// No description provided for @settingsAutoUpdateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Look for a new release on GitHub when the app opens'**
  String get settingsAutoUpdateSubtitle;

  /// No description provided for @commonError.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String commonError(String message);

  /// No description provided for @commonDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?'**
  String commonDeleteConfirm(String name);

  /// No description provided for @commonRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get commonRequired;

  /// No description provided for @commonInvalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Invalid number'**
  String get commonInvalidNumber;

  /// No description provided for @commonAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get commonAll;

  /// No description provided for @commonToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get commonToday;

  /// No description provided for @commonYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get commonYesterday;

  /// No description provided for @commonCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get commonCustom;

  /// No description provided for @commonDateRange.
  ///
  /// In en, this message translates to:
  /// **'Date range'**
  String get commonDateRange;

  /// No description provided for @navScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get navScheduled;

  /// No description provided for @navForecasts.
  ///
  /// In en, this message translates to:
  /// **'Forecasts'**
  String get navForecasts;

  /// No description provided for @navAccounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get navAccounts;

  /// No description provided for @navPayees.
  ///
  /// In en, this message translates to:
  /// **'Payees'**
  String get navPayees;

  /// No description provided for @navCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get navCategories;

  /// No description provided for @navTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get navTags;

  /// No description provided for @navCurrencies.
  ///
  /// In en, this message translates to:
  /// **'Currencies'**
  String get navCurrencies;

  /// No description provided for @navAssets.
  ///
  /// In en, this message translates to:
  /// **'Assets'**
  String get navAssets;

  /// No description provided for @navVehicles.
  ///
  /// In en, this message translates to:
  /// **'Vehicles'**
  String get navVehicles;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @navAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get navAbout;

  /// No description provided for @navAuditLog.
  ///
  /// In en, this message translates to:
  /// **'Audit Log'**
  String get navAuditLog;

  /// No description provided for @navGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get navGeneral;

  /// No description provided for @navManagement.
  ///
  /// In en, this message translates to:
  /// **'Management'**
  String get navManagement;

  /// No description provided for @navSettingsSection.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettingsSection;

  /// No description provided for @privacyShow.
  ///
  /// In en, this message translates to:
  /// **'Show amounts'**
  String get privacyShow;

  /// No description provided for @privacyHide.
  ///
  /// In en, this message translates to:
  /// **'Hide amounts'**
  String get privacyHide;

  /// No description provided for @accountsAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Account'**
  String get accountsAddTitle;

  /// No description provided for @accountsEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Account'**
  String get accountsEditTitle;

  /// No description provided for @assetsAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Asset'**
  String get assetsAddTitle;

  /// No description provided for @assetsEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Asset'**
  String get assetsEditTitle;

  /// No description provided for @budgetsAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Budget'**
  String get budgetsAddTitle;

  /// No description provided for @budgetsEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Budget'**
  String get budgetsEditTitle;

  /// No description provided for @categoriesAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Category'**
  String get categoriesAddTitle;

  /// No description provided for @categoriesEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Category'**
  String get categoriesEditTitle;

  /// No description provided for @currenciesAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Currency'**
  String get currenciesAddTitle;

  /// No description provided for @currenciesEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Currency'**
  String get currenciesEditTitle;

  /// No description provided for @payeesAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Payee'**
  String get payeesAddTitle;

  /// No description provided for @payeesEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Payee'**
  String get payeesEditTitle;

  /// No description provided for @tagsAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Tag'**
  String get tagsAddTitle;

  /// No description provided for @tagsEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Tag'**
  String get tagsEditTitle;

  /// No description provided for @txAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Transaction'**
  String get txAddTitle;

  /// No description provided for @txEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Transaction'**
  String get txEditTitle;

  /// No description provided for @txAllAccounts.
  ///
  /// In en, this message translates to:
  /// **'All accounts'**
  String get txAllAccounts;

  /// No description provided for @authBiometricReason.
  ///
  /// In en, this message translates to:
  /// **'Sign in to Cuenti'**
  String get authBiometricReason;

  /// No description provided for @authUnlockReason.
  ///
  /// In en, this message translates to:
  /// **'Authenticate to unlock Cuenti'**
  String get authUnlockReason;

  /// No description provided for @authServerLine.
  ///
  /// In en, this message translates to:
  /// **'Server: {url}'**
  String authServerLine(String url);

  /// No description provided for @assetsNoPrice.
  ///
  /// In en, this message translates to:
  /// **'No price'**
  String get assetsNoPrice;

  /// No description provided for @assetsPriceRefreshed.
  ///
  /// In en, this message translates to:
  /// **'Price refreshed for {symbol}'**
  String assetsPriceRefreshed(String symbol);

  /// No description provided for @statsTransactionsInPeriod.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No transactions in period} =1{1 transaction in period} other{{count} transactions in period}}'**
  String statsTransactionsInPeriod(num count);

  /// No description provided for @vehiclesCustomRange.
  ///
  /// In en, this message translates to:
  /// **'Custom range'**
  String get vehiclesCustomRange;

  /// No description provided for @scheduledDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\" recurring transaction?'**
  String scheduledDeleteBody(String name);

  /// No description provided for @budgetsDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Delete budget for \"{category}\"?'**
  String budgetsDeleteBody(String category);

  /// No description provided for @settingsUsersCount.
  ///
  /// In en, this message translates to:
  /// **'Users ({count})'**
  String settingsUsersCount(String count);

  /// No description provided for @settingsDeleteUserTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {username}?'**
  String settingsDeleteUserTitle(String username);

  /// No description provided for @aboutCopyright.
  ///
  /// In en, this message translates to:
  /// **'© {year} Cuenti Team'**
  String aboutCopyright(String year);

  /// No description provided for @txFuelHint.
  ///
  /// In en, this message translates to:
  /// **'No km/liters entered — this entry will not appear in the vehicle report'**
  String get txFuelHint;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Cannot connect to server'**
  String get errorNetwork;

  /// No description provided for @errorNotAuthenticated.
  ///
  /// In en, this message translates to:
  /// **'Not authenticated'**
  String get errorNotAuthenticated;

  /// No description provided for @errorInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid username or password'**
  String get errorInvalidCredentials;

  /// No description provided for @errorApiDisabled.
  ///
  /// In en, this message translates to:
  /// **'API access is not enabled'**
  String get errorApiDisabled;

  /// No description provided for @errorInvalidRequest.
  ///
  /// In en, this message translates to:
  /// **'Invalid request'**
  String get errorInvalidRequest;

  /// No description provided for @errorInvalidRequestDetail.
  ///
  /// In en, this message translates to:
  /// **'Invalid request: {detail}'**
  String errorInvalidRequestDetail(String detail);

  /// No description provided for @errorServer.
  ///
  /// In en, this message translates to:
  /// **'Server error ({status})'**
  String errorServer(String status);

  /// No description provided for @errorServerDetail.
  ///
  /// In en, this message translates to:
  /// **'Server error ({status}): {detail}'**
  String errorServerDetail(String status, String detail);

  /// No description provided for @errorCertificate.
  ///
  /// In en, this message translates to:
  /// **'The server certificate is not trusted. Re-run Server Setup to check its fingerprint and trust it.'**
  String get errorCertificate;

  /// No description provided for @errorUnknown.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get errorUnknown;

  /// No description provided for @errorNoSavedCredentials.
  ///
  /// In en, this message translates to:
  /// **'No saved credentials'**
  String get errorNoSavedCredentials;

  /// No description provided for @errorSavedPasswordInvalid.
  ///
  /// In en, this message translates to:
  /// **'Saved password no longer valid'**
  String get errorSavedPasswordInvalid;

  /// No description provided for @errorUnexpectedResponse.
  ///
  /// In en, this message translates to:
  /// **'Unexpected response from server'**
  String get errorUnexpectedResponse;

  /// No description provided for @txSaved.
  ///
  /// In en, this message translates to:
  /// **'Transaction saved'**
  String get txSaved;

  /// No description provided for @txDeleted.
  ///
  /// In en, this message translates to:
  /// **'Transaction deleted'**
  String get txDeleted;

  /// No description provided for @txPendingNotSent.
  ///
  /// In en, this message translates to:
  /// **'Not sent yet'**
  String get txPendingNotSent;

  /// No description provided for @txPendingRejected.
  ///
  /// In en, this message translates to:
  /// **'Refused: {reason}'**
  String txPendingRejected(String reason);

  /// No description provided for @txSavedOnDevice.
  ///
  /// In en, this message translates to:
  /// **'Saved on this device — it will send when there is a connection'**
  String get txSavedOnDevice;

  /// No description provided for @txDiscardPending.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get txDiscardPending;

  /// No description provided for @txRetryPending.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get txRetryPending;

  /// No description provided for @accountsSaved.
  ///
  /// In en, this message translates to:
  /// **'Account saved'**
  String get accountsSaved;

  /// No description provided for @accountsDeleted.
  ///
  /// In en, this message translates to:
  /// **'Account deleted'**
  String get accountsDeleted;

  /// No description provided for @categoriesSaved.
  ///
  /// In en, this message translates to:
  /// **'Category saved'**
  String get categoriesSaved;

  /// No description provided for @categoriesDeleted.
  ///
  /// In en, this message translates to:
  /// **'Category deleted'**
  String get categoriesDeleted;

  /// No description provided for @payeesSaved.
  ///
  /// In en, this message translates to:
  /// **'Payee saved'**
  String get payeesSaved;

  /// No description provided for @payeesDeleted.
  ///
  /// In en, this message translates to:
  /// **'Payee deleted'**
  String get payeesDeleted;

  /// No description provided for @tagsSaved.
  ///
  /// In en, this message translates to:
  /// **'Tag saved'**
  String get tagsSaved;

  /// No description provided for @tagsDeleted.
  ///
  /// In en, this message translates to:
  /// **'Tag deleted'**
  String get tagsDeleted;

  /// No description provided for @currenciesSaved.
  ///
  /// In en, this message translates to:
  /// **'Currency saved'**
  String get currenciesSaved;

  /// No description provided for @currenciesDeleted.
  ///
  /// In en, this message translates to:
  /// **'Currency deleted'**
  String get currenciesDeleted;

  /// No description provided for @assetsSaved.
  ///
  /// In en, this message translates to:
  /// **'Asset saved'**
  String get assetsSaved;

  /// No description provided for @assetsDeleted.
  ///
  /// In en, this message translates to:
  /// **'Asset deleted'**
  String get assetsDeleted;

  /// No description provided for @budgetsSaved.
  ///
  /// In en, this message translates to:
  /// **'Budget saved'**
  String get budgetsSaved;

  /// No description provided for @budgetsDeleted.
  ///
  /// In en, this message translates to:
  /// **'Budget deleted'**
  String get budgetsDeleted;

  /// No description provided for @savedViewsSaved.
  ///
  /// In en, this message translates to:
  /// **'View saved'**
  String get savedViewsSaved;

  /// No description provided for @savedViewsDeleted.
  ///
  /// In en, this message translates to:
  /// **'View deleted'**
  String get savedViewsDeleted;

  /// No description provided for @settingsProfileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved'**
  String get settingsProfileSaved;

  /// No description provided for @offlineBannerSince.
  ///
  /// In en, this message translates to:
  /// **'Offline — figures from {when}'**
  String offlineBannerSince(String when);

  /// No description provided for @accountsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search accounts...'**
  String get accountsSearchHint;

  /// No description provided for @accountsNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No accounts match'**
  String get accountsNoMatch;

  /// No description provided for @payeesSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search payees...'**
  String get payeesSearchHint;

  /// No description provided for @payeesNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No payees match'**
  String get payeesNoMatch;

  /// No description provided for @categoriesSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search categories...'**
  String get categoriesSearchHint;

  /// No description provided for @categoriesNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No categories match'**
  String get categoriesNoMatch;

  /// No description provided for @tagsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search tags...'**
  String get tagsSearchHint;

  /// No description provided for @tagsNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No tags match'**
  String get tagsNoMatch;

  /// No description provided for @currenciesSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search currencies...'**
  String get currenciesSearchHint;

  /// No description provided for @currenciesNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No currencies match'**
  String get currenciesNoMatch;

  /// No description provided for @assetsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search assets...'**
  String get assetsSearchHint;

  /// No description provided for @assetsNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No assets match'**
  String get assetsNoMatch;

  /// No description provided for @commonSortCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom order'**
  String get commonSortCustom;

  /// No description provided for @commonCode.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get commonCode;

  /// No description provided for @commonSymbol.
  ///
  /// In en, this message translates to:
  /// **'Symbol'**
  String get commonSymbol;

  /// No description provided for @commonPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get commonPrice;

  /// No description provided for @accountTypeBank.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get accountTypeBank;

  /// No description provided for @accountTypeCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get accountTypeCash;

  /// No description provided for @accountTypeAsset.
  ///
  /// In en, this message translates to:
  /// **'Asset'**
  String get accountTypeAsset;

  /// No description provided for @accountTypeCreditCard.
  ///
  /// In en, this message translates to:
  /// **'Credit Card'**
  String get accountTypeCreditCard;

  /// No description provided for @accountTypeLiability.
  ///
  /// In en, this message translates to:
  /// **'Liability'**
  String get accountTypeLiability;

  /// No description provided for @accountTypeCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current Account'**
  String get accountTypeCurrent;

  /// No description provided for @accountTypeSavings.
  ///
  /// In en, this message translates to:
  /// **'Savings Account'**
  String get accountTypeSavings;

  /// No description provided for @assetTypeStock.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get assetTypeStock;

  /// No description provided for @assetTypeEtf.
  ///
  /// In en, this message translates to:
  /// **'ETF'**
  String get assetTypeEtf;

  /// No description provided for @assetTypeCrypto.
  ///
  /// In en, this message translates to:
  /// **'Crypto'**
  String get assetTypeCrypto;

  /// No description provided for @paymentMethodCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get paymentMethodCash;

  /// No description provided for @paymentMethodBankTransfer.
  ///
  /// In en, this message translates to:
  /// **'Bank Transfer'**
  String get paymentMethodBankTransfer;

  /// No description provided for @sortAscending.
  ///
  /// In en, this message translates to:
  /// **'Ascending'**
  String get sortAscending;

  /// No description provided for @sortDescending.
  ///
  /// In en, this message translates to:
  /// **'Descending'**
  String get sortDescending;

  /// No description provided for @recurrenceDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get recurrenceDaily;

  /// No description provided for @recurrenceWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get recurrenceWeekly;

  /// No description provided for @recurrenceBiWeekly.
  ///
  /// In en, this message translates to:
  /// **'Fortnightly'**
  String get recurrenceBiWeekly;

  /// No description provided for @recurrenceMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get recurrenceMonthly;

  /// No description provided for @recurrenceMonthlyLastDay.
  ///
  /// In en, this message translates to:
  /// **'Monthly (last day)'**
  String get recurrenceMonthlyLastDay;

  /// No description provided for @recurrenceYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get recurrenceYearly;

  /// No description provided for @validationMinCharacters.
  ///
  /// In en, this message translates to:
  /// **'Minimum {count} characters'**
  String validationMinCharacters(int count);

  /// No description provided for @validationInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get validationInvalidEmail;

  /// No description provided for @authPasswordsMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get authPasswordsMismatch;

  /// No description provided for @aboutVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get aboutVersion;

  /// No description provided for @aboutBuildNumber.
  ///
  /// In en, this message translates to:
  /// **'Build Number'**
  String get aboutBuildNumber;

  /// No description provided for @aboutBuildDate.
  ///
  /// In en, this message translates to:
  /// **'Build Date'**
  String get aboutBuildDate;

  /// No description provided for @aboutBuildTime.
  ///
  /// In en, this message translates to:
  /// **'Build Time'**
  String get aboutBuildTime;

  /// No description provided for @scheduledSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search scheduled...'**
  String get scheduledSearchHint;

  /// No description provided for @scheduledNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No scheduled transactions match'**
  String get scheduledNoMatch;

  /// No description provided for @commonNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get commonNext;

  /// No description provided for @budgetsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search budgets...'**
  String get budgetsSearchHint;

  /// No description provided for @budgetsNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No budgets match'**
  String get budgetsNoMatch;

  /// No description provided for @budgetsSpent.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get budgetsSpent;

  /// No description provided for @scheduledOverdue.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 overdue} other{{count} overdue}}'**
  String scheduledOverdue(num count);

  /// No description provided for @paymentMethodDebitCard.
  ///
  /// In en, this message translates to:
  /// **'Debit Card'**
  String get paymentMethodDebitCard;

  /// No description provided for @paymentMethodStandingOrder.
  ///
  /// In en, this message translates to:
  /// **'Standing Order'**
  String get paymentMethodStandingOrder;

  /// No description provided for @paymentMethodElectronic.
  ///
  /// In en, this message translates to:
  /// **'Electronic Payment'**
  String get paymentMethodElectronic;

  /// No description provided for @paymentMethodBankFee.
  ///
  /// In en, this message translates to:
  /// **'Bank Fee'**
  String get paymentMethodBankFee;

  /// No description provided for @paymentMethodCardTransaction.
  ///
  /// In en, this message translates to:
  /// **'Card Transaction'**
  String get paymentMethodCardTransaction;

  /// No description provided for @paymentMethodTrade.
  ///
  /// In en, this message translates to:
  /// **'Trade'**
  String get paymentMethodTrade;

  /// No description provided for @paymentMethodReward.
  ///
  /// In en, this message translates to:
  /// **'Reward'**
  String get paymentMethodReward;

  /// No description provided for @paymentMethodInterest.
  ///
  /// In en, this message translates to:
  /// **'Interest'**
  String get paymentMethodInterest;

  /// No description provided for @categoryCreate.
  ///
  /// In en, this message translates to:
  /// **'Create \"{name}\"'**
  String categoryCreate(String name);

  /// No description provided for @categoryCreateUnder.
  ///
  /// In en, this message translates to:
  /// **'under {parent}'**
  String categoryCreateUnder(String parent);

  /// No description provided for @categoryCreateTopLevel.
  ///
  /// In en, this message translates to:
  /// **'New top-level category'**
  String get categoryCreateTopLevel;

  /// No description provided for @logoutPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Unsent transactions'**
  String get logoutPendingTitle;

  /// No description provided for @logoutPendingBody.
  ///
  /// In en, this message translates to:
  /// **'{count} transactions have not reached the server. Signing out will discard them.'**
  String logoutPendingBody(int count);
}

class _LDelegate extends LocalizationsDelegate<L> {
  const _LDelegate();

  @override
  Future<L> load(Locale locale) {
    return SynchronousFuture<L>(lookupL(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_LDelegate old) => false;
}

L lookupL(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return LDe();
    case 'en':
      return LEn();
    case 'it':
      return LIt();
  }

  throw FlutterError(
    'L.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
