import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:pdf/widgets.dart' as pw;

import '../../app/services.dart';
import '../../io/backup/backup_json.dart';
import '../../io/backup/backup_service.dart';
import '../../io/backup/winzip_aes.dart';
import '../../io/backup/zip.dart';
import '../../io/csv/csv_service.dart';
import '../../io/export/document_export.dart';
import '../files.dart';
import '../scope.dart';
import '../widgets/common.dart';
import '../widgets/pickers.dart';

/// Asks for a backup file, its password if needed, confirms and restores.
Future<void> restoreBackupFlow(BuildContext context, {Uint8List? bytes}) async {
  final l = context.l10n;
  final services = context.read;
  final data = bytes ?? (await pickAnyFile())?.bytes;
  if (data == null || !context.mounted) return;
  bool encrypted;
  try {
    encrypted = BackupService.isEncrypted(data);
  } on FormatException catch (e) {
    context.showSnack(l.backupInvalid(e.message));
    return;
  }
  String? password;
  if (encrypted) {
    password = await askPassword(context, title: l.passwordRequired);
    if (password == null || !context.mounted) return;
  }
  if (!services.repo.isEmpty && !await confirm(context, l.restoreConfirm)) return;
  if (!context.mounted) return;
  try {
    final result = services.backups.restore(
      data,
      password: password,
      systemCategoryNames: AppServices.systemCategoryNames(l),
    );
    services.settings.defaultCategoriesCreated = true;
    services.settings.currentWallet = null;
    // Recurrences that became due since the backup was made.
    services.recurrences.processDue();
    if (!context.mounted) return;
    context.showSnack([
      l.backupRestored(result.count('transactions')),
      if (result.skipped > 0) l.backupSkipped(result.skipped),
    ].join('\n'));
  } on WrongPasswordException {
    context.showSnack(l.wrongPassword);
  } on PasswordRequiredException {
    context.showSnack(l.passwordRequired);
  } on BackupFormatException catch (e) {
    context.showSnack(l.backupInvalid(e.message));
  } on FormatException catch (e) {
    context.showSnack(l.backupInvalid(e.message));
  } catch (e) {
    context.showSnack(l.errorGeneric('$e'));
  }
}

