import 'package:collection/collection.dart';

import '../core/dates.dart';
import '../data/models.dart';
import '../data/repository.dart';

/// A transaction reduced to what the statistics need.
class StatEntry {
  const StatEntry({
    required this.uuid,
    required this.date,
    required this.money,
    required this.direction,
    required this.category,
    required this.topCategory,
    required this.currency,
    this.description,
  });

  final String uuid;
  final DateTime date;

  /// Positive amount in minor units.
  final int money;
  final int direction;
  final String category;

  /// Parent category if the category is a sub category, else [category].
  final String topCategory;
  final String currency;
  final String? description;

  bool get isIncome => direction == Direction.income;
  bool get isExpense => direction == Direction.expense;
  int get signed => isIncome ? money : -money;
}

class PeriodSummary {
  const PeriodSummary({
    required this.period,
    required this.income,
    required this.expense,
    required this.elapsedDays,
  });

  final Period period;
  final int income;
  final int expense;

  /// Days of the period that already passed (including today).
  final int elapsedDays;

  int get net => income - expense;

  /// Share of the income that was not spent (null without income).
  double? get savingsRate => income <= 0 ? null : net / income;

  int get totalDays => period.lengthInDays;

  double get averageDailyExpense =>
      elapsedDays <= 0 ? 0 : expense / elapsedDays;

  /// Linear projection of the expenses to the end of the period.
  int get projectedExpense => elapsedDays >= totalDays
      ? expense
      : (averageDailyExpense * totalDays).round();
}

class CategoryAmount {
  const CategoryAmount({
    required this.category,
    required this.amount,
    required this.count,
    required this.share,
  });

  final String category;
  final int amount;
  final int count;

  /// 0..1 of the total.
  final double share;
}

class CategoryComparison {
  const CategoryComparison({
    required this.category,
    required this.current,
    required this.previous,
    required this.average,
  });

  final String category;
  final int current;
  final int previous;

  /// Average over the comparison periods before the current one.
  final double average;

  /// Relative change against the previous period (null if it was zero).
  double? get changeVsPrevious =>
      previous == 0 ? null : (current - previous) / previous;

  double? get changeVsAverage =>
      average == 0 ? null : (current - average) / average;
}

class FlowPoint {
  const FlowPoint(this.period, this.income, this.expense);

  final Period period;
  final int income;
  final int expense;

  int get net => income - expense;
}

/// Statistics over counted transactions (confirmed, counted in total, of
/// categories shown in reports and not in the future). Internal transfers
/// are excluded because they are neither income nor expense; transfer fees
/// are kept. All figures are per currency, without conversion.
class StatisticsService {
  StatisticsService(this.repo);

  final Repository repo;

