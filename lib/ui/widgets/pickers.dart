import 'package:flutter/material.dart';

import '../../core/app_icon.dart';
import '../../data/models.dart';
import '../icons.dart';
import '../scope.dart';
import 'common.dart';

Future<T?> _sheet<T>(BuildContext context, Widget Function(BuildContext) builder) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .7,
        minChildSize: .4,
        maxChildSize: .95,
        builder: (context, controller) => PrimaryScrollController(
          controller: controller,
          child: builder(context),
        ),
      ),
    );

/// Searchable list in a bottom sheet.
class _SearchableList<T> extends StatefulWidget {
  const _SearchableList({
    required this.title,
    required this.items,
    required this.label,
    required this.tile,
    this.header,
  });

  final String title;
  final List<T> items;
  final String Function(T) label;
  final Widget Function(BuildContext, T) tile;
  final Widget? header;

  @override
  State<_SearchableList<T>> createState() => _SearchableListState<T>();
}

class _SearchableListState<T> extends State<_SearchableList<T>> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.toLowerCase();
    final items = q.isEmpty
        ? widget.items
        : widget.items.where((i) => widget.label(i).toLowerCase().contains(q)).toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
        ),
        if (widget.items.length > 8)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SearchBar(
              leading: const Icon(Icons.search),
              hintText: context.l10n.search,
              elevation: const WidgetStatePropertyAll(0),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
        ?widget.header,
        Expanded(
          child: ListView.builder(
            primary: true,
            itemCount: items.length,
            itemBuilder: (context, i) => widget.tile(context, items[i]),
          ),
        ),
      ],
    );
  }
}

/// Category picker; returns the chosen category. [types] limits the
/// category types shown.
Future<Category?> pickCategory(BuildContext context, {required int type}) {
  final repo = context.read.repo;
  final all = repo.categories(type: type);
  final parents = all.where((c) => c.parent == null).toList();
  final ordered = <Category>[
    for (final p in parents) ...[
      p,
      ...all.where((c) => c.parent == p.uuid),
    ],
  ];
  return _sheet(
    context,
    (context) => _SearchableList<Category>(
      title: context.l10n.category,
      items: ordered,
      label: (c) => context.categoryName(c.name, c.tag, c.type),
      tile: (context, c) => ListTile(
        contentPadding: EdgeInsets.only(left: c.parent == null ? 16 : 48, right: 16),
        leading: IconAvatar(c.icon, size: c.parent == null ? 40 : 32),
        title: Text(context.categoryName(c.name, c.tag, c.type)),
        onTap: () => Navigator.pop(context, c),
      ),
    ),
  );
}

Future<Wallet?> pickWallet(BuildContext context, {String? exclude}) {
  final wallets = context.read.repo
      .wallets(includeArchived: false)
      .where((w) => w.uuid != exclude)
      .toList();
  return _sheet(
    context,
    (context) => _SearchableList<Wallet>(
      title: context.l10n.wallet,
      items: wallets,
      label: (w) => w.name,
      tile: (context, w) => ListTile(
        leading: IconAvatar(w.icon),
        title: Text(w.name),
        subtitle: Text(w.currency),
        trailing: MoneyText(context.repo.walletBalance(w.uuid), w.currency),
        onTap: () => Navigator.pop(context, w),
      ),
    ),
  );
}

Future<Currency?> pickCurrency(BuildContext context) {
  final currencies = context.read.repo.currencies();
  return _sheet(
    context,
    (context) => _SearchableList<Currency>(
      title: context.l10n.currency,
      items: currencies,
      label: (c) => '${c.iso} ${c.name}',
      tile: (context, c) => ListTile(
        leading: CircleAvatar(child: Text(c.displaySymbol, maxLines: 1)),
        title: Text(c.name),
        subtitle: Text(c.iso),
        trailing: c.favourite ? const Icon(Icons.star, size: 18) : null,
        onTap: () => Navigator.pop(context, c),
      ),
    ),
  );
}

/// Result wrapper so that "none" can be distinguished from "cancelled".
class Picked<T> {
  const Picked(this.value);

  final T? value;
}

