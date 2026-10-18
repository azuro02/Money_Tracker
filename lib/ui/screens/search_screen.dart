import 'package:flutter/material.dart';

import '../../core/calculator.dart';
import '../../core/dates.dart';
import '../../data/repository.dart';
import '../scope.dart';
import '../widgets/common.dart';
import '../widgets/pickers.dart';
import '../widgets/transaction_list.dart';

/// Full text search with field and range filters.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _query = TextEditingController();
  Set<SearchField> _fields = SearchField.values.toSet();
  String? _wallet;
  DateTime? _from;
  DateTime? _to;
  String _min = '';
  String _max = '';
  bool _showFilters = false;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  String _fieldLabel(SearchField f) {
    final l = context.l10n;
    return switch (f) {
      SearchField.description => l.description,
      SearchField.category => l.category,
      SearchField.date => l.date,
      SearchField.money => l.amount,
      SearchField.note => l.note,
      SearchField.event => l.event,
      SearchField.place => l.place,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final repo = context.repo;
    final hasCriteria = _query.text.trim().isNotEmpty ||
        _from != null ||
        _to != null ||
        _min.isNotEmpty ||
        _max.isNotEmpty ||
        _wallet != null;
    // Amount filters use 2 decimals for the comparison; exact enough for
    // filtering and independent of the currency.
    int? amount(String s) => s.trim().isEmpty ? null : evaluateAmount(s, 2);
    final results = !hasCriteria
        ? const []
        : repo.transactions(TransactionFilter(
            wallet: _wallet,
            query: _query.text,
            searchFields: _fields.toList(),
            start: _from,
            end: _to == null ? null : addDays(_to!, 1),
            minMoney: amount(_min),
            maxMoney: amount(_max),
            // Search is not about balances: include every wallet.
            allWallets: true,
          ));
    final wallet = _wallet == null ? null : repo.wallet(_wallet!);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _query,
          autofocus: true,
          decoration: InputDecoration(
            hintText: l.searchHint,
            border: InputBorder.none,
            filled: false,
          ),
          onChanged: (_) => setState(() {}),
        ),
        actions: [
          if (_query.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => setState(_query.clear),
            ),
          IconButton(
            isSelected: _showFilters,
            icon: const Icon(Icons.tune),
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
        ],
      ),
      body: Column(
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: !_showFilters
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.searchIn, style: Theme.of(context).textTheme.labelLarge),
                        Wrap(
                          spacing: 6,
                          children: [
                            for (final f in SearchField.values)
                              FilterChip(
                                label: Text(_fieldLabel(f)),
                                selected: _fields.contains(f),
                                onSelected: (v) => setState(() => _fields = v
                                    ? {..._fields, f}
                                    : ({..._fields}..remove(f))),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            InputChip(
                              avatar: const Icon(Icons.account_balance_wallet_outlined, size: 18),
                              label: Text(wallet?.name ?? l.totalWallet),
                              onPressed: () async {
                                final w = await pickWallet(context);
                                if (w != null) setState(() => _wallet = w.uuid);
                              },
                              onDeleted: _wallet == null
                                  ? null
                                  : () => setState(() => _wallet = null),
                            ),
                            InputChip(
                              avatar: const Icon(Icons.event, size: 18),
                              label: Text(_from == null
                                  ? l.fromDate
                                  : '${l.fromDate} ${context.formatShortDate(_from!)}'),
                              onPressed: () async {
                                final d = await pickDate(context, _from ?? DateTime.now());
                                if (d != null) setState(() => _from = d);
                              },
                              onDeleted:
                                  _from == null ? null : () => setState(() => _from = null),
                            ),
                            InputChip(
                              avatar: const Icon(Icons.event, size: 18),
                              label: Text(_to == null
                                  ? l.toDate
                                  : '${l.toDate} ${context.formatShortDate(_to!)}'),
                              onPressed: () async {
                                final d = await pickDate(context, _to ?? DateTime.now());
                                if (d != null) setState(() => _to = d);
                              },
                              onDeleted: _to == null ? null : () => setState(() => _to = null),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                keyboardType:
                                    const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                    labelText: l.minAmount, isDense: true),
                                onChanged: (v) => setState(() => _min = v),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                keyboardType:
                                    const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                    labelText: l.maxAmount, isDense: true),
                                onChanged: (v) => setState(() => _max = v),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
          ),
          if (hasCriteria)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(l.results(results.length),
                    style: Theme.of(context).textTheme.labelLarge),
              ),
            ),
          Expanded(
            child: !hasCriteria
                ? EmptyState(icon: Icons.search, title: l.searchHint)
                : ListView.builder(
                    itemCount: results.length,
                    itemBuilder: (context, i) => TransactionTile(
                        results[i], showWallet: true, showDate: true),
                  ),
          ),
        ],
      ),
    );
  }
}
