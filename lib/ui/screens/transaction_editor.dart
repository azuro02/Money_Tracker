
import 'package:flutter/material.dart';

import '../../core/app_icon.dart';
import '../../core/calculator.dart';
import '../../core/dates.dart';
import '../../core/money.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../scope.dart';
import '../widgets/common.dart';
import '../widgets/attachments.dart';
import '../widgets/form_fields.dart';
import '../widgets/pickers.dart';
import '../widgets/recurrence_picker.dart';
import 'entities_screen.dart';
import 'transfer_editor.dart';

enum EditorKind { transaction, model, recurrent }

Future<void> openTransactionEditor(
  BuildContext context, {
  String? uuid,
  EditorKind kind = EditorKind.transaction,
  String? debt,
  TransactionModel? template,
}) {
  return Navigator.push(
    context,
    MaterialPageRoute(
      fullscreenDialog: uuid == null,
      builder: (_) => TransactionEditor(
          uuid: uuid, kind: kind, debt: debt, template: template),
    ),
  );
}

/// Editor for transactions, transaction templates and recurrent
/// transactions (they share almost all fields).
class TransactionEditor extends StatefulWidget {
  const TransactionEditor({
    super.key,
    this.uuid,
    this.kind = EditorKind.transaction,
    this.debt,
    this.template,
  });

  final String? uuid;
  final EditorKind kind;

  /// Creates a payment for this debt (category and direction are fixed).
  final String? debt;
  final TransactionModel? template;

  @override
  State<TransactionEditor> createState() => _TransactionEditorState();
}

