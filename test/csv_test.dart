import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:money_tracker/data/models.dart';
import 'package:money_tracker/data/repository.dart';
import 'package:money_tracker/io/backup/backup_json.dart';
import 'package:money_tracker/io/csv/csv_codec.dart';
import 'package:money_tracker/io/csv/csv_service.dart';

import 'helpers/test_repo.dart';

void main() {
  group('codec', () {
    test('writes like opencsv CSVWriter', () {
      expect(
          encodeCsv([
            ['a', 'b "c"', null, 'x,y'],
            ['line\nbreak'],
          ]),
          '"a","b ""c""",,"x,y"\n"line\nbreak"\n');
    });

    test('reads quoted fields, CRLF, BOM and semicolons', () {
      expect(decodeCsv('﻿"a","b ""c"""\r\n1,"2\n3"\r\n'), [
        ['a', 'b "c"'],
        ['1', '2\n3'],
      ]);
      expect(decodeCsv('a;b\n1,5;2'), [
        ['a', 'b'],
        ['1,5', '2'],
      ]);
      expect(decodeCsv('a,,b\n'), [
        ['a', '', 'b'],
      ]);
    });
  });

  group('service', () {
    late Repository repo;
    late CsvService csv;

    setUp(() {
      repo = createTestRepository();
      BackupJsonReader(repo).read(
          File('test/fixtures/original_backup.json').readAsStringSync());
      csv = CsvService(repo);
    });

    test('export uses the original header and format', () {
      final out = csv.exportCsv(
        const ExportOptions(
          wallets: ['w-2'],
          optionalColumns: ['note', 'people', 'event', 'place'],
        ),
        now: DateTime(2024, 1, 1),
      );
      final lines = out.split('\n');
      expect(lines.first,
          '"wallet","currency","category","datetime","money","description","event","people","place","note"');
      expect(out, contains(
          '"Bargeld","EUR","Restaurant","2023-09-02 19:30:00","-45.99","Pizza","Holiday","Anna,Ben","Supermarket","with Anna"'));
      expect(out, contains(
          '"Bargeld","EUR","Transfer","2023-09-04 00:00:00","100.00","Cash withdrawal",,,,'));
    });

    test('export filters by date range and never includes the future', () {
      final out = csv.exportCsv(
        ExportOptions(
          wallets: const ['w-1'],
          start: DateTime(2023, 9, 3),
          end: DateTime(2023, 9, 4),
        ),
        now: DateTime(2024, 1, 1),
      );
      final rows = decodeCsv(out);
      expect(rows.first.length, 6);
      expect(rows.skip(1).map((r) => r[3].substring(0, 10)).toSet(),
          {'2023-09-03', '2023-09-04'});
      final none = csv.exportCsv(const ExportOptions(wallets: ['w-1']),
          now: DateTime(2023, 1, 1));
      expect(decodeCsv(none), hasLength(1));
    });

    test('export -> import round trip creates equal transactions', () {
      final out = csv.exportCsv(
          const ExportOptions(
              wallets: ['w-1', 'w-2'],
              optionalColumns: ['event', 'people', 'place', 'note']),
          now: DateTime(2024, 1, 1));
      final target = createTestRepository();
      target.saveWallet(repo.wallet('w-2')!);
      final count = CsvService(target).importCsv(out);
      expect(count, 10);
      // The existing wallet is reused, the missing one is created.
      expect(target.wallets().map((w) => w.name).toSet(),
          {'Bargeld', 'Girokonto'});
      final pizza = target
          .transactions(const TransactionFilter(query: 'Pizza'))
          .single;
      expect(pizza.transaction.money, 4599);
      expect(pizza.transaction.direction, Direction.expense);
      expect(pizza.placeName, 'Supermarket');
      expect(pizza.eventName, isNull, reason: 'events are never created');
      expect(target.transactionPeople(pizza.transaction.uuid), hasLength(2));
      // System categories are matched by name.
      final transfer = target
          .transactions(TransactionFilter(start: DateTime(2023, 9, 4),
              end: DateTime(2023, 9, 5)))
          .where((v) => v.categoryName == 'Transfer');
      expect(transfer, isNotEmpty);
      expect(transfer.first.transaction.category,
          SystemTag.uuidFor(SystemTag.transfer));
    });

    test('import accepts comma decimals and creates categories', () {
      final count = csv.importCsv(
          'wallet;currency;category;datetime;money;description\n'
          'Neu;JPY;Snacks;2024-01-05 10:00:00;-1500;Onigiri\n'
          'Neu;EUR;Bonus;2024-01-06 10:00:00;12,50;\n');
      expect(count, 2);
      final yen = repo.transactions(const TransactionFilter(query: 'Onigiri')).single;
      expect(yen.transaction.money, 1500);
      expect(yen.currency, 'JPY');
      final bonus = repo.categories(type: CategoryType.income)
          .singleWhere((c) => c.name == 'Bonus');
      final tx = repo.transactions(TransactionFilter(category: bonus.uuid)).single;
      expect(tx.transaction.money, 1250);
      expect(tx.transaction.direction, Direction.income);
      expect(repo.wallets().where((w) => w.name == 'Neu'), hasLength(2));
    });

    test('import errors are atomic', () {
      final before = repo.transactions(const TransactionFilter()).length;
      expect(
          () => csv.importCsv('wallet,currency,category,datetime,money\n'
              'A,EUR,Food,2024-01-01 00:00:00,1\n'
              'A,XXX,Food,2024-01-01 00:00:00,1\n'),
          throwsA(isA<CsvImportException>()
              .having((e) => e.line, 'line', 3)));
      expect(repo.transactions(const TransactionFilter()).length, before);
      expect(() => csv.importCsv('wallet,currency,category,money\n'),
          throwsA(isA<CsvImportException>()));
      expect(
          () => csv.importCsv('wallet,currency,category,datetime,money\n'
              'A,EUR,Food,yesterday,1\n'),
          throwsA(isA<CsvImportException>()));
    });
  });
}
