/// Description of the original MoneyWallet backup JSON (`database.json`,
/// format version 2). The importer of the original app reads the sections
/// strictly in this order, so the exporter must write them the same way and
/// must never write JSON `null` values (null fields are simply omitted).
library;

const int backupVersion = 2;
const int minSupportedBackupVersion = 1;
const int maxSupportedBackupVersion = 2;

const String backupExtensionStandard = '.mwbx';
const String backupExtensionProtected = '.mwbs';
const String backupExtensionLegacy = '.mwb';

const String backupDatabaseEntry = 'databases/database.json';
const String backupAttachmentsFolder = 'attachments/';

enum ColumnKind { text, integer, real, boolean }

class SectionSpec {
  const SectionSpec(
    this.name, {
    this.table,
    this.columns = const {},
    this.defaults = const {},
    this.minVersion = 1,
    this.passthrough = false,
  });

  /// Section (JSON array) name.
  final String name;

  /// Database table (null for pass-through sections).
  final String? table;

  /// JSON key -> kind. The key `id` maps to the `uuid` column.
  final Map<String, ColumnKind> columns;

  /// Default values applied on import when a key is missing (mirrors the
  /// `optXxx(key, default)` calls of the original importer).
  final Map<String, Object> defaults;

  /// First backup version that contains this section.
  final int minVersion;

  /// Sections of features this app does not implement; stored verbatim.
  final bool passthrough;
}

const _t = ColumnKind.text;
const _i = ColumnKind.integer;
const _r = ColumnKind.real;
const _b = ColumnKind.boolean;

const _common = {'id': _t, 'last_edit': _i};

