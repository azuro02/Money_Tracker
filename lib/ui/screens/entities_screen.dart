import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_icon.dart';
import '../../core/dates.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../scope.dart';
import '../widgets/common.dart';
import '../widgets/form_fields.dart';
import '../widgets/pickers.dart';
import 'transactions_screen.dart';

Future<String?> openEventEditor(BuildContext context, {String? uuid}) =>
    Navigator.push<String>(context,
        MaterialPageRoute(fullscreenDialog: true, builder: (_) => EventEditor(uuid: uuid)));

Future<String?> openPersonEditor(BuildContext context, {String? uuid}) =>
    Navigator.push<String>(context,
        MaterialPageRoute(fullscreenDialog: true, builder: (_) => PersonEditor(uuid: uuid)));

Future<String?> openPlaceEditor(BuildContext context, {String? uuid}) =>
    Navigator.push<String>(context,
        MaterialPageRoute(fullscreenDialog: true, builder: (_) => PlaceEditor(uuid: uuid)));

/// Shared actions sheet for list entries.
Future<void> _entityActions(
  BuildContext context, {
  required String name,
  required VoidCallback onEdit,
  required VoidCallback onShowTransactions,
  required void Function() onDelete,
  List<Widget> extra = const [],
}) {
  final l = context.l10n;
  return showModalBottomSheet<void>(
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
              onShowTransactions();
            },
          ),
          ...extra,
          ListTile(
            leading: const Icon(Icons.edit),
            title: Text(l.actionEdit),
            onTap: () {
              Navigator.pop(sheet);
              onEdit();
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: Text(l.actionDelete),
            onTap: () async {
              Navigator.pop(sheet);
              if (await confirmDelete(context, name) && context.mounted) {
                guarded(context, onDelete);
              }
            },
          ),
        ],
      ),
    ),
  );
}

// ----------------------------------------------------------------- events

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final now = DateTime.now();
    final events = context.repo.events();
    final running = events.where((e) => e.isRunning(now)).toList();
    final completed = events.where((e) => !e.isRunning(now)).toList();
    Widget list(List<Event> items) => items.isEmpty
        ? EmptyState(icon: Icons.celebration_outlined, title: l.emptyList)
        : ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              for (final e in items)
                ListTile(
                  leading: IconAvatar(e.icon),
                  title: Text(e.name),
                  subtitle: Text(
                      '${context.formatShortDate(e.startDate)} – ${context.formatDate(e.endDate)}'),
                  onTap: () => _entityActions(
                    context,
                    name: e.name,
                    onEdit: () => openEventEditor(context, uuid: e.uuid),
                    onShowTransactions: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TransactionListScreen(
                            title: e.name, filter: TransactionFilter(event: e.uuid)),
                      ),
                    ),
                    onDelete: () => context.read.repo.deleteEvent(e.uuid),
                  ),
                ),
            ],
          );
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.events),
          bottom: TabBar(tabs: [Tab(text: l.eventRunning), Tab(text: l.eventCompleted)]),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => openEventEditor(context),
          child: const Icon(Icons.add),
        ),
        body: TabBarView(children: [list(running), list(completed)]),
      ),
    );
  }
}

class EventEditor extends StatefulWidget {
  const EventEditor({super.key, this.uuid});

  final String? uuid;

  @override
  State<EventEditor> createState() => _EventEditorState();
}

