import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../core/app_icon.dart';
import '../core/dates.dart';
import 'database.dart';
import 'models.dart';

const _uuid = Uuid();

String newUuid() => _uuid.v4();

/// Error codes mirroring the business rules of the original app.
enum RepositoryError {
  walletUsedInTransfer,
  categoryHasChildren,
  categoryInUse,
  categoryHierarchyNotSupported,
  categoryNotConsistent,
  categorySystemReadOnly,
  currencyInUse,
  invalidRecurrenceRule,
  transactionUsedInTransfer,
  sameWallet,
  notFound,
}

class RepositoryException implements Exception {
  RepositoryException(this.error, [this.message]);

  final RepositoryError error;
  final String? message;

  @override
  String toString() => 'RepositoryException($error${message == null ? '' : ': $message'})';
}

/// Filter used by transaction lists, search and statistics.
class TransactionFilter {
  const TransactionFilter({
    this.wallet,
    this.category,
    this.event,
    this.person,
    this.place,
    this.debt,
    this.start,
    this.end,
    this.includeFuture = true,
    this.onlyCounted = false,
    this.query,
    this.searchFields = SearchField.values,
    this.minMoney,
    this.maxMoney,
    this.direction,
    this.limit,
    this.allWallets = false,
  });

  /// Wallet UUID; null means "all wallets counted in the total".
  final String? wallet;

  /// With [wallet] null: include wallets not counted in the total, too.
  final bool allWallets;

  /// Category UUID; sub categories are included.
  final String? category;
  final String? event;
  final String? person;
  final String? place;
  final String? debt;

  /// Inclusive start / exclusive end.
  final DateTime? start;
  final DateTime? end;
  final bool includeFuture;

  /// Only confirmed transactions that are counted in the total.
  final bool onlyCounted;
  final String? query;
  final List<SearchField> searchFields;
  final int? minMoney;
  final int? maxMoney;
  final int? direction;
  final int? limit;
}

enum SearchField { description, category, date, money, note, event, place }

class WalletBalance {
  const WalletBalance(this.wallet, this.balance);

  final Wallet wallet;
  final int balance;
}

class DebtView {
  const DebtView(this.debt, this.paid, this.currency, this.walletName);

  final Debt debt;

  /// Amount already paid back / received.
  final int paid;
  final String currency;
  final String walletName;

  int get remaining => debt.money - paid;

  double get progress =>
      debt.money == 0 ? 1 : (paid / debt.money).clamp(0.0, 1.0);

  bool get isComplete => paid >= debt.money;
}

/// Input for creating or updating a transfer.
class TransferInput {
  TransferInput({
    this.uuid,
    required this.fromWallet,
    required this.toWallet,
    required this.fromMoney,
    required this.toMoney,
    this.taxMoney = 0,
    required this.date,
    this.description,
    this.note,
    this.place,
    this.event,
    this.recurrence,
    this.confirmed = true,
    this.countInTotal = true,
    this.people = const [],
    this.attachments = const [],
    this.tag,
  });

  final String? uuid;
  final String fromWallet;
  final String toWallet;
  final int fromMoney;
  final int toMoney;
  final int taxMoney;
  final DateTime date;
  final String? description;
  final String? note;
  final String? place;
  final String? event;
  final String? recurrence;
  final bool confirmed;
  final bool countInTotal;
  final List<String> people;
  final List<String> attachments;
  final String? tag;
}

/// All data access and business logic. Methods are synchronous because the
/// underlying sqlite3 binding is synchronous and the data set is small.
class Repository {
  Repository(this.db);

  final AppDatabase db;

  // ---------------------------------------------------------------- seeding

  bool get isEmpty =>
      (db.scalar<int>('SELECT COUNT(*) FROM wallets') ?? 0) == 0;

  /// Inserts currencies from the bundled `currencies.json` (format of the
  /// original app: `[{code, name, symbol, decimals?}]`) and the system
  /// categories. Safe to call repeatedly.
  void seed({
    required String currenciesJson,
    required Map<String, String> systemCategoryNames,
  }) {
    db.transaction(() {
      final list = jsonDecode(currenciesJson) as List;
      for (final item in list) {
        final m = item as Map<String, dynamic>;
        db.execute(
          'INSERT OR IGNORE INTO currencies (iso, name, symbol, decimals, '
          'favourite, last_edit) VALUES (?, ?, ?, ?, 0, ?)',
          [m['code'], m['name'], m['symbol'], m['decimals'] ?? 2, nowMillis()],
        );
      }
      seedSystemCategories(systemCategoryNames);
    });
  }

