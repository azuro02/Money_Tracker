import 'package:flutter/material.dart';

import '../../core/app_icon.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../scope.dart';
import '../widgets/common.dart';
import '../widgets/form_fields.dart';
import '../widgets/pickers.dart';
import 'transactions_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  bool _sorting = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return DefaultTabController(
      length: 3,
      child: Builder(builder: (context) {
        return Scaffold(
          appBar: AppBar(
            title: Text(l.categories),
            actions: [
              IconButton(
                tooltip: l.actionSort,
                isSelected: _sorting,
                icon: const Icon(Icons.sort),
                onPressed: () => setState(() => _sorting = !_sorting),
              ),
            ],
            bottom: TabBar(tabs: [
              Tab(text: l.expenses),
              Tab(text: l.incomes),
              Tab(text: l.systemCategories),
            ]),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              final tab = DefaultTabController.of(context).index;
              Navigator.push(
                context,
                MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (_) => CategoryEditor(
                      type: tab == 1 ? CategoryType.income : CategoryType.expense),
                ),
              );
            },
            child: const Icon(Icons.add),
          ),
          body: TabBarView(
            children: [
              _CategoryList(type: CategoryType.expense, sorting: _sorting),
              _CategoryList(type: CategoryType.income, sorting: _sorting),
              _CategoryList(type: CategoryType.system, sorting: false),
            ],
          ),
        );
      }),
    );
  }
}

class _CategoryList extends StatelessWidget {
  const _CategoryList({required this.type, required this.sorting});

  final int type;
  final bool sorting;

  @override
  Widget build(BuildContext context) {
    final repo = context.repo;
    final all = repo.categories(type: type);
    final parents = all.where((c) => c.parent == null).toList();
    if (all.isEmpty) {
      return EmptyState(icon: Icons.category_outlined, title: context.l10n.emptyList);
    }
    if (sorting) {
      return ReorderableListView(
        onReorder: (from, to) {
          final ids = parents.map((c) => c.uuid).toList();
          final moved = ids.removeAt(from);
          ids.insert(to > from ? to - 1 : to, moved);
          repo.reorderCategories(ids);
        },
        children: [
          for (final c in parents)
            ListTile(
              key: ValueKey(c.uuid),
              leading: IconAvatar(c.icon),
              title: Text(context.categoryName(c.name, c.tag, c.type)),
              trailing: const Icon(Icons.drag_handle),
            ),
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        for (final p in parents) ...[
          _tile(context, p),
          for (final c in all.where((c) => c.parent == p.uuid)) _tile(context, c),
        ],
      ],
    );
  }

  Widget _tile(BuildContext context, Category c) {
    final l = context.l10n;
    return ListTile(
      contentPadding: EdgeInsets.only(left: c.parent == null ? 16 : 56, right: 16),
      leading: IconAvatar(c.icon, size: c.parent == null ? 40 : 32),
      title: Text(context.categoryName(c.name, c.tag, c.type)),
      trailing: c.showReport ? null : const Icon(Icons.visibility_off_outlined, size: 18),
      onTap: () => showModalBottomSheet<void>(
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
                        title: context.categoryName(c.name, c.tag, c.type),
                        filter: TransactionFilter(category: c.uuid),
                      ),
                    ),
                  );
                },
              ),
              if (!c.isSystem) ...[
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: Text(l.actionEdit),
                  onTap: () {
                    Navigator.pop(sheet);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        fullscreenDialog: true,
                        builder: (_) => CategoryEditor(uuid: c.uuid, type: c.type),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: Text(l.actionDelete),
                  onTap: () async {
                    Navigator.pop(sheet);
                    if (await confirmDelete(context, c.name) && context.mounted) {
                      guarded(context, () => context.read.repo.deleteCategory(c.uuid));
                    }
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class CategoryEditor extends StatefulWidget {
  const CategoryEditor({super.key, this.uuid, required this.type});

  final String? uuid;
  final int type;

  @override
  State<CategoryEditor> createState() => _CategoryEditorState();
}

class _CategoryEditorState extends State<CategoryEditor> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  AppIcon? _icon;
  late int _type = widget.type;
  String? _parent;
  bool _showReport = true;
  Category? _existing;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    if (widget.uuid != null) {
      final c = context.read.repo.category(widget.uuid!);
      if (c != null) {
        _existing = c;
        _name.text = c.name;
        _icon = c.icon;
        _type = c.type;
        _parent = c.parent;
        _showReport = c.showReport;
      }
    }
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    final repo = context.read.repo;
    final name = _name.text.trim();
    final ok = guarded(context, () {
      repo.saveCategory(Category(
        uuid: _existing?.uuid ?? newUuid(),
        name: name,
        icon: _icon ?? randomColorIcon(name),
        type: _type,
        parent: _parent,
        tag: _existing?.tag,
        showReport: _showReport,
        index: _existing?.index ?? repo.categories(type: _type).length,
      ));
    });
    if (ok) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final repo = context.repo;
    final hasChildren = _existing != null &&
        repo.categories(type: _type).any((c) => c.parent == _existing!.uuid);
    final parents = repo
        .categories(type: _type)
        .where((c) => c.parent == null && c.uuid != _existing?.uuid)
        .toList();
    final parent = _parent == null ? null : repo.category(_parent!);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.uuid == null ? l.newCategory : l.editCategory),
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
              label: l.categoryName,
              onIconTap: () async {
                final icon = await pickIcon(context, name: _name.text, current: _icon);
                if (icon != null) setState(() => _icon = icon);
              },
            ),
            const SizedBox(height: 16),
            SegmentedButton<int>(
              segments: [
                ButtonSegment(value: CategoryType.expense, label: Text(l.expense)),
                ButtonSegment(value: CategoryType.income, label: Text(l.income)),
              ],
              selected: {_type},
              onSelectionChanged: _parent != null
                  ? null
                  : (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 8),
            if (!hasChildren)
              PickerTile(
                icon: Icons.account_tree_outlined,
                label: l.parentCategory,
                leading: parent == null ? null : IconAvatar(parent.icon),
                value: parent?.name ?? l.noParent,
                onClear: parent == null ? null : () => setState(() => _parent = null),
                onTap: () async {
                  final picked = await pickEntity(
                    context,
                    title: l.parentCategory,
                    items: [for (final c in parents) (c.uuid, c.name, c.icon)],
                  );
                  if (picked != null) setState(() => _parent = picked.value);
                },
              ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.showInReports),
              value: _showReport,
              onChanged: (v) => setState(() => _showReport = v),
            ),
          ],
        ),
      ),
    );
  }
}
