import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/dates.dart';
import '../../data/repository.dart';
import '../scope.dart';
import '../widgets/common.dart';
import '../widgets/transaction_list.dart';

/// Month calendar with a spending heat map and the transactions of the
/// selected day.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selected = dateOnly(DateTime.now());

  void _shift(int months) => setState(() {
        _month = DateTime(_month.year, _month.month + months);
        _selected = _month;
      });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final services = context.services;
    final repo = services.repo;
    final settings = services.settings;
    final theme = Theme.of(context);
    final wallet = settings.currentWallet;
    final monthRange = Period(_month, DateTime(_month.year, _month.month + 1));
    final transactions = repo.transactions(
        TransactionFilter(wallet: wallet, start: monthRange.start, end: monthRange.end));
    // Expense / income per day (all currencies summed per currency).
    final expense = <DateTime, int>{};
    final income = <DateTime, int>{};
    for (final v in transactions) {
      final t = v.transaction;
      if (v.transfer != null || !t.confirmed || !t.countInTotal) continue;
      final d = dateOnly(t.date);
      if (t.isIncome) {
        income[d] = (income[d] ?? 0) + t.money;
      } else {
        expense[d] = (expense[d] ?? 0) + t.money;
      }
    }
    final maxExpense = expense.values.fold<int>(0, (a, b) => a > b ? a : b);
    final firstDay = settings.firstDayOfWeek;
    final leading = (_month.weekday - firstDay + 7) % 7;
    final days = daysInMonth(_month.year, _month.month);
    final names = DateFormat.E(context.localeName).dateSymbols.NARROWWEEKDAYS;
    final dayTransactions = transactions
        .where((v) => dateOnly(v.transaction.date) == _selected)
        .toList();
    final currency = repo.currenciesFor(wallet).firstOrNull ?? 'EUR';

    return Scaffold(
      appBar: AppBar(title: Text(l.calendar)),
      body: Column(
        children: [
          Row(
            children: [
              IconButton(onPressed: () => _shift(-1), icon: const Icon(Icons.chevron_left)),
              Expanded(
                child: Text(context.formatMonth(_month),
                    textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
              ),
              IconButton(onPressed: () => _shift(1), icon: const Icon(Icons.chevron_right)),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: Center(
                      child: Text(names[(firstDay + i) % 7],
                          style: theme.textTheme.labelSmall),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: .9,
              children: [
                for (var i = 0; i < leading; i++) const SizedBox(),
                for (var day = 1; day <= days; day++)
                  Builder(builder: (context) {
                    final date = DateTime(_month.year, _month.month, day);
                    final spent = expense[date] ?? 0;
                    final intensity = maxExpense == 0 ? 0.0 : spent / maxExpense;
                    final selected = date == _selected;
                    final today = date == dateOnly(DateTime.now());
                    return Padding(
                      padding: const EdgeInsets.all(2),
                      child: Material(
                        color: spent == 0
                            ? Colors.transparent
                            : Color.lerp(settings.expenseColor.withValues(alpha: .08),
                                settings.expenseColor.withValues(alpha: .55), intensity),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: selected
                              ? BorderSide(color: theme.colorScheme.primary, width: 2)
                              : today
                                  ? BorderSide(color: theme.colorScheme.outline)
                                  : BorderSide.none,
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => setState(() => _selected = date),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('$day', style: theme.textTheme.bodyMedium),
                              if (income[date] != null)
                                Container(
                                  width: 5,
                                  height: 5,
                                  margin: const EdgeInsets.only(top: 2),
                                  decoration: BoxDecoration(
                                      color: settings.incomeColor,
                                      shape: BoxShape.circle),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            title: Text(context.formatDate(_selected),
                style: theme.textTheme.titleSmall),
            trailing: (expense[_selected] ?? 0) == 0
                ? null
                : MoneyText(-(expense[_selected] ?? 0), currency),
          ),
          Expanded(
            child: dayTransactions.isEmpty
                ? EmptyState(icon: Icons.event_available, title: l.emptyList)
                : ListView(
                    children: [
                      for (final v in dayTransactions)
                        TransactionTile(v, showWallet: wallet == null),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