  void seedSystemCategories(Map<String, String> names) {
    for (final tag in SystemTag.all) {
      final name = names[tag] ?? SystemTag.defaultNames[tag]!;
      db.execute(
        'INSERT OR IGNORE INTO categories (uuid, name, icon, type, parent, '
        'tag, show_report, "index", last_edit) VALUES (?, ?, ?, ?, NULL, ?, '
        '1, 0, ?)',
        [
          SystemTag.uuidFor(tag),
          name,
          randomColorIcon(name).toJson(),
          CategoryType.system,
          tag,
          nowMillis(),
        ],
      );
    }
  }

  /// Default categories created after the first wallet (like the original
  /// tutorial). [names] maps `default::<key>` tags to localized names.
  void seedDefaultCategories(Map<String, String> incomes,
      Map<String, String> expenses) {
    db.transaction(() {
      var index = 0;
      void add(String tag, String name, int type) {
        db.insert('categories', {
          'uuid': newUuid(),
          'name': name,
          'icon': randomColorIcon(name).toJson(),
          'type': type,
          'parent': null,
          'tag': tag,
          'show_report': true,
          'index': index++,
          'last_edit': nowMillis(),
        });
      }

      incomes.forEach((tag, name) => add(tag, name, CategoryType.income));
      expenses.forEach((tag, name) => add(tag, name, CategoryType.expense));
    });
  }

  // ------------------------------------------------------------- currencies

  List<Currency> currencies() => db
      .select('SELECT * FROM currencies ORDER BY favourite DESC, iso')
      .map(Currency.fromRow)
      .toList();

  Map<String, Currency>? _currencyCache;
  int _currencyCacheRevision = -1;

  /// Cached lookup (currencies are needed for every formatted amount).
  Currency? currency(String iso) {
    if (db.inTransaction) {
      final row =
          db.selectFirst('SELECT * FROM currencies WHERE iso = ?', [iso]);
      return row == null ? null : Currency.fromRow(row);
    }
    if (_currencyCache == null || _currencyCacheRevision != db.revision) {
      _currencyCache = {for (final c in currencies()) c.iso: c};
      _currencyCacheRevision = db.revision;
    }
    return _currencyCache![iso];
  }

  void saveCurrency(Currency c) {
    db.insert('currencies', {...c.toRow(), 'last_edit': nowMillis()},
        upsert: true, conflictColumn: 'iso');
  }

  void deleteCurrency(String iso) {
    final used =
        db.scalar<int>('SELECT COUNT(*) FROM wallets WHERE currency = ?', [iso]);
    if ((used ?? 0) > 0) throw RepositoryException(RepositoryError.currencyInUse);
    db.delete('currencies', 'iso = ?', [iso]);
  }

  // ---------------------------------------------------------------- wallets

  List<Wallet> wallets({bool includeArchived = true}) => db
      .select('SELECT * FROM wallets '
          '${includeArchived ? '' : 'WHERE archived = 0 '}'
          'ORDER BY "index", name COLLATE NOCASE')
      .map(Wallet.fromRow)
      .toList();

  Wallet? wallet(String uuid) {
    final row = db.selectFirst('SELECT * FROM wallets WHERE uuid = ?', [uuid]);
    return row == null ? null : Wallet.fromRow(row);
  }

  void saveWallet(Wallet w) {
    db.insert('wallets', {...w.toRow(), 'last_edit': nowMillis()},
        upsert: true);
  }

  void deleteWallet(String uuid) {
    final inTransfer = db.scalar<int>(
      'SELECT COUNT(*) FROM transfers tr JOIN transactions t '
      'ON t.uuid = tr."from" OR t.uuid = tr."to" WHERE t.wallet = ?',
      [uuid],
    );
    if ((inTransfer ?? 0) > 0) {
      throw RepositoryException(RepositoryError.walletUsedInTransfer);
    }
    db.delete('wallets', 'uuid = ?', [uuid]);
  }

  void reorderWallets(List<String> uuids) {
    db.transaction(() {
      for (var i = 0; i < uuids.length; i++) {
        db.update('wallets', {'index': i, 'last_edit': nowMillis()},
            'uuid = ?', [uuids[i]]);
      }
    });
  }

  static const _countedCondition =
      't.confirmed = 1 AND t.count_in_total = 1 AND t.date <= ?';

  /// Start money + sum of confirmed, counted, non-future transactions.
  int walletBalance(String uuid, {DateTime? at}) {
    final w = wallet(uuid);
    if (w == null) return 0;
    final sum = db.scalar<int>(
      'SELECT COALESCE(SUM(CASE WHEN t.direction = 1 THEN t.money '
      'ELSE -t.money END), 0) FROM transactions t '
      'WHERE t.wallet = ? AND $_countedCondition',
      [uuid, toSqlDateTime(at ?? DateTime.now())],
    );
    return w.startMoney + (sum ?? 0);
  }

