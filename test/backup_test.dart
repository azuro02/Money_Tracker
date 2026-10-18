import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:money_tracker/core/app_icon.dart';
import 'package:money_tracker/data/models.dart';
import 'package:money_tracker/data/repository.dart';
import 'package:money_tracker/io/backup/backup_format.dart';
import 'package:money_tracker/io/backup/backup_json.dart';
import 'package:money_tracker/io/backup/backup_service.dart';
import 'package:money_tracker/io/backup/winzip_aes.dart';
import 'package:money_tracker/io/backup/zip.dart';

import 'helpers/test_repo.dart';

String _fixture() =>
    File('test/fixtures/original_backup.json').readAsStringSync();

/// Section names in the order they appear in a JSON document.
List<String> _sectionOrder(String json) => [
      for (final m in RegExp(r'"(\w+)":\[').allMatches(json)) m.group(1)!,
    ];

void main() {
  late Repository repo;

  setUp(() => repo = createTestRepository());

  group('import of an original MoneyWallet backup', () {
    test('imports every section', () {
      final result = BackupJsonReader(repo).read(_fixture());
      expect(result.version, 2);
      expect(result.skipped, 0);
      expect(repo.wallets().map((w) => w.name),
          ['Girokonto', 'Bargeld', 'US Trip']);
      expect(repo.wallet('w-3')!.archived, isTrue);
      expect(repo.wallet('w-3')!.countInTotal, isFalse);
      expect(repo.category('c-restaurant')!.parent, 'c-food');
      expect(repo.category('c-car')!.showReport, isFalse);
      expect(repo.currency('JPY')!.decimals, 0);
      expect(repo.place('pl-1')!.latitude, closeTo(48.137154, 1e-9));
      expect(repo.place('pl-2')!.latitude, isNull);
      expect(repo.transactionPeople('t-1').toSet(), {'p-1', 'p-2'});
      expect(repo.transferPeople('rf-1:2023-09-04'), ['p-1']);
      expect(repo.eventPeople('e-1'), ['p-1']);
      expect(repo.debtPeople('d-1'), ['p-2']);
      expect(repo.transactionAttachments('t-1').single.name, 'receipt.jpg');
      expect(repo.transactionModels().single.description, 'Coffee');
      expect(repo.transferModels().single.description, 'Savings');
      expect(repo.recurrentTransactions().single.rule,
          'FREQ=MONTHLY;BYMONTHDAY=1');
      expect(repo.recurrentTransfers().single.nextOccurrence, isNull);
      expect(repo.transaction('t-saving')!.saving, 's-1');
    });

    test('computes balances like the original app', () {
      BackupJsonReader(repo).read(_fixture());
      // 1500.00 + 2*2500.00 salary - 100.00 transfer - 2.00 fee
      // + 200.00 debt - 50.00 paid back - 100.00 saving deposit.
      // The unconfirmed fuel expense is not counted.
      expect(repo.walletBalance('w-1'), 150000 + 500000 - 10000 - 200 +
          20000 - 5000 - 10000);
      expect(repo.walletBalance('w-2'), 5000 - 4599 + 10000);
      expect(repo.totalBalances(), {'EUR': repo.walletBalance('w-1') +
          repo.walletBalance('w-2')});
    });

    test('transfers and debts are reconstructed', () {
      BackupJsonReader(repo).read(_fixture());
      final transfer = repo.transferView('rf-1:2023-09-04')!;
      expect(transfer.fromWallet, 'w-1');
      expect(transfer.toWallet, 'w-2');
      expect(transfer.fromMoney, 10000);
      expect(transfer.taxMoney, 200);
      final debt = repo.debtView('d-1')!;
      expect(debt.paid, 5000);
      expect(debt.remaining, 15000);
    });

    test('keeps unsupported sections (budgets, savings) verbatim', () {
      BackupJsonReader(repo).read(_fixture());
      expect(repo.passthrough('budgets').single['id'], 'b-1');
      expect(repo.passthrough('budget_wallets').single['wallet'], 'w-1');
      expect(repo.passthrough('savings').single['description'], 'New bike');
    });

    test('numbers written as doubles are accepted', () {
      final json = _fixture().replaceAll('"start_money":150000',
          '"start_money":150000.0');
      BackupJsonReader(repo).read(json);
      expect(repo.wallet('w-1')!.startMoney, 150000);
    });

    test('version 1 backups (without currencies) are accepted', () {
      final map = jsonDecode(_fixture()) as Map<String, dynamic>;
      map['header'] = {'version_code': 1};
      map.remove('currencies');
      final result = BackupJsonReader(repo).read(jsonEncode(map));
      expect(result.version, 1);
      expect(repo.wallets(), hasLength(3));
      expect(repo.currency('EUR'), isNotNull);
    });

    test('rejects unknown versions and invalid files', () {
      expect(() => BackupJsonReader(repo).read('{"header":{"version_code":3}}'),
          throwsA(isA<BackupFormatException>()));
      expect(() => BackupJsonReader(repo).read('not json'),
          throwsA(isA<BackupFormatException>()));
    });

    test('rows with dangling required references are skipped', () {
      final map = jsonDecode(_fixture()) as Map<String, dynamic>;
      (map['transactions'] as List).add({
        'money': 1,
        'date': '2023-01-01 00:00:00',
        'category': 'missing',
        'direction': 0,
        'wallet': 'w-1',
        'id': 'broken',
      });
      final result = BackupJsonReader(repo).read(jsonEncode(map));
      expect(result.skipped, 1);
      expect(repo.transaction('broken'), isNull);
    });

    test('a restore replaces existing data', () {
      repo.saveWallet(const Wallet(
          uuid: 'old', name: 'Old', icon: AppIcon.fallback, currency: 'EUR'));
      BackupJsonReader(repo).read(_fixture());
      expect(repo.wallet('old'), isNull);
    });
  });

  group('export', () {
    test('writes all sections in the order required by the original', () {
      BackupJsonReader(repo).read(_fixture());
      final json = BackupJsonWriter(repo).write();
      expect(json.startsWith('{"header":{"version_code":2},"currencies":['),
          isTrue);
      expect(_sectionOrder(json), backupSections.map((s) => s.name).toList());
      expect(json.contains('null'), isFalse,
          reason: 'the original importer cannot read JSON null values');
    });

    test('round trip preserves every record of the original backup', () {
      BackupJsonReader(repo).read(_fixture());
      final exported = jsonDecode(BackupJsonWriter(repo).write()) as Map;
      final original = jsonDecode(_fixture()) as Map;
      for (final section in backupSections) {
        if (section.name == 'currencies') continue;
        final expected = {
          for (final o in original[section.name] as List)
            (o as Map)['id']: o,
        };
        final actual = {
          for (final o in exported[section.name] as List) (o as Map)['id']: o,
        };
        expect(actual.keys.toSet().containsAll(expected.keys), isTrue,
            reason: section.name);
        for (final id in expected.keys) {
          expect(actual[id], expected[id], reason: '${section.name}/$id');
        }
      }
      // All currencies of the backup are exported again.
      final currencies = {
        for (final c in exported['currencies'] as List) (c as Map)['iso']: c,
      };
      expect(currencies['JPY'], {
        'iso': 'JPY',
        'name': 'Japanese Yen',
        'symbol': '¥',
        'decimals': 0,
        'favourite': false,
        'last_edit': 1700000000000,
        'deleted': false,
      });
    });

    test('pass-through sections drop references to deleted wallets', () {
      BackupJsonReader(repo).read(_fixture());
      repo.db.execute('DELETE FROM transfers');
      repo.deleteWallet('w-1');
      final exported = jsonDecode(BackupJsonWriter(repo).write()) as Map;
      expect(exported['budget_wallets'], isEmpty);
      expect(exported['savings'], isEmpty);
      expect(exported['budgets'], hasLength(1));
    });
  });

  group('BackupService', () {
    late Directory dir;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('mt_backup');
    });

    tearDown(() => dir.deleteSync(recursive: true));

    test('file names follow the original pattern', () {
      final d = DateTime(2024, 1, 31, 12, 5, 9);
      expect(BackupService.fileName(d, encrypted: false),
          'backup_2024-01-31_12-05-09.mwbx');
      expect(BackupService.fileName(d, encrypted: true),
          'backup_2024-01-31_12-05-09.mwbs');
    });

    for (final password in [null, 'secret']) {
      test('backup and restore with attachments (password: $password)', () {
        final source = Directory('${dir.path}/a')..createSync();
        BackupJsonReader(repo).read(_fixture());
        File('${source.path}/att-file-1').writeAsStringSync('receipt content!');
        final bytes = BackupService(repo, attachmentsDir: source)
            .createBackup(password: password);

        final zip = ZipReader(bytes);
        expect(zip.names, [backupDatabaseEntry, 'attachments/att-file-1']);
        expect(zip.isEncrypted, password != null);

        final target = createTestRepository();
        final targetDir = Directory('${dir.path}/b');
        final result = BackupService(target, attachmentsDir: targetDir)
            .restore(bytes, password: password);
        expect(result.count('transactions'), 10);
        expect(File('${targetDir.path}/att-file-1').readAsStringSync(),
            'receipt content!');
        expect(BackupJsonWriter(target).write(), BackupJsonWriter(repo).write());
      });
    }

    test('wrong password leaves existing data untouched', () {
      BackupJsonReader(repo).read(_fixture());
      final bytes = BackupService(repo, attachmentsDir: dir)
          .createBackup(password: 'right');
      final target = createTestRepository();
      target.saveWallet(const Wallet(
          uuid: 'keep', name: 'Keep', icon: AppIcon.fallback, currency: 'EUR'));
      expect(
          () => BackupService(target, attachmentsDir: dir)
              .restore(bytes, password: 'wrong'),
          throwsA(isA<WrongPasswordException>()));
      expect(
          () => BackupService(target, attachmentsDir: dir).restore(bytes),
          throwsA(isA<PasswordRequiredException>()));
      expect(target.wallet('keep'), isNotNull);
    });

    test('rejects archives without database', () {
      final bytes = ZipWriter.encode([]);
      expect(() => BackupService(repo, attachmentsDir: dir).restore(bytes),
          throwsA(isA<BackupFormatException>()));
    });
  });
}
