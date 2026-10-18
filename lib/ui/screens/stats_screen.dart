import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/app_icon.dart';
import '../../core/dates.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../../domain/statistics.dart';
import '../scope.dart';
import '../widgets/common.dart';
import '../widgets/pickers.dart';
import '../widgets/transaction_list.dart';
import '../widgets/wallet_selector.dart';
import 'transactions_screen.dart';

const _fallbackPalette = <Color>[
  Color(0xFF5C6BC0), Color(0xFF26A69A), Color(0xFFFFA726), Color(0xFFEF5350),
  Color(0xFFAB47BC), Color(0xFF42A5F5), Color(0xFF9CCC65), Color(0xFF8D6E63),
  Color(0xFFEC407A), Color(0xFF78909C),
];

Color _categoryColor(Category? c, int index) {
  final icon = c?.icon;
  if (icon is ColorIcon) return Color(icon.argb);
  return _fallbackPalette[index % _fallbackPalette.length];
}

double _pow10(int decimals) => math.pow(10, decimals).toDouble();

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  String? _currency;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final repo = context.repo;
    final wallet = context.settings.currentWallet;
    final currencies = repo.currenciesFor(wallet);
    if (_currency == null || !currencies.contains(_currency)) {
      _currency = currencies.firstOrNull;
    }
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const WalletSelector(),
          bottom: TabBar(tabs: [
            Tab(text: l.statsMonth),
            Tab(text: l.statsTrend),
            Tab(text: l.statsCustom),
          ]),
        ),
        body: _currency == null
            ? EmptyState(icon: Icons.insights, title: l.noData)
            : Column(
                children: [
                  if (currencies.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Wrap(
                        spacing: 8,
                        children: [
                          for (final c in currencies)
                            ChoiceChip(
                              label: Text(c),
                              selected: c == _currency,
                              onSelected: (_) => setState(() => _currency = c),
                            ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: TabBarView(children: [
                      _MonthTab(currency: _currency!, wallet: wallet),
                      _TrendTab(currency: _currency!, wallet: wallet),
                      _CustomTab(currency: _currency!, wallet: wallet),
                    ]),
                  ),
                ],
              ),
      ),
    );
  }
}

// ------------------------------------------------------------------ month

class _MonthTab extends StatefulWidget {
  const _MonthTab({required this.currency, required this.wallet});

  final String currency;
  final String? wallet;

  @override
  State<_MonthTab> createState() => _MonthTabState();
}

class _MonthTabState extends State<_MonthTab> with AutomaticKeepAliveClientMixin {
  DateTime _anchor = DateTime.now();
  int _direction = Direction.expense;
  String? _drill;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l = context.l10n;
    final services = context.services;
    final settings = services.settings;
    final repo = services.repo;
    final theme = Theme.of(context);
    final now = DateTime.now();
    final fdm = settings.firstDayOfMonth;
    final month = monthPeriod(_anchor, firstDayOfMonth: fdm);
    final previous = StatisticsService.previousMonths(month, 3, firstDayOfMonth: fdm);
    final range = Period(previous.last.start, month.end);
    final entries = StatisticsService.forCurrency(
        StatisticsService(repo).load(wallet: widget.wallet, range: range, now: now),
        widget.currency);
    final summary = StatisticsService.summary(entries, month, now: now);
    final categories = {for (final c in repo.categories(includeHidden: true)) c.uuid: c};
    final breakdown = StatisticsService.byCategory(entries, month,
        direction: _direction, parent: _drill);
    final comparison = StatisticsService.compareCategories(entries, month, previous)
        .where((c) => c.current > 0 || c.previous > 0)
        .take(8)
        .toList();
    final isCurrent = month.contains(now);
    final cumulative = StatisticsService.cumulativeDaily(entries, month,
        until: isCurrent ? now : null);
    final cumulativePrev = StatisticsService.cumulativeDaily(entries, previous.first);
    final top = StatisticsService.topExpenses(entries, month, limit: 5);
    final daily = StatisticsService.dailyExpenses(entries, month);
    final decimals = repo.currency(widget.currency)?.decimals ?? 2;
    final label = month.start.day == 1
        ? context.formatMonth(month.start)
        : periodLabel(context, month, GroupType.monthly);

