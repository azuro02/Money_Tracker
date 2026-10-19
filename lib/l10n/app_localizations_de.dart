// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Money Tracker';

  @override
  String get navOverview => 'Übersicht';

  @override
  String get navTransactions => 'Buchungen';

  @override
  String get navStatistics => 'Statistik';

  @override
  String get navMore => 'Mehr';

  @override
  String get actionSave => 'Speichern';

  @override
  String get actionCancel => 'Abbrechen';

  @override
  String get actionDelete => 'Löschen';

  @override
  String get actionEdit => 'Bearbeiten';

  @override
  String get actionAdd => 'Hinzufügen';

  @override
  String get actionClose => 'Schließen';

  @override
  String get actionOk => 'OK';

  @override
  String get actionNext => 'Weiter';

  @override
  String get actionShare => 'Teilen';

  @override
  String get actionArchive => 'Archivieren';

  @override
  String get actionUnarchive => 'Aus Archiv holen';

  @override
  String get actionSort => 'Sortieren';

  @override
  String get actionDuplicate => 'Duplizieren';

  @override
  String get actionShowTransactions => 'Buchungen anzeigen';

  @override
  String get actionSearch => 'Suchen';

  @override
  String get actionClear => 'Zurücksetzen';

  @override
  String get actionNone => 'Keine';

  @override
  String get actionSelect => 'Auswählen';

  @override
  String get actionOpenMap => 'In Karten öffnen';

  @override
  String get confirmDeleteTitle => 'Löschen?';

  @override
  String confirmDeleteMessage(String name) {
    return '„$name“ wird endgültig gelöscht.';
  }

  @override
  String get deleted => 'Gelöscht';

  @override
  String get saved => 'Gespeichert';

  @override
  String get emptyList => 'Noch keine Einträge';

  @override
  String get required => 'Pflichtfeld';

  @override
  String get invalidAmount => 'Ungültiger Betrag';

  @override
  String get noDescription => 'Ohne Beschreibung';

  @override
  String get totalWallet => 'Alle Konten';

  @override
  String get wallets => 'Konten';

  @override
  String get wallet => 'Konto';

  @override
  String get newWallet => 'Neues Konto';

  @override
  String get editWallet => 'Konto bearbeiten';

  @override
  String get walletName => 'Name';

  @override
  String get walletCurrency => 'Währung';

  @override
  String get walletStartMoney => 'Anfangsbestand';

  @override
  String get walletCountInTotal => 'Im Gesamtsaldo berücksichtigen';

  @override
  String get walletArchived => 'Archiviert';

  @override
  String get archivedWallets => 'Archivierte Konten';

  @override
  String get balance => 'Saldo';

  @override
  String get totalBalance => 'Gesamtsaldo';

  @override
  String get income => 'Einnahme';

  @override
  String get expense => 'Ausgabe';

  @override
  String get incomes => 'Einnahmen';

  @override
  String get expenses => 'Ausgaben';

  @override
  String get net => 'Netto';

  @override
  String get transfer => 'Umbuchung';

  @override
  String get transfers => 'Umbuchungen';

  @override
  String get transactions => 'Buchungen';

  @override
  String get newTransaction => 'Neue Buchung';

  @override
  String get editTransaction => 'Buchung bearbeiten';

  @override
  String get newTransfer => 'Neue Umbuchung';

  @override
  String get editTransfer => 'Umbuchung bearbeiten';

  @override
  String get amount => 'Betrag';

  @override
  String get description => 'Beschreibung';

  @override
  String get category => 'Kategorie';

  @override
  String get date => 'Datum';

  @override
  String get time => 'Uhrzeit';

  @override
  String get note => 'Notiz';

  @override
  String get event => 'Ereignis';

  @override
  String get events => 'Ereignisse';

  @override
  String get place => 'Ort';

  @override
  String get places => 'Orte';

  @override
  String get person => 'Person';

  @override
  String get people => 'Personen';

  @override
  String get attachments => 'Anhänge';

  @override
  String get addAttachment => 'Anhang hinzufügen';

  @override
  String get attachmentFromCamera => 'Foto aufnehmen';

  @override
  String get attachmentFromGallery => 'Foto aus Galerie';

  @override
  String get attachmentFromFile => 'Datei';

  @override
  String get confirmed => 'Bestätigt';

  @override
  String get confirmedHint => 'Unbestätigte Buchungen zählen nicht zum Saldo';

  @override
  String get countInTotal => 'In Saldo und Statistik berücksichtigen';

  @override
  String get fromWallet => 'Von';

  @override
  String get toWallet => 'Nach';

  @override
  String get amountReceived => 'Empfangener Betrag';

  @override
  String get fee => 'Gebühr';

  @override
  String exchangeRate(String from, String rate, String to) {
    return 'Kurs: 1 $from = $rate $to';
  }

  @override
  String get applyModel => 'Vorlage verwenden';

  @override
  String get saveAsModel => 'Als Vorlage speichern';

  @override
  String get planned => 'Geplant';

  @override
  String get unconfirmed => 'Unbestätigt';

  @override
  String get transferEditInfo => 'Dieser Eintrag gehört zu einer Umbuchung.';

  @override
  String get noTransactions => 'Noch keine Buchungen';

  @override
  String get noTransactionsHint =>
      'Tippe auf +, um deine erste Einnahme oder Ausgabe zu erfassen.';

  @override
  String get recentTransactions => 'Letzte Buchungen';

  @override
  String get showAll => 'Alle anzeigen';

  @override
  String get categories => 'Kategorien';

  @override
  String get newCategory => 'Neue Kategorie';

  @override
  String get editCategory => 'Kategorie bearbeiten';

  @override
  String get categoryName => 'Name';

  @override
  String get parentCategory => 'Oberkategorie';

  @override
  String get noParent => 'Keine (Hauptkategorie)';

  @override
  String get categoryType => 'Art';

  @override
  String get showInReports => 'In Statistiken anzeigen';

  @override
  String get systemCategories => 'System';

  @override
  String get subcategory => 'Unterkategorie';

  @override
  String get debts => 'Schulden';

  @override
  String get debt => 'Schuld';

  @override
  String get credit => 'Forderung';

  @override
  String get credits => 'Forderungen';

  @override
  String get newDebt => 'Neue Schuld';

  @override
  String get newCredit => 'Neue Forderung';

  @override
  String get editDebt => 'Schuld bearbeiten';

  @override
  String get debtTypeDebt => 'Ich schulde Geld (Schuld)';

  @override
  String get debtTypeCredit => 'Ich habe Geld verliehen (Forderung)';

  @override
  String get expirationDate => 'Fällig am';

  @override
  String get noExpiration => 'Kein Fälligkeitsdatum';

  @override
  String get debtCreateTransaction => 'Geldfluss im Konto verbuchen';

  @override
  String get debtCreateTransactionHint =>
      'Legt eine Einnahme (Schuld) bzw. Ausgabe (Forderung) an.';

  @override
  String debtLeft(String amount) {
    return 'Noch $amount offen';
  }

  @override
  String get debtCompleted => 'Beglichen';

  @override
  String debtExpiresOn(String date) {
    return 'Fällig am $date';
  }

  @override
  String debtExpired(String date) {
    return 'Überfällig seit $date';
  }

  @override
  String get debtPay => 'Zurückzahlen';

  @override
  String get debtReceive => 'Erhalten';

  @override
  String get toPay => 'Zu zahlen';

  @override
  String get toReceive => 'Zu erhalten';

  @override
  String get archived => 'Archiviert';

  @override
  String get recurrences => 'Daueraufträge';

  @override
  String get newRecurrence => 'Neue wiederkehrende Buchung';

  @override
  String get newRecurrentTransfer => 'Neue wiederkehrende Umbuchung';

  @override
  String get editRecurrence => 'Wiederholung bearbeiten';

  @override
  String get repeat => 'Wiederholen';

  @override
  String get startDate => 'Startdatum';

  @override
  String nextOccurrence(String date) {
    return 'Nächste: $date';
  }

  @override
  String get recurrenceFinished => 'Beendet';

  @override
  String get freqDaily => 'Täglich';

  @override
  String get freqWeekly => 'Wöchentlich';

  @override
  String get freqMonthly => 'Monatlich';

  @override
  String get freqYearly => 'Jährlich';

  @override
  String get everyN => 'Alle';

  @override
  String intervalDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tage',
      one: 'Tag',
    );
    return '$_temp0';
  }

  @override
  String intervalWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Wochen',
      one: 'Woche',
    );
    return '$_temp0';
  }

  @override
  String intervalMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Monate',
      one: 'Monat',
    );
    return '$_temp0';
  }

  @override
  String intervalYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Jahre',
      one: 'Jahr',
    );
    return '$_temp0';
  }

  @override
  String get onWeekdays => 'Am';

  @override
  String get endsNever => 'Endet nie';

  @override
  String get endsOn => 'Endet am Datum';

  @override
  String get endsAfter => 'Endet nach Anzahl';

  @override
  String get occurrences => 'Wiederholungen';

  @override
  String get upcoming => 'Nächste Termine';

  @override
  String recurrenceSummaryUntil(String date) {
    return 'bis $date';
  }

  @override
  String recurrenceSummaryCount(int count) {
    return '$count-mal';
  }

  @override
  String get models => 'Vorlagen';

  @override
  String get newModel => 'Neue Vorlage';

  @override
  String get newTransferModel => 'Neue Umbuchungsvorlage';

  @override
  String get editModel => 'Vorlage bearbeiten';

  @override
  String get newEvent => 'Neues Ereignis';

  @override
  String get editEvent => 'Ereignis bearbeiten';

  @override
  String get eventRunning => 'Laufend';

  @override
  String get eventCompleted => 'Abgeschlossen';

  @override
  String get endDate => 'Enddatum';

  @override
  String get newPerson => 'Neue Person';

  @override
  String get editPerson => 'Person bearbeiten';

  @override
  String get newPlace => 'Neuer Ort';

  @override
  String get editPlace => 'Ort bearbeiten';

  @override
  String get name => 'Name';

  @override
  String get address => 'Adresse';

  @override
  String get latitude => 'Breitengrad';

  @override
  String get longitude => 'Längengrad';

  @override
  String get icon => 'Symbol';

  @override
  String get iconColor => 'Farbe';

  @override
  String get iconSymbol => 'Symbol';

  @override
  String get iconInitials => 'Initialen';

  @override
  String get statistics => 'Statistik';

  @override
  String get statsMonth => 'Monat';

  @override
  String get statsTrend => 'Verlauf';

  @override
  String get statsCustom => 'Individuell';

  @override
  String get savingsRate => 'Sparquote';

  @override
  String get avgPerDay => 'Ø pro Tag';

  @override
  String get projection => 'Prognose';

  @override
  String get projectionHint => 'Erwartete Ausgaben am Monatsende';

  @override
  String get expensesByCategory => 'Ausgaben nach Kategorie';

  @override
  String get incomeByCategory => 'Einnahmen nach Kategorie';

  @override
  String get comparison => 'Vergleich mit Vormonaten';

  @override
  String get vsLastMonth => 'ggü. Vormonat';

  @override
  String get vsAverage => 'ggü. Ø 3 Monate';

  @override
  String get cumulativeSpending => 'Ausgaben im Monatsverlauf';

  @override
  String get thisMonth => 'Dieser Monat';

  @override
  String get lastMonth => 'Vormonat';

  @override
  String get last12Months => 'Letzte 12 Monate';

  @override
  String get topExpenses => 'Größte Ausgaben';

  @override
  String get dailySpending => 'Ausgaben pro Tag';

  @override
  String get noData => 'Keine Daten für diesen Zeitraum';

  @override
  String get otherCategories => 'Sonstige';

  @override
  String get direct => '(direkt)';

  @override
  String get groupBy => 'Gruppieren nach';

  @override
  String get groupDaily => 'Tag';

  @override
  String get groupWeekly => 'Woche';

  @override
  String get groupMonthly => 'Monat';

  @override
  String get groupYearly => 'Jahr';

  @override
  String get period => 'Zeitraum';

  @override
  String get cashFlow => 'Geldfluss';

  @override
  String get currency => 'Währung';

  @override
  String get calendar => 'Kalender';

  @override
  String get search => 'Suche';

  @override
  String get searchHint => 'Beschreibung, Kategorie, Notiz …';

  @override
  String get searchIn => 'Suchen in';

  @override
  String get minAmount => 'Min. Betrag';

  @override
  String get maxAmount => 'Max. Betrag';

  @override
  String get fromDate => 'Von';

  @override
  String get toDate => 'Bis';

  @override
  String results(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Treffer',
      one: '1 Treffer',
      zero: 'Keine Treffer',
    );
    return '$_temp0';
  }

  @override
  String get settings => 'Einstellungen';

  @override
  String get settingsAppearance => 'Darstellung';

  @override
  String get settingsTheme => 'Design';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get themeColor => 'Akzentfarbe';

  @override
  String get incomeColor => 'Farbe für Einnahmen';

  @override
  String get expenseColor => 'Farbe für Ausgaben';

  @override
  String get settingsFormat => 'Formate';

  @override
  String get dateFormat => 'Datumsformat';

  @override
  String get showCurrency => 'Währungssymbol anzeigen';

  @override
  String get groupDigits => 'Tausendertrennzeichen';

  @override
  String get roundDecimals => 'Nachkommastellen runden';

  @override
  String get alwaysShowSign => 'Immer +/− anzeigen';

  @override
  String get firstDayOfWeek => 'Erster Wochentag';

  @override
  String get firstDayOfMonth => 'Erster Tag des Monats';

  @override
  String get firstDayOfMonthHint =>
      'Z. B. dein Zahltag – Monatsstatistiken beginnen an diesem Tag';

  @override
  String get groupTransactionsBy => 'Buchungen gruppieren nach';

  @override
  String get settingsSecurity => 'Sicherheit';

  @override
  String get lockMode => 'App-Sperre';

  @override
  String get lockNone => 'Aus';

  @override
  String get lockPin => 'PIN';

  @override
  String get lockPinBiometric => 'PIN + Biometrie';

  @override
  String get changePin => 'PIN ändern';

  @override
  String get lockTimeout => 'Sperren nach';

  @override
  String get lockImmediately => 'Sofort';

  @override
  String lockAfterSeconds(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds Sekunden',
      one: '1 Sekunde',
    );
    return '$_temp0';
  }

  @override
  String lockAfterMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes Minuten',
      one: '1 Minute',
    );
    return '$_temp0';
  }

  @override
  String get biometricsUnavailable =>
      'Biometrie ist auf diesem Gerät nicht verfügbar';

  @override
  String get settingsReminder => 'Tägliche Erinnerung';

  @override
  String get reminderOff => 'Aus';

  @override
  String reminderAt(String time) {
    return 'Täglich um $time';
  }

  @override
  String get reminderTitle => 'Money Tracker';

  @override
  String get reminderBody => 'Schon die heutigen Ausgaben eingetragen?';

  @override
  String get settingsData => 'Daten';

  @override
  String get manageCurrencies => 'Währungen';

  @override
  String get backupAndExport => 'Sicherung & Export';

  @override
  String get about => 'Über';

  @override
  String get privacy => 'Datenschutz';

  @override
  String get privacyText =>
      'Money Tracker funktioniert komplett offline. Die App hat keine Internet-Berechtigung, enthält weder Tracking noch Werbung und erhebt keinerlei Daten. Deine Daten verlassen das Gerät nur, wenn du selbst eine Sicherung oder einen Export teilst.';

  @override
  String version(String version) {
    return 'Version $version';
  }

  @override
  String get licenseInfo =>
      'Freie Software unter der GNU General Public License v3.';

  @override
  String get aboutCredits =>
      'Basiert auf den Ideen und dem Datenformat von MoneyWallet von Andrea Alessandrini (GPL v3). Kein offizielles Projekt des Originals.';

  @override
  String get openSourceLicenses => 'Open-Source-Lizenzen';

  @override
  String get currencies => 'Währungen';

  @override
  String get newCurrency => 'Neue Währung';

  @override
  String get editCurrency => 'Währung bearbeiten';

  @override
  String get currencyIso => 'ISO-Code';

  @override
  String get currencySymbol => 'Symbol';

  @override
  String get currencyDecimals => 'Nachkommastellen';

  @override
  String get favourite => 'Favorit';

  @override
  String get backup => 'Sicherung';

  @override
  String get createBackup => 'Sicherung erstellen';

  @override
  String get createBackupHint => 'Kompatibel mit MoneyWallet (.mwbx / .mwbs)';

  @override
  String get restoreBackup => 'Sicherung wiederherstellen';

  @override
  String get restoreBackupHint => 'Ersetzt alle aktuellen Daten';

  @override
  String get restoreConfirm =>
      'Alle aktuellen Daten werden durch die Sicherung ersetzt. Fortfahren?';

  @override
  String get backupPassword => 'Passwort (optional)';

  @override
  String get backupPasswordHint =>
      'Mit Passwort wird die Sicherung AES-256-verschlüsselt (.mwbs)';

  @override
  String get enterPassword => 'Passwort';

  @override
  String get passwordRequired => 'Diese Sicherung ist passwortgeschützt';

  @override
  String get wrongPassword => 'Falsches Passwort';

  @override
  String get backupCreated => 'Sicherung erstellt';

  @override
  String backupRestored(int count) {
    return 'Sicherung wiederhergestellt: $count Buchungen';
  }

  @override
  String backupSkipped(int count) {
    return '$count ungültige Einträge wurden übersprungen';
  }

  @override
  String backupInvalid(String message) {
    return 'Ungültige Sicherungsdatei: $message';
  }

  @override
  String get autoBackup => 'Automatische Sicherung';

  @override
  String get autoBackupHint =>
      'Wird lokal auf dem Gerät gespeichert, wenn sich Daten geändert haben';

  @override
  String get autoBackupInterval => 'Intervall';

  @override
  String everyHours(int hours) {
    return 'Alle $hours Stunden';
  }

  @override
  String get intervalDaily => 'Täglich';

  @override
  String get intervalWeekly => 'Wöchentlich';

  @override
  String autoBackupFolder(String path) {
    return 'Gespeichert in: $path';
  }

  @override
  String lastBackup(String date) {
    return 'Letzte Sicherung: $date';
  }

  @override
  String get localBackups => 'Lokale Sicherungen';

  @override
  String get importExport => 'Import & Export';

  @override
  String get importCsv => 'CSV importieren';

  @override
  String get importCsvHint => 'MoneyWallet-CSV-Format';

  @override
  String importCsvDone(int count) {
    return '$count Buchungen importiert';
  }

  @override
  String importFailed(String message) {
    return 'Import fehlgeschlagen: $message';
  }

  @override
  String get exportData => 'Buchungen exportieren';

  @override
  String get exportFormat => 'Format';

  @override
  String get exportColumns => 'Zusätzliche Spalten';

  @override
  String get exportSeparateWallets => 'Eine Tabelle pro Konto';

  @override
  String get exportAllTime => 'Gesamter Zeitraum';

  @override
  String get exportDone => 'Export erstellt';

  @override
  String get exportTitle => 'Buchungen';

  @override
  String get total => 'Summe';

  @override
  String get welcomeTitle => 'Willkommen bei Money Tracker';

  @override
  String get welcomeText =>
      'Behalte deine Einnahmen und Ausgaben im Blick – privat, offline und ohne Konto.';

  @override
  String get welcomeCreateWallet => 'Erstes Konto anlegen';

  @override
  String get welcomeRestore => 'Sicherung wiederherstellen';

  @override
  String get welcomeRestoreHint =>
      'Funktioniert auch mit MoneyWallet-Sicherungen';

  @override
  String get lockTitle => 'PIN eingeben';

  @override
  String get lockSetPin => 'PIN festlegen';

  @override
  String get lockConfirmPin => 'PIN wiederholen';

  @override
  String get lockPinMismatch => 'Die PINs stimmen nicht überein';

  @override
  String get lockWrongPin => 'Falsche PIN';

  @override
  String get lockUseBiometrics => 'Biometrie verwenden';

  @override
  String get lockReason => 'Money Tracker entsperren';

  @override
  String get errorWalletInTransfer =>
      'Das Konto wird in Umbuchungen verwendet und kann nicht gelöscht werden.';

  @override
  String get errorCategoryHasChildren => 'Lösche zuerst die Unterkategorien.';

  @override
  String get errorCategoryInUse =>
      'Die Kategorie wird von Buchungen, Vorlagen oder Daueraufträgen verwendet.';

  @override
  String get errorCategoryHierarchy =>
      'Es wird nur eine Ebene von Unterkategorien unterstützt.';

  @override
  String get errorCategoryType =>
      'Eine Unterkategorie muss dieselbe Art wie ihre Oberkategorie haben.';

  @override
  String get errorCategorySystem =>
      'Systemkategorien können nicht geändert werden.';

  @override
  String get errorCurrencyInUse =>
      'Die Währung wird von einem Konto verwendet.';

  @override
  String get errorInvalidRule => 'Ungültige Wiederholung.';

  @override
  String get errorSameWallet => 'Bitte zwei verschiedene Konten wählen.';

  @override
  String errorGeneric(String message) {
    return 'Etwas ist schiefgelaufen: $message';
  }

  @override
  String get sysTransfer => 'Umbuchung';

  @override
  String get sysTransferTax => 'Umbuchungsgebühr';

  @override
  String get sysDebt => 'Schuld';

  @override
  String get sysCredit => 'Forderung';

  @override
  String get sysPaidDebt => 'Schuldentilgung';

  @override
  String get sysPaidCredit => 'Rückzahlung erhalten';

  @override
  String get sysTax => 'Steuer';

  @override
  String get sysDeposit => 'Einzahlung';

  @override
  String get sysWithdraw => 'Abhebung';

  @override
  String get defTip => 'Trinkgeld';

  @override
  String get defPrize => 'Gewinn';

  @override
  String get defSalary => 'Gehalt';

  @override
  String get defInterests => 'Zinsen';

  @override
  String get defSale => 'Verkauf';

  @override
  String get defCarExpenses => 'Auto';

  @override
  String get defTravel => 'Reisen';

  @override
  String get defFriends => 'Freunde';

  @override
  String get defTechnology => 'Technik';

  @override
  String get defFoodDrinks => 'Essen & Trinken';

  @override
  String get defHobby => 'Hobby';

  @override
  String get defGroceries => 'Lebensmittel';

  @override
  String get defHousing => 'Wohnen';

  @override
  String get defHealth => 'Gesundheit';
}
