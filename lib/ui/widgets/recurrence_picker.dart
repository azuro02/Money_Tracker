import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/recurrence_service.dart';
import '../../domain/rrule.dart';
import '../scope.dart';
import 'pickers.dart';

/// Human readable description of an RRULE.
String describeRule(BuildContext context, String rule) {
  final l = context.l10n;
  final RRule r;
  try {
    r = RRule.parse(rule);
  } on FormatException {
    return rule;
  }
  final n = r.interval;
  final base = switch (r.frequency) {
    Frequency.daily => n == 1 ? l.freqDaily : '${l.everyN} $n ${l.intervalDays(n)}',
    Frequency.weekly => n == 1 ? l.freqWeekly : '${l.everyN} $n ${l.intervalWeeks(n)}',
    Frequency.monthly => n == 1 ? l.freqMonthly : '${l.everyN} $n ${l.intervalMonths(n)}',
    Frequency.yearly => n == 1 ? l.freqYearly : '${l.everyN} $n ${l.intervalYears(n)}',
  };
  final parts = [base];
  if (r.frequency == Frequency.weekly && r.byDay.isNotEmpty) {
    final names = DateFormat.E(context.localeName).dateSymbols.SHORTWEEKDAYS;
    parts.add(r.byDay.map((w) => names[w.weekday % 7]).join(', '));
  }
  if (r.until != null) parts.add(l.recurrenceSummaryUntil(context.formatShortDate(r.until!)));
  if (r.count != null) parts.add(l.recurrenceSummaryCount(r.count!));
  return parts.join(' · ');
}

/// Form row that edits a recurrence rule.
class RecurrenceField extends StatelessWidget {
  const RecurrenceField({
    super.key,
    required this.rule,
    required this.start,
    required this.onChanged,
  });

  final String rule;
  final DateTime start;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final upcoming = RRule.isValid(rule)
        ? RecurrenceService.preview(rule, start, max: 3)
        : const <DateTime>[];
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Icon(Icons.repeat),
      ),
      title: Text(describeRule(context, rule)),
      subtitle: upcoming.isEmpty
          ? null
          : Text('${context.l10n.upcoming}: ${upcoming.map(context.formatShortDate).join(', ')}'),
      onTap: () async {
        final result = await showModalBottomSheet<String>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          useSafeArea: true,
          builder: (_) => _RuleEditor(rule: rule, start: start),
        );
        if (result != null) onChanged(result);
      },
    );
  }
}

enum _End { never, until, count }

class _RuleEditor extends StatefulWidget {
  const _RuleEditor({required this.rule, required this.start});

  final String rule;
  final DateTime start;

  @override
  State<_RuleEditor> createState() => _RuleEditorState();
}

class _RuleEditorState extends State<_RuleEditor> {
  late Frequency _freq;
  late int _interval;
  late Set<int> _weekdays;
  late bool _lastDayOfMonth;
  late _End _end;
  late DateTime _until;
  late int _count;
  late Map<String, String> _extra;

  @override
  void initState() {
    super.initState();
    RRule r;
    try {
      r = RRule.parse(widget.rule);
    } on FormatException {
      r = const RRule(frequency: Frequency.monthly);
    }
    _freq = r.frequency;
    _interval = r.interval;
    _weekdays = r.byDay.map((w) => w.weekday).toSet();
    _lastDayOfMonth = r.byMonthDay.contains(-1);
    _end = r.until != null ? _End.until : (r.count != null ? _End.count : _End.never);
    _until = r.until ?? DateTime(widget.start.year + 1, widget.start.month, widget.start.day);
    _count = r.count ?? 12;
    _extra = r.extra;
  }

