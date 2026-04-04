import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';

/// Side menu tile with 100% Stitch v2 design fidelity.
class NavTile extends StatelessWidget {
  const NavTile({
    super.key,
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
    this.badge,
    this.textColor,
  });

  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Stitch v2: Solid Gold background for selected (#7A5901), white text/icon.
    // Unselected: Navy icons/text.
    final bgColor = selected ? const Color(0xFF7A5901) : Colors.transparent;
    final contentColor = selected ? Colors.white : (textColor ?? AppTheme.specNavy);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: contentColor, size: 20),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: contentColor,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: selected ? Colors.white.withValues(alpha: 0.2) : AppTheme.specGold,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badge!,
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerSectionHeader extends StatelessWidget {
  final String title;
  const _DrawerSectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppTheme.specOutline,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          fontSize: 10,
        ),
      ),
    );
  }
}

/// A high-contrast AI button for the Cajun AI card.
class _AiButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _AiButton({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.specGold, size: 20),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.white24),
            ],
          ),
        ),
      ),
    );
  }
}

/// The Main Navigation Drawer for Cajun Local.
/// 100% design fidelity to Stitch v2 "The Digital Curator".
class AppMenuDrawer extends ConsumerStatefulWidget {
  const AppMenuDrawer({
    super.key,
    required this.currentIndex,
    required this.onClose,
    required this.onNavigateToTab,
    required this.onOpenAskLocal,
    required this.onOpenChooseForMe,
    required this.onOpenLocalEvents,
    required this.onOpenNotifications,
    required this.onOpenMessages,
    required this.onSignOut,
  });

  final int currentIndex;
  final VoidCallback onClose;
  final ValueChanged<int> onNavigateToTab;
  final VoidCallback onOpenAskLocal;
  final VoidCallback onOpenChooseForMe;
  final VoidCallback onOpenLocalEvents;
  final VoidCallback onOpenNotifications;
  final VoidCallback onOpenMessages;
  final VoidCallback onSignOut;

  @override
  ConsumerState<AppMenuDrawer> createState() => _AppMenuDrawerState();
}

class _AppMenuDrawerState extends ConsumerState<AppMenuDrawer> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = ref.watch(authControllerProvider).valueOrNull;

    return Drawer(
      backgroundColor: AppTheme.specOffWhite,
      width: MediaQuery.of(context).size.width * 0.85,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Brand/User Header (White Background)
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 64, 16, 12), // Added right padding for close button space
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        const CircleAvatar(
                          radius: 30,
                          backgroundColor: AppTheme.specSurfaceContainer,
                          child: Icon(Icons.person_rounded, size: 30, color: AppTheme.specNavy),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: AppTheme.specGold,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.specWhite, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: widget.onClose,
                      icon: const Icon(Icons.close_rounded, color: AppTheme.specNavy, size: 24),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  profile?.profile?.displayName ?? 'Cajun Curator',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppTheme.specNavy,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, size: 14, color: AppTheme.specOutline),
                    const SizedBox(width: 4),
                    Text(
                      'Baton Rouge, LA',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.specOutline,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                const _DrawerSectionHeader('Main Menu'),
                NavTile(
                  icon: Icons.home_filled,
                  title: 'Home',
                  selected: widget.currentIndex == 0,
                  onTap: () => widget.onNavigateToTab(0),
                ),
                NavTile(
                  icon: Icons.newspaper_outlined,
                  title: 'News',
                  selected: widget.currentIndex == 1,
                  onTap: () => widget.onNavigateToTab(1),
                ),
                NavTile(
                  icon: Icons.explore_outlined,
                  title: 'Explore',
                  selected: widget.currentIndex == 2,
                  onTap: () => widget.onNavigateToTab(2),
                ),
                NavTile(
                  icon: Icons.local_offer_outlined,
                  title: 'Deals',
                  selected: widget.currentIndex == 3,
                  onTap: () => widget.onNavigateToTab(3),
                ),
                NavTile(
                  icon: Icons.person_outline_rounded,
                  title: 'Profile',
                  selected: widget.currentIndex == 4,
                  onTap: () => widget.onNavigateToTab(4),
                ),

                const SizedBox(height: 12),
                // 3. Cajun AI Section (Navy Card Style)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppTheme.specNavy, borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CAJUN AI',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            fontSize: 9,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _AiButton(
                          icon: Icons.auto_awesome_rounded,
                          title: 'Ask Local',
                          onTap: () {
                            widget.onClose();
                            widget.onOpenAskLocal();
                          },
                        ),
                        const SizedBox(height: 8),
                        _AiButton(
                          icon: Icons.casino_rounded,
                          title: 'Choose for me',
                          onTap: () {
                            widget.onClose();
                            widget.onOpenChooseForMe();
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const _DrawerSectionHeader('Connect & Social'),
                NavTile(
                  icon: Icons.event_outlined,
                  title: 'Local Events',
                  selected: false,
                  onTap: () {
                    widget.onClose();
                    widget.onOpenLocalEvents();
                  },
                ),
                NavTile(
                  icon: Icons.notifications_none_rounded,
                  title: 'Notifications',
                  selected: false,
                  onTap: () {
                    widget.onClose();
                    widget.onOpenNotifications();
                  },
                  badge: '2',
                ),
                NavTile(
                  icon: Icons.mail_outline_rounded,
                  title: 'Messages',
                  selected: false,
                  onTap: () {
                    widget.onClose();
                    widget.onOpenMessages();
                  },
                ),
              ],
            ),
          ),

          // 5. Footer Metadata
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NavTile(
                  icon: Icons.logout_rounded,
                  title: 'SIGN OUT',
                  textColor: const Color(0xFFC04F34), // Design Red
                  selected: false,
                  onTap: widget.onSignOut,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
