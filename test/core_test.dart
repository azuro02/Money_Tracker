import 'package:flutter_test/flutter_test.dart';
import 'package:money_tracker/core/app_icon.dart';
import 'package:money_tracker/core/dates.dart';
import 'package:money_tracker/core/money.dart';

void main() {
  group('money', () {
    test('minor units to plain string', () {
      expect(minorToPlainString(1234, 2), '12.34');
      expect(minorToPlainString(-5, 2), '-0.05');
      expect(minorToPlainString(0, 2), '0.00');
      expect(minorToPlainString(1500, 0), '1500');
      expect(minorToPlainString(123456789, 8), '1.23456789');
    });

    test('parse accepts comma and dot like the original importer', () {
      expect(parseMoney('12.34', 2), 1234);
      expect(parseMoney('12,34', 2), 1234);
      expect(parseMoney('-12,3', 2), -1230);
      expect(parseMoney('+7', 2), 700);
      expect(parseMoney('1.234,56', 2), 123456);
      expect(parseMoney('1,234.56', 2), 123456);
      expect(parseMoney(' 1 000,5 ', 2), 100050);
      expect(parseMoney('0.129', 2), 12, reason: 'truncated like BigDecimal.longValue');
      expect(parseMoney('100', 0), 100);
      expect(parseMoney('abc', 2), isNull);
      expect(parseMoney('', 2), isNull);
      expect(parseMoney('.', 2), isNull);
    });

    test('format', () {
      expect(
          formatMoney(123456, decimals: 2, symbol: '€', locale: 'de'), '1.234,56 €');
      expect(formatMoney(-123456, decimals: 2, symbol: '\$', locale: 'en'),
          '-1,234.56 \$');
      expect(
          formatMoney(1250,
              decimals: 2,
              locale: 'en',
              options: const MoneyFormatOptions(
                  showCurrency: false, roundDecimals: true, alwaysShowSign: true)),
          '+13');
      expect(formatMoney(100, decimals: 0, symbol: '¥', locale: 'en'), '100 ¥');
    });
  });

  group('dates', () {
    test('sql formats', () {
      final d = DateTime(2024, 3, 5, 7, 8, 9);
      expect(toSqlDate(d), '2024-03-05');
      expect(toSqlDateTime(d), '2024-03-05 07:08:09');
      expect(parseSqlDateTime('2024-03-05 07:08:09'), d);
      expect(parseSqlDateTime('2024-03-05'), DateTime(2024, 3, 5));
      expect(() => parseSqlDateTime('05.03.2024'), throwsFormatException);
    });

    test('month period with custom first day', () {
      expect(monthPeriod(DateTime(2024, 3, 15)),
          Period(DateTime(2024, 3, 1), DateTime(2024, 4, 1)));
      expect(monthPeriod(DateTime(2024, 3, 15), firstDayOfMonth: 25),
          Period(DateTime(2024, 2, 25), DateTime(2024, 3, 25)));
      expect(monthPeriod(DateTime(2024, 1, 10), firstDayOfMonth: 25),
          Period(DateTime(2023, 12, 25), DateTime(2024, 1, 25)));
      // Day 31 is clamped in short months.
      expect(monthPeriod(DateTime(2024, 2, 29), firstDayOfMonth: 31),
          Period(DateTime(2024, 2, 29), DateTime(2024, 3, 31)));
    });

    test('week period honours first day of week', () {
      final wed = DateTime(2024, 3, 6);
      expect(weekPeriod(wed).start, DateTime(2024, 3, 4));
      expect(weekPeriod(wed, firstDayOfWeek: DateTime.sunday).start,
          DateTime(2024, 3, 3));
    });

    test('split periods', () {
      final parts = splitPeriods(
          Period(DateTime(2024, 1, 15), DateTime(2024, 4, 1)), GroupType.monthly);
      expect(parts.map((p) => toSqlDate(p.start)),
          ['2024-01-15', '2024-02-01', '2024-03-01']);
      expect(parts.first.lengthInDays, 17);
    });

    test('period length is DST safe', () {
      expect(Period(DateTime(2024, 3, 1), DateTime(2024, 4, 1)).lengthInDays, 31);
      expect(Period(DateTime(2024, 10, 1), DateTime(2024, 11, 1)).lengthInDays, 31);
    });
  });

  group('icons', () {
    test('parse original JSON formats', () {
      expect(AppIcon.parse('{"type":"color","color":"#FF0000","name":"AB"}'),
          const ColorIcon('#FF0000', 'AB'));
      expect(AppIcon.parse('{"type":"resource","resource":"ic_icon_car"}'),
          const ResourceIcon('ic_icon_car'));
      expect(AppIcon.parse('garbage'), AppIcon.fallback);
      expect(AppIcon.parse(null), AppIcon.fallback);
    });

    test('serialize round trip', () {
      const icon = ColorIcon('#00FF00', 'Z');
      expect(AppIcon.parse(icon.toJson()), icon);
      expect(const ColorIcon('#123456', 'X').argb, 0xFF123456);
    });

    test('initials', () {
      expect(iconInitials('Food and drinks'), 'FA');
      expect(iconInitials('salary'), 'S');
      expect(iconInitials('  '), '?');
    });
  });
}
