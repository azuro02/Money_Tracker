/// Plain data classes for the database rows. Field semantics follow the
/// original MoneyWallet model (money in minor units, dates as local strings).
library;

import '../core/app_icon.dart';
import '../core/dates.dart';

/// `transaction.direction` values.
abstract final class Direction {
  static const int expense = 0;
  static const int income = 1;
}

/// `category.type` values.
abstract final class CategoryType {
  static const int income = 0;
  static const int expense = 1;
  static const int system = 2;
}

/// `transaction.type` values.
abstract final class TransactionType {
  static const int standard = 0;
  static const int transfer = 1;
  static const int debt = 2;
  static const int saving = 3;
  static const int model = 4;
}

/// `debt.type` values.
abstract final class DebtType {
  static const int debt = 0;
  static const int credit = 1;
}

/// Tags of the system categories created by the original app.
abstract final class SystemTag {
  static const transfer = 'system::transfer';
  static const transferTax = 'system::transfer_tax';
  static const debt = 'system::debt';
  static const credit = 'system::credit';
  static const paidDebt = 'system::paid_debt';
  static const paidCredit = 'system::paid_credit';
  static const tax = 'system::tax';
  static const deposit = 'system::deposit';
  static const withdraw = 'system::withdraw';

  static const all = [
    transfer, transferTax, debt, credit, paidDebt, paidCredit, tax, deposit,
    withdraw,
  ];

  /// System categories belonging to features this app does not offer.
  static const hidden = {deposit, withdraw};

  /// English names used by the original app.
  static const defaultNames = {
    transfer: 'Transfer',
    transferTax: 'Transfer tax',
    debt: 'Debt',
    credit: 'Credit',
    paidDebt: 'Debt paid',
    paidCredit: 'Credit paid',
    tax: 'Tax',
    deposit: 'Deposit',
    withdraw: 'Withdraw',
  };

  static String uuidFor(String tag) => 'system-uuid-$tag';
}

bool _b(Object? v) => v == 1 || v == true;
int _i(Object? v) => v == null ? 0 : (v as num).toInt();

class Currency {
  const Currency({
    required this.iso,
    required this.name,
    this.symbol,
    this.decimals = 2,
    this.favourite = false,
  });

  factory Currency.fromRow(Map<String, Object?> r) => Currency(
        iso: r['iso'] as String,
        name: r['name'] as String,
        symbol: r['symbol'] as String?,
        decimals: _i(r['decimals']),
        favourite: _b(r['favourite']),
      );

  final String iso;
  final String name;
  final String? symbol;
  final int decimals;
  final bool favourite;

  /// Symbol shown next to amounts; falls back to the ISO code.
  String get displaySymbol =>
      (symbol == null || symbol!.isEmpty) ? iso : symbol!;

  Map<String, Object?> toRow() => {
        'iso': iso,
        'name': name,
        'symbol': symbol,
        'decimals': decimals,
        'favourite': favourite,
      };
}

class Wallet {
  const Wallet({
    required this.uuid,
    required this.name,
    required this.icon,
    required this.currency,
    this.startMoney = 0,
    this.countInTotal = true,
    this.archived = false,
    this.note,
    this.tag,
    this.index = 0,
  });

  factory Wallet.fromRow(Map<String, Object?> r) => Wallet(
        uuid: r['uuid'] as String,
        name: r['name'] as String,
        icon: AppIcon.parse(r['icon'] as String?),
        currency: r['currency'] as String,
        startMoney: _i(r['start_money']),
        countInTotal: _b(r['count_in_total']),
        archived: _b(r['archived']),
        note: r['note'] as String?,
        tag: r['tag'] as String?,
        index: _i(r['index']),
      );

  final String uuid;
  final String name;
  final AppIcon icon;
  final String currency;
  final int startMoney;
  final bool countInTotal;
  final bool archived;
  final String? note;
  final String? tag;
  final int index;

  Map<String, Object?> toRow() => {
        'uuid': uuid,
        'name': name,
        'icon': icon.toJson(),
        'currency': currency,
        'start_money': startMoney,
        'count_in_total': countInTotal,
        'archived': archived,
        'note': note,
        'tag': tag,
        'index': index,
      };

  Wallet copyWith({bool? archived, int? index}) => Wallet(
        uuid: uuid,
        name: name,
        icon: icon,
        currency: currency,
        startMoney: startMoney,
        countInTotal: countInTotal,
        archived: archived ?? this.archived,
        note: note,
        tag: tag,
        index: index ?? this.index,
      );
}

