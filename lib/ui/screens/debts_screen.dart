import 'package:flutter/material.dart';

import '../../core/app_icon.dart';
import '../../core/calculator.dart';
import '../../core/dates.dart';
import '../../core/money.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../scope.dart';
import '../widgets/common.dart';
import '../widgets/form_fields.dart';
import '../widgets/pickers.dart';
import 'entities_screen.dart';
import 'transaction_editor.dart';
import 'transactions_screen.dart';

class DebtsScreen extends StatelessWidget {
  const DebtsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return DefaultTabController(
      length: 2,
      child: Builder(builder: (context) {
        return Scaffold(
          appBar: AppBar(
            title: Text(l.debts),
            bottom: TabBar(tabs: [Tab(text: l.debts), Tab(text: l.credits)]),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                fullscreenDialog: true,
                builder: (_) => DebtEditor(
                  type: DefaultTabController.of(context).index == 0
                      ? DebtType.debt
                      : DebtType.credit,
                ),
              ),
            ),
            child: const Icon(Icons.add),
          ),
          body: const TabBarView(children: [
            _DebtList(type: DebtType.debt),
            _DebtList(type: DebtType.credit),
          ]),
        );
      }),
    );
  }
}

class _DebtList extends StatelessWidget {
  const _DebtList({required this.type});

  final int type;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final debts = context.repo.debts(type: type);
    final open = debts.where((d) => !d.debt.archived).toList();
    final archived = debts.where((d) => d.debt.archived).toList();
    if (debts.isEmpty) {
      return EmptyState(icon: Icons.handshake_outlined, title: l.emptyList);
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        if (open.isNotEmpty) SectionHeader(type == DebtType.debt ? l.toPay : l.toReceive),
        for (final d in open) _DebtCard(d),
        if (archived.isNotEmpty) SectionHeader(l.archived),
        for (final d in archived) _DebtCard(d),
      ],
    );
  }
}

class _DebtCard extends StatelessWidget {
  const _DebtCard(this.view);

