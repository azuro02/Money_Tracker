import '../core/dates.dart';
import '../data/database.dart';
import '../data/models.dart';
import '../data/repository.dart';
import 'rrule.dart';

/// Generates the occurrences of recurrent transactions and transfers.
///
/// Mirrors the original `RecurrenceHandlerIntentService`: every occurrence up
/// to today is materialised as a real transaction (or transfer) whose UUID is
/// `<recurrenceUUID>:<yyyy-MM-dd>`; `last_occurrence` / `next_occurrence` are
/// updated afterwards (`next_occurrence` = null once the rule is finished).
/// Because the iOS background scheduling is unreliable, this runs whenever
/// the app starts or resumes. It is idempotent thanks to the stable UUIDs.
class RecurrenceService {
  RecurrenceService(this.repo);

  final Repository repo;

  AppDatabase get _db => repo.db;

  static String occurrenceUuid(String recurrenceUuid, DateTime date) =>
      '$recurrenceUuid:${toSqlDate(date)}';

  /// Processes all due recurrences. Returns the number of created items.
  int processDue({DateTime? now}) {
    final today = dateOnly(now ?? DateTime.now());
    var created = 0;
    _db.transaction(() {
      for (final r in repo.recurrentTransactions()) {
        if (r.nextOccurrence == null || r.nextOccurrence!.isAfter(today)) {
          continue;
        }
        created += _processTransaction(r, today);
      }
      for (final r in repo.recurrentTransfers()) {
        if (r.nextOccurrence == null || r.nextOccurrence!.isAfter(today)) {
          continue;
        }
        created += _processTransfer(r, today);
      }
    });
    return created;
  }

  /// Saves a recurrent transaction (validating its rule) and immediately
  /// creates the occurrences that are already due.
  void saveRecurrentTransaction(RecurrentTransaction r, {DateTime? now}) {
    _validate(r.rule);
    final today = dateOnly(now ?? DateTime.now());
    _db.transaction(() {
      final existing = repo.recurrentTransaction(r.uuid);
      final row = {
        ...r.toRow(),
        'last_edit': nowMillis(),
      };
      if (existing == null ||
          existing.rule != r.rule ||
          existing.startDate != r.startDate) {
        // A new schedule starts from scratch.
        row['last_occurrence'] = toSqlDate(r.startDate);
        row['next_occurrence'] = toSqlDate(r.startDate);
      } else {
        row['last_occurrence'] = toSqlDate(existing.lastOccurrence);
        row['next_occurrence'] = existing.nextOccurrence == null
            ? null
            : toSqlDate(existing.nextOccurrence!);
      }
      _db.insert('recurrent_transactions', row, upsert: true);
      final saved = repo.recurrentTransaction(r.uuid)!;
      if (saved.nextOccurrence != null &&
          !saved.nextOccurrence!.isAfter(today)) {
        _processTransaction(saved, today);
      } else {
        _updateNext(
            'recurrent_transactions', saved.uuid, saved.rule, saved.startDate,
            saved.lastOccurrence, today, alreadyGenerated: false);
      }
    });
  }

  void saveRecurrentTransfer(RecurrentTransfer r, {DateTime? now}) {
    _validate(r.rule);
    final today = dateOnly(now ?? DateTime.now());
    _db.transaction(() {
      final existing = repo.recurrentTransfer(r.uuid);
      final row = {
        ...r.toRow(),
        'last_edit': nowMillis(),
      };
      if (existing == null ||
          existing.rule != r.rule ||
          existing.startDate != r.startDate) {
        row['last_occurrence'] = toSqlDate(r.startDate);
        row['next_occurrence'] = toSqlDate(r.startDate);
      } else {
        row['last_occurrence'] = toSqlDate(existing.lastOccurrence);
        row['next_occurrence'] = existing.nextOccurrence == null
            ? null
            : toSqlDate(existing.nextOccurrence!);
      }
      _db.insert('recurrent_transfers', row, upsert: true);
      final saved = repo.recurrentTransfer(r.uuid)!;
      if (saved.nextOccurrence != null &&
          !saved.nextOccurrence!.isAfter(today)) {
        _processTransfer(saved, today);
      } else {
        _updateNext('recurrent_transfers', saved.uuid, saved.rule,
            saved.startDate, saved.lastOccurrence, today,
            alreadyGenerated: false);
      }
    });
  }

