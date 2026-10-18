// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Money Tracker';

  @override
  String get navOverview => 'Overview';

  @override
  String get navTransactions => 'Transactions';

  @override
  String get navStatistics => 'Statistics';

  @override
  String get navMore => 'More';

  @override
  String get actionSave => 'Save';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionAdd => 'Add';

  @override
  String get actionClose => 'Close';

  @override
  String get actionOk => 'OK';

  @override
  String get actionNext => 'Next';

  @override
  String get actionShare => 'Share';

  @override
  String get actionArchive => 'Archive';

  @override
  String get actionUnarchive => 'Restore from archive';

  @override
  String get actionSort => 'Sort';

  @override
  String get actionDuplicate => 'Duplicate';

  @override
  String get actionShowTransactions => 'Show transactions';

  @override
  String get actionSearch => 'Search';

  @override
  String get actionClear => 'Clear';

  @override
  String get actionNone => 'None';

  @override
  String get actionSelect => 'Select';

  @override
  String get actionOpenMap => 'Open in maps';

  @override
  String get confirmDeleteTitle => 'Delete?';

  @override
  String confirmDeleteMessage(String name) {
    return '\"$name\" will be deleted permanently.';
  }

  @override
  String get deleted => 'Deleted';

  @override
  String get saved => 'Saved';

  @override
  String get emptyList => 'Nothing here yet';

  @override
  String get required => 'Required';

  @override
  String get invalidAmount => 'Invalid amount';

  @override
  String get noDescription => 'No description';

  @override
  String get totalWallet => 'All wallets';

  @override
  String get wallets => 'Wallets';

  @override
  String get wallet => 'Wallet';

  @override
  String get newWallet => 'New wallet';

  @override
  String get editWallet => 'Edit wallet';

  @override
  String get walletName => 'Name';

  @override
  String get walletCurrency => 'Currency';

  @override
  String get walletStartMoney => 'Initial balance';

  @override
  String get walletCountInTotal => 'Include in total';

  @override
  String get walletArchived => 'Archived';

  @override
  String get archivedWallets => 'Archived wallets';

  @override
  String get balance => 'Balance';

  @override
  String get totalBalance => 'Total balance';

  @override
  String get income => 'Income';

  @override
  String get expense => 'Expense';

  @override
  String get incomes => 'Income';

  @override
  String get expenses => 'Expenses';

  @override
  String get net => 'Net';

  @override
  String get transfer => 'Transfer';

  @override
  String get transfers => 'Transfers';

  @override
  String get transactions => 'Transactions';

  @override
  String get newTransaction => 'New transaction';

  @override
  String get editTransaction => 'Edit transaction';

  @override
  String get newTransfer => 'New transfer';

  @override
  String get editTransfer => 'Edit transfer';

  @override
  String get amount => 'Amount';

  @override
  String get description => 'Description';

  @override
  String get category => 'Category';

  @override
  String get date => 'Date';

  @override
  String get time => 'Time';

  @override
  String get note => 'Note';

  @override
  String get event => 'Event';

  @override
  String get events => 'Events';

  @override
  String get place => 'Place';

  @override
  String get places => 'Places';

  @override
  String get person => 'Person';

  @override
  String get people => 'People';

  @override
  String get attachments => 'Attachments';

  @override
  String get addAttachment => 'Add attachment';

  @override
  String get attachmentFromCamera => 'Take photo';

  @override
  String get attachmentFromGallery => 'Photo from gallery';

  @override
  String get attachmentFromFile => 'File';

  @override
  String get confirmed => 'Confirmed';

  @override
  String get confirmedHint =>
      'Unconfirmed transactions are not counted in balances';

  @override
  String get countInTotal => 'Count in balance and statistics';

  @override
  String get fromWallet => 'From';

  @override
  String get toWallet => 'To';

  @override
  String get amountReceived => 'Amount received';

  @override
  String get fee => 'Fee';

  @override
  String exchangeRate(String from, String rate, String to) {
    return 'Rate: 1 $from = $rate $to';
  }

  @override
  String get applyModel => 'Use template';

  @override
  String get saveAsModel => 'Save as template';

  @override
  String get planned => 'Planned';

  @override
  String get unconfirmed => 'Unconfirmed';

  @override
  String get transferEditInfo => 'This entry belongs to a transfer.';

  @override
  String get noTransactions => 'No transactions yet';

  @override
  String get noTransactionsHint =>
      'Tap + to record your first income or expense.';

  @override
  String get recentTransactions => 'Recent transactions';

  @override
  String get showAll => 'Show all';

  @override
  String get categories => 'Categories';

  @override
  String get newCategory => 'New category';

  @override
  String get editCategory => 'Edit category';

  @override
  String get categoryName => 'Name';

  @override
  String get parentCategory => 'Parent category';

  @override
  String get noParent => 'No parent (main category)';

  @override
  String get categoryType => 'Type';

  @override
  String get showInReports => 'Show in statistics';

  @override
  String get systemCategories => 'System';

  @override
  String get subcategory => 'Sub category';

  @override
  String get debts => 'Debts';

  @override
  String get debt => 'Debt';

  @override
  String get credit => 'Credit';

  @override
  String get credits =>
      'Based on the ideas and the data format of MoneyWallet by Andrea Alessandrini (GPL v3). Not affiliated with the original project.';

  @override
  String get newDebt => 'New debt';

  @override
  String get newCredit => 'New credit';

  @override
  String get editDebt => 'Edit debt';

  @override
  String get debtTypeDebt => 'I owe money (debt)';

  @override
  String get debtTypeCredit => 'I lent money (credit)';

  @override
  String get expirationDate => 'Due date';

  @override
  String get noExpiration => 'No due date';

  @override
  String get debtCreateTransaction => 'Record the money flow in the wallet';

  @override
  String get debtCreateTransactionHint =>
      'Adds an income (debt) or expense (credit) transaction.';

  @override
  String debtLeft(String amount) {
    return '$amount left';
  }

  @override
  String get debtCompleted => 'Settled';

  @override
  String debtExpiresOn(String date) {
    return 'Due $date';
  }

  @override
  String debtExpired(String date) {
    return 'Overdue since $date';
  }

  @override
  String get debtPay => 'Pay back';

  @override
  String get debtReceive => 'Receive';

  @override
  String get toPay => 'To pay';

  @override
  String get toReceive => 'To receive';

  @override
  String get archived => 'Archived';

  @override
  String get recurrences => 'Recurring';

  @override
  String get newRecurrence => 'New recurring transaction';

  @override
  String get newRecurrentTransfer => 'New recurring transfer';

  @override
  String get editRecurrence => 'Edit recurrence';

  @override
  String get repeat => 'Repeat';

  @override
  String get startDate => 'Start date';

  @override
  String nextOccurrence(String date) {
    return 'Next: $date';
  }

  @override
  String get recurrenceFinished => 'Finished';

  @override
  String get freqDaily => 'Daily';

  @override
  String get freqWeekly => 'Weekly';

  @override
  String get freqMonthly => 'Monthly';

  @override
  String get freqYearly => 'Yearly';

  @override
  String get everyN => 'Every';

  @override
  String intervalDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'days',
      one: 'day',
    );
    return '$_temp0';
  }

  @override
  String intervalWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'weeks',
      one: 'week',
    );
    return '$_temp0';
  }

  @override
  String intervalMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'months',
      one: 'month',
    );
    return '$_temp0';
  }

  @override
  String intervalYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'years',
      one: 'year',
    );
    return '$_temp0';
  }

  @override
  String get onWeekdays => 'On';

  @override
  String get endsNever => 'Never ends';

  @override
  String get endsOn => 'Ends on date';

  @override
  String get endsAfter => 'Ends after occurrences';

  @override
  String get occurrences => 'Occurrences';

  @override
  String get upcoming => 'Upcoming';

  @override
  String recurrenceSummaryUntil(String date) {
    return 'until $date';
  }

  @override
  String recurrenceSummaryCount(int count) {
    return '$count times';
  }

  @override
  String get models => 'Templates';

  @override
  String get newModel => 'New template';

  @override
  String get newTransferModel => 'New transfer template';

  @override
  String get editModel => 'Edit template';

  @override
  String get newEvent => 'New event';

  @override
  String get editEvent => 'Edit event';

  @override
  String get eventRunning => 'Running';

  @override
  String get eventCompleted => 'Completed';

  @override
  String get endDate => 'End date';

  @override
  String get newPerson => 'New person';

  @override
  String get editPerson => 'Edit person';

  @override
  String get newPlace => 'New place';

  @override
  String get editPlace => 'Edit place';

  @override
  String get name => 'Name';

  @override
  String get address => 'Address';

  @override
  String get latitude => 'Latitude';

  @override
  String get longitude => 'Longitude';

  @override
  String get icon => 'Icon';

  @override
  String get iconColor => 'Colour';

  @override
  String get iconSymbol => 'Symbol';

  @override
  String get iconInitials => 'Initials';

  @override
  String get statistics => 'Statistics';

  @override
  String get statsMonth => 'Month';

  @override
  String get statsTrend => 'Trend';

  @override
  String get statsCustom => 'Custom';

  @override
  String get savingsRate => 'Savings rate';

  @override
  String get avgPerDay => 'Ø per day';

  @override
  String get projection => 'Projection';

  @override
  String get projectionHint => 'Expected expenses at the end of the month';

  @override
  String get expensesByCategory => 'Expenses by category';

  @override
  String get incomeByCategory => 'Income by category';

  @override
  String get comparison => 'Compared to previous months';

  @override
  String get vsLastMonth => 'vs. last month';

  @override
  String get vsAverage => 'vs. Ø 3 months';

  @override
  String get cumulativeSpending => 'Spending over the month';

  @override
  String get thisMonth => 'This month';

  @override
  String get lastMonth => 'Last month';

  @override
  String get last12Months => 'Last 12 months';

  @override
  String get topExpenses => 'Largest expenses';

  @override
  String get dailySpending => 'Daily spending';

  @override
  String get noData => 'No data for this period';

  @override
  String get otherCategories => 'Other';

  @override
  String get direct => '(directly)';

  @override
  String get groupBy => 'Group by';

  @override
  String get groupDaily => 'Day';

  @override
  String get groupWeekly => 'Week';

  @override
  String get groupMonthly => 'Month';

  @override
  String get groupYearly => 'Year';

  @override
  String get period => 'Period';

  @override
  String get cashFlow => 'Cash flow';

  @override
  String get currency => 'Currency';

  @override
  String get calendar => 'Calendar';

  @override
  String get search => 'Search';

  @override
  String get searchHint => 'Description, category, note …';

  @override
  String get searchIn => 'Search in';

  @override
  String get minAmount => 'Min. amount';

  @override
  String get maxAmount => 'Max. amount';

  @override
  String get fromDate => 'From';

  @override
  String get toDate => 'To';

  @override
  String results(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count results',
      one: '1 result',
      zero: 'No results',
    );
    return '$_temp0';
  }

  @override
  String get settings => 'Settings';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeColor => 'Accent colour';

  @override
  String get incomeColor => 'Income colour';

  @override
  String get expenseColor => 'Expense colour';

  @override
  String get settingsFormat => 'Formats';

  @override
  String get dateFormat => 'Date format';

  @override
  String get showCurrency => 'Show currency symbol';

  @override
  String get groupDigits => 'Group digits';

  @override
  String get roundDecimals => 'Round decimals';

  @override
  String get alwaysShowSign => 'Always show +/− sign';

  @override
  String get firstDayOfWeek => 'First day of the week';

  @override
  String get firstDayOfMonth => 'First day of the month';

  @override
  String get firstDayOfMonthHint =>
      'E.g. your payday – monthly statistics start on this day';

  @override
  String get groupTransactionsBy => 'Group transactions by';

  @override
  String get settingsSecurity => 'Security';

  @override
  String get lockMode => 'App lock';

  @override
  String get lockNone => 'Off';

  @override
  String get lockPin => 'PIN';

  @override
  String get lockPinBiometric => 'PIN + biometrics';

  @override
  String get changePin => 'Change PIN';

  @override
  String get lockTimeout => 'Lock after';

  @override
  String get lockImmediately => 'Immediately';

  @override
  String lockAfterSeconds(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds seconds',
      one: '1 second',
    );
    return '$_temp0';
  }

  @override
  String lockAfterMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes',
      one: '1 minute',
    );
    return '$_temp0';
  }

  @override
  String get biometricsUnavailable =>
      'Biometrics are not available on this device';

  @override
  String get settingsReminder => 'Daily reminder';

  @override
  String get reminderOff => 'Off';

  @override
  String reminderAt(String time) {
    return 'Every day at $time';
  }

  @override
  String get reminderTitle => 'Money Tracker';

  @override
  String get reminderBody => 'Did you record today\'s expenses?';

  @override
  String get settingsData => 'Data';

  @override
  String get manageCurrencies => 'Currencies';

  @override
  String get backupAndExport => 'Backup & export';

  @override
  String get about => 'About';

  @override
  String get privacy => 'Privacy';

  @override
  String get privacyText =>
      'Money Tracker works completely offline. It has no internet permission, contains no analytics or advertising and collects no data. Your data never leaves your device unless you share a backup or export yourself.';

  @override
  String version(String version) {
    return 'Version $version';
  }

  @override
  String get licenseInfo =>
      'Free software under the GNU General Public License v3.';

  @override
  String get openSourceLicenses => 'Open source licences';

  @override
  String get currencies => 'Currencies';

  @override
  String get newCurrency => 'New currency';

  @override
  String get editCurrency => 'Edit currency';

  @override
  String get currencyIso => 'ISO code';

  @override
  String get currencySymbol => 'Symbol';

  @override
  String get currencyDecimals => 'Decimal places';

  @override
  String get favourite => 'Favourite';

  @override
  String get backup => 'Backup';

  @override
  String get createBackup => 'Create backup';

  @override
  String get createBackupHint => 'Compatible with MoneyWallet (.mwbx / .mwbs)';

  @override
  String get restoreBackup => 'Restore backup';

  @override
  String get restoreBackupHint => 'Replaces all current data';

  @override
  String get restoreConfirm =>
      'All current data will be replaced by the backup. Continue?';

  @override
  String get backupPassword => 'Password (optional)';

  @override
  String get backupPasswordHint =>
      'With a password the backup is AES-256 encrypted (.mwbs)';

  @override
  String get enterPassword => 'Password';

  @override
  String get passwordRequired => 'This backup is password protected';

  @override
  String get wrongPassword => 'Wrong password';

  @override
  String get backupCreated => 'Backup created';

  @override
  String backupRestored(int count) {
    return 'Backup restored: $count transactions';
  }

  @override
  String backupSkipped(int count) {
    return '$count invalid entries were skipped';
  }

  @override
  String backupInvalid(String message) {
    return 'Invalid backup file: $message';
  }

  @override
  String get autoBackup => 'Automatic backup';

  @override
  String get autoBackupHint =>
      'Stored locally on this device when data changed';

  @override
  String get autoBackupInterval => 'Interval';

  @override
  String everyHours(int hours) {
    return 'Every $hours hours';
  }

  @override
  String get intervalDaily => 'Daily';

  @override
  String get intervalWeekly => 'Weekly';

  @override
  String autoBackupFolder(String path) {
    return 'Saved in: $path';
  }

  @override
  String lastBackup(String date) {
    return 'Last backup: $date';
  }

  @override
  String get localBackups => 'Local backups';

  @override
  String get importExport => 'Import & export';

  @override
  String get importCsv => 'Import CSV';

  @override
  String get importCsvHint => 'MoneyWallet CSV format';

  @override
  String importCsvDone(int count) {
    return '$count transactions imported';
  }

  @override
  String importFailed(String message) {
    return 'Import failed: $message';
  }

  @override
  String get exportData => 'Export transactions';

  @override
  String get exportFormat => 'Format';

  @override
  String get exportColumns => 'Additional columns';

  @override
  String get exportSeparateWallets => 'One table per wallet';

  @override
  String get exportAllTime => 'All time';

  @override
  String get exportDone => 'Export created';

  @override
  String get exportTitle => 'Transactions';

  @override
  String get total => 'Total';

  @override
  String get welcomeTitle => 'Welcome to Money Tracker';

  @override
  String get welcomeText =>
      'Keep track of your income and expenses – private, offline and without an account.';

  @override
  String get welcomeCreateWallet => 'Create your first wallet';

  @override
  String get welcomeRestore => 'Restore a backup';

  @override
  String get welcomeRestoreHint => 'Also works with MoneyWallet backups';

  @override
  String get lockTitle => 'Enter PIN';

  @override
  String get lockSetPin => 'Choose a PIN';

  @override
  String get lockConfirmPin => 'Repeat the PIN';

  @override
  String get lockPinMismatch => 'PINs do not match';

  @override
  String get lockWrongPin => 'Wrong PIN';

  @override
  String get lockUseBiometrics => 'Use biometrics';

  @override
  String get lockReason => 'Unlock Money Tracker';

  @override
  String get errorWalletInTransfer =>
      'The wallet is used in transfers and cannot be deleted.';

  @override
  String get errorCategoryHasChildren => 'Delete the sub categories first.';

  @override
  String get errorCategoryInUse =>
      'The category is used by transactions, templates or recurrences.';

  @override
  String get errorCategoryHierarchy =>
      'Only one level of sub categories is supported.';

  @override
  String get errorCategoryType =>
      'A sub category must have the same type as its parent.';

  @override
  String get errorCategorySystem => 'System categories cannot be changed.';

  @override
  String get errorCurrencyInUse => 'The currency is used by a wallet.';

  @override
  String get errorInvalidRule => 'Invalid recurrence.';

  @override
  String get errorSameWallet => 'Choose two different wallets.';

  @override
  String errorGeneric(String message) {
    return 'Something went wrong: $message';
  }

  @override
  String get sysTransfer => 'Transfer';

  @override
  String get sysTransferTax => 'Transfer fee';

  @override
  String get sysDebt => 'Debt';

  @override
  String get sysCredit => 'Credit';

  @override
  String get sysPaidDebt => 'Debt repayment';

  @override
  String get sysPaidCredit => 'Credit repayment';

  @override
  String get sysTax => 'Tax';

  @override
  String get sysDeposit => 'Deposit';

  @override
  String get sysWithdraw => 'Withdrawal';

  @override
  String get defTip => 'Tip';

  @override
  String get defPrize => 'Prize';

  @override
  String get defSalary => 'Salary';

  @override
  String get defInterests => 'Interests';

  @override
  String get defSale => 'Sale';

  @override
  String get defCarExpenses => 'Car expenses';

  @override
  String get defTravel => 'Travel';

  @override
  String get defFriends => 'Friends';

  @override
  String get defTechnology => 'Technology';

  @override
  String get defFoodDrinks => 'Food and drinks';

  @override
  String get defHobby => 'Hobby';

  @override
  String get defGroceries => 'Groceries';

  @override
  String get defHousing => 'Housing';

  @override
  String get defHealth => 'Health';
}
