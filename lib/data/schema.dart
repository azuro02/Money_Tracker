/// SQLite schema. Table names and column names deliberately mirror the keys
/// used by the original MoneyWallet backup format (`database.json`), which
/// makes backup import/export a direct mapping. The original's integer ids
/// are replaced by the UUID (`uuid`, exported as `id`) as primary key.
library;

const int schemaVersion = 1;

const List<String> schemaStatements = [
  '''
CREATE TABLE currencies (
  iso TEXT PRIMARY KEY NOT NULL,
  name TEXT NOT NULL,
  symbol TEXT,
  decimals INTEGER NOT NULL DEFAULT 2,
  favourite INTEGER NOT NULL DEFAULT 0,
  last_edit INTEGER NOT NULL DEFAULT 0
)''',
  '''
CREATE TABLE wallets (
  uuid TEXT PRIMARY KEY NOT NULL,
  name TEXT NOT NULL,
  icon TEXT NOT NULL,
  currency TEXT NOT NULL REFERENCES currencies(iso) ON UPDATE CASCADE,
  start_money INTEGER NOT NULL DEFAULT 0,
  count_in_total INTEGER NOT NULL DEFAULT 1,
  archived INTEGER NOT NULL DEFAULT 0,
  note TEXT,
  tag TEXT,
  "index" INTEGER NOT NULL DEFAULT 0,
  last_edit INTEGER NOT NULL DEFAULT 0
)''',
  '''
CREATE TABLE categories (
  uuid TEXT PRIMARY KEY NOT NULL,
  name TEXT NOT NULL,
  icon TEXT NOT NULL,
  type INTEGER NOT NULL,
  parent TEXT REFERENCES categories(uuid) ON DELETE CASCADE,
  tag TEXT,
  show_report INTEGER NOT NULL DEFAULT 1,
  "index" INTEGER NOT NULL DEFAULT 0,
  last_edit INTEGER NOT NULL DEFAULT 0
)''',
  '''
CREATE TABLE events (
  uuid TEXT PRIMARY KEY NOT NULL,
  name TEXT NOT NULL,
  icon TEXT NOT NULL,
  note TEXT,
  start_date TEXT NOT NULL,
  end_date TEXT NOT NULL,
  tag TEXT,
  last_edit INTEGER NOT NULL DEFAULT 0
)''',
  '''
CREATE TABLE places (
  uuid TEXT PRIMARY KEY NOT NULL,
  name TEXT NOT NULL,
  icon TEXT NOT NULL,
  address TEXT,
  latitude REAL,
  longitude REAL,
  tag TEXT,
  last_edit INTEGER NOT NULL DEFAULT 0
)''',
  '''
CREATE TABLE people (
  uuid TEXT PRIMARY KEY NOT NULL,
  name TEXT NOT NULL,
  icon TEXT NOT NULL,
  note TEXT,
  tag TEXT,
  last_edit INTEGER NOT NULL DEFAULT 0
)''',
  '''
CREATE TABLE event_people (
  uuid TEXT PRIMARY KEY NOT NULL,
  event TEXT NOT NULL REFERENCES events(uuid) ON DELETE CASCADE,
  person TEXT NOT NULL REFERENCES people(uuid) ON DELETE CASCADE,
  last_edit INTEGER NOT NULL DEFAULT 0,
  UNIQUE (event, person)
)''',
  '''
CREATE TABLE debts (
  uuid TEXT PRIMARY KEY NOT NULL,
  type INTEGER NOT NULL,
  icon TEXT NOT NULL,
  description TEXT NOT NULL,
  date TEXT NOT NULL,
  expiration_date TEXT,
  wallet TEXT NOT NULL REFERENCES wallets(uuid) ON DELETE CASCADE,
  note TEXT,
  place TEXT REFERENCES places(uuid) ON DELETE SET NULL,
  money INTEGER NOT NULL,
  archived INTEGER NOT NULL DEFAULT 0,
  tag TEXT,
  last_edit INTEGER NOT NULL DEFAULT 0
)''',
  '''
CREATE TABLE debt_people (
  uuid TEXT PRIMARY KEY NOT NULL,
  debt TEXT NOT NULL REFERENCES debts(uuid) ON DELETE CASCADE,
  person TEXT NOT NULL REFERENCES people(uuid) ON DELETE CASCADE,
  last_edit INTEGER NOT NULL DEFAULT 0,
  UNIQUE (debt, person)
)''',
  '''
CREATE TABLE recurrent_transactions (
  uuid TEXT PRIMARY KEY NOT NULL,
  money INTEGER NOT NULL,
  description TEXT,
  category TEXT NOT NULL REFERENCES categories(uuid) ON DELETE CASCADE,
  direction INTEGER NOT NULL,
  wallet TEXT NOT NULL REFERENCES wallets(uuid) ON DELETE CASCADE,
  place TEXT REFERENCES places(uuid) ON DELETE SET NULL,
  note TEXT,
  event TEXT REFERENCES events(uuid) ON DELETE SET NULL,
  confirmed INTEGER NOT NULL DEFAULT 1,
  count_in_total INTEGER NOT NULL DEFAULT 1,
  start_date TEXT NOT NULL,
  last_occurrence TEXT NOT NULL,
  next_occurrence TEXT,
  rule TEXT NOT NULL,
  tag TEXT,
  last_edit INTEGER NOT NULL DEFAULT 0
)''',
  '''
CREATE TABLE recurrent_transfers (
  uuid TEXT PRIMARY KEY NOT NULL,
  description TEXT,
  from_wallet TEXT NOT NULL REFERENCES wallets(uuid) ON DELETE CASCADE,
  to_wallet TEXT NOT NULL REFERENCES wallets(uuid) ON DELETE CASCADE,
  from_money INTEGER NOT NULL,
  to_money INTEGER NOT NULL,
  tax_money INTEGER NOT NULL DEFAULT 0,
  note TEXT,
  event TEXT REFERENCES events(uuid) ON DELETE SET NULL,
  place TEXT REFERENCES places(uuid) ON DELETE SET NULL,
  confirmed INTEGER NOT NULL DEFAULT 1,
  count_in_total INTEGER NOT NULL DEFAULT 1,
  start_date TEXT NOT NULL,
  last_occurrence TEXT NOT NULL,
  next_occurrence TEXT,
  rule TEXT NOT NULL,
  tag TEXT,
  last_edit INTEGER NOT NULL DEFAULT 0
)''',
  '''
CREATE TABLE transactions (
  uuid TEXT PRIMARY KEY NOT NULL,
  money INTEGER NOT NULL,
  date TEXT NOT NULL,
  description TEXT,
  category TEXT NOT NULL REFERENCES categories(uuid) ON DELETE CASCADE,
  direction INTEGER NOT NULL,
  type INTEGER NOT NULL DEFAULT 0,
  wallet TEXT NOT NULL REFERENCES wallets(uuid) ON DELETE CASCADE,
  place TEXT REFERENCES places(uuid) ON DELETE SET NULL,
  note TEXT,
  saving TEXT,
  debt TEXT REFERENCES debts(uuid) ON DELETE SET NULL,
  event TEXT REFERENCES events(uuid) ON DELETE SET NULL,
  recurrence TEXT REFERENCES recurrent_transactions(uuid) ON DELETE SET NULL,
  confirmed INTEGER NOT NULL DEFAULT 1,
  count_in_total INTEGER NOT NULL DEFAULT 1,
  tag TEXT,
  last_edit INTEGER NOT NULL DEFAULT 0
)''',
  'CREATE INDEX idx_transactions_date ON transactions(date)',
  'CREATE INDEX idx_transactions_wallet ON transactions(wallet)',
  'CREATE INDEX idx_transactions_category ON transactions(category)',
  '''
CREATE TABLE transaction_people (
  uuid TEXT PRIMARY KEY NOT NULL,
  "transaction" TEXT NOT NULL REFERENCES transactions(uuid) ON DELETE CASCADE,
  person TEXT NOT NULL REFERENCES people(uuid) ON DELETE CASCADE,
  last_edit INTEGER NOT NULL DEFAULT 0,
  UNIQUE ("transaction", person)
)''',
  '''
CREATE TABLE transaction_models (
  uuid TEXT PRIMARY KEY NOT NULL,
  money INTEGER NOT NULL,
  description TEXT,
  category TEXT NOT NULL REFERENCES categories(uuid) ON DELETE CASCADE,
  direction INTEGER NOT NULL,
  wallet TEXT NOT NULL REFERENCES wallets(uuid) ON DELETE CASCADE,
  place TEXT REFERENCES places(uuid) ON DELETE SET NULL,
  note TEXT,
  event TEXT REFERENCES events(uuid) ON DELETE SET NULL,
  confirmed INTEGER NOT NULL DEFAULT 1,
  count_in_total INTEGER NOT NULL DEFAULT 1,
  tag TEXT,
  last_edit INTEGER NOT NULL DEFAULT 0
)''',
  '''
CREATE TABLE transfers (
  uuid TEXT PRIMARY KEY NOT NULL,
  description TEXT,
  date TEXT NOT NULL,
  "from" TEXT NOT NULL REFERENCES transactions(uuid) ON DELETE CASCADE,
  "to" TEXT NOT NULL REFERENCES transactions(uuid) ON DELETE CASCADE,
  tax TEXT REFERENCES transactions(uuid) ON DELETE SET NULL,
  note TEXT,
  place TEXT REFERENCES places(uuid) ON DELETE SET NULL,
  event TEXT REFERENCES events(uuid) ON DELETE SET NULL,
  recurrence TEXT REFERENCES recurrent_transfers(uuid) ON DELETE SET NULL,
  confirmed INTEGER NOT NULL DEFAULT 1,
  count_in_total INTEGER NOT NULL DEFAULT 1,
  tag TEXT,
  last_edit INTEGER NOT NULL DEFAULT 0
)''',
  '''
CREATE TABLE transfer_people (
  uuid TEXT PRIMARY KEY NOT NULL,
  transfer TEXT NOT NULL REFERENCES transfers(uuid) ON DELETE CASCADE,
  person TEXT NOT NULL REFERENCES people(uuid) ON DELETE CASCADE,
  last_edit INTEGER NOT NULL DEFAULT 0,
  UNIQUE (transfer, person)
)''',
  '''
CREATE TABLE transfer_models (
  uuid TEXT PRIMARY KEY NOT NULL,
  description TEXT,
  from_wallet TEXT NOT NULL REFERENCES wallets(uuid) ON DELETE CASCADE,
  to_wallet TEXT NOT NULL REFERENCES wallets(uuid) ON DELETE CASCADE,
  from_money INTEGER NOT NULL,
  to_money INTEGER NOT NULL,
  tax_money INTEGER NOT NULL DEFAULT 0,
  note TEXT,
  event TEXT REFERENCES events(uuid) ON DELETE SET NULL,
  place TEXT REFERENCES places(uuid) ON DELETE SET NULL,
  confirmed INTEGER NOT NULL DEFAULT 1,
  count_in_total INTEGER NOT NULL DEFAULT 1,
  tag TEXT,
  last_edit INTEGER NOT NULL DEFAULT 0
)''',
  '''
CREATE TABLE attachments (
  uuid TEXT PRIMARY KEY NOT NULL,
  file TEXT NOT NULL,
  name TEXT NOT NULL,
  type TEXT,
  size INTEGER NOT NULL DEFAULT 0,
  tag TEXT,
  last_edit INTEGER NOT NULL DEFAULT 0
)''',
  '''
CREATE TABLE transaction_attachment (
  uuid TEXT PRIMARY KEY NOT NULL,
  "transaction" TEXT NOT NULL REFERENCES transactions(uuid) ON DELETE CASCADE,
  attachment TEXT NOT NULL REFERENCES attachments(uuid) ON DELETE CASCADE,
  last_edit INTEGER NOT NULL DEFAULT 0,
  UNIQUE ("transaction", attachment)
)''',
  '''
CREATE TABLE transfer_attachment (
  uuid TEXT PRIMARY KEY NOT NULL,
  transfer TEXT NOT NULL REFERENCES transfers(uuid) ON DELETE CASCADE,
  attachment TEXT NOT NULL REFERENCES attachments(uuid) ON DELETE CASCADE,
  last_edit INTEGER NOT NULL DEFAULT 0,
  UNIQUE (transfer, attachment)
)''',
  // Sections of the original format this app does not implement (budgets,
  // budget_wallets, savings). They are kept verbatim so that a backup
  // created by MoneyWallet can be re-exported without losing data.
  '''
CREATE TABLE passthrough (
  section TEXT NOT NULL,
  position INTEGER NOT NULL,
  json TEXT NOT NULL,
  PRIMARY KEY (section, position)
)''',
];

/// Tables in the order of the original backup sections (excluding currencies
/// which use the ISO code as id, and the pass-through sections).
const List<String> dataTables = [
  'wallets',
  'categories',
  'events',
  'places',
  'people',
  'event_people',
  'debts',
  'debt_people',
  'recurrent_transactions',
  'recurrent_transfers',
  'transactions',
  'transaction_people',
  'transaction_models',
  'transfers',
  'transfer_people',
  'transfer_models',
  'attachments',
  'transaction_attachment',
  'transfer_attachment',
];
