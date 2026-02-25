import 'package:flutter/material.dart';
import 'package:my_app/core/data/models/business_category.dart';
import 'package:my_app/core/data/models/subcategory.dart';
import 'package:my_app/core/data/repositories/category_repository.dart';
import 'package:my_app/core/theme/theme.dart';
import 'package:my_app/shared/widgets/app_buttons.dart';
import 'package:uuid/uuid.dart';

/// Result of add/edit category form: name, bucket, and optional icon (Material icon name).
class _CategoryFormResult {
  const _CategoryFormResult({
    required this.name,
    required this.bucket,
    this.icon,
  });
  final String name;
  final String bucket;
  final String? icon;
}

/// Bucket options for grouping categories (hire, eat, shop, explore).
const _kBucketOptions = [
  ('hire', 'Hire'),
  ('eat', 'Eat'),
  ('shop', 'Shop'),
  ('explore', 'Explore'),
];

/// Icon options for category (value = name stored in DB, used on home).
const _kCategoryIconOptions = [
  ('', 'Default'),
  ('restaurant', 'Restaurant'),
  ('music_note', 'Music'),
  ('store', 'Store'),
  ('terrain', 'Outdoors'),
  ('local_cafe', 'Cafe'),
  ('category', 'General'),
];

/// Admin categories: reorderable list, auto-increment sort order for new,
/// accordion per category with inline subcategories.
class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key, this.embeddedInShell = false});

  final bool embeddedInShell;

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  final CategoryRepository _repo = CategoryRepository();
  List<BusinessCategory> _categories = [];
  final Map<String, List<Subcategory>> _subcategoriesByCategoryId = {};
  final Set<String> _expandedCategoryIds = {};
  bool _loading = true;
  bool _reordering = false;
  String? _addingSubcategoryCategoryId;
  final Map<String, TextEditingController> _subcategoryNameControllers = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _subcategoryNameControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _repo.listCategories();
    if (mounted) {
      setState(() {
        _categories = list;
        _subcategoriesByCategoryId.clear();
        _loading = false;
      });
    }
  }

  Future<void> _loadSubcategories(String categoryId) async {
    if (_subcategoriesByCategoryId.containsKey(categoryId)) return;
    final list = await _repo.listSubcategories(categoryId: categoryId);
    if (mounted) {
      setState(() => _subcategoriesByCategoryId[categoryId] = list);
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (_reordering) return;
    if (oldIndex < newIndex) newIndex -= 1;
    if (oldIndex == newIndex) return;
    final item = _categories.removeAt(oldIndex);
    _categories.insert(newIndex, item);
    setState(() {});
    _persistOrder();
  }

  Future<void> _persistOrder() async {
    setState(() => _reordering = true);
    try {
      for (var i = 0; i < _categories.length; i++) {
        await _repo.updateCategory(_categories[i].id, {'sort_order': i});
      }
    } finally {
      if (mounted) setState(() => _reordering = false);
    }
  }

  Future<void> _addCategory() async {
    final result = await showDialog<_CategoryFormResult>(
      context: context,
      builder: (context) => _AddCategoryDialog(),
    );
    if (result == null || result.name.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      final sortOrder = _categories.length;
      final id = 'cat-${DateTime.now().millisecondsSinceEpoch}-${result.name.trim().hashCode.abs()}';
      await _repo.insertCategory({
        'id': id,
        'name': result.name.trim(),
        'bucket': result.bucket,
        if (result.icon != null && result.icon!.isNotEmpty) 'icon': result.icon,
        'sort_order': sortOrder,
      });
      await _load();
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add category: $e')),
        );
      }
    }
  }

  Future<void> _editCategory(BusinessCategory category) async {
    final result = await showDialog<_CategoryFormResult>(
      context: context,
      builder: (context) => _EditCategoryDialog(category: category),
    );
    if (result == null) return;
    if (result.name.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      await _repo.updateCategory(category.id, {
        'name': result.name.trim(),
        'bucket': result.bucket,
        'icon': result.icon != null && result.icon!.isNotEmpty ? result.icon : null,
      });
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update category: $e')),
        );
      }
    }
  }

  void _startAddSubcategory(String categoryId) {
    setState(() {
      _addingSubcategoryCategoryId = categoryId;
      _subcategoryNameControllers[categoryId] ??= TextEditingController();
    });
  }

  void _cancelAddSubcategory() {
    setState(() {
      _addingSubcategoryCategoryId = null;
    });
  }

  Future<void> _submitAddSubcategory(String categoryId) async {
    final controller = _subcategoryNameControllers[categoryId];
    final name = controller?.text.trim() ?? '';
    if (name.isEmpty) return;
    controller?.clear();
    setState(() => _addingSubcategoryCategoryId = null);
    try {
      final id = const Uuid().v4();
      await _repo.insertSubcategory({
        'id': id,
        'name': name,
        'category_id': categoryId,
      });
      _subcategoriesByCategoryId.remove(categoryId);
      await _loadSubcategories(categoryId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subcategory added')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add subcategory: $e')),
        );
      }
    }
  }

  Future<void> _deleteSubcategory(Subcategory sub) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete subcategory?'),
        content: Text('Delete "${sub.name}"?'),
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
      await _repo.deleteSubcategory(sub.id);
      _subcategoriesByCategoryId.remove(sub.categoryId);
      await _loadSubcategories(sub.categoryId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subcategory deleted')),
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

    if (_loading && _categories.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    Widget body;
    if (_categories.isEmpty) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No categories. Add one to get started.',
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
        itemCount: _categories.length,
        onReorder: _onReorder,
        buildDefaultDragHandles: false,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isExpanded = _expandedCategoryIds.contains(category.id);
          return _CategoryAccordion(
            key: ValueKey(category.id),
            index: index,
            category: category,
            isExpanded: isExpanded,
            subcategories: _subcategoriesByCategoryId[category.id] ?? const [],
            isLoadingSubcategories: isExpanded && !_subcategoriesByCategoryId.containsKey(category.id),
            isAddingSubcategory: _addingSubcategoryCategoryId == category.id,
            subcategoryNameController: _subcategoryNameControllers[category.id],
            onExpand: () {
              setState(() => _expandedCategoryIds.add(category.id));
              _loadSubcategories(category.id);
            },
            onCollapse: () => setState(() => _expandedCategoryIds.remove(category.id)),
            onEditCategory: () => _editCategory(category),
            onAddSubcategory: () => _startAddSubcategory(category.id),
            onCancelAddSubcategory: _cancelAddSubcategory,
            onSubmitAddSubcategory: () => _submitAddSubcategory(category.id),
            onDeleteSubcategory: _deleteSubcategory,
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
              onPressed: _reordering ? null : _addCategory,
              tooltip: 'Add category',
              child: const Icon(Icons.add_rounded),
            ),
          ),
        ],
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add category',
            onPressed: _reordering ? null : _addCategory,
          ),
        ],
      ),
      body: body,
    );
  }
}

