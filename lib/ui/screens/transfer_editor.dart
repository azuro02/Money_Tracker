import 'package:flutter/material.dart';

import '../../core/calculator.dart';
import '../../core/dates.dart';
import '../../core/money.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../scope.dart';
import '../widgets/attachments.dart';
import '../widgets/common.dart';
import '../widgets/form_fields.dart';
import '../widgets/pickers.dart';
import '../widgets/recurrence_picker.dart';
import 'entities_screen.dart';

Future<void> openTransferEditor(
  BuildContext context, {
  String? transferUuid,
  String? modelUuid,
  String? recurrenceUuid,
  bool model = false,
  bool recurrent = false,
}) {
  return Navigator.push(
    context,
    MaterialPageRoute(
      fullscreenDialog:
          transferUuid == null && modelUuid == null && recurrenceUuid == null,
      builder: (_) => TransferEditor(
        transferUuid: transferUuid,
        modelUuid: modelUuid,
        recurrenceUuid: recurrenceUuid,
        model: model || modelUuid != null,
        recurrent: recurrent || recurrenceUuid != null,
      ),
    ),
  );
}

/// Editor for transfers, transfer templates and recurrent transfers.
class TransferEditor extends StatefulWidget {
  const TransferEditor({
    super.key,
    this.transferUuid,
    this.modelUuid,
    this.recurrenceUuid,
    this.model = false,
    this.recurrent = false,
    this.template,
  });

  final String? transferUuid;
  final String? modelUuid;
  final String? recurrenceUuid;
  final bool model;
  final bool recurrent;
  final TransferModel? template;

  @override
  State<TransferEditor> createState() => _TransferEditorState();
}

class _TransferEditorState extends State<TransferEditor> {
  final _form = GlobalKey<FormState>();
  final _fromAmount = TextEditingController();
  final _toAmount = TextEditingController();
  final _fee = TextEditingController();
  final _description = TextEditingController();
  final _note = TextEditingController();
  bool _initialized = false;
  bool _toEdited = false;

  String? _from;
  String? _to;
  DateTime _date = DateTime.now();
  String? _event;
  String? _place;
  List<String> _people = [];
  List<Attachment> _attachments = [];
  bool _confirmed = true;
  bool _countInTotal = true;
  String _rule = 'FREQ=MONTHLY';
  String? _tag;
  String? _walletError;

  bool get _isNew =>
      widget.transferUuid == null &&
      widget.modelUuid == null &&
      widget.recurrenceUuid == null;

  bool get _isTransfer => !widget.model && !widget.recurrent;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final repo = context.read.repo;
    _from = context.read.settings.currentWallet;
    String fmt(int v, String wallet) => minorToPlainString(
        v, repo.currency(repo.wallet(wallet)?.currency ?? '')?.decimals ?? 2);
    void common(String from, String to, int fromMoney, int toMoney, int tax,
        String? description, String? note, String? event, String? place,
        bool confirmed, bool count) {
      _from = from;
      _to = to;
      _fromAmount.text = fmt(fromMoney, from);
      _toAmount.text = fmt(toMoney, to);
      _toEdited = fromMoney != toMoney;
      if (tax > 0) _fee.text = fmt(tax, from);
      _description.text = description ?? '';
      _note.text = note ?? '';
      _event = event;
      _place = place;
      _confirmed = confirmed;
      _countInTotal = count;
    }

