import 'package:flutter/foundation.dart';
import 'package:sqlite3/sqlite3.dart';

import 'schema.dart';

/// Thin wrapper around a synchronous sqlite3 database.
///
/// All data stays in a local file inside the app sandbox. Listeners are
/// notified after every committed write so the UI can refresh.
class AppDatabase extends ChangeNotifier {
  AppDatabase._(this.raw) {
    raw.execute('PRAGMA foreign_keys = ON');
    _migrate();
  }

  factory AppDatabase.open(String path) => AppDatabase._(sqlite3.open(path));

  factory AppDatabase.inMemory() => AppDatabase._(sqlite3.openInMemory());

  final Database raw;
  int _txDepth = 0;
  bool _dirty = false;

  /// Incremented on every committed change; handy for caching.
  int revision = 0;

  bool get inTransaction => _txDepth > 0;

  void _migrate() {
    final version = raw.userVersion;
    if (version == 0) {
      raw.execute('BEGIN');
      try {
        for (final stmt in schemaStatements) {
          raw.execute(stmt);
        }
        raw.userVersion = schemaVersion;
        raw.execute('COMMIT');
      } catch (_) {
        raw.execute('ROLLBACK');
        rethrow;
      }
    }
  }

  List<Map<String, Object?>> select(String sql, [List<Object?> args = const []]) {
    final result = raw.select(sql, args);
    return [for (final row in result) Map<String, Object?>.from(row)];
  }

  Map<String, Object?>? selectFirst(String sql, [List<Object?> args = const []]) {
    final rows = select(sql, args);
    return rows.isEmpty ? null : rows.first;
  }

  T? scalar<T>(String sql, [List<Object?> args = const []]) {
    final result = raw.select(sql, args);
    if (result.isEmpty) return null;
    return result.first.values.first as T?;
  }

  void execute(String sql, [List<Object?> args = const []]) {
    raw.execute(sql, args);
    _markDirty();
  }

  /// Inserts [values] into [table]. Column names are quoted so reserved
  /// words such as `from`, `to`, `index` and `transaction` work.
  void insert(String table, Map<String, Object?> values,
      {bool upsert = false, String conflictColumn = 'uuid'}) {
    final columns = values.keys.map(quoteIdent).join(', ');
    final placeholders = List.filled(values.length, '?').join(', ');
    var sql = 'INSERT INTO $table ($columns) VALUES ($placeholders)';
    if (upsert) {
      final updates = values.keys
          .where((k) => k != conflictColumn)
          .map((k) => '${quoteIdent(k)} = excluded.${quoteIdent(k)}')
          .join(', ');
      sql += updates.isEmpty
          ? ' ON CONFLICT(${quoteIdent(conflictColumn)}) DO NOTHING'
          : ' ON CONFLICT(${quoteIdent(conflictColumn)}) DO UPDATE SET $updates';
    }
    raw.execute(sql, values.values.map(_toSql).toList());
    _markDirty();
  }

  void update(String table, Map<String, Object?> values, String where,
      [List<Object?> args = const []]) {
    final sets = values.keys.map((k) => '${quoteIdent(k)} = ?').join(', ');
    raw.execute('UPDATE $table SET $sets WHERE $where',
        [...values.values.map(_toSql), ...args]);
    _markDirty();
  }

  void delete(String table, String where, [List<Object?> args = const []]) {
    raw.execute('DELETE FROM $table WHERE $where', args);
    _markDirty();
  }

  /// Runs [action] inside a transaction. Nested calls reuse the outer one.
  T transaction<T>(T Function() action) {
    if (_txDepth > 0) {
      _txDepth++;
      try {
        return action();
      } finally {
        _txDepth--;
      }
    }
    raw.execute('BEGIN');
    _txDepth = 1;
    try {
      final result = action();
      raw.execute('COMMIT');
      _txDepth = 0;
      _flush();
      return result;
    } catch (_) {
      _txDepth = 0;
      raw.execute('ROLLBACK');
      _dirty = false;
      rethrow;
    }
  }

  void _markDirty() {
    _dirty = true;
    if (_txDepth == 0) _flush();
  }

  void _flush() {
    if (!_dirty) return;
    _dirty = false;
    revision++;
    notifyListeners();
  }

  void close() => raw.close();

  static Object? _toSql(Object? v) => v is bool ? (v ? 1 : 0) : v;
}

String quoteIdent(String name) => '"${name.replaceAll('"', '""')}"';

int nowMillis() => DateTime.now().millisecondsSinceEpoch;
