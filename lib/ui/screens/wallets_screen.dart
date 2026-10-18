import 'package:flutter/material.dart';

import '../../core/app_icon.dart';
import '../../core/calculator.dart';
import '../../core/money.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../scope.dart';
import '../widgets/common.dart';
import '../widgets/form_fields.dart';
import '../widgets/pickers.dart';
import 'transactions_screen.dart';

class WalletsScreen extends StatefulWidget {
  const WalletsScreen({super.key});

  @override
  State<WalletsScreen> createState() => _WalletsScreenState();
}

class _WalletsScreenState extends State<WalletsScreen> {
  bool _sorting = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final repo = context.repo;
    final all = repo.walletBalances(includeArchived: true);
    final active = all.where((b) => !b.wallet.archived).toList();
    final archived = all.where((b) => b.wallet.archived).toList();

    Widget tile(WalletBalance b, {Key? key, Widget? trailing}) => ListTile(
          key: key,
          leading: IconAvatar(b.wallet.icon),
          title: Text(b.wallet.name),
          subtitle: Text(b.wallet.countInTotal
              ? b.wallet.currency
              : '${b.wallet.currency} · ${l.walletCountInTotal} ✕'),
          trailing: trailing ?? MoneyText(b.balance, b.wallet.currency),
          onTap: _sorting ? null : () => _actions(context, b.wallet),
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(l.wallets),
        actions: [
          IconButton(
            tooltip: l.actionSort,
            isSelected: _sorting,
            icon: const Icon(Icons.sort),
            onPressed: () => setState(() => _sorting = !_sorting),
          ),
        ],
      ),
      floatingActionButton: _sorting
          ? null
          : FloatingActionButton(
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      fullscreenDialog: true, builder: (_) => const WalletEditor())),
              child: const Icon(Icons.add),
            ),
      body: _sorting
          ? ReorderableListView(
              onReorder: (from, to) {
                final ids = active.map((b) => b.wallet.uuid).toList();
                final moved = ids.removeAt(from);
                ids.insert(to > from ? to - 1 : to, moved);
                repo.reorderWallets([...ids, ...archived.map((b) => b.wallet.uuid)]);
              },
              children: [
                for (final b in active)
                  tile(b,
                      key: ValueKey(b.wallet.uuid),
                      trailing: const Icon(Icons.drag_handle)),
              ],
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: 96),
              children: [
                for (final b in active) tile(b),
                if (archived.isNotEmpty) ...[
                  SectionHeader(l.archivedWallets),
                  for (final b in archived) tile(b),
                ],
              ],
            ),
    );
  }

  void _actions(BuildContext context, Wallet wallet) {
    final l = context.l10n;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: Text(l.actionShowTransactions),
              onTap: () {
                Navigator.pop(sheet);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TransactionListScreen(
                        title: wallet.name,
                        filter: TransactionFilter(wallet: wallet.uuid)),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text(l.actionEdit),
              onTap: () {
                Navigator.pop(sheet);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      fullscreenDialog: true,
                      builder: (_) => WalletEditor(uuid: wallet.uuid)),
                );
              },
            ),
            ListTile(
              leading: Icon(wallet.archived ? Icons.unarchive : Icons.archive_outlined),
              title: Text(wallet.archived ? l.actionUnarchive : l.actionArchive),
              onTap: () {
                Navigator.pop(sheet);
                context.read.repo.saveWallet(wallet.copyWith(archived: !wallet.archived));
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(l.actionDelete),
              onTap: () async {
                Navigator.pop(sheet);
                if (await confirmDelete(context, wallet.name) && context.mounted) {
                  guarded(context, () => context.read.repo.deleteWallet(wallet.uuid));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class WalletEditor extends StatefulWidget {
  const WalletEditor({super.key, this.uuid});

  final String? uuid;

  @override
  State<WalletEditor> createState() => _WalletEditorState();
}

class _WalletEditorState extends State<WalletEditor> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _start = TextEditingController(text: '0');
  final _note = TextEditingController();
  AppIcon? _icon;
  String _currency = 'EUR';
  bool _countInTotal = true;
  Wallet? _existing;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final repo = context.read.repo;
    if (widget.uuid != null) {
      final w = repo.wallet(widget.uuid!);
      if (w != null) {
        _existing = w;
        _name.text = w.name;
        _icon = w.icon;
        _currency = w.currency;
        _countInTotal = w.countInTotal;
        _note.text = w.note ?? '';
        _start.text = minorToPlainString(
            w.startMoney, repo.currency(w.currency)?.decimals ?? 2);
      }
    } else {
      _currency = _defaultCurrency(context);
    }
    _name.addListener(() => setState(() {}));
  }

  /// Currency of the device locale (like the original app), else EUR.
  static String _defaultCurrency(BuildContext context) {
    final repo = context.read.repo;
    final country = Localizations.localeOf(context).countryCode;
    const byCountry = {
      'US': 'USD', 'GB': 'GBP', 'CH': 'CHF', 'JP': 'JPY', 'CA': 'CAD',
      'AU': 'AUD', 'SE': 'SEK', 'NO': 'NOK', 'DK': 'DKK', 'PL': 'PLN',
      'CZ': 'CZK', 'HU': 'HUF', 'IN': 'INR', 'CN': 'CNY', 'BR': 'BRL',
      'RU': 'RUB', 'TR': 'TRY', 'MX': 'MXN',
    };
    final iso = byCountry[country] ?? 'EUR';
    final existing = repo.wallets();
    if (existing.isNotEmpty) return existing.first.currency;
    return repo.currency(iso) != null ? iso : 'EUR';
  }

  @override
  void dispose() {
    _name.dispose();
    _start.dispose();
    _note.dispose();
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    final repo = context.read.repo;
    final decimals = repo.currency(_currency)?.decimals ?? 2;
    final start = evaluateAmount(_start.text.trim().isEmpty ? '0' : _start.text, decimals) ?? 0;
    final name = _name.text.trim();
    final ok = guarded(context, () {
      repo.saveWallet(Wallet(
        uuid: _existing?.uuid ?? newUuid(),
        name: name,
        icon: _icon ?? randomColorIcon(name),
        currency: _currency,
        startMoney: start,
        countInTotal: _countInTotal,
        archived: _existing?.archived ?? false,
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        tag: _existing?.tag,
        index: _existing?.index ?? repo.wallets().length,
      ));
    });
    if (ok) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final currency = context.repo.currency(_currency);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.uuid == null ? l.newWallet : l.editWallet),
        actions: [TextButton(onPressed: _save, child: Text(l.actionSave))],
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            IconNameField(
              icon: _icon ?? ColorIcon('#9E9E9E', iconInitials(_name.text)),
              controller: _name,
              label: l.walletName,
              onIconTap: () async {
                final icon = await pickIcon(context, name: _name.text, current: _icon);
                if (icon != null) setState(() => _icon = icon);
              },
            ),
            const SizedBox(height: 8),
            PickerTile(
              icon: Icons.currency_exchange,
              label: l.walletCurrency,
              value: currency == null ? _currency : '${currency.name} (${currency.iso})',
              onTap: () async {
                final c = await pickCurrency(context);
                if (c != null) setState(() => _currency = c.iso);
              },
            ),
            const SizedBox(height: 8),
            AmountField(
              controller: _start,
              decimals: currency?.decimals ?? 2,
              currencySymbol: currency?.displaySymbol ?? _currency,
              label: l.walletStartMoney,
              allowZero: true,
              allowNegative: true,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.walletCountInTotal),
              value: _countInTotal,
              onChanged: (v) => setState(() => _countInTotal = v),
            ),
            TextFormField(
              controller: _note,
              maxLines: 3,
              minLines: 1,
              decoration: InputDecoration(labelText: l.note),
            ),
          ],
        ),
      ),
    );
  }
}
