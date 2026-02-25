import 'package:flutter/material.dart';
import 'package:my_app/core/data/app_data_scope.dart';
import 'package:my_app/core/data/mock_data.dart';
import 'package:my_app/core/favorites/favorites_scope.dart';
import 'package:my_app/core/theme/app_layout.dart';
import 'package:my_app/core/theme/theme.dart';
import 'package:my_app/features/listing/presentation/screens/listing_detail_screen.dart';
import 'package:my_app/shared/widgets/animated_entrance.dart';

/// Favorites tab — saved listings grouped/filtered by category. Uses specOffWhite, specNavy, specGold.
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  /// Selected category id; null = "All".
  String? _selectedCategoryId;

  /// Group listings by categoryId. Keys in display order (first-seen order); value = list of listings.
  static Map<String, List<MockListing>> _groupByCategory(List<MockListing> listings) {
    final map = <String, List<MockListing>>{};
    for (final l in listings) {
      final key = l.categoryId.isNotEmpty ? l.categoryId : 'other';
      map.putIfAbsent(key, () => []).add(l);
    }
    return map;
  }

  /// Category display name (categoryName from first listing in group, or fallback).
  static String _categoryDisplayName(String categoryId, List<MockListing> list) {
    if (list.isNotEmpty && list.first.categoryName.isNotEmpty) {
      return list.first.categoryName;
    }
    if (categoryId == 'other') return 'Other';
    return categoryId;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final favoriteIds = FavoritesScope.of(context);

    return Container(
      color: AppTheme.specOffWhite,
      child: ValueListenableBuilder<Set<String>>(
        valueListenable: favoriteIds,
        builder: (context, ids, _) {
          if (ids.isEmpty) {
            return _buildEmptyState(
              context,
              theme,
              icon: Icons.favorite_border_rounded,
              title: 'No favorites yet',
              subtitle: 'Tap the heart on a listing to save it here.',
            );
          }

          final dataSource = AppDataScope.of(context).dataSource;
          final future = Future.wait(
            ids.map((id) => dataSource.getListingById(id)),
          ).then((list) => list.whereType<MockListing>().toList());

          return FutureBuilder<List<MockListing>>(
            future: future,
            builder: (context, snapshot) {
              final listings = snapshot.data ?? const [];
              if (snapshot.connectionState == ConnectionState.waiting && listings.isEmpty) {
                return const Center(child: CircularProgressIndicator(color: AppTheme.specNavy));
              }
              if (listings.isEmpty) {
                return _buildEmptyState(
                  context,
                  theme,
                  icon: Icons.favorite_border_rounded,
                  title: 'No favorites yet',
                  subtitle: 'Tap the heart on a listing to save it here.',
                );
              }

              final grouped = _groupByCategory(listings);
              final categoryIds = grouped.keys.toList();
              final padding = AppLayout.horizontalPadding(context);

              return CustomScrollView(
                slivers: [
                  // Category filter chips
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(padding.left, 12, padding.right, 8),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: const Text('All'),
                                selected: _selectedCategoryId == null,
                                onSelected: (_) => setState(() => _selectedCategoryId = null),
                                selectedColor: AppTheme.specGold.withValues(alpha: 0.35),
                                checkmarkColor: AppTheme.specNavy,
                              ),
                            ),
                            ...categoryIds.map((cid) {
                              final name = _categoryDisplayName(cid, grouped[cid]!);
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(name),
                                  selected: _selectedCategoryId == cid,
                                  onSelected: (_) => setState(() => _selectedCategoryId = cid),
                                  selectedColor: AppTheme.specGold.withValues(alpha: 0.35),
                                  checkmarkColor: AppTheme.specNavy,
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Grouped list: when All, show sections; when one category, show only that list
                  if (_selectedCategoryId == null) ...[
                    ...categoryIds.expand((cid) {
                      final list = grouped[cid]!;
                      final name = _categoryDisplayName(cid, list);
                      return [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(padding.left, 16, padding.right, 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: AppTheme.specGold,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  name,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.specNavy,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${list.length}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppTheme.specNavy.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(padding.left, 0, padding.right, 8),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final listing = list[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: AnimatedEntrance(
                                    delay: Duration(milliseconds: 50 * (index + 1)),
                                    child: _FavoriteCard(
                                      listing: listing,
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                            builder: (_) => ListingDetailScreen(listingId: listing.id),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                );
                              },
                              childCount: list.length,
                            ),
                          ),
                        ),
                      ];
                    }),
                  ] else ...[
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(padding.left, 8, padding.right, 28),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final list = grouped[_selectedCategoryId] ?? [];
                            if (index >= list.length) return const SizedBox.shrink();
                            final listing = list[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: AnimatedEntrance(
                                delay: Duration(milliseconds: 50 * (index + 1)),
                                child: _FavoriteCard(
                                  listing: listing,
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => ListingDetailScreen(listingId: listing.id),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                          childCount: grouped[_selectedCategoryId]?.length ?? 0,
                        ),
                      ),
                    ),
                  ],
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: AnimatedEntrance(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.specGold.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 56,
                  color: AppTheme.specRed,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.specNavy,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  const _FavoriteCard({required this.listing, required this.onTap});

  final MockListing listing;
  final VoidCallback onTap;

  static const double _cardRadius = 14;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_cardRadius),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.specWhite,
            borderRadius: BorderRadius.circular(_cardRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppTheme.specGold.withValues(alpha: 0.2),
                ),
                child: Icon(
                  Icons.store_rounded,
                  size: 28,
                  color: AppTheme.specNavy,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.specNavy,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (listing.tagline.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        listing.tagline,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppTheme.specNavy.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
