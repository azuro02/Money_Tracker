import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../app/settings.dart';
import '../../core/dates.dart';
import '../../data/models.dart';
import '../scope.dart';
import '../widgets/common.dart';
import 'lock_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final services = context.services;
    final settings = services.settings;
    final money = settings.moneyFormat;
    final locale = context.localeName;
    final sample = DateTime(DateTime.now().year, 3, 7);
    final weekdays = DateFormat.EEEE(locale).dateSymbols.WEEKDAYS;
    final themeLabels = {
      ThemeMode.system: l.themeSystem,
      ThemeMode.light: l.themeLight,
      ThemeMode.dark: l.themeDark,
    };
    final groupLabels = {
      GroupType.daily: l.groupDaily,
      GroupType.weekly: l.groupWeekly,
      GroupType.monthly: l.groupMonthly,
      GroupType.yearly: l.groupYearly,
    };
    final lockLabels = {
      LockMode.none: l.lockNone,
      LockMode.pin: l.lockPin,
      LockMode.pinBiometric: l.lockPinBiometric,
    };
    final reminder = settings.reminderMinutes;

    return Scaffold(
      appBar: AppBar(title: Text(l.settings)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          SectionHeader(l.settingsAppearance),
          ListTile(
            leading: const Icon(Icons.brightness_6_outlined),
            title: Text(l.settingsTheme),
            trailing: SegmentedButton<ThemeMode>(
              showSelectedIcon: false,
              segments: [
                for (final m in ThemeMode.values)
                  ButtonSegment(value: m, label: Text(themeLabels[m]!)),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (s) => settings.themeMode = s.first,
            ),
          ),
          _ColorTile(
            title: l.themeColor,
            icon: Icons.palette_outlined,
            value: settings.seedColor,
            onChanged: (c) => settings.seedColor = c,
          ),
          _ColorTile(
            title: l.incomeColor,
            icon: Icons.trending_up,
            value: settings.incomeColor,
            onChanged: (c) => settings.incomeColor = c,
          ),
          _ColorTile(
            title: l.expenseColor,
            icon: Icons.trending_down,
            value: settings.expenseColor,
            onChanged: (c) => settings.expenseColor = c,
          ),
          SectionHeader(l.settingsFormat),
          ListTile(
            leading: const Icon(Icons.calendar_today_outlined),
            title: Text(l.dateFormat),
            subtitle: Text(DateFormat(settings.dateFormat, locale).format(sample)),
            onTap: () => _choose<int>(
              context,
              title: l.dateFormat,
              values: List.generate(dateFormatPresets.length, (i) => i),
              label: (i) => DateFormat(dateFormatPresets[i], locale).format(sample),
              selected: settings.dateFormatIndex,
              onSelected: (i) => settings.dateFormatIndex = i,
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.euro),
            title: Text(l.showCurrency),
            subtitle: Text(context.formatMoney(123456, 'EUR')),
            value: money.showCurrency,
            onChanged: (v) => settings.setMoneyFormat(showCurrency: v),
          ),
          SwitchListTile(
            secondary: const SizedBox(),
            title: Text(l.groupDigits),
            value: money.groupDigits,
            onChanged: (v) => settings.setMoneyFormat(groupDigits: v),
          ),
          SwitchListTile(
            secondary: const SizedBox(),
            title: Text(l.roundDecimals),
            value: money.roundDecimals,
            onChanged: (v) => settings.setMoneyFormat(roundDecimals: v),
          ),
          SwitchListTile(
            secondary: const SizedBox(),
            title: Text(l.alwaysShowSign),
            value: money.alwaysShowSign,
            onChanged: (v) => settings.setMoneyFormat(alwaysShowSign: v),
          ),
          ListTile(
            leading: const Icon(Icons.view_week_outlined),
            title: Text(l.firstDayOfWeek),
            subtitle: Text(weekdays[settings.firstDayOfWeek % 7]),
            onTap: () => _choose<int>(
              context,
              title: l.firstDayOfWeek,
              values: const [DateTime.monday, DateTime.saturday, DateTime.sunday],
              label: (d) => weekdays[d % 7],
              selected: settings.firstDayOfWeek,
              onSelected: (d) => settings.firstDayOfWeek = d,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.payments_outlined),
            title: Text(l.firstDayOfMonth),
            subtitle: Text('${settings.firstDayOfMonth}. · ${l.firstDayOfMonthHint}'),
            onTap: () => _choose<int>(
              context,
              title: l.firstDayOfMonth,
              values: List.generate(31, (i) => i + 1),
              label: (d) => '$d.',
              selected: settings.firstDayOfMonth,
              onSelected: (d) => settings.firstDayOfMonth = d,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.segment),
            title: Text(l.groupTransactionsBy),
            subtitle: Text(groupLabels[settings.groupType]!),
            onTap: () => _choose<GroupType>(
              context,
              title: l.groupTransactionsBy,
              values: GroupType.values,
              label: (g) => groupLabels[g]!,
              selected: settings.groupType,
              onSelected: (g) => settings.groupType = g,
            ),
          ),
          SectionHeader(l.settingsSecurity),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: Text(l.lockMode),
            subtitle: Text(lockLabels[settings.lockMode]!),
            onTap: () => _choose<LockMode>(
              context,
              title: l.lockMode,
              values: LockMode.values,
              label: (m) => lockLabels[m]!,
              selected: settings.lockMode,
              onSelected: (m) => _setLockMode(context, m),
            ),
          ),
          if (settings.lockMode != LockMode.none) ...[
            ListTile(
              leading: const SizedBox(),
              title: Text(l.changePin),
              onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const PinSetupScreen())),
            ),
            ListTile(
              leading: const SizedBox(),
              title: Text(l.lockTimeout),
              subtitle: Text(_timeoutLabel(context, settings.lockTimeout)),
              onTap: () => _choose<int>(
                context,
                title: l.lockTimeout,
                values: const [0, 30, 60, 300, 900],
                label: (s) => _timeoutLabel(context, s),
                selected: settings.lockTimeout,
                onSelected: (s) => settings.lockTimeout = s,
              ),
            ),
          ],
          SectionHeader(l.settingsReminder),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: Text(l.settingsReminder),
            subtitle: Text(reminder < 0
                ? l.reminderOff
                : l.reminderAt(MaterialLocalizations.of(context).formatTimeOfDay(
                    TimeOfDay(hour: reminder ~/ 60, minute: reminder % 60)))),
            value: reminder >= 0,
            onChanged: (v) async {
              if (!v) {
                settings.reminderMinutes = -1;
                await services.reminder?.schedule(-1, title: '', body: '');
                return;
              }
              final time = await showTimePicker(
                  context: context, initialTime: const TimeOfDay(hour: 20, minute: 0));
              if (time == null || !context.mounted) return;
              final minutes = time.hour * 60 + time.minute;
              final ok = await services.reminder?.schedule(minutes,
                      title: l.reminderTitle, body: l.reminderBody) ??
                  false;
              if (ok) settings.reminderMinutes = minutes;
            },
          ),
          SectionHeader(l.settingsData),
          ListTile(
            leading: const Icon(Icons.currency_exchange),
            title: Text(l.manageCurrencies),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const CurrenciesScreen())),
          ),
        ],
      ),
    );
  }

  String _timeoutLabel(BuildContext context, int seconds) {
    final l = context.l10n;
    if (seconds == 0) return l.lockImmediately;
    if (seconds < 60) return l.lockAfterSeconds(seconds);
    return l.lockAfterMinutes(seconds ~/ 60);
  }

  Future<void> _setLockMode(BuildContext context, LockMode mode) async {
    final services = context.read;
    if (mode == LockMode.none) {
      await services.security.clearPin();
      services.settings.lockMode = mode;
      return;
    }
    if (mode == LockMode.pinBiometric && !await services.security.canUseBiometrics()) {
      if (context.mounted) context.showSnack(context.l10n.biometricsUnavailable);
      return;
    }
    if (!await services.security.hasPin()) {
      if (!context.mounted) return;
      final ok = await Navigator.push<bool>(
          context, MaterialPageRoute(builder: (_) => const PinSetupScreen()));
      if (ok != true) return;
    }
    services.settings.lockMode = mode;
  }

  Future<void> _choose<T>(
    BuildContext context, {
    required String title,
    required List<T> values,
    required String Function(T) label,
    required T selected,
    required void Function(T) onSelected,
  }) async {
    final result = await showModalBottomSheet<T>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheet) => ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .7),
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
            for (final v in values)
              ListTile(
                title: Text(label(v)),
                trailing: v == selected ? const Icon(Icons.check) : null,
                onTap: () => Navigator.pop(sheet, v),
              ),
          ],
        ),
      ),
    );
    if (result != null) onSelected(result);
  }
}

