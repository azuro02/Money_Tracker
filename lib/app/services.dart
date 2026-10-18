import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/database.dart';
import '../data/models.dart';
import '../data/repository.dart';
import '../domain/recurrence_service.dart';
import '../io/backup/backup_service.dart';
import '../io/backup/backup_format.dart';
import '../l10n/app_localizations.dart';
import 'reminder.dart';
import 'security.dart';
import 'settings.dart';

/// Holds the long living objects of the app.
class AppServices {
  AppServices({
    required this.db,
    required this.settings,
    required this.security,
    required this.attachmentsDir,
    required this.backupsDir,
    this.reminder,
  })  : repo = Repository(db) {
    recurrences = RecurrenceService(repo);
    db.addListener(settings.markDataChanged);
  }

  final AppDatabase db;
  final Repository repo;
  final Settings settings;
  final SecurityService security;
  final Directory attachmentsDir;
  final Directory backupsDir;
  final ReminderService? reminder;
  late final RecurrenceService recurrences;

  BackupService get backups =>
      BackupService(repo, attachmentsDir: attachmentsDir);

  static Future<AppServices> create() async {
    final docs = await getApplicationDocumentsDirectory();
    final support = await getApplicationSupportDirectory();
    final settings = await Settings.load();
    final db = AppDatabase.open(p.join(support.path, 'money_tracker.db'));
    final attachments = Directory(p.join(support.path, 'attachments'))
      ..createSync(recursive: true);
    // Backups go to a user visible location (Files app on iOS, the app's
    // external files folder on Android).
    Directory backupsBase = docs;
    if (Platform.isAndroid) {
      backupsBase = await getExternalStorageDirectory() ?? docs;
    }
    final backups = Directory(p.join(backupsBase.path, 'backups'))
      ..createSync(recursive: true);
    final services = AppServices(
      db: db,
      settings: settings,
      security: SecurityService(const SecureSecretStore()),
      attachmentsDir: attachments,
      backupsDir: backups,
      reminder: ReminderService(),
    );
    final currencies = await rootBundle.loadString('assets/currencies.json');
    services.repo.seed(
      currenciesJson: currencies,
      systemCategoryNames: SystemTag.defaultNames,
    );
    return services;
  }

  /// Localized names of the system categories.
  static Map<String, String> systemCategoryNames(AppLocalizations l) => {
        SystemTag.transfer: l.sysTransfer,
        SystemTag.transferTax: l.sysTransferTax,
        SystemTag.debt: l.sysDebt,
        SystemTag.credit: l.sysCredit,
        SystemTag.paidDebt: l.sysPaidDebt,
        SystemTag.paidCredit: l.sysPaidCredit,
        SystemTag.tax: l.sysTax,
        SystemTag.deposit: l.sysDeposit,
        SystemTag.withdraw: l.sysWithdraw,
      };

  /// Creates the default categories once, after the first wallet exists.
  void ensureDefaultCategories(AppLocalizations l) {
    if (settings.defaultCategoriesCreated) return;
    final hasUserCategories = repo
        .categories()
        .any((c) => c.type != CategoryType.system);
    if (!hasUserCategories) {
      repo.seedDefaultCategories(
        {
          'default::salary': l.defSalary,
          'default::interests': l.defInterests,
          'default::sale': l.defSale,
          'default::prize': l.defPrize,
          'default::tip': l.defTip,
        },
        {
          'default::food_drinks': l.defFoodDrinks,
          'default::groceries': l.defGroceries,
          'default::housing': l.defHousing,
          'default::car_expenses': l.defCarExpenses,
          'default::travel': l.defTravel,
          'default::health': l.defHealth,
          'default::technology': l.defTechnology,
          'default::friends': l.defFriends,
          'default::hobby': l.defHobby,
        },
      );
    }
    settings.defaultCategoriesCreated = true;
  }

  /// Work that runs on start and whenever the app returns to foreground.
  Future<void> onResume() async {
    try {
      recurrences.processDue();
    } catch (e, s) {
      debugPrint('Recurrence processing failed: $e\n$s');
    }
    await runAutoBackupIfDue();
  }

  /// Writes a backup into [backupsDir] when enabled, the interval elapsed
  /// and data changed since the last backup. Keeps the newest 10 files.
  Future<File?> runAutoBackupIfDue({DateTime? now}) async {
    if (!settings.autoBackup || repo.isEmpty) return null;
    final current = now ?? DateTime.now();
    final last = settings.lastBackupMillis;
    final due = current.millisecondsSinceEpoch - last >=
        settings.autoBackupHours * Duration.millisecondsPerHour;
    if (!due || settings.lastDataChangeMillis <= last) return null;
    final password = await security.autoBackupPassword();
    try {
      final file = writeBackup(password: password, now: current);
      settings.lastBackupMillis = current.millisecondsSinceEpoch;
      _pruneBackups();
      return file;
    } catch (e, s) {
      debugPrint('Auto backup failed: $e\n$s');
      return null;
    }
  }

  File writeBackup({String? password, DateTime? now}) {
    final encrypted = password != null && password.isNotEmpty;
    final name =
        BackupService.fileName(now ?? DateTime.now(), encrypted: encrypted);
    final file = File(p.join(backupsDir.path, name));
    file.writeAsBytesSync(backups.createBackup(password: password));
    return file;
  }

  List<File> localBackups() {
    if (!backupsDir.existsSync()) return const [];
    return backupsDir
        .listSync()
        .whereType<File>()
        .where((f) =>
            f.path.endsWith(backupExtensionStandard) ||
            f.path.endsWith(backupExtensionProtected))
        .toList()
      ..sort((a, b) => b.path.compareTo(a.path));
  }

  void _pruneBackups({int keep = 10}) {
    final files = localBackups();
    for (final f in files.skip(keep)) {
      try {
        f.deleteSync();
      } catch (_) {}
    }
  }
}
