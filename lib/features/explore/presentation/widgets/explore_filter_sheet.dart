import 'package:flutter/material.dart';

import 'package:cajun_local/core/theme/theme.dart';
import 'package:cajun_local/features/businesses/data/models/amenity.dart';
import 'package:cajun_local/features/businesses/data/models/business_category.dart';
import 'package:cajun_local/features/businesses/data/models/listing_filters.dart';
import 'package:cajun_local/features/businesses/data/repositories/amenities_repository.dart';
import 'package:cajun_local/features/locations/data/models/parish.dart';
import 'package:cajun_local/shared/widgets/app_buttons.dart';

class ExploreFilterSheet extends StatefulWidget {
  const ExploreFilterSheet({
    super.key,
    required this.initialFilters,
    required this.initialOpenNowOnly,
    required this.categories,
    required this.parishes,
    required this.totalCount,
    required this.onApply,
    required this.onClose,
  });

  final ListingFilters initialFilters;
  final bool initialOpenNowOnly;
  final List<BusinessCategory> categories;
  final List<Parish> parishes;
  final int totalCount;
  final void Function(ListingFilters filters, bool openNowOnly) onApply;
  final VoidCallback onClose;

  @override
  State<ExploreFilterSheet> createState() => _ExploreFilterSheetState();
}

class _ExploreFilterSheetState extends State<ExploreFilterSheet> {
  late ListingFilters _filters;
  late bool _openNowOnly;
  String? _expandedCategoryId;
  Future<List<Amenity>>? _amenitiesFuture;

  @override
  void initState() {
    super.initState();
    _filters = widget.initialFilters;
    _openNowOnly = widget.initialOpenNowOnly;
    _amenitiesFuture = _amenitiesFutureForCategory(_filters.categoryId);
  }

