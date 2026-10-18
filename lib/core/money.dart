import 'package:intl/intl.dart';

/// Money amounts are stored as integers in minor units (e.g. cents), exactly
/// like the original MoneyWallet database. The number of fraction digits is
/// defined by the currency (0..8).
class MoneyFormatOptions {
  const MoneyFormatOptions({
    this.showCurrency = true,
    this.groupDigits = true,
    this.roundDecimals = false,
    this.alwaysShowSign = false,
  });

  final bool showCurrency;
  final bool groupDigits;
  final bool roundDecimals;
  final bool alwaysShowSign;

  static const plain = MoneyFormatOptions(
    showCurrency: false,
    groupDigits: false,
  );
}

int _pow10(int exp) {
  var result = 1;
  for (var i = 0; i < exp; i++) {
    result *= 10;
  }
  return result;
}

/// Converts minor units to a decimal string with '.' as separator, without
/// any grouping. Example: (-1234, 2) -> "-12.34".
String minorToPlainString(int minor, int decimals) {
  final negative = minor < 0;
  final abs = minor.abs();
  if (decimals == 0) return '${negative ? '-' : ''}$abs';
  final factor = _pow10(decimals);
  final integer = abs ~/ factor;
  final fraction = (abs % factor).toString().padLeft(decimals, '0');
  return '${negative ? '-' : ''}$integer.$fraction';
}

/// Parses a user supplied decimal number into minor units. Accepts both ','
/// and '.' as decimal separator (like the original CSV importer) and also
/// tolerates thousands separators when both characters are present.
/// Returns null if the input is not a valid number.
int? parseMoney(String input, int decimals) {
  var s = input.trim().replaceAll(RegExp(r'[\s  ]'), '');
  if (s.isEmpty) return null;
  var negative = false;
  if (s.startsWith('-')) {
    negative = true;
    s = s.substring(1);
  } else if (s.startsWith('+')) {
    s = s.substring(1);
  }
  final lastComma = s.lastIndexOf(',');
  final lastDot = s.lastIndexOf('.');
  if (lastComma >= 0 && lastDot >= 0) {
    // The later one is the decimal separator, the other one groups digits.
    if (lastComma > lastDot) {
      s = s.replaceAll('.', '').replaceAll(',', '.');
    } else {
      s = s.replaceAll(',', '');
    }
  } else {
    s = s.replaceAll(',', '.');
  }
  if (!RegExp(r'^\d*(\.\d*)?$').hasMatch(s) || s == '.' || s.isEmpty) {
    return null;
  }
  final parts = s.split('.');
  final integerPart = parts[0].isEmpty ? '0' : parts[0];
  var fractionPart = parts.length > 1 ? parts[1] : '';
  // Truncate like BigDecimal.longValue() in the original importer.
  if (fractionPart.length > decimals) {
    fractionPart = fractionPart.substring(0, decimals);
  }
  fractionPart = fractionPart.padRight(decimals, '0');
  final value = int.parse(integerPart) * _pow10(decimals) +
      (decimals == 0 ? 0 : int.parse(fractionPart));
  return negative ? -value : value;
}

/// Formats minor units for display.
String formatMoney(
  int minor, {
  required int decimals,
  String? symbol,
  String? locale,
  MoneyFormatOptions options = const MoneyFormatOptions(),
}) {
  final digits = options.roundDecimals ? 0 : decimals;
  final pattern = StringBuffer(options.groupDigits ? '#,##0' : '0');
  if (digits > 0) {
    pattern.write('.');
    pattern.write('0' * digits);
  }
  final format = NumberFormat(pattern.toString(), locale);
  final value = minor / _pow10(decimals);
  var text = format.format(value.abs());
  if (options.showCurrency && symbol != null && symbol.isNotEmpty) {
    text = '$text $symbol';
  }
  if (minor < 0) {
    text = '-$text';
  } else if (options.alwaysShowSign && minor > 0) {
    text = '+$text';
  }
  return text;
}
