import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/dates.dart';
import '../core/money.dart';

enum LockMode { none, pin, pinBiometric }

/// Date format presets of the original app (index = setting value).
const dateFormatPresets = <String>[
  'EEEE dd MMMM yyyy',
  'EEEE dd MMM yyyy',
  'EEE dd MMM yyyy',
  'dd MMM yyyy',
  'EEE dd/MM/yyyy',
  'dd/MM/yyyy',
  'yyyy/MM/dd',
  'MM/dd/yyyy',
  'EEE MM/dd/yyyy',
  'dd.MM.yyyy',
  'EEE, dd.MM.yyyy',
  'yyyy-MM-dd',
];

/// Selectable accent / income / expense colours.
const settingsColors = <int>[
  0xFF2E7D32, 0xFF00897B, 0xFF0277BD, 0xFF3949AB, 0xFF6A1B9A, 0xFFAD1457,
  0xFFC62828, 0xFFEF6C00, 0xFF6D4C41, 0xFF455A64,
];

/// User preferences stored with shared_preferences (on device only).
class Settings extends ChangeNotifier {
  Settings(this._prefs);

  final SharedPreferences _prefs;

  static Future<Settings> load() async =>
      Settings(await SharedPreferences.getInstance());

  T _get<T>(String key, T fallback) {
    final value = _prefs.get(key);
    return value is T ? value : fallback;
  }

  Future<void> _set(String key, Object? value) async {
    if (value == null) {
      await _prefs.remove(key);
    } else if (value is bool) {
      await _prefs.setBool(key, value);
    } else if (value is int) {
      await _prefs.setInt(key, value);
    } else if (value is String) {
      await _prefs.setString(key, value);
    }
    notifyListeners();
  }

  // Appearance
  ThemeMode get themeMode => ThemeMode.values[_get('theme_mode', 0).clamp(0, 2)];
  set themeMode(ThemeMode v) => _set('theme_mode', v.index);

  Color get seedColor => Color(_get('seed_color', 0xFF00897B));
  set seedColor(Color v) => _set('seed_color', v.toARGB32());

  Color get incomeColor => Color(_get('income_color', 0xFF2E7D32));
  set incomeColor(Color v) => _set('income_color', v.toARGB32());

  Color get expenseColor => Color(_get('expense_color', 0xFFC62828));
  set expenseColor(Color v) => _set('expense_color', v.toARGB32());

  // Formats
  int get dateFormatIndex =>
      _get('date_format', 10).clamp(0, dateFormatPresets.length - 1);
  set dateFormatIndex(int v) => _set('date_format', v);

  String get dateFormat => dateFormatPresets[dateFormatIndex];

  MoneyFormatOptions get moneyFormat => MoneyFormatOptions(
        showCurrency: _get('money_show_currency', true),
        groupDigits: _get('money_group_digits', true),
        roundDecimals: _get('money_round', false),
        alwaysShowSign: _get('money_sign', false),
      );

  void setMoneyFormat({
    bool? showCurrency,
    bool? groupDigits,
    bool? roundDecimals,
    bool? alwaysShowSign,
  }) {
    if (showCurrency != null) _set('money_show_currency', showCurrency);
    if (groupDigits != null) _set('money_group_digits', groupDigits);
    if (roundDecimals != null) _set('money_round', roundDecimals);
    if (alwaysShowSign != null) _set('money_sign', alwaysShowSign);
  }

  int get firstDayOfWeek => _get('first_day_of_week', DateTime.monday);
  set firstDayOfWeek(int v) => _set('first_day_of_week', v);

  int get firstDayOfMonth => _get('first_day_of_month', 1).clamp(1, 31);
  set firstDayOfMonth(int v) => _set('first_day_of_month', v);

  GroupType get groupType =>
      GroupType.values[_get('group_type', GroupType.monthly.index).clamp(0, 3)];
  set groupType(GroupType v) => _set('group_type', v.index);

  // Current wallet (null = all wallets counted in the total)
  String? get currentWallet => _prefs.getString('current_wallet');
  set currentWallet(String? v) => _set('current_wallet', v);

  // Security
  LockMode get lockMode => LockMode.values[_get('lock_mode', 0).clamp(0, 2)];
  set lockMode(LockMode v) => _set('lock_mode', v.index);

  /// Seconds in background before the app locks again.
  int get lockTimeout => _get('lock_timeout', 0);
  set lockTimeout(int v) => _set('lock_timeout', v);

  // Reminder (hour * 60 + minute, -1 = off)
  int get reminderMinutes => _get('reminder', -1);
  set reminderMinutes(int v) => _set('reminder', v);

  // Automatic backups
  bool get autoBackup => _get('auto_backup', false);
  set autoBackup(bool v) => _set('auto_backup', v);

  int get autoBackupHours => _get('auto_backup_hours', 24);
  set autoBackupHours(int v) => _set('auto_backup_hours', v);

  int get lastBackupMillis => _get('last_backup', 0);
  set lastBackupMillis(int v) => _set('last_backup', v);

  int get lastDataChangeMillis => _get('last_data_change', 0);

  /// Called on every database change (not notifying listeners).
  void markDataChanged() =>
      _prefs.setInt('last_data_change', DateTime.now().millisecondsSinceEpoch);

  bool get defaultCategoriesCreated => _get('default_categories', false);
  set defaultCategoriesCreated(bool v) => _set('default_categories', v);
}
