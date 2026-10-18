import 'package:flutter/material.dart';

import '../scope.dart';
import 'dashboard_screen.dart';
import 'more_screen.dart';
import 'stats_screen.dart';
import 'transaction_editor.dart';
import 'transactions_screen.dart';

/// Main navigation: bottom bar on phones, navigation rail on tablets.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read.ensureDefaultCategories(context.l10n);
    });
  }

  void _select(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final destinations = [
      (Icons.space_dashboard_outlined, Icons.space_dashboard, l.navOverview),
      (Icons.receipt_long_outlined, Icons.receipt_long, l.navTransactions),
      (Icons.insights_outlined, Icons.insights, l.navStatistics),
      (Icons.menu, Icons.menu_open, l.navMore),
    ];
    final pages = [
      DashboardScreen(onShowAll: () => _select(1)),
      const TransactionsScreen(),
      const StatsScreen(),
      const MoreScreen(),
    ];
    final fab = _index <= 1
        ? FloatingActionButton.extended(
            heroTag: 'add',
            onPressed: () => openTransactionEditor(context),
            icon: const Icon(Icons.add),
            label: Text(l.newTransaction),
          )
        : null;
    final wide = MediaQuery.sizeOf(context).width >= 720;
    final body = IndexedStack(index: _index, children: pages);
    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: _select,
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: fab == null
                    ? const SizedBox(height: 56)
                    : FloatingActionButton(
                        heroTag: 'add-rail',
                        elevation: 0,
                        onPressed: () => openTransactionEditor(context),
                        child: const Icon(Icons.add),
                      ),
              ),
              destinations: [
                for (final d in destinations)
                  NavigationRailDestination(
                    icon: Icon(d.$1),
                    selectedIcon: Icon(d.$2),
                    label: Text(d.$3),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: body),
          ],
        ),
      );
    }
    return Scaffold(
      body: body,
      floatingActionButton: fab,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _select,
        destinations: [
          for (final d in destinations)
            NavigationDestination(
              icon: Icon(d.$1),
              selectedIcon: Icon(d.$2),
              label: d.$3,
            ),
        ],
      ),
    );
  }
}
