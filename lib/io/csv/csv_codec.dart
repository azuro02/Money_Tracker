/// Small RFC 4180 CSV writer/reader.
///
/// The writer mimics opencsv's `CSVWriter` defaults used by the original
/// app: separator `,`, every field quoted with `"`, quotes doubled and `\n`
/// as line terminator. Null values become empty (unquoted) fields.
library;

String encodeCsv(List<List<String?>> rows) {
  final out = StringBuffer();
  for (final row in rows) {
    for (var i = 0; i < row.length; i++) {
      if (i > 0) out.write(',');
      final value = row[i];
      if (value != null) {
        out
          ..write('"')
          ..write(value.replaceAll('"', '""'))
          ..write('"');
      }
    }
    out.write('\n');
  }
  return out.toString();
}

/// Parses CSV text. Handles quoted fields, escaped quotes, CRLF/LF line
/// endings, a UTF-8 BOM and an optional `;` separator (auto detected from
/// the header line, as exported by some spreadsheet tools).
List<List<String>> decodeCsv(String input) {
  var text = input;
  if (text.startsWith('﻿')) text = text.substring(1);
  final separator = _detectSeparator(text);
  final rows = <List<String>>[];
  var row = <String>[];
  final field = StringBuffer();
  var inQuotes = false;
  var fieldStarted = false;
  for (var i = 0; i < text.length; i++) {
    final c = text[i];
    if (inQuotes) {
      if (c == '"') {
        if (i + 1 < text.length && text[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        field.write(c);
      }
      continue;
    }
    if (c == '"' && field.isEmpty) {
      inQuotes = true;
      fieldStarted = true;
    } else if (c == separator) {
      row.add(field.toString());
      field.clear();
      fieldStarted = false;
    } else if (c == '\n' || c == '\r') {
      if (c == '\r' && i + 1 < text.length && text[i + 1] == '\n') i++;
      if (fieldStarted || field.isNotEmpty || row.isNotEmpty) {
        row.add(field.toString());
        rows.add(row);
      }
      row = <String>[];
      field.clear();
      fieldStarted = false;
    } else {
      field.write(c);
      fieldStarted = true;
    }
  }
  if (fieldStarted || field.isNotEmpty || row.isNotEmpty) {
    row.add(field.toString());
    rows.add(row);
  }
  return rows;
}

String _detectSeparator(String text) {
  final end = text.indexOf('\n');
  final header = end < 0 ? text : text.substring(0, end);
  final commas = ','.allMatches(header).length;
  final semicolons = ';'.allMatches(header).length;
  return semicolons > commas ? ';' : ',';
}
