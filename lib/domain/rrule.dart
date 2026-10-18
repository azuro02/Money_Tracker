import '../core/dates.dart';

/// Minimal RFC 5545 RRULE implementation covering everything the original
/// MoneyWallet UI produces (FREQ, INTERVAL, BYDAY, BYMONTHDAY, COUNT, UNTIL,
/// WKST). Unknown parts are preserved in [extra] so they survive editing.
///
/// Only dates matter for this app, so instances are local dates at midnight.
enum Frequency { daily, weekly, monthly, yearly }

class WeekdayNum {
  const WeekdayNum(this.weekday, [this.ordinal]);

  /// [DateTime.monday] .. [DateTime.sunday].
  final int weekday;

  /// Optional position inside the month (e.g. 2 for the second Monday,
  /// -1 for the last). Only meaningful for monthly/yearly rules.
  final int? ordinal;

  @override
  bool operator ==(Object other) =>
      other is WeekdayNum &&
      other.weekday == weekday &&
      other.ordinal == ordinal;

  @override
  int get hashCode => Object.hash(weekday, ordinal);

  @override
  String toString() => '${ordinal ?? ''}${_dayCodes[weekday - 1]}';
}

const _dayCodes = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];

class RRule {
  const RRule({
    required this.frequency,
    this.interval = 1,
    this.byDay = const [],
    this.byMonthDay = const [],
    this.count,
    this.until,
    this.weekStart = DateTime.monday,
    this.extra = const {},
  });

  final Frequency frequency;
  final int interval;
  final List<WeekdayNum> byDay;
  final List<int> byMonthDay;
  final int? count;

  /// Inclusive end date.
  final DateTime? until;
  final int weekStart;
  final Map<String, String> extra;

  bool get isInfinite => count == null && until == null;

  static RRule parse(String input) {
    var s = input.trim();
    if (s.toUpperCase().startsWith('RRULE:')) s = s.substring(6);
    Frequency? freq;
    var interval = 1;
    var byDay = <WeekdayNum>[];
    var byMonthDay = <int>[];
    int? count;
    DateTime? until;
    var wkst = DateTime.monday;
    final extra = <String, String>{};
    for (final part in s.split(';')) {
      if (part.isEmpty) continue;
      final idx = part.indexOf('=');
      if (idx <= 0) throw FormatException('Invalid rule part: $part');
      final key = part.substring(0, idx).toUpperCase();
      final value = part.substring(idx + 1);
      switch (key) {
        case 'FREQ':
          freq = switch (value.toUpperCase()) {
            'DAILY' => Frequency.daily,
            'WEEKLY' => Frequency.weekly,
            'MONTHLY' => Frequency.monthly,
            'YEARLY' => Frequency.yearly,
            _ => throw FormatException('Unsupported frequency: $value'),
          };
        case 'INTERVAL':
          interval = int.parse(value);
          if (interval < 1) throw FormatException('Invalid interval: $value');
        case 'BYDAY':
          byDay = value.split(',').map(_parseWeekdayNum).toList();
        case 'BYMONTHDAY':
          byMonthDay = value.split(',').map(int.parse).toList();
        case 'COUNT':
          count = int.parse(value);
        case 'UNTIL':
          until = _parseUntil(value);
        case 'WKST':
          wkst = _parseDay(value);
        default:
          extra[key] = value;
      }
    }
    if (freq == null) throw const FormatException('FREQ is missing');
    return RRule(
      frequency: freq,
      interval: interval,
      byDay: byDay,
      byMonthDay: byMonthDay,
      count: count,
      until: until,
      weekStart: wkst,
      extra: extra,
    );
  }

  static bool isValid(String input) {
    try {
      parse(input);
      return true;
    } on FormatException {
      return false;
    }
  }

  static int _parseDay(String code) {
    final i = _dayCodes.indexOf(code.toUpperCase());
    if (i < 0) throw FormatException('Invalid weekday: $code');
    return i + 1;
  }

  static WeekdayNum _parseWeekdayNum(String s) {
    final m = RegExp(r'^([+-]?\d{1,2})?([A-Za-z]{2})$').firstMatch(s.trim());
    if (m == null) throw FormatException('Invalid BYDAY: $s');
    final ord = m.group(1) == null ? null : int.parse(m.group(1)!);
    return WeekdayNum(_parseDay(m.group(2)!), ord);
  }

  static DateTime _parseUntil(String s) {
    final m = RegExp(r'^(\d{4})(\d{2})(\d{2})').firstMatch(s);
    if (m == null) throw FormatException('Invalid UNTIL: $s');
    return DateTime(
        int.parse(m.group(1)!), int.parse(m.group(2)!), int.parse(m.group(3)!));
  }

