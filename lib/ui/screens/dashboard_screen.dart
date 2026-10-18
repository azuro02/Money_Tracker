import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../../core/app_icon.dart';
import '../../core/dates.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../../domain/statistics.dart';
import '../scope.dart';
import '../widgets/common.dart';
import '../widgets/transaction_list.dart';
import '../widgets/wallet_selector.dart';
import 'debts_screen.dart';
import 'recurrences_screen.dart';
import 'search_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.onShowAll});

  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    final services = context.services;
    final repo = services.repo;
    final settings = services.settings;
    final l = context.l10n;
    final theme = Theme.of(context);
    final walletUuid = settings.currentWallet;
    final wallet = walletUuid == null ? null : repo.wallet(walletUuid);
    final now = DateTime.now();
    final month = monthPeriod(now, firstDayOfMonth: settings.firstDayOfMonth);

    final balances = wallet == null
        ? repo.totalBalances()
        : {wallet.currency: repo.walletBalance(wallet.uuid)};
    final entries = StatisticsService(repo)
        .load(wallet: wallet?.uuid, range: month, now: now);
    final currencies = balances.keys.toList();
    // Main currency = the one with most activity this month.
    final mainCurrency = currencies.isEmpty
        ? null
        : (groupBy(entries, (StatEntry e) => e.currency)
                .entries
                .sorted((a, b) => b.value.length.compareTo(a.value.length))
                .firstOrNull
                ?.key ??
            currencies.first);
    final monthEntries = mainCurrency == null
        ? const <StatEntry>[]
        : StatisticsService.forCurrency(entries, mainCurrency);
    final summary = StatisticsService.summary(monthEntries, month, now: now);
    final topCategories = StatisticsService.byCategory(monthEntries, month).take(4).toList();
    final categories = {for (final c in repo.categories(includeHidden: true)) c.uuid: c};
    final recent = repo.transactions(TransactionFilter(wallet: wallet?.uuid, limit: 6));
    final upcoming = [
      ...repo.recurrentTransactions().where((r) =>
          r.nextOccurrence != null &&
          (wallet == null || r.wallet == wallet.uuid)),
    ].take(3).toList();
    final openDebts = repo
        .debts(wallet: wallet?.uuid)
        .where((d) => !d.debt.archived && !d.isComplete)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const WalletSelector(),
        actions: [
          IconButton(
            tooltip: l.search,
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SearchScreen())),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          // Balance
          Card(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            color: theme.colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(wallet == null ? l.totalBalance : l.balance,
                      style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer)),
                  const SizedBox(height: 4),
                  for (final e in balances.entries)
                    Text(
                      context.formatMoney(e.value, e.key),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (mainCurrency != null)
            InfoCard(
              title: context.formatMonth(month.start.day == 1
                  ? month.start
                  : month.lastDay),
              child: _MonthSummary(summary: summary, currency: mainCurrency),
            ),
          if (topCategories.isNotEmpty && mainCurrency != null)
            InfoCard(
              title: l.expensesByCategory,
              child: Column(
                children: [
                  for (final c in topCategories)
                    _CategoryBar(
                      category: categories[c.category],
                      amount: c.amount,
                      share: c.share,
                      currency: mainCurrency,
                    ),
                ],
              ),
            ),
          if (openDebts.isNotEmpty)
            InfoCard(
              title: l.debts,
              padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
              trailing: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TextButton(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const DebtsScreen())),
                  child: Text(l.showAll),
                ),
              ),
              child: Column(
                children: [
                  for (final d in openDebts.take(3))
                    ListTile(
                      dense: true,
                      leading: IconAvatar(d.debt.icon, size: 32),
                      title: Text(d.debt.description),
                      subtitle: LinearProgressIndicator(
                          value: d.progress,
                          borderRadius: BorderRadius.circular(4)),
                      trailing: MoneyText(
                        d.debt.type == DebtType.debt ? -d.remaining : d.remaining,
                        d.currency,
                      ),
                    ),
                ],
              ),
            ),
          if (upcoming.isNotEmpty)
            InfoCard(
              title: l.upcoming,
              padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
              trailing: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TextButton(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const RecurrencesScreen())),
                  child: Text(l.showAll),
                ),
              ),
              child: Column(
                children: [
                  for (final r in upcoming)
                    ListTile(
                      dense: true,
                      leading: IconAvatar(
                          categories[r.category]?.icon ?? AppIcon.fallback,
                          size: 32),
                      title: Text(r.description?.isNotEmpty == true
                          ? r.description!
                          : categories[r.category]?.name ?? ''),
                      subtitle: Text(context.formatDate(r.nextOccurrence!)),
                      trailing: MoneyText(
                        r.direction == Direction.income ? r.money : -r.money,
                        repo.wallet(r.wallet)?.currency ?? '',
                      ),
                    ),
                ],
              ),
            ),
          SectionHeader(
            l.recentTransactions,
            trailing: TextButton(onPressed: onShowAll, child: Text(l.showAll)),
          ),
          if (recent.isEmpty)
            EmptyState(
              icon: Icons.receipt_long_outlined,
              title: l.noTransactions,
              subtitle: l.noTransactionsHint,
            )
          else
            for (final v in recent)
              TransactionTile(v, showWallet: wallet == null, showDate: true),
        ],
      ),
    );
  }
}

class _MonthSummary extends StatelessWidget {
  const _MonthSummary({required this.summary, required this.currency});

  final PeriodSummary summary;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final settings = context.settings;
    final ratio = summary.income == 0
        ? (summary.expense == 0 ? 0.0 : 1.0)
        : (summary.expense / summary.income).clamp(0.0, 1.0);
    Widget figure(String label, int value, {bool signed = false}) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.labelMedium),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: MoneyText(value, currency,
                    signed: signed, style: theme.textTheme.titleMedium),
              ),
            ],
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            figure(l.incomes, summary.income),
            figure(l.expenses, -summary.expense),
            figure(l.net, summary.net, signed: true),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 10,
            color: ratio >= 1 ? settings.expenseColor : theme.colorScheme.primary,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          runSpacing: 4,
          children: [
            if (summary.savingsRate != null)
              Text('${l.savingsRate}: ${(summary.savingsRate! * 100).round()} %',
                  style: theme.textTheme.bodySmall),
            Text(
                '${l.avgPerDay}: ${context.formatMoney(summary.averageDailyExpense.round(), currency)}',
                style: theme.textTheme.bodySmall),
            if (summary.elapsedDays < summary.totalDays)
              Text(
                  '${l.projection}: ${context.formatMoney(summary.projectedExpense, currency)}',
                  style: theme.textTheme.bodySmall),
          ],
        ),
      ],
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({
    required this.category,
    required this.amount,
    required this.share,
    required this.currency,
  });

  final Category? category;
  final int amount;
  final double share;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = category;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          if (c != null) IconAvatar(c.icon, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                          c == null ? '?' : context.categoryName(c.name, c.tag, c.type),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    Text(context.formatMoney(amount, currency),
                        style: theme.textTheme.bodyMedium),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: share,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