  List<WalletBalance> walletBalances({bool includeArchived = false}) => [
        for (final w in wallets(includeArchived: includeArchived))
          WalletBalance(w, walletBalance(w.uuid)),
      ];

  /// Total per currency over all wallets counted in the total. There is no
  /// currency conversion, like in the original app.
  Map<String, int> totalBalances() {
    final result = <String, int>{};
    for (final w in wallets()) {
      if (!w.countInTotal) continue;
      result[w.currency] = (result[w.currency] ?? 0) + walletBalance(w.uuid);
    }
    return result;
  }

  /// Currencies used by the wallets selected by [walletUuid] (null = total).
  List<String> currenciesFor(String? walletUuid) {
    if (walletUuid != null) {
      final w = wallet(walletUuid);
      return w == null ? const [] : [w.currency];
    }
    return wallets()
        .where((w) => w.countInTotal)
        .map((w) => w.currency)
        .toSet()
        .toList();
  }

  // ------------------------------------------------------------- categories

  List<Category> categories({int? type, bool includeHidden = false}) {
    final rows = db.select(
      'SELECT * FROM categories '
      '${type == null ? '' : 'WHERE type = $type '}'
      'ORDER BY "index", name COLLATE NOCASE',
    );
    return rows
        .map(Category.fromRow)
        .where((c) => includeHidden || !SystemTag.hidden.contains(c.tag))
        .toList();
  }

  Category? category(String uuid) {
    final row =
        db.selectFirst('SELECT * FROM categories WHERE uuid = ?', [uuid]);
    return row == null ? null : Category.fromRow(row);
  }

  Category systemCategory(String tag) {
    final row = db.selectFirst(
        'SELECT * FROM categories WHERE tag = ? AND type = ? LIMIT 1',
        [tag, CategoryType.system]);
    if (row != null) return Category.fromRow(row);
    // Missing system categories (e.g. after importing an incomplete backup)
    // are recreated on demand.
    seedSystemCategories({});
    return systemCategory(tag);
  }

  void saveCategory(Category c) {
    final existing = category(c.uuid);
    if (existing != null && existing.isSystem) {
      throw RepositoryException(RepositoryError.categorySystemReadOnly);
    }
    if (c.type == CategoryType.system) {
      throw RepositoryException(RepositoryError.categorySystemReadOnly);
    }
    if (c.parent != null) {
      final parent = category(c.parent!);
      if (parent == null) throw RepositoryException(RepositoryError.notFound);
      if (parent.parent != null || parent.uuid == c.uuid) {
        throw RepositoryException(
            RepositoryError.categoryHierarchyNotSupported);
      }
      final hasChildren = db.scalar<int>(
          'SELECT COUNT(*) FROM categories WHERE parent = ?', [c.uuid]);
      if ((hasChildren ?? 0) > 0) {
        throw RepositoryException(
            RepositoryError.categoryHierarchyNotSupported);
      }
      if (parent.type != c.type) {
        throw RepositoryException(RepositoryError.categoryNotConsistent);
      }
    }
    db.transaction(() {
      db.insert('categories', {...c.toRow(), 'last_edit': nowMillis()},
          upsert: true);
      // Keep children consistent when the type of a parent changes.
      if (existing != null && existing.type != c.type) {
        db.update('categories', {'type': c.type, 'last_edit': nowMillis()},
            'parent = ?', [c.uuid]);
      }
    });
  }

  void deleteCategory(String uuid) {
    final c = category(uuid);
    if (c == null) return;
    if (c.isSystem) {
      throw RepositoryException(RepositoryError.categorySystemReadOnly);
    }
    final children = db.scalar<int>(
        'SELECT COUNT(*) FROM categories WHERE parent = ?', [uuid]);
    if ((children ?? 0) > 0) {
      throw RepositoryException(RepositoryError.categoryHasChildren);
    }
    final used = db.scalar<int>(
      'SELECT (SELECT COUNT(*) FROM transactions WHERE category = ?1) + '
      '(SELECT COUNT(*) FROM transaction_models WHERE category = ?1) + '
      '(SELECT COUNT(*) FROM recurrent_transactions WHERE category = ?1)',
      [uuid],
    );
    if ((used ?? 0) > 0) throw RepositoryException(RepositoryError.categoryInUse);
    db.delete('categories', 'uuid = ?', [uuid]);
  }

  void reorderCategories(List<String> uuids) {
    db.transaction(() {
      for (var i = 0; i < uuids.length; i++) {
        db.update('categories', {'index': i, 'last_edit': nowMillis()},
            'uuid = ?', [uuids[i]]);
      }
    });
  }

