import 'package:flutter/material.dart';
import 'package:my_app/core/data/models/parish.dart';
import 'package:my_app/core/data/repositories/parish_repository.dart';
import 'package:my_app/shared/widgets/app_buttons.dart';

/// Admin: manage allowed parishes (used in business forms and directory filters).
class AdminParishesScreen extends StatefulWidget {
  const AdminParishesScreen({super.key, this.embeddedInShell = false});

  final bool embeddedInShell;

  @override
  State<AdminParishesScreen> createState() => _AdminParishesScreenState();
}

class _AdminParishesScreenState extends State<AdminParishesScreen> {
  final ParishRepository _repo = ParishRepository();
  List<Parish> _parishes = [];
  bool _loading = true;
  bool _reordering = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _repo.listParishes();
    if (mounted) {
      setState(() {
        _parishes = list;
        _loading = false;
      });
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (_reordering) return;
    if (oldIndex < newIndex) newIndex -= 1;
    if (oldIndex == newIndex) return;
    final item = _parishes.removeAt(oldIndex);
    _parishes.insert(newIndex, item);
    setState(() {});
    _persistOrder();
  }

  Future<void> _persistOrder() async {
    setState(() => _reordering = true);
    try {
      for (var i = 0; i < _parishes.length; i++) {
        await _repo.updateParish(_parishes[i].id, sortOrder: i);
      }
    } finally {
      if (mounted) setState(() => _reordering = false);
    }
  }

  Future<void> _addParish() async {
    final result = await showDialog<_ParishFormResult>(
      context: context,
      builder: (context) => const _AddParishDialog(),
    );
    if (result == null || result.id.trim().isEmpty || result.name.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      final sortOrder = _parishes.length;
      await _repo.insertParish(
        id: result.id.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_'),
        name: result.name.trim(),
        sortOrder: sortOrder,
      );
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Parish added')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add parish: $e')),
        );
      }
    }
  }

  Future<void> _editParish(Parish parish) async {
    final result = await showDialog<_ParishFormResult>(
      context: context,
      builder: (context) => _EditParishDialog(parish: parish),
    );
    if (result == null) return;
    if (result.name.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      await _repo.updateParish(parish.id, name: result.name.trim());
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Parish updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update parish: $e')),
        );
      }
    }
  }

  Future<void> _deleteParish(Parish parish) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete parish?'),
        content: Text(
          'Delete "${parish.name}"? Businesses using this parish may need to be updated.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          AppDangerButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _repo.deleteParish(parish.id);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Parish deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading && _parishes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    Widget body;
    if (_parishes.isEmpty) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No parishes. Add one to define allowed service areas.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else {
      body = ReorderableListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        itemCount: _parishes.length,
        onReorder: _onReorder,
        buildDefaultDragHandles: false,
        itemBuilder: (context, index) {
          final parish = _parishes[index];
          return _ParishTile(
            key: ValueKey(parish.id),
            parish: parish,
            index: index,
            onEdit: () => _editParish(parish),
            onDelete: () => _deleteParish(parish),
            reordering: _reordering,
          );
        },
      );
    }

    if (widget.embeddedInShell) {
      return Stack(
        children: [
          body,
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              onPressed: _reordering ? null : _addParish,
              tooltip: 'Add parish',
              child: const Icon(Icons.add_rounded),
            ),
          ),
        ],
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parishes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add parish',
            onPressed: _reordering ? null : _addParish,
          ),
        ],
      ),
      body: body,
    );
  }
}

class _ParishFormResult {
  const _ParishFormResult({required this.id, required this.name});
  final String id;
  final String name;
}

class _ParishTile extends StatelessWidget {
  const _ParishTile({
    super.key,
    required this.parish,
    required this.index,
    required this.onEdit,
    required this.onDelete,
    required this.reordering,
  });

  final Parish parish;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool reordering;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: ReorderableDragStartListener(
          index: index,
          child: Icon(
            Icons.drag_handle_rounded,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        title: Text(parish.name),
        subtitle: Text(parish.id, style: theme.textTheme.bodySmall),
        trailing: reordering
            ? null
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_rounded),
                    onPressed: onEdit,
                    tooltip: 'Edit',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: onDelete,
                    tooltip: 'Delete',
                  ),
                ],
              ),
      ),
    );
  }
}

class _AddParishDialog extends StatefulWidget {
  const _AddParishDialog();

  @override
  State<_AddParishDialog> createState() => _AddParishDialogState();
}

class _AddParishDialogState extends State<_AddParishDialog> {
  final _idController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  static String _toSlug(String name) {
    return name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
  }

  void _syncIdFromName() {
    final slug = _toSlug(_nameController.text);
    if (slug.isNotEmpty && (_idController.text.isEmpty || _idController.text == _toSlug(_nameController.text))) {
      _idController.text = slug;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New parish'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. St. Martin',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => _syncIdFromName(),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _idController,
              decoration: const InputDecoration(
                labelText: 'ID (slug)',
                hintText: 'e.g. st_martin',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Add'),
        ),
      ],
    );
  }

  void _submit() {
    final name = _nameController.text.trim();
    final id = _idController.text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
    if (name.isNotEmpty && id.isNotEmpty) {
      Navigator.of(context).pop(_ParishFormResult(id: id, name: name));
    }
  }
}

class _EditParishDialog extends StatefulWidget {
  const _EditParishDialog({required this.parish});

  final Parish parish;

  @override
  State<_EditParishDialog> createState() => _EditParishDialogState();
}

class _EditParishDialogState extends State<_EditParishDialog> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.parish.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit parish'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 8),
            Text(
              'ID: ${widget.parish.id}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      Navigator.of(context).pop(_ParishFormResult(id: widget.parish.id, name: name));
    }
  }
}
