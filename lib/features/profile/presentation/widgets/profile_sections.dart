import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cajun_local/core/theme/theme.dart';
import 'package:cajun_local/features/auth/presentation/controllers/auth_controller.dart';

// -------------------------------------------------------------------------- //
// SECTION CARD WRAPPER
// -------------------------------------------------------------------------- //

class ProfileSectionCard extends StatelessWidget {
  const ProfileSectionCard({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.specGold,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.specWhite,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: AppTheme.specNavy.withValues(alpha: 0.08), indent: 56),
                  children[i],
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class ProfileListTile extends StatelessWidget {
  const ProfileListTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.badge,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final int? badge;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (iconColor ?? AppTheme.specNavy).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: iconColor ?? AppTheme.specNavy),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppTheme.specNavy,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.specNavy.withValues(alpha: 0.55),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (badge != null && badge! > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(color: AppTheme.specGold, borderRadius: BorderRadius.circular(12)),
                  child: Text(
                    badge! > 99 ? '99+' : '$badge',
                    style: theme.textTheme.labelSmall?.copyWith(color: AppTheme.specNavy, fontWeight: FontWeight.w700),
                  ),
                ),
              if (trailing != null)
                trailing!
              else if (onTap != null)
                Icon(Icons.chevron_right_rounded, size: 20, color: AppTheme.specNavy.withValues(alpha: 0.4)),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------------------- //
// QUICK ACTIONS
// -------------------------------------------------------------------------- //

class QuickActionsRow extends StatelessWidget {
  const QuickActionsRow({
    super.key,
    required this.signedIn,
    required this.hasListings,
    required this.inboxUnreadCount,
  });

  final bool signedIn;
  final bool hasListings;
  final int inboxUnreadCount;

  @override
  Widget build(BuildContext context) {
    if (!signedIn) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _QuickActionItem(
            icon: Icons.favorite_rounded,
            label: 'Favorites',
            onTap: () => context.push('/favorites'),
          ),
          _QuickActionItem(
            icon: Icons.loyalty_rounded,
            label: 'Punch Cards',
            onTap: () => context.push('/my-punch-cards'),
          ),
          if (hasListings)
            _QuickActionItem(
              icon: Icons.chat_bubble_rounded,
              label: 'Inbox',
              badge: inboxUnreadCount,
              onTap: () => context.push('/form-submissions'),
            )
          else
            Consumer(
              builder: (context, ref, child) {
                final uid = ref.read(authControllerProvider).valueOrNull?.id;
                return _QuickActionItem(
                  icon: Icons.chat_bubble_rounded,
                  label: 'Messages',
                  onTap: () {
                    if (uid != null) context.push('/conversations/$uid');
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  const _QuickActionItem({required this.icon, required this.label, required this.onTap, this.badge});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.specWhite,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, size: 24, color: AppTheme.specNavy),
                ),
                if (badge != null && badge! > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.specRed,
                        shape: BoxShape.rectangle,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badge! > 99 ? '99+' : '$badge',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppTheme.specNavy,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