  // --------------------------------------------------- events/places/people

  List<Event> events() => db
      .select('SELECT * FROM events ORDER BY start_date DESC')
      .map(Event.fromRow)
      .toList();

  Event? event(String uuid) {
    final row = db.selectFirst('SELECT * FROM events WHERE uuid = ?', [uuid]);
    return row == null ? null : Event.fromRow(row);
  }

  void saveEvent(Event e) => db.insert(
      'events', {...e.toRow(), 'last_edit': nowMillis()},
      upsert: true);

  void deleteEvent(String uuid) => db.delete('events', 'uuid = ?', [uuid]);

  List<Place> places() => db
      .select('SELECT * FROM places ORDER BY name COLLATE NOCASE')
      .map(Place.fromRow)
      .toList();

  Place? place(String uuid) {
    final row = db.selectFirst('SELECT * FROM places WHERE uuid = ?', [uuid]);
    return row == null ? null : Place.fromRow(row);
  }

  void savePlace(Place p) => db.insert(
      'places', {...p.toRow(), 'last_edit': nowMillis()},
      upsert: true);

  void deletePlace(String uuid) => db.delete('places', 'uuid = ?', [uuid]);

  List<Person> people() => db
      .select('SELECT * FROM people ORDER BY name COLLATE NOCASE')
      .map(Person.fromRow)
      .toList();

  Person? person(String uuid) {
    final row = db.selectFirst('SELECT * FROM people WHERE uuid = ?', [uuid]);
    return row == null ? null : Person.fromRow(row);
  }

  void savePerson(Person p) => db.insert(
      'people', {...p.toRow(), 'last_edit': nowMillis()},
      upsert: true);

  void deletePerson(String uuid) => db.delete('people', 'uuid = ?', [uuid]);

  // ------------------------------------------------------------- link tables

  List<String> _links(String table, String column, String uuid, String other) =>
      db
          .select('SELECT ${quoteIdent(other)} AS v FROM $table '
              'WHERE ${quoteIdent(column)} = ?', [uuid])
          .map((r) => r['v'] as String)
          .toList();

  void _setLinks(String table, String column, String uuid, String other,
      List<String> values) {
    db.delete(table, '${quoteIdent(column)} = ?', [uuid]);
    for (final v in values.toSet()) {
      db.insert(table, {
        'uuid': newUuid(),
        column: uuid,
        other: v,
        'last_edit': nowMillis(),
      });
    }
  }

  List<String> transactionPeople(String uuid) =>
      _links('transaction_people', 'transaction', uuid, 'person');

  List<String> transferPeople(String uuid) =>
      _links('transfer_people', 'transfer', uuid, 'person');

  List<String> debtPeople(String uuid) =>
      _links('debt_people', 'debt', uuid, 'person');

  List<String> eventPeople(String uuid) =>
      _links('event_people', 'event', uuid, 'person');

  void setEventPeople(String uuid, List<String> people) =>
      db.transaction(() =>
          _setLinks('event_people', 'event', uuid, 'person', people));

  // ------------------------------------------------------------- attachments

  List<Attachment> transactionAttachments(String uuid) => db
      .select(
          'SELECT a.* FROM attachments a JOIN transaction_attachment l '
          'ON l.attachment = a.uuid WHERE l."transaction" = ?',
          [uuid])
      .map(Attachment.fromRow)
      .toList();

  List<Attachment> transferAttachments(String uuid) => db
      .select(
          'SELECT a.* FROM attachments a JOIN transfer_attachment l '
          'ON l.attachment = a.uuid WHERE l.transfer = ?',
          [uuid])
      .map(Attachment.fromRow)
      .toList();

  List<Attachment> allAttachments() =>
      db.select('SELECT * FROM attachments').map(Attachment.fromRow).toList();

  void saveAttachment(Attachment a) => db.insert(
      'attachments', {...a.toRow(), 'last_edit': nowMillis()},
      upsert: true);

  /// Attachments no longer referenced by any transaction or transfer.
  List<Attachment> orphanAttachments() => db
      .select('SELECT * FROM attachments a WHERE '
          'NOT EXISTS (SELECT 1 FROM transaction_attachment l '
          'WHERE l.attachment = a.uuid) AND '
          'NOT EXISTS (SELECT 1 FROM transfer_attachment l '
          'WHERE l.attachment = a.uuid)')
      .map(Attachment.fromRow)
      .toList();

  void deleteAttachment(String uuid) =>
      db.delete('attachments', 'uuid = ?', [uuid]);

  // ------------------------------------------------------------ transactions

