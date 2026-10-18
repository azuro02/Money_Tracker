import 'package:flutter/material.dart';

import '../../core/app_icon.dart';
import '../../data/models.dart';
import '../scope.dart';
import '../widgets/common.dart';
import '../widgets/recurrence_picker.dart';
import 'transaction_editor.dart';
import 'transfer_editor.dart';

class RecurrencesScreen extends StatelessWidget {
  const RecurrencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final repo = context.repo;
    final transactions = repo.recurrentTransactions();
    final transfers = repo.recurrentTransfers();
    String next(DateTime? d) =>
        d == null ? l.recurrenceFinished : l.nextOccurrence(context.formatDate(d));
    return DefaultTabController(
      length: 2,
      child: Builder(builder: (context) {
        return Scaffold(
          appBar: AppBar(
            title: Text(l.recurrences),
            bottom: TabBar(tabs: [Tab(text: l.transactions), Tab(text: l.transfers)]),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => DefaultTabController.of(context).index == 0
                ? openTransactionEditor(context, kind: EditorKind.recurrent)
                : openTransferEditor(context, recurrent: true),
            child: const Icon(Icons.add),
          ),
          body: TabBarView(
            children: [
              transactions.isEmpty
                  ? EmptyState(icon: Icons.repeat, title: l.emptyList)
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 96),
                      children: [
                        for (final r in transactions)
                          Builder(builder: (context) {
                            final category = repo.category(r.category);
                            final wallet = repo.wallet(r.wallet);
                            return ListTile(
                              leading: IconAvatar(category?.icon ?? AppIcon.fallback),
                              title: Text(r.description?.isNotEmpty == true
                                  ? r.description!
                                  : (category == null
                                      ? ''
                                      : context.categoryName(
                                          category.name, category.tag, category.type))),
                              subtitle: Text(
                                  '${describeRule(context, r.rule)}\n${next(r.nextOccurrence)}'),
                              isThreeLine: true,
                              trailing: MoneyText(
                                r.direction == Direction.income ? r.money : -r.money,
                                wallet?.currency ?? '',
                                muted: r.nextOccurrence == null,
                              ),
                              onTap: () => openTransactionEditor(context,
                                  uuid: r.uuid, kind: EditorKind.recurrent),
                            );
                          }),
                      ],
                    ),
              transfers.isEmpty
                  ? EmptyState(icon: Icons.repeat, title: l.emptyList)
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 96),
                      children: [
                        for (final r in transfers)
                          ListTile(
                            leading: const CircleAvatar(child: Icon(Icons.swap_horiz)),
                            title: Text(r.description?.isNotEmpty == true
                                ? r.description!
                                : '${repo.wallet(r.fromWallet)?.name} → ${repo.wallet(r.toWallet)?.name}'),
                            subtitle: Text(
                                '${describeRule(context, r.rule)}\n${next(r.nextOccurrence)}'),
                            isThreeLine: true,
                            trailing: Text(context.formatMoney(
                                r.fromMoney, repo.wallet(r.fromWallet)?.currency ?? '')),
                            onTap: () =>
                                openTransferEditor(context, recurrenceUuid: r.uuid),
                          ),
                      ],
                    ),
            ],
          ),
        );
      }),
    );
  }
}

class ModelsScreen extends StatelessWidget {
  const ModelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final repo = context.repo;
    final models = repo.transactionModels();
    final transferModels = repo.transferModels();
    return DefaultTabController(
      length: 2,
      child: Builder(builder: (context) {
        return Scaffold(
          appBar: AppBar(
            title: Text(l.models),
            bottom: TabBar(tabs: [Tab(text: l.transactions), Tab(text: l.transfers)]),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => DefaultTabController.of(context).index == 0
                ? openTransactionEditor(context, kind: EditorKind.model)
                : openTransferEditor(context, model: true),
            child: const Icon(Icons.add),
          ),
          body: TabBarView(
            children: [
              models.isEmpty
                  ? EmptyState(icon: Icons.bookmarks_outlined, title: l.emptyList)
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 96),
                      children: [
                        for (final m in models)
                          Builder(builder: (context) {
                            final category = repo.category(m.category);
                            return ListTile(
                              leading: IconAvatar(category?.icon ?? AppIcon.fallback),
                              title: Text(m.description?.isNotEmpty == true
                                  ? m.description!
                                  : category?.name ?? ''),
                              subtitle: Text(repo.wallet(m.wallet)?.name ?? ''),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  MoneyText(
                                    m.direction == Direction.income ? m.money : -m.money,
                                    repo.wallet(m.wallet)?.currency ?? '',
                                  ),
                                  IconButton(
                                    tooltip: l.newTransaction,
                                    icon: const Icon(Icons.add_circle_outline),
                                    onPressed: () =>
                                        openTransactionEditor(context, template: m),
                                  ),
                                ],
                              ),
                              onTap: () => openTransactionEditor(context,
                                  uuid: m.uuid, kind: EditorKind.model),
                            );
                          }),
                      ],
                    ),
              transferModels.isEmpty
                  ? EmptyState(icon: Icons.bookmarks_outlined, title: l.emptyList)
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 96),
                      children: [
                        for (final m in transferModels)
                          ListTile(
                            leading: const CircleAvatar(child: Icon(Icons.swap_horiz)),
                            title: Text(m.description?.isNotEmpty == true
                                ? m.description!
                                : '${repo.wallet(m.fromWallet)?.name} → ${repo.wallet(m.toWallet)?.name}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(context.formatMoney(
                                    m.fromMoney, repo.wallet(m.fromWallet)?.currency ?? '')),
                                IconButton(
                                  tooltip: l.newTransfer,
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      fullscreenDialog: true,
                                      builder: (_) => TransferEditor(template: m),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            onTap: () => openTransferEditor(context, modelUuid: m.uuid),
                          ),
                      ],
                    ),
            ],
          ),
        );
      }),
    );
  }
}
