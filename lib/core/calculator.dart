import 'money.dart';

/// Evaluates simple arithmetic like `12,50 + 3*2` (the original app has a
/// built-in calculator for amounts). Supports + - * / and parentheses.
/// Returns the result in minor units (rounded) or null when invalid.
int? evaluateAmount(String input, int decimals) {
  final text = input.replaceAll(RegExp(r'[\s ]'), '').replaceAll('×', '*')
      .replaceAll('÷', '/').replaceAll('−', '-');
  if (text.isEmpty) return null;
  if (!RegExp(r'[+*/()]').hasMatch(text.substring(1)) &&
      !text.substring(1).contains('-')) {
    return parseMoney(text, decimals);
  }
  final parser = _Parser(text, decimals);
  try {
    final value = parser.parseExpression();
    if (parser.pos != text.length || value.isNaN || value.isInfinite) {
      return null;
    }
    var factor = 1;
    for (var i = 0; i < decimals; i++) {
      factor *= 10;
    }
    return (value * factor).round();
  } on FormatException {
    return null;
  }
}

class _Parser {
  _Parser(this.text, this.decimals);

  final String text;
  final int decimals;
  int pos = 0;

  String? get _peek => pos < text.length ? text[pos] : null;

  double parseExpression() {
    var value = _term();
    while (_peek == '+' || _peek == '-') {
      final op = text[pos++];
      final rhs = _term();
      value = op == '+' ? value + rhs : value - rhs;
    }
    return value;
  }

  double _term() {
    var value = _factor();
    while (_peek == '*' || _peek == '/') {
      final op = text[pos++];
      final rhs = _factor();
      value = op == '*' ? value * rhs : value / rhs;
    }
    return value;
  }

  double _factor() {
    if (_peek == '-') {
      pos++;
      return -_factor();
    }
    if (_peek == '+') {
      pos++;
      return _factor();
    }
    if (_peek == '(') {
      pos++;
      final value = parseExpression();
      if (_peek != ')') throw const FormatException('missing )');
      pos++;
      return value;
    }
    final start = pos;
    while (pos < text.length && RegExp(r'[0-9.,]').hasMatch(text[pos])) {
      pos++;
    }
    if (start == pos) throw const FormatException('number expected');
    final number = text.substring(start, pos).replaceAll(',', '.');
    final value = double.tryParse(number);
    if (value == null) throw const FormatException('invalid number');
    return value;
  }
}
