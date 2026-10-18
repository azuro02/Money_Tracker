import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app/services.dart';
import '../app/settings.dart';
import '../core/money.dart';
import '../core/money.dart' as money;
import '../data/models.dart';
import '../data/repository.dart';
import '../l10n/app_localizations.dart';

/// Makes [AppServices] available to the widget tree. Widgets that read the
/// scope are rebuilt whenever the database or the settings change.
class AppScope extends InheritedNotifier<Listenable> {
  AppScope({super.key, required this.services, required super.child})
      : super(notifier: Listenable.merge([services.db, services.settings]));

  final AppServices services;

  static AppServices of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.services;

  /// Access without registering a rebuild dependency (for callbacks).
  static AppServices read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.services;
}

extension AppContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
  AppServices get services => AppScope.of(this);
  Repository get repo => AppScope.of(this).repo;
  Settings get settings => AppScope.of(this).settings;

  /// Read-only access for event handlers.
  AppServices get read => AppScope.read(this);

  String get localeName => Localizations.localeOf(this).toString();

  String formatMoney(int minor, String currencyIso,
      {MoneyFormatOptions? options, bool forceSign = false}) {
    final services = AppScope.of(this);
    final currency = services.repo.currency(currencyIso);
    var opts = options ?? services.settings.moneyFormat;
    if (forceSign) {
      opts = MoneyFormatOptions(
        showCurrency: opts.showCurrency,
        groupDigits: opts.groupDigits,
        roundDecimals: opts.roundDecimals,
        alwaysShowSign: true,
      );
    }
    return money.formatMoney(
      minor,
      decimals: currency?.decimals ?? 2,
      symbol: currency?.displaySymbol ?? currencyIso,
      locale: localeName,
      options: opts,
    );
  }

  String formatDate(DateTime date) =>
      DateFormat(AppScope.of(this).settings.dateFormat, localeName).format(date);

  String formatShortDate(DateTime date) =>
      DateFormat.MMMd(localeName).format(date);

  String formatTime(DateTime date) => DateFormat.Hm(localeName).format(date);

  String formatMonth(DateTime date) =>
      DateFormat.yMMMM(localeName).format(date);

  /// Category name; system categories are shown localized.
  String categoryName(String name, String? tag, int type) {
    if (type != CategoryType.system || tag == null) return name;
    final names = AppServices.systemCategoryNames(l10n);
    return names[tag] ?? name;
  }

  void showSnack(String message) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// Shows a user friendly message for repository errors.
  void showError(Object error) {
    final l = l10n;
    final message = switch (error) {
      RepositoryException(error: RepositoryError.walletUsedInTransfer) =>
        l.errorWalletInTransfer,
      RepositoryException(error: RepositoryError.categoryHasChildren) =>
        l.errorCategoryHasChildren,
      RepositoryException(error: RepositoryError.categoryInUse) =>
        l.errorCategoryInUse,
      RepositoryException(
        error: RepositoryError.categoryHierarchyNotSupported
      ) =>
        l.errorCategoryHierarchy,
      RepositoryException(error: RepositoryError.categoryNotConsistent) =>
        l.errorCategoryType,
      RepositoryException(error: RepositoryError.categorySystemReadOnly) =>
        l.errorCategorySystem,
      RepositoryException(error: RepositoryError.currencyInUse) =>
        l.errorCurrencyInUse,
      RepositoryException(error: RepositoryError.invalidRecurrenceRule) =>
        l.errorInvalidRule,
      RepositoryException(error: RepositoryError.sameWallet) =>
        l.errorSameWallet,
      _ => l.errorGeneric(error.toString()),
    };
    showSnack(message);
  }
}
