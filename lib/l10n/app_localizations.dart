import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Money Tracker'**
  String get appTitle;

  /// No description provided for @navOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get navOverview;

  /// No description provided for @navTransactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get navTransactions;

  /// No description provided for @navStatistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get navStatistics;

  /// No description provided for @navMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navMore;

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @actionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get actionEdit;

  /// No description provided for @actionAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get actionAdd;

  /// No description provided for @actionClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get actionClose;

  /// No description provided for @actionOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get actionOk;

  /// No description provided for @actionNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get actionNext;

  /// No description provided for @actionShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get actionShare;

  /// No description provided for @actionArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get actionArchive;

  /// No description provided for @actionUnarchive.
  ///
  /// In en, this message translates to:
  /// **'Restore from archive'**
  String get actionUnarchive;

  /// No description provided for @actionSort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get actionSort;

  /// No description provided for @actionDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get actionDuplicate;

  /// No description provided for @actionShowTransactions.
  ///
  /// In en, this message translates to:
  /// **'Show transactions'**
  String get actionShowTransactions;

  /// No description provided for @actionSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get actionSearch;

  /// No description provided for @actionClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get actionClear;

  /// No description provided for @actionNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get actionNone;

  /// No description provided for @actionSelect.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get actionSelect;

  /// No description provided for @actionOpenMap.
  ///
  /// In en, this message translates to:
  /// **'Open in maps'**
  String get actionOpenMap;

  /// No description provided for @confirmDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete?'**
  String get confirmDeleteTitle;

  /// No description provided for @confirmDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" will be deleted permanently.'**
  String confirmDeleteMessage(String name);

  /// No description provided for @deleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get deleted;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @emptyList.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get emptyList;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @invalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Invalid amount'**
  String get invalidAmount;

  /// No description provided for @noDescription.
  ///
  /// In en, this message translates to:
  /// **'No description'**
  String get noDescription;

  /// No description provided for @totalWallet.
  ///
  /// In en, this message translates to:
  /// **'All wallets'**
  String get totalWallet;

  /// No description provided for @wallets.
  ///
  /// In en, this message translates to:
  /// **'Wallets'**
  String get wallets;

  /// No description provided for @wallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get wallet;

  /// No description provided for @newWallet.
  ///
  /// In en, this message translates to:
  /// **'New wallet'**
  String get newWallet;

  /// No description provided for @editWallet.
  ///
  /// In en, this message translates to:
  /// **'Edit wallet'**
  String get editWallet;

  /// No description provided for @walletName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get walletName;

  /// No description provided for @walletCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get walletCurrency;

  /// No description provided for @walletStartMoney.
  ///
  /// In en, this message translates to:
  /// **'Initial balance'**
  String get walletStartMoney;

  /// No description provided for @walletCountInTotal.
  ///
  /// In en, this message translates to:
  /// **'Include in total'**
  String get walletCountInTotal;

  /// No description provided for @walletArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get walletArchived;

  /// No description provided for @archivedWallets.
  ///
  /// In en, this message translates to:
  /// **'Archived wallets'**
  String get archivedWallets;

  /// No description provided for @balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// No description provided for @totalBalance.
  ///
  /// In en, this message translates to:
  /// **'Total balance'**
  String get totalBalance;

  /// No description provided for @income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// No description provided for @expense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expense;

  /// No description provided for @incomes.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get incomes;

  /// No description provided for @expenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expenses;

  /// No description provided for @net.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get net;

  /// No description provided for @transfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transfer;

  /// No description provided for @transfers.
  ///
  /// In en, this message translates to:
  /// **'Transfers'**
  String get transfers;

  /// No description provided for @transactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactions;

  /// No description provided for @newTransaction.
  ///
  /// In en, this message translates to:
  /// **'New transaction'**
  String get newTransaction;

  /// No description provided for @editTransaction.
  ///
  /// In en, this message translates to:
  /// **'Edit transaction'**
  String get editTransaction;

  /// No description provided for @newTransfer.
  ///
  /// In en, this message translates to:
  /// **'New transfer'**
  String get newTransfer;

  /// No description provided for @editTransfer.
  ///
  /// In en, this message translates to:
  /// **'Edit transfer'**
  String get editTransfer;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @event.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get event;

  /// No description provided for @events.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get events;

  /// No description provided for @place.
  ///
  /// In en, this message translates to:
  /// **'Place'**
  String get place;

  /// No description provided for @places.
  ///
  /// In en, this message translates to:
  /// **'Places'**
  String get places;

  /// No description provided for @person.
  ///
  /// In en, this message translates to:
  /// **'Person'**
  String get person;

  /// No description provided for @people.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get people;

  /// No description provided for @attachments.
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get attachments;

  /// No description provided for @addAttachment.
  ///
  /// In en, this message translates to:
  /// **'Add attachment'**
  String get addAttachment;

  /// No description provided for @attachmentFromCamera.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get attachmentFromCamera;

  /// No description provided for @attachmentFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Photo from gallery'**
  String get attachmentFromGallery;

  /// No description provided for @attachmentFromFile.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get attachmentFromFile;

  /// No description provided for @confirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get confirmed;

  /// No description provided for @confirmedHint.
  ///
  /// In en, this message translates to:
  /// **'Unconfirmed transactions are not counted in balances'**
  String get confirmedHint;

  /// No description provided for @countInTotal.
  ///
  /// In en, this message translates to:
  /// **'Count in balance and statistics'**
  String get countInTotal;

  /// No description provided for @fromWallet.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get fromWallet;

  /// No description provided for @toWallet.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get toWallet;

  /// No description provided for @amountReceived.
  ///
  /// In en, this message translates to:
  /// **'Amount received'**
  String get amountReceived;

  /// No description provided for @fee.
  ///
  /// In en, this message translates to:
  /// **'Fee'**
  String get fee;

  /// No description provided for @exchangeRate.
  ///
  /// In en, this message translates to:
  /// **'Rate: 1 {from} = {rate} {to}'**
  String exchangeRate(String from, String rate, String to);

  /// No description provided for @applyModel.
  ///
  /// In en, this message translates to:
  /// **'Use template'**
  String get applyModel;

  /// No description provided for @saveAsModel.
  ///
  /// In en, this message translates to:
  /// **'Save as template'**
  String get saveAsModel;

  /// No description provided for @planned.
  ///
  /// In en, this message translates to:
  /// **'Planned'**
  String get planned;

  /// No description provided for @unconfirmed.
  ///
  /// In en, this message translates to:
  /// **'Unconfirmed'**
  String get unconfirmed;

  /// No description provided for @transferEditInfo.
  ///
  /// In en, this message translates to:
  /// **'This entry belongs to a transfer.'**
  String get transferEditInfo;

  /// No description provided for @noTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get noTransactions;

  /// No description provided for @noTransactionsHint.
  ///
  /// In en, this message translates to:
  /// **'Tap + to record your first income or expense.'**
  String get noTransactionsHint;

  /// No description provided for @recentTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recent transactions'**
  String get recentTransactions;

  /// No description provided for @showAll.
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get showAll;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @newCategory.
  ///
  /// In en, this message translates to:
  /// **'New category'**
  String get newCategory;

  /// No description provided for @editCategory.
  ///
  /// In en, this message translates to:
  /// **'Edit category'**
  String get editCategory;

  /// No description provided for @categoryName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get categoryName;

  /// No description provided for @parentCategory.
  ///
  /// In en, this message translates to:
  /// **'Parent category'**
  String get parentCategory;

  /// No description provided for @noParent.
  ///
  /// In en, this message translates to:
  /// **'No parent (main category)'**
  String get noParent;

  /// No description provided for @categoryType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get categoryType;

  /// No description provided for @showInReports.
  ///
  /// In en, this message translates to:
  /// **'Show in statistics'**
  String get showInReports;

  /// No description provided for @systemCategories.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemCategories;

  /// No description provided for @subcategory.
  ///
  /// In en, this message translates to:
  /// **'Sub category'**
  String get subcategory;

  /// No description provided for @debts.
  ///
  /// In en, this message translates to:
  /// **'Debts'**
  String get debts;

  /// No description provided for @debt.
  ///
  /// In en, this message translates to:
  /// **'Debt'**
  String get debt;

  /// No description provided for @credit.
  ///
  /// In en, this message translates to:
  /// **'Credit'**
  String get credit;

  /// No description provided for @credits.
  ///
  /// In en, this message translates to:
  /// **'Credits'**
  String get credits;

  /// No description provided for @newDebt.
  ///
  /// In en, this message translates to:
  /// **'New debt'**
  String get newDebt;

  /// No description provided for @newCredit.
  ///
  /// In en, this message translates to:
  /// **'New credit'**
  String get newCredit;

  /// No description provided for @editDebt.
  ///
  /// In en, this message translates to:
  /// **'Edit debt'**
  String get editDebt;

  /// No description provided for @debtTypeDebt.
  ///
  /// In en, this message translates to:
  /// **'I owe money (debt)'**
  String get debtTypeDebt;

  /// No description provided for @debtTypeCredit.
  ///
  /// In en, this message translates to:
  /// **'I lent money (credit)'**
  String get debtTypeCredit;

  /// No description provided for @expirationDate.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get expirationDate;

  /// No description provided for @noExpiration.
  ///
  /// In en, this message translates to:
  /// **'No due date'**
  String get noExpiration;

  /// No description provided for @debtCreateTransaction.
  ///
  /// In en, this message translates to:
  /// **'Record the money flow in the wallet'**
  String get debtCreateTransaction;

  /// No description provided for @debtCreateTransactionHint.
  ///
  /// In en, this message translates to:
  /// **'Adds an income (debt) or expense (credit) transaction.'**
  String get debtCreateTransactionHint;

  /// No description provided for @debtLeft.
  ///
  /// In en, this message translates to:
  /// **'{amount} left'**
  String debtLeft(String amount);

  /// No description provided for @debtCompleted.
  ///
  /// In en, this message translates to:
  /// **'Settled'**
  String get debtCompleted;

  /// No description provided for @debtExpiresOn.
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String debtExpiresOn(String date);

  /// No description provided for @debtExpired.
  ///
  /// In en, this message translates to:
  /// **'Overdue since {date}'**
  String debtExpired(String date);

  /// No description provided for @debtPay.
  ///
  /// In en, this message translates to:
  /// **'Pay back'**
  String get debtPay;

  /// No description provided for @debtReceive.
  ///
  /// In en, this message translates to:
  /// **'Receive'**
  String get debtReceive;

  /// No description provided for @toPay.
  ///
  /// In en, this message translates to:
  /// **'To pay'**
  String get toPay;

  /// No description provided for @toReceive.
  ///
  /// In en, this message translates to:
  /// **'To receive'**
  String get toReceive;

  /// No description provided for @archived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get archived;

  /// No description provided for @recurrences.
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get recurrences;

  /// No description provided for @newRecurrence.
  ///
  /// In en, this message translates to:
  /// **'New recurring transaction'**
  String get newRecurrence;

  /// No description provided for @newRecurrentTransfer.
  ///
  /// In en, this message translates to:
  /// **'New recurring transfer'**
  String get newRecurrentTransfer;

  /// No description provided for @editRecurrence.
  ///
  /// In en, this message translates to:
  /// **'Edit recurrence'**
  String get editRecurrence;

  /// No description provided for @repeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeat;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get startDate;

  /// No description provided for @nextOccurrence.
  ///
  /// In en, this message translates to:
  /// **'Next: {date}'**
  String nextOccurrence(String date);

  /// No description provided for @recurrenceFinished.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get recurrenceFinished;

  /// No description provided for @freqDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get freqDaily;

  /// No description provided for @freqWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get freqWeekly;

  /// No description provided for @freqMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get freqMonthly;

  /// No description provided for @freqYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get freqYearly;

  /// No description provided for @everyN.
  ///
  /// In en, this message translates to:
  /// **'Every'**
  String get everyN;

  /// No description provided for @intervalDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{day} other{days}}'**
  String intervalDays(int count);

  /// No description provided for @intervalWeeks.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{week} other{weeks}}'**
  String intervalWeeks(int count);

  /// No description provided for @intervalMonths.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{month} other{months}}'**
  String intervalMonths(int count);

  /// No description provided for @intervalYears.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{year} other{years}}'**
  String intervalYears(int count);

  /// No description provided for @onWeekdays.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get onWeekdays;

  /// No description provided for @endsNever.
  ///
  /// In en, this message translates to:
  /// **'Never ends'**
  String get endsNever;

  /// No description provided for @endsOn.
  ///
  /// In en, this message translates to:
  /// **'Ends on date'**
  String get endsOn;

  /// No description provided for @endsAfter.
  ///
  /// In en, this message translates to:
  /// **'Ends after occurrences'**
  String get endsAfter;

  /// No description provided for @occurrences.
  ///
  /// In en, this message translates to:
  /// **'Occurrences'**
  String get occurrences;

  /// No description provided for @upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcoming;

  /// No description provided for @recurrenceSummaryUntil.
  ///
  /// In en, this message translates to:
  /// **'until {date}'**
  String recurrenceSummaryUntil(String date);

  /// No description provided for @recurrenceSummaryCount.
  ///
  /// In en, this message translates to:
  /// **'{count} times'**
  String recurrenceSummaryCount(int count);

  /// No description provided for @models.
  ///
  /// In en, this message translates to:
  /// **'Templates'**
  String get models;

  /// No description provided for @newModel.
  ///
  /// In en, this message translates to:
  /// **'New template'**
  String get newModel;

  /// No description provided for @newTransferModel.
  ///
  /// In en, this message translates to:
  /// **'New transfer template'**
  String get newTransferModel;

  /// No description provided for @editModel.
  ///
  /// In en, this message translates to:
  /// **'Edit template'**
  String get editModel;

  /// No description provided for @newEvent.
  ///
  /// In en, this message translates to:
  /// **'New event'**
  String get newEvent;

  /// No description provided for @editEvent.
  ///
  /// In en, this message translates to:
  /// **'Edit event'**
  String get editEvent;

  /// No description provided for @eventRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get eventRunning;

  /// No description provided for @eventCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get eventCompleted;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End date'**
  String get endDate;

  /// No description provided for @newPerson.
  ///
  /// In en, this message translates to:
  /// **'New person'**
  String get newPerson;

  /// No description provided for @editPerson.
  ///
  /// In en, this message translates to:
  /// **'Edit person'**
  String get editPerson;

  /// No description provided for @newPlace.
  ///
  /// In en, this message translates to:
  /// **'New place'**
  String get newPlace;

  /// No description provided for @editPlace.
  ///
  /// In en, this message translates to:
  /// **'Edit place'**
  String get editPlace;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @latitude.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get latitude;

  /// No description provided for @longitude.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get longitude;

  /// No description provided for @icon.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get icon;

  /// No description provided for @iconColor.
  ///
  /// In en, this message translates to:
  /// **'Colour'**
  String get iconColor;

  /// No description provided for @iconSymbol.
  ///
  /// In en, this message translates to:
  /// **'Symbol'**
  String get iconSymbol;

  /// No description provided for @iconInitials.
  ///
  /// In en, this message translates to:
  /// **'Initials'**
  String get iconInitials;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @statsMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get statsMonth;

  /// No description provided for @statsTrend.
  ///
  /// In en, this message translates to:
  /// **'Trend'**
  String get statsTrend;

  /// No description provided for @statsCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get statsCustom;

  /// No description provided for @savingsRate.
  ///
  /// In en, this message translates to:
  /// **'Savings rate'**
  String get savingsRate;

  /// No description provided for @avgPerDay.
  ///
  /// In en, this message translates to:
  /// **'Ø per day'**
  String get avgPerDay;

  /// No description provided for @projection.
  ///
  /// In en, this message translates to:
  /// **'Projection'**
  String get projection;

  /// No description provided for @projectionHint.
  ///
  /// In en, this message translates to:
  /// **'Expected expenses at the end of the month'**
  String get projectionHint;

  /// No description provided for @expensesByCategory.
  ///
  /// In en, this message translates to:
  /// **'Expenses by category'**
  String get expensesByCategory;

  /// No description provided for @incomeByCategory.
  ///
  /// In en, this message translates to:
  /// **'Income by category'**
  String get incomeByCategory;

  /// No description provided for @comparison.
  ///
  /// In en, this message translates to:
  /// **'Compared to previous months'**
  String get comparison;

  /// No description provided for @vsLastMonth.
  ///
  /// In en, this message translates to:
  /// **'vs. last month'**
  String get vsLastMonth;

  /// No description provided for @vsAverage.
  ///
  /// In en, this message translates to:
  /// **'vs. Ø 3 months'**
  String get vsAverage;

  /// No description provided for @cumulativeSpending.
  ///
  /// In en, this message translates to:
  /// **'Spending over the month'**
  String get cumulativeSpending;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get thisMonth;

  /// No description provided for @lastMonth.
  ///
  /// In en, this message translates to:
  /// **'Last month'**
  String get lastMonth;

  /// No description provided for @last12Months.
  ///
  /// In en, this message translates to:
  /// **'Last 12 months'**
  String get last12Months;

  /// No description provided for @topExpenses.
  ///
  /// In en, this message translates to:
  /// **'Largest expenses'**
  String get topExpenses;

  /// No description provided for @dailySpending.
  ///
  /// In en, this message translates to:
  /// **'Daily spending'**
  String get dailySpending;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data for this period'**
  String get noData;

  /// No description provided for @otherCategories.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get otherCategories;

  /// No description provided for @direct.
  ///
  /// In en, this message translates to:
  /// **'(directly)'**
  String get direct;

  /// No description provided for @groupBy.
  ///
  /// In en, this message translates to:
  /// **'Group by'**
  String get groupBy;

  /// No description provided for @groupDaily.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get groupDaily;

  /// No description provided for @groupWeekly.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get groupWeekly;

  /// No description provided for @groupMonthly.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get groupMonthly;

  /// No description provided for @groupYearly.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get groupYearly;

  /// No description provided for @period.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get period;

  /// No description provided for @cashFlow.
  ///
  /// In en, this message translates to:
  /// **'Cash flow'**
  String get cashFlow;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Description, category, note …'**
  String get searchHint;

  /// No description provided for @searchIn.
  ///
  /// In en, this message translates to:
  /// **'Search in'**
  String get searchIn;

  /// No description provided for @minAmount.
  ///
  /// In en, this message translates to:
  /// **'Min. amount'**
  String get minAmount;

  /// No description provided for @maxAmount.
  ///
  /// In en, this message translates to:
  /// **'Max. amount'**
  String get maxAmount;

  /// No description provided for @fromDate.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get fromDate;

  /// No description provided for @toDate.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get toDate;

  /// No description provided for @results.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No results} =1{1 result} other{{count} results}}'**
  String results(int count);

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeColor.
  ///
  /// In en, this message translates to:
  /// **'Accent colour'**
  String get themeColor;

  /// No description provided for @incomeColor.
  ///
  /// In en, this message translates to:
  /// **'Income colour'**
  String get incomeColor;

  /// No description provided for @expenseColor.
  ///
  /// In en, this message translates to:
  /// **'Expense colour'**
  String get expenseColor;

  /// No description provided for @settingsFormat.
  ///
  /// In en, this message translates to:
  /// **'Formats'**
  String get settingsFormat;

  /// No description provided for @dateFormat.
  ///
  /// In en, this message translates to:
  /// **'Date format'**
  String get dateFormat;

  /// No description provided for @showCurrency.
  ///
  /// In en, this message translates to:
  /// **'Show currency symbol'**
  String get showCurrency;

  /// No description provided for @groupDigits.
  ///
  /// In en, this message translates to:
  /// **'Group digits'**
  String get groupDigits;

  /// No description provided for @roundDecimals.
  ///
  /// In en, this message translates to:
  /// **'Round decimals'**
  String get roundDecimals;

  /// No description provided for @alwaysShowSign.
  ///
  /// In en, this message translates to:
  /// **'Always show +/− sign'**
  String get alwaysShowSign;

  /// No description provided for @firstDayOfWeek.
  ///
  /// In en, this message translates to:
  /// **'First day of the week'**
  String get firstDayOfWeek;

  /// No description provided for @firstDayOfMonth.
  ///
  /// In en, this message translates to:
  /// **'First day of the month'**
  String get firstDayOfMonth;

  /// No description provided for @firstDayOfMonthHint.
  ///
  /// In en, this message translates to:
  /// **'E.g. your payday – monthly statistics start on this day'**
  String get firstDayOfMonthHint;

  /// No description provided for @groupTransactionsBy.
  ///
  /// In en, this message translates to:
  /// **'Group transactions by'**
  String get groupTransactionsBy;

  /// No description provided for @settingsSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get settingsSecurity;

  /// No description provided for @lockMode.
  ///
  /// In en, this message translates to:
  /// **'App lock'**
  String get lockMode;

  /// No description provided for @lockNone.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get lockNone;

  /// No description provided for @lockPin.
  ///
  /// In en, this message translates to:
  /// **'PIN'**
  String get lockPin;

  /// No description provided for @lockPinBiometric.
  ///
  /// In en, this message translates to:
  /// **'PIN + biometrics'**
  String get lockPinBiometric;

  /// No description provided for @changePin.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get changePin;

  /// No description provided for @lockTimeout.
  ///
  /// In en, this message translates to:
  /// **'Lock after'**
  String get lockTimeout;

  /// No description provided for @lockImmediately.
  ///
  /// In en, this message translates to:
  /// **'Immediately'**
  String get lockImmediately;

  /// No description provided for @lockAfterSeconds.
  ///
  /// In en, this message translates to:
  /// **'{seconds, plural, =1{1 second} other{{seconds} seconds}}'**
  String lockAfterSeconds(int seconds);

  /// No description provided for @lockAfterMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, =1{1 minute} other{{minutes} minutes}}'**
  String lockAfterMinutes(int minutes);

  /// No description provided for @biometricsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Biometrics are not available on this device'**
  String get biometricsUnavailable;

  /// No description provided for @settingsReminder.
  ///
  /// In en, this message translates to:
  /// **'Daily reminder'**
  String get settingsReminder;

  /// No description provided for @reminderOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get reminderOff;

  /// No description provided for @reminderAt.
  ///
  /// In en, this message translates to:
  /// **'Every day at {time}'**
  String reminderAt(String time);

  /// No description provided for @reminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Money Tracker'**
  String get reminderTitle;

  /// No description provided for @reminderBody.
  ///
  /// In en, this message translates to:
  /// **'Did you record today\'s expenses?'**
  String get reminderBody;

  /// No description provided for @settingsData.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get settingsData;

  /// No description provided for @manageCurrencies.
  ///
  /// In en, this message translates to:
  /// **'Currencies'**
  String get manageCurrencies;

  /// No description provided for @backupAndExport.
  ///
  /// In en, this message translates to:
  /// **'Backup & export'**
  String get backupAndExport;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @privacyText.
  ///
  /// In en, this message translates to:
  /// **'Money Tracker works completely offline. It has no internet permission, contains no analytics or advertising and collects no data. Your data never leaves your device unless you share a backup or export yourself.'**
  String get privacyText;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String version(String version);

  /// No description provided for @licenseInfo.
  ///
  /// In en, this message translates to:
  /// **'Free software under the GNU General Public License v3.'**
  String get licenseInfo;

  /// No description provided for @aboutCredits.
  ///
  /// In en, this message translates to:
  /// **'Based on the ideas and the data format of MoneyWallet by Andrea Alessandrini (GPL v3). Not affiliated with the original project.'**
  String get aboutCredits;

  /// No description provided for @openSourceLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open source licences'**
  String get openSourceLicenses;

  /// No description provided for @currencies.
  ///
  /// In en, this message translates to:
  /// **'Currencies'**
  String get currencies;

  /// No description provided for @newCurrency.
  ///
  /// In en, this message translates to:
  /// **'New currency'**
  String get newCurrency;

  /// No description provided for @editCurrency.
  ///
  /// In en, this message translates to:
  /// **'Edit currency'**
  String get editCurrency;

  /// No description provided for @currencyIso.
  ///
  /// In en, this message translates to:
  /// **'ISO code'**
  String get currencyIso;

  /// No description provided for @currencySymbol.
  ///
  /// In en, this message translates to:
  /// **'Symbol'**
  String get currencySymbol;

  /// No description provided for @currencyDecimals.
  ///
  /// In en, this message translates to:
  /// **'Decimal places'**
  String get currencyDecimals;

  /// No description provided for @favourite.
  ///
  /// In en, this message translates to:
  /// **'Favourite'**
  String get favourite;

  /// No description provided for @backup.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get backup;

  /// No description provided for @createBackup.
  ///
  /// In en, this message translates to:
  /// **'Create backup'**
  String get createBackup;

  /// No description provided for @createBackupHint.
  ///
  /// In en, this message translates to:
  /// **'Compatible with MoneyWallet (.mwbx / .mwbs)'**
  String get createBackupHint;

  /// No description provided for @restoreBackup.
  ///
  /// In en, this message translates to:
  /// **'Restore backup'**
  String get restoreBackup;

  /// No description provided for @restoreBackupHint.
  ///
  /// In en, this message translates to:
  /// **'Replaces all current data'**
  String get restoreBackupHint;

  /// No description provided for @restoreConfirm.
  ///
  /// In en, this message translates to:
  /// **'All current data will be replaced by the backup. Continue?'**
  String get restoreConfirm;

  /// No description provided for @backupPassword.
  ///
  /// In en, this message translates to:
  /// **'Password (optional)'**
  String get backupPassword;

  /// No description provided for @backupPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'With a password the backup is AES-256 encrypted (.mwbs)'**
  String get backupPasswordHint;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get enterPassword;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'This backup is password protected'**
  String get passwordRequired;

  /// No description provided for @wrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Wrong password'**
  String get wrongPassword;

  /// No description provided for @backupCreated.
  ///
  /// In en, this message translates to:
  /// **'Backup created'**
  String get backupCreated;

  /// No description provided for @backupRestored.
  ///
  /// In en, this message translates to:
  /// **'Backup restored: {count} transactions'**
  String backupRestored(int count);

  /// No description provided for @backupSkipped.
  ///
  /// In en, this message translates to:
  /// **'{count} invalid entries were skipped'**
  String backupSkipped(int count);

  /// No description provided for @backupInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid backup file: {message}'**
  String backupInvalid(String message);

  /// No description provided for @autoBackup.
  ///
  /// In en, this message translates to:
  /// **'Automatic backup'**
  String get autoBackup;

  /// No description provided for @autoBackupHint.
  ///
  /// In en, this message translates to:
  /// **'Stored locally on this device when data changed'**
  String get autoBackupHint;

  /// No description provided for @autoBackupInterval.
  ///
  /// In en, this message translates to:
  /// **'Interval'**
  String get autoBackupInterval;

  /// No description provided for @everyHours.
  ///
  /// In en, this message translates to:
  /// **'Every {hours} hours'**
  String everyHours(int hours);

  /// No description provided for @intervalDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get intervalDaily;

  /// No description provided for @intervalWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get intervalWeekly;

  /// No description provided for @autoBackupFolder.
  ///
  /// In en, this message translates to:
  /// **'Saved in: {path}'**
  String autoBackupFolder(String path);

  /// No description provided for @lastBackup.
  ///
  /// In en, this message translates to:
  /// **'Last backup: {date}'**
  String lastBackup(String date);

  /// No description provided for @localBackups.
  ///
  /// In en, this message translates to:
  /// **'Local backups'**
  String get localBackups;

  /// No description provided for @importExport.
  ///
  /// In en, this message translates to:
  /// **'Import & export'**
  String get importExport;

  /// No description provided for @importCsv.
  ///
  /// In en, this message translates to:
  /// **'Import CSV'**
  String get importCsv;

  /// No description provided for @importCsvHint.
  ///
  /// In en, this message translates to:
  /// **'MoneyWallet CSV format'**
  String get importCsvHint;

  /// No description provided for @importCsvDone.
  ///
  /// In en, this message translates to:
  /// **'{count} transactions imported'**
  String importCsvDone(int count);

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed: {message}'**
  String importFailed(String message);

  /// No description provided for @exportData.
  ///
  /// In en, this message translates to:
  /// **'Export transactions'**
  String get exportData;

  /// No description provided for @exportFormat.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get exportFormat;

  /// No description provided for @exportColumns.
  ///
  /// In en, this message translates to:
  /// **'Additional columns'**
  String get exportColumns;

  /// No description provided for @exportSeparateWallets.
  ///
  /// In en, this message translates to:
  /// **'One table per wallet'**
  String get exportSeparateWallets;

  /// No description provided for @exportAllTime.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get exportAllTime;

  /// No description provided for @exportDone.
  ///
  /// In en, this message translates to:
  /// **'Export created'**
  String get exportDone;

  /// No description provided for @exportTitle.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get exportTitle;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Money Tracker'**
  String get welcomeTitle;

  /// No description provided for @welcomeText.
  ///
  /// In en, this message translates to:
  /// **'Keep track of your income and expenses – private, offline and without an account.'**
  String get welcomeText;

  /// No description provided for @welcomeCreateWallet.
  ///
  /// In en, this message translates to:
  /// **'Create your first wallet'**
  String get welcomeCreateWallet;

  /// No description provided for @welcomeRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore a backup'**
  String get welcomeRestore;

  /// No description provided for @welcomeRestoreHint.
  ///
  /// In en, this message translates to:
  /// **'Also works with MoneyWallet backups'**
  String get welcomeRestoreHint;

  /// No description provided for @lockTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter PIN'**
  String get lockTitle;

  /// No description provided for @lockSetPin.
  ///
  /// In en, this message translates to:
  /// **'Choose a PIN'**
  String get lockSetPin;

  /// No description provided for @lockConfirmPin.
  ///
  /// In en, this message translates to:
  /// **'Repeat the PIN'**
  String get lockConfirmPin;

  /// No description provided for @lockPinMismatch.
  ///
  /// In en, this message translates to:
  /// **'PINs do not match'**
  String get lockPinMismatch;

  /// No description provided for @lockWrongPin.
  ///
  /// In en, this message translates to:
  /// **'Wrong PIN'**
  String get lockWrongPin;

  /// No description provided for @lockUseBiometrics.
  ///
  /// In en, this message translates to:
  /// **'Use biometrics'**
  String get lockUseBiometrics;

  /// No description provided for @lockReason.
  ///
  /// In en, this message translates to:
  /// **'Unlock Money Tracker'**
  String get lockReason;

  /// No description provided for @errorWalletInTransfer.
  ///
  /// In en, this message translates to:
  /// **'The wallet is used in transfers and cannot be deleted.'**
  String get errorWalletInTransfer;

  /// No description provided for @errorCategoryHasChildren.
  ///
  /// In en, this message translates to:
  /// **'Delete the sub categories first.'**
  String get errorCategoryHasChildren;

  /// No description provided for @errorCategoryInUse.
  ///
  /// In en, this message translates to:
  /// **'The category is used by transactions, templates or recurrences.'**
  String get errorCategoryInUse;

  /// No description provided for @errorCategoryHierarchy.
  ///
  /// In en, this message translates to:
  /// **'Only one level of sub categories is supported.'**
  String get errorCategoryHierarchy;

  /// No description provided for @errorCategoryType.
  ///
  /// In en, this message translates to:
  /// **'A sub category must have the same type as its parent.'**
  String get errorCategoryType;

  /// No description provided for @errorCategorySystem.
  ///
  /// In en, this message translates to:
  /// **'System categories cannot be changed.'**
  String get errorCategorySystem;

  /// No description provided for @errorCurrencyInUse.
  ///
  /// In en, this message translates to:
  /// **'The currency is used by a wallet.'**
  String get errorCurrencyInUse;

  /// No description provided for @errorInvalidRule.
  ///
  /// In en, this message translates to:
  /// **'Invalid recurrence.'**
  String get errorInvalidRule;

  /// No description provided for @errorSameWallet.
  ///
  /// In en, this message translates to:
  /// **'Choose two different wallets.'**
  String get errorSameWallet;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong: {message}'**
  String errorGeneric(String message);

  /// No description provided for @sysTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get sysTransfer;

  /// No description provided for @sysTransferTax.
  ///
  /// In en, this message translates to:
  /// **'Transfer fee'**
  String get sysTransferTax;

  /// No description provided for @sysDebt.
  ///
  /// In en, this message translates to:
  /// **'Debt'**
  String get sysDebt;

  /// No description provided for @sysCredit.
  ///
  /// In en, this message translates to:
  /// **'Credit'**
  String get sysCredit;

  /// No description provided for @sysPaidDebt.
  ///
  /// In en, this message translates to:
  /// **'Debt repayment'**
  String get sysPaidDebt;

  /// No description provided for @sysPaidCredit.
  ///
  /// In en, this message translates to:
  /// **'Credit repayment'**
  String get sysPaidCredit;

  /// No description provided for @sysTax.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get sysTax;

  /// No description provided for @sysDeposit.
  ///
  /// In en, this message translates to:
  /// **'Deposit'**
  String get sysDeposit;

  /// No description provided for @sysWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal'**
  String get sysWithdraw;

  /// No description provided for @defTip.
  ///
  /// In en, this message translates to:
  /// **'Tip'**
  String get defTip;

  /// No description provided for @defPrize.
  ///
  /// In en, this message translates to:
  /// **'Prize'**
  String get defPrize;

  /// No description provided for @defSalary.
  ///
  /// In en, this message translates to:
  /// **'Salary'**
  String get defSalary;

  /// No description provided for @defInterests.
  ///
  /// In en, this message translates to:
  /// **'Interests'**
  String get defInterests;

  /// No description provided for @defSale.
  ///
  /// In en, this message translates to:
  /// **'Sale'**
  String get defSale;

  /// No description provided for @defCarExpenses.
  ///
  /// In en, this message translates to:
  /// **'Car expenses'**
  String get defCarExpenses;

  /// No description provided for @defTravel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get defTravel;

  /// No description provided for @defFriends.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get defFriends;

  /// No description provided for @defTechnology.
  ///
  /// In en, this message translates to:
  /// **'Technology'**
  String get defTechnology;

  /// No description provided for @defFoodDrinks.
  ///
  /// In en, this message translates to:
  /// **'Food and drinks'**
  String get defFoodDrinks;

  /// No description provided for @defHobby.
  ///
  /// In en, this message translates to:
  /// **'Hobby'**
  String get defHobby;

  /// No description provided for @defGroceries.
  ///
  /// In en, this message translates to:
  /// **'Groceries'**
  String get defGroceries;

  /// No description provided for @defHousing.
  ///
  /// In en, this message translates to:
  /// **'Housing'**
  String get defHousing;

  /// No description provided for @defHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get defHealth;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