class _AddCategoryDialog extends StatefulWidget {
  @override
  State<_AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<_AddCategoryDialog> {
  final _nameController = TextEditingController();
  String _selectedBucket = 'explore';
  String? _selectedIcon;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New category'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. Restaurants',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedBucket,
              decoration: const InputDecoration(
                labelText: 'Bucket',
                border: OutlineInputBorder(),
              ),
              items: _kBucketOptions
                  .map((e) => DropdownMenuItem(value: e.$1, child: Text(e.$2)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedBucket = v ?? 'explore'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedIcon ?? '',
              decoration: const InputDecoration(
                labelText: 'Category icon',
                border: OutlineInputBorder(),
              ),
              items: _kCategoryIconOptions
                  .map((e) => DropdownMenuItem(value: e.$1, child: Text(e.$2)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedIcon = v),
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
    if (name.isNotEmpty) {
      Navigator.of(context).pop(_CategoryFormResult(
        name: name,
        bucket: _selectedBucket,
        icon: _selectedIcon != null && _selectedIcon!.isNotEmpty ? _selectedIcon : null,
      ));
    }
  }
}

class _EditCategoryDialog extends StatefulWidget {
  const _EditCategoryDialog({required this.category});

  final BusinessCategory category;

  @override
  State<_EditCategoryDialog> createState() => _EditCategoryDialogState();
}

class _EditCategoryDialogState extends State<_EditCategoryDialog> {
  late final TextEditingController _nameController;
  late String _selectedBucket;
  late String? _selectedIcon;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category.name);
    final validBuckets = _kBucketOptions.map((e) => e.$1).toSet();
    _selectedBucket = validBuckets.contains(widget.category.bucket)
        ? widget.category.bucket
        : 'explore';
    final validIcons = _kCategoryIconOptions.map((e) => e.$1).toSet();
    _selectedIcon = widget.category.icon != null && validIcons.contains(widget.category.icon)
        ? widget.category.icon!
        : '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit category'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. Restaurants',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedBucket,
              decoration: const InputDecoration(
                labelText: 'Bucket',
                border: OutlineInputBorder(),
              ),
              items: _kBucketOptions
                  .map((e) => DropdownMenuItem(value: e.$1, child: Text(e.$2)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedBucket = v ?? 'explore'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedIcon ?? '',
              decoration: const InputDecoration(
                labelText: 'Category icon',
                border: OutlineInputBorder(),
              ),
              items: _kCategoryIconOptions
                  .map((e) => DropdownMenuItem(value: e.$1, child: Text(e.$2)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedIcon = v),
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
      Navigator.of(context).pop(_CategoryFormResult(
        name: name,
        bucket: _selectedBucket,
        icon: _selectedIcon != null && _selectedIcon!.isNotEmpty ? _selectedIcon : null,
      ));
    }
  }
}

class _CategoryAccordion extends StatelessWidget {
  const _CategoryAccordion({
    super.key,
    required this.index,
    required this.category,
    required this.isExpanded,
    required this.subcategories,
    required this.isLoadingSubcategories,
    required this.isAddingSubcategory,
    this.subcategoryNameController,
    required this.onExpand,
    required this.onCollapse,
    required this.onEditCategory,
    required this.onAddSubcategory,
    required this.onCancelAddSubcategory,
    required this.onSubmitAddSubcategory,
    required this.onDeleteSubcategory,
  });

  final int index;
  final BusinessCategory category;
  final bool isExpanded;
  final List<Subcategory> subcategories;
  final bool isLoadingSubcategories;
  final bool isAddingSubcategory;
  final TextEditingController? subcategoryNameController;
  final VoidCallback onExpand;
  final VoidCallback onCollapse;
  final VoidCallback onEditCategory;
  final VoidCallback onAddSubcategory;
  final VoidCallback onCancelAddSubcategory;
  final VoidCallback onSubmitAddSubcategory;
  final void Function(Subcategory) onDeleteSubcategory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (isExpanded) {
                  onCollapse();
                } else {
                  onExpand();
                }
              },
              child: ListTile(
                leading: ReorderableDragStartListener(
                  index: index,
                  child: Icon(Icons.drag_handle, color: colorScheme.onSurfaceVariant),
                ),
                title: Text(
                  category.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.specNavy,
                  ),
                ),
                subtitle: isExpanded && subcategories.isNotEmpty
                    ? Text(
                        '${subcategories.length} subcategories',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      )
                    : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: onEditCategory,
                      tooltip: 'Edit category',
                    ),
                    Icon(
                      isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1),
            if (isLoadingSubcategories)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ...subcategories.map((sub) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: Text(
                            sub.name,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface,
                            ),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.close_rounded, size: 20, color: colorScheme.error),
                            onPressed: () => onDeleteSubcategory(sub),
                            tooltip: 'Delete subcategory',
                          ),
                        )),
                    const SizedBox(height: 8),
                    if (isAddingSubcategory)
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: subcategoryNameController,
                              decoration: const InputDecoration(
                                hintText: 'Subcategory name',
                                isDense: true,
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              textCapitalization: TextCapitalization.words,
                              onSubmitted: (_) => onSubmitAddSubcategory(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.check_rounded),
                            onPressed: onSubmitAddSubcategory,
                            tooltip: 'Add',
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: onCancelAddSubcategory,
                            tooltip: 'Cancel',
                          ),
                        ],
                      )
                    else
                      TextButton.icon(
                        onPressed: onAddSubcategory,
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: const Text('Add subcategory'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.specGold,
                          alignment: Alignment.centerLeft,
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
