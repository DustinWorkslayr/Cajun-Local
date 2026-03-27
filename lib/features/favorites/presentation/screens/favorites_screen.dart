import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cajun_local/features/businesses/data/models/business.dart';
import 'package:cajun_local/features/businesses/data/models/business_category.dart';
import 'package:cajun_local/features/categories/data/repositories/category_repository.dart';
import 'package:cajun_local/features/favorites/presentation/providers/favorites_providers.dart';
import 'package:cajun_local/core/theme/app_layout.dart';
import 'package:cajun_local/core/theme/theme.dart';
import 'package:cajun_local/shared/widgets/app_buttons.dart';
import 'package:cajun_local/shared/widgets/animated_entrance.dart';
import 'package:cajun_local/shared/widgets/app_refresh_indicator.dart';

/// Favorites tab — saved listings grouped/filtered by category.
class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  /// Selected category id; null = "All".
  String? _selectedCategoryId;

  /// Group listings by categoryId.
  static Map<String, List<Business>> _groupByCategory(List<Business> listings) {
    final map = <String, List<Business>>{};
    for (final l in listings) {
      final key = l.categoryId.isNotEmpty ? l.categoryId : 'other';
      map.putIfAbsent(key, () => []).add(l);
    }
    return map;
  }

  /// Category display name.
  static String _categoryDisplayName(String categoryId, List<BusinessCategory> categories) {
    if (categoryId == 'other') return 'Other';
    final cat = categories.where((c) => c.id == categoryId).firstOrNull;
    if (cat != null) return cat.name;
    return categoryId[0].toUpperCase() + categoryId.substring(1).replaceAll('_', ' ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final listingsAsync = ref.watch(favoriteListingsProvider);
    final padding = AppLayout.horizontalPadding(context);

    return Container(
      color: AppTheme.specOffWhite,
      child: listingsAsync.when(
        data: (listings) {
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
          final categories = ref.watch(allCategoriesProvider).valueOrNull ?? [];

          final displayedList = _selectedCategoryId == null
              ? listings
              : (grouped[_selectedCategoryId] ?? []);

          return AppRefreshIndicator(
            onRefresh: () async {
              ref.invalidate(userFavoriteIdsProvider);
              await ref.read(userFavoriteIdsProvider.future);
            },
            child: CustomScrollView(
              slivers: [
                // ── Header ────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(padding.left, 20, padding.right, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Eyebrow label
                        Text(
                          'MY COLLECTION',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppTheme.specGold,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Title + count
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                'Your Favorites',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: AppTheme.specNavy,
                                  fontFamily: 'Libre Baskerville',
                                  fontWeight: FontWeight.w700,
                                  height: 1.15,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppTheme.specNavy,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.favorite_rounded, size: 12, color: AppTheme.specSecondaryContainer),
                                  const SizedBox(width: 5),
                                  Text(
                                    '${listings.length}',
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Category pill row — same segmented style as Deals tab bar
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppTheme.specNavy.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                null,
                                ...categoryIds,
                              ].map((id) {
                                final label = id == null
                                    ? 'All'
                                    : _categoryDisplayName(id, categories);
                                final isSelected = _selectedCategoryId == id;
                                return GestureDetector(
                                  onTap: () => setState(() => _selectedCategoryId = id),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 160),
                                    margin: const EdgeInsets.only(right: 4),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppTheme.specWhite : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: isSelected
                                          ? [BoxShadow(color: AppTheme.specNavy.withValues(alpha: 0.10), blurRadius: 8, offset: const Offset(0, 2))]
                                          : [],
                                    ),
                                    child: Text(
                                      label,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                        color: isSelected
                                            ? AppTheme.specNavy
                                            : AppTheme.specNavy.withValues(alpha: 0.45),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                // ── Cards ─────────────────────────────────────────────
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: padding.left),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index >= displayedList.length) return const SizedBox.shrink();
                        final listing = displayedList[index];
                        final categoryName = _categoryDisplayName(listing.categoryId, categories);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: AnimatedEntrance(
                            delay: Duration(milliseconds: 50 * (index + 1)),
                            child: _FavoriteCard(
                              listing: listing,
                              categoryName: categoryName,
                              onTap: () {
                                context.push('/listing/${listing.id}');
                              },
                            ),
                          ),
                        );
                      },
                      childCount: displayedList.length,
                    ),
                  ),
                ),

                SliverToBoxAdapter(child: SizedBox(height: 110 + MediaQuery.paddingOf(context).bottom)),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.specNavy)),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Error loading favorites'),
              const SizedBox(height: 16),
              AppPrimaryButton(
                onPressed: () => ref.invalidate(userFavoriteIdsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
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
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.specGold.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 64, color: AppTheme.specGold),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.specNavy,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.specNavy.withValues(alpha: 0.7),
                  height: 1.5,
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

// ─────────────────────────────────────────────────────────────────────────────
// Favorite Card
// ─────────────────────────────────────────────────────────────────────────────

class _FavoriteCard extends StatelessWidget {
  const _FavoriteCard({
    required this.listing,
    required this.categoryName,
    required this.onTap,
  });

  final Business listing;
  final String categoryName;
  final VoidCallback onTap;

  static const double _cardRadius = 16;

  IconData _getCategoryIcon() {
    final cat = listing.categoryId.toLowerCase();
    if (cat.contains('restaurant') || cat.contains('food')) return Icons.restaurant_rounded;
    if (cat.contains('shopping') || cat.contains('store')) return Icons.store_rounded;
    if (cat.contains('services')) return Icons.work_rounded;
    if (cat.contains('health')) return Icons.medical_services_rounded;
    if (cat.contains('outdoors')) return Icons.park_rounded;
    return Icons.place_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(_cardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_cardRadius),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.specWhite,
            borderRadius: BorderRadius.circular(_cardRadius),
            boxShadow: [
              BoxShadow(
                color: AppTheme.specNavy.withValues(alpha: 0.07),
                blurRadius: 16,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              // No CrossAxisAlignment.stretch — avoids the SliverList hasSize crash
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon square
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.specNavy,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Icon(_getCategoryIcon(), size: 26, color: AppTheme.specGold),
                  ),
                ),
                const SizedBox(width: 14),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category tag
                      Text(
                        categoryName.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppTheme.specGold,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Business name
                      Text(
                        listing.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppTheme.specNavy,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // View details
                      Row(
                        children: [
                          const Icon(Icons.arrow_right_alt_rounded, size: 15,
                              color: AppTheme.specGold),
                          const SizedBox(width: 3),
                          Text(
                            'View details',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppTheme.specGold,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Chevron
                Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: AppTheme.specNavy.withValues(alpha: 0.2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
