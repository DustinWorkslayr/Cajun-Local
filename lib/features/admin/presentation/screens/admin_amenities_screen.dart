import 'package:flutter/material.dart';
import 'package:cajun_local/features/businesses/data/models/amenity.dart';
import 'package:cajun_local/features/businesses/data/repositories/amenities_repository.dart';
import 'package:cajun_local/shared/widgets/app_buttons.dart';
import 'package:uuid/uuid.dart';

/// Bucket options for amenities (global, eat, hire, shop, explore).
const _kBucketOptions = [
  ('global', 'Global'),
  ('eat', 'Eat'),
  ('hire', 'Hire'),
  ('shop', 'Shop'),
  ('explore', 'Explore'),
];

/// Admin: CRUD for amenities master list. Edit-in-place in list; add via FAB; delete with confirm.
class AdminAmenitiesScreen extends StatefulWidget {
  const AdminAmenitiesScreen({super.key, this.embeddedInShell = false});

  final bool embeddedInShell;

  @override
  State<AdminAmenitiesScreen> createState() => _AdminAmenitiesScreenState();
}

class _AdminAmenitiesScreenState extends State<AdminAmenitiesScreen> {
  final AmenitiesRepository _repo = AmenitiesRepository();
  List<Amenity> _amenities = [];
  bool _loading = true;
  String? _filterBucket;
  String? _editingId;
  String _editingBucket = 'global';
  final Map<String, TextEditingController> _editControllers = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _editControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _repo.getAllForAdmin(bucket: _filterBucket);
      if (mounted) {
        setState(() {
          _amenities = list;
          _loading = false;
          _editingId = null;
          for (final c in _editControllers.values) {
            c.dispose();
          }
          _editControllers.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load amenities: $e')));
      }
    }
  }

  static String _slugify(String name) {
    final s = name.trim().toLowerCase();
    if (s.isEmpty) return '';
    return s.replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-|-$'), '');
  }

  int get _nextSortOrder {
    if (_amenities.isEmpty) return 0;
    final maxOrder = _amenities.map((a) => a.sortOrder).reduce((a, b) => a > b ? a : b);
    return maxOrder + 1;
  }

  Future<void> _addAmenity() async {
    final result = await showDialog<_AmenityFormData>(
      context: context,
      builder: (context) => _AddAmenityDialog(nextSortOrder: _nextSortOrder),
    );
    if (result == null || result.name.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      final slug = (result.slug != null && result.slug!.trim().isNotEmpty)
          ? result.slug!.trim()
          : _slugify(result.name);
      if (slug.isEmpty) throw StateError('Slug is required');
      await _repo.insertAmenity({
        'id': const Uuid().v4(),
        'name': result.name.trim(),
        'slug': slug,
        'bucket': result.bucket,
        'sort_order': result.sortOrder,
      });
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Amenity added')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add: $e')));
      }
    }
  }

  void _startEdit(Amenity a) {
    _editControllers[a.id] = TextEditingController(text: a.name);
    _editControllers['${a.id}_slug'] = TextEditingController(text: a.slug);
    setState(() {
      _editingId = a.id;
      _editingBucket = a.bucket;
    });
  }

  void _cancelEdit() {
    for (final c in _editControllers.values) {
      c.dispose();
    }
    _editControllers.clear();
    setState(() => _editingId = null);
  }

  Future<void> _saveEdit(Amenity a) async {
    final nameC = _editControllers[a.id];
    final slugC = _editControllers['${a.id}_slug'];
    if (nameC == null || slugC == null) return;
    final name = nameC.text.trim();
    final slug = slugC.text.trim();
    if (name.isEmpty || slug.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name and slug are required')));
      return;
    }
    setState(() => _loading = true);
    try {
      await _repo.updateAmenity(a.id, {'name': name, 'slug': slug, 'bucket': _editingBucket});
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Amenity updated')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
      }
    }
  }

  Future<void> _deleteAmenity(Amenity a) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete amenity?'),
        content: Text('Delete "${a.name}"? Businesses that selected this amenity will have it removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          AppDangerButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _repo.deleteAmenity(a.id);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Amenity deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading && _amenities.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    Widget body;
    if (_amenities.isEmpty) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _filterBucket != null
                ? 'No amenities in "$_filterBucket".'
                : 'No amenities. Add one to define options for businesses.',
            style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else {
      body = ReorderableListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        itemCount: _amenities.length,
        buildDefaultDragHandles: false,
        onReorder: (oldIndex, newIndex) {
          if (oldIndex < newIndex) newIndex--;
          final copy = List<Amenity>.from(_amenities);
          final item = copy.removeAt(oldIndex);
          copy.insert(newIndex, item);
          setState(() => _amenities = copy);
          final orders = copy.asMap().entries.map((e) => {'id': e.value.id, 'sort_order': e.key}).toList();
          final messenger = ScaffoldMessenger.of(context);
          _repo
              .updateAmenitiesSortOrder(orders)
              .then((_) {
                if (mounted) {
                  messenger.showSnackBar(const SnackBar(content: Text('Order saved')));
                }
              })
              .catchError((e) {
                if (mounted) {
                  setState(() => _load());
                  messenger.showSnackBar(SnackBar(content: Text('Failed to save order: $e')));
                }
              });
        },
        itemBuilder: (context, index) {
          final a = _amenities[index];
          final isEditing = _editingId == a.id;
          return _AmenityTile(
            key: ValueKey(a.id),
            index: index,
            amenity: a,
            isEditing: isEditing,
            editingBucket: _editingBucket,
            onBucketChanged: (v) => setState(() => _editingBucket = v),
            nameController: _editControllers[a.id],
            slugController: _editControllers['${a.id}_slug'],
            onStartEdit: () => _startEdit(a),
            onCancelEdit: _cancelEdit,
            onSaveEdit: () => _saveEdit(a),
            onDelete: () => _deleteAmenity(a),
          );
        },
      );
    }

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!widget.embeddedInShell)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                  'Manage master list of amenities (global + per-bucket). Businesses pick from these.',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text('Filter:', style: theme.textTheme.labelLarge),
                  const SizedBox(width: 8),
                  DropdownButton<String?>(
                    value: _filterBucket,
                    hint: const Text('All buckets'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All buckets')),
                      for (final o in _kBucketOptions) DropdownMenuItem(value: o.$1, child: Text(o.$2)),
                    ],
                    onChanged: (v) {
                      setState(() => _filterBucket = v);
                      _load();
                    },
                  ),
                ],
              ),
            ),
            Expanded(child: body),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: _loading ? null : _addAmenity,
            tooltip: 'Add amenity',
            child: const Icon(Icons.add_rounded),
          ),
        ),
      ],
    );
  }
}