class Category {
  const Category({
    required this.uuid,
    required this.name,
    required this.icon,
    required this.type,
    this.parent,
    this.tag,
    this.showReport = true,
    this.index = 0,
  });

  factory Category.fromRow(Map<String, Object?> r) => Category(
        uuid: r['uuid'] as String,
        name: r['name'] as String,
        icon: AppIcon.parse(r['icon'] as String?),
        type: _i(r['type']),
        parent: r['parent'] as String?,
        tag: r['tag'] as String?,
        showReport: _b(r['show_report']),
        index: _i(r['index']),
      );

  final String uuid;
  final String name;
  final AppIcon icon;
  final int type;
  final String? parent;
  final String? tag;
  final bool showReport;
  final int index;

  bool get isSystem => type == CategoryType.system;

  Map<String, Object?> toRow() => {
        'uuid': uuid,
        'name': name,
        'icon': icon.toJson(),
        'type': type,
        'parent': parent,
        'tag': tag,
        'show_report': showReport,
        'index': index,
      };
}

class Event {
  const Event({
    required this.uuid,
    required this.name,
    required this.icon,
    required this.startDate,
    required this.endDate,
    this.note,
    this.tag,
  });

  factory Event.fromRow(Map<String, Object?> r) => Event(
        uuid: r['uuid'] as String,
        name: r['name'] as String,
        icon: AppIcon.parse(r['icon'] as String?),
        note: r['note'] as String?,
        startDate: parseSqlDateTime(r['start_date'] as String),
        endDate: parseSqlDateTime(r['end_date'] as String),
        tag: r['tag'] as String?,
      );

  final String uuid;
  final String name;
  final AppIcon icon;
  final String? note;
  final DateTime startDate;
  final DateTime endDate;
  final String? tag;

  bool isRunning(DateTime now) => !dateOnly(now).isAfter(dateOnly(endDate));

  Map<String, Object?> toRow() => {
        'uuid': uuid,
        'name': name,
        'icon': icon.toJson(),
        'note': note,
        'start_date': toSqlDate(startDate),
        'end_date': toSqlDate(endDate),
        'tag': tag,
      };
}

class Place {
  const Place({
    required this.uuid,
    required this.name,
    required this.icon,
    this.address,
    this.latitude,
    this.longitude,
    this.tag,
  });

  factory Place.fromRow(Map<String, Object?> r) => Place(
        uuid: r['uuid'] as String,
        name: r['name'] as String,
        icon: AppIcon.parse(r['icon'] as String?),
        address: r['address'] as String?,
        latitude: (r['latitude'] as num?)?.toDouble(),
        longitude: (r['longitude'] as num?)?.toDouble(),
        tag: r['tag'] as String?,
      );

  final String uuid;
  final String name;
  final AppIcon icon;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? tag;

  Map<String, Object?> toRow() => {
        'uuid': uuid,
        'name': name,
        'icon': icon.toJson(),
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'tag': tag,
      };
}

class Person {
  const Person({
    required this.uuid,
    required this.name,
    required this.icon,
    this.note,
    this.tag,
  });

  factory Person.fromRow(Map<String, Object?> r) => Person(
        uuid: r['uuid'] as String,
        name: r['name'] as String,
        icon: AppIcon.parse(r['icon'] as String?),
        note: r['note'] as String?,
        tag: r['tag'] as String?,
      );

  final String uuid;
  final String name;
  final AppIcon icon;
  final String? note;
  final String? tag;

  Map<String, Object?> toRow() => {
        'uuid': uuid,
        'name': name,
        'icon': icon.toJson(),
        'note': note,
        'tag': tag,
      };
}

class Debt {
  const Debt({
    required this.uuid,
    required this.type,
    required this.icon,
    required this.description,
    required this.date,
    required this.wallet,
    required this.money,
    this.expirationDate,
    this.note,
    this.place,
    this.archived = false,
    this.tag,
  });

  factory Debt.fromRow(Map<String, Object?> r) => Debt(
        uuid: r['uuid'] as String,
        type: _i(r['type']),
        icon: AppIcon.parse(r['icon'] as String?),
        description: r['description'] as String,
        date: parseSqlDateTime(r['date'] as String),
        expirationDate: tryParseSqlDateTime(r['expiration_date'] as String?),
        wallet: r['wallet'] as String,
        note: r['note'] as String?,
        place: r['place'] as String?,
        money: _i(r['money']),
        archived: _b(r['archived']),
        tag: r['tag'] as String?,
      );

