import 'dart:convert';

import 'package:sqlite3/sqlite3.dart' show SqliteException;

import '../../data/database.dart';
import '../../data/repository.dart';
import 'backup_format.dart';

class BackupFormatException implements Exception {
  BackupFormatException(this.message);

  final String message;

  @override
  String toString() => 'BackupFormatException: $message';
}

class BackupImportResult {
  BackupImportResult(this.version, this.imported, this.skipped);

  final int version;

  /// Number of imported records per section.
  final Map<String, int> imported;

  /// Records that could not be imported (missing required references).
  final int skipped;

  int count(String section) => imported[section] ?? 0;
}

/// Foreign keys per table: JSON key -> (target table, required).
const Map<String, Map<String, (String, bool)>> _foreignKeys = {
  'categories': {'parent': ('categories', false)},
  'event_people': {'event': ('events', true), 'person': ('people', true)},
  'debts': {'wallet': ('wallets', true), 'place': ('places', false)},
  'debt_people': {'debt': ('debts', true), 'person': ('people', true)},
  'recurrent_transactions': {
    'category': ('categories', true),
    'wallet': ('wallets', true),
    'place': ('places', false),
    'event': ('events', false),
  },
  'recurrent_transfers': {
    'from_wallet': ('wallets', true),
    'to_wallet': ('wallets', true),
    'place': ('places', false),
    'event': ('events', false),
  },
  'transactions': {
    'category': ('categories', true),
    'wallet': ('wallets', true),
    'place': ('places', false),
    'debt': ('debts', false),
    'event': ('events', false),
    'recurrence': ('recurrent_transactions', false),
  },
  'transaction_people': {
    'transaction': ('transactions', true),
    'person': ('people', true),
  },
  'transaction_models': {
    'category': ('categories', true),
    'wallet': ('wallets', true),
    'place': ('places', false),
    'event': ('events', false),
  },
  'transfers': {
    'from': ('transactions', true),
    'to': ('transactions', true),
    'tax': ('transactions', false),
    'place': ('places', false),
    'event': ('events', false),
    'recurrence': ('recurrent_transfers', false),
  },
  'transfer_people': {
    'transfer': ('transfers', true),
    'person': ('people', true),
  },
  'transfer_models': {
    'from_wallet': ('wallets', true),
    'to_wallet': ('wallets', true),
    'place': ('places', false),
    'event': ('events', false),
  },
  'transaction_attachment': {
    'transaction': ('transactions', true),
    'attachment': ('attachments', true),
  },
  'transfer_attachment': {
    'transfer': ('transfers', true),
    'attachment': ('attachments', true),
  },
};

/// Serializes the database to the original MoneyWallet `database.json`.
class BackupJsonWriter {
  BackupJsonWriter(this.repo);

  final Repository repo;

  AppDatabase get _db => repo.db;

  String write() {
    final out = StringBuffer('{"header":${jsonEncode({'version_code': backupVersion})}');
    final existing = <String, Set<String>>{};
    Set<String> ids(String table) => existing.putIfAbsent(
        table,
        () => _db
            .select('SELECT uuid FROM $table')
            .map((r) => r['uuid'] as String)
            .toSet());

    for (final section in backupSections) {
      out.write(',${jsonEncode(section.name)}:[');
      var first = true;
      void add(Map<String, Object?> object) {
        object.removeWhere((_, v) => v == null);
        if (!first) out.write(',');
        first = false;
        out.write(jsonEncode(object));
      }

      if (section.passthrough) {
        for (final object in repo.passthrough(section.name)) {
          final sanitized = _sanitizePassthrough(section.name, object, ids);
          if (sanitized != null) add(sanitized);
        }
      } else {
        final order = switch (section.table) {
          'currencies' => 'ORDER BY iso',
          'categories' => 'ORDER BY parent IS NOT NULL, rowid',
          _ => 'ORDER BY rowid',
        };
        for (final row in _db.select('SELECT * FROM ${section.table} $order')) {
          add(_rowToJson(section, row));
        }
      }
      out.write(']');
    }
    out.write('}');
    return out.toString();
  }

  static Map<String, Object?> _rowToJson(
      SectionSpec section, Map<String, Object?> row) {
    final object = <String, Object?>{};
    section.columns.forEach((key, kind) {
      final column = key == 'id' ? 'uuid' : key;
      final value = row[column];
      if (value == null) return;
      object[key] = switch (kind) {
        ColumnKind.boolean => value == 1 || value == true,
        ColumnKind.integer => (value as num).toInt(),
        ColumnKind.real => (value as num).toDouble(),
        ColumnKind.text => value.toString(),
      };
    });
    // The original only exports non deleted rows; the flag is always false.
    object['deleted'] = false;
    return object;
  }

  /// Drops references to records that no longer exist so the original app
  /// can import the pass-through sections without errors.
  static Map<String, Object?>? _sanitizePassthrough(String section,
      Map<String, dynamic> object, Set<String> Function(String) ids) {
    final copy = Map<String, Object?>.from(object);
    switch (section) {
      case 'budgets':
        final category = copy['category'];
        if (category is String && !ids('categories').contains(category)) {
          copy.remove('category');
        }
      case 'budget_wallets':
        final wallet = copy['wallet'];
        if (wallet is String && !ids('wallets').contains(wallet)) return null;
      case 'savings':
        final wallet = copy['wallet'];
        if (wallet is String && !ids('wallets').contains(wallet)) return null;
    }
    return copy;
  }
}

/// Restores a `database.json` produced by MoneyWallet (version 1 or 2) or by
/// this app. Existing data is replaced (like the original restore).
class BackupJsonReader {
  BackupJsonReader(this.repo);

