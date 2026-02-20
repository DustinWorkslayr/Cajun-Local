import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_app/core/data/mock_data.dart';
import 'package:my_app/core/favorites/favorites_scope.dart';
import 'package:my_app/core/theme/theme.dart';
import 'package:my_app/shared/widgets/animated_entrance.dart';

/// Elegant, futuristic business listing detail page.
class ListingDetailScreen extends StatelessWidget {
  const ListingDetailScreen({super.key, required this.listingId});

  final String listingId;

  static const double _heroHeight = 220;
  static const double _contentRadius = 28;

  static List<MockMenuItem> _menuItemsFor(String id) =>
      MockData.getMenuForListing(id);
  static List<MockSocialLink> _socialLinksFor(String id) =>
      MockData.getSocialLinksForListing(id);
  static List<MockDeal> _dealsFor(String id) =>
      MockData.getDealsForListing(id);
  static List<MockPunchCard> _punchCardsFor(String id) =>
      MockData.getPunchCardsForListing(id);

  @override
  Widget build(BuildContext context) {
    final listing = MockData.getListingById(listingId);
    if (listing == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Listing')),
        body: const Center(child: Text('Listing not found')),
      );
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: colorScheme.surfaceContainerHighest,
        body: CustomScrollView(
          slivers: [
            _buildHero(context, listing, colorScheme),
            SliverToBoxAdapter(
              child: Transform.translate(
                offset: const Offset(0, -_contentRadius),
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(_contentRadius),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withValues(alpha: 0.08),
                        blurRadius: 24,
                        offset: const Offset(0, -8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 24),
                      AnimatedEntrance(
                        delay: const Duration(milliseconds: 80),
                        child: _Section(
                          title: 'About',
                          child: Text(
                            listing.description,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              height: 1.55,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                      if (listing.hours != null && listing.hours!.isNotEmpty)
                        AnimatedEntrance(
                          delay: const Duration(milliseconds: 160),
                          child: _Section(
                            title: 'Hours',
                            icon: Icons.schedule_outlined,
                            child: _HoursBlock(hours: listing.hours!),
                          ),
                        ),
                      if (_menuItemsFor(listing.id).isNotEmpty)
                        AnimatedEntrance(
                          delay: const Duration(milliseconds: 200),
                          child: _Section(
                            title: 'Menu',
                            icon: Icons.restaurant_menu_rounded,
                            child: _MenuBlock(items: _menuItemsFor(listing.id)),
                          ),
                        ),
                      if (listing.address != null ||
                          listing.phone != null ||
                          listing.website != null)
                        AnimatedEntrance(
                          delay: const Duration(milliseconds: 260),
                          child: _Section(
                            title: 'Contact & location',
                            icon: Icons.place_outlined,
                            child: _ContactBlock(listing: listing),
                          ),
                        ),
                      if (_socialLinksFor(listing.id).isNotEmpty)
                        AnimatedEntrance(
                          delay: const Duration(milliseconds: 300),
                          child: _Section(
                            title: 'Social & links',
                            icon: Icons.link_rounded,
                            child: _SocialLinksBlock(links: _socialLinksFor(listing.id)),
                          ),
                        ),
                      if (listing.amenities.isNotEmpty)
                        AnimatedEntrance(
                          delay: const Duration(milliseconds: 340),
                          child: _Section(
                            title: 'Amenities',
                            icon: Icons.check_circle_outline,
                            child: _AmenitiesBlock(amenities: listing.amenities),
                          ),
                        ),
                      if (_dealsFor(listing.id).isNotEmpty)
                        AnimatedEntrance(
                          delay: const Duration(milliseconds: 380),
                          child: _Section(
                            title: 'Coupons & deals',
                            icon: Icons.local_offer_rounded,
                            child: _DealsBlock(listingId: listing.id, deals: _dealsFor(listing.id)),
                          ),
                        ),
                      if (_punchCardsFor(listing.id).isNotEmpty)
                        AnimatedEntrance(
                          delay: const Duration(milliseconds: 420),
                          child: _Section(
                            title: 'Punch cards',
                            icon: Icons.loyalty_rounded,
                            child: _PunchCardsBlock(cards: _punchCardsFor(listing.id)),
                          ),
                        ),
                      const SizedBox(height: 36),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(
    BuildContext context,
    MockListing listing,
    ColorScheme colorScheme,
  ) {
    return SliverAppBar(
      expandedHeight: _heroHeight,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      leading: _GlassButton(
        icon: Icons.arrow_back_ios_new_rounded,
        onTap: () => Navigator.of(context).pop(),
      ),
      actions: [
        ValueListenableBuilder<Set<String>>(
          valueListenable: FavoritesScope.of(context),
          builder: (context, ids, _) {
            final isFav = ids.contains(listing.id);
            return _GlassButton(
              icon: isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              onTap: () {
                final next = Set<String>.from(ids);
                if (next.contains(listing.id)) {
                  next.remove(listing.id);
                } else {
                  next.add(listing.id);
                }
                FavoritesScope.of(context).value = next;
              },
            );
          },
        ),
        const SizedBox(width: 8),
        _GlassButton(
          icon: Icons.share_rounded,
          onTap: () {},
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF002868),
                Color(0xFF0A3D7A),
                Color(0xFF1A1A2E),
              ],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Subtle grid overlay
              CustomPaint(
                painter: _GridOverlayPainter(
                  color: Colors.white.withValues(alpha: 0.04),
                  spacing: 24,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 72, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accentGold.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.accentGold.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        listing.categoryName,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: AppTheme.accentGold,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      listing.name,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      listing.tagline,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white70,
                            fontWeight: FontWeight.w400,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Material(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, size: 20, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _GridOverlayPainter extends CustomPainter {
  _GridOverlayPainter({required this.color, required this.spacing});

  final Color color;
  final double spacing;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.child,
    this.icon,
  });

  final String title;
  final Widget child;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _HoursBlock extends StatelessWidget {
  const _HoursBlock({required this.hours});

  final List<DayHours> hours;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          for (int i = 0; i < hours.length; i++) ...[
            if (i > 0)
              Divider(
                height: 24,
                color: colorScheme.outlineVariant.withValues(alpha: 0.6),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  hours[i].day,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  hours[i].range,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ContactBlock extends StatelessWidget {
  const _ContactBlock({required this.listing});

  final MockListing listing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (listing.address != null)
          _ContactRow(
            icon: Icons.location_on_outlined,
            label: listing.address!,
            onTap: () {},
          ),
        if (listing.phone != null) ...[
          const SizedBox(height: 12),
          _ContactRow(
            icon: Icons.phone_outlined,
            label: listing.phone!,
            onTap: () {},
          ),
        ],
        if (listing.website != null) ...[
          const SizedBox(height: 12),
          _ContactRow(
            icon: Icons.language_rounded,
            label: listing.website!,
            onTap: () {},
          ),
        ],
      ],
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 20, color: colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AmenitiesBlock extends StatelessWidget {
  const _AmenitiesBlock({required this.amenities});

  final List<String> amenities;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final a in amenities)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  a,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _MenuBlock extends StatelessWidget {
  const _MenuBlock({required this.items});

  final List<MockMenuItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bySection = <String, List<MockMenuItem>>{};
    for (final item in items) {
      final sec = item.section ?? 'Menu';
      bySection.putIfAbsent(sec, () => []).add(item);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in bySection.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.key,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                ...entry.value.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                if (item.description != null)
                                  Text(
                                    item.description!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (item.price != null)
                            Text(
                              item.price!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
      ],
    );
  }
}

class _SocialLinksBlock extends StatelessWidget {
  const _SocialLinksBlock({required this.links});

  final List<MockSocialLink> links;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final link in links)
          Material(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _iconForType(link.type),
                      size: 20,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      link.label ?? _labelForType(link.type),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  static IconData _iconForType(String type) {
    switch (type) {
      case 'facebook':
        return Icons.thumb_up_rounded;
      case 'instagram':
        return Icons.camera_alt_rounded;
      case 'twitter':
        return Icons.tag_rounded;
      default:
        return Icons.link_rounded;
    }
  }

  static String _labelForType(String type) {
    switch (type) {
      case 'facebook':
        return 'Facebook';
      case 'instagram':
        return 'Instagram';
      case 'twitter':
        return 'Twitter';
      default:
        return 'Link';
    }
  }
}

class _DealsBlock extends StatelessWidget {
  const _DealsBlock({required this.listingId, required this.deals});

  final String listingId;
  final List<MockDeal> deals;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final deal in deals)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (deal.discount != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            deal.discount!,
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          deal.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    deal.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (deal.code != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Code: ${deal.code!}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _PunchCardsBlock extends StatelessWidget {
  const _PunchCardsBlock({required this.cards});

  final List<MockPunchCard> cards;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final card in cards)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colorScheme.tertiaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: colorScheme.tertiary.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    card.rewardDescription,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (int i = 0; i < card.punchesRequired; i++)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i < card.punchesEarned
                                  ? colorScheme.primary
                                  : colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.8),
                              border: Border.all(
                                color: i < card.punchesEarned
                                    ? colorScheme.primary
                                    : colorScheme.outline.withValues(alpha: 0.5),
                              ),
                            ),
                            child: i < card.punchesEarned
                                ? Icon(Icons.check_rounded, size: 14, color: colorScheme.onPrimary)
                                : null,
                          ),
                        ),
                      const SizedBox(width: 8),
                      Text(
                        '${card.punchesEarned}/${card.punchesRequired} punches',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
