# Money Tracker

A privacy friendly, offline expense tracker for **Android and iOS**, written in
Flutter. It is a modern reimplementation of
[MoneyWallet](https://github.com/AndreAle94/moneywallet) by Andrea Alessandrini.
Backups and CSV exports are compatible with the original app, so you can move
your data between the two apps in both directions.

## Features

- Multiple wallets with any currency, initial balance, archive, sorting and a
  combined view ("all wallets", totals per currency)
- Income and expenses with categories and sub categories, date and time,
  description, notes, events, places, people, attachments (photos, files),
  confirmed / "count in total" flags and a built-in calculator
- Transfers between wallets with fee and a different target amount for
  different currencies
- Debts and credits with repayment tracking, due dates and archive
- Recurring transactions and transfers (RFC 5545 rules: daily, weekly on
  chosen weekdays, monthly incl. last day, yearly, with an end date or a
  number of occurrences)
- Templates for transactions and transfers
- Statistics:
  - monthly summary: income, expenses, net, savings rate, average per day and
    a projection to the end of the month
  - donut chart by category with drill down into sub categories
  - comparison per category with last month and the 3-month average
  - spending over the month against last month
  - daily spending, largest expenses
  - 12 month trend
  - the configurable overview of the original (any period, grouped by day,
    week, month or year, cash flow or single category)
- A "first day of the month" setting, e.g. payday
- Calendar with a spending heat map, full text search with filters
- PIN lock with optional biometrics (Face ID / fingerprint)
- Daily reminder (a local notification)
- German and English

The original app's budgets, savings, ATM/bank search, currency converter and
cloud backup services are not part of this app.

## Compatibility with MoneyWallet

| Format | Import | Export | Notes |
| --- | --- | --- | --- |
| Backup `.mwbx` | ✅ | ✅ | zip with `databases/database.json` and `attachments/` |
| Backup `.mwbs` (password) | ✅ | ✅ | WinZip AES-256, same as zip4j in the original |
| CSV | ✅ | ✅ | `wallet,currency,category,datetime,money,description[,event,people,place,note]` |
| XLSX / PDF | – | ✅ | the original writes `.xls`, this app writes `.xlsx` |
| Legacy `.mwb` (MoneyWallet 3.x) | ❌ | – | |

Budgets, budget wallets and savings plans in an imported backup are stored
unchanged and written back on export. Restoring such a backup in MoneyWallet
therefore does not lose them.

`test/interop_test.dart` checks compatibility against a Java
reimplementation of the original importer/exporter that uses the original
libraries (zip4j 1.3.2, org.json). Run `tool/interop/fetch_deps.sh` once to
download them; the test is skipped without Java.

## Privacy

- No internet permission (removed in the Android manifest), no analytics, no
  ads, no crash reporting, no accounts.
- All data lives in a local SQLite database inside the app sandbox.
- Android cloud backup and device transfer are disabled for the app data.
- Data only leaves the device when you share a backup or an export yourself.

See [PRIVACY.md](PRIVACY.md).

## Development

```sh
flutter pub get
flutter test             # unit, widget, format and interop tests
flutter run
flutter build apk        # Android
flutter build ipa        # iOS (requires macOS with Xcode)
```

Store release (signing, icons, screenshots, listing texts): see
[store/README.md](store/README.md).

Project layout:

- `lib/core`: money, dates, icons, calculator
- `lib/data`: SQLite schema (mirrors the MoneyWallet backup format), models,
  repository with business rules
- `lib/domain`: recurrence rules and generator, statistics
- `lib/io`: backup (zip and WinZip AES, JSON), CSV, XLSX/PDF export
- `lib/app`: settings, security, reminders, services
- `lib/ui`: screens and widgets
- `lib/l10n`: translations (ARB)

## License and credits

Money Tracker is free software, licensed under the **GNU General Public
License v3** (see [LICENSE](LICENSE)).

Based on the ideas and the data format of MoneyWallet by Andrea Alessandrini
(GPL v3). This is an independent project and not affiliated with the
original. The PDF export bundles the DejaVu Sans fonts (see
`assets/fonts/LICENSE-DejaVu.txt`).