  final Repository repo;

  AppDatabase get _db => repo.db;

  BackupImportResult read(String json,
      {Map<String, String> systemCategoryNames = const {}}) {
    final Object? decoded;
    try {
      decoded = jsonDecode(json);
    } on FormatException catch (e) {
      throw BackupFormatException('Invalid JSON: ${e.message}');
    }
    if (decoded is! Map<String, dynamic>) {
      throw BackupFormatException('Root is not an object');
    }
    final document = decoded;
    final header = document['header'];
    if (header is! Map) throw BackupFormatException('Missing header');
    final version = _toInt(header['version_code']);
    if (version == null ||
        version < minSupportedBackupVersion ||
        version > maxSupportedBackupVersion) {
      throw BackupFormatException('Unsupported backup version: $version');
    }

    final imported = <String, int>{};
    var skipped = 0;
    _db.transaction(() {
      repo.clearAll();
      repo.seedSystemCategories(systemCategoryNames);
      final known = <String, Set<String>>{
        'categories': _db
            .select('SELECT uuid FROM categories')
            .map((r) => r['uuid'] as String)
            .toSet(),
      };
      final currencies = _db
          .select('SELECT iso FROM currencies')
          .map((r) => r['iso'] as String)
          .toSet();
      final pendingParents = <String, String>{};

      for (final section in backupSections) {
        if (version < section.minVersion) continue;
        final raw = document[section.name];
        if (raw == null) continue;
        if (raw is! List) {
          throw BackupFormatException('Section ${section.name} is not an array');
        }
        var position = 0;
        var count = 0;
        for (final item in raw) {
          if (item is! Map<String, dynamic>) {
            skipped++;
            continue;
          }
          if (_toBool(item['deleted']) == true) continue;
          if (section.passthrough) {
            _db.insert('passthrough', {
              'section': section.name,
              'position': position++,
              'json': jsonEncode(item),
            });
            count++;
            continue;
          }
          final table = section.table!;
          final row = _jsonToRow(section, item);
          if (table == 'currencies') {
            final iso = row['iso'];
            if (iso is! String || iso.isEmpty || row['name'] == null) {
              skipped++;
              continue;
            }
            row.removeWhere((_, v) => v == null);
            _db.insert('currencies', row, upsert: true, conflictColumn: 'iso');
            currencies.add(iso);
            count++;
            continue;
          }
          if (table == 'wallets') {
            final iso = row['currency'];
            if (iso is String && !currencies.contains(iso)) {
              // Version 1 backups do not contain currencies.
              _db.insert('currencies',
                  {'iso': iso, 'name': iso, 'symbol': iso, 'decimals': 2});
              currencies.add(iso);
            }
          }
          var valid = true;
          final fks = _foreignKeys[table] ?? const {};
          for (final entry in fks.entries) {
            final value = row[entry.key];
            if (value == null) {
              if (entry.value.$2) valid = false;
              continue;
            }
            final targets = known[entry.value.$1] ?? const <String>{};
            if (table == 'categories' && entry.key == 'parent') {
              // Parents may appear later in the array; resolve afterwards.
              pendingParents[row['uuid'] as String] = value as String;
              row['parent'] = null;
              continue;
            }
            if (!targets.contains(value)) {
              if (entry.value.$2) {
                valid = false;
              } else {
                row[entry.key] = null;
              }
            }
          }
          if (!valid) {
            skipped++;
            continue;
          }
          // Let the column defaults apply for missing values.
          row.removeWhere((_, v) => v == null);
          try {
            _db.insert(table, row, upsert: true);
          } on SqliteException {
            skipped++;
            continue;
          }
          known.putIfAbsent(table, () => <String>{}).add(row['uuid'] as String);
          count++;
        }
        imported[section.name] = count;
      }
      final categoryIds = known['categories']!;
      pendingParents.forEach((child, parent) {
        if (categoryIds.contains(child) && categoryIds.contains(parent)) {
          _db.update('categories', {'parent': parent}, 'uuid = ?', [child]);
        }
      });
    });
    return BackupImportResult(version, imported, skipped);
  }

  static Map<String, Object?> _jsonToRow(
      SectionSpec section, Map<String, dynamic> item) {
    final row = <String, Object?>{};
    section.columns.forEach((key, kind) {
      final column = key == 'id' ? 'uuid' : key;
      var value = item.containsKey(key) ? item[key] : section.defaults[key];
      value ??= section.defaults[key];
      row[column] = switch (kind) {
        ColumnKind.text => value?.toString(),
        ColumnKind.integer => _toInt(value),
        ColumnKind.real => value is num ? value.toDouble() : null,
        ColumnKind.boolean => _toBool(value),
      };
    });
    if (section.table != 'currencies') {
      row['uuid'] ??= newUuid();
      row['last_edit'] ??= nowMillis();
    } else {
      row['last_edit'] ??= 0;
    }
    // The original stores both coordinates or none.
    if (row.containsKey('latitude') &&
        (row['latitude'] == null || row['longitude'] == null)) {
      row['latitude'] = null;
      row['longitude'] = null;
    }
    return row;
  }

  static int? _toInt(Object? v) => switch (v) {
        int() => v,
        num() => v.round(),
        String() => int.tryParse(v) ?? double.tryParse(v)?.round(),
        bool() => v ? 1 : 0,
        _ => null,
      };

  static bool? _toBool(Object? v) => switch (v) {
        bool() => v,
        num() => v != 0,
        String() => v.toLowerCase() == 'true' || v == '1',
        _ => null,
      };
}
