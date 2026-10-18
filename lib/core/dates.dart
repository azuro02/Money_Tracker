/// Date helpers. The original app stores dates as local-time strings in the
/// formats `yyyy-MM-dd HH:mm:ss` (datetime) and `yyyy-MM-dd` (date); we keep
/// that representation so that backups stay byte compatible.
library;

String _two(int v) => v.toString().padLeft(2, '0');

String toSqlDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${_two(d.month)}-${_two(d.day)}';

String toSqlDateTime(DateTime d) =>
    '${toSqlDate(d)} ${_two(d.hour)}:${_two(d.minute)}:${_two(d.second)}';

/// Parses `yyyy-MM-dd` or `yyyy-MM-dd HH:mm:ss` (also tolerates `T` and
/// missing seconds). Throws [FormatException] on invalid input.
DateTime parseSqlDateTime(String s) {
  final m = RegExp(
    r'^(\d{4})-(\d{2})-(\d{2})(?:[ T](\d{2}):(\d{2})(?::(\d{2}))?)?',
  ).firstMatch(s.trim());
  if (m == null) throw FormatException('Invalid date: $s');
  int g(int i) => m.group(i) == null ? 0 : int.parse(m.group(i)!);
  return DateTime(g(1), g(2), g(3), g(4), g(5), g(6));
}

DateTime? tryParseSqlDateTime(String? s) {
  if (s == null) return null;
  try {
    return parseSqlDateTime(s);
  } on FormatException {
    return null;
  }
}

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Adds [days] calendar days (DST safe).
DateTime addDays(DateTime d, int days) =>
    DateTime(d.year, d.month, d.day + days, d.hour, d.minute, d.second);

int daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

enum GroupType { daily, weekly, monthly, yearly }

/// A half open date range [start, end) using local dates.
class Period {
  const Period(this.start, this.end);

  final DateTime start;
  final DateTime end;

  /// Last day included in the period.
  DateTime get lastDay => addDays(end, -1);

  int get lengthInDays => DateTime.utc(end.year, end.month, end.day)
      .difference(DateTime.utc(start.year, start.month, start.day))
      .inDays;

  bool contains(DateTime d) => !d.isBefore(start) && d.isBefore(end);

  @override
  bool operator ==(Object other) =>
      other is Period && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'Period(${toSqlDate(start)} .. ${toSqlDate(lastDay)})';
}

/// Computes the "month" containing [date], honouring a custom first day of
/// the month (e.g. payday on the 25th). Days beyond the month length are
/// clamped to the last day of the month.
Period monthPeriod(DateTime date, {int firstDayOfMonth = 1}) {
  DateTime startFor(int year, int month) {
    final day = firstDayOfMonth.clamp(1, daysInMonth(year, month));
    return DateTime(year, month, day);
  }

  var start = startFor(date.year, date.month);
  if (dateOnly(date).isBefore(start)) {
    start = date.month == 1
        ? startFor(date.year - 1, 12)
        : startFor(date.year, date.month - 1);
  }
  final nextMonth = start.month == 12 ? 1 : start.month + 1;
  final nextYear = start.month == 12 ? start.year + 1 : start.year;
  return Period(start, startFor(nextYear, nextMonth));
}

/// The week containing [date]. [firstDayOfWeek] uses [DateTime.monday] ..
/// [DateTime.sunday].
Period weekPeriod(DateTime date, {int firstDayOfWeek = DateTime.monday}) {
  final d = dateOnly(date);
  final diff = (d.weekday - firstDayOfWeek + 7) % 7;
  final start = addDays(d, -diff);
  return Period(start, addDays(start, 7));
}

Period dayPeriod(DateTime date) {
  final d = dateOnly(date);
  return Period(d, addDays(d, 1));
}

Period yearPeriod(DateTime date) =>
    Period(DateTime(date.year), DateTime(date.year + 1));

Period periodFor(
  DateTime date,
  GroupType group, {
  int firstDayOfWeek = DateTime.monday,
  int firstDayOfMonth = 1,
}) {
  switch (group) {
    case GroupType.daily:
      return dayPeriod(date);
    case GroupType.weekly:
      return weekPeriod(date, firstDayOfWeek: firstDayOfWeek);
    case GroupType.monthly:
      return monthPeriod(date, firstDayOfMonth: firstDayOfMonth);
    case GroupType.yearly:
      return yearPeriod(date);
  }
}

/// Splits [range] into consecutive periods of the given [group] type.
List<Period> splitPeriods(
  Period range,
  GroupType group, {
  int firstDayOfWeek = DateTime.monday,
  int firstDayOfMonth = 1,
}) {
  final result = <Period>[];
  var cursor = range.start;
  while (cursor.isBefore(range.end)) {
    final p = periodFor(cursor, group,
        firstDayOfWeek: firstDayOfWeek, firstDayOfMonth: firstDayOfMonth);
    final start = p.start.isBefore(range.start) ? range.start : p.start;
    final end = p.end.isAfter(range.end) ? range.end : p.end;
    result.add(Period(start, end));
    cursor = p.end;
  }
  return result;
}
