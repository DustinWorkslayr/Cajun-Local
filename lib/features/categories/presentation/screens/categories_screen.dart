import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:my_app/core/data/mock_data.dart';
import 'package:my_app/features/listing/presentation/screens/listing_detail_screen.dart';
import 'package:my_app/shared/widgets/animated_entrance.dart';
import 'package:my_app/shared/widgets/filters_slide_out.dart';
import 'package:my_app/shared/widgets/glass_card.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key, this.initialSearch});

  /// When opening from home search, pre-fill search query.
  final String? initialSearch;

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  late ListingFilters _filters;

  @override
  void initState() {
    super.initState();
    _filters = ListingFilters(
      searchQuery: widget.initialSearch ?? '',
    );
  }
  bool _openNowOnly = false;
  bool _showFilterPanel = false;

  List<MockListing> get _filteredListings => MockData.filterListings(
        _filters,
        openNowOnly: _openNowOnly,
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TopBar(
              openNowOnly: _openNowOnly,
              onOpenNowChanged: (v) => setState(() => _openNowOnly = v),
              onFilterTap: () => setState(() => _showFilterPanel = true),
            ),
            Expanded(
              child: _filteredListings.isEmpty
                  ? Center(
                      child: AnimatedEntrance(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            'No businesses match your filters.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                      itemCount: _filteredListings.length,
                      itemBuilder: (context, index) {
                        final listing = _filteredListings[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: AnimatedEntrance(
                            delay: Duration(milliseconds: 50 * (index + 1)),
                            child: GlassCard(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => ListingDetailScreen(
                                      listingId: listing.id,
                                    ),
                                  ),
                                );
                              },
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      color: colorScheme.surfaceContainerHighest
                                          .withValues(alpha: 0.8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'No Image',
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 18),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          listing.name,
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          listing.tagline,
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (listing.isOpenNow) ...[
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.schedule_rounded,
                                                size: 14,
                                                color: colorScheme.primary,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Open now',
                                                style: theme.textTheme.labelSmall?.copyWith(
                                                  color: colorScheme.primary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 14,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
        if (_showFilterPanel)
          AnimatedOpacity(
            opacity: _showFilterPanel ? 1 : 0,
            duration: const Duration(milliseconds: 200),
            child: FiltersSlideOut(
              initialFilters: _filters,
              onApply: (f) {
                setState(() {
                  _filters = f;
                  _showFilterPanel = false;
                });
              },
              onClose: () => setState(() => _showFilterPanel = false),
            ),
          ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.openNowOnly,
    required this.onOpenNowChanged,
    required this.onFilterTap,
  });

  final bool openNowOnly;
  final ValueChanged<bool> onOpenNowChanged;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.85),
            border: Border(
              bottom: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
          ),
          child: Row(
            children: [
              Text(
                'Open now',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 10),
              Switch.adaptive(
                value: openNowOnly,
                onChanged: onOpenNowChanged,
                activeColor: colorScheme.primary,
              ),
              const Spacer(),
              Material(
                color: colorScheme.primaryContainer.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: onFilterTap,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(
                      Icons.tune_rounded,
                      color: colorScheme.onPrimaryContainer,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