  static const _transactionSelect = '''
SELECT t.*, c.name AS c_name, c.icon AS c_icon, c.tag AS c_tag, c.type AS c_type,
  c.parent AS c_parent, w.name AS w_name, w.currency AS w_currency,
  e.name AS e_name, p.name AS p_name,
  (SELECT tr.uuid FROM transfers tr WHERE tr."from" = t.uuid
     OR tr."to" = t.uuid OR tr.tax = t.uuid LIMIT 1) AS transfer_uuid
FROM transactions t
JOIN categories c ON c.uuid = t.category
JOIN wallets w ON w.uuid = t.wallet
LEFT JOIN events e ON e.uuid = t.event
LEFT JOIN places p ON p.uuid = t.place
''';

  static TransactionView _view(Map<String, Object?> r) => TransactionView(
        transaction: Transaction.fromRow(r),
        categoryName: r['c_name'] as String,
        categoryIcon: AppIcon.parse(r['c_icon'] as String?),
        categoryTag: r['c_tag'] as String?,
        categoryType: (r['c_type'] as num).toInt(),
        categoryParent: r['c_parent'] as String?,
        walletName: r['w_name'] as String,
        currency: r['w_currency'] as String,
        transfer: r['transfer_uuid'] as String?,
        eventName: r['e_name'] as String?,
        placeName: r['p_name'] as String?,
      );

  List<TransactionView> transactions(TransactionFilter f) {
    final where = <String>[];
    final args = <Object?>[];
    if (f.wallet != null) {
      where.add('t.wallet = ?');
      args.add(f.wallet);
    } else if (!f.allWallets) {
      where.add('w.count_in_total = 1');
    }
    if (f.category != null) {
      where.add('(t.category = ? OR c.parent = ?)');
      args..add(f.category)..add(f.category);
    }
    if (f.event != null) {
      where.add('t.event = ?');
      args.add(f.event);
    }
    if (f.place != null) {
      where.add('t.place = ?');
      args.add(f.place);
    }
    if (f.debt != null) {
      where.add('t.debt = ?');
      args.add(f.debt);
    }
    if (f.person != null) {
      where.add('(EXISTS (SELECT 1 FROM transaction_people tp '
          'WHERE tp."transaction" = t.uuid AND tp.person = ?) OR '
          'EXISTS (SELECT 1 FROM transfer_people fp JOIN transfers tr '
          'ON tr.uuid = fp.transfer WHERE fp.person = ? AND '
          '(tr."from" = t.uuid OR tr."to" = t.uuid OR tr.tax = t.uuid)))');
      args..add(f.person)..add(f.person);
    }
    if (f.start != null) {
      where.add('t.date >= ?');
      args.add(toSqlDateTime(f.start!));
    }
    if (f.end != null) {
      where.add('t.date < ?');
      args.add(toSqlDateTime(f.end!));
    }
    if (!f.includeFuture) {
      where.add('t.date <= ?');
      args.add(toSqlDateTime(DateTime.now()));
    }
    if (f.onlyCounted) {
      where.add('t.confirmed = 1 AND t.count_in_total = 1');
    }
    if (f.direction != null) {
      where.add('t.direction = ?');
      args.add(f.direction);
    }
    if (f.minMoney != null) {
      where.add('t.money >= ?');
      args.add(f.minMoney);
    }
    if (f.maxMoney != null) {
      where.add('t.money <= ?');
      args.add(f.maxMoney);
    }
    final q = f.query?.trim();
    if (q != null && q.isNotEmpty && f.searchFields.isNotEmpty) {
      final like = '%${q.replaceAll('\\', '\\\\').replaceAll('%', '\\%').replaceAll('_', '\\_')}%';
      final parts = <String>[];
      for (final field in f.searchFields) {
        final column = switch (field) {
          SearchField.description => 't.description',
          SearchField.category => 'c.name',
          SearchField.date => 't.date',
          SearchField.money => 'CAST(t.money AS TEXT)',
          SearchField.note => 't.note',
          SearchField.event => 'e.name',
          SearchField.place => 'p.name',
        };
        parts.add("$column LIKE ? ESCAPE '\\'");
        args.add(like);
      }
      where.add('(${parts.join(' OR ')})');
    }
    final sql = StringBuffer(_transactionSelect);
    if (where.isNotEmpty) sql.write('WHERE ${where.join(' AND ')} ');
    sql.write('ORDER BY t.date DESC, t.rowid DESC');
    if (f.limit != null) sql.write(' LIMIT ${f.limit}');
    return db.select(sql.toString(), args).map(_view).toList();
  }

  TransactionView? transactionView(String uuid) {
    final row = db.selectFirst('${_transactionSelect}WHERE t.uuid = ?', [uuid]);
    return row == null ? null : _view(row);
  }

