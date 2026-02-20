import 'package:flutter/material.dart';
import 'package:my_app/core/data/mock_data.dart';
import 'package:my_app/features/my_listings/presentation/screens/listing_edit_screen.dart';
import 'package:my_app/shared/widgets/animated_entrance.dart';
import 'package:my_app/shared/widgets/glass_card.dart';

/// List of businesses owned by the current user; tap to open edit/dashboard.
class MyListingsScreen extends StatelessWidget {
  const MyListingsScreen({super.key});

  static const double _horizontalPadding = 20;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = MockData.currentUser;
    final listings = user.ownedListingIds
        .map((id) => MockData.getListingById(id))
        .whereType<MockListing>()
        .toList();

    if (listings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'You don\'t have any listings yet.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(_horizontalPadding, 24, _horizontalPadding, 28),
      itemCount: listings.length,
      itemBuilder: (context, index) {
        final listing = listings[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: AnimatedEntrance(
            delay: Duration(milliseconds: 60 * (index + 1)),
            child: GlassCard(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ListingEditScreen(listingId: listing.id),
                  ),
                );
              },
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: colorScheme.primaryContainer.withValues(alpha: 0.8),
                    ),
                    child: Icon(
                      Icons.store_rounded,
                      color: colorScheme.onPrimaryContainer,
                      size: 28,
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
                            color: colorScheme.onSurface,
                          ),
                        ),
                        if (listing.address != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            listing.address!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
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
    );
  }
}