    if (widget.transferUuid != null) {
      final v = repo.transferView(widget.transferUuid!);
      if (v != null) {
        final t = v.transfer;
        common(v.fromWallet, v.toWallet, v.fromMoney, v.toMoney, v.taxMoney,
            t.description, t.note, t.event, t.place, t.confirmed, t.countInTotal);
        _date = t.date;
        _people = repo.transferPeople(t.uuid);
        _attachments = repo.transferAttachments(t.uuid);
        _tag = t.tag;
      }
    } else if (widget.modelUuid != null || widget.template != null) {
      final m = widget.template ??
          repo.transferModels().where((m) => m.uuid == widget.modelUuid).firstOrNull;
      if (m != null) {
        common(m.fromWallet, m.toWallet, m.fromMoney, m.toMoney, m.taxMoney,
            m.description, m.note, m.event, m.place, m.confirmed, m.countInTotal);
        if (widget.modelUuid != null) _tag = m.tag;
      }
    } else if (widget.recurrenceUuid != null) {
      final r = repo.recurrentTransfer(widget.recurrenceUuid!);
      if (r != null) {
        common(r.fromWallet, r.toWallet, r.fromMoney, r.toMoney, r.taxMoney,
            r.description, r.note, r.event, r.place, r.confirmed, r.countInTotal);
        _date = r.startDate;
        _rule = r.rule;
        _tag = r.tag;
      }
    }
    _fromAmount.addListener(() {
      if (!_toEdited) _toAmount.text = _fromAmount.text;
    });
  }

  @override
  void dispose() {
    for (final c in [_fromAmount, _toAmount, _fee, _description, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    final repo = context.read.repo;
    final valid = _form.currentState!.validate();
    setState(() {
      _walletError = (_from == null || _to == null)
          ? context.l10n.required
          : (_from == _to ? context.l10n.errorSameWallet : null);
    });
    if (!valid || _walletError != null) return;
    final fromCurrency = repo.currency(repo.wallet(_from!)!.currency);
    final toCurrency = repo.currency(repo.wallet(_to!)!.currency);
    final fromMoney = evaluateAmount(_fromAmount.text, fromCurrency?.decimals ?? 2)!.abs();
    final sameCurrency = fromCurrency?.iso == toCurrency?.iso;
    final toMoney = sameCurrency
        ? fromMoney
        : evaluateAmount(_toAmount.text, toCurrency?.decimals ?? 2)!.abs();
    final tax = _fee.text.trim().isEmpty
        ? 0
        : (evaluateAmount(_fee.text, fromCurrency?.decimals ?? 2) ?? 0).abs();
    String? text(TextEditingController c) =>
        c.text.trim().isEmpty ? null : c.text.trim();
    final services = context.read;
    final ok = guarded(context, () {
      if (widget.model) {
        repo.saveTransferModel(TransferModel(
          uuid: widget.modelUuid ?? newUuid(),
          description: text(_description),
          fromWallet: _from!,
          toWallet: _to!,
          fromMoney: fromMoney,
          toMoney: toMoney,
          taxMoney: tax,
          note: text(_note),
          event: _event,
          place: _place,
          confirmed: _confirmed,
          countInTotal: _countInTotal,
          tag: _tag,
        ));
      } else if (widget.recurrent) {
        services.recurrences.saveRecurrentTransfer(RecurrentTransfer(
          uuid: widget.recurrenceUuid ?? newUuid(),
          description: text(_description),
          fromWallet: _from!,
          toWallet: _to!,
          fromMoney: fromMoney,
          toMoney: toMoney,
          taxMoney: tax,
          note: text(_note),
          event: _event,
          place: _place,
          confirmed: _confirmed,
          countInTotal: _countInTotal,
          startDate: dateOnly(_date),
          lastOccurrence: dateOnly(_date),
          rule: _rule,
          tag: _tag,
        ));
      } else {
        repo.saveTransfer(TransferInput(
          uuid: widget.transferUuid,
          fromWallet: _from!,
          toWallet: _to!,
          fromMoney: fromMoney,
          toMoney: toMoney,
          taxMoney: tax,
          date: _date,
          description: text(_description),
          note: text(_note),
          place: _place,
          event: _event,
          confirmed: _confirmed,
          countInTotal: _countInTotal,
          people: _people,
          attachments: _attachments.map((a) => a.uuid).toList(),
          tag: _tag,
        ));
        cleanupOrphanAttachments(services);
      }
    });
    if (ok) Navigator.pop(context, true);
  }

  Future<void> _delete() async {
    final l = context.l10n;
    if (!await confirmDelete(context,
        _description.text.isEmpty ? l.transfer : _description.text)) {
      return;
    }
    if (!mounted) return;
    final services = context.read;
    final ok = guarded(context, () {
      if (widget.transferUuid != null) {
        services.repo.deleteTransfer(widget.transferUuid!);
        cleanupOrphanAttachments(services);
      } else if (widget.modelUuid != null) {
        services.repo.deleteTransferModel(widget.modelUuid!);
      } else if (widget.recurrenceUuid != null) {
        services.repo.deleteRecurrentTransfer(widget.recurrenceUuid!);
      }
    });
    if (ok && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final services = context.services;
    final repo = services.repo;
    final from = _from == null ? null : repo.wallet(_from!);
    final to = _to == null ? null : repo.wallet(_to!);
    final fromCurrency = from == null ? null : repo.currency(from.currency);
    final toCurrency = to == null ? null : repo.currency(to.currency);
    final differentCurrency =
        fromCurrency != null && toCurrency != null && fromCurrency.iso != toCurrency.iso;
    final event = _event == null ? null : repo.event(_event!);
    final place = _place == null ? null : repo.place(_place!);
    final people = _people.map(repo.person).whereType<Person>().toList();
    String? rate;
    if (differentCurrency) {
      final a = evaluateAmount(_fromAmount.text, fromCurrency.decimals);
      final b = evaluateAmount(_toAmount.text, toCurrency.decimals);
      if (a != null && b != null && a > 0) {
        final value = (b / _pow(toCurrency.decimals)) / (a / _pow(fromCurrency.decimals));
        rate = value.toStringAsFixed(4);
      }
    }
    final title = widget.model
        ? (_isNew ? l.newTransferModel : l.editModel)
        : widget.recurrent
            ? (_isNew ? l.newRecurrentTransfer : l.editRecurrence)
            : (_isNew ? l.newTransfer : l.editTransfer);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (!_isNew)
            IconButton(
              tooltip: l.actionDelete,
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _save,
        icon: const Icon(Icons.check),
        label: Text(l.actionSave),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            PickerTile(
              icon: Icons.north_east,
              label: l.fromWallet,
              leading: from == null ? null : IconAvatar(from.icon),
              value: from == null ? null : '${l.fromWallet}: ${from.name}',
              error: _walletError,
              onTap: () async {
                final w = await pickWallet(context, exclude: _to);
                if (w != null) setState(() => _from = w.uuid);
              },
            ),
            Center(
              child: IconButton.filledTonal(
                icon: const Icon(Icons.swap_vert),
                onPressed: () => setState(() {
                  final f = _from;
                  _from = _to;
                  _to = f;
                }),
              ),
            ),
            PickerTile(
              icon: Icons.south_west,
              label: l.toWallet,
              leading: to == null ? null : IconAvatar(to.icon),
              value: to == null ? null : '${l.toWallet}: ${to.name}',
              error: _walletError,
              onTap: () async {
                final w = await pickWallet(context, exclude: _from);
                if (w != null) setState(() => _to = w.uuid);
              },
            ),
            const SizedBox(height: 12),
            AmountField(
              controller: _fromAmount,
              decimals: fromCurrency?.decimals ?? 2,
              currencySymbol: fromCurrency?.displaySymbol ?? '',
              autofocus: _isNew && widget.template == null,
            ),
            if (differentCurrency) ...[
              const SizedBox(height: 12),
              Focus(
                onFocusChange: (f) {
                  if (f) _toEdited = true;
                },
                child: AmountField(
                  controller: _toAmount,
                  decimals: toCurrency.decimals,
                  currencySymbol: toCurrency.displaySymbol,
                  label: l.amountReceived,
                ),
              ),
              if (rate != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 12),
                  child: Text(l.exchangeRate(fromCurrency.iso, rate, toCurrency.iso),
                      style: Theme.of(context).textTheme.bodySmall),
                ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: _fee,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: l.fee,
                prefixIcon: const Icon(Icons.percent),
                suffixText: fromCurrency?.displaySymbol,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final fee = evaluateAmount(v, fromCurrency?.decimals ?? 2);
                return fee == null || fee < 0 ? l.invalidAmount : null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                  labelText: l.description, prefixIcon: const Icon(Icons.short_text)),
            ),
            if (widget.recurrent) ...[
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
                  onChanged: (r) => setState(() => _rule = r)),
            ],
            if (_isTransfer)
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
                          setState(() => _date = DateTime(
                              d.year, d.month, d.day, _date.hour, _date.minute));
                        }
                      },
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.schedule),
                    label: Text(context.formatTime(_date)),
                    onPressed: () async {
                      final t = await showTimePicker(
                          context: context, initialTime: TimeOfDay.fromDateTime(_date));
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
                final picked = await pickEntity(context,
                    title: l.event,
                    items: [for (final e in repo.events()) (e.uuid, e.name, e.icon)],
                    onCreate: () => openEventEditor(context));
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
                final picked = await pickEntity(context,
                    title: l.place,
                    items: [for (final e in repo.places()) (e.uuid, e.name, e.icon)],
                    onCreate: () => openPlaceEditor(context));
                if (picked != null) setState(() => _place = picked.value);
              },
            ),
            if (_isTransfer)
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
              decoration: InputDecoration(
                  labelText: l.note, prefixIcon: const Icon(Icons.notes)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.confirmed),
              value: _confirmed,
              onChanged: (v) => setState(() => _confirmed = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.countInTotal),
              value: _countInTotal,
              onChanged: (v) => setState(() => _countInTotal = v),
            ),
            if (_isTransfer) ...[
              const Divider(),
              AttachmentsSection(
                attachments: _attachments,
                dir: services.attachmentsDir,
                onAdd: (source) async {
                  final a = await addAttachment(context, source);
                  if (a != null && mounted) {
                    setState(() => _attachments = [..._attachments, a]);
                  }
                },
                onRemove: (a) => setState(() =>
                    _attachments = _attachments.where((x) => x.uuid != a.uuid).toList()),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

double _pow(int decimals) {
  var v = 1.0;
  for (var i = 0; i < decimals; i++) {
    v *= 10;
  }
  return v;
}