    String name(String uuid) {
      final c = categories[uuid];
      if (c == null) return '?';
      final n = context.categoryName(c.name, c.tag, c.type);
      return _drill != null && uuid == _drill ? '$n ${l.direct}' : n;
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => setState(() {
                _anchor = addDays(month.start, -1);
                _drill = null;
              }),
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(label,
                  textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
            ),
            IconButton(
              onPressed: isCurrent
                  ? null
                  : () => setState(() {
                        _anchor = month.end;
                        _drill = null;
                      }),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        // Summary
        InfoCard(
          child: Column(
            children: [
              Row(
                children: [
                  _Figure(l.incomes, summary.income, widget.currency),
                  _Figure(l.expenses, -summary.expense, widget.currency),
                  _Figure(l.net, summary.net, widget.currency, signed: true),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  _Kpi(
                    l.savingsRate,
                    summary.savingsRate == null
                        ? '–'
                        : '${(summary.savingsRate! * 100).toStringAsFixed(0)} %',
                  ),
                  _Kpi(l.avgPerDay,
                      context.formatMoney(summary.averageDailyExpense.round(), widget.currency)),
                  if (isCurrent)
                    _Kpi(l.projection,
                        context.formatMoney(summary.projectedExpense, widget.currency),
                        tooltip: l.projectionHint),
                ],
              ),
            ],
          ),
        ),
        // Category donut
        InfoCard(
          title: _direction == Direction.expense ? l.expensesByCategory : l.incomeByCategory,
          trailing: SegmentedButton<int>(
            showSelectedIcon: false,
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
            segments: [
              ButtonSegment(value: Direction.expense, icon: const Icon(Icons.remove, size: 16)),
              ButtonSegment(value: Direction.income, icon: const Icon(Icons.add, size: 16)),
            ],
            selected: {_direction},
            onSelectionChanged: (s) => setState(() {
              _direction = s.first;
              _drill = null;
            }),
          ),
          child: breakdown.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(l.noData, textAlign: TextAlign.center),
                )
              : Column(
                  children: [
                    if (_drill != null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: InputChip(
                          avatar: const Icon(Icons.arrow_back, size: 16),
                          label: Text(name(_drill!).replaceAll(' ${l.direct}', '')),
                          onPressed: () => setState(() => _drill = null),
                        ),
                      ),
                    SizedBox(
                      height: 200,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 62,
                              sections: [
                                for (var i = 0; i < breakdown.length; i++)
                                  PieChartSectionData(
                                    value: breakdown[i].amount.toDouble(),
                                    color: _categoryColor(categories[breakdown[i].category], i),
                                    radius: 34,
                                    showTitle: false,
                                  ),
                              ],
                              pieTouchData: PieTouchData(
                                touchCallback: (event, response) {
                                  if (event is! FlTapUpEvent) return;
                                  final i = response?.touchedSection?.touchedSectionIndex;
                                  if (i == null || i < 0 || i >= breakdown.length) return;
                                  _drillInto(breakdown[i].category, categories);
                                },
                              ),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(l.total, style: theme.textTheme.labelMedium),
                              Text(
                                context.formatMoney(
                                    breakdown.fold(0, (s, c) => s + c.amount),
                                    widget.currency),
                                style: theme.textTheme.titleMedium,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (var i = 0; i < breakdown.length; i++)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 8,
                          backgroundColor:
                              _categoryColor(categories[breakdown[i].category], i),
                        ),
                        title: Text(name(breakdown[i].category)),
                        subtitle: LinearProgressIndicator(
                          value: breakdown[i].share,
                          color: _categoryColor(categories[breakdown[i].category], i),
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(context.formatMoney(breakdown[i].amount, widget.currency)),
                            Text('${(breakdown[i].share * 100).toStringAsFixed(1)} %',
                                style: theme.textTheme.bodySmall),
                          ],
                        ),
                        onTap: () => _drillInto(breakdown[i].category, categories,
                            month: month),
                      ),
                  ],
                ),
        ),
        // Comparison
        if (comparison.isNotEmpty && _direction == Direction.expense)
          InfoCard(
            title: l.comparison,
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(child: SizedBox()),
                    SizedBox(
                        width: 84,
                        child: Text(l.vsLastMonth,
                            textAlign: TextAlign.end, style: theme.textTheme.labelSmall)),
                    SizedBox(
                        width: 84,
                        child: Text(l.vsAverage,
                            textAlign: TextAlign.end, style: theme.textTheme.labelSmall)),
                  ],
                ),
                for (final c in comparison)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        IconAvatar(categories[c.category]?.icon ?? AppIcon.fallback, size: 28),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name(c.category), maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text(context.formatMoney(c.current, widget.currency),
                                  style: theme.textTheme.bodySmall),
                            ],
                          ),
                        ),
                        SizedBox(width: 84, child: _Delta(c.changeVsPrevious)),
                        SizedBox(width: 84, child: _Delta(c.changeVsAverage)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        // Cumulative spending
        InfoCard(
          title: l.cumulativeSpending,
          child: Column(
            children: [
              SizedBox(
                height: 200,
                child: _CumulativeChart(
                  current: cumulative,
                  previous: cumulativePrev,
                  decimals: decimals,
                  days: month.lengthInDays,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Legend(theme.colorScheme.primary, label),
                  const SizedBox(width: 16),
                  _Legend(theme.colorScheme.outline, l.lastMonth),
                ],
              ),
            ],
          ),
        ),
        // Daily spending
        if (daily.isNotEmpty)
          InfoCard(
            title: l.dailySpending,
            child: SizedBox(
              height: 140,
              child: _DailyBars(
                period: month,
                values: daily,
                decimals: decimals,
                color: settings.expenseColor,
              ),
            ),
          ),
        // Top expenses
        if (top.isNotEmpty)
          InfoCard(
            title: l.topExpenses,
            padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
            child: Column(
              children: [
                for (final e in top)
                  Builder(builder: (context) {
                    final view = repo.transactionView(e.uuid);
                    return view == null ? const SizedBox() : TransactionTile(view, showDate: true);
                  }),
              ],
            ),
          ),
      ],
    );
  }

  void _drillInto(String category, Map<String, Category> categories, {Period? month}) {
    final hasChildren = categories.values.any((c) => c.parent == category);
    if (_drill == null && hasChildren) {
      setState(() => _drill = category);
      return;
    }
    if (month == null) return;
    final c = categories[category];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TransactionListScreen(
          title: c == null ? '' : context.categoryName(c.name, c.tag, c.type),
          filter: TransactionFilter(
            wallet: widget.wallet,
            category: category,
            start: month.start,
            end: month.end,
            onlyCounted: true,
          ),
        ),
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure(this.label, this.value, this.currency, {this.signed = false});

  final String label;
  final int value;
  final String currency;
  final bool signed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Text(label, style: theme.textTheme.labelMedium),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: MoneyText(value, currency, signed: signed, style: theme.textTheme.titleMedium),
          ),
        ],
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi(this.label, this.value, {this.tooltip});

  final String label;
  final String value;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final child = Column(
      children: [
        Text(label, style: theme.textTheme.labelSmall),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value, style: theme.textTheme.titleSmall),
        ),
      ],
    );
    return Expanded(
      child: tooltip == null ? child : Tooltip(message: tooltip, child: child),
    );
  }
}