  /// Upcoming occurrences (for previews in the UI).
  static List<DateTime> preview(String rule, DateTime start,
      {int max = 5, DateTime? from}) {
    final r = RRule.parse(rule);
    final f = from == null ? null : dateOnly(from);
    return r
        .instances(start)
        .where((d) => f == null || !d.isBefore(f))
        .take(max)
        .toList();
  }

  void _validate(String rule) {
    if (!RRule.isValid(rule)) {
      throw RepositoryException(RepositoryError.invalidRecurrenceRule, rule);
    }
  }

  /// Returns the dates in [nextOccurrence, today] and the first date after
  /// today (or null when the rule is exhausted). Iteration always starts at
  /// the real DTSTART so COUNT is honoured correctly.
  (List<DateTime>, DateTime?) _due(
      String rule, DateTime start, DateTime from, DateTime today) {
    final r = RRule.parse(rule);
    final due = <DateTime>[];
    for (final d in r.instances(start)) {
      if (d.isBefore(from)) continue;
      if (d.isAfter(today)) return (due, d);
      due.add(d);
    }
    return (due, null);
  }

  int _processTransaction(RecurrentTransaction r, DateTime today) {
    if (!RRule.isValid(r.rule)) return 0;
    final (due, next) = _due(r.rule, r.startDate, r.nextOccurrence!, today);
    var created = 0;
    for (final date in due) {
      final uuid = occurrenceUuid(r.uuid, date);
      if (repo.transaction(uuid) != null) continue;
      _db.insert('transactions', {
        ...Transaction(
          uuid: uuid,
          money: r.money,
          date: date,
          description: r.description,
          category: r.category,
          direction: r.direction,
          wallet: r.wallet,
          place: r.place,
          note: r.note,
          event: r.event,
          recurrence: r.uuid,
          confirmed: r.confirmed,
          countInTotal: r.countInTotal,
        ).toRow(),
        'last_edit': nowMillis(),
      });
      created++;
    }
    _db.update(
      'recurrent_transactions',
      {
        'last_occurrence':
            toSqlDate(due.isEmpty ? r.lastOccurrence : due.last),
        'next_occurrence': next == null ? null : toSqlDate(next),
        'last_edit': nowMillis(),
      },
      'uuid = ?',
      [r.uuid],
    );
    return created;
  }

  int _processTransfer(RecurrentTransfer r, DateTime today) {
    if (!RRule.isValid(r.rule)) return 0;
    final (due, next) = _due(r.rule, r.startDate, r.nextOccurrence!, today);
    var created = 0;
    for (final date in due) {
      final uuid = occurrenceUuid(r.uuid, date);
      if (repo.transfer(uuid) != null) continue;
      repo.saveTransfer(
        TransferInput(
          fromWallet: r.fromWallet,
          toWallet: r.toWallet,
          fromMoney: r.fromMoney,
          toMoney: r.toMoney,
          taxMoney: r.taxMoney,
          date: date,
          description: r.description,
          note: r.note,
          place: r.place,
          event: r.event,
          recurrence: r.uuid,
          confirmed: r.confirmed,
          countInTotal: r.countInTotal,
        ),
        uuidOverride: uuid,
      );
      created++;
    }
    _db.update(
      'recurrent_transfers',
      {
        'last_occurrence':
            toSqlDate(due.isEmpty ? r.lastOccurrence : due.last),
        'next_occurrence': next == null ? null : toSqlDate(next),
        'last_edit': nowMillis(),
      },
      'uuid = ?',
      [r.uuid],
    );
    return created;
  }

  void _updateNext(String table, String uuid, String rule, DateTime start,
      DateTime last, DateTime today,
      {required bool alreadyGenerated}) {
    final r = RRule.parse(rule);
    DateTime? next;
    for (final d in r.instances(start)) {
      if (d.isAfter(today)) {
        next = d;
        break;
      }
    }
    _db.update(
      table,
      {'next_occurrence': next == null ? null : toSqlDate(next)},
      'uuid = ?',
      [uuid],
    );
  }
}