  /// Loads the entries of [range] for the given wallet (null = total).
  List<StatEntry> load({
    String? wallet,
    required Period range,
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final end = range.end.isAfter(current) ? current : range.end;
    final categories = {for (final c in repo.categories(includeHidden: true)) c.uuid: c};
    final rows = repo.transactions(TransactionFilter(
      wallet: wallet,
      start: range.start,
      end: end.add(const Duration(seconds: 1)),
      onlyCounted: true,
    ));
    final result = <StatEntry>[];
    for (final v in rows) {
      final t = v.transaction;
      if (t.date.isAfter(current) || !range.contains(t.date)) continue;
      final category = categories[t.category];
      if (category == null || !category.showReport) continue;
      if (category.tag == SystemTag.transfer) continue;
      result.add(StatEntry(
        uuid: t.uuid,
        date: t.date,
        money: t.money,
        direction: t.direction,
        category: t.category,
        topCategory: category.parent ?? category.uuid,
        currency: v.currency,
        description: t.description,
      ));
    }
    return result;
  }

  // ------------------------------------------------------- pure functions

  static List<StatEntry> forCurrency(List<StatEntry> entries, String currency) =>
      entries.where((e) => e.currency == currency).toList();

  static PeriodSummary summary(List<StatEntry> entries, Period period,
      {DateTime? now}) {
    final today = dateOnly(now ?? DateTime.now());
    var income = 0;
    var expense = 0;
    for (final e in entries) {
      if (!period.contains(e.date)) continue;
      if (e.isIncome) {
        income += e.money;
      } else {
        expense += e.money;
      }
    }
    final int elapsed;
    if (today.isBefore(period.start)) {
      elapsed = 0;
    } else if (!today.isBefore(period.end)) {
      elapsed = period.lengthInDays;
    } else {
      elapsed = Period(period.start, addDays(today, 1)).lengthInDays;
    }
    return PeriodSummary(
        period: period, income: income, expense: expense, elapsedDays: elapsed);
  }

  /// Amounts per category, largest first. Without [parent] sub categories
  /// are rolled up into their parent; with [parent] only that category and
  /// its children are listed (drill down).
  static List<CategoryAmount> byCategory(
    List<StatEntry> entries,
    Period period, {
    int direction = Direction.expense,
    String? parent,
  }) {
    final selected = entries.where((e) =>
        e.direction == direction &&
        period.contains(e.date) &&
        (parent == null || e.topCategory == parent));
    final groups = groupBy(selected,
        (StatEntry e) => parent == null ? e.topCategory : e.category);
    final total = selected.fold<int>(0, (s, e) => s + e.money);
    final result = [
      for (final entry in groups.entries)
        CategoryAmount(
          category: entry.key,
          amount: entry.value.fold(0, (s, e) => s + e.money),
          count: entry.value.length,
          share: total == 0
              ? 0
              : entry.value.fold<int>(0, (s, e) => s + e.money) / total,
        ),
    ]..sort((a, b) => b.amount.compareTo(a.amount));
    return result;
  }

  /// Compares the expenses per (top level) category of [current] with the
  /// previous periods.
  static List<CategoryComparison> compareCategories(
    List<StatEntry> entries,
    Period current,
    List<Period> previous, {
    int direction = Direction.expense,
  }) {
    int sum(String category, Period p) => entries
        .where((e) =>
            e.direction == direction &&
            e.topCategory == category &&
            p.contains(e.date))
        .fold(0, (s, e) => s + e.money);
    final categories = entries
        .where((e) =>
            e.direction == direction &&
            (current.contains(e.date) || previous.any((p) => p.contains(e.date))))
        .map((e) => e.topCategory)
        .toSet();
    final result = [
      for (final c in categories)
        CategoryComparison(
          category: c,
          current: sum(c, current),
          previous: previous.isEmpty ? 0 : sum(c, previous.first),
          average: previous.isEmpty
              ? 0
              : previous.map((p) => sum(c, p)).sum / previous.length,
        ),
    ]..sort((a, b) => b.current.compareTo(a.current) != 0
        ? b.current.compareTo(a.current)
        : b.average.compareTo(a.average));
    return result;
  }

  /// Cumulative expenses per day of [period] (index 0 = first day). The list
  /// ends at [until] (exclusive) when given, e.g. today for the running month.
  static List<int> cumulativeDaily(List<StatEntry> entries, Period period,
      {int direction = Direction.expense, DateTime? until}) {
    final days = period.lengthInDays;
    final perDay = List<int>.filled(days, 0);
    for (final e in entries) {
      if (e.direction != direction || !period.contains(e.date)) continue;
      final index = Period(period.start, dateOnly(e.date)).lengthInDays;
      if (index >= 0 && index < days) perDay[index] += e.money;
    }
    var limit = days;
    if (until != null && until.isBefore(period.end)) {
      limit = Period(period.start, addDays(dateOnly(until), 1)).lengthInDays;
      if (limit < 0) limit = 0;
    }
    final result = <int>[];
    var running = 0;
    for (var i = 0; i < limit; i++) {
      running += perDay[i];
      result.add(running);
    }
    return result;
  }

  /// Income/expense per sub period (cash flow over time).
  static List<FlowPoint> flow(List<StatEntry> entries, List<Period> periods,
      {String? category}) {
    return [
      for (final p in periods)
        FlowPoint(
          p,
          entries
              .where((e) =>
                  e.isIncome &&
                  p.contains(e.date) &&
                  (category == null || e.topCategory == category))
              .fold(0, (s, e) => s + e.money),
          entries
              .where((e) =>
                  e.isExpense &&
                  p.contains(e.date) &&
                  (category == null || e.topCategory == category))
              .fold(0, (s, e) => s + e.money),
        ),
    ];
  }

  /// Largest single expenses of the period.
  static List<StatEntry> topExpenses(List<StatEntry> entries, Period period,
          {int limit = 10}) =>
      (entries.where((e) => e.isExpense && period.contains(e.date)).toList()
            ..sort((a, b) => b.money.compareTo(a.money)))
          .take(limit)
          .toList();

  /// Expense total per day (for the calendar heat map).
  static Map<DateTime, int> dailyExpenses(
      List<StatEntry> entries, Period period) {
    final result = <DateTime, int>{};
    for (final e in entries) {
      if (!e.isExpense || !period.contains(e.date)) continue;
      final d = dateOnly(e.date);
      result[d] = (result[d] ?? 0) + e.money;
    }
    return result;
  }

  /// The [count] periods (of the same kind) before [period].
  static List<Period> previousMonths(Period period, int count,
      {int firstDayOfMonth = 1}) {
    final result = <Period>[];
    var cursor = period;
    for (var i = 0; i < count; i++) {
      cursor = monthPeriod(addDays(cursor.start, -1),
          firstDayOfMonth: firstDayOfMonth);
      result.add(cursor);
    }
    return result;
  }
}