Future<String?> askPassword(BuildContext context,
    {required String title, bool optional = false, String? hint}) {
  final controller = TextEditingController();
  final l = context.l10n;
  return showDialog<String>(
    context: context,
    builder: (context) {
      var obscure = true;
      return StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                obscureText: obscure,
                decoration: InputDecoration(
                  labelText: optional ? l.backupPassword : l.enterPassword,
                  suffixIcon: IconButton(
                    icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => obscure = !obscure),
                  ),
                ),
              ),
              if (hint != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(hint, style: Theme.of(context).textTheme.bodySmall),
                ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l.actionCancel)),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: Text(l.actionOk),
            ),
          ],
        ),
      );
    },
  );
}

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final services = context.services;
    final settings = services.settings;
    final locals = services.localBackups();
    final lastBackup = settings.lastBackupMillis;
    return Scaffold(
      appBar: AppBar(title: Text(l.backupAndExport)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          SectionHeader(l.backup),
          ListTile(
            leading: const Icon(Icons.backup_outlined),
            title: Text(l.createBackup),
            subtitle: Text(l.createBackupHint),
            onTap: () => _createBackup(context),
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: Text(l.restoreBackup),
            subtitle: Text(l.restoreBackupHint),
            onTap: () => restoreBackupFlow(context),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.schedule),
            title: Text(l.autoBackup),
            subtitle: Text(l.autoBackupHint),
            value: settings.autoBackup,
            onChanged: (v) {
              settings.autoBackup = v;
              if (v) services.runAutoBackupIfDue();
            },
          ),
          if (settings.autoBackup) ...[
            ListTile(
              leading: const SizedBox(),
              title: Text(l.autoBackupInterval),
              subtitle: Slider(
                value: settings.autoBackupHours.toDouble(),
                min: 24,
                max: 168,
                divisions: 36,
                label: _interval(context, settings.autoBackupHours),
                onChanged: (v) => settings.autoBackupHours = v.round(),
              ),
              trailing: Text(_interval(context, settings.autoBackupHours)),
            ),
            ListTile(
              leading: const SizedBox(),
              title: Text(l.backupPassword),
              subtitle: Text(l.backupPasswordHint),
              trailing: const Icon(Icons.key),
              onTap: () async {
                final pw = await askPassword(context,
                    title: l.backupPassword, optional: true, hint: l.backupPasswordHint);
                if (pw != null) await services.security.setAutoBackupPassword(pw);
              },
            ),
            ListTile(
              leading: const SizedBox(),
              title: Text(l.autoBackupFolder(services.backupsDir.path)),
              subtitle: lastBackup == 0
                  ? null
                  : Text(l.lastBackup(DateFormat.yMd(context.localeName)
                      .add_Hm()
                      .format(DateTime.fromMillisecondsSinceEpoch(lastBackup)))),
            ),
          ],
          if (locals.isNotEmpty) ...[
            SectionHeader(l.localBackups),
            for (final f in locals.take(10))
              ListTile(
                leading: Icon(f.path.endsWith('.mwbs') ? Icons.lock : Icons.inventory_2_outlined),
                title: Text(p.basename(f.path)),
                subtitle: Text('${(f.lengthSync() / 1024).toStringAsFixed(1)} KB'),
                trailing: PopupMenuButton<String>(
                  onSelected: (action) async {
                    switch (action) {
                      case 'restore':
                        await restoreBackupFlow(context, bytes: f.readAsBytesSync());
                      case 'share':
                        await shareBytes(context, f.readAsBytesSync(), p.basename(f.path));
                      case 'delete':
                        if (await confirmDelete(context, p.basename(f.path))) {
                          f.deleteSync();
                          setState(() {});
                        }
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'restore', child: Text(l.restoreBackup)),
                    PopupMenuItem(value: 'share', child: Text(l.actionShare)),
                    PopupMenuItem(value: 'delete', child: Text(l.actionDelete)),
                  ],
                ),
              ),
          ],
          SectionHeader(l.importExport),
          ListTile(
            leading: const Icon(Icons.file_download_outlined),
            title: Text(l.importCsv),
            subtitle: Text(l.importCsvHint),
            onTap: () => _importCsv(context),
          ),
          ListTile(
            leading: const Icon(Icons.file_upload_outlined),
            title: Text(l.exportData),
            subtitle: const Text('CSV · XLSX · PDF'),
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    fullscreenDialog: true, builder: (_) => const ExportScreen())),
          ),
        ],
      ),
    );
  }

  String _interval(BuildContext context, int hours) =>
      hours == 24
          ? context.l10n.intervalDaily
          : hours == 168
              ? context.l10n.intervalWeekly
              : context.l10n.everyHours(hours);

  Future<void> _createBackup(BuildContext context) async {
    final l = context.l10n;
    final services = context.read;
    final password = await askPassword(context,
        title: l.createBackup, optional: true, hint: l.backupPasswordHint);
    if (password == null || !context.mounted) return;
    final encrypted = password.isNotEmpty;
    final bytes = services.backups.createBackup(password: encrypted ? password : null);
    final name = BackupService.fileName(DateTime.now(), encrypted: encrypted);
    await _deliver(context, bytes, name, 'application/octet-stream');
  }

  Future<void> _importCsv(BuildContext context) async {
    final l = context.l10n;
    final file = await pickAnyFile();
    if (file == null || !context.mounted) return;
    try {
      String content;
      try {
        content = utf8.decode(file.bytes);
      } on FormatException {
        content = latin1.decode(file.bytes);
      }
      final count = CsvService(context.read.repo).importCsv(content);
      if (context.mounted) context.showSnack(l.importCsvDone(count));
    } on CsvImportException catch (e) {
      context.showSnack(l.importFailed(
          e.line == null ? e.message : '${e.message} (${e.line})'));
    } catch (e) {
      context.showSnack(l.importFailed('$e'));
    }
  }
}

/// Lets the user save or share a generated file.
Future<void> _deliver(
    BuildContext context, Uint8List bytes, String name, String mime) async {
  final l = context.l10n;
  final action = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (sheet) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(title: Text(name)),
          ListTile(
            leading: const Icon(Icons.save_alt),
            title: Text(l.actionSave),
            onTap: () => Navigator.pop(sheet, 'save'),
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: Text(l.actionShare),
            onTap: () => Navigator.pop(sheet, 'share'),
          ),
        ],
      ),
    ),
  );
  if (action == null || !context.mounted) return;
  try {
    if (action == 'save') {
      if (await saveBytesAs(bytes, name, mimeType: mime) && context.mounted) {
        context.showSnack(l.saved);
      }
    } else {
      await shareBytes(context, bytes, name, mimeType: mime);
    }
  } on PlatformException catch (e) {
    if (context.mounted) context.showSnack(l.errorGeneric(e.message ?? e.code));
  }
}