class _EventEditorState extends State<EventEditor> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _note = TextEditingController();
  AppIcon? _icon;
  DateTime _start = dateOnly(DateTime.now());
  DateTime _end = addDays(dateOnly(DateTime.now()), 7);
  List<String> _people = [];
  String? _tag;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    if (widget.uuid != null) {
      final repo = context.read.repo;
      final e = repo.event(widget.uuid!);
      if (e != null) {
        _name.text = e.name;
        _note.text = e.note ?? '';
        _icon = e.icon;
        _start = e.startDate;
        _end = e.endDate;
        _tag = e.tag;
        _people = repo.eventPeople(e.uuid);
      }
    }
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    final repo = context.read.repo;
    final uuid = widget.uuid ?? newUuid();
    final name = _name.text.trim();
    final ok = guarded(context, () {
      repo.saveEvent(Event(
        uuid: uuid,
        name: name,
        icon: _icon ?? randomColorIcon(name),
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        startDate: _start,
        endDate: _end.isBefore(_start) ? _start : _end,
        tag: _tag,
      ));
      repo.setEventPeople(uuid, _people);
    });
    if (ok) Navigator.pop(context, uuid);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final repo = context.repo;
    final people = _people.map(repo.person).whereType<Person>();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.uuid == null ? l.newEvent : l.editEvent),
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
              label: l.name,
              onIconTap: () async {
                final icon = await pickIcon(context, name: _name.text, current: _icon);
                if (icon != null) setState(() => _icon = icon);
              },
            ),
            const SizedBox(height: 8),
            PickerTile(
              icon: Icons.event,
              label: l.startDate,
              value: context.formatDate(_start),
              onTap: () async {
                final d = await pickDate(context, _start);
                if (d != null) setState(() => _start = d);
              },
            ),
            PickerTile(
              icon: Icons.event_available,
              label: l.endDate,
              value: context.formatDate(_end),
              onTap: () async {
                final d = await pickDate(context, _end, first: _start);
                if (d != null) setState(() => _end = d);
              },
            ),
            PickerTile(
              icon: Icons.people_outline,
              label: l.people,
              value: people.isEmpty ? null : people.map((p) => p.name).join(', '),
              onTap: () async {
                final picked = await pickPeople(context, _people,
                    onCreate: () => openPersonEditor(context));
                if (picked != null) setState(() => _people = picked);
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _note,
              maxLines: 4,
              minLines: 1,
              decoration: InputDecoration(labelText: l.note),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------- people

class PeopleScreen extends StatelessWidget {
  const PeopleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final people = context.repo.people();
    return Scaffold(
      appBar: AppBar(title: Text(l.people)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => openPersonEditor(context),
        child: const Icon(Icons.add),
      ),
      body: people.isEmpty
          ? EmptyState(icon: Icons.people_outline, title: l.emptyList)
          : ListView(
              padding: const EdgeInsets.only(bottom: 96),
              children: [
                for (final p in people)
                  ListTile(
                    leading: IconAvatar(p.icon),
                    title: Text(p.name),
                    subtitle: p.note == null ? null : Text(p.note!, maxLines: 1),
                    onTap: () => _entityActions(
                      context,
                      name: p.name,
                      onEdit: () => openPersonEditor(context, uuid: p.uuid),
                      onShowTransactions: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TransactionListScreen(
                              title: p.name, filter: TransactionFilter(person: p.uuid)),
                        ),
                      ),
                      onDelete: () => context.read.repo.deletePerson(p.uuid),
                    ),
                  ),
              ],
            ),
    );
  }
}

class PersonEditor extends StatefulWidget {
  const PersonEditor({super.key, this.uuid});

  final String? uuid;

  @override
  State<PersonEditor> createState() => _PersonEditorState();
}