  final String uuid;
  final int type;
  final AppIcon icon;
  final String description;
  final DateTime date;
  final DateTime? expirationDate;
  final String wallet;
  final String? note;
  final String? place;
  final int money;
  final bool archived;
  final String? tag;

  Map<String, Object?> toRow() => {
        'uuid': uuid,
        'type': type,
        'icon': icon.toJson(),
        'description': description,
        'date': toSqlDate(date),
        'expiration_date':
            expirationDate == null ? null : toSqlDate(expirationDate!),
        'wallet': wallet,
        'note': note,
        'place': place,
        'money': money,
        'archived': archived,
        'tag': tag,
      };
}

class Transaction {
  const Transaction({
    required this.uuid,
    required this.money,
    required this.date,
    required this.category,
    required this.direction,
    required this.wallet,
    this.description,
    this.type = TransactionType.standard,
    this.place,
    this.note,
    this.saving,
    this.debt,
    this.event,
    this.recurrence,
    this.confirmed = true,
    this.countInTotal = true,
    this.tag,
  });

  factory Transaction.fromRow(Map<String, Object?> r) => Transaction(
        uuid: r['uuid'] as String,
        money: _i(r['money']),
        date: parseSqlDateTime(r['date'] as String),
        description: r['description'] as String?,
        category: r['category'] as String,
        direction: _i(r['direction']),
        type: _i(r['type']),
        wallet: r['wallet'] as String,
        place: r['place'] as String?,
        note: r['note'] as String?,
        saving: r['saving'] as String?,
        debt: r['debt'] as String?,
        event: r['event'] as String?,
        recurrence: r['recurrence'] as String?,
        confirmed: _b(r['confirmed']),
        countInTotal: _b(r['count_in_total']),
        tag: r['tag'] as String?,
      );

  final String uuid;

  /// Always positive; the sign comes from [direction].
  final int money;
  final DateTime date;
  final String? description;
  final String category;
  final int direction;
  final int type;
  final String wallet;
  final String? place;
  final String? note;
  final String? saving;
  final String? debt;
  final String? event;
  final String? recurrence;
  final bool confirmed;
  final bool countInTotal;
  final String? tag;

  bool get isIncome => direction == Direction.income;

  int get signedMoney => isIncome ? money : -money;

  Map<String, Object?> toRow() => {
        'uuid': uuid,
        'money': money,
        'date': toSqlDateTime(date),
        'description': description,
        'category': category,
        'direction': direction,
        'type': type,
        'wallet': wallet,
        'place': place,
        'note': note,
        'saving': saving,
        'debt': debt,
        'event': event,
        'recurrence': recurrence,
        'confirmed': confirmed,
        'count_in_total': countInTotal,
        'tag': tag,
      };
}

/// A transaction joined with the names needed for display.
class TransactionView {
  const TransactionView({
    required this.transaction,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryTag,
    required this.categoryType,
    required this.categoryParent,
    required this.walletName,
    required this.currency,
    this.transfer,
    this.eventName,
    this.placeName,
  });

  final Transaction transaction;
  final String categoryName;
  final AppIcon categoryIcon;
  final String? categoryTag;
  final int categoryType;
  final String? categoryParent;
  final String walletName;
  final String currency;

  /// UUID of the transfer this transaction belongs to, if any.
  final String? transfer;
  final String? eventName;
  final String? placeName;
}

class Transfer {
  const Transfer({
    required this.uuid,
    required this.date,
    required this.from,
    required this.to,
    this.description,
    this.tax,
    this.note,
    this.place,
    this.event,
    this.recurrence,
    this.confirmed = true,
    this.countInTotal = true,
    this.tag,
  });

  factory Transfer.fromRow(Map<String, Object?> r) => Transfer(
        uuid: r['uuid'] as String,
        description: r['description'] as String?,
        date: parseSqlDateTime(r['date'] as String),
        from: r['from'] as String,
        to: r['to'] as String,
        tax: r['tax'] as String?,
        note: r['note'] as String?,
        place: r['place'] as String?,
        event: r['event'] as String?,
        recurrence: r['recurrence'] as String?,
        confirmed: _b(r['confirmed']),
        countInTotal: _b(r['count_in_total']),
        tag: r['tag'] as String?,
      );

  final String uuid;
  final String? description;
  final DateTime date;

  /// UUIDs of the generated transactions.
  final String from;
  final String to;
  final String? tax;
  final String? note;
  final String? place;
  final String? event;
  final String? recurrence;
  final bool confirmed;
  final bool countInTotal;
  final String? tag;
}