class _TransactionEditorState extends State<TransactionEditor> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _description = TextEditingController();
  final _note = TextEditingController();
  bool _initialized = false;

  int _direction = Direction.expense;
  String? _category;
  String? _wallet;
  DateTime _date = DateTime.now();
  String? _event;
  String? _place;
  List<String> _people = [];
  List<Attachment> _attachments = [];
  bool _confirmed = true;
  bool _countInTotal = true;
  String _rule = 'FREQ=MONTHLY';
  String? _debt;
  int _type = TransactionType.standard;
  String? _saving;
  String? _recurrence;
  String? _tag;
  bool _categoryLocked = false;
  bool _categoryError = false;

  bool get _isNew => widget.uuid == null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final services = context.read;
    final repo = services.repo;
    _wallet = services.settings.currentWallet ??
        repo.wallets(includeArchived: false).firstOrNull?.uuid;
    if (widget.uuid != null) {
      switch (widget.kind) {
        case EditorKind.transaction:
          final t = repo.transaction(widget.uuid!);
          if (t != null) _loadTransaction(t, repo);
        case EditorKind.model:
          final m = repo.transactionModels().where((m) => m.uuid == widget.uuid).firstOrNull;
          if (m != null) _loadModel(m, repo);
        case EditorKind.recurrent:
          final r = repo.recurrentTransaction(widget.uuid!);
          if (r != null) {
            _loadCommon(r.money, r.description, r.category, r.direction,
                r.wallet, r.place, r.note, r.event, r.confirmed, r.countInTotal, repo);
            _date = r.startDate;
            _rule = r.rule;
            _tag = r.tag;
          }
      }
    } else if (widget.template != null) {
      _loadModel(widget.template!, repo);
      _tag = null;
    }
    if (widget.debt != null) {
      final debt = repo.debtView(widget.debt!);
      if (debt != null) {
        _debt = debt.debt.uuid;
        _type = TransactionType.debt;
        _direction = repo.debtPaymentDirection(debt.debt.type);
        _category = repo.debtPaymentCategory(debt.debt.type).uuid;
        _wallet = debt.debt.wallet;
        _description.text = debt.debt.description;
        _categoryLocked = true;
        if (debt.remaining > 0) {
          final decimals = repo.currency(debt.currency)?.decimals ?? 2;
          _amount.text = minorToPlainString(debt.remaining, decimals);
        }
      }
    }
  }

  void _loadCommon(int money, String? description, String category, int direction,
      String wallet, String? place, String? note, String? event, bool confirmed,
      bool countInTotal, Repository repo) {
    final decimals = repo.currency(repo.wallet(wallet)?.currency ?? '')?.decimals ?? 2;
    _amount.text = minorToPlainString(money, decimals);
    _description.text = description ?? '';
    _category = category;
    _direction = direction;
    _wallet = wallet;
    _place = place;
    _note.text = note ?? '';
    _event = event;
    _confirmed = confirmed;
    _countInTotal = countInTotal;
    _categoryLocked = repo.category(category)?.isSystem ?? false;
  }

  void _loadModel(TransactionModel m, Repository repo) {
    _loadCommon(m.money, m.description, m.category, m.direction, m.wallet,
        m.place, m.note, m.event, m.confirmed, m.countInTotal, repo);
    _tag = m.tag;
  }

  void _loadTransaction(Transaction t, Repository repo) {
    _loadCommon(t.money, t.description, t.category, t.direction, t.wallet,
        t.place, t.note, t.event, t.confirmed, t.countInTotal, repo);
    _date = t.date;
    _people = repo.transactionPeople(t.uuid);
    _attachments = repo.transactionAttachments(t.uuid);
    _debt = t.debt;
    _type = t.type;
    _saving = t.saving;
    _recurrence = t.recurrence;
    _tag = t.tag;
  }

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    _note.dispose();
    super.dispose();
  }

  String get _title {
    final l = context.l10n;
    return switch (widget.kind) {
      EditorKind.transaction => _isNew ? l.newTransaction : l.editTransaction,
      EditorKind.model => _isNew ? l.newModel : l.editModel,
      EditorKind.recurrent => _isNew ? l.newRecurrence : l.editRecurrence,
    };
  }

  Future<void> _save() async {
    final repo = context.read.repo;
    final valid = _form.currentState!.validate();
    setState(() => _categoryError = _category == null);
    if (!valid || _category == null || _wallet == null) return;
    final wallet = repo.wallet(_wallet!)!;
    final decimals = repo.currency(wallet.currency)?.decimals ?? 2;
    final money = evaluateAmount(_amount.text, decimals)!.abs();
    String? text(TextEditingController c) =>
        c.text.trim().isEmpty ? null : c.text.trim();
    final uuid = widget.uuid ?? newUuid();
    final ok = guarded(context, () {
      switch (widget.kind) {
        case EditorKind.transaction:
          repo.saveTransaction(
            Transaction(
              uuid: uuid,
              money: money,
              date: _date,
              description: text(_description),
              category: _category!,
              direction: _direction,
              type: _type,
              wallet: _wallet!,
              place: _place,
              note: text(_note),
              saving: _saving,
              debt: _debt,
              event: _event,
              recurrence: _recurrence,
              confirmed: _confirmed,
              countInTotal: _countInTotal,
              tag: _tag,
            ),
            people: _people,
            attachments: _attachments.map((a) => a.uuid).toList(),
          );
          _cleanupAttachments();
        case EditorKind.model:
          repo.saveTransactionModel(TransactionModel(
            uuid: uuid,
            money: money,
            description: text(_description),
            category: _category!,
            direction: _direction,
            wallet: _wallet!,
            place: _place,
            note: text(_note),
            event: _event,
            confirmed: _confirmed,
            countInTotal: _countInTotal,
            tag: _tag,
          ));
        case EditorKind.recurrent:
          context.read.recurrences.saveRecurrentTransaction(RecurrentTransaction(
            uuid: uuid,
            money: money,
            description: text(_description),
            category: _category!,
            direction: _direction,
            wallet: _wallet!,
            place: _place,
            note: text(_note),
            event: _event,
            confirmed: _confirmed,
            countInTotal: _countInTotal,
            startDate: dateOnly(_date),
            lastOccurrence: dateOnly(_date),
            rule: _rule,
            tag: _tag,
          ));
      }
    });
    if (ok && mounted) Navigator.pop(context, true);
  }

  void _cleanupAttachments() => cleanupOrphanAttachments(context.read);

  Future<void> _delete() async {
    final l = context.l10n;
    if (!await confirmDelete(context,
        _description.text.isEmpty ? l.transactions : _description.text)) {
      return;
    }
    if (!mounted) return;
    final services = context.read;
    final ok = guarded(context, () {
      switch (widget.kind) {
        case EditorKind.transaction:
          services.repo.deleteTransaction(widget.uuid!);
          _cleanupAttachments();
        case EditorKind.model:
          services.repo.deleteTransactionModel(widget.uuid!);
        case EditorKind.recurrent:
          services.repo.deleteRecurrentTransaction(widget.uuid!);
      }
    });
    if (ok && mounted) Navigator.pop(context, true);
  }

  Future<void> _applyTemplate() async {
    final repo = context.read.repo;
    final models = repo.transactionModels();
    final transferModels = repo.transferModels();
    final picked = await showModalBottomSheet<Object>(
      context: context,
      showDragHandle: true,
      builder: (context) => ListView(
        shrinkWrap: true,
        children: [
          for (final m in models)
            ListTile(
              leading: IconAvatar(repo.category(m.category)?.icon ?? AppIcon.fallback),
              title: Text(m.description ?? repo.category(m.category)?.name ?? ''),
              trailing: MoneyText(
                  m.direction == Direction.income ? m.money : -m.money,
                  repo.wallet(m.wallet)?.currency ?? ''),
              onTap: () => Navigator.pop(context, m),
            ),
          for (final m in transferModels)
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.swap_horiz)),
              title: Text(m.description ??
                  '${repo.wallet(m.fromWallet)?.name} → ${repo.wallet(m.toWallet)?.name}'),
              onTap: () => Navigator.pop(context, m),
            ),
          if (models.isEmpty && transferModels.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(context.l10n.emptyList, textAlign: TextAlign.center),
            ),
        ],
      ),
    );
    if (!mounted || picked == null) return;
    if (picked is TransactionModel) {
      setState(() {
        _loadModel(picked, repo);
        _tag = null;
      });
    } else if (picked is TransferModel) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => TransferEditor(template: picked)),
      );
    }
  }

  Future<void> _saveAsTemplate() async {
    final repo = context.read.repo;
    if (_category == null || _wallet == null) {
      setState(() => _categoryError = _category == null);
      return;
    }
    final wallet = repo.wallet(_wallet!)!;
    final money =
        evaluateAmount(_amount.text, repo.currency(wallet.currency)?.decimals ?? 2) ?? 0;
    repo.saveTransactionModel(TransactionModel(
      uuid: newUuid(),
      money: money.abs(),
      description: _description.text.trim().isEmpty ? null : _description.text.trim(),
      category: _category!,
      direction: _direction,
      wallet: _wallet!,
      place: _place,
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
      event: _event,
      confirmed: _confirmed,
      countInTotal: _countInTotal,
    ));
    context.showSnack(context.l10n.saved);
  }

  Future<void> _addAttachment(String source) async {
    final attachment = await addAttachment(context, source);
    if (attachment != null && mounted) {
      setState(() => _attachments = [..._attachments, attachment]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final services = context.services;
    final repo = services.repo;
    final theme = Theme.of(context);
    final wallet = _wallet == null ? null : repo.wallet(_wallet!);
    final currency = wallet == null ? null : repo.currency(wallet.currency);
    final category = _category == null ? null : repo.category(_category!);
    final event = _event == null ? null : repo.event(_event!);
    final place = _place == null ? null : repo.place(_place!);
    final people = _people.map(repo.person).whereType<Person>().toList();
    final isTransaction = widget.kind == EditorKind.transaction;
    final color = _direction == Direction.income
        ? services.settings.incomeColor
        : services.settings.expenseColor;
    final inTransfer = widget.uuid != null && isTransaction && repo.transferOf(widget.uuid!) != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: [
          if (_isNew && isTransaction && widget.debt == null)
            IconButton(
              tooltip: l.applyModel,
              icon: const Icon(Icons.bookmarks_outlined),
              onPressed: _applyTemplate,
            ),
          PopupMenuButton<String>(
            itemBuilder: (context) => [
              if (isTransaction)
                PopupMenuItem(value: 'template', child: Text(l.saveAsModel)),
              if (!_isNew)
                PopupMenuItem(value: 'delete', child: Text(l.actionDelete)),
            ],
            onSelected: (v) => v == 'delete' ? _delete() : _saveAsTemplate(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: inTransfer ? null : _save,
        icon: const Icon(Icons.check),
        label: Text(l.actionSave),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            if (!_categoryLocked)
              SegmentedButton<int>(
                segments: [
                  ButtonSegment(
                      value: Direction.expense,
                      icon: const Icon(Icons.remove),
                      label: Text(l.expense)),
                  ButtonSegment(
                      value: Direction.income,
                      icon: const Icon(Icons.add),
                      label: Text(l.income)),
                  if (_isNew && widget.kind != EditorKind.model && widget.debt == null)
                    ButtonSegment(
                        value: -1,
                        icon: const Icon(Icons.swap_horiz),
                        label: Text(l.transfer)),
                ],
                selected: {_direction},
                onSelectionChanged: (s) {
                  if (s.first == -1) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        fullscreenDialog: true,
                        builder: (_) => TransferEditor(
                            recurrent: widget.kind == EditorKind.recurrent),
                      ),
                    );
                    return;
                  }
                  setState(() {
                    _direction = s.first;
                    final expected = _direction == Direction.income
                        ? CategoryType.income
                        : CategoryType.expense;
                    if (category != null && category.type != expected) {
                      _category = null;
                    }
                  });
                },
              ),
            if (inTransfer)
              Card(
                color: theme.colorScheme.secondaryContainer,
                child: ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(l.transferEditInfo),
                ),
              ),
            const SizedBox(height: 16),
            AmountField(
              controller: _amount,
              decimals: currency?.decimals ?? 2,
              currencySymbol: currency?.displaySymbol ?? '',
              autofocus: _isNew && widget.template == null && widget.debt == null,
              color: color,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l.description,
                prefixIcon: const Icon(Icons.short_text),
              ),
            ),
            const SizedBox(height: 8),
            PickerTile(
              icon: Icons.category_outlined,
              label: l.category,
              leading: category == null ? null : IconAvatar(category.icon),
              value: category == null
                  ? null
                  : context.categoryName(category.name, category.tag, category.type),
              error: _categoryError ? l.required : null,
              onTap: _categoryLocked
                  ? null
                  : () async {
                      final c = await pickCategory(context,
                          type: _direction == Direction.income
                              ? CategoryType.income
                              : CategoryType.expense);
                      if (c != null) {
                        setState(() {
                          _category = c.uuid;
                          _categoryError = false;
                        });
                      }
                    },
            ),
            PickerTile(
              icon: Icons.account_balance_wallet_outlined,
              label: l.wallet,
              leading: wallet == null ? null : IconAvatar(wallet.icon),
              value: wallet?.name,
              onTap: widget.debt != null
                  ? null
                  : () async {
                      final w = await pickWallet(context);
                      if (w != null) setState(() => _wallet = w.uuid);
                    },
            ),
            if (widget.kind == EditorKind.recurrent) ...[
              PickerTile(
                icon: Icons.event,
                label: l.startDate,
                value: context.formatDate(_date),
                onTap: () async {
                  final d = await pickDate(context, _date);
                  if (d != null) setState(() => _date = d);
                },
              ),
              RecurrenceField(
                rule: _rule,
                start: _date,
                onChanged: (r) => setState(() => _rule = r),
              ),
            ],
            if (isTransaction)
              Row(
                children: [
                  Expanded(
                    child: PickerTile(
                      icon: Icons.event,
                      label: l.date,
                      value: context.formatDate(_date),
                      onTap: () async {
                        final d = await pickDate(context, _date);
                        if (d != null) {
                          setState(() => _date = DateTime(d.year, d.month, d.day,
                              _date.hour, _date.minute, _date.second));
                        }
                      },
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.schedule),
                    label: Text(context.formatTime(_date)),
                    onPressed: () async {
                      final t = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(_date));
                      if (t != null) {
                        setState(() => _date = DateTime(
                            _date.year, _date.month, _date.day, t.hour, t.minute));
                      }
                    },
                  ),
                ],
              ),
            const Divider(),
            PickerTile(
              icon: Icons.celebration_outlined,
              label: l.event,
              leading: event == null ? null : IconAvatar(event.icon),
              value: event?.name,
              onClear: () => setState(() => _event = null),
              onTap: () async {
                final picked = await pickEntity(
                  context,
                  title: l.event,
                  items: [for (final e in repo.events()) (e.uuid, e.name, e.icon)],
                  onCreate: () => openEventEditor(context),
                );
                if (picked != null) setState(() => _event = picked.value);
              },
            ),
            PickerTile(
              icon: Icons.place_outlined,
              label: l.place,
              leading: place == null ? null : IconAvatar(place.icon),
              value: place?.name,
              onClear: () => setState(() => _place = null),
              onTap: () async {
                final picked = await pickEntity(
                  context,
                  title: l.place,
                  items: [for (final e in repo.places()) (e.uuid, e.name, e.icon)],
                  onCreate: () => openPlaceEditor(context),
                );
                if (picked != null) setState(() => _place = picked.value);
              },
            ),
            if (isTransaction)
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
            const SizedBox(height: 8),
            TextFormField(
              controller: _note,
              minLines: 1,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l.note,
                prefixIcon: const Icon(Icons.notes),
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.confirmed),
              subtitle: Text(l.confirmedHint),
              value: _confirmed,
              onChanged: (v) => setState(() => _confirmed = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.countInTotal),
              value: _countInTotal,
              onChanged: (v) => setState(() => _countInTotal = v),
            ),
            if (isTransaction) ...[
              const Divider(),
              AttachmentsSection(
                attachments: _attachments,
                dir: services.attachmentsDir,
                onAdd: _addAttachment,
                onRemove: (a) => setState(
                    () => _attachments = _attachments.where((x) => x.uuid != a.uuid).toList()),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
