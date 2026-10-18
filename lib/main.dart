import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/services.dart';
import 'ui/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  final services = await AppServices.create();
  runApp(MoneyTrackerApp(services: services));
}
