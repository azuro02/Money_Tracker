import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import '../../data/repository.dart';
import 'backup_format.dart';
import 'backup_json.dart';
import 'zip.dart';

/// Creates and restores backups in the original MoneyWallet container
/// format: a zip archive with `databases/database.json` and the attachment
/// files under `attachments/`. `.mwbs` files are AES-256 encrypted.
class BackupService {
  BackupService(this.repo, {required this.attachmentsDir});

  final Repository repo;

  /// Directory holding the attachment files (named by `attachment.file`).
  final Directory attachmentsDir;

  static String fileName(DateTime now, {required bool encrypted}) {
    String two(int v) => v.toString().padLeft(2, '0');
    final stamp = '${now.year}-${two(now.month)}-${two(now.day)}_'
        '${two(now.hour)}-${two(now.minute)}-${two(now.second)}';
    return 'backup_$stamp${encrypted ? backupExtensionProtected : backupExtensionStandard}';
  }

  Uint8List createBackup({String? password}) {
    final json = BackupJsonWriter(repo).write();
    final entries = <ZipEntry>[
      ZipEntry(backupDatabaseEntry, Uint8List.fromList(utf8.encode(json))),
    ];
    for (final attachment in repo.allAttachments()) {
      final file = File(p.join(attachmentsDir.path, attachment.file));
      if (file.existsSync()) {
        entries.add(ZipEntry('$backupAttachmentsFolder${attachment.file}',
            file.readAsBytesSync()));
      }
    }
    return ZipWriter.encode(entries,
        password: (password == null || password.isEmpty) ? null : password);
  }

  /// True if the archive needs a password.
  static bool isEncrypted(Uint8List bytes) => ZipReader(bytes).isEncrypted;

  /// Replaces all data with the content of the backup. Throws
  /// [PasswordRequiredException], `WrongPasswordException`,
  /// [BackupFormatException] or [FormatException].
  BackupImportResult restore(Uint8List bytes,
      {String? password, Map<String, String> systemCategoryNames = const {}}) {
    final ZipReader zip;
    try {
      zip = ZipReader(bytes);
    } on FormatException {
      throw BackupFormatException('Not a MoneyWallet backup');
    }
    final names = zip.names;
    if (!names.contains(backupDatabaseEntry)) {
      if (names.any((n) => n.startsWith('database/'))) {
        throw BackupFormatException(
            'Legacy MoneyWallet 3.x backups (.mwb) are not supported');
      }
      throw BackupFormatException('database file not found');
    }
    final json = utf8.decode(zip.read(backupDatabaseEntry, password: password)!);
    // Extract attachments first, so a wrong password fails before any data
    // is replaced.
    final files = <String, Uint8List>{};
    for (final name in names) {
      if (!name.startsWith(backupAttachmentsFolder)) continue;
      final fileName = name.substring(backupAttachmentsFolder.length);
      if (fileName.isEmpty || fileName.contains('/') || fileName == '..') {
        continue;
      }
      files[fileName] = zip.read(name, password: password)!;
    }
    final result = BackupJsonReader(repo)
        .read(json, systemCategoryNames: systemCategoryNames);
    if (!attachmentsDir.existsSync()) attachmentsDir.createSync(recursive: true);
    for (final old in attachmentsDir.listSync().whereType<File>()) {
      old.deleteSync();
    }
    files.forEach((name, data) {
      File(p.join(attachmentsDir.path, name)).writeAsBytesSync(data);
    });
    return result;
  }
}