  Transaction? transaction(String uuid) {
    final row =
        db.selectFirst('SELECT * FROM transactions WHERE uuid = ?', [uuid]);
    return row == null ? null : Transaction.fromRow(row);
  }

  String? transferOf(String transactionUuid) => db.scalar<String>(
      'SELECT uuid FROM transfers WHERE "from" = ?1 OR "to" = ?1 OR tax = ?1',
      [transactionUuid]);

  /// Inserts or updates a standard (or debt) transaction including people
  /// and attachment links.
  void saveTransaction(
    Transaction t, {
    List<String> people = const [],
    List<String> attachments = const [],
  }) {
    if (transferOf(t.uuid) != null) {
      throw RepositoryException(RepositoryError.transactionUsedInTransfer);
    }
    db.transaction(() {
      db.insert('transactions', {...t.toRow(), 'last_edit': nowMillis()},
          upsert: true);
      _setLinks('transaction_people', 'transaction', t.uuid, 'person', people);
      _setLinks('transaction_attachment', 'transaction', t.uuid, 'attachment',
          attachments);
    });
  }

  void deleteTransaction(String uuid) {
    final transfer = transferOf(uuid);
    db.transaction(() {
      if (transfer != null) {
        deleteTransfer(transfer);
      } else {
        db.delete('transactions', 'uuid = ?', [uuid]);
      }
    });
  }

  // --------------------------------------------------------------- transfers

  Transfer? transfer(String uuid) {
    final row = db.selectFirst('SELECT * FROM transfers WHERE uuid = ?', [uuid]);
    return row == null ? null : Transfer.fromRow(row);
  }

  static const _transferSelect = '''
SELECT tr.*, f.wallet AS f_wallet, f.money AS f_money,
  t.wallet AS t_wallet, t.money AS t_money, COALESCE(x.money, 0) AS x_money,
  fw.currency AS f_currency, tw.currency AS t_currency,
  fw.name AS f_name, tw.name AS t_name
FROM transfers tr
JOIN transactions f ON f.uuid = tr."from"
JOIN transactions t ON t.uuid = tr."to"
LEFT JOIN transactions x ON x.uuid = tr.tax
JOIN wallets fw ON fw.uuid = f.wallet
JOIN wallets tw ON tw.uuid = t.wallet
''';

  static TransferView _transferView(Map<String, Object?> r) => TransferView(
        transfer: Transfer.fromRow(r),
        fromWallet: r['f_wallet'] as String,
        toWallet: r['t_wallet'] as String,
        fromMoney: (r['f_money'] as num).toInt(),
        toMoney: (r['t_money'] as num).toInt(),
        taxMoney: (r['x_money'] as num).toInt(),
        fromCurrency: r['f_currency'] as String,
        toCurrency: r['t_currency'] as String,
        fromWalletName: r['f_name'] as String,
        toWalletName: r['t_name'] as String,
      );

  TransferView? transferView(String uuid) {
    final row = db.selectFirst('${_transferSelect}WHERE tr.uuid = ?', [uuid]);
    return row == null ? null : _transferView(row);
  }

  List<TransferView> transfers({String? wallet, int? limit}) {
    final where = wallet == null
        ? 'WHERE fw.count_in_total = 1 OR tw.count_in_total = 1'
        : 'WHERE f.wallet = ?1 OR t.wallet = ?1';
    return db
        .select(
          '$_transferSelect$where ORDER BY tr.date DESC'
          '${limit == null ? '' : ' LIMIT $limit'}',
          wallet == null ? const [] : [wallet],
        )
        .map(_transferView)
        .toList();
  }