Future<Picked<String>?> pickEntity(
  BuildContext context, {
  required String title,
  required List<(String uuid, String name, AppIcon icon)> items,
  Future<String?> Function()? onCreate,
}) {
  return _sheet(
    context,
    (context) => _SearchableList<(String, String, AppIcon)>(
      title: title,
      items: items,
      label: (i) => i.$2,
      header: Column(
        children: [
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.block)),
            title: Text(context.l10n.actionNone),
            onTap: () => Navigator.pop(context, const Picked<String>(null)),
          ),
          if (onCreate != null)
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.add)),
            title: Text(context.l10n.actionAdd),
            onTap: () async {
              final created = await onCreate();
              if (created != null && context.mounted) {
                Navigator.pop(context, Picked(created));
              }
            },
          ),
          const Divider(height: 1),
        ],
      ),
      tile: (context, i) => ListTile(
        leading: IconAvatar(i.$3),
        title: Text(i.$2),
        onTap: () => Navigator.pop(context, Picked(i.$1)),
      ),
    ),
  );
}

Future<List<String>?> pickPeople(BuildContext context, List<String> selected,
    {required Future<String?> Function() onCreate}) {
  return _sheet(
    context,
    (context) => _PeoplePicker(selected: selected, onCreate: onCreate),
  );
}

class _PeoplePicker extends StatefulWidget {
  const _PeoplePicker({required this.selected, required this.onCreate});

  final List<String> selected;
  final Future<String?> Function() onCreate;

  @override
  State<_PeoplePicker> createState() => _PeoplePickerState();
}

class _PeoplePickerState extends State<_PeoplePicker> {
  late final Set<String> _selected = widget.selected.toSet();

  @override
  Widget build(BuildContext context) {
    final people = context.repo.people();
    final l = context.l10n;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
          child: Row(
            children: [
              Expanded(
                  child: Text(l.people,
                      style: Theme.of(context).textTheme.titleLarge)),
              FilledButton(
                onPressed: () => Navigator.pop(context, _selected.toList()),
                child: Text(l.actionOk),
              ),
            ],
          ),
        ),
        ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person_add)),
          title: Text(l.newPerson),
          onTap: () async {
            final created = await widget.onCreate();
            if (created != null) setState(() => _selected.add(created));
          },
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            primary: true,
            children: [
              for (final p in people)
                CheckboxListTile(
                  secondary: IconAvatar(p.icon),
                  title: Text(p.name),
                  value: _selected.contains(p.uuid),
                  onChanged: (v) => setState(() =>
                      v == true ? _selected.add(p.uuid) : _selected.remove(p.uuid)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Icon picker: colored circle with initials or a symbol.
Future<AppIcon?> pickIcon(BuildContext context, {required String name, AppIcon? current}) {
  return _sheet(context, (context) => _IconPicker(name: name, current: current));
}

class _IconPicker extends StatefulWidget {
  const _IconPicker({required this.name, this.current});

  final String name;
  final AppIcon? current;

  @override
  State<_IconPicker> createState() => _IconPickerState();
}

class _IconPickerState extends State<_IconPicker> {
  late String _color = switch (widget.current) {
    ColorIcon(:final color) => color,
    _ => materialIconColors[widget.name.length % materialIconColors.length],
  };

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final initials = iconInitials(widget.name);
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(tabs: [Tab(text: l.iconInitials), Tab(text: l.iconSymbol)]),
          Expanded(
            child: TabBarView(
              children: [
                ListView(
                  primary: true,
                  padding: const EdgeInsets.all(16),
                  children: [
                    Center(child: IconAvatar(ColorIcon(_color, initials), size: 72)),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        for (final c in materialIconColors)
                          InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => setState(() => _color = c),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Color(ColorIcon(c, '').argb),
                                shape: BoxShape.circle,
                                border: c == _color
                                    ? Border.all(
                                        width: 3,
                                        color: Theme.of(context).colorScheme.onSurface)
                                    : null,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () =>
                          Navigator.pop(context, ColorIcon(_color, initials)),
                      child: Text(l.actionSelect),
                    ),
                  ],
                ),
                ListView(
                  primary: false,
                  padding: const EdgeInsets.all(12),
                  children: [
                    for (final group in iconGroups.values)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final entry in group.entries)
                              InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () => Navigator.pop(
                                    context, ResourceIcon(entry.key)),
                                child: IconAvatar(ResourceIcon(entry.key), size: 48),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<DateTime?> pickDate(BuildContext context, DateTime initial,
    {DateTime? first, DateTime? last}) {
  return showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: first ?? DateTime(1900),
    lastDate: last ?? DateTime(2100),
  );
}