class _Delta extends StatelessWidget {
  const _Delta(this.change);

  final double? change;

  @override
  Widget build(BuildContext context) {
    final settings = context.settings;
    final theme = Theme.of(context);
    if (change == null) {
      return Text('–', textAlign: TextAlign.end, style: theme.textTheme.bodySmall);
    }
    // For expenses an increase is bad.
    final up = change! > 0;
    final color = change!.abs() < .005
        ? theme.colorScheme.onSurfaceVariant
        : (up ? settings.expenseColor : settings.incomeColor);
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Icon(up ? Icons.arrow_upward : Icons.arrow_downward, size: 14, color: color),
        Text('${(change!.abs() * 100).toStringAsFixed(0)} %',
            style: theme.textTheme.bodySmall?.copyWith(color: color)),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend(this.color, this.label);

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 12, height: 3, color: color),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      );
}

FlTitlesData _titles(BuildContext context,
    {required String Function(double) bottom, double? bottomInterval}) {
  final compact = NumberFormat.compact(locale: context.localeName);
  return FlTitlesData(
    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    leftTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 44,
        getTitlesWidget: (value, meta) => value == meta.max || value == meta.min && value != 0
            ? const SizedBox()
            : Text(compact.format(value), style: Theme.of(context).textTheme.labelSmall),
      ),
    ),
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 22,
        interval: bottomInterval,
        getTitlesWidget: (value, meta) => Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(bottom(value), style: Theme.of(context).textTheme.labelSmall),
        ),
      ),
    ),
  );
}

