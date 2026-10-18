import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/dates.dart';
import '../../data/models.dart';
import '../scope.dart';
import '../screens/transaction_editor.dart';
import '../screens/transfer_editor.dart';
import 'common.dart';

/// Human readable label of a period depending on the group type.
String periodLabel(BuildContext context, Period p, GroupType group) {
  final locale = context.localeName;
  switch (group) {
    case GroupType.daily:
      return context.formatDate(p.start);
    case GroupType.weekly:
      return '${DateFormat.MMMd(locale).format(p.start)} – '
          '${DateFormat.yMMMd(locale).format(p.lastDay)}';
    case GroupType.monthly:
      if (p.start.day == 1 && p.end.day == 1) {
        return DateFormat.yMMMM(locale).format(p.start);
      }
      return '${DateFormat.MMMd(locale).format(p.start)} – '
          '${DateFormat.yMMMd(locale).format(p.lastDay)}';
    case GroupType.yearly:
      return DateFormat.y(locale).format(p.start);
  }
}

class TransactionTile extends StatelessWidget {
  const TransactionTile(this.view, {super.key, this.showWallet = true, this.showDate = false});

  final TransactionView view;
  final bool showWallet;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final t = view.transaction;
    final l = context.l10n;
    final now = DateTime.now();
    final future = t.date.isAfter(now);
    final category = context.categoryName(
        view.categoryName, view.categoryTag, view.categoryType);
    final title = (t.description == null || t.description!.isEmpty)
        ? category
        : t.description!;
    final parts = <String>[
      if (title != category) category,
      if (showWallet) view.walletName,
      if (showDate) context.formatShortDate(t.date),
    ];
    final theme = Theme.of(context);
    final flags = <Widget>[
      if (future) _Flag(l.planned, theme.colorScheme.tertiary),
      if (!t.confirmed) _Flag(l.unconfirmed, theme.colorScheme.outline),
    ];
    return ListTile(
      leading: IconAvatar(view.categoryIcon),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Row(
        children: [
          ...flags,
          Expanded(
            child: Text(parts.join(' · '),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
      trailing: MoneyText(
        t.signedMoney,
        view.currency,
        muted: future || !t.confirmed || !t.countInTotal,
        style: theme.textTheme.titleSmall,
      ),
      onTap: () => openTransactionView(context, view),
    );
  }
}

/// Opens the right editor for a transaction (transfers have their own).
void openTransactionView(BuildContext context, TransactionView view) {
  if (view.transfer != null) {
    openTransferEditor(context, transferUuid: view.transfer);
  } else {
    openTransactionEditor(context, uuid: view.transaction.uuid);
  }
}

class _Flag extends StatelessWidget {
  const _Flag(this.text, this.color);

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(text,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color)),
      );
}

/// A list of transactions grouped by period with per-period totals.
class GroupedTransactionList extends StatelessWidget {
  const GroupedTransactionList({
    super.key,
    required this.transactions,
    this.showWallet = true,
    this.padding = const EdgeInsets.only(bottom: 96),
    this.header,
  });

  final List<TransactionView> transactions;
  final bool showWallet;
  final EdgeInsets padding;
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    final settings = context.settings;
    final group = settings.groupType;
    final items = <Object>[];
    Period? current;
    var totals = <String, int>{};
    var headerIndex = -1;
    void closeGroup() {
      if (headerIndex >= 0) {
        items[headerIndex] = (items[headerIndex] as _Header).withTotals(totals);
      }
    }

    for (final v in transactions) {
      final t = v.transaction;
      if (current == null || !current.contains(t.date)) {
        closeGroup();
        current = periodFor(t.date, group,
            firstDayOfWeek: settings.firstDayOfWeek,
            firstDayOfMonth: settings.firstDayOfMonth);
        totals = {};
        headerIndex = items.length;
        items.add(_Header(current, const {}));
      }
      if (t.confirmed && t.countInTotal && v.transfer == null) {
        totals[v.currency] = (totals[v.currency] ?? 0) + t.signedMoney;
      }
      items.add(v);
    }
    closeGroup();
    final hasHeader = header != null;
    return ListView.builder(
      padding: padding,
      itemCount: items.length + (hasHeader ? 1 : 0),
      itemBuilder: (context, index) {
        if (hasHeader && index == 0) return header!;
        final item = items[index - (hasHeader ? 1 : 0)];
        if (item is _Header) {
          return _PeriodHeader(item, group);
        }
        return TransactionTile(item as TransactionView, showWallet: showWallet,
            showDate: group != GroupType.daily);
      },
    );
  }
}

class _Header {
  const _Header(this.period, this.totals);

  final Period period;
  final Map<String, int> totals;

  _Header withTotals(Map<String, int> t) => _Header(period, Map.of(t));
}

class _PeriodHeader extends StatelessWidget {
  const _PeriodHeader(this.header, this.group);

  final _Header header;
  final GroupType group;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Row(
        children: [
          Expanded(
            child: Text(periodLabel(context, header.period, group),
                style: theme.textTheme.titleSmall
                    ?.copyWith(color: theme.colorScheme.primary)),
          ),
          for (final e in header.totals.entries)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: MoneyText(e.value, e.key,
                  signed: true, style: theme.textTheme.labelLarge),
            ),
        ],
      ),
    );
  }
}

class TransferTile extends StatelessWidget {
  const TransferTile(this.view, {super.key});

  final TransferView view;

  @override
  Widget build(BuildContext context) {
    final t = view.transfer;
    final theme = Theme.of(context);
    final same = view.fromCurrency == view.toCurrency &&
        view.fromMoney == view.toMoney;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.secondaryContainer,
        child: Icon(Icons.swap_horiz, color: theme.colorScheme.onSecondaryContainer),
      ),
      title: Text('${view.fromWalletName} → ${view.toWalletName}',
          maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        [
          if (t.description != null && t.description!.isNotEmpty) t.description!,
          context.formatDate(t.date),
        ].join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(context.formatMoney(view.fromMoney, view.fromCurrency),
              style: theme.textTheme.titleSmall),
          if (!same)
            Text('→ ${context.formatMoney(view.toMoney, view.toCurrency)}',
                style: theme.textTheme.bodySmall),
          if (view.taxMoney > 0)
            Text('+ ${context.formatMoney(view.taxMoney, view.fromCurrency)}',
                style: theme.textTheme.bodySmall),
        ],
      ),
      onTap: () => openTransferEditor(context, transferUuid: t.uuid),
    );
  }
}
