import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_tracker/app/security.dart';
import 'package:money_tracker/app/services.dart';
import 'package:money_tracker/app/settings.dart';
import 'package:money_tracker/data/database.dart';
import 'package:money_tracker/data/models.dart';
import 'package:money_tracker/ui/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Services backed by an in-memory database and mocked preferences.
Future<AppServices> createTestServices(
    {Map<String, Object> prefs = const {}}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final settings = await Settings.load();
  final dir = Directory.systemTemp.createTempSync('mt_widget');
  final services = AppServices(
    db: AppDatabase.inMemory(),
    settings: settings,
    security: SecurityService(MemorySecretStore()),
    attachmentsDir: Directory('${dir.path}/attachments')..createSync(),
    backupsDir: Directory('${dir.path}/backups')..createSync(),
  );
  services.repo.seed(
    currenciesJson: File('assets/currencies.json').readAsStringSync(),
    systemCategoryNames: SystemTag.defaultNames,
  );
  return services;
}

Future<void> pumpApp(WidgetTester tester, AppServices services) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
      MoneyTrackerApp(services: services, locale: const Locale('de')));
  await tester.pumpAndSettle();
}