class _CumulativeChart extends StatelessWidget {
  const _CumulativeChart({
    required this.current,
    required this.previous,
    required this.decimals,
    required this.days,
  });

  final List<int> current;
  final List<int> previous;
  final int decimals;
  final int days;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final f = _pow10(decimals);
    List<FlSpot> spots(List<int> values) => [
          for (var i = 0; i < values.length; i++) FlSpot(i + 1, values[i] / f),
        ];
    return LineChart(
      LineChartData(
        minX: 1,
        maxX: days.toDouble(),
        minY: 0,
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: theme.colorScheme.outlineVariant, strokeWidth: .5),
        ),
        borderData: FlBorderData(show: false),
        titlesData: _titles(context,
            bottom: (v) => v == v.roundToDouble() ? '${v.toInt()}' : '',
            bottomInterval: 7),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots(previous),
            color: theme.colorScheme.outline,
            barWidth: 2,
            dashArray: [4, 4],
            dotData: const FlDotData(show: false),
          ),
          LineChartBarData(
            spots: spots(current),
            color: theme.colorScheme.primary,
            barWidth: 3,
            isCurved: false,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: theme.colorScheme.primary.withValues(alpha: .12),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyBars extends StatelessWidget {
  const _DailyBars({
    required this.period,
    required this.values,
    required this.decimals,
    required this.color,
  });

  final Period period;
  final Map<DateTime, int> values;
  final int decimals;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final f = _pow10(decimals);
    final days = period.lengthInDays;
    return BarChart(
      BarChartData(
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, _, rod, _) => BarTooltipItem(
              '${context.formatShortDate(addDays(period.start, group.x))}\n'
              '${NumberFormat.decimalPatternDigits(locale: context.localeName, decimalDigits: decimals).format(rod.toY)}',
              Theme.of(context).textTheme.labelSmall!.copyWith(color: Colors.white),
            ),
          ),
        ),
        titlesData: _titles(context,
            bottom: (v) {
              final d = addDays(period.start, v.toInt());
              return (v.toInt() % 7 == 0) ? '${d.day}' : '';
            }),
        barGroups: [
          for (var i = 0; i < days; i++)
            BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: (values[addDays(period.start, i)] ?? 0) / f,
                color: color,
                width: math.max(2, 220 / days),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
              ),
            ]),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ trend

class _TrendTab extends StatelessWidget {
  const _TrendTab({required this.currency, required this.wallet});