  /// Creates or updates a transfer. Like the original app, a transfer is
  /// represented by two (or three, with a fee) real transactions using the
  /// system categories "Transfer" and "Transfer tax".
  String saveTransfer(TransferInput input, {String? uuidOverride}) {
    if (input.fromWallet == input.toWallet) {
      throw RepositoryException(RepositoryError.sameWallet);
    }
    return db.transaction(() {
      final existing = input.uuid == null ? null : transfer(input.uuid!);
      final uuid = existing?.uuid ?? uuidOverride ?? newUuid();
      final transferCategory = systemCategory(SystemTag.transfer).uuid;
      final taxCategory = systemCategory(SystemTag.transferTax).uuid;
      Transaction tx(String id, String wallet, int money, int direction,
              String category) =>
          Transaction(
            uuid: id,
            money: money,
            date: input.date,
            description: input.description,
            category: category,
            direction: direction,
            type: TransactionType.transfer,
            wallet: wallet,
            place: input.place,
            note: input.note,
            event: input.event,
            confirmed: input.confirmed,
            countInTotal: input.countInTotal,
          );
      final fromId = existing?.from ?? newUuid();
      final toId = existing?.to ?? newUuid();
      db.insert(
          'transactions',
          {
            ...tx(fromId, input.fromWallet, input.fromMoney, Direction.expense,
                    transferCategory)
                .toRow(),
            'last_edit': nowMillis(),
          },
          upsert: true);
      db.insert(
          'transactions',
          {
            ...tx(toId, input.toWallet, input.toMoney, Direction.income,
                    transferCategory)
                .toRow(),
            'last_edit': nowMillis(),
          },
          upsert: true);
      String? taxId = existing?.tax;
      if (input.taxMoney > 0) {
        taxId ??= newUuid();
        db.insert(
            'transactions',
            {
              ...tx(taxId, input.fromWallet, input.taxMoney, Direction.expense,
                      taxCategory)
                  .toRow(),
              'last_edit': nowMillis(),
            },
            upsert: true);
      }
      db.insert(
          'transfers',
          {
            'uuid': uuid,
            'description': input.description,
            'date': toSqlDateTime(input.date),
            'from': fromId,
            'to': toId,
            'tax': input.taxMoney > 0 ? taxId : null,
            'note': input.note,
            'place': input.place,
            'event': input.event,
            'recurrence': input.recurrence ?? existing?.recurrence,
            'confirmed': input.confirmed,
            'count_in_total': input.countInTotal,
            'tag': input.tag ?? existing?.tag,
            'last_edit': nowMillis(),
          },
          upsert: true);
      if (input.taxMoney <= 0 && existing?.tax != null) {
        db.delete('transactions', 'uuid = ?', [existing!.tax]);
      }
      _setLinks('transfer_people', 'transfer', uuid, 'person', input.people);
      _setLinks('transfer_attachment', 'transfer', uuid, 'attachment',
          input.attachments);
      return uuid;
    });
  }

  void deleteTransfer(String uuid) {
    final t = transfer(uuid);
    if (t == null) return;
    db.transaction(() {
      db.delete('transfers', 'uuid = ?', [uuid]);
      db.delete('transactions', 'uuid IN (?, ?, ?)', [t.from, t.to, t.tax]);
    });
  }

  // ------------------------------------------------------------------- debts

  static const _debtSelect = '''
SELECT d.*, w.currency AS w_currency, w.name AS w_name,
  COALESCE((SELECT SUM(CASE WHEN t.direction = 1 THEN t.money ELSE -t.money END)
    FROM transactions t JOIN categories c ON c.uuid = t.category
    WHERE t.debt = d.uuid AND t.confirmed = 1 AND t.date <= ?
      AND c.tag IN ('system::paid_debt', 'system::paid_credit')), 0) AS paid
FROM debts d JOIN wallets w ON w.uuid = d.wallet
''';

  static DebtView _debtView(Map<String, Object?> r) => DebtView(
        Debt.fromRow(r),
        ((r['paid'] as num).toInt()).abs(),
        r['w_currency'] as String,
        r['w_name'] as String,
      );

  List<DebtView> debts({int? type, String? wallet}) {
    final where = <String>[];
    final args = <Object?>[toSqlDateTime(DateTime.now())];
    if (type != null) {
      where.add('d.type = ?');
      args.add(type);
    }
    if (wallet != null) {
      where.add('d.wallet = ?');
      args.add(wallet);
    }
    return db
        .select(
          '$_debtSelect${where.isEmpty ? '' : 'WHERE ${where.join(' AND ')} '}'
          'ORDER BY d.archived, d.date DESC',
          args,
        )
        .map(_debtView)
        .toList();
  }

  DebtView? debtView(String uuid) {
    final row = db.selectFirst('${_debtSelect}WHERE d.uuid = ?',
        [toSqlDateTime(DateTime.now()), uuid]);
    return row == null ? null : _debtView(row);
  }

  /// Saves a debt. When [createMasterTransaction] is set on creation, the
  /// initial money flow is recorded like in the original (a debt is money
  /// received = income, a credit is money lent = expense).
  void saveDebt(Debt d,
      {List<String> people = const [], bool createMasterTransaction = false}) {
    db.transaction(() {
      final isNew = debtView(d.uuid) == null;
      db.insert('debts', {...d.toRow(), 'last_edit': nowMillis()},
          upsert: true);
      _setLinks('debt_people', 'debt', d.uuid, 'person', people);
      if (isNew && createMasterTransaction) {
        final isDebt = d.type == DebtType.debt;
        final tx = Transaction(
          uuid: newUuid(),
          money: d.money,
          date: DateTime(d.date.year, d.date.month, d.date.day),
          description: d.description,
          category:
              systemCategory(isDebt ? SystemTag.debt : SystemTag.credit).uuid,
          direction: isDebt ? Direction.income : Direction.expense,
          type: TransactionType.debt,
          wallet: d.wallet,
          place: d.place,
          note: d.note,
          debt: d.uuid,
        );
        db.insert('transactions', {...tx.toRow(), 'last_edit': nowMillis()});
        _setLinks('transaction_people', 'transaction', tx.uuid, 'person',
            people);
      }
    });
  }

