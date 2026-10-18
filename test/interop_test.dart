// Interoperability with the original MoneyWallet backup code path.
//
// tool/interop/ZipInterop.java re-implements the original importer/exporter
// with the same libraries (zip4j 1.3.2, org.json). The test is skipped when
// Java or the libraries are missing; run `tool/interop/fetch_deps.sh` first.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:money_tracker/io/backup/backup_json.dart';
import 'package:money_tracker/io/backup/backup_service.dart';

import 'helpers/test_repo.dart';

const _libs = 'tool/interop/lib';

String? _skipReason() {
  if (Process.runSync('which', ['java']).exitCode != 0) return 'java missing';
  for (final jar in [
    'zip4j-1.3.2.jar',
    'gson-2.10.1.jar',
    'json-20231013.jar',
  ]) {
    if (!File('$_libs/$jar').existsSync()) {
      return 'run tool/interop/fetch_deps.sh';
    }
  }
  return null;
}

ProcessResult _java(List<String> args) {
  final sep = Platform.isWindows ? ';' : ':';
  final cp = [
    '$_libs/zip4j-1.3.2.jar',
    '$_libs/gson-2.10.1.jar',
    '$_libs/json-20231013.jar',
  ].join(sep);
  return Process.runSync('java', [
    '-cp',
    cp,
    'tool/interop/ZipInterop.java',
    ...args,
  ]);
}

void main() {
  final skip = _skipReason();
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('mt_interop'));
  tearDown(() => dir.deleteSync(recursive: true));

  for (final password in ['-', 'Geheim 123']) {
    test('original app can read our backups (password: $password)', () {
      final repo = createTestRepository();
      BackupJsonReader(repo).read(
          File('test/fixtures/original_backup.json').readAsStringSync());
      final attachments = Directory('${dir.path}/att')..createSync();
      File('${attachments.path}/att-file-1').writeAsStringSync('content');
      final bytes = BackupService(repo, attachmentsDir: attachments)
          .createBackup(password: password == '-' ? null : password);
      final file = File('${dir.path}/backup.mwbx')..writeAsBytesSync(bytes);
      final out = Directory('${dir.path}/out')..createSync();

      final result = _java(['read', file.path, password, out.path]);
      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
      expect(result.stdout as String,
          contains('wallets=3 categories=13 events=1 places=2 people=2'));
      expect(result.stdout as String,
          contains('budgets=1 budget_wallets=1 savings=1'));
      expect(result.stdout as String, contains('transactions=10'));
      expect(File('${out.path}/att-file-1').readAsStringSync(), 'content');
    }, skip: skip);

    test('we can read backups created by the original app (password: $password)',
        () {
      final att = File('${dir.path}/att-file-1')..writeAsStringSync('receipt');
      final backup = '${dir.path}/original.mwbs';
      final result = _java([
        'write',
        backup,
        password,
        'test/fixtures/original_backup.json',
        att.path,
      ]);
      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');

      final repo = createTestRepository();
      final target = Directory('${dir.path}/restored');
      final restore = BackupService(repo, attachmentsDir: target).restore(
          File(backup).readAsBytesSync(),
          password: password == '-' ? null : password);
      expect(restore.skipped, 0);
      expect(repo.wallets(), hasLength(3));
      expect(File('${target.path}/att-file-1').readAsStringSync(), 'receipt');
    }, skip: skip);
  }
}