  @override
  String toString() {
    final parts = <String>['FREQ=${frequency.name.toUpperCase()}'];
    if (until != null) {
      final u = until!;
      parts.add('UNTIL=${u.year.toString().padLeft(4, '0')}'
          '${u.month.toString().padLeft(2, '0')}'
          '${u.day.toString().padLeft(2, '0')}');
    }
    if (count != null) parts.add('COUNT=$count');
    if (interval != 1) parts.add('INTERVAL=$interval');
    if (byDay.isNotEmpty) parts.add('BYDAY=${byDay.join(',')}');
    if (byMonthDay.isNotEmpty) parts.add('BYMONTHDAY=${byMonthDay.join(',')}');
    if (weekStart != DateTime.monday) {
      parts.add('WKST=${_dayCodes[weekStart - 1]}');
    }
    extra.forEach((k, v) => parts.add('$k=$v'));
    return parts.join(';');
  }

  /// Lazily yields all instances starting at [start] (DTSTART), in order.
  Iterable<DateTime> instances(DateTime start) sync* {
    final dtstart = dateOnly(start);
    var emitted = 0;
    // Guard against rules that never match (e.g. BYMONTHDAY=31 + FEB only).
    var emptyPeriods = 0;
    for (var period = 0;; period++) {
      final candidates = _candidates(dtstart, period);
      var any = false;
      for (final d in candidates) {
        if (d.isBefore(dtstart)) continue;
        if (until != null && d.isAfter(until!)) return;
        any = true;
        yield d;
        emitted++;
        if (count != null && emitted >= count!) return;
      }
      emptyPeriods = any ? 0 : emptyPeriods + 1;
      if (emptyPeriods > 1000) return;
    }
  }

  List<DateTime> _candidates(DateTime dtstart, int period) {
    final step = period * interval;
    switch (frequency) {
      case Frequency.daily:
        final d = addDays(dtstart, step);
        if (byDay.isNotEmpty && !byDay.any((w) => w.weekday == d.weekday)) {
          return const [];
        }
        if (byMonthDay.isNotEmpty && !_matchesMonthDay(d)) return const [];
        return [d];
      case Frequency.weekly:
        final weekStartDate =
            addDays(dtstart, -((dtstart.weekday - weekStart + 7) % 7));
        final base = addDays(weekStartDate, step * 7);
        final days = byDay.isEmpty
            ? [dtstart.weekday]
            : byDay.map((w) => w.weekday).toSet().toList();
        final result = [
          for (final wd in days) addDays(base, (wd - weekStart + 7) % 7),
        ]..sort();
        return result;
      case Frequency.monthly:
        final monthIndex = dtstart.month - 1 + step;
        final year = dtstart.year + monthIndex ~/ 12;
        final month = monthIndex % 12 + 1;
        return _daysInMonth(year, month, dtstart);
      case Frequency.yearly:
        final year = dtstart.year + step;
        if (byMonthDay.isEmpty && byDay.isEmpty) {
          if (dtstart.day > daysInMonth(year, dtstart.month)) return const [];
          return [DateTime(year, dtstart.month, dtstart.day)];
        }
        return _daysInMonth(year, dtstart.month, dtstart);
    }
  }

  bool _matchesMonthDay(DateTime d) {
    final len = daysInMonth(d.year, d.month);
    return byMonthDay.any((md) => md > 0 ? md == d.day : len + md + 1 == d.day);
  }

  List<DateTime> _daysInMonth(int year, int month, DateTime dtstart) {
    final len = daysInMonth(year, month);
    final result = <DateTime>{};
    if (byMonthDay.isEmpty && byDay.isEmpty) {
      // RFC 5545: invalid dates (e.g. 31st in a 30 day month) are skipped.
      if (dtstart.day <= len) result.add(DateTime(year, month, dtstart.day));
    }
    for (final md in byMonthDay) {
      final day = md > 0 ? md : len + md + 1;
      if (day >= 1 && day <= len) result.add(DateTime(year, month, day));
    }
    for (final w in byDay) {
      final matches = [
        for (var day = 1; day <= len; day++)
          if (DateTime(year, month, day).weekday == w.weekday)
            DateTime(year, month, day),
      ];
      if (w.ordinal == null) {
        result.addAll(matches);
      } else {
        final i = w.ordinal! > 0 ? w.ordinal! - 1 : matches.length + w.ordinal!;
        if (i >= 0 && i < matches.length) result.add(matches[i]);
      }
    }
    // When both BYMONTHDAY and BYDAY are present they intersect.
    if (byMonthDay.isNotEmpty && byDay.isNotEmpty) {
      result.removeWhere((d) =>
          !_matchesMonthDay(d) || !byDay.any((w) => w.weekday == d.weekday));
    }
    return result.toList()..sort();
  }
}