  Future<List<Amenity>> _amenitiesFutureForCategory(String? categoryId) {
    if (categoryId == null) return Future.value([]);
    final cat = widget.categories.where((c) => c.id == categoryId).firstOrNull;
    final bucket = cat?.bucket;
    return AmenitiesRepository().getAmenitiesForBucket(bucket);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.specWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.specNavy.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Navy header card
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              decoration: BoxDecoration(
                color: AppTheme.specNavy,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: AppTheme.specNavy.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.specGold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.tune_rounded, size: 20, color: AppTheme.specGold),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FILTER RESULTS',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppTheme.specGold,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                        Text(
                          'Refine your discovery',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.onClose,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, size: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.paddingOf(context).bottom + 64),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _sectionLabel('CATEGORY'),
                    const SizedBox(height: 8),
                    _buildCategoryList(theme),
                    const SizedBox(height: 20),
                    _sectionLabel('PARISHES'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.parishes.map((p) {
                        final selected = _filters.parishIds.contains(p.id);
                        return FilterChip(
                          label: Text(p.name),
                          selected: selected,
                          onSelected: (_) {
                            setState(() {
                              final next = Set<String>.from(_filters.parishIds);
                              if (selected) {
                                next.remove(p.id);
                              } else {
                                next.add(p.id);
                              }
                              _filters = _filters.copyWith(parishIds: next);
                            });
                          },
                          selectedColor: AppTheme.specGold.withValues(alpha: 0.3),
                          checkmarkColor: AppTheme.specNavy,
                        );
                      }).toList(),
                    ),
                    if (_filters.categoryId != null) ...[
                      const SizedBox(height: 20),
                      _sectionLabel('AMENITIES'),
                      const SizedBox(height: 8),
                      FutureBuilder<List<Amenity>>(
                        future: _amenitiesFuture,
                        builder: (context, snap) {
                          final amenities = snap.data ?? [];
                          if (amenities.isEmpty && snap.connectionState != ConnectionState.waiting) {
                            return const SizedBox.shrink();
                          }
                          if (amenities.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Center(child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))),
                            );
                          }
                          return Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: amenities.map((a) {
                              final selected = _filters.amenityIds.contains(a.id);
                              return FilterChip(
                                label: Text(a.name),
                                selected: selected,
                                onSelected: (_) {
                                  setState(() {
                                    final next = Set<String>.from(_filters.amenityIds);
                                    if (selected) {
                                      next.remove(a.id);
                                    } else {
                                      next.add(a.id);
                                    }
                                    _filters = _filters.copyWith(amenityIds: next);
                                  });
                                },
                                selectedColor: AppTheme.specGold.withValues(alpha: 0.3),
                                checkmarkColor: AppTheme.specNavy,
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: 20),
                    _sectionLabel('DISTANCE (optional)'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Any'),
                          selected: _filters.maxDistanceMiles == null,
                          onSelected: (_) => setState(() => _filters = _filters.copyWith(maxDistanceMiles: null)),
                          selectedColor: AppTheme.specGold.withValues(alpha: 0.3),
                          labelStyle: TextStyle(
                            color: _filters.maxDistanceMiles == null ? AppTheme.specNavy : theme.colorScheme.onSurfaceVariant,
                            fontWeight: _filters.maxDistanceMiles == null ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        ...([10.0, 25.0, 50.0].map((m) {
                          final selected = _filters.maxDistanceMiles == m;
                          return ChoiceChip(
                            label: Text('${m.round()} mi'),
                            selected: selected,
                            onSelected: (_) => setState(() => _filters = _filters.copyWith(maxDistanceMiles: m)),
                            selectedColor: AppTheme.specGold.withValues(alpha: 0.3),
                            labelStyle: TextStyle(
                              color: selected ? AppTheme.specNavy : theme.colorScheme.onSurfaceVariant,
                              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          );
                        })),
                      ],
                    ),
                    if (_filters.maxDistanceMiles != null) ...[
                      const SizedBox(height: 8),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppTheme.specGold,
                          thumbColor: AppTheme.specGold,
                          overlayColor: AppTheme.specGold.withValues(alpha: 0.2),
                        ),
                        child: Slider(
                          value: _filters.maxDistanceMiles!.clamp(1.0, 50.0),
                          min: 1,
                          max: 50,
                          divisions: 49,
                          label: '${_filters.maxDistanceMiles!.round()} mi',
                          onChanged: (v) => setState(() => _filters = _filters.copyWith(maxDistanceMiles: v)),
                        ),
                      ),
                    ],
                    _sectionLabel('MINIMUM RATING'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [null, 3.0, 3.5, 4.0, 4.5].map((r) {
                        final label = r == null ? 'Any' : r.toString();
                        final selected = _filters.minRating == r;
                        return ChoiceChip(
                          label: Text(label),
                          selected: selected,
                          onSelected: (_) => setState(() => _filters = _filters.copyWith(minRating: r)),
                          selectedColor: AppTheme.specGold.withValues(alpha: 0.3),
                          labelStyle: TextStyle(
                            color: selected ? AppTheme.specNavy : theme.colorScheme.onSurfaceVariant,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: Text('Open now only', style: theme.textTheme.bodyLarge?.copyWith(color: AppTheme.specNavy))),
                        Switch.adaptive(
                          value: _openNowOnly,
                          onChanged: (v) => setState(() => _openNowOnly = v),
                          activeTrackColor: AppTheme.specGold,
                          activeThumbColor: AppTheme.specNavy,
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(child: Text('Deals only', style: theme.textTheme.bodyLarge?.copyWith(color: AppTheme.specNavy))),
                        Switch.adaptive(
                          value: _filters.dealOnly,
                          onChanged: (v) => setState(() => _filters = _filters.copyWith(dealOnly: v)),
                          activeTrackColor: AppTheme.specGold,
                          activeThumbColor: AppTheme.specNavy,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    AppPrimaryButton(
                      onPressed: () => widget.onApply(_filters, _openNowOnly),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: AppTheme.specNavy,
                      ),
                      label: const Text(
                        'Apply',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: AppTheme.specNavy,
                        ),
                      ),
                    ),
                  ],
                ),
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
            color: AppTheme.specNavy,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
    );
  }

  Widget _buildCategoryList(ThemeData theme) {
    return Column(
      children: [
        _FilterCategoryTile(
          label: 'All Businesses',
          count: widget.totalCount,
          isExpanded: false,
          isSelected: _filters.categoryId == null,
          onTap: () => setState(() {
            _filters = _filters.copyWith(categoryId: null, subcategoryIds: const {}, amenityIds: const {});
            _expandedCategoryId = null;
            _amenitiesFuture = _amenitiesFutureForCategory(null);
          }),
        ),
        ...widget.categories.map((cat) {
          final isExpanded = _expandedCategoryId == cat.id;
          final isSelected = _filters.categoryId == cat.id;
          return Column(
            key: ValueKey(cat.id),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FilterCategoryTile(
                label: cat.name,
                count: 0,
                isExpanded: isExpanded,
                isSelected: isSelected,
                hasSubcategories: cat.subcategories.isNotEmpty,
                onTap: () => setState(() {
                  if (isExpanded) {
                    _expandedCategoryId = null;
                  } else {
                    _expandedCategoryId = cat.id;
                    _filters = _filters.copyWith(categoryId: cat.id, amenityIds: const {});
                    _amenitiesFuture = _amenitiesFutureForCategory(cat.id);
                  }
                }),
              ),
              if (isExpanded && cat.subcategories.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: cat.subcategories.map((sub) {
                      final selected = _filters.subcategoryIds.contains(sub.id);
                      return FilterChip(
                        label: Text(sub.name),
                        selected: selected,
                        onSelected: (_) {
                          setState(() {
                            final next = Set<String>.from(_filters.subcategoryIds);
                            if (selected) {
                              next.remove(sub.id);
                            } else {
                              next.add(sub.id);
                            }
                            _filters = _filters.copyWith(subcategoryIds: next);
                          });
                        },
                        selectedColor: AppTheme.specGold.withValues(alpha: 0.3),
                      );
                    }).toList(),
                  ),
                ),
            ],
          );
        }),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category tile row (private to this file)
// ─────────────────────────────────────────────────────────────────────────────

class _FilterCategoryTile extends StatelessWidget {
  const _FilterCategoryTile({
    required this.label,
    required this.count,
    required this.isExpanded,
    required this.isSelected,
    this.hasSubcategories = false,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool isExpanded;
  final bool isSelected;
  final bool hasSubcategories;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: isSelected ? AppTheme.specGold.withValues(alpha: 0.2) : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: AppTheme.specNavy,
                  ),
                ),
              ),
              if (hasSubcategories)
                Icon(
                  isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  color: AppTheme.specNavy,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
