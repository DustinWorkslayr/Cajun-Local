import 'package:flutter/material.dart';
import 'package:my_app/core/data/mock_data.dart';
import 'package:my_app/features/listing/presentation/screens/listing_detail_screen.dart';
import 'package:my_app/shared/widgets/animated_entrance.dart';
import 'package:my_app/shared/widgets/glass_card.dart';

class DealsScreen extends StatefulWidget {
  const DealsScreen({super.key});

  @override
  State<DealsScreen> createState() => _DealsScreenState();
}

class _DealsScreenState extends State<DealsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const double _horizontalPadding = 20;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: colorScheme.surface,
          child: TabBar(
            controller: _tabController,
            labelColor: colorScheme.primary,
            unselectedLabelColor: colorScheme.onSurfaceVariant,
            indicatorColor: colorScheme.primary,
            tabs: [
              Tab(
                icon: Icon(Icons.local_offer_rounded, size: 20),
                text: 'Discounts',
              ),
              Tab(
                icon: Icon(Icons.loyalty_rounded, size: 20),
                text: 'Loyalty',
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _DiscountsTab(horizontalPadding: _horizontalPadding),
              _LoyaltyTab(horizontalPadding: _horizontalPadding),
            ],
          ),
        ),
      ],
    );
  }
}

class _DiscountsTab extends StatelessWidget {
  const _DiscountsTab({required this.horizontalPadding});

  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final deals = MockData.activeDeals;

    if (deals.isEmpty) {
      return Center(
        child: AnimatedEntrance(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.local_offer_outlined,
                  size: 64,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 20),
                Text(
                  'No active discounts',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Check back for coupons and deals from local businesses.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 28),
      itemCount: deals.length,
      itemBuilder: (context, index) {
        final deal = deals[index];
        final listing = MockData.getListingById(deal.listingId);
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: AnimatedEntrance(
            delay: Duration(milliseconds: 60 * (index + 1)),
            child: GlassCard(
              onTap: () {
                if (listing != null) {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ListingDetailScreen(
                        listingId: deal.listingId,
                      ),
                    ),
                  );
                }
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer
                              .withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          deal.discount ?? 'Deal',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              deal.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            if (listing != null)
                              Text(
                                listing.name,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    deal.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (deal.code != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          'Code: ',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: colorScheme.outline,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            deal.code!,
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LoyaltyTab extends StatelessWidget {
  const _LoyaltyTab({required this.horizontalPadding});

  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final punchCards = MockData.activePunchCards;

    if (punchCards.isEmpty) {
      return Center(
        child: AnimatedEntrance(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.loyalty_outlined,
                  size: 64,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 20),
                Text(
                  'No loyalty cards yet',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Earn punches and rewards at participating local spots.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 28),
      itemCount: punchCards.length,
      itemBuilder: (context, index) {
        final card = punchCards[index];
        final listing = MockData.getListingById(card.listingId);
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: AnimatedEntrance(
            delay: Duration(milliseconds: 60 * (index + 1)),
            child: GlassCard(
              onTap: () {
                if (listing != null) {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ListingDetailScreen(
                        listingId: card.listingId,
                      ),
                    ),
                  );
                }
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          card.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.loyalty_rounded,
                        size: 22,
                        color: colorScheme.primary,
                      ),
                    ],
                  ),
                  if (listing != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      listing.name,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    card.rewardDescription,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      for (int i = 0; i < card.punchesRequired; i++)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i < card.punchesEarned
                                  ? colorScheme.primary
                                  : colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.8),
                              border: Border.all(
                                color: i < card.punchesEarned
                                    ? colorScheme.primary
                                    : colorScheme.outline
                                        .withValues(alpha: 0.5),
                              ),
                            ),
                            child: i < card.punchesEarned
                                ? Icon(
                                    Icons.check_rounded,
                                    size: 16,
                                    color: colorScheme.onPrimary,
                                  )
                                : null,
                          ),
                        ),
                      const SizedBox(width: 8),
                      Text(
                        '${card.punchesEarned}/${card.punchesRequired}',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
