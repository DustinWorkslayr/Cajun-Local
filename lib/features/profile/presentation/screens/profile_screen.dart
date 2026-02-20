import 'package:flutter/material.dart';
import 'package:my_app/core/data/mock_data.dart';
import 'package:my_app/features/my_listings/presentation/screens/my_listings_screen.dart';
import 'package:my_app/shared/widgets/animated_entrance.dart';
import 'package:my_app/shared/widgets/glass_card.dart';
import 'package:my_app/shared/widgets/section_header.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const double _horizontalPadding = 20;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = MockData.currentUser;
    final hasListings = user.ownedListingIds.isNotEmpty;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: AnimatedEntrance(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(_horizontalPadding, 24, _horizontalPadding, 20),
              child: GlassCard(
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.8),
                      child: Text(
                        user.displayName.isNotEmpty
                            ? user.displayName[0].toUpperCase()
                            : '?',
                        style: theme.textTheme.headlineLarge?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      user.displayName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (user.email != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        user.email!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: SectionHeader(title: 'Account'),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              if (hasListings)
                AnimatedEntrance(
                  delay: const Duration(milliseconds: 60),
                  child: _ProfileTile(
                    icon: Icons.store_rounded,
                    label: 'My Listings',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const MyListingsScreen(),
                        ),
                      );
                    },
                  ),
                ),
              AnimatedEntrance(
                delay: Duration(milliseconds: hasListings ? 100 : 80),
                child: _ProfileTile(
                  icon: Icons.person_outline_rounded,
                  label: 'Edit profile',
                  onTap: () {},
                ),
              ),
              AnimatedEntrance(
                delay: Duration(milliseconds: hasListings ? 140 : 120),
                child: _ProfileTile(
                  icon: Icons.notifications_outlined,
                  label: 'Notifications',
                  onTap: () {},
                ),
              ),
              AnimatedEntrance(
                delay: Duration(milliseconds: hasListings ? 180 : 160),
                child: _ProfileTile(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  onTap: () {},
                ),
              ),
            ]),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: SectionHeader(title: 'About'),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              AnimatedEntrance(
                delay: const Duration(milliseconds: 200),
                child: _ProfileTile(
                  icon: Icons.info_outline_rounded,
                  label: 'About Cajun Local',
                  onTap: () {},
                ),
              ),
              AnimatedEntrance(
                delay: const Duration(milliseconds: 240),
                child: _ProfileTile(
                  icon: Icons.description_outlined,
                  label: 'Privacy policy',
                  onTap: () {},
                ),
              ),
            ]),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              color: colorScheme.primary,
              size: 22,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyLarge,
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
    );
  }
}
