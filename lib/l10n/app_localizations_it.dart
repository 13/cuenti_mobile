// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class LIt extends L {
  LIt([String locale = 'it']) : super(locale);

  @override
  String get commonSave => 'Salva';

  @override
  String get commonCancel => 'Annulla';

  @override
  String get commonDelete => 'Elimina';

  @override
  String get commonClose => 'Chiudi';

  @override
  String get commonEdit => 'Modifica';

  @override
  String get commonRetry => 'Riprova';

  @override
  String get commonName => 'Nome';

  @override
  String get commonType => 'Tipo';

  @override
  String get commonCurrency => 'Valuta';

  @override
  String get commonAmount => 'Importo';

  @override
  String get commonMemo => 'Nota';

  @override
  String get commonNone => 'Nessuna';

  @override
  String get commonNoData => 'Nessun dato';

  @override
  String get commonAccount => 'Conto';

  @override
  String get commonExpense => 'Uscita';

  @override
  String get commonIncome => 'Entrata';

  @override
  String get commonTransfer => 'Trasferimento';

  @override
  String get commonClearFilters => 'Azzera i filtri';

  @override
  String get commonEmail => 'Email';

  @override
  String get commonPassword => 'Password';

  @override
  String get commonUsername => 'Nome utente';

  @override
  String get commonFirstName => 'Nome';

  @override
  String get commonLastName => 'Cognome';

  @override
  String get commonGroup => 'Gruppo';

  @override
  String get commonUndoWarning => 'Questa azione non può essere annullata.';

  @override
  String get offlineBanner =>
      'Offline — sono mostrati gli ultimi dati scaricati';

  @override
  String get navDashboard => 'Riepilogo';

  @override
  String get navTransactions => 'Movimenti';

  @override
  String get navBudgets => 'Budget';

  @override
  String get navStatistics => 'Statistiche';

  @override
  String get actionRefresh => 'Aggiorna';

  @override
  String get actionLogout => 'Esci';

  @override
  String get authSignInTitle => 'Accedi';

  @override
  String get authSignInButton => 'Accedi';

  @override
  String get authSignInBiometrics => 'Accedi con la biometria';

  @override
  String get authNotYou => 'Non sei tu?';

  @override
  String get authNoAccountRegister => 'Non hai un account? Registrati';

  @override
  String get authHaveAccountSignIn => 'Hai già un account? Accedi';

  @override
  String get authRegister => 'Registrati';

  @override
  String get authCreateAccount => 'Crea account';

  @override
  String get authConfirmPassword => 'Conferma password';

  @override
  String get authLockedTitle => 'Cuenti è bloccata';

  @override
  String get authUnlock => 'Sblocca';

  @override
  String get authShowPassword => 'Mostra password';

  @override
  String get authHidePassword => 'Nascondi password';

  @override
  String get serverSetupTitle => 'Configurazione server';

  @override
  String get serverUrl => 'URL del server';

  @override
  String get serverSaveContinue => 'Salva e continua';

  @override
  String get serverTrust => 'Considera attendibile';

  @override
  String get serverUntrustedTitle => 'Certificato non riconosciuto';

  @override
  String get serverInsecureTitle => 'Connessione non cifrata';

  @override
  String serverInsecureBody(String host) {
    return '$host sarà raggiunto tramite http: la password, la sessione e tutto ciò che l\'app carica viaggiano non cifrati e chiunque sia sulla stessa rete può leggerli. Usa https, a meno che tu non consideri affidabile ogni dispositivo di questa rete.';
  }

  @override
  String get serverInsecureContinue => 'Usa comunque http';

  @override
  String serverUntrustedBody(String host) {
    return '$host ha presentato un certificato per cui nessuna autorità di certificazione garantisce. Per un server Cuenti self-hosted è normale, ma è anche il segno di una connessione intercettata. Consideralo attendibile solo se questa impronta corrisponde a quella del tuo server.';
  }

  @override
  String get serverChange => 'Cambia server';

  @override
  String get accountsEmpty => 'Nessun conto';

  @override
  String get accountsAdd => 'Aggiungi conto';

  @override
  String get accountsDeleteTitle => 'Eliminare il conto?';

  @override
  String get accountsDeleteBody =>
      'Tutti i movimenti collegati ne saranno interessati.';

  @override
  String get accountsInstitution => 'Istituto';

  @override
  String get accountsStartBalance => 'Saldo iniziale';

  @override
  String get accountsExcludeSummary => 'Escludi dal riepilogo';

  @override
  String get accountsExcludeReports => 'Escludi dai report';

  @override
  String get assetsEmpty => 'Nessun asset';

  @override
  String get assetsAdd => 'Aggiungi asset';

  @override
  String get assetsDeleteTitle => 'Eliminare l\'asset?';

  @override
  String get assetsSymbolHint => 'Simbolo (es. VWCE.DE)';

  @override
  String get assetsRefreshPrice => 'Aggiorna quotazione';

  @override
  String get currenciesEmpty => 'Nessuna valuta';

  @override
  String get currenciesAdd => 'Aggiungi valuta';

  @override
  String get currenciesDeleteTitle => 'Eliminare la valuta?';

  @override
  String get currenciesCodeHint => 'Codice (es. EUR)';

  @override
  String get currenciesNameHint => 'Nome (es. Euro)';

  @override
  String get currenciesSymbolHint => 'Simbolo (es. €)';

  @override
  String get currenciesDecimals => 'Decimali';

  @override
  String get currenciesDecimal => 'Separatore decimale';

  @override
  String get currenciesGrouping => 'Separatore migliaia';

  @override
  String get tagsEmpty => 'Nessun tag';

  @override
  String get tagsAdd => 'Aggiungi tag';

  @override
  String get tagsDeleteTitle => 'Eliminare il tag?';

  @override
  String get payeesEmpty => 'Nessun beneficiario';

  @override
  String get payeesAdd => 'Aggiungi beneficiario';

  @override
  String get payeesDeleteTitle => 'Eliminare il beneficiario?';

  @override
  String get payeesNotes => 'Note';

  @override
  String get payeesDefaultCategory => 'Categoria predefinita';

  @override
  String get payeesDefaultPayment => 'Pagamento predefinito';

  @override
  String get payeeLabel => 'Beneficiario';

  @override
  String get categoriesEmpty => 'Nessuna categoria';

  @override
  String get categoriesAdd => 'Aggiungi categoria';

  @override
  String get categoriesDeleteTitle => 'Eliminare la categoria?';

  @override
  String get categoriesEditOne => 'Modifica categoria';

  @override
  String get categoriesDeleteOne => 'Elimina categoria';

  @override
  String get categoriesParent => 'Categoria principale';

  @override
  String get categoriesTopLevel => 'Nessuna (primo livello)';

  @override
  String get categoryLabel => 'Categoria';

  @override
  String get categorySearchClear => 'Cancella ricerca';

  @override
  String get categorySearchEmpty => 'Nessuna categoria corrispondente';

  @override
  String categorySearchHint(String what) {
    return 'Cerca $what';
  }

  @override
  String get txEmpty => 'Nessun movimento';

  @override
  String get txNoMatch => 'Nessun movimento corrispondente';

  @override
  String get txAdd => 'Aggiungi movimento';

  @override
  String get txSearchHint => 'Cerca movimenti…';

  @override
  String get txDeleteTitle => 'Eliminare il movimento?';

  @override
  String get txTypeFilter => 'Tipo di movimento';

  @override
  String get txFromAccount => 'Dal conto';

  @override
  String get txToAccount => 'Al conto';

  @override
  String get txPaymentMethod => 'Metodo di pagamento';

  @override
  String get txTagsHint => 'Tag (separati da virgola)';

  @override
  String get txSplits => 'Suddivisioni';

  @override
  String get txAddSplit => 'Aggiungi suddivisione';

  @override
  String get txRemoveSplit => 'Rimuovi suddivisione';

  @override
  String get txSplitNeedsCategory => 'Ogni suddivisione richiede una categoria';

  @override
  String txSplitSumMismatch(String sum, String total) {
    return 'Le suddivisioni devono corrispondere all\'importo: $sum di $total';
  }

  @override
  String get txRequired => 'Obbligatorio';

  @override
  String get txInvalidNumber => 'Numero non valido';

  @override
  String get fuelOdometer => 'Contachilometri (km)';

  @override
  String get fuelLiters => 'Litri';

  @override
  String get fuelFullTank => 'Pieno';

  @override
  String fuelLastReading(String value) {
    return 'ultimo: $value';
  }

  @override
  String get fuelImplausibleLiters => 'Valore in litri non plausibile';

  @override
  String fuelNotIncreasing(String last) {
    return 'Il contachilometri non supera l\'ultima lettura ($last)';
  }

  @override
  String fuelLargeJump(String distance) {
    return 'Salto molto ampio dall\'ultima lettura ($distance km) — errore di battitura?';
  }

  @override
  String fuelConsumption(String distance, String consumption) {
    return '$distance km dall\'ultimo, ~$consumption L/100km';
  }

  @override
  String fuelDistanceOnly(String distance) {
    return '$distance km dall\'ultimo rifornimento';
  }

  @override
  String get vehiclesChooseCategory => 'Scegli categoria';

  @override
  String get vehiclesFuelCategory => 'Categoria carburante';

  @override
  String get vehiclesSetDefault => 'Imposta come predefinita';

  @override
  String get vehiclesDefaultSaved => 'Predefinita salvata';

  @override
  String get vehiclesPickPrompt =>
      'Scegli una categoria carburante per vedere il report del veicolo';

  @override
  String get vehiclesNoEntries => 'Nessun rifornimento in questo periodo';

  @override
  String get vehiclesNotEnoughData => 'Dati insufficienti per un grafico';

  @override
  String get vehiclesThisYear => 'Quest\'anno';

  @override
  String get vehiclesTotalCost => 'Costo totale';

  @override
  String get vehiclesDistance => 'Distanza';

  @override
  String get vehiclesAvgConsumption => '⌀ Consumo';

  @override
  String get vehiclesAvgPricePerLiter => '⌀ Prezzo/L';

  @override
  String get vehiclesFull => 'Pieno';

  @override
  String get budgetsEmpty => 'Nessun budget';

  @override
  String get budgetsAdd => 'Aggiungi budget';

  @override
  String get budgetsDeleteTitle => 'Eliminare il budget?';

  @override
  String get budgetsMonthlyLimit => 'Limite mensile';

  @override
  String get budgetsActive => 'Attivo';

  @override
  String get budgetsRemaining => 'Rimanente: ';

  @override
  String get budgetsSelectCategory => 'Scegli una categoria';

  @override
  String get scheduledEmpty => 'Nessun movimento pianificato';

  @override
  String get scheduledDeleteTitle => 'Eliminare la pianificazione?';

  @override
  String get scheduledPost => 'Registra';

  @override
  String get scheduledSkip => 'Salta';

  @override
  String get scheduledPosted => 'Movimento registrato';

  @override
  String get scheduledSkipped => 'Ricorrenza saltata';

  @override
  String get savedViewsTitle => 'Viste salvate';

  @override
  String get savedViewsEmpty => 'Nessuna vista salvata';

  @override
  String get savedViewsSaveCurrent => 'Salva la vista corrente';

  @override
  String get savedViewsDeleteTitle => 'Eliminare la vista salvata?';

  @override
  String get savedViewsDeleteOne => 'Elimina vista';

  @override
  String get savedViewsFromWeb => 'Salvata dall\'app web';

  @override
  String get auditEmpty => 'Nessuna voce di audit';

  @override
  String get auditNoMatch => 'Nessuna voce di audit corrispondente';

  @override
  String get auditSearchHint => 'Cerca nel registro…';

  @override
  String get auditTitle => 'Registro attività';

  @override
  String get dashboardNetWorth => 'Patrimonio netto';

  @override
  String get dashboardCash => 'Liquidità';

  @override
  String get dashboardPortfolio => 'Portafoglio';

  @override
  String get dashboardNoAccounts => 'Nessun conto';

  @override
  String get forecastsNet => 'Netto';

  @override
  String get forecastsMonthlyForecast => 'Previsione mensile';

  @override
  String get forecastsBreakdown => 'Dettaglio';

  @override
  String get vehiclesConsumption => 'Consumo';

  @override
  String get vehiclesEntries => 'Voci';

  @override
  String get statsAllAccounts => 'Tutti i conti';

  @override
  String get statsIncomeByCategory => 'Entrate per categoria';

  @override
  String get statsExpenseByCategory => 'Uscite per categoria';

  @override
  String get statsTotal => 'Totale';

  @override
  String get statsOverview => 'Panoramica';

  @override
  String get scheduledLate => '(IN RITARDO!)';

  @override
  String dashboardAssetUnits(String units, String symbol) {
    return '$units unità · $symbol';
  }

  @override
  String scheduledNextOn(String pattern, String date) {
    return '$pattern · Prossima: $date';
  }

  @override
  String currenciesFormatSummary(
    String symbol,
    String digits,
    String decimal,
    String grouping,
  ) {
    return 'Simbolo $symbol · $digits decimali · $decimal $grouping';
  }

  @override
  String get a11yChartIncomeExpense => 'Grafico: entrate e uscite';

  @override
  String get a11yChartCashFlow => 'Grafico: andamento del saldo';

  @override
  String get a11yChartMonthlyCashFlow => 'Grafico: andamento mensile';

  @override
  String get a11yChartCategories => 'Grafico: categorie';

  @override
  String get commonBalance => 'Saldo';

  @override
  String get statsSavingsRate => 'Tasso di risparmio';

  @override
  String get statsIncomeVsExpense => 'Entrate e uscite';

  @override
  String get statsNetCashFlowTrend => 'Andamento del saldo';

  @override
  String get statsMonthlyCashFlow => 'Andamento mensile';

  @override
  String get statsRangeDaily => 'Giornaliero';

  @override
  String get statsRangeWeekly => 'Settimanale';

  @override
  String get statsRangeMonthly => 'Mensile';

  @override
  String get statsRangeYearly => 'Annuale';

  @override
  String get statsAllCategories => 'Tutte le categorie';

  @override
  String statsDirectAmount(String name) {
    return '$name (diretto)';
  }

  @override
  String get updateAvailable => 'Aggiornamento disponibile';

  @override
  String get updateUpToDate => 'Sei aggiornato';

  @override
  String get updateCheckFailed => 'Impossibile verificare gli aggiornamenti';

  @override
  String get updateNoApk => 'Nessun APK nell\'ultima release';

  @override
  String get updateLater => 'Più tardi';

  @override
  String get settingsProfile => 'Profilo';

  @override
  String get settingsPreferences => 'Preferenze';

  @override
  String get settingsSecurity => 'Sicurezza';

  @override
  String get settingsServer => 'Server';

  @override
  String get settingsData => 'Dati';

  @override
  String get settingsNotLoggedIn => 'Non connesso';

  @override
  String get settingsEditProfile => 'Modifica profilo';

  @override
  String get settingsDarkMode => 'Modalità scura';

  @override
  String get settingsDefaultCurrency => 'Valuta predefinita';

  @override
  String get settingsLocale => 'Lingua';

  @override
  String get settingsApiAccess => 'Accesso API';

  @override
  String get settingsApiAccessSubtitle =>
      'Abilita l\'accesso API per questo account';

  @override
  String get settingsBiometric => 'Sblocco biometrico';

  @override
  String get settingsBiometricSubtitle =>
      'Richiedi impronta o volto per riaprire e accedere';

  @override
  String get settingsChangePassword => 'Cambia password';

  @override
  String get settingsCurrentPassword => 'Password attuale';

  @override
  String get settingsNewPassword => 'Nuova password';

  @override
  String get settingsConfirmNewPassword => 'Conferma nuova password';

  @override
  String get settingsPasswordsMismatch => 'Le password non coincidono';

  @override
  String get settingsPasswordChanged => 'Password modificata';

  @override
  String settingsConnectedTo(String url) {
    return 'Connesso a: $url';
  }

  @override
  String get settingsExportData => 'Esporta dati';

  @override
  String get settingsImportData => 'Importa dati';

  @override
  String get settingsImportTitle => 'Importare i dati?';

  @override
  String get settingsImportBody =>
      'Questo sostituisce i dati sul server con il contenuto del file.';

  @override
  String get settingsImport => 'Importa';

  @override
  String get settingsImportComplete => 'Importazione completata';

  @override
  String settingsExportFailed(String error) {
    return 'Esportazione non riuscita: $error';
  }

  @override
  String settingsImportFailed(String error) {
    return 'Importazione non riuscita: $error';
  }

  @override
  String get settingsAdministration => 'Amministrazione';

  @override
  String get settingsAdminPanel => 'Pannello di amministrazione';

  @override
  String get settingsGlobalApiEnabled => 'API globale abilitata';

  @override
  String get settingsRegistrationEnabled => 'Registrazione abilitata';

  @override
  String get settingsEnable => 'Abilita';

  @override
  String get settingsDisable => 'Disabilita';

  @override
  String get settingsDeleteUserBody =>
      'Questo rimuove definitivamente l\'utente e i suoi dati.';

  @override
  String get settingsChange => 'Cambia';

  @override
  String get settingsAbout => 'Informazioni';

  @override
  String get aboutTitle => 'Informazioni su Cuenti';

  @override
  String get aboutTagline => 'L\'app Cuenti per dispositivi mobili';

  @override
  String get aboutDescription =>
      'Cuenti è un\'applicazione per la gestione delle finanze personali: registra i movimenti, gestisci i conti e tieni sotto controllo i tuoi asset in diverse valute.';

  @override
  String get aboutSoftwareInfo => 'Informazioni sul software';

  @override
  String get aboutCheckUpdates => 'Cerca aggiornamenti';

  @override
  String get aboutVisitWebsite => 'Visita il sito web';

  @override
  String get updateSkipVersion => 'Salta questa versione';

  @override
  String get updateInstall => 'Aggiorna';

  @override
  String get updateDownloadFailed => 'Download non riuscito';

  @override
  String updateReady(String tag) {
    return '$tag è pronta per l\'installazione.';
  }

  @override
  String get settingsAutoUpdate => 'Controllo automatico aggiornamenti';

  @override
  String get settingsAutoUpdateSubtitle =>
      'Cerca una nuova versione su GitHub all\'apertura dell\'app';

  @override
  String commonError(String message) {
    return 'Errore: $message';
  }

  @override
  String commonDeleteConfirm(String name) {
    return 'Eliminare \"$name\"?';
  }

  @override
  String get commonRequired => 'Obbligatorio';

  @override
  String get commonInvalidNumber => 'Numero non valido';

  @override
  String get commonAll => 'Tutti';

  @override
  String get commonToday => 'Oggi';

  @override
  String get commonYesterday => 'Ieri';

  @override
  String get commonCustom => 'Personalizzato';

  @override
  String get commonDateRange => 'Intervallo di date';

  @override
  String get navScheduled => 'Pianificati';

  @override
  String get navForecasts => 'Previsioni';

  @override
  String get navAccounts => 'Conti';

  @override
  String get navPayees => 'Beneficiari';

  @override
  String get navCategories => 'Categorie';

  @override
  String get navTags => 'Tag';

  @override
  String get navCurrencies => 'Valute';

  @override
  String get navAssets => 'Asset';

  @override
  String get navVehicles => 'Veicoli';

  @override
  String get navSettings => 'Impostazioni';

  @override
  String get navAbout => 'Informazioni';

  @override
  String get navAuditLog => 'Registro attività';

  @override
  String get navGeneral => 'Generale';

  @override
  String get navManagement => 'Gestione';

  @override
  String get navSettingsSection => 'Impostazioni';

  @override
  String get privacyShow => 'Mostra importi';

  @override
  String get privacyHide => 'Nascondi importi';

  @override
  String get accountsAddTitle => 'Aggiungi conto';

  @override
  String get accountsEditTitle => 'Modifica conto';

  @override
  String get assetsAddTitle => 'Aggiungi asset';

  @override
  String get assetsEditTitle => 'Modifica asset';

  @override
  String get budgetsAddTitle => 'Aggiungi budget';

  @override
  String get budgetsEditTitle => 'Modifica budget';

  @override
  String get categoriesAddTitle => 'Aggiungi categoria';

  @override
  String get categoriesEditTitle => 'Modifica categoria';

  @override
  String get currenciesAddTitle => 'Aggiungi valuta';

  @override
  String get currenciesEditTitle => 'Modifica valuta';

  @override
  String get payeesAddTitle => 'Aggiungi beneficiario';

  @override
  String get payeesEditTitle => 'Modifica beneficiario';

  @override
  String get tagsAddTitle => 'Aggiungi tag';

  @override
  String get tagsEditTitle => 'Modifica tag';

  @override
  String get txAddTitle => 'Aggiungi movimento';

  @override
  String get txEditTitle => 'Modifica movimento';

  @override
  String get txAllAccounts => 'Tutti i conti';

  @override
  String get authBiometricReason => 'Accedi a Cuenti';

  @override
  String get authUnlockReason => 'Autenticati per sbloccare Cuenti';

  @override
  String authServerLine(String url) {
    return 'Server: $url';
  }

  @override
  String get assetsNoPrice => 'Nessuna quotazione';

  @override
  String assetsPriceRefreshed(String symbol) {
    return 'Quotazione aggiornata per $symbol';
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
      other: '$countString movimenti nel periodo',
      one: '1 movimento nel periodo',
      zero: 'Nessun movimento nel periodo',
    );
    return '$_temp0';
  }

  @override
  String get vehiclesCustomRange => 'Intervallo personalizzato';

  @override
  String scheduledDeleteBody(String name) {
    return 'Eliminare il movimento ricorrente \"$name\"?';
  }

  @override
  String budgetsDeleteBody(String category) {
    return 'Eliminare il budget per \"$category\"?';
  }

  @override
  String settingsUsersCount(String count) {
    return 'Utenti ($count)';
  }

  @override
  String settingsDeleteUserTitle(String username) {
    return 'Eliminare $username?';
  }

  @override
  String aboutCopyright(String year) {
    return '© $year Cuenti Team';
  }

  @override
  String get txFuelHint =>
      'Nessun km/litro inserito — questa voce non comparirà nel report del veicolo';

  @override
  String get errorNetwork => 'Impossibile connettersi al server';

  @override
  String get errorNotAuthenticated => 'Non autenticato';

  @override
  String get errorInvalidCredentials => 'Nome utente o password non validi';

  @override
  String get errorApiDisabled => 'L\'accesso API non è abilitato';

  @override
  String get errorInvalidRequest => 'Richiesta non valida';

  @override
  String errorServer(String status) {
    return 'Errore del server ($status)';
  }

  @override
  String get errorCertificate =>
      'Il certificato del server non è attendibile. Ripeti la configurazione del server per verificarne l\'impronta e considerarlo attendibile.';

  @override
  String get errorUnknown => 'Si è verificato un errore';

  @override
  String get errorNoSavedCredentials => 'Nessuna credenziale salvata';

  @override
  String get errorSavedPasswordInvalid =>
      'La password salvata non è più valida';

  @override
  String get errorUnexpectedResponse => 'Risposta del server imprevista';

  @override
  String get txSaved => 'Movimento salvato';

  @override
  String get txDeleted => 'Movimento eliminato';

  @override
  String get accountsSaved => 'Conto salvato';

  @override
  String get accountsDeleted => 'Conto eliminato';

  @override
  String get categoriesSaved => 'Categoria salvata';

  @override
  String get categoriesDeleted => 'Categoria eliminata';

  @override
  String get payeesSaved => 'Beneficiario salvato';

  @override
  String get payeesDeleted => 'Beneficiario eliminato';

  @override
  String get tagsSaved => 'Tag salvato';

  @override
  String get tagsDeleted => 'Tag eliminato';

  @override
  String get currenciesSaved => 'Valuta salvata';

  @override
  String get currenciesDeleted => 'Valuta eliminata';

  @override
  String get assetsSaved => 'Asset salvato';

  @override
  String get assetsDeleted => 'Asset eliminato';

  @override
  String get budgetsSaved => 'Budget salvato';

  @override
  String get budgetsDeleted => 'Budget eliminato';

  @override
  String get savedViewsSaved => 'Vista salvata';

  @override
  String get savedViewsDeleted => 'Vista eliminata';

  @override
  String get settingsProfileSaved => 'Profilo salvato';

  @override
  String offlineBannerSince(String when) {
    return 'Offline — dati del $when';
  }

  @override
  String get accountsSearchHint => 'Cerca conti...';

  @override
  String get accountsNoMatch => 'Nessun conto corrisponde';

  @override
  String get payeesSearchHint => 'Cerca beneficiari...';

  @override
  String get payeesNoMatch => 'Nessun beneficiario corrisponde';

  @override
  String get categoriesSearchHint => 'Cerca categorie...';

  @override
  String get categoriesNoMatch => 'Nessuna categoria corrisponde';

  @override
  String get tagsSearchHint => 'Cerca tag...';

  @override
  String get tagsNoMatch => 'Nessun tag corrisponde';

  @override
  String get currenciesSearchHint => 'Cerca valute...';

  @override
  String get currenciesNoMatch => 'Nessuna valuta corrisponde';

  @override
  String get assetsSearchHint => 'Cerca titoli...';

  @override
  String get assetsNoMatch => 'Nessun titolo corrisponde';

  @override
  String get commonSortCustom => 'Ordine personalizzato';

  @override
  String get commonCode => 'Codice';

  @override
  String get commonSymbol => 'Simbolo';

  @override
  String get commonPrice => 'Prezzo';

  @override
  String get accountTypeBank => 'Banca';

  @override
  String get accountTypeCash => 'Contanti';

  @override
  String get accountTypeAsset => 'Attività';

  @override
  String get accountTypeCreditCard => 'Carta di credito';

  @override
  String get accountTypeLiability => 'Passività';

  @override
  String get accountTypeCurrent => 'Conto corrente';

  @override
  String get accountTypeSavings => 'Conto di risparmio';

  @override
  String get assetTypeStock => 'Azione';

  @override
  String get assetTypeEtf => 'ETF';

  @override
  String get assetTypeCrypto => 'Cripto';

  @override
  String get paymentMethodCash => 'Contanti';

  @override
  String get paymentMethodCard => 'Carta';

  @override
  String get paymentMethodBankTransfer => 'Bonifico';

  @override
  String get paymentMethodCheck => 'Assegno';

  @override
  String get sortAscending => 'Crescente';

  @override
  String get sortDescending => 'Decrescente';

  @override
  String get recurrenceDaily => 'Giornaliero';

  @override
  String get recurrenceWeekly => 'Settimanale';

  @override
  String get recurrenceBiWeekly => 'Quindicinale';

  @override
  String get recurrenceMonthly => 'Mensile';

  @override
  String get recurrenceMonthlyLastDay => 'Mensile (ultimo giorno)';

  @override
  String get recurrenceYearly => 'Annuale';

  @override
  String validationMinCharacters(int count) {
    return 'Minimo $count caratteri';
  }

  @override
  String get validationInvalidEmail => 'Email non valida';

  @override
  String get authPasswordsMismatch => 'Le password non coincidono';

  @override
  String get aboutVersion => 'Versione';

  @override
  String get aboutBuildNumber => 'Numero build';

  @override
  String get aboutBuildDate => 'Data build';

  @override
  String get aboutBuildTime => 'Ora build';

  @override
  String get scheduledSearchHint => 'Cerca pianificate...';

  @override
  String get scheduledNoMatch => 'Nessuna operazione pianificata corrisponde';

  @override
  String get commonNext => 'Prossima';

  @override
  String get budgetsSearchHint => 'Cerca budget...';

  @override
  String get budgetsNoMatch => 'Nessun budget corrisponde';

  @override
  String get budgetsSpent => 'Speso';

  @override
  String scheduledOverdue(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count in ritardo',
      one: '1 in ritardo',
    );
    return '$_temp0';
  }
}
