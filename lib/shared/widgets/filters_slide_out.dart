import 'package:flutter/material.dart';
import 'package:my_app/core/data/mock_data.dart';
import 'package:my_app/shared/widgets/app_buttons.dart';

/// Slide-out panel from the right: Filters & Categories with search,
/// expandable categories with multiselect subcategories, and parish selector.
/// [totalCount] and [categories] are optional; when null, 0 and [] are used (no mock data).
class FiltersSlideOut extends StatefulWidget {
  const FiltersSlideOut({
    super.key,
    required this.initialFilters,
    required this.onApply,
    required this.onClose,
    required this.parishes,
    this.totalCount,
    this.categories,
  });

  final ListingFilters initialFilters;
  final void Function(ListingFilters filters) onApply;
  final VoidCallback onClose;
  final List<MockParish> parishes;
  final int? totalCount;
  final List<MockCategory>? categories;

  @override
  State<FiltersSlideOut> createState() => _FiltersSlideOutState();
}

enum _FilterSection { category, location }

class _FiltersSlideOutState extends State<FiltersSlideOut>
    with SingleTickerProviderStateMixin {
  late TextEditingController _searchController;
  late ListingFilters _filters;
  String? _expandedCategoryId;
  /// Only one section expanded at a time to reduce visual clutter.
  _FilterSection? _expandedSection = _FilterSection.category;
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

  int get _totalCount => widget.totalCount ?? 0;
  List<MockCategory> get _categories => widget.categories ?? [];

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
                  width: (MediaQuery.sizeOf(context).width * 0.88).clamp(0.0, 400.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeader(theme),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionLabel('Search'),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: 'Search businesses...',
                                  prefixIcon: const Icon(Icons.search_rounded, size: 22),
                                  filled: true,
                                  isDense: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                ),
                                onChanged: (v) => setState(() {
                                  _filters = _filters.copyWith(searchQuery: v);
                                }),
                              ),
                              const SizedBox(height: 12),
                              _buildSectionCard(
                                theme,
                                section: _FilterSection.category,
                                title: 'Category',
                                subtitle: _categorySummary(),
                                icon: Icons.category_outlined,
                                child: _buildCategoryList(theme),
                              ),
                              const SizedBox(height: 8),
                              _buildSectionCard(
                                theme,
                                section: _FilterSection.location,
                                title: 'Location',
                                subtitle: _locationSummary(),
                                icon: Icons.location_on_outlined,
                                child: _buildParishChips(theme),
                              ),
                            ],
                          ),
                        ),
                      ),
                      _buildFooter(theme),
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
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Filters',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          IconButton(
            onPressed: widget.onClose,
            icon: const Icon(Icons.close_rounded, size: 22),
            style: IconButton.styleFrom(
              minimumSize: const Size(40, 40),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: AppOutlinedButton(
                onPressed: _clearFilters,
                child: const Text('Clear'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: AppPrimaryButton(
                onPressed: () {
                  widget.onApply(_filters.copyWith(
                    searchQuery: _searchController.text.trim(),
                  ));
                },
                expanded: false,
                child: const Text('Apply'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
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

  String _categorySummary() {
    if (_filters.categoryId == null) return 'All businesses';
    final idx = _categories.indexWhere((c) => c.id == _filters.categoryId);
    if (idx < 0) return 'All businesses';
    final cat = _categories[idx];
    if (_filters.subcategoryIds.isEmpty) return cat.name;
    return '${cat.name} · ${_filters.subcategoryIds.length} type${_filters.subcategoryIds.length == 1 ? '' : 's'}';
  }

  String _locationSummary() {
    if (_filters.parishIds.isEmpty) return 'All parishes';
    if (_filters.parishIds.length == 1) {
      for (final p in widget.parishes) {
        if (p.id == _filters.parishIds.first) return p.name;
      }
      return '1 parish';
    }
    return '${_filters.parishIds.length} parishes';
  }

  Widget _buildSectionCard(
    ThemeData theme, {
    required _FilterSection section,
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    final colorScheme = theme.colorScheme;
    final isExpanded = _expandedSection == section;
    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => setState(() {
              _expandedSection = isExpanded ? null : section;
            }),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(icon, size: 22, color: colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    color: colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              child: child,
            ),
        ],
      ),
    );
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
        const SizedBox(height: 4),
        ..._categories.expand((cat) {
          final isExpanded = _expandedCategoryId == cat.id;
          final isSelected = _filters.categoryId == cat.id;
          return [
            KeyedSubtree(
              key: ValueKey(cat.id),
              child: _CategoryTile(
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
            ),
            if (isExpanded && cat.subcategories.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 4, bottom: 6),
                child: _SubcategoryMultiselect(
                  subcategories: cat.subcategories,
                  selectedIds: _filters.subcategoryIds,
                  onChanged: (ids) => setState(() {
                    _filters = _filters.copyWith(subcategoryIds: ids);
                  }),
                ),
              ),
            const SizedBox(height: 4),
          ];
        }),
      ],
    );
  }

  Widget _buildParishChips(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: widget.parishes.map((p) {
        final selected = _filters.parishIds.contains(p.id);
        return FilterChip(
          label: Text(p.name, style: theme.textTheme.labelMedium),
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
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          visualDensity: VisualDensity.compact,
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
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              Text(
                '$count',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (hasSubcategories)
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: colorScheme.onSurfaceVariant,
                  size: 22,
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
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () => _showMultiselectSheet(context),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
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
                size: 22,
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