  String _build() {
    final rule = RRule(
      frequency: _freq,
      interval: _interval,
      byDay: _freq == Frequency.weekly
          ? (_weekdays.toList()..sort()).map(WeekdayNum.new).toList()
          : const [],
      byMonthDay: _freq == Frequency.monthly
          ? [_lastDayOfMonth ? -1 : widget.start.day]
          : const [],
      until: _end == _End.until ? _until : null,
      count: _end == _End.count ? _count : null,
      extra: _extra,
    );
    return rule.toString();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final weekdayNames = DateFormat.E(context.localeName).dateSymbols.SHORTWEEKDAYS;
    final firstDay = context.settings.firstDayOfWeek;
    final order = [for (var i = 0; i < 7; i++) (firstDay - 1 + i) % 7 + 1];
    final unit = switch (_freq) {
      Frequency.daily => l.intervalDays(_interval),
      Frequency.weekly => l.intervalWeeks(_interval),
      Frequency.monthly => l.intervalMonths(_interval),
      Frequency.yearly => l.intervalYears(_interval),
    };
    final rule = _build();
    final preview = RecurrenceService.preview(rule, widget.start, max: 4);
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          16, 0, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.repeat, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          SegmentedButton<Frequency>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: Frequency.daily, label: Text(l.groupDaily)),
              ButtonSegment(value: Frequency.weekly, label: Text(l.groupWeekly)),
              ButtonSegment(value: Frequency.monthly, label: Text(l.groupMonthly)),
              ButtonSegment(value: Frequency.yearly, label: Text(l.groupYearly)),
            ],
            selected: {_freq},
            onSelectionChanged: (s) => setState(() => _freq = s.first),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(l.everyN),
              IconButton(
                onPressed: _interval > 1 ? () => setState(() => _interval--) : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text('$_interval', style: Theme.of(context).textTheme.titleLarge),
              IconButton(
                onPressed: _interval < 99 ? () => setState(() => _interval++) : null,
                icon: const Icon(Icons.add_circle_outline),
              ),
              Text(unit),
            ],
          ),
          if (_freq == Frequency.weekly) ...[
            const SizedBox(height: 8),
            Text(l.onWeekdays),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              children: [
                for (final wd in order)
                  FilterChip(
                    label: Text(weekdayNames[wd % 7]),
                    selected: _weekdays.contains(wd),
                    onSelected: (v) => setState(
                        () => v ? _weekdays.add(wd) : _weekdays.remove(wd)),
                  ),
              ],
            ),
          ],
          if (_freq == Frequency.monthly)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('${l.groupMonthly}: ${_lastDayOfMonth ? '−1' : widget.start.day}.'),
              subtitle: Text(DateFormat.MMMd(context.localeName).format(
                  DateTime(widget.start.year, widget.start.month + 1, 0))),
              value: _lastDayOfMonth,
              onChanged: (v) => setState(() => _lastDayOfMonth = v),
            ),
          const Divider(height: 24),
          RadioGroup<_End>(
            groupValue: _end,
            onChanged: (v) => setState(() => _end = v!),
            child: Column(
              children: [
                RadioListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _End.never,
                    title: Text(l.endsNever)),
                RadioListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _End.until,
                  title: Text(l.endsOn),
                  subtitle: _end == _End.until ? Text(context.formatDate(_until)) : null,
                  secondary: _end == _End.until
                      ? IconButton(
                          icon: const Icon(Icons.edit_calendar),
                          onPressed: () async {
                            final d = await pickDate(context, _until,
                                first: widget.start);
                            if (d != null) setState(() => _until = d);
                          },
                        )
                      : null,
                ),
                RadioListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _End.count,
                  title: Text(l.endsAfter),
                  secondary: _end == _End.count
                      ? SizedBox(
                          width: 72,
                          child: TextFormField(
                            initialValue: '$_count',
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            onChanged: (v) => setState(
                                () => _count = (int.tryParse(v) ?? 1).clamp(1, 9999)),
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
          if (preview.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('${l.upcoming}: ${preview.map(context.formatShortDate).join(', ')}',
                style: Theme.of(context).textTheme.bodySmall),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.pop(context, rule),
            child: Text(l.actionOk),
          ),
        ],
      ),
    );
  }
}