class _PersonEditorState extends State<PersonEditor> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _note = TextEditingController();
  AppIcon? _icon;
  String? _tag;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    if (widget.uuid != null) {
      final p = context.read.repo.person(widget.uuid!);
      if (p != null) {
        _name.text = p.name;
        _note.text = p.note ?? '';
        _icon = p.icon;
        _tag = p.tag;
      }
    }
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    final uuid = widget.uuid ?? newUuid();
    final name = _name.text.trim();
    final ok = guarded(context, () {
      context.read.repo.savePerson(Person(
        uuid: uuid,
        name: name,
        icon: _icon ?? randomColorIcon(name),
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        tag: _tag,
      ));
    });
    if (ok) Navigator.pop(context, uuid);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.uuid == null ? l.newPerson : l.editPerson),
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
              label: l.name,
              onIconTap: () async {
                final icon = await pickIcon(context, name: _name.text, current: _icon);
                if (icon != null) setState(() => _icon = icon);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _note,
              maxLines: 4,
              minLines: 1,
              decoration: InputDecoration(labelText: l.note),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------- places

class PlacesScreen extends StatelessWidget {
  const PlacesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final places = context.repo.places();
    return Scaffold(
      appBar: AppBar(title: Text(l.places)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => openPlaceEditor(context),
        child: const Icon(Icons.add),
      ),
      body: places.isEmpty
          ? EmptyState(icon: Icons.place_outlined, title: l.emptyList)
          : ListView(
              padding: const EdgeInsets.only(bottom: 96),
              children: [
                for (final p in places)
                  ListTile(
                    leading: IconAvatar(p.icon),
                    title: Text(p.name),
                    subtitle: p.address == null ? null : Text(p.address!, maxLines: 1),
                    onTap: () => _entityActions(
                      context,
                      name: p.name,
                      onEdit: () => openPlaceEditor(context, uuid: p.uuid),
                      onShowTransactions: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TransactionListScreen(
                              title: p.name, filter: TransactionFilter(place: p.uuid)),
                        ),
                      ),
                      onDelete: () => context.read.repo.deletePlace(p.uuid),
                      extra: [
                        if (p.address != null || p.latitude != null)
                          ListTile(
                            leading: const Icon(Icons.map_outlined),
                            title: Text(l.actionOpenMap),
                            onTap: () {
                              Navigator.pop(context);
                              openInMaps(p);
                            },
                          ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

/// Hands the location to the system maps app (only on explicit user action;
/// the app itself never connects to the internet).
Future<void> openInMaps(Place p) async {
  final query = p.latitude != null && p.longitude != null
      ? '${p.latitude},${p.longitude}'
      : (p.address ?? p.name);
  final geo = Uri.parse('geo:0,0?q=${Uri.encodeComponent(query)}');
  if (await canLaunchUrl(geo)) {
    await launchUrl(geo);
    return;
  }
  // iOS: Apple Maps URL scheme.
  await launchUrl(Uri.parse('maps://?q=${Uri.encodeComponent(query)}'));
}

class PlaceEditor extends StatefulWidget {
  const PlaceEditor({super.key, this.uuid});

  final String? uuid;

  @override
  State<PlaceEditor> createState() => _PlaceEditorState();
}

class _PlaceEditorState extends State<PlaceEditor> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _lat = TextEditingController();
  final _lng = TextEditingController();
  AppIcon? _icon;
  String? _tag;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    if (widget.uuid != null) {
      final p = context.read.repo.place(widget.uuid!);
      if (p != null) {
        _name.text = p.name;
        _address.text = p.address ?? '';
        _lat.text = p.latitude?.toString() ?? '';
        _lng.text = p.longitude?.toString() ?? '';
        _icon = p.icon;
        _tag = p.tag;
      }
    }
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    for (final c in [_name, _address, _lat, _lng]) {
      c.dispose();
    }
    super.dispose();
  }

  double? _coordinate(String text) =>
      double.tryParse(text.trim().replaceAll(',', '.'));

  void _save() {
    if (!_form.currentState!.validate()) return;
    final uuid = widget.uuid ?? newUuid();
    final name = _name.text.trim();
    final lat = _coordinate(_lat.text);
    final lng = _coordinate(_lng.text);
    final ok = guarded(context, () {
      context.read.repo.savePlace(Place(
        uuid: uuid,
        name: name,
        icon: _icon ?? randomColorIcon(name),
        address: _address.text.trim().isEmpty ? null : _address.text.trim(),
        latitude: lat != null && lng != null ? lat : null,
        longitude: lat != null && lng != null ? lng : null,
        tag: _tag,
      ));
    });
    if (ok) Navigator.pop(context, uuid);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    String? validate(String? v, double max) {
      if (v == null || v.trim().isEmpty) return null;
      final d = _coordinate(v);
      return d == null || d.abs() > max ? l.invalidAmount : null;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.uuid == null ? l.newPlace : l.editPlace),
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
              label: l.name,
              onIconTap: () async {
                final icon = await pickIcon(context, name: _name.text, current: _icon);
                if (icon != null) setState(() => _icon = icon);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _address,
              maxLines: 3,
              minLines: 1,
              decoration: InputDecoration(labelText: l.address),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _lat,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true, signed: true),
                    decoration: InputDecoration(labelText: l.latitude),
                    validator: (v) => validate(v, 90),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _lng,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true, signed: true),
                    decoration: InputDecoration(labelText: l.longitude),
                    validator: (v) => validate(v, 180),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