  final DebtView view;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final d = view.debt;
    final now = DateTime.now();
    final expiration = d.expirationDate;
    final expired = expiration != null && dateOnly(now).isAfter(expiration) && !view.isComplete;
    final isDebt = d.type == DebtType.debt;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _actions(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconAvatar(d.icon),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d.description, style: theme.textTheme.titleMedium),
                        Text(view.walletName, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  MoneyText(isDebt ? -d.money : d.money, view.currency,
                      style: theme.textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: view.progress,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      view.isComplete
                          ? l.debtCompleted
                          : l.debtLeft(context.formatMoney(view.remaining, view.currency)),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  if (expiration != null)
                    Text(
                      expired
                          ? l.debtExpired(context.formatShortDate(expiration))
                          : l.debtExpiresOn(context.formatShortDate(expiration)),
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: expired ? theme.colorScheme.error : null),
                    ),
                ],
              ),
              if (!view.isComplete && !d.archived)
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.tonalIcon(
                    icon: Icon(isDebt ? Icons.north_east : Icons.south_west),
                    label: Text(isDebt ? l.debtPay : l.debtReceive),
                    onPressed: () => openTransactionEditor(context, debt: d.uuid),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _actions(BuildContext context) {
    final l = context.l10n;
    final d = view.debt;
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
                        title: d.description, filter: TransactionFilter(debt: d.uuid)),
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
                      builder: (_) => DebtEditor(uuid: d.uuid, type: d.type)),
                );
              },
            ),
            ListTile(
              leading: Icon(d.archived ? Icons.unarchive : Icons.archive_outlined),
              title: Text(d.archived ? l.actionUnarchive : l.actionArchive),
              onTap: () {
                Navigator.pop(sheet);
                context.read.repo.setDebtArchived(d.uuid, !d.archived);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(l.actionDelete),
              onTap: () async {
                Navigator.pop(sheet);
                if (await confirmDelete(context, d.description) && context.mounted) {
                  guarded(context, () => context.read.repo.deleteDebt(d.uuid));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class DebtEditor extends StatefulWidget {
  const DebtEditor({super.key, this.uuid, required this.type});

  final String? uuid;
  final int type;

  @override
  State<DebtEditor> createState() => _DebtEditorState();
}

class _DebtEditorState extends State<DebtEditor> {
  final _form = GlobalKey<FormState>();
  final _description = TextEditingController();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  late int _type = widget.type;
  AppIcon? _icon;
  String? _wallet;
  String? _place;
  DateTime _date = dateOnly(DateTime.now());
  DateTime? _expiration;
  List<String> _people = [];
  bool _createTransaction = true;
  Debt? _existing;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final repo = context.read.repo;
    _wallet = context.read.settings.currentWallet ??
        repo.wallets(includeArchived: false).firstOrNull?.uuid;
    if (widget.uuid != null) {
      final v = repo.debtView(widget.uuid!);
      if (v != null) {
        final d = v.debt;
        _existing = d;
        _type = d.type;
        _description.text = d.description;
        _amount.text = minorToPlainString(d.money, repo.currency(v.currency)?.decimals ?? 2);
        _note.text = d.note ?? '';
        _icon = d.icon;
        _wallet = d.wallet;
        _place = d.place;
        _date = d.date;
        _expiration = d.expirationDate;
        _people = repo.debtPeople(d.uuid);
      }
    }
    _description.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _description.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate() || _wallet == null) return;
    final repo = context.read.repo;
    final wallet = repo.wallet(_wallet!)!;
    final money = evaluateAmount(_amount.text, repo.currency(wallet.currency)?.decimals ?? 2)!.abs();
    final description = _description.text.trim();
    final ok = guarded(context, () {
      repo.saveDebt(
        Debt(
          uuid: _existing?.uuid ?? newUuid(),
          type: _type,
          icon: _icon ?? randomColorIcon(description),
          description: description,
          date: _date,
          expirationDate: _expiration,
          wallet: _wallet!,
          note: _note.text.trim().isEmpty ? null : _note.text.trim(),
          place: _place,
          money: money,
          archived: _existing?.archived ?? false,
          tag: _existing?.tag,
        ),
        people: _people,
        createMasterTransaction: _existing == null && _createTransaction,
      );
    });
    if (ok) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final repo = context.repo;
    final wallet = _wallet == null ? null : repo.wallet(_wallet!);
    final currency = wallet == null ? null : repo.currency(wallet.currency);
    final place = _place == null ? null : repo.place(_place!);
    final people = _people.map(repo.person).whereType<Person>();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.uuid == null
            ? (_type == DebtType.debt ? l.newDebt : l.newCredit)
            : l.editDebt),
        actions: [TextButton(onPressed: _save, child: Text(l.actionSave))],
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<int>(
              segments: [
                ButtonSegment(value: DebtType.debt, label: Text(l.debt)),
                ButtonSegment(value: DebtType.credit, label: Text(l.credit)),
              ],
              selected: {_type},
              onSelectionChanged:
                  _existing != null ? null : (s) => setState(() => _type = s.first),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(_type == DebtType.debt ? l.debtTypeDebt : l.debtTypeCredit,
                  style: Theme.of(context).textTheme.bodySmall),
            ),
            IconNameField(
              icon: _icon ?? ColorIcon('#9E9E9E', iconInitials(_description.text)),
              controller: _description,
              label: l.description,
              onIconTap: () async {
                final icon =
                    await pickIcon(context, name: _description.text, current: _icon);
                if (icon != null) setState(() => _icon = icon);
              },
            ),
            const SizedBox(height: 12),
            AmountField(
              controller: _amount,
              decimals: currency?.decimals ?? 2,
              currencySymbol: currency?.displaySymbol ?? '',
            ),
            PickerTile(
              icon: Icons.account_balance_wallet_outlined,
              label: l.wallet,
              leading: wallet == null ? null : IconAvatar(wallet.icon),
              value: wallet?.name,
              onTap: () async {
                final w = await pickWallet(context);
                if (w != null) setState(() => _wallet = w.uuid);
              },
            ),
            PickerTile(
              icon: Icons.event,
              label: l.date,
              value: context.formatDate(_date),
              onTap: () async {
                final d = await pickDate(context, _date);
                if (d != null) setState(() => _date = d);
              },
            ),
            PickerTile(
              icon: Icons.event_busy,
              label: l.expirationDate,
              value: _expiration == null ? null : context.formatDate(_expiration!),
              onClear: () => setState(() => _expiration = null),
              onTap: () async {
                final d = await pickDate(context, _expiration ?? _date, first: _date);
                if (d != null) setState(() => _expiration = d);
              },
            ),
            PickerTile(
              icon: Icons.people_outline,
              label: l.people,
              value: people.isEmpty ? null : people.map((p) => p.name).join(', '),
              onClear: () => setState(() => _people = []),
              onTap: () async {
                final picked = await pickPeople(context, _people,
                    onCreate: () => openPersonEditor(context));
                if (picked != null) setState(() => _people = picked);
              },
            ),
            PickerTile(
              icon: Icons.place_outlined,
              label: l.place,
              value: place?.name,
              onClear: () => setState(() => _place = null),
              onTap: () async {
                final picked = await pickEntity(context,
                    title: l.place,
                    items: [for (final p in repo.places()) (p.uuid, p.name, p.icon)],
                    onCreate: () => openPlaceEditor(context));
                if (picked != null) setState(() => _place = picked.value);
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _note,
              maxLines: 4,
              minLines: 1,
              decoration: InputDecoration(labelText: l.note),
            ),
            if (_existing == null)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l.debtCreateTransaction),
                subtitle: Text(l.debtCreateTransactionHint),
                value: _createTransaction,
                onChanged: (v) => setState(() => _createTransaction = v),
              ),
          ],
        ),
      ),
    );
  }
}