/// Everything needed to display and edit a transfer.
class TransferView {
  const TransferView({
    required this.transfer,
    required this.fromWallet,
    required this.toWallet,
    required this.fromMoney,
    required this.toMoney,
    required this.taxMoney,
    required this.fromCurrency,
    required this.toCurrency,
    required this.fromWalletName,
    required this.toWalletName,
  });

  final Transfer transfer;
  final String fromWallet;
  final String toWallet;
  final int fromMoney;
  final int toMoney;
  final int taxMoney;
  final String fromCurrency;
  final String toCurrency;
  final String fromWalletName;
  final String toWalletName;
}

class TransactionModel {
  const TransactionModel({
    required this.uuid,
    required this.money,
    required this.category,
    required this.direction,
    required this.wallet,
    this.description,
    this.place,
    this.note,
    this.event,
    this.confirmed = true,
    this.countInTotal = true,
    this.tag,
  });

  factory TransactionModel.fromRow(Map<String, Object?> r) => TransactionModel(
        uuid: r['uuid'] as String,
        money: _i(r['money']),
        description: r['description'] as String?,
        category: r['category'] as String,
        direction: _i(r['direction']),
        wallet: r['wallet'] as String,
        place: r['place'] as String?,
        note: r['note'] as String?,
        event: r['event'] as String?,
        confirmed: _b(r['confirmed']),
        countInTotal: _b(r['count_in_total']),
        tag: r['tag'] as String?,
      );

  final String uuid;
  final int money;
  final String? description;
  final String category;
  final int direction;
  final String wallet;
  final String? place;
  final String? note;
  final String? event;
  final bool confirmed;
  final bool countInTotal;
  final String? tag;

  Map<String, Object?> toRow() => {
        'uuid': uuid,
        'money': money,
        'description': description,
        'category': category,
        'direction': direction,
        'wallet': wallet,
        'place': place,
        'note': note,
        'event': event,
        'confirmed': confirmed,
        'count_in_total': countInTotal,
        'tag': tag,
      };
}

class TransferModel {
  const TransferModel({
    required this.uuid,
    required this.fromWallet,
    required this.toWallet,
    required this.fromMoney,
    required this.toMoney,
    this.taxMoney = 0,
    this.description,
    this.note,
    this.event,
    this.place,
    this.confirmed = true,
    this.countInTotal = true,
    this.tag,
  });

  factory TransferModel.fromRow(Map<String, Object?> r) => TransferModel(
        uuid: r['uuid'] as String,
        description: r['description'] as String?,
        fromWallet: r['from_wallet'] as String,
        toWallet: r['to_wallet'] as String,
        fromMoney: _i(r['from_money']),
        toMoney: _i(r['to_money']),
        taxMoney: _i(r['tax_money']),
        note: r['note'] as String?,
        event: r['event'] as String?,
        place: r['place'] as String?,
        confirmed: _b(r['confirmed']),
        countInTotal: _b(r['count_in_total']),
        tag: r['tag'] as String?,
      );

  final String uuid;
  final String? description;
  final String fromWallet;
  final String toWallet;
  final int fromMoney;
  final int toMoney;
  final int taxMoney;
  final String? note;
  final String? event;
  final String? place;
  final bool confirmed;
  final bool countInTotal;
  final String? tag;

  Map<String, Object?> toRow() => {
        'uuid': uuid,
        'description': description,
        'from_wallet': fromWallet,
        'to_wallet': toWallet,
        'from_money': fromMoney,
        'to_money': toMoney,
        'tax_money': taxMoney,
        'note': note,
        'event': event,
        'place': place,
        'confirmed': confirmed,
        'count_in_total': countInTotal,
        'tag': tag,
      };
}

class RecurrentTransaction {
  const RecurrentTransaction({
    required this.uuid,
    required this.money,
    required this.category,
    required this.direction,
    required this.wallet,
    required this.startDate,
    required this.lastOccurrence,
    required this.rule,
    this.nextOccurrence,
    this.description,
    this.place,
    this.note,
    this.event,
    this.confirmed = true,
    this.countInTotal = true,
    this.tag,
  });

  factory RecurrentTransaction.fromRow(Map<String, Object?> r) =>
      RecurrentTransaction(
        uuid: r['uuid'] as String,
        money: _i(r['money']),
        description: r['description'] as String?,
        category: r['category'] as String,
        direction: _i(r['direction']),
        wallet: r['wallet'] as String,
        place: r['place'] as String?,
        note: r['note'] as String?,
        event: r['event'] as String?,
        confirmed: _b(r['confirmed']),
        countInTotal: _b(r['count_in_total']),
        startDate: parseSqlDateTime(r['start_date'] as String),
        lastOccurrence: parseSqlDateTime(r['last_occurrence'] as String),
        nextOccurrence: tryParseSqlDateTime(r['next_occurrence'] as String?),
        rule: r['rule'] as String,
        tag: r['tag'] as String?,
      );