enum ExportFormat { csv, xlsx, pdf }

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  ExportFormat _format = ExportFormat.csv;
  Set<String>? _wallets;
  DateTime? _start;
  DateTime? _end;
  final Set<String> _columns = {};
  bool _separate = true;
  bool _busy = false;

  Future<void> _export() async {
    final l = context.l10n;
    final services = context.read;
    final options = ExportOptions(
      wallets: _wallets!.toList(),
      start: _start,
      end: _end,
      optionalColumns: [
        for (final c in CsvColumn.optional)
          if (_columns.contains(c)) c,
      ],
    );
    setState(() => _busy = true);
    try {
      final stamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
      final base = 'MoneyTracker_export_$stamp';
      final csv = CsvService(services.repo);
      late Uint8List bytes;
      late String name;
      late String mime;
      if (_format == ExportFormat.csv) {
        bytes = Uint8List.fromList(utf8.encode(csv.exportCsv(options)));
        name = '$base.csv';
        mime = 'text/csv';
      } else {
        final rows = csv.loadRows(options);
        final labels = ExportLabels(
          columnTitles: {
            CsvColumn.datetime: l.date,
            CsvColumn.category: l.category,
            CsvColumn.money: l.amount,
            CsvColumn.wallet: l.wallet,
            CsvColumn.description: l.description,
            CsvColumn.event: l.event,
            CsvColumn.people: l.people,
            CsvColumn.place: l.place,
            CsvColumn.note: l.note,
          },
          formatDate: (d) => '${context.formatDate(d)} ${context.formatTime(d)}',
          formatMoney: (r) => context.formatMoney(r.signedMoney, r.currency),
          categoryName: (r) {
            final names = AppServices.systemCategoryNames(l);
            return r.categoryTag != null && names.containsKey(r.categoryTag)
                ? names[r.categoryTag]!
                : r.category;
          },
          title: l.exportTitle,
          total: l.total,
        );
        if (_format == ExportFormat.xlsx) {
          bytes = buildXlsx(rows, options, labels, separateWallets: _separate);
          name = '$base.xlsx';
          mime = mimeTypeFor(name);
        } else {
          final regular = pw.Font.ttf(await rootBundle.load('assets/fonts/DejaVuSans.ttf'));
          final bold = pw.Font.ttf(await rootBundle.load('assets/fonts/DejaVuSans-Bold.ttf'));
          bytes = await buildPdf(rows, options, labels,
              regular: regular, bold: bold, separateWallets: _separate);
          name = '$base.pdf';
          mime = 'application/pdf';
        }
      }
      if (mounted) await _deliver(context, bytes, name, mime);
    } catch (e) {
      if (mounted) context.showSnack(l.errorGeneric('$e'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final wallets = context.repo.wallets();
    _wallets ??= {
      for (final w in wallets)
        if (!w.archived) w.uuid,
    };
    final columnLabels = {
      CsvColumn.event: l.event,
      CsvColumn.people: l.people,
      CsvColumn.place: l.place,
      CsvColumn.note: l.note,
    };
    return Scaffold(
      appBar: AppBar(title: Text(l.exportData)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _busy || _wallets!.isEmpty ? null : _export,
        icon: _busy
            ? const SizedBox(
                width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.file_upload_outlined),
        label: Text(l.exportData),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          Text(l.exportFormat, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<ExportFormat>(
            segments: const [
              ButtonSegment(value: ExportFormat.csv, label: Text('CSV')),
              ButtonSegment(value: ExportFormat.xlsx, label: Text('XLSX')),
              ButtonSegment(value: ExportFormat.pdf, label: Text('PDF')),
            ],
            selected: {_format},
            onSelectionChanged: (s) => setState(() => _format = s.first),
          ),
          if (_format == ExportFormat.csv)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(l.importCsvHint, style: Theme.of(context).textTheme.bodySmall),
            ),
          const SizedBox(height: 16),
          Text(l.wallets, style: Theme.of(context).textTheme.titleSmall),
          for (final w in wallets)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              secondary: IconAvatar(w.icon, size: 32),
              title: Text(w.name),
              subtitle: Text(w.currency),
              value: _wallets!.contains(w.uuid),
              onChanged: (v) => setState(() =>
                  v == true ? _wallets!.add(w.uuid) : _wallets!.remove(w.uuid)),
            ),
          const SizedBox(height: 8),
          Text(l.period, style: Theme.of(context).textTheme.titleSmall),
          Wrap(
            spacing: 8,
            children: [
              InputChip(
                label: Text(_start == null
                    ? l.fromDate
                    : '${l.fromDate} ${context.formatShortDate(_start!)}'),
                onPressed: () async {
                  final d = await pickDate(context, _start ?? DateTime.now());
                  if (d != null) setState(() => _start = d);
                },
                onDeleted: _start == null ? null : () => setState(() => _start = null),
              ),
              InputChip(
                label: Text(_end == null
                    ? l.toDate
                    : '${l.toDate} ${context.formatShortDate(_end!)}'),
                onPressed: () async {
                  final d = await pickDate(context, _end ?? DateTime.now());
                  if (d != null) setState(() => _end = d);
                },
                onDeleted: _end == null ? null : () => setState(() => _end = null),
              ),
            ],
          ),
          if (_start == null && _end == null)
            Text(l.exportAllTime, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          Text(l.exportColumns, style: Theme.of(context).textTheme.titleSmall),
          Wrap(
            spacing: 8,
            children: [
              for (final c in CsvColumn.optional)
                FilterChip(
                  label: Text(columnLabels[c]!),
                  selected: _columns.contains(c),
                  onSelected: (v) =>
                      setState(() => v ? _columns.add(c) : _columns.remove(c)),
                ),
            ],
          ),
          if (_format != ExportFormat.csv)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.exportSeparateWallets),
              value: _separate,
              onChanged: (v) => setState(() => _separate = v),
            ),
        ],
      ),
    );
  }
}
