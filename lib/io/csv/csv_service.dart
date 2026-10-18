import '../../core/app_icon.dart';
import '../../core/dates.dart';
import '../../core/money.dart';
import '../../data/database.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import 'csv_codec.dart';

/// Column keys of the original MoneyWallet CSV format.
abstract final class CsvColumn {
  static const wallet = 'wallet';
  static const currency = 'currency';
  static const category = 'category';
  static const datetime = 'datetime';
  static const money = 'money';
  static const description = 'description';
  static const event = 'event';
  static const people = 'people';
  static const place = 'place';
  static const note = 'note';

  static const required = [wallet, currency, category, datetime, money];
  static const base = [...required, description];
  static const optional = [event, people, place, note];
}

class ExportOptions {
  const ExportOptions({
    required this.wallets,
    this.start,
    this.end,
    this.optionalColumns = const [],
  });

  /// Wallet UUIDs to export.
  final List<String> wallets;

  /// Inclusive date range (dates only). Future transactions are never
  /// exported, like in the original app.
  final DateTime? start;
  final DateTime? end;

  /// Subset of [CsvColumn.optional], in the original order.
  final List<String> optionalColumns;

  List<String> get columns => [
        ...CsvColumn.base,
        for (final c in CsvColumn.optional)
          if (optionalColumns.contains(c)) c,
      ];
}

/// A flat transaction row used by all export formats.
class ExportRow {
  const ExportRow({
    required this.walletUuid,
    required this.wallet,
    required this.currency,
    required this.decimals,
    required this.symbol,
    required this.category,
    required this.categoryTag,
    required this.date,
    required this.signedMoney,
    this.description,
    this.event,
    this.people = const [],
    this.place,
    this.note,
  });

  final String walletUuid;
  final String wallet;
  final String currency;
  final int decimals;
  final String symbol;
  final String category;
  final String? categoryTag;
  final DateTime date;
  final int signedMoney;
  final String? description;
  final String? event;
  final List<String> people;
  final String? place;
  final String? note;
}

class CsvImportException implements Exception {
  CsvImportException(this.message, {this.line});

  final String message;
  final int? line;

  @override
  String toString() =>
      'CsvImportException(${line == null ? '' : 'line $line: '}$message)';
}

class CsvService {
  CsvService(this.repo);

  final Repository repo;

  AppDatabase get _db => repo.db;

  /// Loads the rows to export, newest first.
  List<ExportRow> loadRows(ExportOptions options, {DateTime? now}) {
    if (options.wallets.isEmpty) return const [];
    final current = now ?? DateTime.now();
    var end = current;
    if (options.end != null) {
      final endOfDay = addDays(dateOnly(options.end!), 1)
          .subtract(const Duration(seconds: 1));
      if (endOfDay.isBefore(end)) end = endOfDay;
    }
    final args = <Object?>[toSqlDateTime(end), ...options.wallets];
    var startClause = '';
    if (options.start != null) {
      startClause = 'AND t.date >= ? ';
      args.add(toSqlDateTime(dateOnly(options.start!)));
    }
    final placeholders = List.filled(options.wallets.length, '?').join(',');
    final rows = _db.select(
      'SELECT t.uuid, t.money, t.direction, t.date, t.description, t.note, '
      't.wallet, w.name AS w_name, w.currency AS w_currency, '
      'cu.decimals AS cu_decimals, cu.symbol AS cu_symbol, '
      'c.name AS c_name, c.tag AS c_tag, e.name AS e_name, p.name AS p_name, '
      '(SELECT GROUP_CONCAT(pe.name, char(31)) FROM transaction_people tp '
      'JOIN people pe ON pe.uuid = tp.person '
      'WHERE tp."transaction" = t.uuid) AS people_names '
      'FROM transactions t JOIN wallets w ON w.uuid = t.wallet '
      'JOIN categories c ON c.uuid = t.category '
      'LEFT JOIN currencies cu ON cu.iso = w.currency '
      'LEFT JOIN events e ON e.uuid = t.event '
      'LEFT JOIN places p ON p.uuid = t.place '
      'WHERE t.date <= ? AND t.wallet IN ($placeholders) $startClause'
      'ORDER BY t.date DESC, t.rowid DESC',
      args,
    );
    return [
      for (final r in rows)
        ExportRow(
          walletUuid: r['wallet'] as String,
          wallet: r['w_name'] as String,
          currency: r['w_currency'] as String,
          decimals: (r['cu_decimals'] as int?) ?? 2,
          symbol: (r['cu_symbol'] as String?) ?? (r['w_currency'] as String),
          category: r['c_name'] as String,
          categoryTag: r['c_tag'] as String?,
          date: parseSqlDateTime(r['date'] as String),
          signedMoney: r['direction'] == Direction.income
              ? r['money'] as int
              : -(r['money'] as int),
          description: r['description'] as String?,
          event: r['e_name'] as String?,
          people: (r['people_names'] as String?)
                  ?.split('\u001f')
                  .where((s) => s.isNotEmpty)
                  .toList() ??
              const [],
          place: r['p_name'] as String?,
          note: r['note'] as String?,
        ),
    ];
  }