  /// Category to use when paying back a debt / receiving a credit.
  Category debtPaymentCategory(int debtType) => systemCategory(
      debtType == DebtType.debt ? SystemTag.paidDebt : SystemTag.paidCredit);

  /// Direction of a payment for the given debt type.
  int debtPaymentDirection(int debtType) =>
      debtType == DebtType.debt ? Direction.expense : Direction.income;

  void setDebtArchived(String uuid, bool archived) => db.update(
      'debts', {'archived': archived, 'last_edit': nowMillis()}, 'uuid = ?',
      [uuid]);

  void deleteDebt(String uuid) {
    db.transaction(() {
      db.delete('transactions', 'debt = ?', [uuid]);
      db.delete('debts', 'uuid = ?', [uuid]);
    });
  }

  // ------------------------------------------------------------------ models

  List<TransactionModel> transactionModels() => db
      .select('SELECT * FROM transaction_models ORDER BY description')
      .map(TransactionModel.fromRow)
      .toList();

  void saveTransactionModel(TransactionModel m) => db.insert(
      'transaction_models', {...m.toRow(), 'last_edit': nowMillis()},
      upsert: true);

  void deleteTransactionModel(String uuid) =>
      db.delete('transaction_models', 'uuid = ?', [uuid]);

  List<TransferModel> transferModels() => db
      .select('SELECT * FROM transfer_models ORDER BY description')
      .map(TransferModel.fromRow)
      .toList();

  void saveTransferModel(TransferModel m) => db.insert(
      'transfer_models', {...m.toRow(), 'last_edit': nowMillis()},
      upsert: true);

  void deleteTransferModel(String uuid) =>
      db.delete('transfer_models', 'uuid = ?', [uuid]);

  // ------------------------------------------------------------- recurrences

  List<RecurrentTransaction> recurrentTransactions() => db
      .select('SELECT * FROM recurrent_transactions '
          'ORDER BY next_occurrence IS NULL, next_occurrence')
      .map(RecurrentTransaction.fromRow)
      .toList();

  RecurrentTransaction? recurrentTransaction(String uuid) {
    final row = db.selectFirst(
        'SELECT * FROM recurrent_transactions WHERE uuid = ?', [uuid]);
    return row == null ? null : RecurrentTransaction.fromRow(row);
  }

  List<RecurrentTransfer> recurrentTransfers() => db
      .select('SELECT * FROM recurrent_transfers '
          'ORDER BY next_occurrence IS NULL, next_occurrence')
      .map(RecurrentTransfer.fromRow)
      .toList();

  RecurrentTransfer? recurrentTransfer(String uuid) {
    final row = db.selectFirst(
        'SELECT * FROM recurrent_transfers WHERE uuid = ?', [uuid]);
    return row == null ? null : RecurrentTransfer.fromRow(row);
  }

  void deleteRecurrentTransaction(String uuid) =>
      db.delete('recurrent_transactions', 'uuid = ?', [uuid]);

  void deleteRecurrentTransfer(String uuid) =>
      db.delete('recurrent_transfers', 'uuid = ?', [uuid]);

  // ------------------------------------------------------------- pass-through

  /// Raw JSON objects of backup sections this app does not use.
  List<Map<String, dynamic>> passthrough(String section) => db
      .select('SELECT json FROM passthrough WHERE section = ? '
          'ORDER BY position', [section])
      .map((r) => jsonDecode(r['json'] as String) as Map<String, dynamic>)
      .toList();

  // ---------------------------------------------------------------- utilities

  /// Removes every user record (used before restoring a backup).
  void clearAll() {
    db.transaction(() {
      for (final table in const [
        'transfer_attachment', 'transaction_attachment', 'attachments',
        'transfer_people', 'transfer_models', 'transfers',
        'transaction_people', 'transaction_models', 'transactions',
        'recurrent_transfers', 'recurrent_transactions', 'debt_people',
        'debts', 'event_people', 'people', 'places', 'events',
        'passthrough',
      ]) {
        db.execute('DELETE FROM $table');
      }
      db.execute('UPDATE categories SET parent = NULL');
      db.execute('DELETE FROM categories');
      db.execute('DELETE FROM wallets');
    });
  }
}