const List<SectionSpec> backupSections = [
  SectionSpec(
    'currencies',
    table: 'currencies',
    minVersion: 2,
    columns: {
      'iso': _t,
      'name': _t,
      'symbol': _t,
      'decimals': _i,
      'favourite': _b,
      'last_edit': _i,
    },
    defaults: {'decimals': 2, 'favourite': false},
  ),
  SectionSpec(
    'wallets',
    table: 'wallets',
    columns: {
      'name': _t,
      'icon': _t,
      'currency': _t,
      'start_money': _i,
      'count_in_total': _b,
      'archived': _b,
      'note': _t,
      'tag': _t,
      'index': _i,
      ..._common,
    },
    defaults: {
      'start_money': 0,
      'count_in_total': true,
      'archived': false,
      'index': 0,
    },
  ),
  SectionSpec(
    'categories',
    table: 'categories',
    columns: {
      'name': _t,
      'icon': _t,
      'type': _i,
      'parent': _t,
      'tag': _t,
      'show_report': _b,
      'index': _i,
      ..._common,
    },
    defaults: {'type': 0, 'show_report': true, 'index': 0},
  ),
  SectionSpec(
    'events',
    table: 'events',
    columns: {
      'name': _t,
      'icon': _t,
      'note': _t,
      'start_date': _t,
      'end_date': _t,
      'tag': _t,
      ..._common,
    },
  ),
  SectionSpec(
    'places',
    table: 'places',
    columns: {
      'name': _t,
      'icon': _t,
      'address': _t,
      'latitude': _r,
      'longitude': _r,
      'tag': _t,
      ..._common,
    },
  ),
  SectionSpec(
    'people',
    table: 'people',
    columns: {'name': _t, 'icon': _t, 'note': _t, 'tag': _t, ..._common},
  ),
  SectionSpec(
    'event_people',
    table: 'event_people',
    columns: {'event': _t, 'person': _t, ..._common},
  ),
  SectionSpec(
    'debts',
    table: 'debts',
    columns: {
      'type': _i,
      'icon': _t,
      'description': _t,
      'date': _t,
      'expiration_date': _t,
      'wallet': _t,
      'note': _t,
      'place': _t,
      'money': _i,
      'archived': _b,
      'tag': _t,
      ..._common,
    },
    defaults: {'type': 0, 'money': 0, 'archived': false},
  ),
  SectionSpec(
    'debt_people',
    table: 'debt_people',
    columns: {'debt': _t, 'person': _t, ..._common},
  ),
  SectionSpec('budgets', passthrough: true),
  SectionSpec('budget_wallets', passthrough: true),
  SectionSpec('savings', passthrough: true),
  SectionSpec(
    'recurrent_transactions',
    table: 'recurrent_transactions',
    columns: {
      'money': _i,
      'description': _t,
      'category': _t,
      'direction': _i,
      'wallet': _t,
      'place': _t,
      'note': _t,
      'event': _t,
      'confirmed': _b,
      'count_in_total': _b,
      'start_date': _t,
      'last_occurrence': _t,
      'next_occurrence': _t,
      'rule': _t,
      'tag': _t,
      ..._common,
    },
    defaults: {
      'money': 0,
      'direction': 0,
      'confirmed': true,
      'count_in_total': true,
    },
  ),
  SectionSpec(
    'recurrent_transfers',
    table: 'recurrent_transfers',
    columns: {
      'description': _t,
      'from_wallet': _t,
      'to_wallet': _t,
      'from_money': _i,
      'to_money': _i,
      'tax_money': _i,
      'note': _t,
      'event': _t,
      'place': _t,
      'confirmed': _b,
      'count_in_total': _b,
      'start_date': _t,
      'last_occurrence': _t,
      'next_occurrence': _t,
      'rule': _t,
      'tag': _t,
      ..._common,
    },
    defaults: {
      'from_money': 0,
      'to_money': 0,
      'tax_money': 0,
      'confirmed': true,
      'count_in_total': true,
    },
  ),
  SectionSpec(
    'transactions',
    table: 'transactions',
    columns: {
      'money': _i,
      'date': _t,
      'description': _t,
      'category': _t,
      'direction': _i,
      'type': _i,
      'wallet': _t,
      'place': _t,
      'note': _t,
      'saving': _t,
      'debt': _t,
      'event': _t,
      'recurrence': _t,
      'confirmed': _b,
      'count_in_total': _b,
      'tag': _t,
      ..._common,
    },
    defaults: {
      'money': 0,
      'direction': 0,
      'type': 0,
      'confirmed': true,
      'count_in_total': true,
    },
  ),
  SectionSpec(
    'transaction_people',
    table: 'transaction_people',
    columns: {'transaction': _t, 'person': _t, ..._common},
  ),
  SectionSpec(
    'transaction_models',
    table: 'transaction_models',
    columns: {
      'money': _i,
      'description': _t,
      'category': _t,
      'direction': _i,
      'wallet': _t,
      'place': _t,
      'note': _t,
      'event': _t,
      'confirmed': _b,
      'count_in_total': _b,
      'tag': _t,
      ..._common,
    },
    defaults: {
      'money': 0,
      'direction': 0,
      'confirmed': true,
      'count_in_total': true,
    },
  ),
  SectionSpec(
    'transfers',
    table: 'transfers',
    columns: {
      'description': _t,
      'date': _t,
      'from': _t,
      'to': _t,
      'tax': _t,
      'note': _t,
      'place': _t,
      'event': _t,
      'recurrence': _t,
      'confirmed': _b,
      'count_in_total': _b,
      'tag': _t,
      ..._common,
    },
    defaults: {'confirmed': true, 'count_in_total': true},
  ),
  SectionSpec(
    'transfer_people',
    table: 'transfer_people',
    columns: {'transfer': _t, 'person': _t, ..._common},
  ),
  SectionSpec(
    'transfer_models',
    table: 'transfer_models',
    columns: {
      'description': _t,
      'from_wallet': _t,
      'to_wallet': _t,
      'from_money': _i,
      'to_money': _i,
      'tax_money': _i,
      'note': _t,
      'event': _t,
      'place': _t,
      'confirmed': _b,
      'count_in_total': _b,
      'tag': _t,
      ..._common,
    },
    defaults: {
      'from_money': 0,
      'to_money': 0,
      'tax_money': 0,
      'confirmed': true,
      'count_in_total': true,
    },
  ),
  SectionSpec(
    'attachments',
    table: 'attachments',
    columns: {
      'file': _t,
      'name': _t,
      'type': _t,
      'size': _i,
      'tag': _t,
      ..._common,
    },
    defaults: {'size': 0},
  ),
  SectionSpec(
    'transaction_attachment',
    table: 'transaction_attachment',
    columns: {'transaction': _t, 'attachment': _t, ..._common},
  ),
  SectionSpec(
    'transfer_attachment',
    table: 'transfer_attachment',
    columns: {'transfer': _t, 'attachment': _t, ..._common},
  ),
];