  final String uuid;
  final int money;
  final String? description;
  final String category;
  final int direction;
  final String wallet;
  final String? place;
  final String? note;
  final String? event;
  final bool confirmed;
  final bool countInTotal;
  final DateTime startDate;
  final DateTime lastOccurrence;

  /// Null once the recurrence is finished.
  final DateTime? nextOccurrence;
  final String rule;
  final String? tag;

  Map<String, Object?> toRow() => {
        'uuid': uuid,
        'money': money,
        'description': description,
        'category': category,
        'direction': direction,
        'wallet': wallet,
        'place': place,
        'note': note,
        'event': event,
        'confirmed': confirmed,
        'count_in_total': countInTotal,
        'start_date': toSqlDate(startDate),
        'last_occurrence': toSqlDate(lastOccurrence),
        'next_occurrence':
            nextOccurrence == null ? null : toSqlDate(nextOccurrence!),
        'rule': rule,
        'tag': tag,
      };
}

class RecurrentTransfer {
  const RecurrentTransfer({
    required this.uuid,
    required this.fromWallet,
    required this.toWallet,
    required this.fromMoney,
    required this.toMoney,
    required this.startDate,
    required this.lastOccurrence,
    required this.rule,
    this.taxMoney = 0,
    this.nextOccurrence,
    this.description,
    this.note,
    this.event,
    this.place,
    this.confirmed = true,
    this.countInTotal = true,
    this.tag,
  });

  factory RecurrentTransfer.fromRow(Map<String, Object?> r) =>
      RecurrentTransfer(
        uuid: r['uuid'] as String,
        description: r['description'] as String?,
        fromWallet: r['from_wallet'] as String,
        toWallet: r['to_wallet'] as String,
        fromMoney: _i(r['from_money']),
        toMoney: _i(r['to_money']),
        taxMoney: _i(r['tax_money']),
        note: r['note'] as String?,
        event: r['event'] as String?,
        place: r['place'] as String?,
        confirmed: _b(r['confirmed']),
        countInTotal: _b(r['count_in_total']),
        startDate: parseSqlDateTime(r['start_date'] as String),
        lastOccurrence: parseSqlDateTime(r['last_occurrence'] as String),
        nextOccurrence: tryParseSqlDateTime(r['next_occurrence'] as String?),
        rule: r['rule'] as String,
        tag: r['tag'] as String?,
      );

  final String uuid;
  final String? description;
  final String fromWallet;
  final String toWallet;
  final int fromMoney;
  final int toMoney;
  final int taxMoney;
  final String? note;
  final String? event;
  final String? place;
  final bool confirmed;
  final bool countInTotal;
  final DateTime startDate;
  final DateTime lastOccurrence;
  final DateTime? nextOccurrence;
  final String rule;
  final String? tag;

  Map<String, Object?> toRow() => {
        'uuid': uuid,
        'description': description,
        'from_wallet': fromWallet,
        'to_wallet': toWallet,
        'from_money': fromMoney,
        'to_money': toMoney,
        'tax_money': taxMoney,
        'note': note,
        'event': event,
        'place': place,
        'confirmed': confirmed,
        'count_in_total': countInTotal,
        'start_date': toSqlDate(startDate),
        'last_occurrence': toSqlDate(lastOccurrence),
        'next_occurrence':
            nextOccurrence == null ? null : toSqlDate(nextOccurrence!),
        'rule': rule,
        'tag': tag,
      };
}

class Attachment {
  const Attachment({
    required this.uuid,
    required this.file,
    required this.name,
    required this.size,
    this.type,
    this.tag,
  });

  factory Attachment.fromRow(Map<String, Object?> r) => Attachment(
        uuid: r['uuid'] as String,
        file: r['file'] as String,
        name: r['name'] as String,
        type: r['type'] as String?,
        size: _i(r['size']),
        tag: r['tag'] as String?,
      );

  final String uuid;

  /// File name inside the attachments directory (and in the backup zip).
  final String file;

  /// Original, user visible file name.
  final String name;
  final String? type;
  final int size;
  final String? tag;

  Map<String, Object?> toRow() => {
        'uuid': uuid,
        'file': file,
        'name': name,
        'type': type,
        'size': size,
        'tag': tag,
      };
}