  final String currency;
  final String? wallet;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final services = context.services;
    final settings = services.settings;
    final theme = Theme.of(context);
    final now = DateTime.now();
    final fdm = settings.firstDayOfMonth;
    final current = monthPeriod(now, firstDayOfMonth: fdm);
    final months = [
      ...StatisticsService.previousMonths(current, 11, firstDayOfMonth: fdm).reversed,
      current,
    ];
    final range = Period(months.first.start, current.end);
    final entries = StatisticsService.forCurrency(
        StatisticsService(services.repo).load(wallet: wallet, range: range, now: now),
        currency);
    final flow = StatisticsService.flow(entries, months);
    final decimals = services.repo.currency(currency)?.decimals ?? 2;
    final f = _pow10(decimals);
    final completed = flow.take(flow.length - 1).where((p) => p.income > 0 || p.expense > 0);
    final avgIncome = completed.isEmpty
        ? 0
        : completed.fold<int>(0, (s, p) => s + p.income) ~/ completed.length;
    final avgExpense = completed.isEmpty
        ? 0
        : completed.fold<int>(0, (s, p) => s + p.expense) ~/ completed.length;
    final monthFormat = DateFormat.MMM(context.localeName);

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        InfoCard(
          title: l.last12Months,
          child: Column(
            children: [
              SizedBox(
                height: 240,
                child: BarChart(
                  BarChartData(
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) =>
                          FlLine(color: theme.colorScheme.outlineVariant, strokeWidth: .5),
                    ),
                    titlesData: _titles(context, bottom: (v) {
                      final i = v.toInt();
                      if (i < 0 || i >= months.length) return '';
                      return monthFormat.format(months[i].lastDay).substring(0, 1);
                    }),
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, _, rod, rodIndex) => BarTooltipItem(
                          '${monthFormat.format(months[group.x].lastDay)}\n'
                          '${context.formatMoney((rod.toY * f).round(), currency)}',
                          theme.textTheme.labelSmall!.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                    barGroups: [
                      for (var i = 0; i < flow.length; i++)
                        BarChartGroupData(
                          x: i,
                          barsSpace: 2,
                          barRods: [
                            BarChartRodData(
                              toY: flow[i].income / f,
                              color: settings.incomeColor,
                              width: 7,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                            ),
                            BarChartRodData(
                              toY: flow[i].expense / f,
                              color: settings.expenseColor,
                              width: 7,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Legend(settings.incomeColor, l.incomes),
                  const SizedBox(width: 16),
                  _Legend(settings.expenseColor, l.expenses),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  _Kpi('Ø ${l.incomes}', context.formatMoney(avgIncome, currency)),
                  _Kpi('Ø ${l.expenses}', context.formatMoney(avgExpense, currency)),
                  _Kpi('Ø ${l.net}', context.formatMoney(avgIncome - avgExpense, currency)),
                ],
              ),
            ],
          ),
        ),
        for (final p in flow.reversed)
          ListTile(
            title: Text(p.period.start.day == 1
                ? context.formatMonth(p.period.start)
                : periodLabel(context, p.period, GroupType.monthly)),
            subtitle: Text(
                '${context.formatMoney(p.income, currency)}  ·  ${context.formatMoney(-p.expense, currency)}'),
            trailing: MoneyText(p.net, currency, signed: true),
          ),
      ],
    );
  }
}

// ----------------------------------------------------------------- custom

enum _FlowType { net, income, expense }

/// The configurable overview of the original app: any date range, grouped
/// by day/week/month/year, cash flow or a single category.
class _CustomTab extends StatefulWidget {
  const _CustomTab({required this.currency, required this.wallet});

  final String currency;
  final String? wallet;

  @override
  State<_CustomTab> createState() => _CustomTabState();
}

class _CustomTabState extends State<_CustomTab> with AutomaticKeepAliveClientMixin {
  GroupType? _group;
  Period? _range;
  _FlowType _type = _FlowType.net;
  String? _category;

  @override
  bool get wantKeepAlive => true;

