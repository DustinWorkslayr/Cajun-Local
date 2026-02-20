import 'package:flutter/material.dart';
import 'package:my_app/core/data/mock_data.dart';

/// Slide-out panel from the right: Filters & Categories with search,
/// expandable categories with multiselect subcategories, and parish selector.
class FiltersSlideOut extends StatefulWidget {
  const FiltersSlideOut({
    super.key,
    required this.initialFilters,
    required this.onApply,
    required this.onClose,
  });

  final ListingFilters initialFilters;
  final void Function(ListingFilters filters) onApply;
  final VoidCallback onClose;

  @override
  State<FiltersSlideOut> createState() => _FiltersSlideOutState();
}

class _FiltersSlideOutState extends State<FiltersSlideOut>
    with SingleTickerProviderStateMixin {
  late TextEditingController _searchController;
  late ListingFilters _filters;
  String? _expandedCategoryId;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialFilters.searchQuery);
    _filters = widget.initialFilters;
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _slideController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  int get _totalCount => MockData.listings.length;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          GestureDetector(
            onTap: widget.onClose,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              color: Colors.black54,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: SlideTransition(
              position: _slideAnimation,
              child: Material(
                color: colorScheme.surface.withValues(alpha: 0.98),
                elevation: 16,
                shadowColor: colorScheme.shadow.withValues(alpha: 0.2),
                child: SizedBox(
                  width: MediaQuery.sizeOf(context).width * 0.88,
                  child: Column(
                    children: [
                      _buildHeader(theme),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionLabel('SEARCH'),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: 'Search businesses...',
                                  prefixIcon: const Icon(Icons.search_rounded),
                                  filled: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                                onChanged: (v) => setState(() {
                                  _filters = _filters.copyWith(searchQuery: v);
                                }),
                              ),
                              const SizedBox(height: 24),
                              _sectionLabel('CATEGORY'),
                              const SizedBox(height: 8),
                              _buildCategoryList(theme),
                              const SizedBox(height: 24),
                              _sectionLabel('PARISHES'),
                              const SizedBox(height: 8),
                              _buildParishChips(theme),
                              const SizedBox(height: 32),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: _clearFilters,
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                      ),
                                      child: const Text('Clear all'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 2,
                                    child: FilledButton(
                                      onPressed: () {
                                        widget.onApply(_filters.copyWith(
                                          searchQuery: _searchController.text.trim(),
                                        ));
                                      },
                                      style: FilledButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                      ),
                                      child: const Text('Apply filters'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ),
        ),
      ],
    ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Filters & Categories',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          IconButton(
            onPressed: widget.onClose,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
    );
  }

  void _clearFilters() {
    setState(() {
      _filters = const ListingFilters();
      _searchController.clear();
      _expandedCategoryId = null;
    });
  }

  Widget _buildCategoryList(ThemeData theme) {
    return Column(
      children: [
        _CategoryTile(
          label: 'All Businesses',
          count: _totalCount,
          isExpanded: false,
          isSelected: _filters.categoryId == null,
          onTap: () => setState(() {
            _filters = _filters.copyWith(categoryId: null, subcategoryIds: {});
            _expandedCategoryId = null;
          }),
        ),
        ...MockData.categories.map((cat) {
          final isExpanded = _expandedCategoryId == cat.id;
          final isSelected = _filters.categoryId == cat.id;
          return Column(
            key: ValueKey(cat.id),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CategoryTile(
                label: cat.name,
                count: cat.count,
                isExpanded: isExpanded,
                isSelected: isSelected,
                hasSubcategories: cat.subcategories.isNotEmpty,
                onTap: () => setState(() {
                  if (isExpanded) {
                    _expandedCategoryId = null;
                  } else {
                    _expandedCategoryId = cat.id;
                    _filters = _filters.copyWith(categoryId: cat.id);
                  }
                }),
              ),
              if (isExpanded && cat.subcategories.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
                  child: _SubcategoryMultiselect(
                    subcategories: cat.subcategories,
                    selectedIds: _filters.subcategoryIds,
                    onChanged: (ids) => setState(() {
                      _filters = _filters.copyWith(subcategoryIds: ids);
                    }),
                  ),
                ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildParishChips(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: MockData.parishes.map((p) {
        final selected = _filters.parishIds.contains(p.id);
        return FilterChip(
          label: Text(p.name),
          selected: selected,
          onSelected: (v) {
            setState(() {
              final next = Set<String>.from(_filters.parishIds);
              if (v) {
                next.add(p.id);
              } else {
                next.remove(p.id);
              }
              _filters = _filters.copyWith(parishIds: next);
            });
          },
          selectedColor: colorScheme.primaryContainer,
          checkmarkColor: colorScheme.primary,
        );
      }).toList(),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.label,
    required this.count,
    required this.isExpanded,
    required this.isSelected,
    required this.onTap,
    this.hasSubcategories = false,
  });

  final String label;
  final int count;
  final bool isExpanded;
  final bool isSelected;
  final VoidCallback onTap;
  final bool hasSubcategories;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: isSelected
          ? colorScheme.primaryContainer.withValues(alpha: 0.5)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              Text(
                '$count',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (hasSubcategories)
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: colorScheme.onSurfaceVariant,
                  size: 24,
                )
              else
                Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.onSurfaceVariant,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Multiselect subcategory: dropdown trigger that opens a bottom sheet with chips.
class _SubcategoryMultiselect extends StatelessWidget {
  const _SubcategoryMultiselect({
    required this.subcategories,
    required this.selectedIds,
    required this.onChanged,
  });

  final List<MockSubcategory> subcategories;
  final Set<String> selectedIds;
  final void Function(Set<String>) onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedList = subcategories
        .where((s) => selectedIds.contains(s.id))
        .map((s) => s.name)
        .toList();
    final label = selectedList.isEmpty
        ? 'Select type...'
        : selectedList.join(', ');

    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _showMultiselectSheet(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: selectedList.isEmpty
                        ? colorScheme.onSurfaceVariant
                        : colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMultiselectSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            var localSelected = Set<String>.from(selectedIds);
            return DraggableScrollableSheet(
              initialChildSize: 0.5,
              minChildSize: 0.3,
              maxChildSize: 0.85,
              expand: false,
              builder: (_, scrollController) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select types (multi-select)',
                        style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          children: subcategories
                              .map((s) => CheckboxListTile(
                                    title: Text(s.name),
                                    value: localSelected.contains(s.id),
                                    onChanged: (v) {
                                      setModalState(() {
                                        if (v == true) {
                                          localSelected.add(s.id);
                                        } else {
                                          localSelected.remove(s.id);
                                        }
                                      });
                                    },
                                  ))
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: () {
                                onChanged(localSelected);
                                Navigator.pop(ctx);
                              },
                              child: const Text('Done'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