  /// Exports in the original CSV layout:
  /// `wallet,currency,category,datetime,money,description[,event,people,place,note]`.
  String exportCsv(ExportOptions options, {DateTime? now}) {
    final columns = options.columns;
    final rows = <List<String?>>[columns];
    for (final row in loadRows(options, now: now)) {
      rows.add([
        for (final c in columns)
          switch (c) {
            CsvColumn.wallet => row.wallet,
            CsvColumn.currency => row.currency,
            CsvColumn.category => row.category,
            CsvColumn.datetime => toSqlDateTime(row.date),
            CsvColumn.money => minorToPlainString(row.signedMoney, row.decimals),
            CsvColumn.description => row.description,
            CsvColumn.event => row.event,
            CsvColumn.people => row.people.isEmpty ? null : row.people.join(','),
            CsvColumn.place => row.place,
            CsvColumn.note => row.note,
            _ => null,
          },
      ]);
    }
    return encodeCsv(rows);
  }

  /// Imports a CSV file in the original format. Missing wallets, categories,
  /// places and people are created; events are only linked when they exist.
  /// The import is atomic. Returns the number of imported transactions.
  int importCsv(String content) {
    final rows = decodeCsv(content);
    if (rows.isEmpty) return 0;
    final header = rows.first.map((h) => h.trim().toLowerCase()).toList();
    for (final column in CsvColumn.required) {
      if (!header.contains(column)) {
        throw CsvImportException('Missing required column "$column"');
      }
    }
    String? value(List<String> row, String column) {
      final i = header.indexOf(column);
      if (i < 0 || i >= row.length) return null;
      final v = row[i].trim();
      return v.isEmpty ? null : v;
    }

    return _db.transaction(() {
      final walletCache = <String, String>{};
      final categoryCache = <String, String>{};
      var count = 0;
      for (var line = 1; line < rows.length; line++) {
        final row = rows[line];
        if (row.every((f) => f.trim().isEmpty)) continue;
        final wallet = value(row, CsvColumn.wallet);
        final currencyIso = value(row, CsvColumn.currency);
        final category = value(row, CsvColumn.category);
        final datetime = value(row, CsvColumn.datetime);
        final moneyString = value(row, CsvColumn.money);
        if (wallet == null ||
            currencyIso == null ||
            category == null ||
            datetime == null ||
            moneyString == null) {
          throw CsvImportException('One or more required values are missing',
              line: line + 1);
        }
        final currency = repo.currency(currencyIso.toUpperCase());
        if (currency == null) {
          throw CsvImportException('Unknown currency ($currencyIso)',
              line: line + 1);
        }
        final money = parseMoney(moneyString, currency.decimals);
        if (money == null) {
          throw CsvImportException('Invalid money amount ($moneyString)',
              line: line + 1);
        }
        final DateTime date;
        try {
          date = parseSqlDateTime(datetime);
        } on FormatException {
          throw CsvImportException('Invalid date ($datetime)', line: line + 1);
        }
        final direction = money < 0 ? Direction.expense : Direction.income;
        final walletId = walletCache.putIfAbsent('$wallet\u0000${currency.iso}',
            () => _getOrCreateWallet(wallet, currency.iso));
        final categoryId = categoryCache.putIfAbsent(
            '$category\u0000$direction',
            () => _getOrCreateCategory(category, direction));
        final people = (value(row, CsvColumn.people) ?? '')
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .map(_getOrCreatePerson)
            .toList();
        final transaction = Transaction(
          uuid: newUuid(),
          money: money.abs(),
          date: date,
          description: value(row, CsvColumn.description),
          category: categoryId,
          direction: direction,
          wallet: walletId,
          note: value(row, CsvColumn.note),
          event: _findByName('events', value(row, CsvColumn.event)),
          place: _getOrCreatePlace(value(row, CsvColumn.place)),
        );
        repo.saveTransaction(transaction, people: people);
        count++;
      }
      return count;
    });
  }

  String? _findByName(String table, String? name) {
    if (name == null) return null;
    return _db.scalar<String>(
        'SELECT uuid FROM $table WHERE name = ? ORDER BY rowid DESC LIMIT 1',
        [name]);
  }

  String _getOrCreateWallet(String name, String currency) {
    final existing = _db.scalar<String>(
        'SELECT uuid FROM wallets WHERE name = ? AND currency = ? '
        'ORDER BY rowid DESC LIMIT 1',
        [name, currency]);
    if (existing != null) return existing;
    final wallet = Wallet(
      uuid: newUuid(),
      name: name,
      icon: randomColorIcon(name),
      currency: currency,
      index: repo.wallets().length,
    );
    repo.saveWallet(wallet);
    return wallet.uuid;
  }

  String _getOrCreateCategory(String name, int direction) {
    final type = direction == Direction.income
        ? CategoryType.income
        : CategoryType.expense;
    final existing = _db.scalar<String>(
        'SELECT uuid FROM categories WHERE name = ? AND (type = ? OR type = ?) '
        'ORDER BY rowid DESC LIMIT 1',
        [name, type, CategoryType.system]);
    if (existing != null) return existing;
    final category = Category(
      uuid: newUuid(),
      name: name,
      icon: randomColorIcon(name),
      type: type,
    );
    repo.saveCategory(category);
    return category.uuid;
  }

  String? _getOrCreatePlace(String? name) {
    if (name == null) return null;
    final existing = _findByName('places', name);
    if (existing != null) return existing;
    final place = Place(uuid: newUuid(), name: name, icon: randomColorIcon(name));
    repo.savePlace(place);
    return place.uuid;
  }

  String _getOrCreatePerson(String name) {
    final existing = _findByName('people', name);
    if (existing != null) return existing;
    final person =
        Person(uuid: newUuid(), name: name, icon: randomColorIcon(name));
    repo.savePerson(person);
    return person.uuid;
  }
}
