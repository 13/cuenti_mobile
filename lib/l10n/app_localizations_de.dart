// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class LDe extends L {
  LDe([String locale = 'de']) : super(locale);

  @override
  String get commonSave => 'Speichern';

  @override
  String get commonCancel => 'Abbrechen';

  @override
  String get commonDelete => 'Löschen';

  @override
  String get commonClose => 'Schließen';

  @override
  String get commonEdit => 'Bearbeiten';

  @override
  String get commonRetry => 'Erneut versuchen';

  @override
  String get commonName => 'Name';

  @override
  String get commonType => 'Typ';

  @override
  String get commonCurrency => 'Währung';

  @override
  String get commonAmount => 'Betrag';

  @override
  String get commonMemo => 'Notiz';

  @override
  String get commonNone => 'Keine';

  @override
  String get commonNoData => 'Keine Daten';

  @override
  String get commonAccount => 'Konto';

  @override
  String get commonExpense => 'Ausgabe';

  @override
  String get commonIncome => 'Einnahme';

  @override
  String get commonTransfer => 'Umbuchung';

  @override
  String get commonClearFilters => 'Filter zurücksetzen';

  @override
  String get commonEmail => 'E-Mail';

  @override
  String get commonPassword => 'Passwort';

  @override
  String get commonUsername => 'Benutzername';

  @override
  String get commonFirstName => 'Vorname';

  @override
  String get commonLastName => 'Nachname';

  @override
  String get commonGroup => 'Gruppe';

  @override
  String get commonUndoWarning =>
      'Diese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get offlineBanner =>
      'Offline — angezeigt werden die zuletzt geladenen Zahlen';

  @override
  String get navDashboard => 'Übersicht';

  @override
  String get navTransactions => 'Buchungen';

  @override
  String get navBudgets => 'Budgets';

  @override
  String get navStatistics => 'Statistiken';

  @override
  String get actionRefresh => 'Aktualisieren';

  @override
  String get actionLogout => 'Abmelden';

  @override
  String get authSignInTitle => 'Anmelden';

  @override
  String get authSignInButton => 'Anmelden';

  @override
  String get authSignInBiometrics => 'Mit Biometrie anmelden';

  @override
  String get authNotYou => 'Nicht Sie?';

  @override
  String get authNoAccountRegister => 'Noch kein Konto? Registrieren';

  @override
  String get authHaveAccountSignIn => 'Bereits ein Konto? Anmelden';

  @override
  String get authRegister => 'Registrieren';

  @override
  String get authCreateAccount => 'Konto erstellen';

  @override
  String get authConfirmPassword => 'Passwort bestätigen';

  @override
  String get authLockedTitle => 'Cuenti ist gesperrt';

  @override
  String get authUnlock => 'Entsperren';

  @override
  String get authShowPassword => 'Passwort anzeigen';

  @override
  String get authHidePassword => 'Passwort verbergen';

  @override
  String get serverSetupTitle => 'Servereinrichtung';

  @override
  String get serverUrl => 'Server-URL';

  @override
  String get serverSaveContinue => 'Speichern & weiter';

  @override
  String get serverTrust => 'Vertrauen';

  @override
  String get serverUntrustedTitle => 'Unbekanntes Zertifikat';

  @override
  String get serverInsecureTitle => 'Unverschlüsselte Verbindung';

  @override
  String serverInsecureBody(String host) {
    return '$host wird über http erreicht. Ihr Passwort, Ihre Sitzung und alles, was diese App lädt, werden dabei unverschlüsselt übertragen und sind für jeden im selben Netz lesbar. Verwenden Sie https, sofern Sie nicht jedem Gerät in diesem Netz vertrauen.';
  }

  @override
  String get serverInsecureContinue => 'Trotzdem http verwenden';

  @override
  String serverUntrustedBody(String host) {
    return '$host hat ein Zertifikat vorgelegt, für das keine Zertifizierungsstelle bürgt. Bei einem selbst gehosteten Cuenti-Server ist das normal, aber genauso sieht auch eine abgefangene Verbindung aus. Vertrauen Sie ihm nur, wenn dieser Fingerabdruck zu Ihrem Server passt.';
  }

  @override
  String get serverChange => 'Server wechseln';

  @override
  String get accountsEmpty => 'Noch keine Konten';

  @override
  String get accountsAdd => 'Konto hinzufügen';

  @override
  String get accountsDeleteTitle => 'Konto löschen?';

  @override
  String get accountsDeleteBody =>
      'Alle zugehörigen Buchungen sind davon betroffen.';

  @override
  String get accountsInstitution => 'Institut';

  @override
  String get accountsStartBalance => 'Anfangssaldo';

  @override
  String get accountsExcludeSummary => 'Nicht in Übersicht';

  @override
  String get accountsExcludeReports => 'Nicht in Berichten';

  @override
  String get assetsEmpty => 'Noch keine Anlagen';

  @override
  String get assetsAdd => 'Anlage hinzufügen';

  @override
  String get assetsDeleteTitle => 'Anlage löschen?';

  @override
  String get assetsSymbolHint => 'Symbol (z. B. VWCE.DE)';

  @override
  String get assetsRefreshPrice => 'Kurs aktualisieren';

  @override
  String get currenciesEmpty => 'Noch keine Währungen';

  @override
  String get currenciesAdd => 'Währung hinzufügen';

  @override
  String get currenciesDeleteTitle => 'Währung löschen?';

  @override
  String get currenciesCodeHint => 'Code (z. B. EUR)';

  @override
  String get currenciesNameHint => 'Name (z. B. Euro)';

  @override
  String get currenciesSymbolHint => 'Symbol (z. B. €)';

  @override
  String get currenciesDecimals => 'Nachkommastellen';

  @override
  String get currenciesDecimal => 'Dezimaltrennzeichen';

  @override
  String get currenciesGrouping => 'Tausendertrennzeichen';

  @override
  String get tagsEmpty => 'Noch keine Tags';

  @override
  String get tagsAdd => 'Tag hinzufügen';

  @override
  String get tagsDeleteTitle => 'Tag löschen?';

  @override
  String get payeesEmpty => 'Noch keine Empfänger';

  @override
  String get payeesAdd => 'Empfänger hinzufügen';

  @override
  String get payeesDeleteTitle => 'Empfänger löschen?';

  @override
  String get payeesNotes => 'Notizen';

  @override
  String get payeesDefaultCategory => 'Standardkategorie';

  @override
  String get payeesDefaultPayment => 'Standardzahlweise';

  @override
  String get payeeLabel => 'Empfänger';

  @override
  String get categoriesEmpty => 'Noch keine Kategorien';

  @override
  String get categoriesAdd => 'Kategorie hinzufügen';

  @override
  String get categoriesDeleteTitle => 'Kategorie löschen?';

  @override
  String get categoriesEditOne => 'Kategorie bearbeiten';

  @override
  String get categoriesDeleteOne => 'Kategorie löschen';

  @override
  String get categoriesParent => 'Übergeordnete Kategorie';

  @override
  String get categoriesTopLevel => 'Keine (oberste Ebene)';

  @override
  String get categoryLabel => 'Kategorie';

  @override
  String get categorySearchClear => 'Suche löschen';

  @override
  String get categorySearchEmpty => 'Keine passenden Kategorien';

  @override
  String categorySearchHint(String what) {
    return '$what suchen';
  }

  @override
  String get txEmpty => 'Noch keine Buchungen';

  @override
  String get txNoMatch => 'Keine passenden Buchungen';

  @override
  String get txAdd => 'Buchung hinzufügen';

  @override
  String get txSearchHint => 'Buchungen durchsuchen …';

  @override
  String get txDeleteTitle => 'Buchung löschen?';

  @override
  String get txTypeFilter => 'Buchungsart';

  @override
  String get txFromAccount => 'Von Konto';

  @override
  String get txToAccount => 'Auf Konto';

  @override
  String get txPaymentMethod => 'Zahlungsart';

  @override
  String get txTagsHint => 'Tags (durch Komma getrennt)';

  @override
  String get txSplits => 'Aufteilungen';

  @override
  String get txAddSplit => 'Aufteilung hinzufügen';

  @override
  String get txRemoveSplit => 'Aufteilung entfernen';

  @override
  String get txSplitNeedsCategory => 'Jede Aufteilung braucht eine Kategorie';

  @override
  String txSplitSumMismatch(String sum, String total) {
    return 'Aufteilungen müssen den Betrag ergeben: $sum von $total';
  }

  @override
  String get txRequired => 'Pflichtfeld';

  @override
  String get txInvalidNumber => 'Ungültige Zahl';

  @override
  String get fuelOdometer => 'Kilometerstand (km)';

  @override
  String get fuelLiters => 'Liter';

  @override
  String get fuelFullTank => 'Volltankung';

  @override
  String fuelLastReading(String value) {
    return 'zuletzt: $value';
  }

  @override
  String get fuelImplausibleLiters => 'Unplausible Literangabe';

  @override
  String fuelNotIncreasing(String last) {
    return 'Kilometerstand ist nicht höher als zuletzt ($last)';
  }

  @override
  String fuelLargeJump(String distance) {
    return 'Sehr großer Sprung seit der letzten Ablesung ($distance km) — Tippfehler?';
  }

  @override
  String fuelConsumption(String distance, String consumption) {
    return '$distance km seit dem letzten Mal, ca. $consumption l/100 km';
  }

  @override
  String fuelDistanceOnly(String distance) {
    return '$distance km seit der letzten Tankfüllung';
  }

  @override
  String get vehiclesChooseCategory => 'Kategorie wählen';

  @override
  String get vehiclesFuelCategory => 'Tankkategorie';

  @override
  String get vehiclesSetDefault => 'Als Standard festlegen';

  @override
  String get vehiclesDefaultSaved => 'Standard gespeichert';

  @override
  String get vehiclesPickPrompt =>
      'Wählen Sie eine Tankkategorie für den Fahrzeugbericht';

  @override
  String get vehiclesNoEntries => 'Keine Tankvorgänge in diesem Zeitraum';

  @override
  String get vehiclesNotEnoughData => 'Zu wenig Daten für ein Diagramm';

  @override
  String get vehiclesThisYear => 'Dieses Jahr';

  @override
  String get vehiclesTotalCost => 'Gesamtkosten';

  @override
  String get vehiclesDistance => 'Strecke';

  @override
  String get vehiclesAvgConsumption => '⌀ Verbrauch';

  @override
  String get vehiclesAvgPricePerLiter => '⌀ Preis/l';

  @override
  String get vehiclesFull => 'Voll';

  @override
  String get budgetsEmpty => 'Noch keine Budgets';

  @override
  String get budgetsAdd => 'Budget hinzufügen';

  @override
  String get budgetsDeleteTitle => 'Budget löschen?';

  @override
  String get budgetsMonthlyLimit => 'Monatslimit';

  @override
  String get budgetsActive => 'Aktiv';

  @override
  String get budgetsRemaining => 'Verbleibend: ';

  @override
  String get budgetsSelectCategory => 'Kategorie wählen';

  @override
  String get scheduledEmpty => 'Keine geplanten Buchungen';

  @override
  String get scheduledDeleteTitle => 'Planung löschen?';

  @override
  String get scheduledPost => 'Buchen';

  @override
  String get scheduledSkip => 'Überspringen';

  @override
  String get scheduledPosted => 'Buchung gebucht';

  @override
  String get scheduledSkipped => 'Termin übersprungen';

  @override
  String get savedViewsTitle => 'Gespeicherte Ansichten';

  @override
  String get savedViewsEmpty => 'Noch keine gespeicherten Ansichten';

  @override
  String get savedViewsSaveCurrent => 'Aktuelle Ansicht speichern';

  @override
  String get savedViewsDeleteTitle => 'Gespeicherte Ansicht löschen?';

  @override
  String get savedViewsDeleteOne => 'Ansicht löschen';

  @override
  String get savedViewsFromWeb => 'In der Web-App gespeichert';

  @override
  String get auditEmpty => 'Keine Protokolleinträge';

  @override
  String get auditNoMatch => 'Keine passenden Protokolleinträge';

  @override
  String get auditSearchHint => 'Protokoll durchsuchen …';

  @override
  String get auditTitle => 'Protokoll';

  @override
  String get dashboardNetWorth => 'Nettovermögen';

  @override
  String get dashboardCash => 'Barmittel';

  @override
  String get dashboardPortfolio => 'Portfolio';

  @override
  String get dashboardNoAccounts => 'Keine Konten';

  @override
  String get forecastsNet => 'Saldo';

  @override
  String get forecastsMonthlyForecast => 'Monatsprognose';

  @override
  String get forecastsBreakdown => 'Aufschlüsselung';

  @override
  String get vehiclesConsumption => 'Verbrauch';

  @override
  String get vehiclesEntries => 'Einträge';

  @override
  String get statsAllAccounts => 'Alle Konten';

  @override
  String get statsIncomeByCategory => 'Einnahmen nach Kategorie';

  @override
  String get statsExpenseByCategory => 'Ausgaben nach Kategorie';

  @override
  String get statsTotal => 'Gesamt';

  @override
  String get statsOverview => 'Übersicht';

  @override
  String get scheduledLate => '(ÜBERFÄLLIG!)';

  @override
  String dashboardAssetUnits(String units, String symbol) {
    return '$units Einheiten · $symbol';
  }

  @override
  String scheduledNextOn(String pattern, String date) {
    return '$pattern · Nächste: $date';
  }

  @override
  String currenciesFormatSummary(
    String symbol,
    String digits,
    String decimal,
    String grouping,
  ) {
    return 'Symbol $symbol · $digits Nachkommastellen · $decimal $grouping';
  }

  @override
  String get a11yChartIncomeExpense => 'Diagramm: Einnahmen und Ausgaben';

  @override
  String get a11yChartCashFlow => 'Diagramm: Saldoentwicklung';

  @override
  String get a11yChartMonthlyCashFlow => 'Diagramm: monatlicher Verlauf';

  @override
  String get a11yChartCategories => 'Diagramm: Kategorien';

  @override
  String get commonBalance => 'Saldo';

  @override
  String get statsSavingsRate => 'Sparquote';

  @override
  String get statsIncomeVsExpense => 'Einnahmen und Ausgaben';

  @override
  String get statsNetCashFlowTrend => 'Entwicklung des Saldos';

  @override
  String get statsMonthlyCashFlow => 'Monatlicher Verlauf';

  @override
  String get statsRangeDaily => 'Täglich';

  @override
  String get statsRangeWeekly => 'Wöchentlich';

  @override
  String get statsRangeMonthly => 'Monatlich';

  @override
  String get statsRangeYearly => 'Jährlich';

  @override
  String get statsAllCategories => 'Alle Kategorien';

  @override
  String statsDirectAmount(String name) {
    return '$name (direkt)';
  }

  @override
  String get updateAvailable => 'Update verfügbar';

  @override
  String get updateUpToDate => 'Sie sind auf dem neuesten Stand';

  @override
  String get updateCheckFailed => 'Update-Prüfung fehlgeschlagen';

  @override
  String get updateNoApk => 'Kein APK im neuesten Release gefunden';

  @override
  String get updateLater => 'Später';

  @override
  String get settingsProfile => 'Profil';

  @override
  String get settingsPreferences => 'Einstellungen';

  @override
  String get settingsSecurity => 'Sicherheit';

  @override
  String get settingsServer => 'Server';

  @override
  String get settingsData => 'Daten';

  @override
  String get settingsNotLoggedIn => 'Nicht angemeldet';

  @override
  String get settingsEditProfile => 'Profil bearbeiten';

  @override
  String get settingsDarkMode => 'Dunkler Modus';

  @override
  String get settingsDefaultCurrency => 'Standardwährung';

  @override
  String get settingsLocale => 'Sprache';

  @override
  String get settingsApiAccess => 'API-Zugriff';

  @override
  String get settingsApiAccessSubtitle =>
      'API-Zugriff für dieses Konto aktivieren';

  @override
  String get settingsBiometric => 'Biometrische Entsperrung';

  @override
  String get settingsBiometricSubtitle =>
      'Fingerabdruck/Gesicht zum Öffnen und Anmelden verlangen';

  @override
  String get settingsChangePassword => 'Passwort ändern';

  @override
  String get settingsCurrentPassword => 'Aktuelles Passwort';

  @override
  String get settingsNewPassword => 'Neues Passwort';

  @override
  String get settingsConfirmNewPassword => 'Neues Passwort bestätigen';

  @override
  String get settingsPasswordsMismatch => 'Passwörter stimmen nicht überein';

  @override
  String get settingsPasswordChanged => 'Passwort geändert';

  @override
  String settingsConnectedTo(String url) {
    return 'Verbunden mit: $url';
  }

  @override
  String get settingsExportData => 'Daten exportieren';

  @override
  String get settingsImportData => 'Daten importieren';

  @override
  String get settingsImportTitle => 'Daten importieren?';

  @override
  String get settingsImportBody =>
      'Dies ersetzt die Daten auf dem Server durch den Dateiinhalt.';

  @override
  String get settingsImport => 'Importieren';

  @override
  String get settingsImportComplete => 'Import abgeschlossen';

  @override
  String settingsExportFailed(String error) {
    return 'Export fehlgeschlagen: $error';
  }

  @override
  String settingsImportFailed(String error) {
    return 'Import fehlgeschlagen: $error';
  }

  @override
  String get settingsAdministration => 'Administration';

  @override
  String get settingsAdminPanel => 'Adminbereich';

  @override
  String get settingsGlobalApiEnabled => 'Globale API aktiviert';

  @override
  String get settingsRegistrationEnabled => 'Registrierung aktiviert';

  @override
  String get settingsEnable => 'Aktivieren';

  @override
  String get settingsDisable => 'Deaktivieren';

  @override
  String get settingsDeleteUserBody =>
      'Dies entfernt den Benutzer und seine Daten dauerhaft.';

  @override
  String get settingsChange => 'Ändern';

  @override
  String get settingsAbout => 'Über';

  @override
  String get aboutTitle => 'Über Cuenti';

  @override
  String get aboutTagline => 'Die mobile Cuenti-App';

  @override
  String get aboutDescription =>
      'Cuenti ist eine Anwendung für die private Finanzverwaltung: Buchungen erfassen, Konten verwalten und Anlagen über verschiedene Währungen hinweg im Blick behalten.';

  @override
  String get aboutSoftwareInfo => 'Softwareinfo';

  @override
  String get aboutCheckUpdates => 'Nach Updates suchen';

  @override
  String get aboutVisitWebsite => 'Website besuchen';

  @override
  String get updateSkipVersion => 'Diese Version überspringen';

  @override
  String get updateInstall => 'Aktualisieren';

  @override
  String get updateDownloadFailed => 'Download fehlgeschlagen';

  @override
  String updateReady(String tag) {
    return '$tag kann installiert werden.';
  }

  @override
  String get settingsAutoUpdate => 'Automatische Update-Prüfung';

  @override
  String get settingsAutoUpdateSubtitle =>
      'Beim Öffnen der App auf GitHub nach einer neuen Version suchen';

  @override
  String commonError(String message) {
    return 'Fehler: $message';
  }

  @override
  String commonDeleteConfirm(String name) {
    return 'Möchten Sie \"$name\" löschen?';
  }

  @override
  String get commonRequired => 'Pflichtfeld';

  @override
  String get commonInvalidNumber => 'Ungültige Zahl';

  @override
  String get commonAll => 'Alle';

  @override
  String get commonToday => 'Heute';

  @override
  String get commonYesterday => 'Gestern';

  @override
  String get commonCustom => 'Benutzerdefiniert';

  @override
  String get commonDateRange => 'Zeitraum';

  @override
  String get navScheduled => 'Geplant';

  @override
  String get navForecasts => 'Prognosen';

  @override
  String get navAccounts => 'Konten';

  @override
  String get navPayees => 'Empfänger';

  @override
  String get navCategories => 'Kategorien';

  @override
  String get navTags => 'Tags';

  @override
  String get navCurrencies => 'Währungen';

  @override
  String get navAssets => 'Anlagen';

  @override
  String get navVehicles => 'Fahrzeuge';

  @override
  String get navSettings => 'Einstellungen';

  @override
  String get navAbout => 'Über';

  @override
  String get navAuditLog => 'Protokoll';

  @override
  String get navGeneral => 'Allgemein';

  @override
  String get navManagement => 'Verwaltung';

  @override
  String get navSettingsSection => 'Einstellungen';

  @override
  String get privacyShow => 'Beträge anzeigen';

  @override
  String get privacyHide => 'Beträge verbergen';

  @override
  String get accountsAddTitle => 'Konto hinzufügen';

  @override
  String get accountsEditTitle => 'Konto bearbeiten';

  @override
  String get assetsAddTitle => 'Anlage hinzufügen';

  @override
  String get assetsEditTitle => 'Anlage bearbeiten';

  @override
  String get budgetsAddTitle => 'Budget hinzufügen';

  @override
  String get budgetsEditTitle => 'Budget bearbeiten';

  @override
  String get categoriesAddTitle => 'Kategorie hinzufügen';

  @override
  String get categoriesEditTitle => 'Kategorie bearbeiten';

  @override
  String get currenciesAddTitle => 'Währung hinzufügen';

  @override
  String get currenciesEditTitle => 'Währung bearbeiten';

  @override
  String get payeesAddTitle => 'Empfänger hinzufügen';

  @override
  String get payeesEditTitle => 'Empfänger bearbeiten';

  @override
  String get tagsAddTitle => 'Tag hinzufügen';

  @override
  String get tagsEditTitle => 'Tag bearbeiten';

  @override
  String get txAddTitle => 'Buchung hinzufügen';

  @override
  String get txEditTitle => 'Buchung bearbeiten';

  @override
  String get txAllAccounts => 'Alle Konten';

  @override
  String get authBiometricReason => 'Bei Cuenti anmelden';

  @override
  String get authUnlockReason => 'Zum Entsperren von Cuenti authentifizieren';

  @override
  String authServerLine(String url) {
    return 'Server: $url';
  }

  @override
  String get assetsNoPrice => 'Kein Kurs';

  @override
  String assetsPriceRefreshed(String symbol) {
    return 'Kurs für $symbol aktualisiert';
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
      other: '$countString Buchungen im Zeitraum',
      one: '1 Buchung im Zeitraum',
      zero: 'Keine Buchungen im Zeitraum',
    );
    return '$_temp0';
  }

  @override
  String get vehiclesCustomRange => 'Eigener Zeitraum';

  @override
  String scheduledDeleteBody(String name) {
    return 'Wiederkehrende Buchung \"$name\" löschen?';
  }

  @override
  String budgetsDeleteBody(String category) {
    return 'Budget für \"$category\" löschen?';
  }

  @override
  String settingsUsersCount(String count) {
    return 'Benutzer ($count)';
  }

  @override
  String settingsDeleteUserTitle(String username) {
    return '$username löschen?';
  }

  @override
  String aboutCopyright(String year) {
    return '© $year Cuenti Team';
  }

  @override
  String get txFuelHint =>
      'Keine km/Liter eingetragen — dieser Eintrag erscheint nicht im Fahrzeugbericht';

  @override
  String get errorNetwork => 'Keine Verbindung zum Server';

  @override
  String get errorNotAuthenticated => 'Nicht angemeldet';

  @override
  String get errorInvalidCredentials => 'Benutzername oder Passwort ist falsch';

  @override
  String get errorApiDisabled => 'API-Zugriff ist nicht aktiviert';

  @override
  String get errorInvalidRequest => 'Ungültige Anfrage';

  @override
  String errorInvalidRequestDetail(String detail) {
    return 'Ungültige Anfrage: $detail';
  }

  @override
  String errorServer(String status) {
    return 'Serverfehler ($status)';
  }

  @override
  String errorServerDetail(String status, String detail) {
    return 'Serverfehler ($status): $detail';
  }

  @override
  String get errorCertificate =>
      'Dem Serverzertifikat wird nicht vertraut. Führen Sie die Servereinrichtung erneut aus, um den Fingerabdruck zu prüfen und ihm zu vertrauen.';

  @override
  String get errorUnknown => 'Ein Fehler ist aufgetreten';

  @override
  String get errorNoSavedCredentials => 'Keine gespeicherten Zugangsdaten';

  @override
  String get errorSavedPasswordInvalid =>
      'Gespeichertes Passwort ist nicht mehr gültig';

  @override
  String get errorUnexpectedResponse => 'Unerwartete Antwort vom Server';

  @override
  String get txSaved => 'Buchung gespeichert';

  @override
  String get txDeleted => 'Buchung gelöscht';

  @override
  String get txPendingNotSent => 'Noch nicht gesendet';

  @override
  String txPendingRejected(String reason) {
    return 'Abgelehnt: $reason';
  }

  @override
  String get txPendingRefused => 'Abgelehnt';

  @override
  String get txSavedOnDevice =>
      'Auf diesem Gerät gespeichert — wird gesendet, sobald eine Verbindung besteht';

  @override
  String get txDiscardPending => 'Verwerfen';

  @override
  String get txRetryPending => 'Erneut versuchen';

  @override
  String get accountsSaved => 'Konto gespeichert';

  @override
  String get accountsDeleted => 'Konto gelöscht';

  @override
  String get categoriesSaved => 'Kategorie gespeichert';

  @override
  String get categoriesDeleted => 'Kategorie gelöscht';

  @override
  String get payeesSaved => 'Empfänger gespeichert';

  @override
  String get payeesDeleted => 'Empfänger gelöscht';

  @override
  String get tagsSaved => 'Tag gespeichert';

  @override
  String get tagsDeleted => 'Tag gelöscht';

  @override
  String get currenciesSaved => 'Währung gespeichert';

  @override
  String get currenciesDeleted => 'Währung gelöscht';

  @override
  String get assetsSaved => 'Anlage gespeichert';

  @override
  String get assetsDeleted => 'Anlage gelöscht';

  @override
  String get budgetsSaved => 'Budget gespeichert';

  @override
  String get budgetsDeleted => 'Budget gelöscht';

  @override
  String get savedViewsSaved => 'Ansicht gespeichert';

  @override
  String get savedViewsDeleted => 'Ansicht gelöscht';

  @override
  String get settingsProfileSaved => 'Profil gespeichert';

  @override
  String offlineBannerSince(String when) {
    return 'Offline — Zahlen von $when';
  }

  @override
  String get accountsSearchHint => 'Konten durchsuchen...';

  @override
  String get accountsNoMatch => 'Keine Konten gefunden';

  @override
  String get payeesSearchHint => 'Empfänger durchsuchen...';

  @override
  String get payeesNoMatch => 'Keine Empfänger gefunden';

  @override
  String get categoriesSearchHint => 'Kategorien durchsuchen...';

  @override
  String get categoriesNoMatch => 'Keine Kategorien gefunden';

  @override
  String get tagsSearchHint => 'Tags durchsuchen...';

  @override
  String get tagsNoMatch => 'Keine Tags gefunden';

  @override
  String get currenciesSearchHint => 'Währungen durchsuchen...';

  @override
  String get currenciesNoMatch => 'Keine Währungen gefunden';

  @override
  String get assetsSearchHint => 'Anlagen durchsuchen...';

  @override
  String get assetsNoMatch => 'Keine Anlagen gefunden';

  @override
  String get commonSortCustom => 'Eigene Reihenfolge';

  @override
  String get commonCode => 'Kürzel';

  @override
  String get commonSymbol => 'Symbol';

  @override
  String get commonPrice => 'Preis';

  @override
  String get accountTypeBank => 'Bank';

  @override
  String get accountTypeCash => 'Bargeld';

  @override
  String get accountTypeAsset => 'Anlage';

  @override
  String get accountTypeCreditCard => 'Kreditkarte';

  @override
  String get accountTypeLiability => 'Verbindlichkeit';

  @override
  String get accountTypeCurrent => 'Girokonto';

  @override
  String get accountTypeSavings => 'Sparkonto';

  @override
  String get assetTypeStock => 'Aktie';

  @override
  String get assetTypeEtf => 'ETF';

  @override
  String get assetTypeCrypto => 'Krypto';

  @override
  String get paymentMethodCash => 'Bargeld';

  @override
  String get paymentMethodBankTransfer => 'Überweisung';

  @override
  String get sortAscending => 'Aufsteigend';

  @override
  String get sortDescending => 'Absteigend';

  @override
  String get recurrenceDaily => 'Täglich';

  @override
  String get recurrenceWeekly => 'Wöchentlich';

  @override
  String get recurrenceBiWeekly => 'Zweiwöchentlich';

  @override
  String get recurrenceMonthly => 'Monatlich';

  @override
  String get recurrenceMonthlyLastDay => 'Monatlich (letzter Tag)';

  @override
  String get recurrenceYearly => 'Jährlich';

  @override
  String validationMinCharacters(int count) {
    return 'Mindestens $count Zeichen';
  }

  @override
  String get validationInvalidEmail => 'Ungültige E-Mail';

  @override
  String get authPasswordsMismatch => 'Passwörter stimmen nicht überein';

  @override
  String get aboutVersion => 'Version';

  @override
  String get aboutBuildNumber => 'Build-Nummer';

  @override
  String get aboutBuildDate => 'Build-Datum';

  @override
  String get aboutBuildTime => 'Build-Zeit';

  @override
  String get scheduledSearchHint => 'Geplante durchsuchen...';

  @override
  String get scheduledNoMatch => 'Keine geplanten Buchungen gefunden';

  @override
  String get commonNext => 'Nächste';

  @override
  String get budgetsSearchHint => 'Budgets durchsuchen...';

  @override
  String get budgetsNoMatch => 'Keine Budgets gefunden';

  @override
  String get budgetsSpent => 'Ausgegeben';

  @override
  String scheduledOverdue(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count überfällig',
      one: '1 überfällig',
    );
    return '$_temp0';
  }

  @override
  String get paymentMethodDebitCard => 'Debitkarte';

  @override
  String get paymentMethodStandingOrder => 'Dauerauftrag';

  @override
  String get paymentMethodElectronic => 'Elektronische Zahlung';

  @override
  String get paymentMethodBankFee => 'Bankgebühr';

  @override
  String get paymentMethodCardTransaction => 'Kartenzahlung';

  @override
  String get paymentMethodTrade => 'Wertpapiergeschäft';

  @override
  String get paymentMethodReward => 'Bonus';

  @override
  String get paymentMethodInterest => 'Zinsen';

  @override
  String categoryCreate(String name) {
    return '„$name“ anlegen';
  }

  @override
  String categoryCreateUnder(String parent) {
    return 'unter $parent';
  }

  @override
  String get categoryCreateTopLevel => 'Neue Hauptkategorie';

  @override
  String get logoutPendingTitle => 'Nicht gesendete Buchungen';

  @override
  String logoutPendingBody(int count) {
    return '$count Buchungen haben den Server nicht erreicht. Beim Abmelden gehen sie verloren.';
  }

  @override
  String get logoutPendingUnknown =>
      'Nicht gesendete Buchungen konnten nicht gelesen werden. Sie bleiben auf diesem Gerät, statt verworfen zu werden, und werden möglicherweise später gesendet.';

  @override
  String get outboxForeignTitle =>
      'Nicht gesendete Buchungen eines anderen Kontos';

  @override
  String outboxForeignBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count nicht gesendete Buchungen wurden unter einem anderen Konto oder einer anderen Serveradresse gespeichert und werden nicht gesendet. Wer sich wieder mit jenem Konto anmeldet oder die Serveradresse korrigiert, sieht sie wieder — beim nächsten Speichern hier werden sie jedoch beiseitegelegt.',
      one:
          '1 nicht gesendete Buchung wurde unter einem anderen Konto oder einer anderen Serveradresse gespeichert und wird nicht gesendet. Wer sich wieder mit jenem Konto anmeldet oder die Serveradresse korrigiert, sieht sie wieder — beim nächsten Speichern hier wird sie jedoch beiseitegelegt.',
    );
    return '$_temp0';
  }

  @override
  String get outboxUnknownTitle =>
      'Nicht gesendete Buchungen aus einer früheren Version';

  @override
  String outboxUnknownBody(int count, String account) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count nicht gesendete Buchungen wurden vor dieser Version gespeichert; die App kann nicht feststellen, wem sie gehören. Als $account senden?',
      one:
          '1 nicht gesendete Buchung wurde vor dieser Version gespeichert; die App kann nicht feststellen, wem sie gehört. Als $account senden?',
    );
    return '$_temp0';
  }

  @override
  String get outboxKeep => 'Behalten';

  @override
  String get outboxSendAsThisAccount => 'Als dieses Konto senden';

  @override
  String get outboxNotNow => 'Jetzt nicht';
}
