import 'dart:io';

import 'package:money_tracker/data/database.dart';
import 'package:money_tracker/data/repository.dart';

/// Creates an in-memory repository seeded with the bundled currencies and
/// the system categories.
Repository createTestRepository() {
  final repo = Repository(AppDatabase.inMemory());
  repo.seed(
    currenciesJson: File('assets/currencies.json').readAsStringSync(),
    systemCategoryNames: const {},
  );
  return repo;
}
