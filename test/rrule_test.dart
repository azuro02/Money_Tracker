import 'package:flutter_test/flutter_test.dart';
import 'package:money_tracker/core/dates.dart';
import 'package:money_tracker/domain/rrule.dart';

List<String> _take(String rule, DateTime start, [int n = 6]) => RRule.parse(rule)
    .instances(start)
    .take(n)
    .map(toSqlDate)
    .toList();

void main() {
  test('daily with interval', () {
    expect(_take('FREQ=DAILY;INTERVAL=3', DateTime(2024, 2, 27), 4),
        ['2024-02-27', '2024-03-01', '2024-03-04', '2024-03-07']);
  });

  test('weekly on several days, starting mid week', () {
    expect(
        _take('FREQ=WEEKLY;BYDAY=MO,FR', DateTime(2024, 3, 6), 4),
        ['2024-03-08', '2024-03-11', '2024-03-15', '2024-03-18']);
  });

  test('weekly every two weeks without BYDAY uses the start weekday', () {
    expect(_take('FREQ=WEEKLY;INTERVAL=2', DateTime(2024, 3, 6), 3),
        ['2024-03-06', '2024-03-20', '2024-04-03']);
  });

  test('monthly on day 31 skips short months (RFC 5545)', () {
    expect(_take('FREQ=MONTHLY', DateTime(2024, 1, 31), 4),
        ['2024-01-31', '2024-03-31', '2024-05-31', '2024-07-31']);
  });

  test('monthly BYMONTHDAY and last day', () {
    expect(_take('FREQ=MONTHLY;BYMONTHDAY=5', DateTime(2024, 1, 10), 3),
        ['2024-02-05', '2024-03-05', '2024-04-05']);
    expect(_take('FREQ=MONTHLY;BYMONTHDAY=-1', DateTime(2024, 1, 1), 3),
        ['2024-01-31', '2024-02-29', '2024-03-31']);
  });

  test('monthly second Monday', () {
    expect(_take('FREQ=MONTHLY;BYDAY=2MO', DateTime(2024, 1, 1), 3),
        ['2024-01-08', '2024-02-12', '2024-03-11']);
  });

  test('yearly on Feb 29 only in leap years', () {
    expect(_take('FREQ=YEARLY', DateTime(2024, 2, 29), 2),
        ['2024-02-29', '2028-02-29']);
  });

  test('COUNT and UNTIL', () {
    expect(_take('FREQ=DAILY;COUNT=2', DateTime(2024, 1, 1), 10),
        ['2024-01-01', '2024-01-02']);
    expect(_take('FREQ=WEEKLY;UNTIL=20240115', DateTime(2024, 1, 1), 10),
        ['2024-01-01', '2024-01-08', '2024-01-15']);
    expect(_take('FREQ=WEEKLY;UNTIL=20240115T235959Z', DateTime(2024, 1, 1), 10),
        hasLength(3));
  });

  test('round trip to string keeps unknown parts', () {
    final rule = RRule.parse('RRULE:FREQ=WEEKLY;INTERVAL=2;BYDAY=MO,WE;COUNT=5;BYSETPOS=1');
    expect(rule.toString(), 'FREQ=WEEKLY;COUNT=5;INTERVAL=2;BYDAY=MO,WE;BYSETPOS=1');
    expect(RRule.parse(rule.toString()).byDay.length, 2);
  });

  test('invalid rules', () {
    expect(RRule.isValid('FREQ=HOURLY'), isFalse);
    expect(RRule.isValid('INTERVAL=2'), isFalse);
    expect(RRule.isValid('FREQ=DAILY;INTERVAL=0'), isFalse);
    expect(RRule.isValid('FREQ=DAILY'), isTrue);
  });

  test('impossible rule terminates', () {
    expect(_take('FREQ=MONTHLY;BYMONTHDAY=31', DateTime(2024, 4, 30), 2),
        ['2024-05-31', '2024-07-31']);
    expect(
        RRule.parse('FREQ=YEARLY;BYMONTHDAY=30').instances(DateTime(2024, 2, 1)).take(1),
        isEmpty);
  });
}
