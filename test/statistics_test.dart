import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart' as xl;
import 'package:flutter_test/flutter_test.dart';
import 'package:money_tracker/core/dates.dart';
import 'package:money_tracker/data/models.dart';
import 'package:money_tracker/domain/statistics.dart';
import 'package:money_tracker/io/backup/backup_json.dart';
import 'package:money_tracker/io/csv/csv_service.dart';
import 'package:money_tracker/io/export/document_export.dart';
import 'package:pdf/widgets.dart' as pw;

import 'helpers/test_repo.dart';

StatEntry _e(String uuid, DateTime date, int money, int direction,
        {String category = 'food', String? top, String currency = 'EUR'}) =>
    StatEntry(
      uuid: uuid,
      date: date,
      money: money,
      direction: direction,
      category: category,
      topCategory: top ?? category,
      currency: currency,
    );

void main() {
  final march = Period(DateTime(2024, 3, 1), DateTime(2024, 4, 1));
  final entries = [
    _e('salary', DateTime(2024, 3, 1), 300000, Direction.income, category: 'salary'),
    _e('rent', DateTime(2024, 3, 2), 100000, Direction.expense, category: 'home'),
    _e('pizza', DateTime(2024, 3, 5), 2000, Direction.expense,
        category: 'restaurant', top: 'food'),
    _e('market', DateTime(2024, 3, 5), 5000, Direction.expense),
    _e('feb-food', DateTime(2024, 2, 10), 10000, Direction.expense),
    _e('jan-food', DateTime(2024, 1, 10), 4000, Direction.expense),
    _e('usd', DateTime(2024, 3, 5), 999, Direction.expense, currency: 'USD'),
  ];
  final eur = StatisticsService.forCurrency(entries, 'EUR');

  test('summary with savings rate and projection', () {
    final s = StatisticsService.summary(eur, march, now: DateTime(2024, 3, 10));
    expect(s.income, 300000);
    expect(s.expense, 107000);
    expect(s.net, 193000);
    expect(s.savingsRate, closeTo(193000 / 300000, 1e-9));
    expect(s.elapsedDays, 10);
    expect(s.averageDailyExpense, 10700);
    expect(s.projectedExpense, 10700 * 31);
    final past = StatisticsService.summary(eur, march, now: DateTime(2024, 5, 1));
    expect(past.elapsedDays, 31);
    expect(past.projectedExpense, 107000);
  });

  test('by category rolls up sub categories and supports drill down', () {
    final top = StatisticsService.byCategory(eur, march);
    expect(top.map((c) => c.category), ['home', 'food']);
    expect(top[1].amount, 7000);
    expect(top[1].count, 2);
    expect(top.map((c) => c.share).reduce((a, b) => a + b), closeTo(1, 1e-9));
    final drill = StatisticsService.byCategory(eur, march, parent: 'food');
    expect({for (final c in drill) c.category: c.amount},
        {'food': 5000, 'restaurant': 2000});
  });

  test('comparison with previous months', () {
    final previous = StatisticsService.previousMonths(march, 3);
    expect(previous.first, Period(DateTime(2024, 2, 1), DateTime(2024, 3, 1)));
    expect(previous.last.start, DateTime(2023, 12, 1));
    final cmp = StatisticsService.compareCategories(eur, march, previous);
    final food = cmp.singleWhere((c) => c.category == 'food');
    expect(food.current, 7000);
    expect(food.previous, 10000);
    expect(food.average, closeTo(14000 / 3, 1e-9));
    expect(food.changeVsPrevious, closeTo(-.3, 1e-9));
    expect(cmp.singleWhere((c) => c.category == 'home').changeVsPrevious, isNull);
  });

  test('cumulative daily expenses', () {
    final curve = StatisticsService.cumulativeDaily(eur, march,
        until: DateTime(2024, 3, 6));
    expect(curve, [0, 100000, 100000, 100000, 107000, 107000]);
    expect(StatisticsService.cumulativeDaily(eur, march).length, 31);
  });

  test('flow, top expenses and daily totals', () {
    final flow = StatisticsService.flow(
        eur,
        splitPeriods(Period(DateTime(2024, 1, 1), DateTime(2024, 4, 1)),
            GroupType.monthly));
    expect(flow.map((f) => f.expense), [4000, 10000, 107000]);
    expect(flow.last.net, 193000);
    expect(StatisticsService.topExpenses(eur, march, limit: 2).map((e) => e.uuid),
        ['rent', 'market']);
    expect(StatisticsService.dailyExpenses(eur, march)[DateTime(2024, 3, 5)], 7000);
  });

  test('load excludes transfers, unconfirmed and hidden categories', () {
    final repo = createTestRepository();
    BackupJsonReader(repo).read(
        File('test/fixtures/original_backup.json').readAsStringSync());
    final loaded = StatisticsService(repo).load(
      range: Period(DateTime(2023, 9, 1), DateTime(2023, 10, 1)),
      now: DateTime(2024, 1, 1),
    );
    final ids = loaded.map((e) => e.uuid).toSet();
    expect(ids, contains('t-1'));
    expect(ids, contains('t-tr-tax'), reason: 'fees are real expenses');
    expect(ids, isNot(contains('t-tr-from')));
    expect(ids, isNot(contains('t-2')), reason: 'not confirmed');
    expect(loaded.singleWhere((e) => e.uuid == 't-1').topCategory, 'c-food');
  });

  group('document export', () {
    final repo = createTestRepository();
    BackupJsonReader(repo).read(
        File('test/fixtures/original_backup.json').readAsStringSync());
    const options = ExportOptions(
        wallets: ['w-1', 'w-2'], optionalColumns: ['note', 'people']);
    final rows = CsvService(repo).loadRows(options, now: DateTime(2024, 1, 1));
    final labels = ExportLabels(
      columnTitles: const {
        'datetime': 'Date',
        'category': 'Category',
        'money': 'Money',
        'wallet': 'Wallet',
        'description': 'Description',
        'people': 'People',
        'note': 'Note',
      },
      formatDate: toSqlDate,
      formatMoney: (r) => '${r.signedMoney} ${r.symbol}',
      categoryName: (r) => r.category,
      title: 'Export',
      total: 'Total',
    );

    test('column order matches the original', () {
      expect(documentColumns(options, singleTable: true),
          ['datetime', 'category', 'money', 'wallet', 'description', 'people', 'note']);
      expect(documentColumns(options, singleTable: false),
          isNot(contains('wallet')));
    });

    test('xlsx contains one sheet per wallet', () {
      final bytes = buildXlsx(rows, options, labels);
      expect(bytes.sublist(0, 2), [0x50, 0x4B], reason: 'zip container');
      final book = xl.Excel.decodeBytes(bytes);
      expect(book.tables.keys.toSet(), {'Girokonto', 'Bargeld'});
      final sheet = book.tables['Bargeld']!;
      expect(sheet.rows.first.map((c) => c?.value.toString()),
          ['Date', 'Category', 'Money', 'Description', 'People', 'Note']);
      expect(sheet.maxRows, 3);
    });

    test('pdf is generated with unicode fonts', () async {
      pw.Font font(String name) => pw.Font.ttf(ByteData.sublistView(
          File('assets/fonts/$name').readAsBytesSync()));
      final bytes = await buildPdf(rows, options, labels,
          regular: font('DejaVuSans.ttf'), bold: font('DejaVuSans-Bold.ttf'));
      expect(String.fromCharCodes(bytes.sublist(0, 5)), '%PDF-');
      expect(bytes.length, greaterThan(1000));
    });
  });
}
