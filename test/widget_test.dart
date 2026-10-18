import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:money_tracker/app/settings.dart';
import 'package:money_tracker/core/app_icon.dart';
import 'package:money_tracker/data/models.dart';
import 'package:money_tracker/data/repository.dart';
import 'package:money_tracker/io/backup/backup_json.dart';
import 'package:money_tracker/ui/screens/backup_screen.dart';
import 'package:money_tracker/ui/screens/calendar_screen.dart';
import 'package:money_tracker/ui/screens/categories_screen.dart';
import 'package:money_tracker/ui/screens/debts_screen.dart';
import 'package:money_tracker/ui/screens/entities_screen.dart';
import 'package:money_tracker/ui/screens/recurrences_screen.dart';
import 'package:money_tracker/ui/screens/search_screen.dart';
import 'package:money_tracker/ui/screens/settings_screen.dart';
import 'package:money_tracker/ui/screens/wallets_screen.dart';

import 'helpers/test_app.dart';

void main() {
  setUpAll(() => initializeDateFormatting());

  testWidgets('onboarding creates the first wallet and default categories',
      (tester) async {
    final services = await createTestServices();
    await pumpApp(tester, services);

    expect(find.text('Willkommen bei Money Tracker'), findsOneWidget);
    await tester.tap(find.text('Erstes Konto anlegen'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Girokonto');
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();

    expect(services.repo.wallets().single.name, 'Girokonto');
    expect(find.text('Übersicht'), findsWidgets);
    expect(services.repo.categories(type: CategoryType.expense), isNotEmpty);
    expect(services.settings.defaultCategoriesCreated, isTrue);
  });

  testWidgets('a new expense can be recorded', (tester) async {
    final services = await createTestServices();
    final repo = services.repo;
    repo.saveWallet(const Wallet(
        uuid: 'w', name: 'Konto', icon: ColorIcon('#FF0000', 'K'),
        currency: 'EUR', startMoney: 10000));
    repo.saveCategory(const Category(
        uuid: 'food', name: 'Essen', icon: ColorIcon('#00FF00', 'E'),
        type: CategoryType.expense));
    services.settings.defaultCategoriesCreated = true;
    await pumpApp(tester, services);

    await tester.tap(find.text('Neue Buchung').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Betrag'), '12,5+2');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Beschreibung'), 'Mittagessen');
    await tester.pump();
    expect(find.text('= 14.50'), findsOneWidget);

    // Saving without category shows an error.
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();
    expect(find.text('Pflichtfeld'), findsOneWidget);

    await tester.tap(find.text('Kategorie'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Essen').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();

    final tx = repo.transactions(const TransactionFilter()).single.transaction;
    expect(tx.money, 1450);
    expect(tx.direction, Direction.expense);
    expect(tx.description, 'Mittagessen');
    expect(repo.walletBalance('w'), 10000 - 1450);
    expect(find.text('Mittagessen'), findsOneWidget);
  });

  testWidgets('lock screen requires the PIN', (tester) async {
    final services = await createTestServices(
        prefs: {'lock_mode': LockMode.pin.index, 'default_categories': true});
    await services.security.setPin('1234');
    services.repo.saveWallet(const Wallet(
        uuid: 'w', name: 'Konto', icon: ColorIcon('#FF0000', 'K'), currency: 'EUR'));
    await pumpApp(tester, services);

    expect(find.text('PIN eingeben'), findsOneWidget);
    for (final digit in ['1', '1', '1', '1']) {
      // No frame between the taps: fast typing must not lose digits.
      await tester.tap(find.text(digit));
    }
    await tester.pump();
    await tester.tap(find.byIcon(Icons.check_circle));
    await tester.pumpAndSettle();
    expect(find.text('Falsche PIN'), findsOneWidget);

    for (final digit in ['1', '2', '3', '4']) {
      // No frame between the taps: fast typing must not lose digits.
      await tester.tap(find.text(digit));
    }
    await tester.pump();
    await tester.tap(find.byIcon(Icons.check_circle));
    await tester.pumpAndSettle();
    expect(find.text('PIN eingeben'), findsNothing);
    expect(find.text('Übersicht'), findsWidgets);
  });

  group('screens render with imported MoneyWallet data', () {
    late dynamic services;

    Future<void> setUpData(WidgetTester tester) async {
      services = await createTestServices(prefs: {'default_categories': true});
      BackupJsonReader(services.repo).read(
          File('test/fixtures/original_backup.json').readAsStringSync());
      await pumpApp(tester, services);
    }

    testWidgets('dashboard, transactions and statistics', (tester) async {
      await setUpData(tester);
      expect(find.text('Gesamtsaldo'), findsOneWidget);
      await tester.tap(find.text('Buchungen').first);
      await tester.pumpAndSettle();
      expect(find.text('Pizza'), findsOneWidget);
      await tester.tap(find.text('Umbuchungen'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Girokonto → Bargeld'), findsOneWidget);
      await tester.tap(find.text('Statistik').first);
      await tester.pumpAndSettle();
      expect(find.text('Sparquote'), findsOneWidget);
      await tester.tap(find.text('Verlauf'));
      await tester.pumpAndSettle();
      expect(find.text('Letzte 12 Monate'), findsOneWidget);
      await tester.tap(find.text('Individuell'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('opening an existing transaction loads its data', (tester) async {
      await setUpData(tester);
      await tester.tap(find.text('Buchungen').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pizza'));
      await tester.pumpAndSettle();
      expect(find.text('Buchung bearbeiten'), findsOneWidget);
      expect(find.text('45.99'), findsOneWidget);
      expect(find.text('Anna, Ben'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('receipt.jpg'), 200,
          scrollable: find.byType(Scrollable).last);
      expect(find.text('receipt.jpg'), findsOneWidget);
    });

    for (final entry in <String, Widget>{
      'wallets': const WalletsScreen(),
      'categories': const CategoriesScreen(),
      'debts': const DebtsScreen(),
      'recurrences': const RecurrencesScreen(),
      'models': const ModelsScreen(),
      'events': const EventsScreen(),
      'people': const PeopleScreen(),
      'places': const PlacesScreen(),
      'calendar': const CalendarScreen(),
      'search': const SearchScreen(),
      'backup': const BackupScreen(),
      'export': const ExportScreen(),
      'settings': const SettingsScreen(),
      'currencies': const CurrenciesScreen(),
    }.entries) {
      testWidgets('${entry.key} screen', (tester) async {
        await setUpData(tester);
        final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
        navigator.push(MaterialPageRoute(builder: (_) => entry.value));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(entry.value.runtimeType), findsOneWidget);
      });
    }
  });
}
