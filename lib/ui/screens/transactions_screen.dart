import 'package:flutter/material.dart';

import '../../data/repository.dart';
import '../scope.dart';
import '../widgets/common.dart';
import '../widgets/transaction_list.dart';
import '../widgets/wallet_selector.dart';
import 'calendar_screen.dart';
import 'search_screen.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final services = context.services;
    final wallet = services.settings.currentWallet;
    final transactions =
        services.repo.transactions(TransactionFilter(wallet: wallet));
    final transfers = services.repo.transfers(wallet: wallet);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const WalletSelector(),
          actions: [
            IconButton(
              tooltip: l.calendar,
              icon: const Icon(Icons.calendar_month),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const CalendarScreen())),
            ),
            IconButton(
              tooltip: l.search,
              icon: const Icon(Icons.search),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SearchScreen())),
            ),
          ],
          bottom: TabBar(tabs: [
            Tab(text: l.transactions),
            Tab(text: l.transfers),
          ]),
        ),
        body: TabBarView(
          children: [
            transactions.isEmpty
                ? EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: l.noTransactions,
                    subtitle: l.noTransactionsHint,
                  )
                : GroupedTransactionList(
                    transactions: transactions,
                    showWallet: wallet == null,
                  ),
            transfers.isEmpty
                ? EmptyState(icon: Icons.swap_horiz, title: l.emptyList)
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 96),
                    itemCount: transfers.length,
                    itemBuilder: (context, i) => TransferTile(transfers[i]),
                  ),
          ],
        ),
      ),
    );
  }
}

/// Transactions matching a filter (category, event, person, place, debt).
class TransactionListScreen extends StatelessWidget {
  const TransactionListScreen({
    super.key,
    required this.title,
    required this.filter,
  });

  final String title;
  final TransactionFilter filter;

  @override
  Widget build(BuildContext context) {
    final transactions = context.repo.transactions(filter);
    final totals = <String, int>{};
    for (final v in transactions) {
      final t = v.transaction;
      if (t.confirmed && t.countInTotal && !t.date.isAfter(DateTime.now())) {
        totals[v.currency] = (totals[v.currency] ?? 0) + t.signedMoney;
      }
    }
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: transactions.isEmpty
          ? EmptyState(icon: Icons.receipt_long_outlined, title: context.l10n.emptyList)
          : GroupedTransactionList(
              transactions: transactions,
              header: totals.isEmpty
                  ? null
                  : ListTile(
                      title: Text(context.l10n.total),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (final e in totals.entries)
                            MoneyText(e.value, e.key, signed: true),
                        ],
                      ),
                    ),
            ),
    );
  }
}