  Period _defaultRange(GroupType group) {
    final settings = context.read.settings;
    final now = DateTime.now();
    return switch (group) {
      GroupType.daily => weekPeriod(now, firstDayOfWeek: settings.firstDayOfWeek),
      GroupType.weekly => monthPeriod(now, firstDayOfMonth: settings.firstDayOfMonth),
      GroupType.monthly => yearPeriod(now),
      GroupType.yearly => Period(DateTime(now.year - 3), DateTime(now.year + 1)),
    };
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l = context.l10n;
    final services = context.services;
    final settings = services.settings;
    final theme = Theme.of(context);
    final group = _group ?? GroupType.monthly;
    final range = _range ?? _defaultRange(group);
    final periods = splitPeriods(range, group,
        firstDayOfWeek: settings.firstDayOfWeek, firstDayOfMonth: settings.firstDayOfMonth);
    final entries = StatisticsService.forCurrency(
        StatisticsService(services.repo).load(wallet: widget.wallet, range: range),
        widget.currency);
    final flow = StatisticsService.flow(entries, periods, category: _category);
    final decimals = services.repo.currency(widget.currency)?.decimals ?? 2;
    final f = _pow10(decimals);
    int value(FlowPoint p) => switch (_type) {
          _FlowType.net => p.net,
          _FlowType.income => p.income,
          _FlowType.expense => p.expense,
        };
    final category = _category == null ? null : services.repo.category(_category!);
    final groupLabels = {
      GroupType.daily: l.groupDaily,
      GroupType.weekly: l.groupWeekly,
      GroupType.monthly: l.groupMonthly,
      GroupType.yearly: l.groupYearly,
    };

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                avatar: const Icon(Icons.date_range, size: 18),
                label: Text('${context.formatShortDate(range.start)} – '
                    '${context.formatShortDate(range.lastDay)}'),
                onPressed: () async {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(1900),
                    lastDate: DateTime(2100),
                    initialDateRange:
                        DateTimeRange(start: range.start, end: range.lastDay),
                  );
                  if (picked != null) {
                    setState(() => _range =
                        Period(dateOnly(picked.start), addDays(dateOnly(picked.end), 1)));
                  }
                },
              ),
              PopupMenuButton<GroupType>(
                initialValue: group,
                onSelected: (g) => setState(() {
                  _group = g;
                  _range = null;
                }),
                itemBuilder: (_) => [
                  for (final g in GroupType.values)
                    PopupMenuItem(value: g, child: Text(groupLabels[g]!)),
                ],
                child: Chip(
                  avatar: const Icon(Icons.view_week_outlined, size: 18),
                  label: Text('${l.groupBy}: ${groupLabels[group]}'),
                ),
              ),
              InputChip(
                avatar: const Icon(Icons.category_outlined, size: 18),
                label: Text(category == null
                    ? l.cashFlow
                    : context.categoryName(category.name, category.tag, category.type)),
                onPressed: () async {
                  final type = _type == _FlowType.income
                      ? CategoryType.income
                      : CategoryType.expense;
                  final c = await pickCategory(context, type: type);
                  if (c != null) {
                    setState(() {
                      _category = c.uuid;
                      _type = c.type == CategoryType.income
                          ? _FlowType.income
                          : _FlowType.expense;
                    });
                  }
                },
                onDeleted: _category == null ? null : () => setState(() => _category = null),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: SegmentedButton<_FlowType>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: _FlowType.net, label: Text(l.net)),
              ButtonSegment(value: _FlowType.income, label: Text(l.incomes)),
              ButtonSegment(value: _FlowType.expense, label: Text(l.expenses)),
            ],
            selected: {_type},
            onSelectionChanged: (s) => setState(() {
              _type = s.first;
              _category = null;
            }),
          ),
        ),
        InfoCard(
          child: SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: theme.colorScheme.outlineVariant, strokeWidth: .5),
                ),
                titlesData: _titles(context, bottom: (v) {
                  final i = v.toInt();
                  if (i < 0 || i >= periods.length) return '';
                  final step = math.max(1, (periods.length / 6).ceil());
                  if (i % step != 0) return '';
                  final p = periods[i];
                  return switch (group) {
                    GroupType.daily => DateFormat.E(context.localeName).format(p.start),
                    GroupType.weekly => DateFormat.Md(context.localeName).format(p.start),
                    GroupType.monthly => DateFormat.MMM(context.localeName).format(p.lastDay),
                    GroupType.yearly => '${p.start.year}',
                  };
                }),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group0, _, rod, _) => BarTooltipItem(
                      context.formatMoney((rod.toY * f).round(), widget.currency),
                      theme.textTheme.labelSmall!.copyWith(color: Colors.white),
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < flow.length; i++)
                    BarChartGroupData(x: i, barRods: [
                      BarChartRodData(
                        toY: value(flow[i]) / f,
                        width: math.max(4, 200 / flow.length),
                        color: switch (_type) {
                          _FlowType.income => settings.incomeColor,
                          _FlowType.expense => settings.expenseColor,
                          _FlowType.net => value(flow[i]) >= 0
                              ? settings.incomeColor
                              : settings.expenseColor,
                        },
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ]),
                ],
              ),
            ),
          ),
        ),
        for (final p in flow.reversed)
          ListTile(
            title: Text(periodLabel(context, p.period, group)),
            trailing: MoneyText(
              _type == _FlowType.expense ? -value(p) : value(p),
              widget.currency,
              signed: _type == _FlowType.net,
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TransactionListScreen(
                  title: periodLabel(context, p.period, group),
                  filter: TransactionFilter(
                    wallet: widget.wallet,
                    category: _category,
                    start: p.period.start,
                    end: p.period.end,
                    direction: switch (_type) {
                      _FlowType.income => Direction.income,
                      _FlowType.expense => Direction.expense,
                      _FlowType.net => null,
                    },
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