class _ColorTile extends StatelessWidget {
  const _ColorTile({
    required this.title,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final IconData icon;
  final Color value;
  final ValueChanged<Color> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: CircleAvatar(radius: 14, backgroundColor: value),
      onTap: () async {
        final color = await showModalBottomSheet<Color>(
          context: context,
          showDragHandle: true,
          builder: (sheet) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final c in settingsColors)
                  InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => Navigator.pop(sheet, Color(c)),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: Color(c),
                      child: c == value.toARGB32()
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
                  ),
              ],
            ),
          ),
        );
        if (color != null) onChanged(color);
      },
    );
  }
}

class CurrenciesScreen extends StatefulWidget {
  const CurrenciesScreen({super.key});

  @override
  State<CurrenciesScreen> createState() => _CurrenciesScreenState();
}

class _CurrenciesScreenState extends State<CurrenciesScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final q = _query.toLowerCase();
    final currencies = context.repo
        .currencies()
        .where((c) => q.isEmpty || '${c.iso} ${c.name}'.toLowerCase().contains(q))
        .toList();
    return Scaffold(
      appBar: AppBar(title: Text(l.currencies)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _edit(context, null),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SearchBar(
              leading: const Icon(Icons.search),
              hintText: l.search,
              elevation: const WidgetStatePropertyAll(0),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 96),
              itemCount: currencies.length,
              itemBuilder: (context, i) {
                final c = currencies[i];
                return ListTile(
                  leading: CircleAvatar(child: FittedBox(child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Text(c.displaySymbol),
                  ))),
                  title: Text(c.name),
                  subtitle: Text('${c.iso} · ${l.currencyDecimals}: ${c.decimals}'),
                  trailing: IconButton(
                    icon: Icon(c.favourite ? Icons.star : Icons.star_border),
                    onPressed: () => context.read.repo.saveCurrency(Currency(
                      iso: c.iso,
                      name: c.name,
                      symbol: c.symbol,
                      decimals: c.decimals,
                      favourite: !c.favourite,
                    )),
                  ),
                  onTap: () => _edit(context, c),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _edit(BuildContext context, Currency? c) async {
    final l = context.l10n;
    final iso = TextEditingController(text: c?.iso);
    final name = TextEditingController(text: c?.name);
    final symbol = TextEditingController(text: c?.symbol);
    final decimals = TextEditingController(text: '${c?.decimals ?? 2}');
    final form = GlobalKey<FormState>();
    final result = await showDialog<String>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(c == null ? l.newCurrency : l.editCurrency),
        content: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: iso,
                enabled: c == null,
                textCapitalization: TextCapitalization.characters,
                maxLength: 8,
                decoration: InputDecoration(labelText: l.currencyIso),
                validator: (v) => (v == null || v.trim().isEmpty) ? l.required : null,
              ),
              TextFormField(
                controller: name,
                decoration: InputDecoration(labelText: l.name),
                validator: (v) => (v == null || v.trim().isEmpty) ? l.required : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: symbol,
                decoration: InputDecoration(labelText: l.currencySymbol),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: decimals,
                enabled: c == null || !context.repo.wallets().any((w) => w.currency == c.iso),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: l.currencyDecimals),
                validator: (v) {
                  final d = int.tryParse(v ?? '');
                  return d == null || d < 0 || d > 8 ? l.invalidAmount : null;
                },
              ),
            ],
          ),
        ),
        actions: [
          if (c != null)
            TextButton(
              onPressed: () => Navigator.pop(dialog, 'delete'),
              child: Text(l.actionDelete),
            ),
          TextButton(
              onPressed: () => Navigator.pop(dialog), child: Text(l.actionCancel)),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) Navigator.pop(dialog, 'save');
            },
            child: Text(l.actionSave),
          ),
        ],
      ),
    );
    if (!context.mounted) return;
    final repo = context.read.repo;
    if (result == 'delete' && c != null) {
      guarded(context, () => repo.deleteCurrency(c.iso));
    } else if (result == 'save') {
      guarded(
        context,
        () => repo.saveCurrency(Currency(
          iso: iso.text.trim().toUpperCase(),
          name: name.text.trim(),
          symbol: symbol.text.trim().isEmpty ? null : symbol.text.trim(),
          decimals: int.parse(decimals.text),
          favourite: c?.favourite ?? false,
        )),
      );
    }
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.about)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(Icons.account_balance_wallet_rounded,
                  size: 44, color: theme.colorScheme.onPrimaryContainer),
            ),
          ),
          const SizedBox(height: 12),
          Center(child: Text(l.appTitle, style: theme.textTheme.headlineSmall)),
          FutureBuilder(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) => Center(
              child: Text(snapshot.hasData ? l.version(snapshot.data!.version) : ''),
            ),
          ),
          const SizedBox(height: 24),
          InfoCard(
            title: l.privacy,
            child: Text(l.privacyText),
          ),
          InfoCard(
            title: 'GPL v3',
            child: Text('${l.licenseInfo}\n\n${l.aboutCredits}'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => showLicensePage(
                context: context, applicationName: l.appTitle),
            child: Text(l.openSourceLicenses),
          ),
        ],
      ),
    );
  }
}