class _AmenityFormData {
  const _AmenityFormData({required this.name, required this.bucket, this.slug, this.sortOrder = 0});
  final String name;
  final String bucket;
  final String? slug;
  final int sortOrder;
}

class _AmenityTile extends StatelessWidget {
  const _AmenityTile({
    super.key,
    required this.index,
    required this.amenity,
    required this.isEditing,
    required this.editingBucket,
    required this.onBucketChanged,
    required this.nameController,
    required this.slugController,
    required this.onStartEdit,
    required this.onCancelEdit,
    required this.onSaveEdit,
    required this.onDelete,
  });

  final int index;
  final Amenity amenity;
  final bool isEditing;
  final String editingBucket;
  final ValueChanged<String> onBucketChanged;
  final TextEditingController? nameController;
  final TextEditingController? slugController;
  final VoidCallback onStartEdit;
  final VoidCallback onCancelEdit;
  final VoidCallback onSaveEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isEditing && nameController != null && slugController != null) {
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder(), isDense: true),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: slugController,
                decoration: const InputDecoration(labelText: 'Slug', border: OutlineInputBorder(), isDense: true),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: editingBucket,
                decoration: const InputDecoration(labelText: 'Bucket', border: OutlineInputBorder(), isDense: true),
                items: [for (final o in _kBucketOptions) DropdownMenuItem(value: o.$1, child: Text(o.$2))],
                onChanged: (v) {
                  if (v != null) onBucketChanged(v);
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: onCancelEdit, child: const Text('Cancel')),
                  const SizedBox(width: 8),
                  FilledButton(onPressed: onSaveEdit, child: const Text('Save')),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: ReorderableDragStartListener(
          index: index,
          child: Icon(Icons.drag_handle_rounded, color: theme.colorScheme.onSurfaceVariant),
        ),
        title: Text(amenity.name),
        subtitle: Text('${amenity.slug} · ${amenity.bucket}', style: theme.textTheme.bodySmall),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.edit_rounded), onPressed: onStartEdit, tooltip: 'Edit'),
            IconButton(icon: const Icon(Icons.delete_outline_rounded), onPressed: onDelete, tooltip: 'Delete'),
          ],
        ),
      ),
    );
  }
}

class _AddAmenityDialog extends StatefulWidget {
  const _AddAmenityDialog({this.nextSortOrder = 0});

  final int nextSortOrder;

  @override
  State<_AddAmenityDialog> createState() => _AddAmenityDialogState();
}

class _AddAmenityDialogState extends State<_AddAmenityDialog> {
  final _nameController = TextEditingController();
  final _slugController = TextEditingController();
  String _bucket = 'global';

  @override
  void dispose() {
    _nameController.dispose();
    _slugController.dispose();
    super.dispose();
  }

  static String _slugify(String name) {
    final s = name.trim().toLowerCase();
    if (s.isEmpty) return '';
    return s.replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-|-$'), '');
  }

  void _syncSlug() {
    final slug = _slugify(_nameController.text);
    if (slug.isNotEmpty && _slugController.text.isEmpty) {
      _slugController.text = slug;
    }
  }

  void _submit() {
    final name = _nameController.text.trim();
    final slug = _slugController.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop(
      _AmenityFormData(
        name: name,
        bucket: _bucket,
        slug: slug.isNotEmpty ? slug : _slugify(name),
        sortOrder: widget.nextSortOrder,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New amenity'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. Outdoor seating',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => _syncSlug(),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _slugController,
              decoration: const InputDecoration(
                labelText: 'Slug (optional, derived from name)',
                hintText: 'e.g. outdoor-seating',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _bucket,
              decoration: const InputDecoration(labelText: 'Bucket', border: OutlineInputBorder()),
              items: [for (final o in _kBucketOptions) DropdownMenuItem(value: o.$1, child: Text(o.$2))],
              onChanged: (v) => setState(() => _bucket = v ?? 'global'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(onPressed: _submit, child: const Text('Add')),
      ],
    );
  }
}
