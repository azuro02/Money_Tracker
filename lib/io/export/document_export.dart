import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:excel/excel.dart' as xl;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/money.dart';
import '../csv/csv_service.dart';

/// Localized texts and formatters for the document exports.
class ExportLabels {
  const ExportLabels({
    required this.columnTitles,
    required this.formatDate,
    required this.formatMoney,
    required this.categoryName,
    required this.title,
    required this.total,
  });

  /// Column key (see [CsvColumn]) -> header text.
  final Map<String, String> columnTitles;
  final String Function(DateTime) formatDate;
  final String Function(ExportRow) formatMoney;

  /// Display name of a category (localizes system categories).
  final String Function(ExportRow) categoryName;
  final String title;
  final String total;
}

/// Column order of the original XLS/PDF exports: date, category, money,
/// wallet (only when everything is in one table), description, optionals.
List<String> documentColumns(ExportOptions options, {required bool singleTable}) => [
      CsvColumn.datetime,
      CsvColumn.category,
      CsvColumn.money,
      if (singleTable) CsvColumn.wallet,
      CsvColumn.description,
      for (final c in CsvColumn.optional)
        if (options.optionalColumns.contains(c)) c,
    ];

String _cell(String column, ExportRow row, ExportLabels labels) =>
    switch (column) {
      CsvColumn.datetime => labels.formatDate(row.date),
      CsvColumn.category => labels.categoryName(row),
      CsvColumn.money => labels.formatMoney(row),
      CsvColumn.wallet => row.wallet,
      CsvColumn.description => row.description ?? '',
      CsvColumn.event => row.event ?? '',
      CsvColumn.people => row.people.join(', '),
      CsvColumn.place => row.place ?? '',
      CsvColumn.note => row.note ?? '',
      _ => '',
    };

Map<String, List<ExportRow>> _groupByWallet(List<ExportRow> rows) =>
    groupBy(rows, (ExportRow r) => r.wallet);

/// Builds an `.xlsx` workbook: one sheet per wallet, or a single sheet.
Uint8List buildXlsx(
  List<ExportRow> rows,
  ExportOptions options,
  ExportLabels labels, {
  bool separateWallets = true,
}) {
  final excel = xl.Excel.createExcel();
  final defaultSheet = excel.getDefaultSheet()!;
  final groups = separateWallets
      ? _groupByWallet(rows)
      : {labels.title: rows};
  if (groups.isEmpty) groups[labels.title] = const [];
  final columns =
      documentColumns(options, singleTable: !separateWallets);
  final used = <String>{};
  for (final entry in groups.entries) {
    var name = entry.key.replaceAll(RegExp(r'[\[\]\*\?/\\:]'), ' ').trim();
    if (name.isEmpty) name = labels.title;
    if (name.length > 31) name = name.substring(0, 31);
    var unique = name;
    for (var i = 2; used.contains(unique); i++) {
      final suffix = ' ($i)';
      unique = '${name.substring(0, (31 - suffix.length).clamp(0, name.length))}$suffix';
    }
    used.add(unique);
    final sheet = excel[unique];
    final bold = xl.CellStyle(bold: true);
    sheet.appendRow([
      for (final c in columns) xl.TextCellValue(labels.columnTitles[c] ?? c),
    ]);
    for (var i = 0; i < columns.length; i++) {
      sheet
          .cell(xl.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          .cellStyle = bold;
    }
    for (final row in entry.value) {
      sheet.appendRow([
        for (final c in columns)
          c == CsvColumn.money
              ? xl.DoubleCellValue(double.parse(
                  minorToPlainString(row.signedMoney, row.decimals)))
              : xl.TextCellValue(_cell(c, row, labels)),
      ]);
    }
    for (var i = 0; i < columns.length; i++) {
      sheet.setColumnAutoFit(i);
    }
  }
  if (!used.contains(defaultSheet)) excel.delete(defaultSheet);
  excel.setDefaultSheet(used.first);
  return Uint8List.fromList(excel.save()!);
}

/// Builds a PDF document with one table per wallet.
Future<Uint8List> buildPdf(
  List<ExportRow> rows,
  ExportOptions options,
  ExportLabels labels, {
  required pw.Font regular,
  required pw.Font bold,
  bool separateWallets = true,
}) async {
  final doc = pw.Document(
    author: 'Money Tracker',
    title: labels.title,
    theme: pw.ThemeData.withFont(base: regular, bold: bold),
  );
  final groups = separateWallets ? _groupByWallet(rows) : {labels.title: rows};
  final columns = documentColumns(options, singleTable: !separateWallets);
  final moneyIndex = columns.indexOf(CsvColumn.money);
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(24),
      header: (context) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 8),
        child: pw.Text(labels.title,
            style: pw.TextStyle(font: bold, fontSize: 18)),
      ),
      build: (context) => [
        if (groups.isEmpty) pw.Text('—'),
        for (final entry in groups.entries) ...[
          pw.SizedBox(height: 12),
          pw.Text(entry.key, style: pw.TextStyle(font: bold, fontSize: 14)),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headers: [for (final c in columns) labels.columnTitles[c] ?? c],
            data: [
              for (final row in entry.value)
                [for (final c in columns) _cell(c, row, labels)],
            ],
            headerStyle: pw.TextStyle(font: bold, fontSize: 9),
            cellStyle: const pw.TextStyle(fontSize: 8),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignments: {
              if (moneyIndex >= 0) moneyIndex: pw.Alignment.centerRight,
            },
            border: const pw.TableBorder(
              horizontalInside: pw.BorderSide(color: PdfColors.grey300, width: .5),
            ),
          ),
          ..._totals(entry.value, labels, bold),
        ],
      ],
    ),
  );
  return doc.save();
}

List<pw.Widget> _totals(
    List<ExportRow> rows, ExportLabels labels, pw.Font bold) {
  final byCurrency = groupBy(rows, (ExportRow r) => r.currency);
  return [
    for (final entry in byCurrency.entries)
      pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Padding(
          padding: const pw.EdgeInsets.only(top: 4),
          child: pw.Text(
            '${labels.total}: ${labels.formatMoney(ExportRow(
              walletUuid: '',
              wallet: '',
              currency: entry.key,
              decimals: entry.value.first.decimals,
              symbol: entry.value.first.symbol,
              category: '',
              categoryTag: null,
              date: DateTime(2000),
              signedMoney: entry.value.fold(0, (s, r) => s + r.signedMoney),
            ))}',
            style: pw.TextStyle(font: bold, fontSize: 10),
          ),
        ),
      ),
  ];
}
